# -*- coding: utf-8 -*-
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

with open('assets/data/smart_2500_articles.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

for a in data['articles']:
    secs = a.get('sections', [])
    if len(secs) >= 3 and 'إليكِ أهم الإرشادات العملية' in secs[1].get('content', ''):
        aid = a.get('id')
        title = a.get('title')
        print(f"Article ID: {aid} - Title: {title}")
        print("\n--- SECTION 1 ---")
        print(secs[0].get('title'))
        print(secs[0].get('content')[:300])
        print("\n--- SECTION 2 ---")
        print(secs[1].get('title'))
        print(secs[1].get('content'))
        print("\n--- SECTION 3 ---")
        print(secs[2].get('title'))
        print(secs[2].get('content'))
        break
