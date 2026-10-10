# -*- coding: utf-8 -*-
import json
import re
import sys
import random

sys.stdout.reconfigure(encoding='utf-8')

DATA_PATH = 'C:/nabda_app/assets/data/smart_2500_articles.json'
with open(DATA_PATH, 'r', encoding='utf-8') as f:
    data = json.load(f)

articles = data['articles']
total_count = len(articles)

total_words = 0
legacy_brand_matches = 0
stray_amp_matches = 0
ai_pattern_matches = 0
cutoff_matches = 0
missing_sources = 0
missing_faqs = 0
short_articles = 0

ai_patterns = [
    r'لراحة بال تامة',
    r'لنتائج مضمونة ومريحة',
    r'دليل نبضة الموثق:',
    r'الدليل الذهبي:',
    r'السر المجهول:',
    r'حقائق طبية مؤكدة تفاجئكِ',
    r'إليكِ الإجابة الطبية القاطعة'
]

for a in articles:
    # Word count
    text_content = a.get('title', '') + ' ' + a.get('summary', '')
    for s in a.get('sections', []):
        text_content += ' ' + s.get('title', '') + ' ' + s.get('content', '') + ' ' + ' '.join(s.get('bulletPoints', []))
    words = len(text_content.split())
    total_words += words
    if words < 120:
        short_articles += 1

    # Legacy branding
    if re.search(r'\b(ملكتي|موقع الملكة|تطبيق الملكة|malekah\.info)\b', text_content):
        legacy_brand_matches += 1

    # Stray &
    if re.search(r'&(?!amp;|lt;|gt;|quot;|#)', text_content):
        stray_amp_matches += 1

    # AI Patterns in Title
    if any(re.search(p, a.get('title', '')) for p in ai_patterns):
        ai_pattern_matches += 1

    # Abrupt cutoffs
    if re.search(r'(?:وهو|وهي)\s+كالتالي\s*:\s*$', text_content, flags=re.MULTILINE):
        cutoff_matches += 1

    # Sources
    sec_titles = [s.get('title', '') for s in a.get('sections', [])]
    if not any('المصادر' in st for st in sec_titles):
        missing_sources += 1

    # FAQs
    if not a.get('faqs') or len(a.get('faqs')) < 2:
        missing_faqs += 1

print("=" * 65)
print("📊 نتائج الفحص والتدقيق الشامل للموسوعة الكبرى (6,982 مقال):")
print("=" * 65)
print(f"• إجمالي المقالات المفحوصة: {total_count:,} مقال")
print(f"• إجمالي الكلمات في الموسوعة: {total_words:,} كلمة")
print(f"• متوسط الكلمات لكل مقال: {total_words // total_count} كلمة")
print(f"• مقالات تحتوي على علامة تجارية قديمة (ملكتي): {legacy_brand_matches}")
print(f"• مقالات تحتوي على رموز & غير منسقة: {stray_amp_matches}")
print(f"• عناوين تحتوي على عبارات AI نمطية: {ai_pattern_matches}")
print(f"• مقالات بها نهايات مقطوعة (وهو كالتالي:): {cutoff_matches}")
print(f"• مقالات تفتقر للمصادر الطبية المعتمدة: {missing_sources}")
print(f"• مقالات تفتقر للأسئلة الشائعة (FAQs): {missing_faqs}")
print(f"• مقالات قصيرة جداً (<120 كلمة): {short_articles}")

print("\n" + "=" * 65)
print("🌟 عينات عشوائية من المقالات بعد التنقيح وصياغة العناوين المثيرة:")
print("=" * 65)

random.seed(42)
sample_indices = random.sample(range(total_count), 5)
for idx in sample_indices:
    sa = articles[idx]
    print(f"\n[مقال #{sa['rank']}] المعرف: {sa['id']} | القسم: {sa['categoryName']}")
    print(f"📌 العنوان المثير المنقح: {sa['title']}")
    print(f"📝 العنوان الأصلي السابق: {sa.get('originalTitle', 'غير متوفر')}")
    print(f"💡 الملخص: {sa['summary'][:160]}...")
    print(f"📑 الأقسام ({len(sa['sections'])} أقسام):")
    for si, sec in enumerate(sa['sections']):
        print(f"   {si+1}. {sec['title']} ({len(sec['content'])} حرف)")
    print("📚 المصادر المعتمدة:")
    for line in sa['sections'][-1]['content'].split('\n')[:3]:
        print(f"   {line}")
    print("❓ عينة من الأسئلة الشائعة:")
    print(f"   س: {sa['faqs'][0]['question']}")
    print(f"   ج: {sa['faqs'][0]['answer'][:90]}...")
