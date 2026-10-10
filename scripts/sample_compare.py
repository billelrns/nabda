# -*- coding: utf-8 -*-
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

with open('C:/nabda_app/assets/data/smart_2500_articles.json', 'r', encoding='utf-8') as f:
    smart = json.load(f)['articles']

raw_map = {}
for rf in [
    'C:/nabda_app/assets/data/malekah_raw_articles.json',
    'C:/nabda_app/assets/data/malekah_1000_raw.json',
    'C:/nabda_app/assets/data/malekah_batch3_raw.json'
]:
    with open(rf, 'r', encoding='utf-8') as f:
        for a in json.load(f).get('articles', []):
            raw_map[str(a.get('id')).strip()] = a

by_cat = {}
for a in smart:
    cat = a.get('categoryId')
    if cat not in by_cat:
        by_cat[cat] = a

for cat, a in by_cat.items():
    aid = a.get('id')
    orig_id = str(a.get('originalId')).strip()
    raw = raw_map.get(orig_id, {})
    raw_body = raw.get('body', '')
    
    smart_secs = a.get('sections', [])
    smart_content_len = sum(len(s.get('content', '')) for s in smart_secs)
    
    print("=" * 60)
    print(f"CATEGORY: {cat} | ID: {aid} | Original ID: {orig_id}")
    print(f"SMART TITLE: {a.get('title')}")
    print(f"RAW TITLE  : {raw.get('title')}")
    print(f"RAW BODY LENGTH  : {len(raw_body)} chars")
    print(f"SMART SECTIONS LEN: {smart_content_len} chars ({len(smart_secs)} sections)")
    print(f"SMART BULLETS: {[len(s.get('bulletPoints') or []) for s in smart_secs]}")
    print(f"FAQS COUNT   : {len(a.get('faqs') or [])}")
    print(f"SOURCES PREVIEW: {smart_secs[-1].get('content', '')[:100] if smart_secs else 'None'}")
