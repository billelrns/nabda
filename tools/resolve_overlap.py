import sys
sys.path.insert(0, 'tools')
import data_females
import data_males
import re

def norm(s):
    s = re.sub(r'[\u064B-\u0652]', '', s)
    s = re.sub(r'[إأآا]', 'ا', s)
    s = re.sub(r'ة', 'ه', s)
    s = re.sub(r'ى', 'ي', s)
    return re.sub(r'\s+', ' ', s).strip()

# We keep:
# 'نور' in female (remove from male - male has 'نور الدين' and 'أنور')
# 'نجاح' in female (remove from male)
# 'صباح' in female (remove from male)
# 'ضياء' in male (remove from female)
# 'نضال' in male (remove from female)
# 'زين' in male (remove from female - female has 'زينة')
# 'وسام' in male (remove from female)
# 'تيسير' in male (remove from female)
# 'هتان' in male (remove from female)
# 'جهاد' in male (remove from female)

remove_from_females = {'ضياء', 'نضال', 'زين', 'وسام', 'تيسير', 'هتان', 'جهاد'}
remove_from_males = {'نور', 'نجاح', 'صباح'}

data_females.FEMALE_NAMES = [item for item in data_females.FEMALE_NAMES if item[0] not in remove_from_females]
data_males.MALE_NAMES = [item for item in data_males.MALE_NAMES if item[0] not in remove_from_males]

print(f"Females after resolution: {len(data_females.FEMALE_NAMES)}")
print(f"Males after resolution: {len(data_males.MALE_NAMES)}")

with open('tools/data_females.py', 'w', encoding='utf-8') as f:
    f.write('# -*- coding: utf-8 -*-\n')
    f.write('"""Unique vetted female names."""\n\n')
    f.write('FEMALE_NAMES = [\n')
    for item in data_females.FEMALE_NAMES:
        name, meaning, countries, is_islamic, famous = item
        f.write(f'    ({repr(name)}, {repr(meaning)}, {repr(countries)}, {repr(is_islamic)}, {repr(famous)}),\n')
    f.write(']\n')

with open('tools/data_males.py', 'w', encoding='utf-8') as f:
    f.write('# -*- coding: utf-8 -*-\n')
    f.write('"""Unique vetted authentic Arabic male names."""\n\n')
    f.write('MALE_NAMES = [\n')
    for item in data_males.MALE_NAMES:
        name, meaning, countries, is_islamic, famous = item
        f.write(f'    ({repr(name)}, {repr(meaning)}, {repr(countries)}, {repr(is_islamic)}, {repr(famous)}),\n')
    f.write(']\n')

print("Saved cleanly.")
