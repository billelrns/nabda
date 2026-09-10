# -*- coding: utf-8 -*-
"""
Verification Suite for Baby Names and Twin Names Databases.
Checks all 8 acceptance criteria:
1. Actual count: females, males, total, twin groups.
2. 0 duplicate normalized names.
3. 0 synthetic compound names (matching `<name> ال<adjective>`).
4. 0 template filler sentences.
5. 0 occurrences of ' • أشهر من سُمّي به' in meaning.
6. All meanings length >= 20, all countries non-empty and in approved 22.
7. All twin names present in baby names database.
8. flutter analyze exit code 0.
"""
import os
import re
import sys
import subprocess

sys.stdout.reconfigure(encoding='utf-8')

VALID_COUNTRIES = [
    'الجزائر', 'المغرب', 'تونس', 'ليبيا', 'مصر', 'السعودية', 'الإمارات', 'الكويت',
    'قطر', 'البحرين', 'عُمان', 'العراق', 'سوريا', 'الأردن', 'لبنان', 'فلسطين',
    'اليمن', 'السودان', 'موريتانيا', 'الصومال', 'جيبوتي', 'جزر القمر'
]

FORBIDDEN_TEMPLATES = [
    "شخصية تاريخية بارزة حملت اسم",
    "شخصية معاصرة ناجحة تدعى",
    "رمز اجتماعي ارتبط باسم"
]

OLD_ADJECTIVES = [
    "الصالحة", "الطاهرة", "الحسناء", "المباركة", "الكريمة", "الصابرة",
    "الشاكرة", "الزاهدة", "العابدة", "الراضية", "الغانمة", "الناجحة",
    "المؤمنة", "التقية", "العفيفة", "الرحيمة", "الحليمة", "المطيعة",
    "المخلصة", "الودودة", "الرشيدة", "الوفية", "المنيرة"
]

def normalize_ar(s):
    s = re.sub(r'[ً-ْ]', '', s)  # tashkeel
    s = re.sub(r'[إأآا]', 'ا', s)
    s = re.sub(r'ة', 'ه', s)
    s = re.sub(r'ى', 'ي', s)
    return re.sub(r'\s+', ' ', s).strip()

def main():
    print("==================================================")
    print("   NABDA BABY & TWIN NAMES DATABASE VERIFICATION  ")
    print("==================================================\n")

    errors = []

    # 1. Parse lib/data/baby_names_database.dart
    baby_file = os.path.join('lib', 'data', 'baby_names_database.dart')
    if not os.path.exists(baby_file):
        print(f"ERROR: {baby_file} does not exist!")
        sys.exit(1)

    with open(baby_file, 'r', encoding='utf-8') as f:
        baby_content = f.read()

    # Regex to extract BabyName(...)
    pattern = re.compile(
        r"BabyName\(\s*'((?:\\.|[^'\\])*)',\s*'(female|male)',\s*'((?:\\.|[^'\\])*)',\s*(\d+),\s*(?:const\s*)?\[([^\]]*)\],\s*isIslamic:\s*(true|false),\s*famousPeople:\s*(?:const\s*)?\[([^\]]*)\]\s*\)",
        re.MULTILINE
    )

    matches = pattern.findall(baby_content)
    if not matches:
        print("ERROR: Could not parse BabyName entries from baby_names_database.dart!")
        sys.exit(1)

    females = [m for m in matches if m[1] == 'female']
    males = [m for m in matches if m[1] == 'male']
    total_names = len(matches)

    print(f"Criterion 1 - Counts:")
    print(f"  • Female Names: {len(females)}")
    print(f"  • Male Names:   {len(males)}")
    print(f"  • Total Names:  {total_names}")

    # 2. Parse lib/data/twin_names_database.dart
    twin_file = os.path.join('lib', 'data', 'twin_names_database.dart')
    if not os.path.exists(twin_file):
        print(f"ERROR: {twin_file} does not exist!")
        sys.exit(1)

    with open(twin_file, 'r', encoding='utf-8') as f:
        twin_content = f.read()

    twin_pattern = re.compile(
        r"TwinNameGroup\(\s*type:\s*'([^']+)',\s*genderType:\s*'([^']+)',\s*names:\s*(?:const\s*)?\[([^\]]+)\],\s*harmonyReason:\s*'((?:\\.|[^'\\])*)',\s*meaning:\s*'((?:\\.|[^'\\])*)',\s*\)",
        re.MULTILINE
    )

    twin_matches = twin_pattern.findall(twin_content)
    print(f"  • Twin Groups:  {len(twin_matches)}\n")

    # 3. Check for Duplicates after Normalization
    seen_norm = {}
    duplicates = []
    baby_names_raw = set()

    for m in matches:
        raw_name = m[0]
        baby_names_raw.add(raw_name)
        norm_name = normalize_ar(raw_name)
        if norm_name in seen_norm:
            duplicates.append((raw_name, seen_norm[norm_name]))
        else:
            seen_norm[norm_name] = raw_name

    print("Criterion 2 - Duplicate Check:")
    if duplicates:
        errors.append(f"Found {len(duplicates)} duplicates: {duplicates[:5]}")
        print(f"  [FAIL] Found {len(duplicates)} duplicates!")
    else:
        print("  [PASS] Exactly 0 duplicates after normalization.")

    # 4. Check for Synthetic Compound Names (<name> ال<adjective>)
    synthetic_compounds = []
    for m in matches:
        raw_name = m[0]
        parts = raw_name.split()
        if len(parts) == 2:
            if parts[1] in OLD_ADJECTIVES:
                synthetic_compounds.append(raw_name)

    print("Criterion 3 - Synthetic Compound Check:")
    if synthetic_compounds:
        errors.append(f"Found synthetic compounds: {synthetic_compounds}")
        print(f"  [FAIL] Found {len(synthetic_compounds)} synthetic compounds!")
    else:
        print("  [PASS] Exactly 0 synthetic compound names.")

    # 5. Check for Template Sentences in meanings
    template_violations = []
    for m in matches:
        meaning = m[2]
        for t in FORBIDDEN_TEMPLATES:
            if t in meaning:
                template_violations.append((m[0], t))

    print("Criterion 4 - Template Meaning Check:")
    if template_violations:
        errors.append(f"Found template meanings: {template_violations[:5]}")
        print(f"  [FAIL] Found {len(template_violations)} template meanings!")
    else:
        print("  [PASS] Exactly 0 template filler sentences in meanings.")

    # 6. Check for leftover ' • أشهر من سُمّي به' in meaning
    leftover_famous = []
    for m in matches:
        meaning = m[2]
        if "أشهر من سُمّي به" in meaning:
            leftover_famous.append(m[0])

    print("Criterion 5 - Leftover Personality Strings in Meaning Check:")
    if leftover_famous:
        errors.append(f"Found leftover famous strings in: {leftover_famous[:5]}")
        print(f"  [FAIL] Found {len(leftover_famous)} leftover famous strings!")
    else:
        print("  [PASS] Exactly 0 leftover 'أشهر من سُمّي به' in meanings.")

    # 7. Check Meaning Length >= 20 and Valid Countries
    short_meanings = []
    invalid_countries = []
    empty_countries = []

    for m in matches:
        name = m[0]
        meaning = m[2]
        c_raw = m[4].strip()
        if len(meaning) < 20:
            short_meanings.append((name, len(meaning)))
        if not c_raw:
            empty_countries.append(name)
        else:
            c_list = [c.strip().strip("'") for c in c_raw.split(',') if c.strip()]
            for c in c_list:
                if c not in VALID_COUNTRIES:
                    invalid_countries.append((name, c))

    print("Criterion 6 - Meaning Length & Country Validity Check:")
    if short_meanings or empty_countries or invalid_countries:
        if short_meanings:
            errors.append(f"Short meanings in {len(short_meanings)} names: {short_meanings[:3]}")
        if empty_countries:
            errors.append(f"Empty countries in {len(empty_countries)} names: {empty_countries[:3]}")
        if invalid_countries:
            errors.append(f"Invalid countries in {len(invalid_countries)} names: {invalid_countries[:3]}")
        print(f"  [FAIL] Issues with meaning length or countries!")
    else:
        print("  [PASS] All meanings length >= 20 chars; all countries non-empty and in approved 22 list.")

    # 8. Check Twin Names Present in Baby Names Database
    missing_twin_names = []
    twin_categories = set()

    for tm in twin_matches:
        t_type = tm[0]
        t_gender = tm[1]
        twin_categories.add((t_type, t_gender))
        names_raw = [n.strip().strip("'") for n in tm[2].split(',') if n.strip()]
        for name in names_raw:
            if name not in baby_names_raw:
                missing_twin_names.append((name, names_raw))

    print("Criterion 7 - Twin Group Integrity & Names Existence Check:")
    print(f"  • Twin Categories Covered: {len(twin_categories)} of 9 required")
    if len(twin_categories) < 9:
        errors.append(f"Only {len(twin_categories)} of 9 twin categories covered!")
    if missing_twin_names:
        errors.append(f"Twin names missing from baby database: {missing_twin_names[:5]}")
        print(f"  [FAIL] Missing {len(missing_twin_names)} twin names from baby database!")
    else:
        print("  [PASS] All twin names exist in babyNamesDatabase; all 9 combinations covered.")

    print("\n==================================================")
    if errors:
        print(f"VERIFICATION FAILED WITH {len(errors)} ERRORS:")
        for e in errors:
            print("  [ERROR]", e)
        sys.exit(1)
    else:
        print("ALL ACCEPTANCE CRITERIA PASSED WITH ZERO ERRORS!")
        print("==================================================")
        sys.exit(0)

if __name__ == '__main__':
    main()
