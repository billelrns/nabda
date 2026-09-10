import sys
sys.path.insert(0, 'tools')
import data_females
import data_males

PAN = ['الجزائر', 'المغرب', 'تونس', 'مصر', 'السعودية', 'الإمارات', 'العراق', 'سوريا', 'الأردن', 'فلسطين', 'لبنان', 'اليمن', 'السودان']

# Add females: ريمان, ريناد, إستبرق
new_females = [
    ("ريمان", "الموضع العالي الشامخ، والظبية البيضاء اللطيفة، رمز الرفعة والنقاء والجمال الطبيعي", PAN, False, []),
    ("ريناد", "الرائحة الزكية الفواحة لشجر العود والبخور وتراب الجنة ونبات الرند العطر في البادية", PAN, True, []),
    ("إستبرق", "الحرير الغليظ المنسوج بخيوط الذهب الفاخرة، ذُكر في القرآن الكريم كلباس كريم لأهل الجنة", PAN, True, []),
]

for f in new_females:
    data_females.FEMALE_NAMES.append(f)

# Add male: أبو بكر
new_male = ("أبو بكر", "كنية الصديق الأكبر رضي الله عنه، والبكر الفتي المتقدم في كل خير وسبق إسلامي وفضيلة", PAN, True,
            ["أبو بكر الصديق (أول الخلفاء الراشدين وخير الأمة بعد الأنبياء وثاني اثنين في الغار)"])

data_males.MALE_NAMES.append(new_male)

# Save data_females.py
with open('tools/data_females.py', 'w', encoding='utf-8') as f:
    f.write('# -*- coding: utf-8 -*-\n')
    f.write('"""Unique vetted female names."""\n\n')
    f.write('FEMALE_NAMES = [\n')
    for item in data_females.FEMALE_NAMES:
        name, meaning, countries, is_islamic, famous = item
        f.write(f'    ({repr(name)}, {repr(meaning)}, {repr(countries)}, {repr(is_islamic)}, {repr(famous)}),\n')
    f.write(']\n')

# Save data_males.py
with open('tools/data_males.py', 'w', encoding='utf-8') as f:
    f.write('# -*- coding: utf-8 -*-\n')
    f.write('"""Unique vetted authentic Arabic male names."""\n\n')
    f.write('MALE_NAMES = [\n')
    for item in data_males.MALE_NAMES:
        name, meaning, countries, is_islamic, famous = item
        f.write(f'    ({repr(name)}, {repr(meaning)}, {repr(countries)}, {repr(is_islamic)}, {repr(famous)}),\n')
    f.write(']\n')

print("Added missing names and updated data_females and data_males.")
