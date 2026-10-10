# -*- coding: utf-8 -*-
import json
import sys
from collections import Counter

sys.stdout.reconfigure(encoding='utf-8')

# Load catalog
with open('C:/nabda_app/assets/data/malekah_articles_catalog.json', 'r', encoding='utf-8') as f:
    catalog = json.load(f)['articles']

# Load current 2500 articles
with open('C:/nabda_app/assets/data/smart_2500_articles.json', 'r', encoding='utf-8') as f:
    smart = json.load(f)['articles']

current_orig_ids = {str(a.get('originalId')).strip() for a in smart if a.get('originalId')}
print(f"Total catalog articles: {len(catalog)}")
print(f"Current smart articles: {len(smart)} (Unique original IDs: {len(current_orig_ids)})")

# Check already scraped in raw files
scraped_ids = set()
for rf in [
    'C:/nabda_app/assets/data/malekah_raw_articles.json',
    'C:/nabda_app/assets/data/malekah_1000_raw.json',
    'C:/nabda_app/assets/data/malekah_batch3_raw.json'
]:
    with open(rf, 'r', encoding='utf-8') as f:
        for a in json.load(f).get('articles', []):
            aid = str(a.get('id')).strip()
            if aid:
                scraped_ids.add(aid)

print(f"Already scraped in raw files: {len(scraped_ids)}")

# Remaining to scrape
remaining = [a for a in catalog if str(a.get('id')).strip() not in current_orig_ids]
print(f"Remaining articles to scrape & process: {len(remaining)}")

domain_counter = Counter(a.get('domain') for a in remaining)
print("\nDomain distribution of remaining articles:")
for d, c in domain_counter.most_common():
    print(f"  - {d}: {c} articles")
