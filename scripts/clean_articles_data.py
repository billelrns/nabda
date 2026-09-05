"""
تنظيف smart_2500_articles.json من مراجع «الملكة» + توحيد الألوان مع هوية نبضة.
يعمل مرّة واحدة قبل التكامل مع التطبيق.

الاستخدام:
    cd C:\\nabda_app
    python scripts/clean_articles_data.py
"""
import json
import re
import shutil
import sys
from pathlib import Path
from datetime import datetime

if sys.stdout.encoding != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

SRC = Path(r'C:\nabda_app\assets\data\smart_2500_articles.json')
BACKUP = Path(f'C:/nabda_app/assets/data/smart_2500_articles.backup_{datetime.now():%Y%m%d_%H%M%S}.json')

# ───────────── الاستبدالات النصّية ─────────────
TEXT_REPLACEMENTS = {
    # الرابط القديم → الحالي (nabda.app لم يعد نطاقنا)
    'https://nabda.app/': 'https://nabda.online/',
    'http://nabda.app/': 'https://nabda.online/',
    'nabda.app/': 'nabda.online/',
    'nabda.app': 'nabda.online',
    # أي إشارة صريحة لموقع منافس
    'malekah.info': 'nabda.online',
    'moqedma.com': 'nabda.online',
}

# ───────────── تحويل الألوان (Malika/random → Nabda official) ─────────────
COLOR_MAP = {
    # الوردي الأساسي (pregnancy) — نفس لون نبضة، نُبقيه
    '#E91E63': '#E91E63',
    # وردي زاهي (beauty) → وردي ناعم أهدأ يليق بالجمال
    '#FF4081': '#FF6090',
    # فوشيا صاخب (marriage) → روز أنثوي هادئ
    '#E040FB': '#EC407A',
    # بنفسجي غامق (fertility) → لافندر أنثوي (نبضة الثانوي)
    '#9C27B0': '#7E57C2',
    # أخضر (womens_health) → تركوازي نبضة الرسمي!
    '#4CAF50': '#00897B',
    # سماوي (baby_care) → أزرق فاتح لطيف
    '#00BCD4': '#29B6F6',
    # حالات نادرة أخرى نأخذها لألوان نبضة
    '#E42558': '#E91E63',  # Malika primary → Nabda pink
    '#008299': '#00897B',  # Malika teal → Nabda teal
    '#FF6C93': '#FF6090',  # Malika soft pink → Nabda soft pink
    '#4B5AB9': '#7E57C2',  # Malika purple → Nabda lavender
}


def clean_text(text: str) -> str:
    """يطبّق الاستبدالات النصية على أي نصّ."""
    if not isinstance(text, str):
        return text
    for old, new in TEXT_REPLACEMENTS.items():
        text = text.replace(old, new)
    return text


def clean_color(hex_color: str) -> str:
    """يحوّل ألوان الملكة/الملوّنة إلى ألوان نبضة الرسمية."""
    if not isinstance(hex_color, str):
        return hex_color
    upper = hex_color.upper()
    if hex_color in COLOR_MAP:
        return COLOR_MAP[hex_color]
    if upper in COLOR_MAP:
        return COLOR_MAP[upper]
    return hex_color


def clean_article(article: dict) -> dict:
    """ينظّف مقالاً واحداً: النصوص + الألوان."""
    # الحقول النصّية العادية
    for key in ['title', 'summary', 'author', 'sourceUrl', 'toolTitle', 'toolSubtitle', 'originalTitle']:
        if key in article and article[key]:
            article[key] = clean_text(article[key])
    # اللون
    if 'themeColorHex' in article:
        article['themeColorHex'] = clean_color(article['themeColorHex'])
    # الأقسام
    for section in article.get('sections', []) or []:
        section['title'] = clean_text(section.get('title', ''))
        section['content'] = clean_text(section.get('content', ''))
    # الأسئلة الشائعة
    for faq in article.get('faqs', []) or []:
        faq['question'] = clean_text(faq.get('question', ''))
        faq['answer'] = clean_text(faq.get('answer', ''))
    return article


def main():
    print(f"═══ تنظيف {SRC} ═══")
    if not SRC.exists():
        print(f"❌ الملف غير موجود: {SRC}")
        return

    # نسخة احتياطية
    shutil.copy(SRC, BACKUP)
    print(f"✓ نسخة احتياطية: {BACKUP.name}")

    # تحميل
    with SRC.open('r', encoding='utf-8') as f:
        data = json.load(f)
    articles = data.get('articles', [])
    print(f"✓ تحميل {len(articles)} مقال")

    # تنظيف أي مراجع في أعلى مستوى مثل categories_distribution إذا وجدت
    if 'categories_distribution' in data:
        pass

    # عدّ التغييرات قبل
    counters = {'urls_changed': 0, 'colors_changed': 0}
    for a in articles:
        old_url = a.get('sourceUrl', '')
        old_color = a.get('themeColorHex', '')
        clean_article(a)
        if a.get('sourceUrl', '') != old_url:
            counters['urls_changed'] += 1
        if a.get('themeColorHex', '') != old_color:
            counters['colors_changed'] += 1

    # حفظ
    with SRC.open('w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"\n✓ {counters['urls_changed']} رابط nabda.app → nabda.online")
    print(f"✓ {counters['colors_changed']} لون محوّل لألوان نبضة")
    print(f"\n✓ الملف مُحدَّث: {SRC}")
    print(f"  الحجم: {SRC.stat().st_size / 1024 / 1024:.1f} MB")


if __name__ == '__main__':
    main()
