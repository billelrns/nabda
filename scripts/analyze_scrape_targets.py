# -*- coding: utf-8 -*-
import json
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')

# 1. Load catalog
with open('C:/nabda_app/assets/data/malekah_articles_catalog.json', 'r', encoding='utf-8') as f:
    catalog = json.load(f)['articles']

# 2. Load existing 2500 articles
with open('C:/nabda_app/assets/data/smart_2500_articles.json', 'r', encoding='utf-8') as f:
    smart = json.load(f)['articles']

smart_orig_ids = {str(a.get('originalId', '')).strip() for a in smart if a.get('originalId')}
smart_article_ids = {str(a.get('id', '')).strip() for a in smart if a.get('id')}

# 3. Check raw files
raw_files = [
    'C:/nabda_app/assets/data/malekah_raw_articles.json',
    'C:/nabda_app/assets/data/malekah_1000_raw.json',
    'C:/nabda_app/assets/data/malekah_batch3_raw.json',
    'C:/nabda_app/assets/data/malekah_remaining_raw.json'
]
raw_scraped = {}
for rf in raw_files:
    if os.path.exists(rf):
        with open(rf, 'r', encoding='utf-8') as f:
            for a in json.load(f).get('articles', []):
                aid = str(a.get('id', '')).strip()
                if aid:
                    raw_scraped[aid] = a

print(f"Total catalog articles: {len(catalog)}")
print(f"Smart 2500 original IDs: {len(smart_orig_ids)}")
print(f"Total in all raw files: {len(raw_scraped)}")

# Targets = catalog items whose ID is not in smart_orig_ids
targets = [a for a in catalog if str(a.get('id', '')).strip() not in smart_orig_ids]
print(f"Remaining articles to add to corpus: {len(targets)}")

# Of those targets, how many already exist in raw_scraped?
already_in_raw = [a for a in targets if str(a.get('id', '')).strip() in raw_scraped]
need_scrape = [a for a in targets if str(a.get('id', '')).strip() not in raw_scraped]
print(f"Already in raw files (ready to process): {len(already_in_raw)}")
print(f"Need to fetch from malekah.info: {len(need_scrape)}")
