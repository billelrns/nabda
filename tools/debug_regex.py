import re

with open('lib/data/baby_names_database.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

baby_lines = [l.strip() for l in lines if l.strip().startswith('BabyName(')]
print("Total BabyName lines in file:", len(baby_lines))

pattern = re.compile(
    r"BabyName\(\s*'((?:\\.|[^'\\])*)',\s*'(female|male)',\s*'((?:\\.|[^'\\])*)',\s*(\d+),\s*const\s*\[([^\]]*)\],\s*isIslamic:\s*(true|false),\s*famousPeople:\s*const\s*\[([^\]]*)\]\s*\)"
)


unmatched = []
for l in baby_lines:
    if not pattern.match(l):
        unmatched.append(l)

print(f"Unmatched lines: {len(unmatched)}")
if unmatched:
    for u in unmatched[:5]:
        print("  -", u[:140])
