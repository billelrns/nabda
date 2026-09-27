# -*- coding: utf-8 -*-
"""
Nabda Web Tools Data & HTML Pre-renderer
Bakes all SEO content into static HTML at build time:
- 40 pregnancy weeks in fetus-size.html (no runtime fetch)
- 1,765 baby names in baby-names.html (no runtime fetch)
- 1,765 individual name pages in web/tools/names/{slug}.html
- Comprehensive web/sitemap.xml
- Automated Arabic word count checks (fails if indexable content is missing)
"""

import os
import re
import sys
import json
import html

# Ensure UTF-8 output in Windows shells
if sys.stdout.encoding != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DART_WEEKS_FILE = os.path.join(BASE_DIR, "lib", "models", "pregnancy_week_articles.dart")
DART_NAMES_FILE = os.path.join(BASE_DIR, "lib", "data", "baby_names_database.dart")
DATA_DIR = os.path.join(BASE_DIR, "web", "tools", "data")
NAMES_DIR = os.path.join(BASE_DIR, "web", "tools", "names")
FETUS_HTML_FILE = os.path.join(BASE_DIR, "web", "tools", "fetus-size.html")
NAMES_HTML_FILE = os.path.join(BASE_DIR, "web", "tools", "baby-names.html")
SITEMAP_FILE = os.path.join(BASE_DIR, "web", "sitemap.xml")

os.makedirs(DATA_DIR, exist_ok=True)
os.makedirs(NAMES_DIR, exist_ok=True)

# ══════════════════════════════════════════════════════════════
# 1. Transliteration & Deterministic Latin Slugs
# ══════════════════════════════════════════════════════════════

ARABIC_TO_LATIN = {
    'أ': 'a', 'إ': 'i', 'آ': 'aa', 'ا': 'a', 'ء': 'a', 'ئ': 'e', 'ؤ': 'o',
    'ب': 'b', 'ت': 't', 'ث': 'th', 'ج': 'j', 'ح': 'h', 'خ': 'kh',
    'د': 'd', 'ذ': 'dh', 'ر': 'r', 'ز': 'z', 'س': 's', 'ش': 'sh',
    'ص': 's', 'ض': 'd', 'ط': 't', 'ظ': 'z', 'ع': 'a', 'غ': 'gh',
    'ف': 'f', 'ق': 'q', 'ك': 'k', 'ل': 'l', 'م': 'm', 'ن': 'n',
    'ه': 'h', 'و': 'w', 'ي': 'y', 'ى': 'a', 'ة': 'a'
}

SPECIAL_NAMES = {
    'مريم': 'maryam', 'فاطمة': 'fatima', 'عائشة': 'aisha', 'خديجة': 'khadija',
    'زينب': 'zainab', 'سارة': 'sara', 'آية': 'aya', 'أمينة': 'amina',
    'إيمان': 'iman', 'هاجر': 'hajar', 'جميلة': 'jamila', 'حسيبة': 'hassiba',
    'أسماء': 'asmaa', 'سمية': 'somaya', 'سلمى': 'salma', 'نور': 'nour',
    'ملاك': 'malak', 'ليلى': 'layla', 'ياسمين': 'yasmin', 'صفية': 'safia',
    'حنان': 'hanan', 'هناء': 'hanaa', 'وفاء': 'wafaa', 'هدى': 'hoda',
    'رحمة': 'rahma', 'إكرام': 'ikram', 'أحلام': 'ahlam', 'إلهام': 'ilham',
    'لين': 'leen', 'ليان': 'layan', 'جنى': 'jana', 'ضحى': 'doha',
    'محمد': 'mohamed', 'أحمد': 'ahmed', 'محمود': 'mahmoud', 'علي': 'ali',
    'عمر': 'omar', 'عثمان': 'othman', 'أبو بكر': 'abu-bakr', 'خالد': 'khaled',
    'يوسف': 'youssef', 'إبراهيم': 'ibrahim', 'إسماعيل': 'ismail', 'إسحاق': 'ishaq',
    'يعقوب': 'yaqoub', 'موسى': 'moussa', 'عيسى': 'issa', 'يحيى': 'yahya',
    'زكريا': 'zakaria', 'داود': 'daoud', 'سليمان': 'soliman', 'أيوب': 'ayoub',
    'يونس': 'younes', 'هارون': 'haroun', 'حمزة': 'hamza', 'بلال': 'bilal',
    'طارق': 'tariq', 'زياد': 'ziad', 'حسام': 'hossam', 'كريم': 'karim',
    'ياسين': 'yassine', 'ريان': 'rayan', 'آدم': 'adam',
    'نوح': 'nouh', 'إدريس': 'idriss', 'صالح': 'saleh', 'هود': 'houd'
}

COMPOUNDS = [
    ('عبد الله', 'abdullah'),
    ('عبد الرحمن', 'abdulrahman'),
    ('عبد الرحيم', 'abdulrahim'),
    ('عبد الملك', 'abdulmalik'),
    ('عبد السلام', 'abdulsalam'),
    ('عبد العزيز', 'abdulaziz'),
    ('عبد الخالق', 'abdulkhaliq'),
    ('عبد الرزاق', 'abdulrazzaq'),
    ('عبد الفتاح', 'abdulfattah'),
    ('عبد اللطيف', 'abdullatif'),
    ('عبد الحليم', 'abdulhalim'),
    ('عبد العظيم', 'abdulazim'),
    ('عبد الكريم', 'abdulkarim'),
    ('عبد القادر', 'abdulqadir'),
    ('عبد الوهاب', 'abdulwahab'),
    ('عبد المجيد', 'abdulmajid'),
    ('عبد الواحد', 'abdulwahid'),
    ('عبد الصمد', 'abdulsamad'),
    ('عبد الباسط', 'abdulbasit'),
    ('عبد الستار', 'abdulsettar'),
    ('سيف الدين', 'saif-el-din'),
    ('صلاح الدين', 'salah-el-din'),
    ('نور الدين', 'nour-el-din'),
    ('عز الدين', 'ezz-el-din'),
    ('علاء الدين', 'alaa-el-din'),
    ('بهاء الدين', 'bahaa-el-din'),
    ('جمال الدين', 'jamal-el-din'),
    ('جلال الدين', 'jalal-el-din'),
    ('حسام الدين', 'hossam-el-din'),
    ('خير الدين', 'kheir-el-din'),
    ('ضياء الدين', 'dyaa-el-din'),
    ('عماد الدين', 'emad-el-din'),
    ('فخر الدين', 'fakhr-el-din'),
    ('محيي الدين', 'mohyi-el-din'),
    ('نجم الدين', 'najm-el-din'),
    ('شمس الدين', 'shams-el-din'),
    ('شرف الدين', 'sharaf-el-din'),
    ('سراج الدين', 'seraj-el-din'),
    ('تقي الدين', 'taqi-el-din'),
    ('تاج الدين', 'taj-el-din'),
    ('غياث الدين', 'ghiath-el-din'),
    ('ناصر الدين', 'nasser-el-din'),
    ('معين الدين', 'moein-el-din'),
    ('برهان الدين', 'borhan-el-din'),
    ('ركن الدين', 'rokn-el-din'),
    ('صدر الدين', 'sadr-el-din'),
    ('مجد الدين', 'majd-el-din'),
    ('علم الدين', 'alam-el-din'),
    ('سعد الدين', 'saad-el-din'),
    ('صفي الدين', 'safi-el-din'),
    ('ولي الدين', 'wali-el-din'),
    ('نصير الدين', 'nassir-el-din'),
    ('فاطمة الزهراء', 'fatima-al-zahraa'),
    ('أم كلثوم', 'oum-kalthoum'),
    ('أبو بكر', 'abu-bakr')
]

def transliterate_arabic(text):
    text = text.strip()
    if text in SPECIAL_NAMES:
        return SPECIAL_NAMES[text]
    
    for ar, lat in COMPOUNDS:
        if text == ar:
            return lat

    t = text
    t = re.sub(r'^عبد\s+ال', 'abdel-', t)
    t = re.sub(r'^عبد\s+', 'abdel-', t)
    t = re.sub(r'^أبو\s+', 'abu-', t)
    t = re.sub(r'^أم\s+', 'oum-', t)
    t = re.sub(r'\s+الدين$', '-el-din', t)

    res = []
    i = 0
    while i < len(t):
        ch = t[i]
        if ch in ARABIC_TO_LATIN:
            res.append(ARABIC_TO_LATIN[ch])
        elif ch in ' -':
            res.append('-')
        elif ch.isascii() and (ch.isalnum() or ch == '-'):
            res.append(ch.lower())
        i += 1
    
    slug = ''.join(res)
    slug = re.sub(r'-+', '-', slug).strip('-')
    return slug if slug else 'name'

# ══════════════════════════════════════════════════════════════
# 2. Extract & Pre-render Fetus Weeks (fetus-size.html)
# ══════════════════════════════════════════════════════════════

def get_fruit_emoji(size_ar):
    s = size_ar or ''
    if 'فراولة' in s: return '🍓'
    if 'ليمون' in s: return '🍋'
    if 'تفاح' in s: return '🍎'
    if 'برتقال' in s or 'يوسفي' in s: return '🍊'
    if 'أفوكادو' in s: return '🥑'
    if 'موز' in s: return '🍌'
    if 'بطيخ' in s: return '🍉'
    if 'عنب' in s: return '🍇'
    if 'توت' in s or 'تين' in s: return '🫐'
    if 'خوخ' in s: return '🍑'
    if 'كرز' in s: return '🍒'
    if 'كمثرى' in s: return '🍐'
    if 'رمان' in s: return '🍎'
    if 'باذنجان' in s: return '🍆'
    if 'جزر' in s: return '🥕'
    if 'ذرة' in s: return '🌽'
    if 'قرع' in s or 'يقطين' in s: return '🎃'
    if 'سمسم' in s or 'بذرة' in s or 'حبة' in s: return '🌱'
    if 'بويضة' in s or 'نطفة' in s or 'تحضير' in s: return '✨'
    return '🍎'

def export_fetus_weeks():
    print(f"Reading pregnancy weeks from {DART_WEEKS_FILE}...")
    with open(DART_WEEKS_FILE, "r", encoding="utf-8") as f:
        content = f.read()

    pattern = re.compile(
        r'PregnancyWeekArticle\s*\(\s*'
        r'week:\s*(\d+),\s*'
        r"babySizeAr:\s*'((?:\\'|[^'])*)',\s*"
        r"babySizeEn:\s*'((?:\\'|[^'])*)',\s*"
        r"babyLength:\s*'((?:\\'|[^'])*)',\s*"
        r"babyWeight:\s*'((?:\\'|[^'])*)',\s*"
        r"fetalDevAr:\s*'((?:\\'|[^'])*)',\s*"
        r"fetalDevEn:\s*'((?:\\'|[^'])*)',\s*"
        r"symptomsAr:\s*'((?:\\'|[^'])*)',\s*"
        r"symptomsEn:\s*'((?:\\'|[^'])*)',\s*"
        r"nutritionAr:\s*'((?:\\'|[^'])*)',\s*"
        r"nutritionEn:\s*'((?:\\'|[^'])*)',\s*"
        r"tipsAr:\s*'((?:\\'|[^'])*)',\s*"
        r"tipsEn:\s*'((?:\\'|[^'])*)'",
        re.DOTALL
    )

    weeks = []
    for m in pattern.finditer(content):
        w = {
            "week": int(m.group(1)),
            "babySizeAr": m.group(2).replace(r"\'", "'"),
            "babySizeEn": m.group(3).replace(r"\'", "'"),
            "babyLength": m.group(4).replace(r"\'", "'"),
            "babyWeight": m.group(5).replace(r"\'", "'"),
            "fetalDevAr": m.group(6).replace(r"\'", "'"),
            "fetalDevEn": m.group(7).replace(r"\'", "'"),
            "symptomsAr": m.group(8).replace(r"\'", "'"),
            "nutritionAr": m.group(10).replace(r"\'", "'"),
            "tipsAr": m.group(12).replace(r"\'", "'")
        }
        weeks.append(w)

    week_dict = {w["week"]: w for w in weeks}
    if 1 not in week_dict:
        week_dict[1] = {
            "week": 1,
            "babySizeAr": "بداية الدورة الشهرية (التحضير)",
            "babySizeEn": "Preparation stage",
            "babyLength": "غير مرئي",
            "babyWeight": "غير ملموس",
            "fetalDevAr": "في الأسبوع الأول يبدأ جسمك بالاستعداد لرحلة الحمل الجديدة مع بداية دورتك الشهرية، حيث يتجدد جدار الرحم وتتهيأ البويضات في المبيضين للنضوج.",
            "fetalDevEn": "Your body prepares for pregnancy as the menstrual cycle begins.",
            "symptomsAr": "أعراض بداية الدورة الشهرية الطبيعية والشعور ببعض التعب والتقلصات الخفيفة.",
            "nutritionAr": "تناولي الأطعمة الغنية بالحديد لتعويض الدم المفقود والحرص على شرب السوائل الدافئة والماء بوفرة وحمض الفوليك.",
            "tipsAr": "ابدئي بتناول مكمل حمض الفوليك (400 ميكروغرام) يومياً إذا كنتِ تخططين للحمل، واحرصي على قسط كافٍ من الراحة والنوم."
        }
    if 3 not in week_dict:
        week_dict[3] = {
            "week": 3,
            "babySizeAr": "البويضة المخصبة (الكيسة)",
            "babySizeEn": "Fertilized ovum",
            "babyLength": "0.1 مم",
            "babyWeight": "أقل من 0.1 غرام",
            "fetalDevAr": "في الأسبوع الثالث تلتقي البويضة بالحيوان المنوي في قناة فالوب ويحدث الإخصاب وتتحد الشفرة الجينية وتبدأ الخلايا بالانقسام السريع وتتحرك نحو الرحم.",
            "fetalDevEn": "Fertilization occurs! The zygote divides into multiple cells and travels toward the uterus.",
            "symptomsAr": "لا تظهر عادة أعراض واضحة في هذه المرحلة المبكرة، وقد تشعر بعض النساء بوخز خفيف أو حساسية طفيفة.",
            "nutritionAr": "استمري في تناول الغذاء المتوازن والخضروات الورقية والفواكه والابتعاد التام عن المواد الضارة والأدوية دون استشارة طبية.",
            "tipsAr": "احرصي على شرب الماء وتجنب التوتر والمجهود البدني العنيف، وثقي برعاية الله في هذه البداية المعجزة."
        }

    all_weeks = [week_dict[i] for i in range(1, 41) if i in week_dict]
    all_weeks.sort(key=lambda x: x["week"])
    
    # Save JSON backup
    out_json = os.path.join(DATA_DIR, "fetus_weeks.json")
    with open(out_json, "w", encoding="utf-8") as f:
        json.dump(all_weeks, f, ensure_ascii=False, indent=2)
    print(f"Exported {len(all_weeks)} pregnancy weeks to {out_json}")

    # Build Static HTML for fetus-size.html
    render_fetus_size_html(all_weeks)
    return all_weeks

def render_fetus_size_html(all_weeks):
    print("Pre-rendering static HTML for web/tools/fetus-size.html...")
    
    # Generate Top Quick Nav Links for all 40 weeks
    quick_nav_links = []
    for w in all_weeks:
        num = w["week"]
        quick_nav_links.append(f'<a href="#week-{num}" class="week-nav-item" title="الأسبوع {num}">أسبوع {num}</a>')
    quick_nav_html = '\n        '.join(quick_nav_links)

    # Generate Dropdown Options for all 40 weeks
    dropdown_opts = ['<option value="">اختاري الأسبوع...</option>']
    for w in all_weeks:
        num = w["week"]
        dropdown_opts.append(f'<option value="{num}">الأسبوع {num}</option>')
    dropdown_html = '\n          '.join(dropdown_opts)

    # Generate 40 Static Cards
    cards_html = []
    for item in all_weeks:
        w_num = item["week"]
        tri_num = 1 if w_num <= 13 else (2 if w_num <= 26 else 3)
        tri_text = "الثلث الأول" if tri_num == 1 else ("الثلث الثاني" if tri_num == 2 else "الثلث الثالث")
        fruit_emoji = get_fruit_emoji(item.get("babySizeAr"))
        size_ar = html.escape(item.get("babySizeAr") or "التحضير")
        length_val = html.escape(item.get("babyLength") or "--")
        weight_val = html.escape(item.get("babyWeight") or "--")
        fetal_dev = html.escape(item.get("fetalDevAr") or "")
        symptoms = html.escape(item.get("symptomsAr") or "")
        nutrition = html.escape(item.get("nutritionAr") or "")
        tips = html.escape(item.get("tipsAr") or "")

        card_str = f'''      <section id="week-{w_num}" class="week-card" data-week="{w_num}" data-trimester="{tri_num}">
        <div>
          <div class="week-header">
            <h2 class="week-num-badge">الأسبوع {w_num} من الحمل</h2>
            <span class="trimester-pill">{tri_text}</span>
          </div>
          <div class="fruit-size-title">
            <span>{fruit_emoji}</span>
            <span>بحجم: <strong>{size_ar}</strong></span>
          </div>
          <div class="metrics-bar">
            <div>الطول: <span>{length_val}</span></div>
            <div>•</div>
            <div>الوزن: <span>{weight_val}</span></div>
          </div>
          <p class="week-dev-text">{fetal_dev}</p>
        </div>

        <div>
          <button class="week-expand-btn" onclick="toggleDetails(this)">عرض الأعراض والنصائح ▾</button>
          <div class="week-more-details">
            {f'<div class="detail-section"><strong>أعراض الأم المتوقعة:</strong> {symptoms}</div>' if symptoms else ''}
            {f'<div class="detail-section"><strong>التغذية الموصى بها:</strong> {nutrition}</div>' if nutrition else ''}
            {f'<div class="detail-section"><strong>نصيحة نبضة:</strong> {tips}</div>' if tips else ''}
          </div>
        </div>
      </section>'''
        cards_html.append(card_str)

    all_cards_html = '\n\n'.join(cards_html)

    fetus_html_content = f'''<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>حجم الجنين أسبوعاً بأسبوع — دليلكِ المصور لنمو طفلكِ مع الفواكه | نبضة</title>
  <meta name="description" content="تابعي حجم الجنين أسبوعاً بأسبوع من الأسبوع 1 إلى 40: الطول، الوزن، وتطور الأعضاء مقارنة بأحجام الفواكه والخضار مع نصائح التغذية والأعراض لكل مرحلة من نبضة.">
  <link rel="canonical" href="https://nabda.online/tools/fetus-size.html">
  <link rel="icon" type="image/png" href="../favicon.png">
  <!-- Open Graph -->
  <meta property="og:title" content="حجم الجنين أسبوعاً بأسبوع — دليلكِ المصور لنمو طفلكِ | نبضة">
  <meta property="og:description" content="اكتشفي حجم جنينكِ هذا الأسبوع ووزنه وطوله وتطوراته مقارنة بحجم الفواكه عبر 40 أسبوعاً.">
  <meta property="og:type" content="website">
  <meta property="og:url" content="https://nabda.online/tools/fetus-size.html">
  <meta property="og:image" content="https://nabda.online/landing-assets/slide-pregnancy.png">

  <!-- Fonts -->
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;500;600;700;800;900&family=Tajawal:wght@400;500;700;800&display=swap" rel="stylesheet">

  <script type="application/ld+json">
  {{
    "@context": "https://schema.org",
    "@type": "WebApplication",
    "name": "دليل حجم الجنين أسبوعاً بأسبوع من نبضة",
    "url": "https://nabda.online/tools/fetus-size.html",
    "applicationCategory": "HealthApplication",
    "operatingSystem": "All",
    "description": "دليل طبي مصور لنمو الجنين وتطور أعضائه أسبوعاً بأسبوع عبر 40 أسبوعاً كاملاً."
  }}
  </script>

  <script type="application/ld+json">
  {{
    "@context": "https://schema.org",
    "@type": "FAQPage",
    "mainEntity": [
      {{
        "@type": "Question",
        "name": "كيف يُقاس طول الجنين في السونار؟",
        "acceptedAnswer": {{
          "@type": "Answer",
          "text": "حتى الأسبوع العشرين يُقاس طول الجنين من قمة الرأس إلى أسفل الردف (CRL) لأن ساقي الجنين تكونان منثنيتين. بعد الأسبوع العشرين، يُقاس الطول كاملاً من الرأس إلى الكعب (CHL)."
        }}
      }},
      {{
        "@type": "Question",
        "name": "هل اختلاف وزن الجنين عن الأرقام المتوقعة مقلق؟",
        "acceptedAnswer": {{
          "@type": "Answer",
          "text": "الأرقام المذكورة هي متوسطات إحصائية طبيعية. يختلف كل جنين عن الآخر بناءً على الجينات وطبيعة جسم الوالدين. يعتبر الطبيب الوزن سليماً طالما يقع بين الشريحة المئوية 10 و 90."
        }}
      }},
      {{
        "@type": "Question",
        "name": "متى يبدأ الجنين في اكتساب الوزن السريع؟",
        "acceptedAnswer": {{
          "@type": "Answer",
          "text": "يبدأ الجنين في اكتساب الوزن بسرعة ملحوظة في الثلث الثالث من الحمل (ابتداءً من الأسبوع 28)، حيث يكتسب نحو 200 إلى 250 غراماً كل أسبوع لتكوين طبقات الدهون العازلة للحرارة."
        }}
      }}
    ]
  }}
  </script>

  <style>
    :root {{
      --primary: #E91E63;
      --primary-dark: #C2185B;
      --primary-soft: #FFF0F5;
      --teal: #00897B;
      --teal-light: #E0F2F1;
      --text-dark: #1F1A20;
      --text-muted: #6C6270;
      --bg: #FFF8FB;
      --card-bg: #FFFFFF;
      --border: #F3D3E2;
      --shadow: 0 8px 24px rgba(233, 30, 99, 0.07);
      --font: 'Cairo', 'Tajawal', sans-serif;
    }}

    * {{ box-sizing: border-box; margin: 0; padding: 0; font-family: var(--font); }}
    body {{ background: var(--bg); color: var(--text-dark); line-height: 1.7; direction: rtl; text-align: right; }}
    a {{ text-decoration: none; color: inherit; }}

    /* Header */
    .header {{
      background: rgba(255, 255, 255, 0.9);
      backdrop-filter: blur(12px);
      -webkit-backdrop-filter: blur(12px);
      border-bottom: 1px solid var(--border);
      position: sticky; top: 0; z-index: 100;
      padding: 12px 20px;
    }}
    .header-inner {{
      max-width: 1180px; margin: 0 auto;
      display: flex; align-items: center; justify-content: space-between; gap: 14px;
    }}
    .logo-box {{ display: flex; align-items: center; gap: 10px; }}
    .logo-badge {{
      width: 36px; height: 36px; border-radius: 50%;
      background: linear-gradient(135deg, #F43F7E, #FF8DA1);
      display: flex; align-items: center; justify-content: center;
      color: white; font-size: 18px; box-shadow: 0 4px 12px rgba(244,63,126,.3);
    }}
    .logo-text {{ font-size: 22px; font-weight: 900; color: var(--primary); }}
    .nav-links {{ display: flex; align-items: center; gap: 16px; font-size: 14px; font-weight: 700; }}
    .nav-link {{ color: var(--text-muted); transition: color .2s; }}
    .nav-link:hover, .nav-link.active {{ color: var(--primary); }}
    .app-btn {{
      background: linear-gradient(135deg, var(--primary), #FF4081);
      color: #fff; padding: 8px 18px; border-radius: 999px;
      font-weight: 700; font-size: 13px;
    }}

    /* Container */
    .container {{ max-width: 1100px; margin: 30px auto; padding: 0 20px; }}
    .breadcrumbs {{ font-size: 13px; color: var(--text-muted); margin-bottom: 16px; }}
    .breadcrumbs a {{ color: var(--teal); font-weight: 600; }}

    .hero-title {{ font-size: 32px; font-weight: 900; color: #1a1a1a; margin-bottom: 8px; }}
    .hero-subtitle {{ font-size: 16px; color: var(--text-muted); margin-bottom: 24px; }}

    /* Quick Navigation Nav Bar */
    .weeks-quick-nav {{
      background: white; border: 1px solid var(--border);
      border-radius: 20px; padding: 18px 22px; margin-bottom: 24px;
      box-shadow: var(--shadow);
    }}
    .quick-nav-title {{
      font-size: 14.5px; font-weight: 800; color: var(--primary); margin-bottom: 12px;
      display: flex; align-items: center; gap: 8px;
    }}
    .quick-nav-links {{
      display: flex; flex-wrap: wrap; gap: 6px;
    }}
    .week-nav-item {{
      background: var(--bg); border: 1px solid #ECD4E0;
      color: var(--text-dark); padding: 5px 12px; border-radius: 8px;
      font-size: 12.5px; font-weight: 700; text-decoration: none; transition: all .2s;
    }}
    .week-nav-item:hover {{
      background: var(--primary); color: white; border-color: var(--primary);
    }}

    /* Filter & Quick Navigation Bar */
    .filter-bar {{
      background: white; border: 1px solid var(--border);
      border-radius: 20px; padding: 18px 22px; margin-bottom: 26px;
      display: flex; justify-content: space-between; align-items: center;
      gap: 16px; flex-wrap: wrap; box-shadow: var(--shadow);
    }}
    .trimester-tabs {{ display: flex; gap: 8px; flex-wrap: wrap; }}
    .tab-btn {{
      background: var(--bg); border: 1px solid #ECD4E0;
      color: var(--text-dark); padding: 8px 18px; border-radius: 999px;
      font-size: 13.5px; font-weight: 700; cursor: pointer; transition: all .2s;
    }}
    .tab-btn.active, .tab-btn:hover {{
      background: var(--primary); color: white; border-color: var(--primary);
    }}

    .week-select-box {{ display: flex; align-items: center; gap: 10px; font-size: 14px; font-weight: 700; }}
    .week-dropdown {{
      padding: 8px 14px; border-radius: 12px; border: 1.5px solid #ECD4E0;
      font-size: 14px; font-weight: 700; color: var(--primary); outline: none; background: #fff;
    }}

    /* Weeks Grid */
    .weeks-grid {{
      display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
      gap: 22px; margin-bottom: 40px;
    }}
    .week-card {{
      background: white; border: 1.5px solid #F4DBE7; border-radius: 22px;
      padding: 24px; box-shadow: var(--shadow);
      display: flex; flex-direction: column; justify-content: space-between;
      transition: transform .25s ease, box-shadow .25s ease;
      position: relative; overflow: hidden;
      scroll-margin-top: 100px;
    }}
    .week-card:hover {{ transform: translateY(-4px); box-shadow: 0 14px 30px rgba(233, 30, 99, 0.12); }}
    .week-card.highlight {{ border-color: var(--primary); box-shadow: 0 0 0 3px rgba(233,30,99,.25); }}

    .week-header {{ display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 14px; }}
    .week-num-badge {{
      background: linear-gradient(135deg, var(--primary), #FF6090);
      color: white; padding: 5px 14px; border-radius: 50px;
      font-size: 14px; font-weight: 800; margin: 0; line-height: 1.4;
    }}
    .trimester-pill {{
      font-size: 11.5px; font-weight: 700; color: var(--teal);
      background: var(--teal-light); padding: 4px 10px; border-radius: 50px;
    }}

    .fruit-size-title {{ font-size: 18px; font-weight: 800; color: #1F1A20; margin-bottom: 12px; display: flex; align-items: center; gap: 8px; }}
    .metrics-bar {{
      display: flex; gap: 12px; background: #FFF3F7; border: 1px solid #FCE4EC;
      padding: 10px 14px; border-radius: 14px; margin-bottom: 14px; font-size: 13px; font-weight: 700;
    }}
    .metrics-bar span {{ color: var(--primary-dark); }}

    .week-dev-text {{ font-size: 14px; color: #555; line-height: 1.65; margin-bottom: 14px; flex-grow: 1; }}
    .week-expand-btn {{
      background: none; border: none; color: var(--teal);
      font-weight: 800; font-size: 13px; cursor: pointer; text-align: right; padding: 4px 0;
    }}
    .week-more-details {{
      display: none; padding-top: 14px; border-top: 1px dashed #ECD4E0; margin-top: 10px; font-size: 13px;
    }}
    .week-card.open .week-more-details {{ display: block; }}
    .detail-section {{ margin-bottom: 10px; }}
    .detail-section strong {{ color: var(--primary); display: block; margin-bottom: 2px; }}

    /* SEO Section */
    .article-section {{
      background: white; border-radius: 24px; border: 1px solid var(--border);
      padding: 36px; margin-top: 40px; box-shadow: var(--shadow);
    }}
    .article-section h2 {{ font-size: 22px; font-weight: 800; color: #111; margin: 28px 0 12px; }}
    .article-section h2:first-of-type {{ margin-top: 0; }}
    .article-section p {{ font-size: 15px; color: #4A444C; line-height: 1.8; margin-bottom: 14px; }}
    .article-section ul {{ padding-right: 22px; margin-bottom: 16px; color: #4A444C; font-size: 15px; }}
    .article-section li {{ margin-bottom: 8px; }}

    /* FAQ */
    .faq-item {{ border: 1px solid #F0DDE6; border-radius: 14px; margin-bottom: 12px; overflow: hidden; }}
    .faq-q {{ padding: 16px 20px; background: #FFFBFD; font-weight: 700; font-size: 15px; cursor: pointer; display: flex; justify-content: space-between; }}
    .faq-a {{ padding: 16px 20px; font-size: 14.5px; color: #555; background: #fff; border-top: 1px solid #F0DDE6; display: none; }}
    .faq-item.open .faq-a {{ display: block; }}
    .faq-item.open .faq-q {{ color: var(--primary); }}

    /* Footer */
    .footer {{
      background: #fff; border-top: 1px solid var(--border);
      padding: 40px 20px; margin-top: 60px; text-align: center; font-size: 13.5px; color: var(--text-muted);
    }}
    .footer-links {{ display: flex; justify-content: center; gap: 18px; flex-wrap: wrap; margin-bottom: 16px; font-weight: 600; }}
    .footer-links a:hover {{ color: var(--primary); }}
  </style>
</head>
<body>

  <!-- Header -->
  <header class="header">
    <div class="header-inner">
      <a href="/" class="logo-box">
        <div class="logo-badge">♥</div>
        <span class="logo-text">نبضة</span>
      </a>
      <nav class="nav-links">
        <a href="/" class="nav-link">الرئيسية</a>
        <a href="/tools/due-date.html" class="nav-link">حاسبة الولادة</a>
        <a href="/tools/ovulation.html" class="nav-link">التبويض والخصوبة</a>
        <a href="/tools/baby-names.html" class="nav-link">أسماء المواليد</a>
        <a href="/tools/fetus-size.html" class="nav-link active">حجم الجنين</a>
        <a href="/articles.html" class="nav-link">موسوعة نبضة</a>
        <a href="/shop" class="nav-link">المتجر</a>
      </nav>
      <a href="/" class="app-btn">تطبيق نبضة</a>
    </div>
  </header>

  <main class="container">
    <div class="breadcrumbs">
      <a href="/">الرئيسية</a> / <span>أدوات الحمل</span> / <span>حجم وتطور الجنين</span>
    </div>

    <h1 class="hero-title">حجم الجنين أسبوعاً بأسبوع (من الأسبوع 1 إلى 40) 🍎</h1>
    <p class="hero-subtitle">دليلكِ الطبي المتكامل لمعرفة مقاسات جنينكِ، طوله ووزنه، والتطورات المعجزة لكل مرحلة مقارنة بالفواكه والخضروات اللطيفة.</p>

    <!-- Top Navigation Links (All 40 Weeks) -->
    <nav class="weeks-quick-nav" aria-label="روابط سريعة لأسابيع الحمل">
      <div class="quick-nav-title">🔗 تصفحي أسابيع الحمل مباشرة:</div>
      <div class="quick-nav-links">
        {quick_nav_html}
      </div>
    </nav>

    <!-- Filter & Navigation Bar -->
    <div class="filter-bar">
      <div class="trimester-tabs">
        <button class="tab-btn active" onclick="filterTrimester('all', this)">جميع الأسابيع (40)</button>
        <button class="tab-btn" onclick="filterTrimester('1', this)">الثلث الأول (1 - 13)</button>
        <button class="tab-btn" onclick="filterTrimester('2', this)">الثلث الثاني (14 - 26)</button>
        <button class="tab-btn" onclick="filterTrimester('3', this)">الثلث الثالث (27 - 40)</button>
      </div>

      <div class="week-select-box">
        <label for="weekJump">انتقلي للأسبوع:</label>
        <select id="weekJump" class="week-dropdown" onchange="jumpToWeek(this.value)">
          {dropdown_html}
        </select>
      </div>
    </div>

    <!-- Weeks Grid (Pre-rendered Static HTML) -->
    <div class="weeks-grid" id="weeksGrid">
{all_cards_html}
    </div>

    <!-- Educational SEO Guide -->
    <article class="article-section">
      <h2>كيف يُقاس حجم الجنين ووزنه خلال أشهر الحمل؟</h2>
      <p>يعد تتبع حجم الجنين ونموه واحداً من أهم الفحوصات الطبية الدورية التي يحرص عليها أطباء النساء والتوليد. في النصف الأول من الحمل، وتحديداً حتى الأسبوع العشرين، يكون الجنين ملتفاً وساقاه منثنيتين نحو صدره، لذلك يقيس الأطباء طول الجنين من أعلى الرأس إلى أسفل الردف (Crown-Rump Length - CRL).</p>
      <p>أما بدءاً من الأسبوع العشرين وحتى موعد الولادة، فيصبح من الممكن قياس طول الجنين كاملاً من الرأس إلى الكعب (Crown-Heel Length - CHL). كما يعتمد الأطباء في تقدير وزن الجنين على معادلة هادلوك (Hadlock Formula) التي تدمج قياسات محيط الرأس (HC)، القطر ثنائي الجدار (BPD)، محيط البطن (AC)، وطول عظم الفخذ (FL).</p>

      <h2>لماذا نستخدم الفواكه لتشبيه حجم الجنين؟</h2>
      <p>يساعد تشبيه حجم الجنين بحبات الفواكه والخضار الأمهات والآباء على استيعاب الحجم الحقيقي لأطفالهم بصورة ملموسة ومرئية في الحياة اليومية. فمن حبة سمسم مجهرية في الأسبوع الخامس، ينمو الجنين ليصبح بحجم حبة أفوكادو في الأسبوع السادس عشر، ثم كوز ذرة في الأسبوع الرابع والعشرين، وصولاً إلى حجم البطيخة الكاملة في الأسبوع الأربعين!</p>

      <h2>محطات معجزة في تطور الجنين عبر الأثلاث</h2>
      <ul>
        <li><strong>الأسبوع 6:</strong> يبدأ القلب الصغير بالنبض بمعدل يتراوح بين 100 و 160 نبضة في الدقيقة، وتتشكل براعم الذراعين والساقين.</li>
        <li><strong>الأسبوع 12:</strong> تكتمل الأعضاء الحيوية الأساسية، وتبدأ الكليتان في إفراز البول في السائل الأمنيوسي، وتتشكل براعم الأسنان اللبنية تحت اللثة.</li>
        <li><strong>الأسبوع 20:</strong> منتصف الرحلة! يستطيع الجنين الآن سماع نبضات قلب أمه والأصوات الخارجية، وتبدأ الأم بالشعور بحركاته الرقيقة بوضوح.</li>
        <li><strong>الأسبوع 28:</strong> يستطيع الجنين فتح عينيه والرمش، ويبدأ دورات منتظمة من النوم واليقظة، مع استمرار نضج الرئتين لامتصاص الأكسجين بعد الولادة.</li>
        <li><strong>الأسبوع 37:</strong> يُعتبر الجنين الآن مكتمل النمو طبياً (Full Term)، وأي ولادة بعد هذا التاريخ تعد ولادة طبيعية في موعدها.</li>
      </ul>

      <h2>الأسئلة الشائعة حول نمو الجنين</h2>
      <div class="faq-item">
        <div class="faq-q" onclick="toggleFaq(this)">ماذا يعني وجود الجنين في الشريحة المئوية 50؟ <span>▾</span></div>
        <div class="faq-a">الشريحة المئوية 50 تعني أن وزن جنينك يطابق تماماً المتوسط الإحصائي العام للأجنة في نفس هذا الأسبوع. تعتبر أي قراءة بين الشريحة 10 والشريحة 90 قراءة طبيعية وصحية تماماً.</div>
      </div>
      <div class="faq-item">
        <div class="faq-q" onclick="toggleFaq(this)">هل حركة الجنين الكثيرة تدل على كبر حجمه؟ <span>▾</span></div>
        <div class="faq-a">حركة الجنين تدل بالأساس على نشاط جهازه العصبي وسلامة تدفق الدم والأكسجين إليه، ولا ترتبط بالضرورة بحجم أو وزن الجنين.</div>
      </div>
      <div class="faq-item">
        <div class="faq-q" onclick="toggleFaq(this)">ما هي الأغذية التي تساعد على زيادة وزن الجنين الصحي؟ <span>▾</span></div>
        <div class="faq-a">البروتينات عالية الجودة (البيض، اللحوم الخالية من الدهون، البقوليات)، منتجات الألبان الغنية بالكالسيوم، المكسرات النيئة، والخضروات الورقية الغنية بالحديد وحمض الفوليك.</div>
      </div>
    </article>
  </main>

  <!-- Footer -->
  <footer class="footer">
    <div class="footer-links">
      <a href="/">الرئيسية</a>
      <a href="/tools/due-date.html">حاسبة الولادة</a>
      <a href="/tools/ovulation.html">حاسبة التبويض</a>
      <a href="/tools/baby-names.html">أسماء المواليد</a>
      <a href="/tools/fetus-size.html">حجم الجنين</a>
      <a href="/articles.html">موسوعة نبضة</a>
      <a href="/shop">المتجر</a>
      <a href="/privacy.html">سياسة الخصوصية</a>
      <a href="/terms.html">شروط الاستخدام</a>
    </div>
    <p>© 2026 نبضة (Nabda). جميع الحقوق محفوظة. المحتوى لأغراض تثقيفية وإرشادية ولا يغني عن الاستشارة الطبية المتخصصة.</p>
  </footer>

  <script>
    function filterTrimester(tri, btn) {{
      document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');

      const cards = document.querySelectorAll('.week-card');
      cards.forEach(card => {{
        if (tri === 'all') {{
          card.style.display = '';
        }} else {{
          card.style.display = card.getAttribute('data-trimester') === String(tri) ? '' : 'none';
        }}
      }});
    }}

    function toggleDetails(btn) {{
      const card = btn.closest('.week-card');
      card.classList.toggle('open');
      btn.textContent = card.classList.contains('open') ? 'إخفاء التفاصيل ▴' : 'عرض الأعراض والنصائح ▾';
    }}

    function jumpToWeek(weekNum) {{
      if (!weekNum) return;
      const allBtn = document.querySelectorAll('.tab-btn')[0];
      if (allBtn && !allBtn.classList.contains('active')) {{
        filterTrimester('all', allBtn);
      }}
      setTimeout(() => {{
        const target = document.getElementById(`week-${{weekNum}}`);
        if (target) {{
          target.scrollIntoView({{ behavior: 'smooth', block: 'center' }});
          target.classList.add('highlight');
          setTimeout(() => target.classList.remove('highlight'), 2500);
        }}
      }}, 50);
    }}

    function checkHash() {{
      if (window.location.hash) {{
        const wMatch = window.location.hash.match(/week-(\\d+)/);
        if (wMatch && wMatch[1]) {{
          jumpToWeek(wMatch[1]);
        }}
      }}
    }}

    function toggleFaq(el) {{
      el.parentElement.classList.toggle('open');
    }}

    window.addEventListener('load', checkHash);
    window.addEventListener('hashchange', checkHash);
  </script>
</body>
</html>
'''

    with open(FETUS_HTML_FILE, "w", encoding="utf-8") as f:
        f.write(fetus_html_content)
    print(f"Generated static fetus-size.html ({len(fetus_html_content.encode('utf-8'))} bytes)")

# ══════════════════════════════════════════════════════════════
# 3. Extract & Pre-render Baby Names (baby-names.html + /names/{slug}.html)
# ══════════════════════════════════════════════════════════════

def export_baby_names():
    print(f"Reading baby names from {DART_NAMES_FILE}...")
    with open(DART_NAMES_FILE, "r", encoding="utf-8") as f:
        content = f.read()

    pattern = re.compile(
        r"BabyName\(\s*'((?:\\'|[^'])+)',\s*'([^']+)',\s*'((?:\\'|[^'])+)',\s*(\d+),\s*\[([^\]]*)\],\s*isIslamic:\s*(true|false),\s*famousPeople:\s*\[([^\]]*)\]\s*\)"
    )

    names = []
    for m in pattern.finditer(content):
        name = m.group(1).replace(r"\'", "'")
        gender = m.group(2)
        meaning = m.group(3).replace(r"\'", "'")
        popularity = int(m.group(4))
        
        countries_raw = m.group(5)
        countries = [c.strip().strip("'").strip('"') for c in countries_raw.split(',') if c.strip()]
        
        is_islamic = m.group(6) == 'true'
        famous_raw = m.group(7)
        famous = [p.strip().strip("'").replace(r"\'", "'") for p in re.findall(r"'((?:\\'|[^'])+)'", famous_raw)]
        
        names.append({
            "name": name,
            "gender": gender,
            "meaning": meaning,
            "popularity": popularity,
            "countries": countries,
            "isIslamic": is_islamic,
            "famousPeople": famous
        })

    # Save JSON backup
    out_json = os.path.join(DATA_DIR, "baby_names.json")
    with open(out_json, "w", encoding="utf-8") as f:
        json.dump(names, f, ensure_ascii=False, indent=2)
    print(f"Exported {len(names)} baby names to {out_json}")

    # Build Slug Mapping
    slug_map = build_slug_map(names)
    
    # Pre-render web/tools/baby-names.html with all 1,765 names statically in HTML
    render_baby_names_main_html(names, slug_map)

    # Pre-render 1,765 individual name pages in web/tools/names/{slug}.html
    render_individual_name_pages(names, slug_map)

    # Pre-render sitemap.xml
    render_sitemap(names, slug_map)

    return names, slug_map

def build_slug_map(names):
    slug_file = os.path.join(DATA_DIR, "name_slugs.json")
    slug_map = {}
    if os.path.exists(slug_file):
        try:
            with open(slug_file, "r", encoding="utf-8") as f:
                slug_map = json.load(f)
        except Exception:
            slug_map = {}

    used_slugs = set(slug_map.values())
    changed = False

    for item in names:
        n = item["name"]
        if n not in slug_map:
            base_slug = transliterate_arabic(n)
            slug = base_slug
            c = 2
            while slug in used_slugs:
                slug = f"{base_slug}-{c}"
                c += 1
            used_slugs.add(slug)
            slug_map[n] = slug
            changed = True

    with open(slug_file, "w", encoding="utf-8") as f:
        json.dump(slug_map, f, ensure_ascii=False, indent=2)

    return slug_map

def normalize_ar(text):
    if not text:
        return ""
    t = text
    t = re.sub(r'[أإآ]', 'ا', t)
    t = re.sub(r'ة', 'ه', t)
    t = re.sub(r'ى', 'ي', t)
    t = re.sub(r'[\u064B-\u065F]', '', t)
    return t.lower().strip()

def render_baby_names_main_html(names, slug_map):
    print("Pre-rendering static HTML for web/tools/baby-names.html...")
    
    # Generate compact cards for all 1,765 names (< 400 KB total file size)
    cards_html = []
    for item in names:
        name = item["name"]
        slug = slug_map[name]
        is_girl = item["gender"] in ["female", "girl", "بنت"]
        g_cls = "girl" if is_girl else "boy"
        g_val = "f" if is_girl else "m"
        is_islamic = item.get("isIslamic", False)
        q_val = "1" if is_islamic else "0"
        pop = item.get("popularity", 50)
        meaning = item.get("meaning", "").strip()
        
        if len(meaning) > 28:
            short_meaning = meaning[:26].rsplit(' ', 1)[0] + '…'
        else:
            short_meaning = meaning

        esc_name = html.escape(name)
        esc_meaning = html.escape(short_meaning)
        first_country = item.get("countries", ["العالم العربي"])[0] if item.get("countries") else "العالم العربي"
        esc_countries = html.escape(first_country)

        card = (
            f'<li class="name {g_cls}" data-g="{g_val}" data-q="{q_val}" data-p="{pop}">'
            f'<a href="/tools/names/{slug}.html"><h3>{esc_name}</h3></a>'
            f'<p>{esc_meaning}</p>'
            f'<span class="countries">{esc_countries}</span>'
            f'</li>'
        )
        cards_html.append(card)

    all_cards_str = '\n'.join(cards_html)

    html_content = f'''<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>معجم أسماء المواليد ومعانيها — أكثر من 1,760 اسم عربي وإسلامي للبنات والأولاد | نبضة</title>
  <meta name="description" content="ابحثي في أكبر معجم لأسماء المواليد العربية والإسلامية (1,760+ اسم): معاني الأسماء الدقيقة، أسماء البنات والأولاد، الأسماء القرآنية، وشعبيتها في مختلف الدول العربية عبر نبضة.">
  <link rel="canonical" href="https://nabda.online/tools/baby-names.html">
  <link rel="icon" type="image/png" href="../favicon.png">
  <!-- Open Graph -->
  <meta property="og:title" content="معجم أسماء المواليد ومعانيها | نبضة">
  <meta property="og:description" content="أكثر من 1,760 اسماً عربياً وإسلامياً للبنات والأولاد مع المعاني والشعبية.">
  <meta property="og:type" content="website">
  <meta property="og:url" content="https://nabda.online/tools/baby-names.html">
  <meta property="og:image" content="https://nabda.online/landing-assets/slide-baby.png">

  <!-- Fonts -->
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;500;600;700;800;900&family=Tajawal:wght@400;500;700;800&display=swap" rel="stylesheet">

  <script type="application/ld+json">
  {{
    "@context": "https://schema.org",
    "@type": "WebApplication",
    "name": "معجم أسماء المواليد من نبضة",
    "url": "https://nabda.online/tools/baby-names.html",
    "applicationCategory": "HealthApplication",
    "operatingSystem": "All",
    "description": "قاعدة بيانات شاملة تضم أكثر من 1760 اسماً للمواليد مع المعاني والأصول والتصنيفات الإسلامية."
  }}
  </script>

  <style>
    :root {{
      --primary: #E91E63;
      --primary-dark: #C2185B;
      --primary-soft: #FFF0F5;
      --girl-pink: #F06292;
      --girl-bg: #FCE4EC;
      --boy-blue: #1E88E5;
      --boy-bg: #E3F2FD;
      --islamic-gold: #D89E00;
      --islamic-bg: #FFF9E6;
      --teal: #00897B;
      --text-dark: #1F1A20;
      --text-muted: #6C6270;
      --bg: #FFF8FB;
      --card-bg: #FFFFFF;
      --border: #F3D3E2;
      --shadow: 0 8px 24px rgba(233, 30, 99, 0.07);
      --font: 'Cairo', 'Tajawal', sans-serif;
    }}

    * {{ box-sizing: border-box; margin: 0; padding: 0; font-family: var(--font); }}
    body {{ background: var(--bg); color: var(--text-dark); line-height: 1.7; direction: rtl; text-align: right; }}
    a {{ text-decoration: none; color: inherit; }}

    /* Header */
    .header {{
      background: rgba(255, 255, 255, 0.9);
      backdrop-filter: blur(12px);
      -webkit-backdrop-filter: blur(12px);
      border-bottom: 1px solid var(--border);
      position: sticky; top: 0; z-index: 100;
      padding: 12px 20px;
    }}
    .header-inner {{
      max-width: 1180px; margin: 0 auto;
      display: flex; align-items: center; justify-content: space-between; gap: 14px;
    }}
    .logo-box {{ display: flex; align-items: center; gap: 10px; }}
    .logo-badge {{
      width: 36px; height: 36px; border-radius: 50%;
      background: linear-gradient(135deg, #F43F7E, #FF8DA1);
      display: flex; align-items: center; justify-content: center;
      color: white; font-size: 18px; box-shadow: 0 4px 12px rgba(244,63,126,.3);
    }}
    .logo-text {{ font-size: 22px; font-weight: 900; color: var(--primary); }}
    .nav-links {{ display: flex; align-items: center; gap: 16px; font-size: 14px; font-weight: 700; }}
    .nav-link {{ color: var(--text-muted); transition: color .2s; }}
    .nav-link:hover, .nav-link.active {{ color: var(--primary); }}
    .app-btn {{
      background: linear-gradient(135deg, var(--primary), #FF4081);
      color: #fff; padding: 8px 18px; border-radius: 999px;
      font-weight: 700; font-size: 13px;
    }}

    /* Container */
    .container {{ max-width: 1100px; margin: 30px auto; padding: 0 20px; }}
    .breadcrumbs {{ font-size: 13px; color: var(--text-muted); margin-bottom: 16px; }}
    .breadcrumbs a {{ color: var(--teal); font-weight: 600; }}

    .hero-title {{ font-size: 32px; font-weight: 900; color: #1a1a1a; margin-bottom: 8px; }}
    .hero-subtitle {{ font-size: 16px; color: var(--text-muted); margin-bottom: 24px; }}

    /* Search & Filter Box */
    .search-panel {{
      background: white; border: 1.5px solid var(--border);
      border-radius: 24px; padding: 26px; box-shadow: var(--shadow);
      margin-bottom: 30px;
    }}
    .search-input-wrap {{ position: relative; margin-bottom: 20px; }}
    .search-input {{
      width: 100%; padding: 15px 52px 15px 20px; border-radius: 16px;
      border: 1.5px solid #E2D1DA; background: #FFFDFE;
      font-size: 16px; font-weight: 700; color: #222; outline: none;
      transition: border-color .2s, box-shadow .2s;
    }}
    .search-input:focus {{ border-color: var(--primary); box-shadow: 0 0 0 3px rgba(233,30,99,.12); }}
    .search-icon {{
      position: absolute; right: 18px; top: 50%; transform: translateY(-50%);
      font-size: 20px; color: var(--text-muted);
    }}

    .filters-row {{
      display: flex; justify-content: space-between; align-items: center;
      gap: 12px; flex-wrap: wrap;
    }}
    .gender-tabs {{ display: flex; gap: 8px; flex-wrap: wrap; }}
    .filter-tab {{
      background: var(--bg); border: 1px solid #ECD4E0;
      color: var(--text-dark); padding: 8px 18px; border-radius: 999px;
      font-size: 13.5px; font-weight: 700; cursor: pointer; transition: all .2s;
    }}
    .filter-tab.active, .filter-tab:hover {{
      background: var(--primary); color: white; border-color: var(--primary);
    }}
    .results-count {{ font-size: 14px; font-weight: 700; color: var(--text-muted); }}

    /* Names Grid */
    .names-grid {{
      list-style: none; display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
      gap: 18px; margin-bottom: 30px; padding: 0;
    }}
    .name {{
      background: white; border: 1.5px solid #F5DBE7; border-radius: 20px;
      padding: 20px; box-shadow: var(--shadow);
      display: flex; flex-direction: column; justify-content: space-between;
      transition: transform .2s, box-shadow .2s; position: relative;
    }}
    .name:hover {{ transform: translateY(-3px); box-shadow: 0 10px 26px rgba(233, 30, 99, 0.1); border-color: var(--primary); }}
    .name.girl {{ border-color: #F8BBD0; }}
    .name.boy {{ border-color: #BBDEFB; }}
    .name.card-hidden {{ display: none !important; }}

    .name h3 {{ font-size: 22px; font-weight: 900; color: #1a1a1a; margin-bottom: 8px; }}
    .name a:hover h3 {{ color: var(--primary); }}
    .name p {{ font-size: 14px; color: #4A444C; line-height: 1.6; margin-bottom: 12px; flex-grow: 1; }}
    .name .countries {{ font-size: 12.5px; color: var(--text-muted); border-top: 1px solid #F4E7EE; padding-top: 10px; display: block; }}
    .name .countries::before {{ content: 'شائع في: '; font-weight: 700; color: #888; }}

    /* Load more button */
    .load-more-box {{ text-align: center; margin: 30px 0; }}
    .load-more-btn {{
      background: white; border: 1.5px solid var(--primary); color: var(--primary);
      padding: 12px 36px; border-radius: 999px; font-size: 15px; font-weight: 800;
      cursor: pointer; transition: all .2s;
    }}
    .load-more-btn:hover {{ background: var(--primary); color: white; }}

    /* SEO Section */
    .article-section {{
      background: white; border-radius: 24px; border: 1px solid var(--border);
      padding: 36px; margin-top: 40px; box-shadow: var(--shadow);
    }}
    .article-section h2 {{ font-size: 22px; font-weight: 800; color: #111; margin: 28px 0 12px; }}
    .article-section h2:first-of-type {{ margin-top: 0; }}
    .article-section p {{ font-size: 15px; color: #4A444C; line-height: 1.8; margin-bottom: 14px; }}
    .article-section ul {{ padding-right: 22px; margin-bottom: 16px; color: #4A444C; font-size: 15px; }}
    .article-section li {{ margin-bottom: 8px; }}

    /* Toast */
    .toast {{
      position: fixed; bottom: 30px; left: 50%; transform: translateX(-50%);
      background: rgba(30, 26, 32, 0.9); color: white;
      padding: 10px 24px; border-radius: 50px; font-size: 13.5px; font-weight: 700;
      display: none; z-index: 1000; box-shadow: 0 8px 24px rgba(0,0,0,0.2);
    }}

    /* Footer */
    .footer {{
      background: #fff; border-top: 1px solid var(--border);
      padding: 40px 20px; margin-top: 60px; text-align: center; font-size: 13.5px; color: var(--text-muted);
    }}
    .footer-links {{ display: flex; justify-content: center; gap: 18px; flex-wrap: wrap; margin-bottom: 16px; font-weight: 600; }}
    .footer-links a:hover {{ color: var(--primary); }}
  </style>
</head>
<body>

  <!-- Header -->
  <header class="header">
    <div class="header-inner">
      <a href="/" class="logo-box">
        <div class="logo-badge">♥</div>
        <span class="logo-text">نبضة</span>
      </a>
      <nav class="nav-links">
        <a href="/" class="nav-link">الرئيسية</a>
        <a href="/tools/due-date.html" class="nav-link">حاسبة الولادة</a>
        <a href="/tools/ovulation.html" class="nav-link">التبويض والخصوبة</a>
        <a href="/tools/baby-names.html" class="nav-link active">أسماء المواليد</a>
        <a href="/tools/fetus-size.html" class="nav-link">حجم الجنين</a>
        <a href="/articles.html" class="nav-link">موسوعة نبضة</a>
        <a href="/shop" class="nav-link">المتجر</a>
      </nav>
      <a href="/" class="app-btn">تطبيق نبضة</a>
    </div>
  </header>

  <main class="container">
    <div class="breadcrumbs">
      <a href="/">الرئيسية</a> / <span>أدوات الأطفال</span> / <span>معجم أسماء المواليد</span>
    </div>

    <h1 class="hero-title">معجم أسماء المواليد ومعانيها (1,760+ اسم) 🌸</h1>
    <p class="hero-subtitle">اكتشفي أجمل الأسماء العربية والإسلامية للبنات والأولاد مع معانيها الدقيقة، شعبيتها في الدول العربية، والأسماء القرآنية الخالدة.</p>

    <!-- Search Panel -->
    <div class="search-panel">
      <div class="search-input-wrap">
        <span class="search-icon">🔍</span>
        <input type="text" id="nameSearch" class="search-input" placeholder="ابحثي عن اسم أو معنى محدد (مثال: مريم، نور، سيف، الجمال...)" oninput="handleSearch()">
      </div>

      <div class="filters-row">
        <div class="gender-tabs">
          <button class="filter-tab active" onclick="setGenderFilter('all', this)">الكل ({len(names)})</button>
          <button class="filter-tab" onclick="setGenderFilter('girl', this)">بنات 👧</button>
          <button class="filter-tab" onclick="setGenderFilter('boy', this)">أولاد 👦</button>
          <button class="filter-tab" onclick="setGenderFilter('islamic', this)">قرآنية وإسلامية ✨</button>
          <button class="filter-tab" onclick="setGenderFilter('popular', this)">الأكثر شيوعاً ⭐</button>
        </div>
        <div class="results-count" id="countDisplay">{len(names)} اسماً متاحاً</div>
      </div>
    </div>

    <!-- Names Grid (1,765 Pre-rendered Static HTML Elements) -->
    <ul class="names-grid" id="namesGrid">
{all_cards_str}
    </ul>

    <div class="load-more-box" id="loadMoreBox">
      <button class="load-more-btn" onclick="renderMore()">عرض المزيد من الأسماء (100+)</button>
    </div>

    <!-- Educational SEO Guide -->
    <article class="article-section">
      <h2>كيف تختارين اسماً جميلاً ومباركاً لمولودكِ؟</h2>
      <p>اختيار اسم المولود هو الهدية الأولى والدائمة التي يقدمها الوالدان لطفلهما، وله أثر نفسي واجتماعي عميق يرافقه طوال مسيرة حياته. وقد حثّ الإسلام على إحسان اختيار الأسماء، فقد رُوي عن النبي ﷺ قوله: <em>«إنكم تُدعون يوم القيامة بأسمائكم وأسماء آبائكم، فأحسنوا أسماءكم»</em>.</p>

      <h2>قواعد وضوابط اختيار الأسماء في الثقافة العربية والإسلامية</h2>
      <ul>
        <li><strong>أحب الأسماء إلى الله:</strong> ما عُبّد وحُمّد، مثل: عبد الله، عبد الرحمن، محمد، أحمد، ومحمود.</li>
        <li><strong>أسماء الأنبياء والصالحين والصحابيات:</strong> مثل إبراهيم، يوسف، موسى، عيسى، مريم، خديجة، عائشة، وفاطمة، لما تحمله من قدوة وبركة وتاريخ مشرف.</li>
        <li><strong>وضوح المعنى وجماله:</strong> اختيار الأسماء التي تحمل دلالات رقيقة ومحمودة كالجمال، النور، الصبر، العزة، والنقاء، والابتعاد عن الأسماء ذات المعاني الحزينة أو المذمومة.</li>
        <li><strong>ملاءمة النطق والتناغم:</strong> مراعاة سهولة نطق الاسم وتناغمه مع اسم الأب واللقب العائلي دون ثقل في مخارج الحروف.</li>
      </ul>

      <h2>أسماء التوائم المتناسقة</h2>
      <p>إذا كنتِ تنتظرين توأماً، فإن التناسق اللفظي أو المعنوي يضفي سحراً خاصاً، مثل الجمع بين (آية وليان)، (ريان وريمان)، (عمر وعلي)، أو (يوسف ويونس). يضم تطبيق نبضة قسماً خاصاً لأكثر من 80 ثنائياً توأمياً متناغماً تم اختياره بعناية فائقة.</p>
    </article>
  </main>

  <div id="toast" class="toast">تم نسخ تفاصيل الاسم بنجاح! 📋</div>

  <!-- Footer -->
  <footer class="footer">
    <div class="footer-links">
      <a href="/">الرئيسية</a>
      <a href="/tools/due-date.html">حاسبة الولادة</a>
      <a href="/tools/ovulation.html">حاسبة التبويض</a>
      <a href="/tools/baby-names.html">أسماء المواليد</a>
      <a href="/tools/fetus-size.html">حجم الجنين</a>
      <a href="/articles.html">موسوعة نبضة</a>
      <a href="/shop">المتجر</a>
      <a href="/privacy.html">سياسة الخصوصية</a>
      <a href="/terms.html">شروط الاستخدام</a>
    </div>
    <p>© 2026 نبضة (Nabda). جميع الحقوق محفوظة. المحتوى لأغراض تثقيفية وإرشادية.</p>
  </footer>

  <script>
    let currentGender = 'all';
    let currentLimit = 150;
    const cards = Array.from(document.querySelectorAll('.name'));
    const cardData = cards.map(c => ({{
      el: c,
      g: c.getAttribute('data-g'),
      q: c.getAttribute('data-q') === '1',
      p: parseInt(c.getAttribute('data-p') || '0', 10),
      text: normalizeAr(c.textContent)
    }}));

    function normalizeAr(str) {{
      if (!str) return '';
      return str
        .replace(/[أإآ]/g, 'ا')
        .replace(/ة/g, 'ه')
        .replace(/ى/g, 'ي')
        .replace(/[\\u064B-\\u065F]/g, '')
        .toLowerCase()
        .trim();
    }}

    function applyFilters() {{
      const q = normalizeAr(document.getElementById('nameSearch').value);
      let matchCount = 0;
      let visibleCount = 0;

      cardData.forEach(item => {{
        let passGender = true;
        if (currentGender === 'girl') passGender = (item.g === 'f');
        else if (currentGender === 'boy') passGender = (item.g === 'm');
        else if (currentGender === 'islamic') passGender = item.q;
        else if (currentGender === 'popular') passGender = (item.p >= 85);

        let passSearch = true;
        if (q) {{
          passSearch = item.text.includes(q);
        }}

        if (passGender && passSearch) {{
          matchCount++;
          if (matchCount <= currentLimit) {{
            item.el.classList.remove('card-hidden');
            visibleCount++;
          }} else {{
            item.el.classList.add('card-hidden');
          }}
        }} else {{
          item.el.classList.add('card-hidden');
        }}
      }});

      document.getElementById('countDisplay').textContent = `${{matchCount}} اسماً متاحاً`;
      const loadMoreBox = document.getElementById('loadMoreBox');
      loadMoreBox.style.display = (visibleCount < matchCount) ? 'block' : 'none';
    }}

    function setGenderFilter(filter, btn) {{
      document.querySelectorAll('.filter-tab').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      currentGender = filter;
      currentLimit = 150;
      applyFilters();
    }}

    function handleSearch() {{
      currentLimit = 150;
      applyFilters();
    }}

    function renderMore() {{
      currentLimit += 150;
      applyFilters();
    }}

    applyFilters();
  </script>
</body>
</html>
'''

    with open(NAMES_HTML_FILE, "w", encoding="utf-8") as f:
        f.write(html_content)
    size_kb = len(html_content.encode('utf-8')) / 1024
    print(f"Generated static baby-names.html ({size_kb:.1f} KB)")

# ══════════════════════════════════════════════════════════════
# 4. Generate 1,765 Standalone Individual Name Pages
# ══════════════════════════════════════════════════════════════

def render_individual_name_pages(names, slug_map):
    print(f"Generating 1,765 individual name pages in {NAMES_DIR}...")
    
    # Pre-index names by first letter and gender for fast related names lookup
    by_letter_gender = {}
    for item in names:
        first_letter = item["name"][0] if item["name"] else ""
        gender = item["gender"]
        key = (first_letter, gender)
        by_letter_gender.setdefault(key, []).append(item)

    for item in names:
        name = item["name"]
        slug = slug_map[name]
        is_girl = item["gender"] in ["female", "girl", "بنت"]
        g_cls = "girl" if is_girl else "boy"
        g_label = "بنت 👧" if is_girl else "ولد 👦"
        is_islamic = item.get("isIslamic", False)
        pop = item.get("popularity", 50)
        meaning = item.get("meaning", "")
        countries = item.get("countries", [])
        famous = item.get("famousPeople", [])

        # Find 10 related names:
        first_letter = name[0] if name else ""
        related_pool = [n for n in by_letter_gender.get((first_letter, item["gender"]), []) if n["name"] != name]
        if len(related_pool) < 10:
            # Add same first letter other gender
            other_g = [n for n in names if n["name"] != name and n["name"].startswith(first_letter) and n not in related_pool]
            related_pool.extend(other_g)
        if len(related_pool) < 10:
            # Add popular names of same gender
            same_g = [n for n in names if n["name"] != name and n["gender"] == item["gender"] and n not in related_pool]
            related_pool.extend(same_g[:(10 - len(related_pool))])
        
        related_10 = related_pool[:10]
        related_chips = []
        for rel in related_10:
            rel_slug = slug_map.get(rel["name"], "name")
            rel_g = "girl" if rel["gender"] in ["female", "girl", "بنت"] else "boy"
            related_chips.append(
                f'<a href="/tools/names/{rel_slug}.html" class="related-chip {rel_g}">'
                f'<strong>{html.escape(rel["name"])}</strong>'
                f'<span>{html.escape(rel["meaning"][:45])}...</span>'
                f'</a>'
            )
        related_html = '\n          '.join(related_chips)

        countries_chips = [f'<span class="country-pill">{html.escape(c)}</span>' for c in countries]
        countries_html = ' '.join(countries_chips) if countries_chips else '<span class="country-pill">كافة الدول العربية</span>'

        famous_html = ""
        if famous:
            famous_items = [f'<li><strong>{html.escape(p)}</strong></li>' for p in famous]
            famous_html = f'''
        <div class="detail-block">
          <h2>شخصيات تاريخية وبارزة تحمل اسم {html.escape(name)}</h2>
          <ul class="famous-list">
            {''.join(famous_items)}
          </ul>
        </div>
            '''

        page_title = f"معنى اسم {name} — أصله ودلالته وشيوعه ومشاهيره | نبضة"
        page_desc = f"تعرفي على معنى اسم {name} بالتفصيل في معجم نبضة: أصله العربي، دلالاته، حكم التسمية به، شخصيات بارزة تحمله، والدول الأكثر تسمية به."
        canonical_url = f"https://nabda.online/tools/names/{slug}.html"
        esc_meaning_js = html.escape(meaning).replace("'", "\\'")

        page_content = f'''<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{html.escape(page_title)}</title>
  <meta name="description" content="{html.escape(page_desc)}">
  <link rel="canonical" href="{canonical_url}">
  <link rel="icon" type="image/png" href="../../favicon.png">
  <!-- Open Graph -->
  <meta property="og:title" content="معنى اسم {html.escape(name)} ودلالته وشيوعه | نبضة">
  <meta property="og:description" content="{html.escape(meaning[:140])}">
  <meta property="og:type" content="article">
  <meta property="og:url" content="{canonical_url}">
  <meta property="og:image" content="https://nabda.online/landing-assets/slide-baby.png">

  <!-- Fonts -->
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;500;600;700;800;900&family=Tajawal:wght@400;500;700;800&display=swap" rel="stylesheet">

  <!-- Schema.org BreadcrumbList -->
  <script type="application/ld+json">
  {{
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    "itemListElement": [
      {{
        "@type": "ListItem",
        "position": 1,
        "name": "الرئيسية",
        "item": "https://nabda.online/"
      }},
      {{
        "@type": "ListItem",
        "position": 2,
        "name": "معجم أسماء المواليد",
        "item": "https://nabda.online/tools/baby-names.html"
      }},
      {{
        "@type": "ListItem",
        "position": 3,
        "name": "معنى اسم {html.escape(name)}",
        "item": "{canonical_url}"
      }}
    ]
  }}
  </script>

  <!-- Schema.org DefinedTerm -->
  <script type="application/ld+json">
  {{
    "@context": "https://schema.org",
    "@type": "DefinedTerm",
    "name": "{html.escape(name)}",
    "description": "{html.escape(meaning)}",
    "inDefinedTermSet": {{
      "@type": "DefinedTermSet",
      "name": "معجم أسماء المواليد من نبضة",
      "url": "https://nabda.online/tools/baby-names.html"
    }}
  }}
  </script>

  <style>
    :root {{
      --primary: #E91E63;
      --primary-dark: #C2185B;
      --primary-soft: #FFF0F5;
      --girl-pink: #F06292;
      --girl-bg: #FCE4EC;
      --boy-blue: #1E88E5;
      --boy-bg: #E3F2FD;
      --islamic-gold: #D89E00;
      --islamic-bg: #FFF9E6;
      --teal: #00897B;
      --text-dark: #1F1A20;
      --text-muted: #6C6270;
      --bg: #FFF8FB;
      --border: #F3D3E2;
      --shadow: 0 8px 24px rgba(233, 30, 99, 0.07);
      --font: 'Cairo', 'Tajawal', sans-serif;
    }}

    * {{ box-sizing: border-box; margin: 0; padding: 0; font-family: var(--font); }}
    body {{ background: var(--bg); color: var(--text-dark); line-height: 1.7; direction: rtl; text-align: right; }}
    a {{ text-decoration: none; color: inherit; }}

    /* Header */
    .header {{
      background: rgba(255, 255, 255, 0.9);
      backdrop-filter: blur(12px);
      -webkit-backdrop-filter: blur(12px);
      border-bottom: 1px solid var(--border);
      position: sticky; top: 0; z-index: 100;
      padding: 12px 20px;
    }}
    .header-inner {{
      max-width: 1180px; margin: 0 auto;
      display: flex; align-items: center; justify-content: space-between; gap: 14px;
    }}
    .logo-box {{ display: flex; align-items: center; gap: 10px; }}
    .logo-badge {{
      width: 36px; height: 36px; border-radius: 50%;
      background: linear-gradient(135deg, #F43F7E, #FF8DA1);
      display: flex; align-items: center; justify-content: center;
      color: white; font-size: 18px; box-shadow: 0 4px 12px rgba(244,63,126,.3);
    }}
    .logo-text {{ font-size: 22px; font-weight: 900; color: var(--primary); }}
    .nav-links {{ display: flex; align-items: center; gap: 16px; font-size: 14px; font-weight: 700; }}
    .nav-link {{ color: var(--text-muted); transition: color .2s; }}
    .nav-link:hover {{ color: var(--primary); }}
    .app-btn {{
      background: linear-gradient(135deg, var(--primary), #FF4081);
      color: #fff; padding: 8px 18px; border-radius: 999px;
      font-weight: 700; font-size: 13px;
    }}

    .container {{ max-width: 900px; margin: 30px auto; padding: 0 20px; }}
    .breadcrumbs {{ font-size: 13.5px; color: var(--text-muted); margin-bottom: 20px; }}
    .breadcrumbs a {{ color: var(--teal); font-weight: 600; }}

    /* Main Name Card */
    .name-hero-card {{
      background: white; border: 1.5px solid #F5DBE7; border-radius: 26px;
      padding: 36px; box-shadow: var(--shadow); margin-bottom: 30px;
    }}
    .name-hero-top {{
      display: flex; justify-content: space-between; align-items: center;
      flex-wrap: wrap; gap: 16px; margin-bottom: 24px; padding-bottom: 20px;
      border-bottom: 1.5px solid #F8E9F1;
    }}
    .name-hero-title {{
      font-size: 38px; font-weight: 900; color: #1a1a1a; letter-spacing: -0.5px;
    }}
    .badges-box {{ display: flex; gap: 8px; flex-wrap: wrap; }}
    .badge {{
      font-size: 13px; font-weight: 800; padding: 5px 14px; border-radius: 50px;
    }}
    .badge.girl {{ background: var(--girl-bg); color: var(--girl-pink); }}
    .badge.boy {{ background: var(--boy-bg); color: var(--boy-blue); }}
    .badge.islamic {{ background: var(--islamic-bg); color: var(--islamic-gold); border: 1px solid #FFE082; }}
    .badge.popularity {{ background: #F3E5F5; color: #7B1FA2; }}

    .detail-block {{ margin-bottom: 26px; }}
    .detail-block h2 {{
      font-size: 20px; font-weight: 800; color: #1a1a1a; margin-bottom: 10px;
      display: flex; align-items: center; gap: 8px;
    }}
    .meaning-text {{
      font-size: 17px; line-height: 1.9; color: #3A323D;
      background: #FFF8FB; padding: 20px; border-radius: 16px; border: 1px solid #FCE4EC;
    }}

    .countries-box {{ display: flex; gap: 8px; flex-wrap: wrap; margin-top: 10px; }}
    .country-pill {{
      background: #F3EDF1; color: #444; padding: 5px 14px; border-radius: 50px;
      font-size: 13.5px; font-weight: 600;
    }}

    .famous-list {{ padding-right: 22px; color: #4A444C; font-size: 15.5px; line-height: 1.8; }}
    .famous-list li {{ margin-bottom: 8px; }}

    /* Action bar */
    .action-bar {{
      display: flex; gap: 12px; margin-top: 26px; padding-top: 20px;
      border-top: 1px solid #F8E9F1; flex-wrap: wrap;
    }}
    .btn-action {{
      background: var(--bg); border: 1.5px solid #ECD4E0;
      color: var(--text-dark); padding: 10px 22px; border-radius: 999px;
      font-size: 14px; font-weight: 700; cursor: pointer; transition: all .2s;
    }}
    .btn-action:hover {{
      background: var(--primary); color: white; border-color: var(--primary);
    }}
    .btn-back {{
      background: var(--teal); color: white; border: none;
      padding: 10px 22px; border-radius: 999px; font-size: 14px; font-weight: 700;
    }}
    .btn-back:hover {{ background: #00796B; }}

    /* Related Names Section */
    .related-section {{
      background: white; border: 1px solid var(--border); border-radius: 26px;
      padding: 32px; box-shadow: var(--shadow); margin-bottom: 30px;
    }}
    .related-section h2 {{ font-size: 21px; font-weight: 800; margin-bottom: 16px; }}
    .related-grid {{
      display: grid; grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
      gap: 14px; margin-top: 14px;
    }}
    .related-chip {{
      display: flex; flex-direction: column; background: #FFFBFD;
      border: 1px solid #F3DCE7; border-radius: 14px; padding: 12px 16px;
      transition: all .2s;
    }}
    .related-chip:hover {{
      border-color: var(--primary); transform: translateY(-2px);
      box-shadow: 0 6px 16px rgba(233,30,99,.1);
    }}
    .related-chip strong {{ font-size: 17px; color: #1a1a1a; margin-bottom: 4px; }}
    .related-chip span {{ font-size: 12px; color: var(--text-muted); line-height: 1.4; }}

    /* App CTA */
    .app-cta-box {{
      background: linear-gradient(135deg, #FFF0F5, #FFE4E1);
      border: 1.5px dashed var(--primary); border-radius: 26px;
      padding: 32px; text-align: center; margin-top: 40px;
    }}
    .app-cta-box h3 {{ font-size: 22px; font-weight: 900; color: var(--primary-dark); margin-bottom: 10px; }}
    .app-cta-box p {{ font-size: 15px; color: #555; max-width: 600px; margin: 0 auto 20px; }}

    /* Toast */
    .toast {{
      position: fixed; bottom: 30px; left: 50%; transform: translateX(-50%);
      background: rgba(30, 26, 32, 0.9); color: white;
      padding: 10px 24px; border-radius: 50px; font-size: 13.5px; font-weight: 700;
      display: none; z-index: 1000; box-shadow: 0 8px 24px rgba(0,0,0,0.2);
    }}

    /* Footer */
    .footer {{
      background: #fff; border-top: 1px solid var(--border);
      padding: 40px 20px; margin-top: 60px; text-align: center; font-size: 13.5px; color: var(--text-muted);
    }}
    .footer-links {{ display: flex; justify-content: center; gap: 18px; flex-wrap: wrap; margin-bottom: 16px; font-weight: 600; }}
    .footer-links a:hover {{ color: var(--primary); }}
  </style>
</head>
<body>

  <!-- Header -->
  <header class="header">
    <div class="header-inner">
      <a href="/" class="logo-box">
        <div class="logo-badge">♥</div>
        <span class="logo-text">نبضة</span>
      </a>
      <nav class="nav-links">
        <a href="/" class="nav-link">الرئيسية</a>
        <a href="/tools/due-date.html" class="nav-link">حاسبة الولادة</a>
        <a href="/tools/ovulation.html" class="nav-link">التبويض والخصوبة</a>
        <a href="/tools/baby-names.html" class="nav-link">أسماء المواليد</a>
        <a href="/tools/fetus-size.html" class="nav-link">حجم الجنين</a>
        <a href="/articles.html" class="nav-link">موسوعة نبضة</a>
        <a href="/shop" class="nav-link">المتجر</a>
      </nav>
      <a href="/" class="app-btn">تطبيق نبضة</a>
    </div>
  </header>

  <main class="container">
    <div class="breadcrumbs">
      <a href="/">الرئيسية</a> / <a href="/tools/baby-names.html">أسماء المواليد</a> / <span>معنى اسم {html.escape(name)}</span>
    </div>

    <!-- Main Detail Card -->
    <article class="name-hero-card">
      <div class="name-hero-top">
        <h1 class="name-hero-title">معنى اسم {html.escape(name)}</h1>
        <div class="badges-box">
          <span class="badge {g_cls}">{g_label}</span>
          {"""<span class="badge islamic">اسم قرآني وإسلامي ✨</span>""" if is_islamic else ""}
          <span class="badge popularity">شعبية الاسم: {pop}/100 ⭐</span>
        </div>
      </div>

      <div class="detail-block">
        <h2>📖 معنى الاسم في معجم اللغة العربية</h2>
        <div class="meaning-text">
          {html.escape(meaning)}
        </div>
      </div>

      <div class="detail-block">
        <h2>🌍 الدول الأكثر شيوعاً وتسمية بالاسم</h2>
        <div class="countries-box">
          {countries_html}
        </div>
      </div>

      {famous_html}

      <div class="action-bar">
        <button class="btn-action" onclick="copyDetails()">نسخ معنى الاسم 📋</button>
        <button class="btn-action" onclick="shareName()">مشاركة الاسم 🔗</button>
        <a href="/tools/baby-names.html" class="btn-back">← العودة إلى معجم الأسماء الكامل</a>
      </div>
    </article>

    <!-- Suggested Names (10 Internal Links for Deep SEO Crawl) -->
    <section class="related-section">
      <h2>💡 أسماء مقترحة ومشابهة لاسم {html.escape(name)}</h2>
      <p style="font-size: 14px; color: var(--text-muted); margin-bottom: 12px;">اكتشفي أيضاً هذه الأسماء الرائعة التي تبدأ بحرف مشابه أو تشترك في ذات الأصول والمعاني الطيبة:</p>
      <div class="related-grid">
        {related_html}
      </div>
    </section>

    <!-- App CTA -->
    <div class="app-cta-box">
      <h3>هل تنتظرين مولودكِ الجديد؟ 👶✨</h3>
      <p>يساعدكِ تطبيق نبضة على متابعة نمو طفلكِ أسبوعاً بأسبوع، وحساب مواعيد الركلات وحركة الجنين، واكتشاف أكثر من 80 ثنائياً متناسقاً لأسماء التوائم مع نصائح عملية مبسّطة.</p>
      <a href="/" class="app-btn" style="font-size: 15px; padding: 12px 28px;">حمّلي تطبيق نبضة مجاناً الآن</a>
    </div>
  </main>

  <div id="toast" class="toast">تم نسخ تفاصيل الاسم بنجاح! 📋</div>

  <!-- Footer -->
  <footer class="footer">
    <div class="footer-links">
      <a href="/">الرئيسية</a>
      <a href="/tools/due-date.html">حاسبة الولادة</a>
      <a href="/tools/ovulation.html">حاسبة التبويض</a>
      <a href="/tools/baby-names.html">أسماء المواليد</a>
      <a href="/tools/fetus-size.html">حجم الجنين</a>
      <a href="/articles.html">موسوعة نبضة</a>
      <a href="/shop">المتجر</a>
      <a href="/privacy.html">سياسة الخصوصية</a>
      <a href="/terms.html">شروط الاستخدام</a>
    </div>
    <p>© 2026 نبضة (Nabda). جميع الحقوق محفوظة. المحتوى لأغراض تثقيفية وإرشادية.</p>
  </footer>

  <script>
    function copyDetails() {{
      const text = "معنى اسم {html.escape(name)}: {esc_meaning_js}\\nعبر معجم أسماء نبضة: {canonical_url}";
      navigator.clipboard.writeText(text).then(() => {{
        const t = document.getElementById('toast');
        t.textContent = 'تم نسخ تفاصيل الاسم بنجاح! 📋';
        t.style.display = 'block';
        setTimeout(() => t.style.display = 'none', 2200);
      }});
    }}

    function shareName() {{
      if (navigator.share) {{
        navigator.share({{
          title: 'معنى اسم {html.escape(name)}',
          text: '{esc_meaning_js}',
          url: '{canonical_url}'
        }}).catch(() => {{}});
      }} else {{
        copyDetails();
      }}
    }}
  </script>
</body>
</html>
'''
        file_path = os.path.join(NAMES_DIR, f"{slug}.html")
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(page_content)

    print(f"Generated {len(names)} individual name pages in {NAMES_DIR}.")

# ══════════════════════════════════════════════════════════════
# 5. Generate Full Sitemap (sitemap.xml)
# ══════════════════════════════════════════════════════════════

def render_sitemap(names, slug_map):
    print("Generating comprehensive sitemap.xml...")
    urls = [
        ("https://nabda.online/", "daily", "1.0"),
        ("https://nabda.online/tools/due-date.html", "weekly", "0.95"),
        ("https://nabda.online/tools/ovulation.html", "weekly", "0.95"),
        ("https://nabda.online/tools/baby-names.html", "weekly", "0.95"),
        ("https://nabda.online/tools/fetus-size.html", "weekly", "0.95"),
        ("https://nabda.online/articles.html", "weekly", "0.9"),
        ("https://nabda.online/shop", "weekly", "0.8"),
        ("https://nabda.online/privacy.html", "monthly", "0.5"),
        ("https://nabda.online/terms.html", "monthly", "0.5"),
    ]

    for item in names:
        slug = slug_map[item["name"]]
        urls.append((f"https://nabda.online/tools/names/{slug}.html", "monthly", "0.8"))

    sitemap_lines = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
    ]
    for loc, freq, prio in urls:
        sitemap_lines.append(f'  <url>\n    <loc>{loc}</loc>\n    <changefreq>{freq}</changefreq>\n    <priority>{prio}</priority>\n  </url>')
    sitemap_lines.append('</urlset>\n')

    with open(SITEMAP_FILE, "w", encoding="utf-8") as f:
        f.write('\n'.join(sitemap_lines))
    print(f"Exported sitemap.xml with {len(urls)} URLs.")

# ══════════════════════════════════════════════════════════════
# 6. Automated Verification Checks (Fail Fast)
# ══════════════════════════════════════════════════════════════

CHECKS = [
    ('web/tools/due-date.html',   600),
    ('web/tools/ovulation.html',  600),
    ('web/tools/fetus-size.html', 2000),
    ('web/tools/baby-names.html', 3000),
]

def count_arabic_words(file_path):
    abs_path = os.path.join(BASE_DIR, file_path) if not os.path.isabs(file_path) else file_path
    with open(abs_path, 'r', encoding='utf-8') as f:
        html_text = f.read()

    # Strip script and style tags completely
    clean = re.sub(r'<(script|style)[^>]*>[\s\S]*?</\1>', ' ', html_text, flags=re.IGNORECASE)
    # Strip HTML tags
    clean = re.sub(r'<[^>]+>', ' ', clean)
    # Match Arabic words (2 or more Arabic characters)
    words = re.findall(r'[\u0600-\u06FF]{2,}', clean)
    return len(words)

def run_checks():
    print("\n" + "=" * 60)
    print("Running Automated Word Count Verification (Raw HTML SEO Check):")
    print("=" * 60)
    failed = False
    for rel_path, min_words in CHECKS:
        count = count_arabic_words(rel_path)
        status = "PASSED ✓" if count >= min_words else "FAILED ✗"
        print(f"  {rel_path:<28} : {count:>5} words (min: {min_words}) -> {status}")
        if count < min_words:
            failed = True

    print("=" * 60)
    if failed:
        print("ERROR: One or more pages failed the indexable word count check!")
        sys.exit(1)
    else:
        print("SUCCESS: All pages exceed the required indexable word counts!\n")

if __name__ == "__main__":
    export_fetus_weeks()
    export_baby_names()
    run_checks()
