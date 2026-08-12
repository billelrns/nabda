# -*- coding: utf-8 -*-
"""ضغط صور المقالات الجديدة إلى حجم مناسب للتطبيق.
   - أقصى عرض/ارتفاع 900px
   - JPEG q82 داخل امتداد .png (فلاتر يقرأ المحتوى لا الامتداد)
   - يتخطى الملفات المضغوطة مسبقاً (< 200KB)
"""
import os, glob
from PIL import Image

DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                   'assets', 'images', 'article_pics')
MAX = 900
Q = 82
SKIP_UNDER = 200 * 1024

targets = []
for pat in ('d*.png', 'f*.png', 'a031.png', 'n*.png'):
    targets += glob.glob(os.path.join(DIR, pat))
targets = sorted(set(targets))

before = after = 0
done = skipped = 0

for path in targets:
    size = os.path.getsize(path)
    before += size
    if size < SKIP_UNDER:
        after += size
        skipped += 1
        continue
    try:
        im = Image.open(path)
        im = im.convert('RGB')
        w, h = im.size
        if max(w, h) > MAX:
            r = MAX / float(max(w, h))
            im = im.resize((int(w * r), int(h * r)), Image.LANCZOS)
        im.save(path, format='JPEG', quality=Q, optimize=True, progressive=True)
        after += os.path.getsize(path)
        done += 1
        print(u'  ✓ %-12s %6.1fKB → %6.1fKB' % (
            os.path.basename(path), size / 1024.0,
            os.path.getsize(path) / 1024.0))
    except Exception as e:
        after += size
        print(u'  ✗ %s : %s' % (os.path.basename(path), e))

print()
print(u'ملفات مضغوطة: %d | متخطاة: %d' % (done, skipped))
print(u'الحجم: %.1f MB → %.1f MB' % (before / 1048576.0, after / 1048576.0))
