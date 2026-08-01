import json
import os

def clean_and_export():
    processed_path = "scratch/processed_medical_data.json"
    if not os.path.exists(processed_path):
        print("Processed medical data file not found!")
        return

    with open(processed_path, "r", encoding="utf-8") as f:
        elements = json.load(f)

    cleaned = []
    
    # Arabic dictionary for common replacements and translations
    type_translations = {
        "doctor": "طبيب / عيادة خاصة",
        "clinic": "عيادة طبية",
        "hospital": "مستشفى / مركز صحي",
        "gynaecologist": "أخصائي نساء وتوليد"
    }

    for el in elements:
        name = el.get("name", "").strip()
        name_ar = el.get("name_ar")
        name_fr = el.get("name_fr")
        
        # Skip completely unnamed or placeholder entries unless they have a phone or represent a gynaecologist
        is_placeholder = name in ["عيادة/طبيب غير مسمى", "cabinet medical", "Cabinet médical", "Médecin", "Médécin", "dispensaire", "Dispensaire", "Polyclinique", "polyclinique", "Hôpital", "clinic", "doctors", "hospital"]
        is_gyn = el.get("is_gyn", False)
        phone = el.get("phone", "غير متوفر")
        
        if is_placeholder and not is_gyn and phone == "غير متوفر":
            continue # Skip low-quality general entries
            
        # Clean names
        if is_placeholder:
            if is_gyn:
                name_display_ar = "عيادة أمراض النساء والتوليد"
                name_display_fr = "Cabinet de Gynécologie"
            else:
                if el.get("type") == "hospital":
                    name_display_ar = "مركز صحي / مستشفى"
                    name_display_fr = "Centre de Santé / Hôpital"
                elif el.get("type") == "clinic":
                    name_display_ar = "عيادة طبية"
                    name_display_fr = "Clinique Médicale"
                else:
                    name_display_ar = "عيادة طبية خاصة"
                    name_display_fr = "Cabinet Médical"
        else:
            name_display_ar = name_ar or name
            name_display_fr = name_fr or name
            
        # Refine type
        type_str = el.get("type")
        if is_gyn:
            type_str = "gynaecologist"
            
        # Infer public vs private in Algeria
        # Public: CHU, EPH, EPSP, Polyclinique, Dispensaire, Centre de santé, مستشفى, مستوصف, قاعة علاج
        # Private: Clinique, Cabinet, Dr, طبيب, الدكتورة, الدكتور, Chifa, Chiffa, Clinique privée
        is_public = False
        name_lower = name.lower()
        name_ar_str = name_ar or ""
        
        public_keywords = ["chu", "eph", "epsp", "polyclinique", "dispensaire", "public", "maternite publique", 
                           "مستشفى عمومي", "مستوصف", "قاعة علاج", "المستشفى", "المركز الاستشفائي", "العمومي"]
        
        private_keywords = ["clinique privée", "cabinet", "cabinet medical", "dr.", "dr ", "doctor", "pr.", "pr ",
                            "عيادة خاصة", "الدكتور", "الدكتورة", "طبيب خاص", "طبيبة"]
                            
        # Check tags as well
        tags = el.get("tags", {})
        operator_type = tags.get("operator:type", "").lower()
        
        if operator_type == "public":
            is_public = True
        elif operator_type == "private":
            is_public = False
        else:
            # Infer from name
            has_public_keyword = any(k in name_lower or k in name_ar_str for k in public_keywords)
            has_private_keyword = any(k in name_lower or k in name_ar_str for k in private_keywords)
            
            if has_public_keyword and not has_private_keyword:
                is_public = True
            elif type_str == "hospital":
                is_public = True # Most hospitals in OSM Algeria are public EPH/CHU
            else:
                is_public = False # Default to private for individual doctors/clinics
                
        # Address formatting
        city = el.get("city", "غير محدد")
        if city == "غير محدد" and tags.get("addr:province"):
            city = tags.get("addr:province")
            
        street = el.get("street")
        address_parts = []
        if street:
            address_parts.append(street)
        if city and city != "غير محدد":
            address_parts.append(city)
            
        address_str = ", ".join(address_parts) if address_parts else "الجزائر"
        
        cleaned.append({
            "id": el.get("id"),
            "name_ar": name_display_ar,
            "name_fr": name_display_fr,
            "lat": el.get("lat"),
            "lon": el.get("lon"),
            "phone": phone,
            "address": address_str,
            "city": city,
            "type": type_str,
            "type_desc_ar": type_translations.get(type_str, "طبيب / عيادة"),
            "is_public": is_public,
            "website": tags.get("website") or "غير متوفر"
        })

    # Save to assets/data
    os.makedirs("assets/data", exist_ok=True)
    out_path = "assets/data/algeria_doctors_clinics.json"
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(cleaned, f, ensure_ascii=False, indent=2)

    print(f"Successfully cleaned and exported {len(cleaned)} medical facilities.")
    gyns = [x for x in cleaned if x["type"] == "gynaecologist"]
    clinics = [x for x in cleaned if x["type"] == "clinic"]
    hospitals = [x for x in cleaned if x["type"] == "hospital"]
    priv_docs = [x for x in cleaned if x["type"] == "doctor"]
    
    print(f"Summary:")
    print(f"  - Obstetrics/Gynaecology: {len(gyns)}")
    print(f"  - General Private Doctors: {len(priv_docs)}")
    print(f"  - General Clinics: {len(clinics)}")
    print(f"  - General Hospitals: {len(hospitals)}")
    print(f"  - Public Facilities: {sum(1 for x in cleaned if x['is_public'])}")
    print(f"  - Private Facilities: {sum(1 for x in cleaned if not x['is_public'])}")

if __name__ == "__main__":
    clean_and_export()
