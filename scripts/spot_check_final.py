# -*- coding: utf-8 -*-
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

path = 'C:/nabda_app/assets/data/smart_2500_articles.json'
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)

articles = data.get('articles', [])

# Sample 1 from each category
seen_cats = set()
samples = []
for a in articles:
    cat = a.get('categoryId')
    if cat not in seen_cats:
        seen_cats.add(cat)
        samples.append(a)

for a in samples:
    print("=" * 60)
    print(f"[{a.get('categoryId')}] ID: {a.get('id')}")
    print(f"TITLE: {a.get('title')}")
    print(f"SUMMARY: {a.get('summary')[:120]}...")
    print(f"SECTIONS ({len(a.get('sections', []))}):")
    for s in a.get('sections', []):
        print(f"  • {s.get('title')} ({len(s.get('content', ''))} chars)")
        if s.get('bulletPoints'):
            print(f"    Bullets ({len(s.get('bulletPoints'))}):", s.get('bulletPoints')[:2])
    print("FAQS:")
    for q in a.get('faqs', []):
        print(f"  س: {q.get('question')}")
        print(f"  ج: {q.get('answer')[:80]}...")
    print(f"SOURCES PREVIEW:\n{a.get('sections', [])[-1].get('content', '')[:200]}...")
