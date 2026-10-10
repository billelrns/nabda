# -*- coding: utf-8 -*-
import json
import re
import sys
from collections import Counter

sys.stdout.reconfigure(encoding='utf-8')

for path in ['C:/nabda_app/assets/data/malekah_1000_raw.json', 'C:/nabda_app/assets/data/malekah_batch3_raw.json']:
    with open(path, 'r', encoding='utf-8') as f:
        arts = json.load(f)['articles']
    print(f"\n--- {path} ({len(arts)} articles) ---")
    patterns = Counter()
    for a in arts:
        body = a.get('body', '')
        if '## ' in body:
            patterns['has_hash_hash'] += 1
        if '●' in body:
            patterns['has_black_circle'] += 1
        if re.search(r'\n\s*\d+[\.\)]\s+', body):
            patterns['has_numbered_list'] += 1
        if '•' in body:
            patterns['has_bullet'] += 1
        if '&' in body:
            patterns['has_ampersand'] += 1
    print("Patterns count:", patterns)
