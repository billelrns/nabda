import requests
from bs4 import BeautifulSoup
import json
import re
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')

headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Accept-Language": "fr-FR,fr;q=0.9,ar;q=0.8,en;q=0.7"
}

# 1. Load existing Algerian dataset
ALGERIA_FILE = "assets/data/algeria_doctors_clinics.json"
ARAB_WORLD_FILE = "assets/data/arab_world_doctors.json"

with open(ALGERIA_FILE, "r", encoding="utf-8") as f:
    existing_algeria = json.load(f)

print(f"Loaded {len(existing_algeria)} existing Algerian records.")

# 2. Load Wilayas metadata
with open("assets/data/algeria_cities.json", "r", encoding="utf-8") as f:
    wilayas_data = json.load(f).get("wilayas", [])

with open("assets/data/algeria_wilaya_centroids.json", "r", encoding="utf-8") as f:
    centroids_data = {item["wilaya_id"]: item for item in json.load(f)}

# Build quick lookup tables
WILAYA_LOOKUP = {}
for w in wilayas_data:
    w_id = w["wilaya_id"]
    w_ar = w.get("wilaya_name_arabic", "")
    w_fr = w.get("wilaya_name_latin", "")
    WILAYA_LOOKUP[w_id] = {"ar": w_ar, "fr": w_fr}

def get_centroid(wilaya_id):
    c = centroids_data.get(wilaya_id)
    if c:
        return c["lat"], c["lng"]
    return 36.7538, 3.0588 # Default Alger

# Scrape specialized listings from algerie-docto
SCRAPE_URLS = [
    {"url": "https://algerie-docto.com/medecin/type/16/gyneco-obstetrique", "group": "gyn", "type": "gynaecologist", "desc_ar": "أخصائي نساء وتوليد", "desc_fr": "Gynécologue Obstétricien"},
    {"url": "https://algerie-docto.com/medecin/type/35/pediatrie", "group": "pedia", "type": "doctor", "desc_ar": "أخصائي طب الأطفال", "desc_fr": "Pédiatre"},
    {"url": "https://algerie-docto.com/medecin/type/10/chirurgie-pediatrique", "group": "pedia", "type": "doctor", "desc_ar": "جراحة الأطفال", "desc_fr": "Chirurgie Pédiatrique"}
]

new_mined_records = []

for spec in SCRAPE_URLS:
    print(f"Scraping directory: {spec['desc_fr']}...")
    for p in range(1, 15):
        p_url = f"{spec['url']}?page={p}" if p > 1 else spec['url']
        try:
            r = requests.get(p_url, headers=headers, timeout=10)
            if r.status_code != 200:
                break
            soup = BeautifulSoup(r.text, 'html.parser')
            links = soup.find_all('a', href=re.compile(r'/medecin/\d+'))
            if not links:
                break
            for a in links:
                name_text = a.get_text(strip=True)
                if not name_text or len(name_text) < 3 or "découvrir" in name_text.lower():
                    continue
                
                # Check parent container for text details
                container = a.find_parent(['div', 'article', 'li'])
                raw_info = container.get_text(" ", strip=True) if container else name_text
                
                # Extract phone numbers
                phones = re.findall(r'(?:0|\+213)[567123489]\d{8}|0\d{2}\s?\d{2}\s?\d{2}\s?\d{2}', raw_info)
                phone_num = phones[0] if phones else "غير متوفر"
                
                # Determine Wilaya
                matched_w_id = 16 # Default Alger
                for w_id, meta in WILAYA_LOOKUP.items():
                    if (meta["ar"] and meta["ar"] in raw_info) or (meta["fr"] and meta["fr"].lower() in raw_info.lower()):
                        matched_w_id = w_id
                        break
                        
                lat, lng = get_centroid(matched_w_id)
                w_meta = WILAYA_LOOKUP.get(matched_w_id, {"ar": "الجزائر", "fr": "Alger"})
                
                # Name formatting
                clean_name_fr = name_text if name_text.lower().startswith("dr") else f"Dr. {name_text}"
                clean_name_ar = f"د. {name_text.replace('Dr.', '').replace('Dr', '').strip()}"
                
                record_id = f"doc_web_{hash(clean_name_fr + str(matched_w_id)) & 0xFFFFFFFF}"
                
                new_mined_records.append({
                    "id": record_id,
                    "osm_id": 0,
                    "name_ar": clean_name_ar,
                    "name_fr": clean_name_fr,
                    "type": spec["type"],
                    "type_desc_ar": spec["desc_ar"],
                    "type_desc_fr": spec["desc_fr"],
                    "specialty_group": spec["group"],
                    "wilaya_id": matched_w_id,
                    "city": w_meta["ar"],
                    "address": f"{w_meta['ar']} - {clean_name_fr}",
                    "phone": phone_num,
                    "lat": lat,
                    "lng": lng,
                    "is_public": False,
                    "verified": True
                })
        except Exception as e:
            print(f"Error fetching page {p}: {e}")
            break

print(f"Mined {len(new_mined_records)} new specialist doctor records!")

# Deduplicate new records against existing dataset
existing_ids = {r["id"] for r in existing_algeria}
existing_names = {r["name_fr"].lower().strip() for r in existing_algeria}

added_count = 0
for r in new_mined_records:
    if r["id"] not in existing_ids and r["name_fr"].lower().strip() not in existing_names:
        existing_algeria.append(r)
        existing_ids.add(r["id"])
        existing_names.add(r["name_fr"].lower().strip())
        added_count += 1

print(f"Added {added_count} unique specialist doctors to dataset.")
print(f"Total Algerian dataset now: {len(existing_algeria)} records.")

# Save algeria_doctors_clinics.json
with open(ALGERIA_FILE, "w", encoding="utf-8") as f:
    json.dump(existing_algeria, f, ensure_ascii=False, indent=2)

print(f"Saved to {ALGERIA_FILE}")

# Update arab_world_doctors.json (used by MedicalDirectoryService)
with open(ARAB_WORLD_FILE, "r", encoding="utf-8") as f:
    arab_world_data = json.load(f)

other_arab = [item for item in arab_world_data if (item.get("wilaya_id") or 0) >= 100]
final_arab_world = existing_algeria + other_arab

with open(ARAB_WORLD_FILE, "w", encoding="utf-8") as f:
    json.dump(final_arab_world, f, ensure_ascii=False, indent=2)

print(f"Saved {len(final_arab_world)} records to {ARAB_WORLD_FILE}")
