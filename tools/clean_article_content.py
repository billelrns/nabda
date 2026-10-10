# -*- coding: utf-8 -*-
"""
تنظيف متون مقالات الموسوعة
===========================
يعالج ثلاثة أعطال في assets/data/smart_2500_articles.json:

  1. بقايا JSON-LD من الموقع المصدر ملتصقة بنهاية المتن (1,475 مقالًا)
     النمط ثابت: نصّ عربي سليم ← "  ← },  {  ← "@type": "BreadcrumbList…
     العلاج: قصّ المتن عند أول علامة من علامات الـJSON.

  2. كيانات HTML مكسورة فقدت علامة & (178 مقالًا)
     hellip; → …   laquo;/«; → «   raquo;/»; → »   nbsp; → مسافة

  3. نصّ مشوّه بترميز مزدوج UTF-8→Latin-1 (7 مقالات)
     العلاج: s.encode('latin-1').decode('utf-8') مع تحقّق أن الناتج عربي فعلاً؛
     وإن فشل التحقّق يُترك كما هو ويُبلَّغ عنه للمعالجة اليدوية.

ما لا يعالجه عمدًا: **العريض** — يُترك للواجهة لتعرضه منسَّقًا لا لتحذفه.

التشغيل من جذر المشروع:
    python tools\\clean_article_content.py --check    # إحصاء بلا كتابة
    python tools\\clean_article_content.py            # تنفيذ + نسخة احتياطية
"""
import json, os, re, shutil, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, 'assets', 'data', 'smart_2500_articles.json')
BACKUP = DATA + '.before-clean.bak'

# --- 1. علامات بداية فضلات JSON-LD ------------------------------------------
JSONLD_MARKS = [
    re.compile(r'"\s*\r?\n\s*\},'),          # النمط الغالب: " ثم سطر جديد ثم },
    re.compile(r'"@type"'),
    re.compile(r'"@context"'),
    re.compile(r'BreadcrumbList'),
    re.compile(r'itemListElement'),
    re.compile(r'\r?\n\s*\}\s*,?\s*\r?\n\s*\{'),
]

# --- 2. كيانات مكسورة --------------------------------------------------------
ENTS = [
    (re.compile(r'&?hellip;'), '…'),
    (re.compile(r'&?laquo;|«;'), '«'),
    (re.compile(r'&?raquo;|»;'), '»'),
    (re.compile(r'&?nbsp;'), ' '),
    (re.compile(r'&?amp;'), '&'),
    (re.compile(r'&?quot;'), '"'),
    (re.compile(r'&?ldquo;|&?rdquo;'), '"'),
    (re.compile(r'&?rsquo;|&?lsquo;'), '’'),
    (re.compile(r'&#(\d+);'), lambda m: chr(int(m.group(1)))),
]

MOJIBAKE = re.compile(r'[ÙØÛ][-ÿ]')
ARABIC = re.compile(r'[؀-ۿ]')


def strip_jsonld(t):
    """يقصّ المتن عند أبكر علامة JSON، ثم ينظّف الذيل."""
    idx = None
    for p in JSONLD_MARKS:
        m = p.search(t)
        if m and (idx is None or m.start() < idx):
            idx = m.start()
    if idx is None:
        return t, False
    out = t[:idx].rstrip()
    # الذيل غالبًا علامة اقتباس يتيمة تركها المستخرِج
    while out and out[-1] in '"”“ \n\r\t':
        out = out[:-1].rstrip()
    return out, True


def fix_entities(t):
    before = t
    for p, r in ENTS:
        t = p.sub(r, t)
    return t, (t != before)


def fix_mojibake(t):
    """يعيد ترميز النصّ المزدوج.

    التلف هنا مركّب: النصّ رُمّز UTF-8 ثم قُرئ كـcp1252، وفي الطريق تحوّل
    البايت 0x85 (وهو النصف الثاني من حرف الميم) إلى مسافة. لذلك نعيده قبل
    فكّ الترميز. ⚠️ المسافة الأصلية التي كانت بعد الميم ضائعة نهائيًا في
    المصدر، فتظهر «يومعرفة» بدل «يوم عرفة» — النصّ مقروء لا سليم.
    """
    if not MOJIBAKE.search(t):
        return t, False
    s = t
    for lead in ('Ù', 'Ø'):
        s = s.replace(lead + ' ', lead + '')
    b = bytearray()
    for ch in s:
        try:
            b += ch.encode('cp1252')
        except Exception:
            try:
                b += ch.encode('latin-1')
            except Exception:
                return t, False
    try:
        fixed = b.decode('utf-8', errors='strict')
    except UnicodeDecodeError:
        return t, False
    if len(ARABIC.findall(fixed)) > len(ARABIC.findall(t)):
        return fixed, True
    return t, False


def clean_text(t):
    flags = set()
    t, f = strip_jsonld(t)
    if f: flags.add('jsonld')
    t, f = fix_entities(t)
    if f: flags.add('entities')
    t, f = fix_mojibake(t)
    if f: flags.add('mojibake')
    # مسافات غير فاصلة ومسافات زائدة داخل فواصل الفقرات
    t = t.replace('\xa0', ' ')
    t = re.sub(r'[ \t]+\n', '\n', t)
    t = re.sub(r'\n[ \t]+', '\n', t)
    t = re.sub(r'\n{3,}', '\n\n', t)
    return t.strip(), flags


def main():
    check = '--check' in sys.argv
    d = json.load(open(DATA, encoding='utf-8'))
    arts = d['articles']

    stats = {'jsonld': 0, 'entities': 0, 'mojibake': 0, 'touched': 0}
    unfixed_mojibake = []

    for x in arts:
        touched = set()
        for key in ('title', 'summary', 'description'):
            if isinstance(x.get(key), str):
                nv, f = clean_text(x[key])
                x[key] = nv
                touched |= f
        for s in x.get('sections', []):
            for key in ('title', 'content', 'calloutTip', 'calloutWarning'):
                if isinstance(s.get(key), str):
                    nv, f = clean_text(s[key])
                    s[key] = nv
                    touched |= f
            if isinstance(s.get('bulletPoints'), list):
                s['bulletPoints'] = [clean_text(b)[0] if isinstance(b, str) else b
                                     for b in s['bulletPoints']]
        for q in x.get('faqs', []):
            for key in ('question', 'answer'):
                if isinstance(q.get(key), str):
                    nv, f = clean_text(q[key])
                    q[key] = nv
                    touched |= f
        for k in touched:
            stats[k] += 1
        if touched:
            stats['touched'] += 1
        blob = x.get('title', '') + ' '.join(s.get('content', '') for s in x.get('sections', []))
        if MOJIBAKE.search(blob):
            unfixed_mojibake.append(x['id'])

    print('المقالات        : %d' % len(arts))
    print('نُظّف منها       : %d' % stats['touched'])
    print('  بقايا JSON    : %d' % stats['jsonld'])
    print('  كيانات HTML   : %d' % stats['entities'])
    print('  ترميز مزدوج   : %d' % stats['mojibake'])
    if unfixed_mojibake:
        print('\n[!] تعذّر إصلاح الترميز في %d مقالًا — تحتاج قرارًا يدويًا (حذف أو إعادة جلب):'
              % len(unfixed_mojibake))
        for i in unfixed_mojibake[:20]:
            print('    ' + i)

    if check:
        print('\n(فحص فقط — لم يُكتب شيء)')
        return 0

    if not os.path.exists(BACKUP):
        shutil.copy2(DATA, BACKUP)
        print('\nنسخة احتياطية -> %s' % os.path.basename(BACKUP))

    tmp = DATA + '.tmp'
    with open(tmp, 'w', encoding='utf-8') as f:
        json.dump(d, f, ensure_ascii=False)
    os.replace(tmp, DATA)
    print('كُتب %s' % os.path.basename(DATA))
    return 0


if __name__ == '__main__':
    sys.exit(main())
