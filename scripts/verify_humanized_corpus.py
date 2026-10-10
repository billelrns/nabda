# -*- coding: utf-8 -*-
import json
import re
import sys
from collections import Counter

sys.stdout.reconfigure(encoding='utf-8')

path = 'C:/nabda_app/assets/data/smart_2500_articles.json'
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)

articles = data.get('articles', [])
print(f"Total articles audited: {len(articles)}")

total_sections = 0
total_bullets = 0
total_faqs = 0
total_words = 0
missing_sources = 0
missing_disclaimers = 0
malekah_mentions = 0
ampersand_stray = 0
cutoff_phrases = 0
ai_suffix_count = 0
category_counts = Counter()

lengths = []

for a in articles:
    aid = a.get('id')
    cat = a.get('categoryId')
    category_counts[cat] += 1
    title = a.get('title', '')
    summary = a.get('summary', '')
    secs = a.get('sections', [])
    faqs = a.get('faqs', [])
    
    total_sections += len(secs)
    total_faqs += len(faqs)
    
    full_text = title + ' ' + summary + ' ' + ' '.join(s.get('title', '') + ' ' + s.get('content', '') + ' ' + ' '.join(s.get('bulletPoints') or []) for s in secs)
    words = len(full_text.split())
    total_words += words
    lengths.append(len(full_text))
    
    # Check bullets
    for s in secs:
        total_bullets += len(s.get('bulletPoints') or [])
        
    # Check legacy mentions
    if 'ملكتي' in full_text or 'تطبيق الملكة' in full_text or 'malekah' in full_text:
        malekah_mentions += 1
        
    # Check stray &
    if re.search(r'&(?!lt;|gt;|quot;|#)', full_text):
        ampersand_stray += 1
        
    # Check cutoffs
    if 'وهو كالتالي:' in full_text or 'وهي كالتالي:' in full_text:
        cutoff_phrases += 1
        
    # Check AI suffixes in title
    if 'حقائق خفية لم يخبركِ بها أحد' in title or 'كشف السر الطبي وخطوات العلاج' in title:
        ai_suffix_count += 1
        
    # Check sources section
    has_src = False
    has_disc = False
    for s in secs:
        if 'المصادر والمراجع الطبية' in s.get('title', ''):
            has_src = True
            if 'تنويه طبي' in s.get('content', ''):
                has_disc = True
    if not has_src:
        missing_sources += 1
    if not has_disc:
        missing_disclaimers += 1

print("\n" + "=" * 50)
print("📊 FINAL VERIFICATION AUDIT METRICS (2,500 ARTICLES)")
print("=" * 50)
print(f"Total Articles              : {len(articles)}")
print(f"Total Words                 : {total_words:,} words (Avg: {total_words // len(articles)} words/article)")
print(f"Total Characters (Avg)      : {sum(lengths) // len(articles):,} chars/article")
print(f"Min Chars: {min(lengths):,} | Max Chars: {max(lengths):,}")
print(f"Total Sections              : {total_sections:,} (Avg: {total_sections / len(articles):.1f} per article)")
print(f"Total Bullet Points         : {total_bullets:,}")
print(f"Total FAQs                  : {total_faqs:,} (Avg: {total_faqs / len(articles):.1f} per article)")
print(f"Missing Sources Sections    : {missing_sources}")
print(f"Missing Medical Disclaimers : {missing_disclaimers}")
print(f"Legacy Brand Mentions       : {malekah_mentions}")
print(f"Stray Ampersand '&'         : {ampersand_stray}")
print(f"Truncated Cutoff Phrases    : {cutoff_phrases}")
print(f"Repetitive AI Title Suffixes: {ai_suffix_count}")

print("\nCategories distribution:")
for cat, count in category_counts.most_common():
    print(f"  - {cat}: {count} articles")
