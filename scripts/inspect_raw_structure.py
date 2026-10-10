# -*- coding: utf-8 -*-
import json
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

for path in ['C:/nabda_app/assets/data/malekah_raw_articles.json', 'C:/nabda_app/assets/data/malekah_1000_raw.json']:
    with open(path, 'r', encoding='utf-8') as f:
        articles = json.load(f)['articles']
    print(f"\n--- FILE: {path} ---")
    for a in articles[:2]:
        body = a.get('body', '')
        print(f"\nID: {a.get('id')} | Title: {a.get('title')}")
        headings = re.findall(r'(##+[^\n]+)', body)
        print(f"Headings found ({len(headings)}):", headings[:5])
        bullet_count = body.count('•')
        print(f"Bullet points count: {bullet_count}")
