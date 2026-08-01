import sys

sys.stdout.reconfigure(encoding='utf-8')

with open("lib/main.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

for i, line in enumerate(lines[:3500]):
    l_lower = line.lower()
    if "soon" in l_lower or "الأطباء" in line or "doctors" in l_lower or "navitem" in l_lower or "sidebar" in l_lower:
        print(f"Line {i+1}: {line.strip()}")
