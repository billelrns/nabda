import json
import os
import math

def distance(lat1, lon1, lat2, lon2):
    # Standard Euclidean distance is fine for close coordinates mapping
    return math.sqrt((lat1 - lat2) ** 2 + (lon1 - lon2) ** 2)

def enrich_data():
    cities_path = "assets/data/algeria_cities.json"
    processed_path = "scratch/processed_medical_data.json"
    
    if not os.path.exists(cities_path) or not os.path.exists(processed_path):
        print("Data files missing!")
        return
        
    with open(cities_path, "r", encoding="utf-8") as f:
        cities_data = json.load(f)
        
    with open(processed_path, "r", encoding="utf-8") as f:
        medical_elements = json.load(f)
        
    wilayas = cities_data.get("wilayas", [])
    communes = cities_data.get("communes", [])
    
    # Maps for matching
    wilaya_map = {} # wilaya_id -> {names, id, name_ar, name_latin}
    commune_to_wilaya = {} # name -> wilaya_id
    
    for w in wilayas:
        wid = int(w["wilaya_id"])
        w_ar = w["wilaya_name_arabic"].strip()
        w_lat = w["wilaya_name_latin"].strip().lower()
        
        wilaya_map[wid] = {
            "id": wid,
            "name_ar": w["wilaya_name_arabic"],
            "name_latin": w["wilaya_name_latin"],
            "centroid_lat": 0.0,
            "centroid_lon": 0.0,
            "count": 0
        }
        
        # Add to matching maps
        commune_to_wilaya[w_ar] = wid
        commune_to_wilaya[w_lat] = wid
        commune_to_wilaya[w_lat.replace(" ", "-")] = wid
        commune_to_wilaya[w_lat.replace("-", " ")] = wid
        commune_to_wilaya["ولاية " + w_ar] = wid
        commune_to_wilaya[w_ar + " ولاية"] = wid

    for c in communes:
        wid = int(c["wilaya_id"])
        c_ar = c["commune_name_arabic"].strip() if c.get("commune_name_arabic") else ""
        c_lat = c["commune_name_latin"].strip().lower() if c.get("commune_name_latin") else ""
        
        if c_ar:
            commune_to_wilaya[c_ar] = wid
        if c_lat:
            commune_to_wilaya[c_lat] = wid
            commune_to_wilaya[c_lat.replace(" ", "-")] = wid
            commune_to_wilaya[c_lat.replace("-", " ")] = wid

    print(f"Loaded {len(wilayas)} wilayas and {len(communes)} communes.")
    
    matched_count = 0
    unmatched_elements = []
    enriched_elements = []
    
    # Step 1: Text-based matching
    for el in medical_elements:
        lat = el.get("lat")
        lon = el.get("lon")
        if lat is None or lon is None:
            continue
            
        matched_wid = None
        
        # Try to find a match in city, street, name, or address tags
        tags = el.get("tags", {})
        search_texts = []
        
        city = el.get("city", "")
        if city and city != "غير محدد":
            search_texts.append(city.lower())
            
        street = el.get("street", "")
        if street:
            search_texts.append(street.lower())
            
        name = el.get("name", "")
        if name:
            search_texts.append(name.lower())
            
        name_ar = el.get("name_ar", "")
        if name_ar:
            search_texts.append(name_ar)
            
        name_fr = el.get("name_fr", "")
        if name_fr:
            search_texts.append(name_fr.lower())
            
        # Check province tag if available
        prov = tags.get("addr:province") or tags.get("addr:state") or tags.get("is_in:province") or tags.get("is_in:state")
        if prov:
            search_texts.append(prov.lower())
            
        # Look for matches in search texts
        for txt in search_texts:
            # Exact match
            if txt in commune_to_wilaya:
                matched_wid = commune_to_wilaya[txt]
                break
            # Substring matches for longer texts (e.g. "Alger", "Oran")
            for key, wid in commune_to_wilaya.items():
                if len(key) > 3 and key in txt:
                    matched_wid = wid
                    break
            if matched_wid:
                break
                
        if matched_wid:
            matched_count += 1
            # Add to centroid sum
            wilaya_map[matched_wid]["centroid_lat"] += lat
            wilaya_map[matched_wid]["centroid_lon"] += lon
            wilaya_map[matched_wid]["count"] += 1
            
            enriched_elements.append({
                "element": el,
                "wilaya_id": matched_wid
            })
        else:
            unmatched_elements.append(el)

    print(f"Step 1: Matched {matched_count} elements using text search. {len(unmatched_elements)} unmatched.")
    
    # Calculate initial centroids for wilayas that have matched elements
    # For wilayas that don't have matched elements, let's seed them with approximate coordinates of major cities
    # (since we know Algeria's geographic layout, we can provide defaults for common ones, or use averages of others)
    for wid, w in wilaya_map.items():
        if w["count"] > 0:
            w["centroid_lat"] /= w["count"]
            w["centroid_lon"] /= w["count"]
        else:
            # Seed default coordinates for key wilayas if they have 0 elements matched initially
            # Algiers (16): 36.7, 3.0
            # Oran (31): 35.7, -0.6
            # Constantine (25): 36.3, 6.6
            # Set a general default of Algiers center
            w["centroid_lat"] = 36.75
            w["centroid_lon"] = 3.05

    # Step 2: Distance-based matching for unmatched elements
    distance_matched_count = 0
    for el in unmatched_elements:
        lat = el.get("lat")
        lon = el.get("lon")
        
        # Find closest wilaya centroid
        closest_wid = None
        min_dist = float("inf")
        
        for wid, w in wilaya_map.items():
            dist = distance(lat, lon, w["centroid_lat"], w["centroid_lon"])
            if dist < min_dist:
                min_dist = dist
                closest_wid = wid
                
        if closest_wid:
            distance_matched_count += 1
            # Recalculate centroid dynamically (rolling average)
            w = wilaya_map[closest_wid]
            w["centroid_lat"] = (w["centroid_lat"] * w["count"] + lat) / (w["count"] + 1)
            w["centroid_lon"] = (w["centroid_lon"] * w["count"] + lon) / (w["count"] + 1)
            w["count"] += 1
            
            enriched_elements.append({
                "element": el,
                "wilaya_id": closest_wid
            })

    print(f"Step 2: Matched {distance_matched_count} remaining elements using coordinate distance.")

    # Final Output formatting
    type_translations = {
        "doctor": "طبيب / عيادة خاصة",
        "clinic": "عيادة طبية",
        "hospital": "مستشفى / مركز صحي",
        "gynaecologist": "أخصائي نساء وتوليد"
    }

    final_medical = []
    for item in enriched_elements:
        el = item["element"]
        wid = item["wilaya_id"]
        w_info = wilaya_map[wid]
        
        name = el.get("name", "").strip()
        name_ar = el.get("name_ar")
        name_fr = el.get("name_fr")
        
        is_gyn = el.get("is_gyn", False)
        phone = el.get("phone", "غير متوفر")
        type_str = el.get("type")
        
        if is_gyn:
            type_str = "gynaecologist"
            
        is_placeholder = name in ["عيادة/طبيب غير مسمى", "cabinet medical", "Cabinet médical", "Médecin", "Médécin", "dispensaire", "Dispensaire", "Polyclinique", "polyclinique", "Hôpital", "clinic", "doctors", "hospital"]
        
        if is_placeholder:
            if is_gyn:
                name_display_ar = "عيادة أمراض النساء والتوليد"
                name_display_fr = "Cabinet de Gynécologie"
            else:
                if type_str == "hospital":
                    name_display_ar = "مركز صحي / مستشفى"
                    name_display_fr = "Centre de Santé / Hôpital"
                elif type_str == "clinic":
                    name_display_ar = "عيادة طبية"
                    name_display_fr = "Clinique Médicale"
                else:
                    name_display_ar = "عيادة طبية خاصة"
                    name_display_fr = "Cabinet Médical"
        else:
            name_display_ar = name_ar or name
            name_display_fr = name_fr or name

        # Infer public vs private
        is_public = False
        name_lower = name.lower()
        name_ar_str = name_ar or ""
        tags = el.get("tags", {})
        operator_type = tags.get("operator:type", "").lower()
        
        if operator_type == "public":
            is_public = True
        elif operator_type == "private":
            is_public = False
        else:
            public_keywords = ["chu", "eph", "epsp", "polyclinique", "dispensaire", "public", "maternite publique", 
                               "مستشفى عمومي", "مستوصف", "قاعة علاج", "المستشفى", "المركز الاستشفائي", "العمومي"]
            private_keywords = ["clinique privée", "cabinet", "cabinet medical", "dr.", "dr ", "doctor", "pr.", "pr ",
                                "عيادة خاصة", "الدكتور", "الدكتورة", "طبيب خاص", "طبيبة"]
            has_public_keyword = any(k in name_lower or k in name_ar_str for k in public_keywords)
            has_private_keyword = any(k in name_lower or k in name_ar_str for k in private_keywords)
            
            if has_public_keyword and not has_private_keyword:
                is_public = True
            elif type_str == "hospital":
                is_public = True
            else:
                is_public = False
                
        # Address
        city = el.get("city", "غير محدد")
        if city == "غير محدد":
            city = w_info["name_ar"]
            
        street = el.get("street")
        address_parts = []
        if street:
            address_parts.append(street)
        address_parts.append(city)
        address_str = ", ".join(address_parts)

        # Skip low quality data
        if is_placeholder and not is_gyn and phone == "غير متوفر":
            continue

        final_medical.append({
            "id": el.get("id"),
            "name_ar": name_display_ar,
            "name_fr": name_display_fr,
            "lat": el.get("lat"),
            "lon": el.get("lon"),
            "phone": phone,
            "address": address_str,
            "city": city,
            "wilaya_id": wid,
            "wilaya_name_ar": w_info["name_ar"],
            "wilaya_name_fr": w_info["name_latin"],
            "type": type_str,
            "type_desc_ar": type_translations.get(type_str, "طبيب / عيادة"),
            "is_public": is_public,
            "website": tags.get("website") or "غير متوفر"
        })

    # Save to final database file
    out_path = "assets/data/algeria_doctors_clinics.json"
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(final_medical, f, ensure_ascii=False, indent=2)

    # Save wilaya centroids for map camera zoom targets!
    wilaya_centroids = []
    for wid, w in wilaya_map.items():
        if w["count"] > 0:
            wilaya_centroids.append({
                "wilaya_id": w["id"],
                "wilaya_name_ar": w["name_ar"],
                "wilaya_name_fr": w["name_latin"],
                "lat": w["centroid_lat"],
                "lon": w["centroid_lon"]
            })
            
    centroids_path = "assets/data/algeria_wilaya_centroids.json"
    with open(centroids_path, "w", encoding="utf-8") as f:
        json.dump(wilaya_centroids, f, ensure_ascii=False, indent=2)

    print(f"Exported final database: {len(final_medical)} entries.")
    print(f"Saved wilaya centroids for camera targets to {centroids_path}.")

if __name__ == "__main__":
    enrich_data()
