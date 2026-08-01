import json
import urllib.request
import urllib.parse
import time
import os
import math

# Major Arab countries configuration
ARAB_COUNTRIES = {
    "Egypt": {"name_ar": "مصر", "lat": 26.8206, "lon": 30.8025},
    "Saudi Arabia": {"name_ar": "السعودية", "lat": 23.8859, "lon": 45.0792},
    "Morocco": {"name_ar": "المغرب", "lat": 31.7917, "-7.0926": -7.0926}, # fix longitude key
    "Tunisia": {"name_ar": "تونس", "lat": 33.8869, "lon": 9.5375},
    "Libya": {"name_ar": "ليبيا", "lat": 26.3351, "lon": 17.2283},
    "Sudan": {"name_ar": "السودان", "lat": 12.8628, "lon": 30.2176},
    "Syria": {"name_ar": "سوريا", "lat": 34.8021, "lon": 38.9968},
    "Iraq": {"name_ar": "العراق", "lat": 33.2232, "lon": 43.6793},
    "Jordan": {"name_ar": "الأردن", "lat": 31.2401, "lon": 36.5106},
    "Lebanon": {"name_ar": "لبنان", "lat": 33.8547, "lon": 35.8623},
    "Palestine": {"name_ar": "فلسطين", "lat": 31.9522, "lon": 35.2332},
    "Yemen": {"name_ar": "اليمن", "lat": 15.5527, "lon": 48.5164},
    "Oman": {"name_ar": "عمان", "lat": 21.4735, "lon": 55.9754},
    "United Arab Emirates": {"name_ar": "الإمارات", "lat": 23.4241, "lon": 53.8478},
    "Kuwait": {"name_ar": "الكويت", "lat": 29.3117, "lon": 47.4818},
    "Qatar": {"name_ar": "قطر", "lat": 25.3548, "lon": 51.1839},
    "Bahrain": {"name_ar": "البحرين", "lat": 26.0667, "lon": 50.5500},
    "Mauritania": {"name_ar": "موريتانيا", "lat": 21.0079, "lon": -10.9408}
}

# Fix Morocco longitude key
ARAB_COUNTRIES["Morocco"] = {"name_ar": "المغرب", "lat": 31.7917, "lon": -7.0926}

# List of major Arab cities for offline reverse-geocoding (city fallback)
MAJOR_CITIES = [
    # Egypt
    {"name_ar": "القاهرة", "name_en": "Cairo", "country": "Egypt", "lat": 30.0444, "lon": 31.2357},
    {"name_ar": "الإسكندرية", "name_en": "Alexandria", "country": "Egypt", "lat": 31.2001, "lon": 29.9187},
    {"name_ar": "الجيزة", "name_en": "Giza", "country": "Egypt", "lat": 30.0131, "lon": 31.2089},
    {"name_ar": "شبرا الخيمة", "name_en": "Shubra El-Kheima", "country": "Egypt", "lat": 30.1286, "lon": 31.2422},
    {"name_ar": "بورسعيد", "name_en": "Port Said", "country": "Egypt", "lat": 31.2565, "lon": 32.2841},
    {"name_ar": "السويس", "name_en": "Suez", "country": "Egypt", "lat": 29.9668, "lon": 32.5498},
    {"name_ar": "المنصورة", "name_en": "Mansoura", "country": "Egypt", "lat": 31.0409, "lon": 31.3785},
    {"name_ar": "المحلة الكبرى", "name_en": "El Mahalla El Kubra", "country": "Egypt", "lat": 30.9763, "lon": 31.1686},
    {"name_ar": "طنطا", "name_en": "Tanta", "country": "Egypt", "lat": 30.7865, "lon": 31.0004},
    {"name_ar": "أسيوط", "name_en": "Asyut", "country": "Egypt", "lat": 27.1783, "lon": 31.1849},
    {"name_ar": "الفيوم", "name_en": "Fayoum", "country": "Egypt", "lat": 29.3084, "lon": 30.8422},
    {"name_ar": "الزقازيق", "name_en": "Zagazig", "country": "Egypt", "lat": 30.5877, "lon": 31.5174},
    {"name_ar": "الإسماعيلية", "name_en": "Ismailia", "country": "Egypt", "lat": 30.6043, "lon": 32.2723},
    {"name_ar": "أسوان", "name_en": "Aswan", "country": "Egypt", "lat": 24.0889, "lon": 32.8998},
    {"name_ar": "الأقصر", "name_en": "Luxor", "country": "Egypt", "lat": 25.6872, "lon": 32.6396},
    # Saudi Arabia
    {"name_ar": "الرياض", "name_en": "Riyadh", "country": "Saudi Arabia", "lat": 24.7136, "lon": 46.6753},
    {"name_ar": "جدة", "name_en": "Jeddah", "country": "Saudi Arabia", "lat": 21.5433, "lon": 39.1728},
    {"name_ar": "مكة المكرمة", "name_en": "Mecca", "country": "Saudi Arabia", "lat": 21.3891, "lon": 39.8579},
    {"name_ar": "المدينة المنورة", "name_en": "Medina", "country": "Saudi Arabia", "lat": 24.5246, "lon": 39.5692},
    {"name_ar": "الدمام", "name_en": "Dammam", "country": "Saudi Arabia", "lat": 26.4207, "lon": 50.0888},
    {"name_ar": "الخبر", "name_en": "Khobar", "country": "Saudi Arabia", "lat": 26.2764, "lon": 50.2082},
    {"name_ar": "الطائف", "name_en": "Taif", "country": "Saudi Arabia", "lat": 21.2854, "lon": 40.4062},
    {"name_ar": "تبوك", "name_en": "Tabuk", "country": "Saudi Arabia", "lat": 28.3835, "lon": 36.5662},
    {"name_ar": "بريدة", "name_en": "Buraidah", "country": "Saudi Arabia", "lat": 26.3260, "lon": 43.9750},
    {"name_ar": "خميس مشيط", "name_en": "Khamis Mushait", "country": "Saudi Arabia", "lat": 18.3064, "lon": 42.7281},
    {"name_ar": "الهفوف", "name_en": "Hafouf", "country": "Saudi Arabia", "lat": 25.3782, "lon": 49.5880},
    # Morocco
    {"name_ar": "الدار البيضاء", "name_en": "Casablanca", "country": "Morocco", "lat": 33.5731, "lon": -7.5898},
    {"name_ar": "الرباط", "name_en": "Rabat", "country": "Morocco", "lat": 34.0209, "lon": -6.8417},
    {"name_ar": "مراكش", "name_en": "Marrakech", "country": "Morocco", "lat": 31.6295, "lon": -7.9811},
    {"name_ar": "فاس", "name_en": "Fes", "country": "Morocco", "lat": 34.0331, "lon": -5.0003},
    {"name_ar": "طنجة", "name_en": "Tangier", "country": "Morocco", "lat": 35.7595, "lon": -5.8340},
    {"name_ar": "أغادير", "name_en": "Agadir", "country": "Morocco", "lat": 30.4278, "lon": -9.5981},
    {"name_ar": "مكناس", "name_en": "Meknes", "country": "Morocco", "lat": 33.8938, "lon": -5.5547},
    {"name_ar": "وجدة", "name_en": "Oujda", "country": "Morocco", "lat": 34.6867, "lon": -1.9114},
    {"name_ar": "القنيطرة", "name_en": "Kenitra", "country": "Morocco", "lat": 34.2610, "lon": -6.5802},
    {"name_ar": "تطوان", "name_en": "Tetouan", "country": "Morocco", "lat": 35.5889, "lon": -5.3626},
    # Tunisia
    {"name_ar": "تونس", "name_en": "Tunis", "country": "Tunisia", "lat": 36.8065, "lon": 10.1815},
    {"name_ar": "صفاقس", "name_en": "Sfax", "country": "Tunisia", "lat": 34.7406, "lon": 10.7603},
    {"name_ar": "سوسة", "name_en": "Sousse", "country": "Tunisia", "lat": 35.8256, "lon": 10.6369},
    {"name_ar": "القيروان", "name_en": "Kairouan", "country": "Tunisia", "lat": 35.6781, "lon": 10.0963},
    {"name_ar": "بنزرت", "name_en": "Bizerte", "country": "Tunisia", "lat": 37.2744, "lon": 9.8739},
    {"name_ar": "قابس", "name_en": "Gabes", "country": "Tunisia", "lat": 33.8815, "lon": 10.0982},
    # Libya
    {"name_ar": "طرابلس", "name_en": "Tripoli", "country": "Libya", "lat": 32.8872, "lon": 13.1913},
    {"name_ar": "بنغازي", "name_en": "Benghazi", "country": "Libya", "lat": 32.1150, "lon": 20.0686},
    {"name_ar": "مصراتة", "name_en": "Misrata", "country": "Libya", "lat": 32.3754, "lon": 15.0925},
    {"name_ar": "الزاوية", "name_en": "Zawiya", "country": "Libya", "lat": 32.7522, "lon": 12.7278},
    # Sudan
    {"name_ar": "الخرطوم", "name_en": "Khartoum", "country": "Sudan", "lat": 15.5007, "lon": 32.5599},
    {"name_ar": "أم درمان", "name_en": "Omdurman", "country": "Sudan", "lat": 15.6500, "lon": 32.4833},
    {"name_ar": "بورتسودان", "name_en": "Port Sudan", "country": "Sudan", "lat": 19.6158, "lon": 37.2164},
    # Syria
    {"name_ar": "دمشق", "name_en": "Damascus", "country": "Syria", "lat": 33.5138, "lon": 36.2765},
    {"name_ar": "حلب", "name_en": "Aleppo", "country": "Syria", "lat": 36.2021, "lon": 37.1343},
    {"name_ar": "حمص", "name_en": "Homs", "country": "Syria", "lat": 34.7324, "lon": 36.7137},
    {"name_ar": "اللاذقية", "name_en": "Latakia", "country": "Syria", "lat": 35.5312, "lon": 35.7908},
    {"name_ar": "حماة", "name_en": "Hama", "country": "Syria", "lat": 35.1318, "lon": 36.7578},
    # Iraq
    {"name_ar": "بغداد", "name_en": "Baghdad", "country": "Iraq", "lat": 33.3152, "lon": 44.3661},
    {"name_ar": "البصرة", "name_en": "Basra", "country": "Iraq", "lat": 30.5081, "lon": 47.7835},
    {"name_ar": "الموصل", "name_en": "Mosul", "country": "Iraq", "lat": 36.3489, "lon": 43.1577},
    {"name_ar": "أربيل", "name_en": "Erbil", "country": "Iraq", "lat": 36.1901, "lon": 44.0093},
    {"name_ar": "السليمانية", "name_en": "Sulaymaniyah", "country": "Iraq", "lat": 35.5560, "lon": 45.4333},
    # Jordan
    {"name_ar": "عمان", "name_en": "Amman", "country": "Jordan", "lat": 31.9454, "lon": 35.9284},
    {"name_ar": "الزرقاء", "name_en": "Zarqa", "country": "Jordan", "lat": 32.0608, "lon": 36.0872},
    {"name_ar": "إربد", "name_en": "Irbid", "country": "Jordan", "lat": 32.5556, "lon": 35.8500},
    {"name_ar": "العقبة", "name_en": "Aqaba", "country": "Jordan", "lat": 29.5267, "lon": 35.0078},
    # Lebanon
    {"name_ar": "بيروت", "name_en": "Beirut", "country": "Lebanon", "lat": 33.8938, "lon": 35.5018},
    {"name_ar": "طرابلس", "name_en": "Tripoli", "country": "Lebanon", "lat": 34.4367, "lon": 35.8497},
    {"name_ar": "صيدا", "name_en": "Sidon", "country": "Lebanon", "lat": 33.5631, "lon": 35.3728},
    # Palestine
    {"name_ar": "القدس", "name_en": "Jerusalem", "country": "Palestine", "lat": 31.7683, "lon": 35.2137},
    {"name_ar": "غزة", "name_en": "Gaza", "country": "Palestine", "lat": 31.5016, "lon": 34.4668},
    {"name_ar": "رام الله", "name_en": "Ramallah", "country": "Palestine", "lat": 31.9029, "lon": 35.2033},
    {"name_ar": "نابلس", "name_en": "Nablus", "country": "Palestine", "lat": 32.2211, "lon": 35.2544},
    {"name_ar": "الخليل", "name_en": "Hebron", "country": "Palestine", "lat": 31.5292, "lon": 35.0938},
    # Yemen
    {"name_ar": "صنعاء", "name_en": "Sana'a", "country": "Yemen", "lat": 15.3694, "lon": 44.1910},
    {"name_ar": "عدن", "name_en": "Aden", "country": "Yemen", "lat": 12.7855, "lon": 45.0186},
    {"name_ar": "تعز", "name_en": "Taiz", "country": "Yemen", "lat": 13.5795, "lon": 44.0206},
    # Oman
    {"name_ar": "مسقط", "name_en": "Muscat", "country": "Oman", "lat": 23.5859, "lon": 58.4059},
    {"name_ar": "صلالة", "name_en": "Salalah", "country": "Oman", "lat": 17.0151, "lon": 54.0924},
    {"name_ar": "صهار", "name_en": "Sohar", "country": "Oman", "lat": 24.3461, "lon": 56.7075},
    # United Arab Emirates
    {"name_ar": "دبي", "name_en": "Dubai", "country": "United Arab Emirates", "lat": 25.2048, "lon": 55.2708},
    {"name_ar": "أبوظبي", "name_en": "Abu Dhabi", "country": "United Arab Emirates", "lat": 24.4539, "lon": 54.3773},
    {"name_ar": "الشارقة", "name_en": "Sharjah", "country": "United Arab Emirates", "lat": 25.3463, "lon": 55.4209},
    {"name_ar": "العين", "name_en": "Al Ain", "country": "United Arab Emirates", "lat": 24.1302, "lon": 55.8023},
    # Kuwait
    {"name_ar": "مدينة الكويت", "name_en": "Kuwait City", "country": "Kuwait", "lat": 29.3759, "lon": 47.9774},
    {"name_ar": "حولي", "name_en": "Hawally", "country": "Kuwait", "lat": 29.3392, "lon": 48.0169},
    # Qatar
    {"name_ar": "الدوحة", "name_en": "Doha", "country": "Qatar", "lat": 25.2854, "lon": 51.5310},
    {"name_ar": "الريان", "name_en": "Al Rayyan", "country": "Qatar", "lat": 25.2917, "lon": 51.4244},
    # Bahrain
    {"name_ar": "المنامة", "name_en": "Manama", "country": "Bahrain", "lat": 26.2285, "lon": 50.5860},
    {"name_ar": "المحرق", "name_en": "Muharraq", "country": "Bahrain", "lat": 26.2572, "lon": 50.6119},
    # Mauritania
    {"name_ar": "نواكشوط", "name_en": "Nouakchott", "country": "Mauritania", "lat": 18.0735, "lon": -15.9582}
]

def calculate_distance(lat1, lon1, lat2, lon2):
    return math.sqrt((lat1 - lat2)**2 + (lon1 - lon2)**2)

def find_closest_city(lat, lon, country_name):
    # Filter cities by country
    country_cities = [c for c in MAJOR_CITIES if c["country"] == country_name]
    if not country_cities:
        # Fallback to capital of that country or first matched city
        for c in MAJOR_CITIES:
            if c["country"] == country_name:
                return c["name_ar"], c["name_en"]
        return "غير محدد", "Unknown"
        
    closest_city = None
    min_dist = float("inf")
    
    for c in country_cities:
        dist = calculate_distance(lat, lon, c["lat"], c["lon"])
        if dist < min_dist:
            min_dist = dist
            closest_city = c
            
    return closest_city["name_ar"], closest_city["name_en"]

def query_country_data(country_name, country_details):
    print(f"\n--- Fetching data for {country_name} ({country_details['name_ar']}) ---")
    
    query = f"""[out:json][timeout:120];
area["name:en"="{country_name}"]->.searchArea;
(
  node["healthcare"="gynaecology"](area.searchArea);
  node["healthcare:speciality"~"gynaecology|obstetrics"](area.searchArea);
  node["amenity"="doctors"]["speciality"="gynaecology"](area.searchArea);
  
  way["healthcare"="gynaecology"](area.searchArea);
  way["healthcare:speciality"~"gynaecology|obstetrics"](area.searchArea);
  way["amenity"="doctors"]["speciality"="gynaecology"](area.searchArea);
);
out center;"""

    url = "https://overpass-api.de/api/interpreter"
    data = urllib.parse.urlencode({"data": query}).encode("utf-8")
    
    req = urllib.request.Request(url, data=data, headers={"User-Agent": "NabdaArabWorldDataExtractor/1.0"})
    
    retries = 3
    for attempt in range(retries):
        try:
            with urllib.request.urlopen(req) as response:
                result = json.loads(response.read().decode("utf-8"))
                return result.get("elements", [])
        except Exception as e:
            print(f"Attempt {attempt+1} failed for {country_name}: {e}")
            if attempt < retries - 1:
                time.sleep(10 * (attempt + 1))
            else:
                print(f"Skipping {country_name} due to repeated errors.")
                return []

def main():
    arab_doctors = []
    
    # Let's check if the existing database for Algeria is present, and load it to keep it intact!
    existing_algeria_path = "assets/data/algeria_doctors_clinics.json"
    algeria_loaded = False
    
    if os.path.exists(existing_algeria_path):
        try:
            with open(existing_algeria_path, "r", encoding="utf-8") as f:
                algeria_data = json.load(f)
                
            # Add country tags to Algeria data
            for item in algeria_data:
                item["country_name_ar"] = "الجزائر"
                item["country_name_en"] = "Algeria"
                arab_doctors.append(item)
                
            print(f"Loaded {len(algeria_data)} records for Algeria from existing database.")
            algeria_loaded = True
        except Exception as e:
            print(f"Could not load existing Algeria database: {e}")

    # Fetch data for other countries
    for country, details in ARAB_COUNTRIES.items():
        if country == "Algeria" and algeria_loaded:
            # We already loaded Algeria from the high-quality local file
            continue
            
        elements = query_country_data(country, details)
        print(f"Found {len(elements)} raw elements for {country}.")
        
        country_skipped = 0
        country_added = 0
        
        for el in elements:
            tags = el.get("tags", {})
            
            # Position
            lat = el.get("lat") or (el.get("center", {}).get("lat") if "center" in el else None)
            lon = el.get("lon") or (el.get("center", {}).get("lon") if "center" in el else None)
            
            if not lat or not lon:
                continue
                
            # Name
            name = tags.get("name", "").strip()
            name_ar = tags.get("name:ar", "").strip() or tags.get("name", "").strip()
            name_fr = tags.get("name:en", "").strip() or tags.get("name:fr", "").strip() or name
            
            phone = tags.get("phone") or tags.get("contact:phone") or "غير متوفر"
            
            # Determine if it's generic and nameless
            is_generic = name.lower() in [
                "", "cabinet medical", "cabinet médical", "médecin", "médécin", 
                "dispensaire", "polyclinique", "hôpital", "clinic", "doctors", 
                "hospital", "gynécologue", "gynecologue", "cabinet de gynecologie", 
                "cabinet de gynécologie", "عيادة/طبيب غير مسمى", "عيادة طب نساء", 
                "أخصائي نساء وتوليد", "طب نساء وتوليد"
            ] or not name
            
            # Filter generic nameless items without phones
            if is_generic and phone == "غير متوفر":
                country_skipped += 1
                continue
                
            # Formatting generic names
            amenity = tags.get("amenity") or tags.get("healthcare")
            is_structure = amenity in ["hospital", "clinic", "university"] or "مستشفى" in name_ar or "مستوصف" in name_ar or "مصلحة" in name_ar
            
            if is_generic:
                if is_structure:
                    name_display_ar = "عيادة أمراض النساء والتوليد"
                    name_display_en = "Gynaecology and Obstetrics Center"
                else:
                    name_display_ar = "عيادة أمراض النساء والتوليد الخاصة"
                    name_display_en = "Private Gynaecology Clinic"
            else:
                name_display_ar = name_ar
                name_display_en = name_fr
                
            # Correct spelling
            name_display_ar = name_display_ar.replace("الاستعمالات الطبية", "الاستعجالات الطبية")
            name_display_ar = name_display_ar.replace("الاستعمالات طبية", "الاستعجالات الطبية")
            name_display_ar = name_display_ar.replace("مصلحة الاستعمالات", "مصلحة الاستعجالات")

            # Determine category / type
            # If name has "hospital" or "مستشفى", type is hospital, otherwise clinic or doctor
            type_str = "gynaecologist"
            if is_structure:
                if any(k in name_display_ar for k in ["مستشفى", "مؤسسة", "المؤسسة", "eph", "chu", "hospital"]):
                    type_str = "hospital"
                else:
                    type_str = "clinic"
                    
            type_desc_ar = "أخصائي نساء وتوليد"
            if type_str == "hospital":
                type_desc_ar = "مستشفى / مركز صحي عمومي"
            elif type_str == "clinic":
                type_desc_ar = "عيادة طبية نساء وتوليد"

            # Assign to closest city
            city_ar, city_en = find_closest_city(lat, lon, country)
            
            addr_street = tags.get("addr:street") or tags.get("addr:place") or ""
            address = f"{addr_street}, {city_ar}" if addr_street else city_ar
            
            is_public = False
            if type_str == "hospital":
                is_public = True
            
            COUNTRY_CODES = {
                "Algeria": 0,
                "Egypt": 100,
                "Saudi Arabia": 101,
                "Morocco": 102,
                "Tunisia": 103,
                "Libya": 104,
                "Sudan": 105,
                "Syria": 106,
                "Iraq": 107,
                "Jordan": 108,
                "Lebanon": 109,
                "Palestine": 110,
                "Yemen": 111,
                "Oman": 112,
                "United Arab Emirates": 113,
                "Kuwait": 114,
                "Qatar": 115,
                "Bahrain": 116,
                "Mauritania": 117
            }

            arab_doctors.append({
                "id": f"{el.get('type', 'node')}_{el.get('id')}",
                "name_ar": name_display_ar,
                "name_fr": name_display_en,
                "lat": lat,
                "lon": lon,
                "phone": phone,
                "address": f"{address} ({details['name_ar']})",
                "city": city_ar,
                "wilaya_id": COUNTRY_CODES.get(country, 999),
                "wilaya_name_ar": details["name_ar"],
                "wilaya_name_fr": country,
                "country_name_ar": details["name_ar"],
                "country_name_en": country,
                "type": type_str,
                "type_desc_ar": type_desc_ar,
                "is_public": is_public,
                "website": tags.get("website") or "غير متوفر"
            })
            country_added += 1
            
        print(f"Country {country}: Added {country_added} records, skipped {country_skipped} generic nameless records.")
        time.sleep(2)  # Avoid rate limits on Overpass API

    # Save to unified database
    output_path = "assets/data/arab_world_doctors.json"
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(arab_doctors, f, ensure_ascii=False, indent=2)
        
    print(f"\nSaved {len(arab_doctors)} total Arab World gynecologists to {output_path}.")

if __name__ == "__main__":
    main()
