import json
import os
import math
import re

def normalize_arabic(text):
    if not text:
        return ""
    text = str(text).strip().lower()
    # Normalize Alif variations
    text = text.replace("أ", "ا").replace("إ", "ا").replace("آ", "ا")
    # Normalize Teh Marbuta
    text = text.replace("ة", "ه")
    # Normalize Alef Maksura
    text = text.replace("ى", "ي")
    # Remove extra spaces
    text = " ".join(text.split())
    return text

def distance(lat1, lon1, lat2, lon2):
    return math.sqrt((lat1 - lat2) ** 2 + (lon1 - lon2) ** 2)

def enrich_all_medical_data():
    cities_path = "assets/data/algeria_cities.json"
    raw_path = "scratch/raw_medical_all.json"
    if not os.path.exists(raw_path):
        raw_path = "scratch/raw_osm_data.json"
        
    if not os.path.exists(cities_path) or not os.path.exists(raw_path):
        print(f"Data files missing! Check {cities_path} and {raw_path}")
        return
        
    with open(cities_path, "r", encoding="utf-8") as f:
        cities_data = json.load(f)
        
    with open(raw_path, "r", encoding="utf-8") as f:
        raw_elements = json.load(f)
        
    wilayas = cities_data.get("wilayas", [])
    communes = cities_data.get("communes", [])
    
    # Map building
    wilaya_by_id = {}
    commune_to_wilaya = {} # normalized_name -> wilaya_id
    communes_list = []
    
    for w in wilayas:
        wid = int(w["wilaya_id"])
        w_ar = w["wilaya_name_arabic"]
        w_lat = w["wilaya_name_latin"]
        
        wilaya_by_id[wid] = {
            "id": wid,
            "name_ar": w_ar,
            "name_fr": w_lat,
            "lat": (float(w.get("latitude")) if w.get("latitude") else 0.0),
            "lon": (float(w.get("longitude")) if w.get("longitude") else 0.0)
        }
        
        norm_ar = normalize_arabic(w_ar)
        norm_fr = w_lat.strip().lower()
        
        commune_to_wilaya[norm_ar] = wid
        commune_to_wilaya[norm_fr] = wid
        commune_to_wilaya[norm_fr.replace(" ", "-")] = wid
        commune_to_wilaya[norm_fr.replace("-", " ")] = wid
        commune_to_wilaya[normalize_arabic("ولاية " + w_ar)] = wid
        commune_to_wilaya[normalize_arabic(w_ar + " ولاية")] = wid

    for c in communes:
        wid = int(c["wilaya_id"])
        c_ar = c.get("commune_name_arabic") or ""
        c_lat = c.get("commune_name_latin") or ""
        
        if c_ar:
            commune_to_wilaya[normalize_arabic(c_ar)] = wid
        if c_lat:
            norm_c_lat = c_lat.strip().lower()
            commune_to_wilaya[norm_c_lat] = wid
            commune_to_wilaya[norm_c_lat.replace(" ", "-")] = wid
            commune_to_wilaya[norm_c_lat.replace("-", " ")] = wid

    print(f"Loaded {len(wilayas)} wilayas and {len(communes)} communes.")
    
    processed_facilities = []
    
    for el in raw_elements:
        tags = el.get('tags', {})
        
        # Coordinates
        lat = el.get('lat')
        lon = el.get('lon')
        if lat is None or lon is None:
            center = el.get('center')
            if center:
                lat = center.get('lat')
                lon = center.get('lon')
                
        if lat is None or lon is None:
            continue
            
        # Extract names & tags
        name_raw = tags.get('name') or tags.get('name:ar') or tags.get('name:fr') or tags.get('name:en')
        name_ar = tags.get('name:ar') or ""
        name_fr = tags.get('name:fr') or ""
        
        phone = tags.get('phone') or tags.get('contact:phone') or tags.get('contact:mobile') or tags.get('mobile') or "غير متوفر"
        city_raw = tags.get('addr:city') or tags.get('addr:suburb') or tags.get('addr:district') or tags.get('addr:full') or ""
        street = tags.get('addr:street') or ""
        website = tags.get('website') or tags.get('contact:website') or "غير متوفر"
        
        specialty = (tags.get('healthcare:speciality') or tags.get('speciality') or "").lower()
        amenity = (tags.get('amenity') or "").lower()
        healthcare = (tags.get('healthcare') or "").lower()
        
        full_text = f"{name_raw or ''} {name_ar} {name_fr} {specialty} {city_raw} {street} {tags.get('description') or ''}".lower()
        full_text_norm = normalize_arabic(full_text)
        
        # Determine Specialty Group
        # Groups: 'gyn', 'pedia', 'maternity', 'general'
        is_gyn = False
        is_pedia = False
        is_maternity = False
        
        if 'gynaec' in specialty or 'obstetric' in specialty or 'gyneco' in full_text or 'نساء' in full_text_norm or 'توليد' in full_text_norm:
            is_gyn = True
            
        if 'pediatr' in specialty or 'paediatr' in specialty or 'child' in specialty or 'pédiat' in full_text or 'اطفال' in full_text_norm or 'طفوله' in full_text_norm:
            is_pedia = True
            
        if 'maternity' in full_text or 'أمومة' in full_text_norm or 'امومه' in full_text_norm or 'ehs' in full_text:
            is_maternity = True
            
        if is_gyn and is_pedia:
            specialty_group = "maternity"
            type_desc_ar = "مستشفى/عيادة الأمومة والطفولة"
            facility_type = "maternity_hospital"
        elif is_gyn:
            specialty_group = "gyn"
            type_desc_ar = "أخصائية / طبيب نساء وتوليد"
            facility_type = "gynaecologist"
        elif is_pedia:
            specialty_group = "pedia"
            type_desc_ar = "أخصائي / طبيب أطفال"
            facility_type = "pediatrician"
        elif is_maternity:
            specialty_group = "maternity"
            type_desc_ar = "عيادة أمومة وطفولة"
            facility_type = "maternity_hospital"
        else:
            specialty_group = "general"
            if amenity == "hospital" or healthcare == "hospital":
                type_desc_ar = "مستشفى عام"
                facility_type = "hospital"
            elif amenity == "clinic" or healthcare == "clinic":
                type_desc_ar = "عيادة متعددة الخدمات"
                facility_type = "clinic"
            else:
                type_desc_ar = "عيادة طبية"
                facility_type = "doctor"

        # Determine Wilaya & Commune
        matched_wid = None
        matched_commune_ar = ""
        
        # 1. Match from city tag or name
        for text in [city_raw, street, name_raw]:
            if not text:
                continue
            norm_t = normalize_arabic(text)
            if norm_t in commune_to_wilaya:
                matched_wid = commune_to_wilaya[norm_t]
                matched_commune_ar = text
                break
            # Try subparts
            words = norm_t.split()
            for w in words:
                if len(w) >= 4 and w in commune_to_wilaya:
                    matched_wid = commune_to_wilaya[w]
                    matched_commune_ar = w
                    break
            if matched_wid:
                break
                
        # 2. Spatial matching fallback (closest Wilaya centroid)
        if not matched_wid:
            min_dist = float('inf')
            best_wid = 1
            for wid, w_info in wilaya_by_id.items():
                if w_info["lat"] != 0.0 and w_info["lon"] != 0.0:
                    d = distance(lat, lon, w_info["lat"], w_info["lon"])
                    if d < min_dist:
                        min_dist = d
                        best_wid = wid
            matched_wid = best_wid
            
        w_details = wilaya_by_id.get(matched_wid, wilaya_by_id[16]) # Default Algiers if issue
        
        # Format clean name
        display_name_ar = name_ar or name_raw or "عيادة طبية"
        if "د." not in display_name_ar and "طبيب" not in display_name_ar and "مستشفى" not in display_name_ar and "عيادة" not in display_name_ar:
            if specialty_group == "gyn":
                display_name_ar = f"د. {display_name_ar} (نساء وتوليد)"
            elif specialty_group == "pedia":
                display_name_ar = f"د. {display_name_ar} (طب الأطفال)"
            elif specialty_group == "maternity":
                display_name_ar = f"مركز/عيادة {display_name_ar}"

        display_name_fr = name_fr or name_raw or display_name_ar
        address_str = f"{street}, {matched_commune_ar or w_details['name_ar']}, {w_details['name_ar']}".strip(", ")
        is_public = (amenity == "hospital" or healthcare == "hospital" or "عمومي" in full_text_norm or "عمومية" in full_text_norm or "ehs" in full_text or "eph" in full_text or "epsp" in full_text)

        # Filter out generic uncontactable facilities (no phone number and general clinic)
        if specialty_group == "general" and phone == "غير متوفر":
            continue

        processed_facilities.append({
            "id": f"{el.get('type', 'node')}_{el.get('id')}",
            "name_ar": display_name_ar,
            "name_fr": display_name_fr,
            "lat": round(lat, 6),
            "lon": round(lon, 6),
            "phone": phone,
            "address": address_str,
            "city": matched_commune_ar or w_details['name_ar'],
            "wilaya_id": matched_wid,
            "wilaya_name_ar": w_details['name_ar'],
            "wilaya_name_fr": w_details['name_fr'],
            "type": facility_type,
            "specialty_group": specialty_group,
            "type_desc_ar": type_desc_ar,
            "is_public": is_public,
            "website": website
        })

    print(f"Enriched total of {len(processed_facilities)} facilities.")
    
    # Save enriched file directly to assets/data/algeria_doctors_clinics.json
    output_path = "assets/data/algeria_doctors_clinics.json"
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(processed_facilities, f, ensure_ascii=False, indent=2)
    print(f"Saved enriched data to {output_path}")

    # Print breakdown summary by specialty group
    gyn_cnt = sum(1 for x in processed_facilities if x['specialty_group'] == 'gyn')
    pedia_cnt = sum(1 for x in processed_facilities if x['specialty_group'] == 'pedia')
    mat_cnt = sum(1 for x in processed_facilities if x['specialty_group'] == 'maternity')
    gen_cnt = sum(1 for x in processed_facilities if x['specialty_group'] == 'general')
    
    print("\n--- Summary Breakdown ---")
    print(f"  - OB/GYN (نساء وتوليد): {gyn_cnt}")
    print(f"  - Pediatrics (طب الأطفال): {pedia_cnt}")
    print(f"  - Maternity & Children Centers (أمومة وطفولة): {mat_cnt}")
    print(f"  - General Clinics/Hospitals: {gen_cnt}")
    
    # Wilayas covered count
    covered_wilayas = len(set(x['wilaya_id'] for x in processed_facilities))
    print(f"  - Wilayas Covered: {covered_wilayas} out of 58")

if __name__ == "__main__":
    enrich_all_medical_data()
