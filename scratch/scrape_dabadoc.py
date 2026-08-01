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

BASE_URL = "https://www.dabadoc.com"

URLS = [
    {"url": "/dz/medecins/gynecologue-obstetricien", "group": "gyn", "type": "gynaecologist", "desc_ar": "أخصائي نساء وتوليد", "desc_fr": "Gynécologue Obstétricien"},
    {"url": "/dz/medecins/pediatre", "group": "pedia", "type": "doctor", "desc_ar": "أخصائي طب الأطفال", "desc_fr": "Pédiatre"},
]

# Load Wilayas & Cities mapping
with open("assets/data/algeria_cities.json", "r", encoding="utf-8") as f:
    ALGERIA_CITIES = json.load(f)

with open("assets/data/algeria_wilaya_centroids.json", "r", encoding="utf-8") as f:
    WILAYA_CENTROIDS = {item["wilaya_id"]: item for item in json.load(f)}

def extract_wilaya(text):
    text_lower = text.lower()
    for wilaya in ALGERIA_CITIES:
        w_name_ar = wilaya["wilaya_name"]
        w_name_fr = wilaya["wilaya_name_ascii"].lower()
        if w_name_ar in text or w_name_fr in text_lower:
            return wilaya["wilaya_id"], wilaya["wilaya_name"], wilaya["wilaya_name_ascii"]
        for commune in wilaya.get("communes", []):
            c_ar = commune.get("commune_name", "")
            c_fr = commune.get("commune_name_ascii", "").lower()
            if (c_ar and c_ar in text) or (c_fr and len(c_fr) > 3 and c_fr in text_lower):
                return wilaya["wilaya_id"], wilaya["wilaya_name"], wilaya["wilaya_name_ascii"]
    return 16, "الجزائر", "Alger"

def run():
    all_docs = []
    for item in URLS:
        target = f"{BASE_URL}{item['url']}"
        print(f"\n--- Testing Dabadoc: {target} ---")
        try:
            r = requests.get(target, headers=headers, timeout=15)
            print(f"Status: {r.status_code}")
            if r.status_code == 200:
                soup = BeautifulSoup(r.text, 'html.parser')
                links = soup.find_all('a', href=re.compile(r'/dz/doc/|/dz/medecin/'))
                print(f"Found {len(links)} doctor links")
                for link in links:
                    name = link.get_text(strip=True)
                    href = link['href']
                    if name and len(name) > 3:
                        all_docs.append({
                            "name": name,
                            "url": BASE_URL + href if not href.startswith('http') else href,
                            "desc_ar": item["desc_ar"],
                            "desc_fr": item["desc_fr"],
                            "group": item["group"],
                            "type": item["type"]
                        })
        except Exception as e:
            print(f"Error: {e}")

    print(f"\nTotal Dabadoc extracted: {len(all_docs)}")

if __name__ == "__main__":
    run()
