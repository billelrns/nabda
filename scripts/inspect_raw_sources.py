# -*- coding: utf-8 -*-
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

for path in ['assets/data/malekah_raw_articles.json', 'assets/data/malekah_1000_raw.json', 'assets/data/malekah_batch3_raw.json']:
    with open(path, 'r', encoding='utf-8') as f:
        d = json.load(f)
    arts = d.get('articles', [])
    print(f"\nFile: {path} - Articles count: {len(arts)}")
    if arts:
        first = arts[0]
        print(f"  Keys: {list(first.keys())}")
        print(f"  First title: {first.get('title')}")
        body = first.get('body') or first.get('content') or ''
        print(f"  Body length: {len(body)}")
        print(f"  Body preview: {body[:150]}...")
