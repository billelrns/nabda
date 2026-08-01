import requests
from bs4 import BeautifulSoup
import json
import re
import os
import sys
import time

sys.stdout.reconfigure(encoding='utf-8')

headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Accept-Language": "fr-FR,fr;q=0.9,ar;q=0.8,en;q=0.7"
}

BASE_URL = "https://algerie-docto.com"

CATEGORIES = [
    {"url": "/medecin/type/16/gyneco-obstetrique", "group": "gyn", "type": "gynaecologist", "desc_ar": "أخصائي نساء وتوليد", "desc_fr": "Gynécologue Obstétricien"},
    {"url": "/medecin/type/35/pediatrie", "group": "pedia", "type": "doctor", "desc_ar": "أخصائي طب الأطفال", "desc_fr": "Pédiatre"},
    {"url": "/medecin/type/10/chirurgie-pediatrique", "group": "pedia", "type": "doctor", "desc_ar": "جراحة الأطفال", "desc_fr": "Chirurgie Pédiatrique"}
]

# Load Wilayas & Cities mapping
with open("assets/data/algeria_cities.json", "r", encoding="utf-8") as f:
    ALGERIA_CITIES = json.load(f).get("wilayas", [])

with open("assets/data/algeria_wilaya_centroids.json", "r", encoding="utf-8") as f:
    WILAYA_CENTROIDS = {item["wilaya_id"]: item for item in json.load(f)}

def extract_wilaya(text):
    text_lower = text.lower()
    for wilaya in ALGERIA_CITIES:
        w_name_ar = wilaya.get("wilaya_name_arabic", "")
        w_name_fr = wilaya.get("wilaya_name_latin", "").lower()
        if (w_name_ar and w_name_ar in text) or (w_name_fr and w_name_fr in text_lower):
            return wilaya["wilaya_id"], w_name_ar, wilaya.get("wilaya_name_latin", "Alger")
        for commune in wilaya.get("communes", []):
            c_ar = commune.get("commune_name_arabic", "")
            c_fr = commune.get("commune_name_latin", "").lower()
            if (c_ar and c_ar in text) or (c_fr and len(c_fr) > 3 and c_fr in text_lower):
                return wilaya["wilaya_id"], w_name_ar, wilaya.get("wilaya_name_latin", "Alger")
    return 16, "الجزائر", "Alger" # Default to Alger if unspecified

def scrape_category(cat):
    print(f"\n--- Scraping {cat['desc_fr']} ({cat['desc_ar']}) ---")
    doctors = []
    page = 1
    
    while page <= 10: # Fetch up to 10 pages per specialty
        page_url = f"{BASE_URL}{cat['url']}" if page == 1 else f"{BASE_URL}{cat['url']}?page={page}"
        print(f"Fetching Page {page}: {page_url}")
        
        try:
            r = requests.get(page_url, headers=headers, timeout=15)
            if r.status_code != 200:
                print(f"Page {page} returned status {r.status_code}. Stopping category.")
                break
                
            soup = BeautifulSoup(r.text, 'html.parser')
            # Look for doctor list items
            items = soup.find_all(['div', 'article', 'li'], class_=re.compile(r'medecin|doctor|card|item', re.I))
            if not items:
                # Try finding all links to doctor detail pages
                doc_links = soup.find_all('a', href=re.compile(r'/medecin/\d+'))
                if not doc_links:
                    print(f"No more items found on page {page}.")
                    break
                    
                print(f"Found {len(doc_links)} doctor links on page {page}")
                for link in doc_links:
                    d_url = link['href']
                    if not d_url.startswith('http'):
                        d_url = BASE_URL + d_url
                    name = link.get_text(strip=True)
                    if name and len(name) > 3:
                        doctors.append({
                            "name": name,
                            "url": d_url,
                            "raw_text": link.parent.get_text(" ", strip=True) if link.parent else name
                        })
            else:
                for item in items:
                    text = item.get_text(" ", strip=True)
                    link = item.find('a', href=re.compile(r'/medecin/\d+'))
                    d_url = link['href'] if link else ""
                    if d_url and not d_url.startswith('http'):
                        d_url = BASE_URL + d_url
                    doctors.append({
                        "name": link.get_text(strip=True) if link else "Dr. Specialiste",
                        "url": d_url,
                        "raw_text": text
                    })
            page += 1
            time.sleep(0.5)
        except Exception as e:
            print(f"Error fetching page {page}: {e}")
            break
            
    print(f"Total raw items collected for {cat['desc_fr']}: {len(doctors)}")
    return doctors

def parse_doctor_details(doc, cat):
    raw_text = doc.get("raw_text", "")
    name = doc.get("name", "").strip()
    
    # Extract phone numbers
    phones = re.findall(r'(?:0|\+213)[567123489]\d{8}|0\d{2}\s?\d{2}\s?\d{2}\s?\d{2}', raw_text)
    clean_phone = phones[0] if phones else "غير متوفر"
    
    # Extract Wilaya
    wilaya_id, wilaya_ar, wilaya_fr = extract_wilaya(raw_text)
    centroid = WILAYA_CENTROIDS.get(wilaya_id, {"lat": 36.7538, "lng": 3.0588})
    
    # Format Doctor Name
    if not name.lower().startswith("dr") and not name.startswith("د.") and not name.startswith("طبيب"):
        name_fr = f"Dr. {name}"
        name_ar = f"د. {name}"
    else:
        name_fr = name
        name_ar = name
        
    facility_id = f"doc_ad_{hash(doc['url']) & 0xFFFFFFFF}"
    
    return {
        "id": facility_id,
        "osm_id": 0,
        "name_ar": name_ar,
        "name_fr": name_fr,
        "type": cat["type"],
        "type_desc_ar": cat["desc_ar"],
        "type_desc_fr": cat["desc_fr"],
        "specialty_group": cat["group"],
        "wilaya_id": wilaya_id,
        "city": wilaya_ar,
        "address": f"{wilaya_ar} - {name_fr}",
        "phone": clean_phone,
        "lat": centroid["lat"],
        "lng": centroid["lng"],
        "is_public": False,
        "verified": True,
        "source": "algerie-docto"
    }

def run_scraper():
    all_extracted = []
    for cat in CATEGORIES:
        docs = scrape_category(cat)
        for doc in docs:
            parsed = parse_doctor_details(doc, cat)
            all_extracted.append(parsed)
            
    print(f"\nSuccessfully extracted and formatted {len(all_extracted)} specialists from Algerie-Docto!")
    
    # Save scraped dataset
    output_path = "scratch/scraped_specialists.json"
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(all_extracted, f, ensure_ascii=False, indent=2)
    print(f"Saved to {output_path}")

if __name__ == "__main__":
    run_scraper()
