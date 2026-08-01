import json
import requests
import os

def fetch_algeria_medical():
    url = "https://overpass-api.de/api/interpreter"
    
    # Overpass QL query to find:
    # 1. Gynaecology/Obstetrics specialists (doctors, clinics, etc.)
    # 2. General clinics and hospitals in Algeria
    query = """
    [out:json][timeout:240];
    area["ISO3166-1"="DZ"]->.searchArea;
    (
      // Doctors/clinics tagged specifically with gynaecology
      nwr["healthcare:speciality"="gynaecology"](area.searchArea);
      nwr["speciality"="gynaecology"](area.searchArea);
      
      // General doctors, clinics, and hospitals
      nwr["amenity"="doctors"](area.searchArea);
      nwr["amenity"="clinic"](area.searchArea);
      nwr["amenity"="hospital"](area.searchArea);
      
      // Healthcare tags
      nwr["healthcare"="doctor"](area.searchArea);
      nwr["healthcare"="clinic"](area.searchArea);
      nwr["healthcare"="hospital"](area.searchArea);
    );
    out center;
    """
    
    headers = {
        "User-Agent": "NabdaAppMedicalDirectory/1.0 (info@nabda.app)",
        "Accept": "application/json"
    }
    print("Sending request to Overpass API (this might take a minute)...")
    try:
        response = requests.post(url, data={'data': query}, headers=headers, timeout=300)
        response.raise_for_status()
        data = response.json()
        
        elements = data.get('elements', [])
        print(f"Successfully fetched {len(elements)} elements from OpenStreetMap.")
        
        # Save raw data
        os.makedirs("scratch", exist_ok=True)
        raw_path = "scratch/raw_osm_data.json"
        with open(raw_path, "w", encoding="utf-8") as f:
            json.dump(elements, f, ensure_ascii=False, indent=2)
        print(f"Raw data saved to {raw_path}")
        
        # Process elements
        processed = []
        for el in elements:
            tags = el.get('tags', {})
            
            # Extract coordinates
            lat = el.get('lat')
            lon = el.get('lon')
            if lat is None or lon is None:
                center = el.get('center')
                if center:
                    lat = center.get('lat')
                    lon = center.get('lon')
            
            if lat is None or lon is None:
                continue # Skip if no location
                
            # Extract names
            name = tags.get('name')
            name_ar = tags.get('name:ar')
            name_fr = tags.get('name:fr')
            name_en = tags.get('name:en')
            
            # Phone number
            phone = tags.get('phone') or tags.get('contact:phone') or tags.get('contact:mobile') or tags.get('mobile')
            
            # Address/Location info
            city = tags.get('addr:city') or tags.get('addr:suburb') or tags.get('addr:district')
            street = tags.get('addr:street')
            housenumber = tags.get('addr:housenumber')
            full_address = tags.get('addr:full')
            
            # Specialties and descriptions
            specialty = tags.get('healthcare:speciality') or tags.get('speciality')
            amenity = tags.get('amenity')
            healthcare = tags.get('healthcare')
            
            # Build display names
            display_name = name or name_ar or name_fr or name_en or "عيادة/طبيب غير مسمى"
            
            # Determine type
            is_gyn = False
            if (specialty and 'gynaec' in specialty.lower()) or \
               (tags.get('target_groups') == 'women') or \
               ('gyneco' in display_name.lower()) or \
               ('نساء' in display_name) or \
               ('توليد' in display_name):
                is_gyn = True
                
            type_label = "unknown"
            if amenity == "hospital" or healthcare == "hospital":
                type_label = "hospital"
            elif amenity == "clinic" or healthcare == "clinic":
                type_label = "clinic"
            elif amenity == "doctors" or healthcare == "doctor":
                type_label = "doctor"
                
            processed.append({
                "id": f"{el.get('type')}_{el.get('id')}",
                "name": display_name,
                "name_ar": name_ar,
                "name_fr": name_fr,
                "lat": lat,
                "lon": lon,
                "phone": phone or "غير متوفر",
                "city": city or "غير محدد",
                "street": street,
                "type": type_label,
                "is_gyn": is_gyn,
                "tags": {k: v for k, v in tags.items() if k in ['opening_hours', 'website', 'operator', 'description', 'healthcare:speciality', 'amenity', 'healthcare']}
            })
            
        print(f"Processed {len(processed)} valid entries with location coordinates.")
        
        # Save processed data
        processed_path = "scratch/processed_medical_data.json"
        with open(processed_path, "w", encoding="utf-8") as f:
            json.dump(processed, f, ensure_ascii=False, indent=2)
        print(f"Processed data saved to {processed_path}")
        
        # Print summary
        gyn_count = sum(1 for x in processed if x['is_gyn'])
        clinic_count = sum(1 for x in processed if x['type'] == 'clinic')
        hospital_count = sum(1 for x in processed if x['type'] == 'hospital')
        doctor_count = sum(1 for x in processed if x['type'] == 'doctor')
        print(f"Summary:")
        print(f"  - Obstetrics/Gynaecology: {gyn_count}")
        print(f"  - General Doctors: {doctor_count}")
        print(f"  - Clinics: {clinic_count}")
        print(f"  - Hospitals: {hospital_count}")
        
    except Exception as e:
        print(f"Error occurred: {e}")

if __name__ == "__main__":
    fetch_algeria_medical()
