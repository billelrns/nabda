# -*- coding: utf-8 -*-
from curl_cffi import requests
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

with open('C:/nabda_app/assets/data/malekah_articles_catalog.json', 'r', encoding='utf-8') as f:
    catalog = json.load(f)['articles']

raw_ids = set()
with open('C:/nabda_app/assets/data/malekah_remaining_raw.json', 'r', encoding='utf-8') as f:
    raw_ids = {str(a['id']).strip() for a in json.load(f)['articles']}

with open('C:/nabda_app/assets/data/smart_2500_articles.json', 'r', encoding='utf-8') as f:
    smart_ids = {str(a.get('originalId', '')).strip() for a in json.load(f)['articles']}

# Find articles that should have been processed in the first 800 items
test_count = 0
for a in catalog:
    aid = str(a['id']).strip()
    if aid not in raw_ids and aid not in smart_ids:
        # Check this one
        url = f"https://malekah.info/Article/{aid}/"
        try:
            r = requests.get(url, impersonate='chrome120', timeout=10)
            print(f"ID {aid}: status={r.status_code}, len={len(r.text)}")
            if r.status_code == 200:
                print("  Snippet:", r.text[:250].replace('\n', ' '))
        except Exception as e:
            print(f"ID {aid}: error={e}")
        test_count += 1
        if test_count >= 5:
            break
