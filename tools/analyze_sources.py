import sys
import re

def analyze_file(filepath):
    print(f"=== Analyzing {filepath} ===")
    with open(filepath, 'r', encoding='utf-8') as f:
        text = f.read()
    
    # Check tuples like ("name", "meaning", countries, is_islamic, famous)
    matches = re.findall(r'\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*,', text)
    print(f"Tuple matches: {len(matches)}")
    if matches:
        print("First 5:", [m[0] for m in matches[:5]])
        print("Last 5:", [m[0] for m in matches[-5:]])

import female_names_data
print("FEMALE_NAMES count:", len(female_names_data.FEMALE_NAMES))

