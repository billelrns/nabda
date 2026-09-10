import sys
sys.path.insert(0, 'tools')
import data_females

VALID_COUNTRIES = [
    'الجزائر', 'المغرب', 'تونس', 'ليبيا', 'مصر', 'السعودية', 'الإمارات', 'الكويت',
    'قطر', 'البحرين', 'عُمان', 'العراق', 'سوريا', 'الأردن', 'لبنان', 'فلسطين',
    'اليمن', 'السودان', 'موريتانيا', 'الصومال', 'جيبوتي', 'جزر القمر'
]

errors = []
for i, item in enumerate(data_females.FEMALE_NAMES):
    name, meaning, countries, is_islamic, famous = item
    if len(meaning) < 20:
        errors.append(f"Short meaning for {name}: {len(meaning)} chars")
    if not countries:
        errors.append(f"Empty countries for {name}")
    for c in countries:
        if c not in VALID_COUNTRIES:
            errors.append(f"Invalid country '{c}' for {name}")

print(f"Total female names checked: {len(data_females.FEMALE_NAMES)}")
print(f"Errors found: {len(errors)}")
if errors:
    for e in errors[:10]:
        print("  -", e)
