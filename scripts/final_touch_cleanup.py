# -*- coding: utf-8 -*-
import json
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

path = 'C:/nabda_app/assets/data/smart_2500_articles.json'
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)

articles = data.get('articles', [])

def clean_final_touches(text):
    if not text or not isinstance(text, str):
        return text
    # Fix remaining Arabic &
    text = re.sub(r'([\u0600-\u06FF])\s*&\s*([\u0600-\u06FF])', r'\1 و \2', text)
    text = re.sub(r'&([\u0600-\u06FF])', r' \1', text)
    text = re.sub(r'([\u0600-\u06FF])&', r'\1 ', text)
    # Fix cutoff phrases
    text = re.sub(r'(?:وهو|وهي)\s+كالتالي\s*:\s*', '، وتتلخص في النقاط التالية: ', text)
    text = re.sub(r'[ \t]{2,}', ' ', text)
    return text.strip()

fixed_count = 0
for a in articles:
    changed = False
    for s in a.get('sections', []):
        old_c = s.get('content', '')
        new_c = clean_final_touches(old_c)
        if new_c != old_c:
            s['content'] = new_c
            changed = True
        old_t = s.get('title', '')
        new_t = clean_final_touches(old_t)
        if new_t != old_t:
            s['title'] = new_t
            changed = True
    if changed:
        fixed_count += 1

print(f"Fixed {fixed_count} articles with final touches.")

with open(path, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print("Saved clean JSON.")
