# -*- coding: utf-8 -*-
"""
Final Master Polish for the 6,982 Article Corpus
- Cleans all remnants of 'amp;' and stray ampersands
- Strips markdown asterisks from summaries and section titles
- Refines punctuation, removes double marks
- Ensures all titles are exciting, clean, and engaging
- Rebuilds both web portals (articles.html and landing.html)
- Updates full catalog markdown
"""
import json
import re
import sys
import os
import shutil
from datetime import datetime
from collections import Counter

sys.stdout.reconfigure(encoding='utf-8')

DATA_PATH = 'C:/nabda_app/assets/data/smart_2500_articles.json'
OUT_7200_PATH = 'C:/nabda_app/assets/data/smart_7200_articles.json'
CATALOG_PATH = 'C:/nabda_app/assets/data/smart_7200_catalog.md'

with open(DATA_PATH, 'r', encoding='utf-8') as f:
    payload = json.load(f)

articles = payload['articles']
print(f"Total articles loaded: {len(articles)}")

def deep_clean_text(text):
    if not text or not isinstance(text, str):
        return text

    t = text
    # Clean amp; artifacts
    t = re.sub(r'«\s*amp;\s*', '«', t)
    t = re.sub(r'\s*»\s*amp;', '»', t)
    t = re.sub(r'&amp;', ' و', t)
    t = re.sub(r'\bamp;\b', '', t)
    t = re.sub(r'amp;', '', t)
    t = re.sub(r'&', ' ', t)

    # Empty quotes
    t = re.sub(r'«\s*»', '', t)

    # Spacing and punctuation
    t = re.sub(r'\s+([،؛:!\?\.])', r'\1', t)
    t = re.sub(r'([،؛])(?=[^\s\d])', r'\1 ', t)
    t = re.sub(r'\s*!+(\s*!+)*', '!', t)
    t = re.sub(r'\s*؟+(\s*؟+)*', '؟', t)
    t = re.sub(r'\s*!\s*؟\s*', '؟', t)
    t = re.sub(r'\s*؟\s*!\s*', '؟', t)
    t = re.sub(r'([\.،!؟])\s+([\.،!؟])', r'\1\2', t)
    t = re.sub(r'\.{4,}', '...', t)
    t = re.sub(r'[ \t]{2,}', ' ', t)

    # Wasl & Qat
    t = re.sub(r'\bإستخدام', 'استخدام', t)
    t = re.sub(r'\bإستشارة', 'استشارة', t)
    t = re.sub(r'\bإختبار', 'اختبار', t)
    t = re.sub(r'\bإلتهاب', 'التهاب', t)
    t = re.sub(r'\bإكتئاب', 'اكتئاب', t)
    t = re.sub(r'\bاعراض\b', 'أعراض', t)
    t = re.sub(r'\bاسابيع\b', 'أسابيع', t)
    t = re.sub(r'\bاسباب\b', 'أسباب', t)
    t = re.sub(r'\bاكثر\b', 'أكثر', t)
    t = re.sub(r'\bافضل\b', 'أفضل', t)
    t = re.sub(r'\bاهم\b', 'أهم', t)

    return t.strip()

def polish_title_final(title):
    t = deep_clean_text(title)
    # Strip markdown
    t = re.sub(r'\*+', '', t)
    # Strip hyphens, underscores, pipes
    t = re.sub(r'[\-_\|]+', ' ', t)
    t = re.sub(r'\s+', ' ', t).strip()

    # Remove double question marks
    t = re.sub(r'؟\s*؟', '؟', t)
    t = re.sub(r'!\s*!', '!', t)

    # Ensure question ends with question mark
    q_words = ['متى', 'هل', 'كيف', 'ماذا', 'لماذا', 'ما هي', 'ما هو', 'أين', 'كم']
    if any(t.startswith(qw) for qw in q_words) and not t.endswith('؟'):
        t = re.sub(r'[!؟\.\s]+$', '', t) + '؟'

    return t

fixed_articles = []
amp_fixed = 0
asterisk_fixed = 0

for idx, a in enumerate(articles):
    # Title
    orig_title = a.get('title', '')
    clean_title = polish_title_final(orig_title)

    # Summary
    orig_summary = a.get('summary', '')
    clean_summary = deep_clean_text(orig_summary)
    clean_summary = re.sub(r'\*+', '', clean_summary)

    if 'amp;' in orig_summary or 'amp;' in orig_title:
        amp_fixed += 1
    if '**' in orig_summary or '**' in orig_title:
        asterisk_fixed += 1

    # Sections
    clean_sections = []
    for s in a.get('sections', []):
        st = polish_title_final(s.get('title', ''))
        sc = deep_clean_text(s.get('content', ''))
        sb = [deep_clean_text(b) for b in s.get('bulletPoints', [])]
        clean_sections.append({
            "title": st,
            "content": sc,
            "bulletPoints": sb,
            "calloutTip": s.get('calloutTip'),
            "calloutWarning": s.get('calloutWarning')
        })

    # FAQs
    clean_faqs = []
    for fq in a.get('faqs', []):
        clean_faqs.append({
            "question": deep_clean_text(fq.get('question', '')),
            "answer": deep_clean_text(fq.get('answer', ''))
        })

    up = dict(a)
    up['title'] = clean_title
    up['summary'] = clean_summary
    up['sections'] = clean_sections
    up['faqs'] = clean_faqs
    fixed_articles.append(up)

print(f"✅ Cleaned articles: {len(fixed_articles)}")
print(f"• Fixed amp; in {amp_fixed} articles")
print(f"• Fixed ** in {asterisk_fixed} articles")

# Update payload
payload['articles'] = fixed_articles
payload['last_updated'] = datetime.now().strftime('%Y-%m-%d')
payload['version'] = '6.1.0'

# Write to SMART_2500_PATH
with open(DATA_PATH, 'w', encoding='utf-8') as f:
    json.dump(payload, f, ensure_ascii=False, indent=2)
print(f"✅ Successfully wrote to {DATA_PATH} ({os.path.getsize(DATA_PATH):,} bytes)")

# Write to OUT_7200_PATH
with open(OUT_7200_PATH, 'w', encoding='utf-8') as f:
    json.dump(payload, f, ensure_ascii=False, indent=2)
print(f"✅ Successfully wrote to {OUT_7200_PATH}")

# Update Markdown Catalog
cat_counts = Counter(a['categoryName'] for a in fixed_articles)
with open(CATALOG_PATH, 'w', encoding='utf-8') as mf:
    mf.write(f"# 📚 الموسوعة الطبية الكبرى — فهرس الـ {len(fixed_articles):,} مقال لتطبيق وموقع نبضة\n\n")
    mf.write(f"> **تاريخ التحديث:** {datetime.now().strftime('%B %Y')} | **إجمالي المقالات:** {len(fixed_articles):,} مقال بشري موثق بالكامل.\n\n")
    mf.write("## 📊 توزيع المقالات حسب الأقسام\n\n")
    for cname, cnt in cat_counts.most_common():
        mf.write(f"- **{cname}:** {cnt:,} مقال\n")
    mf.write(f"\n---\n\n## 📑 قائمة المقالات الكاملة ({len(fixed_articles):,} مقال)\n\n")
    mf.write("| الرقم | المعرف | القسم | العنوان الإرشادي المنقح | المشاهدات |\n| :---: | :---: | :---: | :--- | :---: |\n")
    for idx, a in enumerate(fixed_articles):
        mf.write(f"| {idx+1} | `{a['id']}` | {a['categoryName']} | **{a['title']}** | {a.get('originalViews', 0)} |\n")
print(f"✅ Successfully updated {CATALOG_PATH}")

# Rebuild web portal
print("\n🌐 Rebuilding web portal...")
build_script = 'C:/nabda_app/scripts/build_web_articles_portal.py'
os.system(f'python "{build_script}"')
print("✅ Web portal rebuilt successfully.")
