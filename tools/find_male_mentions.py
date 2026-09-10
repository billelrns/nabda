import glob
import re

for f in glob.glob('tools/*.py'):
    with open(f, 'r', encoding='utf-8') as fp:
        c = fp.read()
    if 'male' in c.lower() or 'محمد' in c:
        print(f"Found mentions in {f} (size: {len(c)})")
