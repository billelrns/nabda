import json
import requests
import os
import time

def fetch_algeria_all_specialties():
    url = "https://overpass-api.de/api/interpreter"
    
    # Overpass QL query to find:
    # 1. Gynaecology/Obstetrics specialists (doctors, clinics, hospitals)
    # 2. Pediatrics/Child health specialists (doctors, clinics, hospitals)
    # 3. All general doctors, clinics, and hospitals in Algeria
    query = """
    [out:json][timeout:300];
    area["ISO3166-1"="DZ"]->.searchArea;
    (
      // Gynaecology & Obstetrics
      nwr["healthcare:speciality"="gynaecology"](area.searchArea);
      nwr["speciality"="gynaecology"](area.searchArea);
      nwr["healthcare:speciality"="obstetrics"](area.searchArea);
      nwr["speciality"="obstetrics"](area.searchArea);
      
      // Pediatrics & Child care
      nwr["healthcare:speciality"="pediatrics"](area.searchArea);
      nwr["speciality"="pediatrics"](area.searchArea);
      nwr["healthcare:speciality"="paediatrics"](area.searchArea);
      nwr["speciality"="paediatrics"](area.searchArea);
      nwr["healthcare:speciality"="child_health"](area.searchArea);
      
      // General Doctors & Clinics & Hospitals
      nwr["amenity"="doctors"](area.searchArea);
      nwr["amenity"="clinic"](area.searchArea);
      nwr["amenity"="hospital"](area.searchArea);
      
      // Healthcare tags
      nwr["healthcare"="doctor"](area.searchArea);
      nwr["healthcare"="clinic"](area.searchArea);
      nwr["healthcare"="hospital"](area.searchArea);
      nwr["healthcare"="centre_de_sante"](area.searchArea);
    );
    out center;
    """
    
    headers = {
        "User-Agent": "NabdaAppMedicalDirectory/2.0 (info@nabda.app)",
        "Accept": "application/json"
    }
    print("Sending comprehensive medical query to Overpass API for Algeria...")
    
    try:
        response = requests.post(url, data={'data': query}, headers=headers, timeout=360)
        response.raise_for_status()
        data = response.json()
        
        elements = data.get('elements', [])
        print(f"Successfully fetched {len(elements)} raw elements from OpenStreetMap.")
        
        os.makedirs("scratch", exist_ok=True)
        raw_path = "scratch/raw_medical_all.json"
        with open(raw_path, "w", encoding="utf-8") as f:
            json.dump(elements, f, ensure_ascii=False, indent=2)
        print(f"Raw data saved to {raw_path}")
        
    except Exception as e:
        print(f"Error fetching from Overpass API: {e}")

if __name__ == "__main__":
    fetch_algeria_all_specialties()
