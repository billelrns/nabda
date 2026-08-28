# -*- coding: utf-8 -*-
"""ضغط صور نبضة الجديدة إلى حجم مناسب للتطبيق."""
import os, glob
from PIL import Image

ROOT = os.path.dirname(os.path.abspath(__file__))
MAX = 900
Q = 82
SKIP_UNDER = 200 * 1024

PATTERNS = [
    'assets/images/article_pics/d*.png',
    'assets/images/article_pics/f*.png',
    'assets/images/article_pics/b0*.png',
    'assets/images/article_pics/n*.png',
    'assets/images/article_pics/a031.png',
    'assets/images/share_cards/*.png',
    'assets/images/intro/*.png',
    'assets/images/hero_home.png',
]

targets = []
for pat in PATTERNS:
    targets += glob.glob(os.path.join(ROOT, pat))
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
        im = Image.open(path).convert('RGB')
        w, h = im.size
        if max(w, h) > MAX:
            r = MAX / float(max(w, h))
            im = im.resize((int(w * r), int(h * r)), Image.LANCZOS)
        im.save(path, format='JPEG', quality=Q, optimize=True, progressive=True)
        after += os.path.getsize(path)
        done += 1
        print('  OK  %-22s %7.1fKB -> %7.1fKB' % (
            os.path.basename(path), size / 1024.0, os.path.getsize(path) / 1024.0))
    except Exception as e:
        after += size
        print('  ERR %s : %s' % (os.path.basename(path), e))

print()
print('compressed: %d | skipped: %d' % (done, skipped))
print('total: %.1f MB -> %.1f MB' % (before / 1048576.0, after / 1048576.0))
