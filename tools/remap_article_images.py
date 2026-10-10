# -*- coding: utf-8 -*-
"""
إعادة ربط صور مقالات الموسوعة
==============================
المشكلة التي يعالجها:
  smart_2500_articles.json كان يشير إلى 72 ملف خلفية، منها 30 فقط موجود على
  القرص — و30 الموجودة كانت بطاقات تدرّج فارغة مكتوبًا عليها «HEALTH · 04 /
  NABDA HEALTH ENCYCLOPEDIA» بالإنجليزية. فـ2,612 مقالًا كانت بلا صورة أصلًا،
  والباقي بصورة فارغة.

الحل:
  15 صورة واقعية (مولَّدة بـHiggsfield) موزّعة على التصنيفات الستّة حسب حجم
  كل تصنيف، ثم إعادة توزيع كل المقالات عليها بالتناوب داخل تصنيفها.
  النتيجة: كل مقال من 6,982 له صورة حقيقية موجودة فعلًا.

التشغيل من جذر المشروع:
    python tools\\remap_article_images.py            # تنفيذ
    python tools\\remap_article_images.py --check    # فحص فقط بلا كتابة

يُنشئ نسخة احتياطية من الربط القديم في tools/_article_images_backup.json
(خريطة id -> imagePath فقط، لا الملف كامل، فحجمها صغير).
"""
import json, os, sys, collections

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, 'assets', 'data', 'smart_2500_articles.json')
BGDIR = os.path.join(ROOT, 'assets', 'images', 'articles_bg')
BACKUP = os.path.join(ROOT, 'tools', '_article_images_backup.json')
REL = 'assets/images/articles_bg'

# الصور الحقيقية المتاحة لكل تصنيف — وُزِّع العدد حسب عدد المقالات
REAL = {
    'health':    ['bg_health_01', 'bg_health_02', 'bg_health_03',
                  'bg_health_04', 'bg_health_05'],
    'pregnancy': ['bg_pregnancy_01', 'bg_pregnancy_02', 'bg_pregnancy_03'],
    'beauty':    ['bg_beauty_01', 'bg_beauty_02'],
    'marriage':  ['bg_marriage_01', 'bg_marriage_02'],
    'baby':      ['bg_baby_01', 'bg_baby_02'],
    'fertility': ['bg_fertility_01'],
}


def cat_of(path):
    """يستخرج التصنيف من اسم الملف القديم: bg_health_07.jpg -> health"""
    name = path.rsplit('/', 1)[-1]
    if not name.startswith('bg_'):
        return None
    return name[3:].rsplit('_', 1)[0]


def main():
    check = '--check' in sys.argv

    for c, names in REAL.items():
        for n in names:
            p = os.path.join(BGDIR, n + '.jpg')
            if not os.path.exists(p):
                print('[!] صورة مفقودة: %s.jpg' % n)
                return 1

    d = json.load(open(DATA, encoding='utf-8'))
    arts = d['articles']
    print('المقالات: %d' % len(arts))

    if not check and not os.path.exists(BACKUP):
        json.dump({a['id']: a.get('imagePath') for a in arts},
                  open(BACKUP, 'w', encoding='utf-8'), ensure_ascii=False)
        print('نسخة احتياطية للربط القديم -> tools/_article_images_backup.json')

    counters = collections.Counter()
    unknown = 0
    for a in arts:
        c = cat_of(a.get('imagePath', ''))
        if c not in REAL:
            unknown += 1
            c = 'health'
        pool = REAL[c]
        a['imagePath'] = '%s/%s.jpg' % (REL, pool[counters[c] % len(pool)])
        counters[c] += 1

    if unknown:
        print('[!] %d مقالًا بتصنيف غير معروف — أُسنِدت إلى health' % unknown)

    used = collections.Counter(a['imagePath'].rsplit('/', 1)[1] for a in arts)
    print('\nالتوزيع النهائي (%d صورة):' % len(used))
    for k, v in sorted(used.items()):
        print('  %-22s %5d مقالًا' % (k, v))

    missing = [k for k in used if not os.path.exists(os.path.join(BGDIR, k))]
    print('\nملفات مشار إليها وغير موجودة: %d' % len(missing))
    if missing:
        print('  ' + ', '.join(missing))
        return 1

    if check:
        print('\n(فحص فقط — لم يُكتب شيء)')
        return 0

    tmp = DATA + '.tmp'
    with open(tmp, 'w', encoding='utf-8') as f:
        json.dump(d, f, ensure_ascii=False)
    os.replace(tmp, DATA)
    print('\nكُتب %s' % DATA)

    # حذف بطاقات التدرّج القديمة التي لم يعد يشير إليها أحد
    keep = set(used)
    removed = 0
    for f in sorted(os.listdir(BGDIR)):
        if f.startswith('bg_') and f.endswith('.jpg') and f not in keep:
            os.remove(os.path.join(BGDIR, f))
            removed += 1
    print('حُذفت %d بطاقة تدرّج قديمة لم تعد مستعملة' % removed)
    return 0


if __name__ == '__main__':
    sys.exit(main())
