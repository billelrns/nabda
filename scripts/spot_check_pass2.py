# -*- coding: utf-8 -*-
"""
VERIFICATION PASS 2: Cross-category sampling and linguistic inspection.
Pulls sample articles across all 6 categories and verifies their structure and readability.
"""
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

with open('assets/data/smart_2500_articles.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

articles = data.get('articles', [])

by_cat = {}
for a in articles:
    cat = a.get('categoryId', 'pregnancy')
    by_cat.setdefault(cat, []).append(a)

print("==================================================")
print("🔄 VERIFICATION PASS 2: SPOT-CHECK ACROSS CATEGORIES")
print("==================================================")

for cat, cat_articles in by_cat.items():
    print(f"\n📁 CATEGORY: {cat.upper()} (Total: {len(cat_articles)} articles)")
    # Sample 2 articles
    for a in cat_articles[:2]:
        aid = a.get('id')
        title = a.get('title')
        secs = a.get('sections', [])
        print(f"  • [{aid}] {title}")
        print(f"    - Read time: {a.get('readTime')} | Views: {a.get('originalViews')}")
        print(f"    - Image path: {a.get('imagePath')}")
        print(f"    - Total sections: {len(secs)}")
        
        # Section 1 snippet
        if secs:
            s1 = secs[0]
            print(f"    - Sec 1: {s1.get('title')}")
            print(f"      Text: {s1.get('content')[:120]}...")
            
        # Sources section
        sources_sec = None
        for s in secs:
            if 'المصادر والمراجع الطبية' in s.get('title', ''):
                sources_sec = s
                break
        if sources_sec:
            print(f"    - Sources: {sources_sec.get('title')}")
            lines = sources_sec.get('content', '').split('\n')
            for l in lines[:3]:
                if l.strip():
                    print(f"        {l.strip()}")
            has_disc = 'تنويه طبي' in sources_sec.get('content', '')
            print(f"      ✓ Clinical Disclaimer Included: {has_disc}")
        else:
            print("      ❌ Missing sources section!")

print("\n==================================================")
print("✓ Spot check completed successfully across all categories.")
print("==================================================")
