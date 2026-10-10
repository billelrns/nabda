# -*- coding: utf-8 -*-
import json
import sys
import os

sys.stdout.reconfigure(encoding='utf-8')

smart_path = 'C:/nabda_app/assets/data/smart_2500_articles.json'
with open(smart_path, 'r', encoding='utf-8') as f:
    smart_data = json.load(f)

smart_articles = smart_data.get('articles', [])
print(f"Total smart articles: {len(smart_articles)}")

# Build raw index from the 3 raw files
raw_map_by_id = {}
raw_map_by_title = {}

raw_files = [
    'C:/nabda_app/assets/data/malekah_raw_articles.json',
    'C:/nabda_app/assets/data/malekah_1000_raw.json',
    'C:/nabda_app/assets/data/malekah_batch3_raw.json'
]

total_raw_found = 0
for rf in raw_files:
    if not os.path.exists(rf):
        print(f"File not found: {rf}")
        continue
    with open(rf, 'r', encoding='utf-8') as f:
        rd = json.load(f)
    r_arts = rd.get('articles', [])
    total_raw_found += len(r_arts)
    print(f"Loaded {len(r_arts)} from {os.path.basename(rf)}")
    for a in r_arts:
        aid = str(a.get('id', '')).strip()
        body = a.get('body') or a.get('content') or ''
        title = a.get('title') or ''
        clean_t = title.replace('-', ' ').strip()
        if aid:
            raw_map_by_id[aid] = a
        if clean_t:
            raw_map_by_title[clean_t] = a

print(f"Total raw loaded: {total_raw_found}, Unique IDs: {len(raw_map_by_id)}")

matched_by_id = 0
matched_by_title = 0
unmatched = []

for a in smart_articles:
    orig_id = str(a.get('originalId', '')).strip()
    title = a.get('title', '').strip()
    orig_title = a.get('originalTitle', '').replace('-', ' ').strip()
    
    if orig_id and orig_id in raw_map_by_id:
        matched_by_id += 1
    elif orig_title and orig_title in raw_map_by_title:
        matched_by_title += 1
    else:
        unmatched.append((a.get('id'), orig_id, title[:50]))

print(f"Matched by ID: {matched_by_id}")
print(f"Matched by Title: {matched_by_title}")
print(f"Total Matched: {matched_by_id + matched_by_title} / {len(smart_articles)}")
print(f"Unmatched count: {len(unmatched)}")
if unmatched:
    print("Sample unmatched:", unmatched[:5])
