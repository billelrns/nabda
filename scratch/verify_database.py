import json
import sys

# Force stdout encoding to utf-8 for Windows console
sys.stdout.reconfigure(encoding='utf-8')

def verify():
    path = "assets/data/algeria_doctors_clinics.json"
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
        
    print(f"Total Facilities: {len(data)}")
    
    by_group = {}
    by_wilaya = {}
    with_phone = 0
    with_city = 0
    
    for item in data:
        grp = item.get("specialty_group", "unknown")
        by_group[grp] = by_group.get(grp, 0) + 1
        
        wid = item.get("wilaya_id", 0)
        by_wilaya[wid] = by_wilaya.get(wid, 0) + 1
        
        if item.get("phone") and item["phone"] != "غير متوفر":
            with_phone += 1
            
        if item.get("city") and item["city"] != "غير محدد":
            with_city += 1

    print("\n--- Specialty Breakdown ---")
    print(f"  OB/GYN (نساء وتوليد): {by_group.get('gyn', 0)}")
    print(f"  Pediatrics (طب الأطفال): {by_group.get('pedia', 0)}")
    print(f"  Maternity & Children Centers (أمومة وطفولة): {by_group.get('maternity', 0)}")
    print(f"  General Clinics/Hospitals: {by_group.get('general', 0)}")

    print("\n--- Coverage Metrics ---")
    print(f"  Facilities with valid contact phone: {with_phone} / {len(data)}")
    print(f"  Facilities mapped to Commune/City: {with_city} / {len(data)}")
    print(f"  Total Wilayas with active medical records: {len(by_wilaya)} / 58")

if __name__ == "__main__":
    verify()
