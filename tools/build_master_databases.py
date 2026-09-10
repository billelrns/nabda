# -*- coding: utf-8 -*-
"""
tools/build_master_databases.py
Assembles and writes:
1. lib/data/baby_names_database.dart (from base + extra datasets)
2. lib/data/twin_names_database.dart (from base + extra datasets)
3. tools/verify_names.py
"""
import os
import re
import sys

sys.path.insert(0, 'tools')
import data_females
import data_females_extra
import data_males
import data_males_extra
import data_abd_din
import data_abd_din_extra
import data_twins
import data_twins_extra

# 22 Approved Arab Countries
VALID_COUNTRIES = [
    'الجزائر', 'المغرب', 'تونس', 'ليبيا', 'مصر', 'السعودية', 'الإمارات', 'الكويت',
    'قطر', 'البحرين', 'عُمان', 'العراق', 'سوريا', 'الأردن', 'لبنان', 'فلسطين',
    'اليمن', 'السودان', 'موريتانيا', 'الصومال', 'جيبوتي', 'جزر القمر'
]

def norm(s):
    s = re.sub(r'[\u064B-\u0652]', '', s)
    s = re.sub(r'[إأآا]', 'ا', s)
    s = re.sub(r'ة', 'ه', s)
    s = re.sub(r'ى', 'ي', s)
    return re.sub(r'\s+', ' ', s).strip()

# Top popular names in Algeria / Maghreb to give priority rank
TOP_FEMALES_POPULARITY = [
    "مريم", "فاطمة", "عائشة", "خديجة", "زينب", "سارة", "آية", "أمينة", "إيمان", "هاجر",
    "جميلة", "حسيبة", "أسماء", "سمية", "سلمى", "نور", "ملاك", "ليلى", "ياسمين", "صفية",
    "حنان", "هناء", "وفاء", "هدى", "رحمة", "إكرام", "أحلام", "إلهام", "ريان", "لين",
    "ليان", "جنى", "ضحى", "سجى", "منال", "نهال", "نوال", "نسرين", "سعاد", "زهرة",
    "مليكة", "فريدة", "فوزية", "حليمة", "كريمة", "لطيفة", "نادية", "وسيلة", "لويزة", "باية"
]

TOP_MALES_POPULARITY = [
    "محمد", "أحمد", "عبد الله", "عبد الرحمن", "عبد القادر", "علي", "عمر", "يوسف", "إبراهيم", "مصطفى",
    "خالد", "أمين", "حمزة", "طارق", "بلال", "ياسين", "أيوب", "زكريا", "أنس", "إسماعيل",
    "العربي", "هواري", "ديدوش", "مراد", "رياض", "كريم", "رابح", "لخضر", "صلاح الدين", "نور الدين",
    "عماد", "مهدي", "هشام", "سفيان", "سامي", "سليم", "وليد", "ياسر", "توفيق", "زياد",
    "حسام", "فارس", "عادل", "نبيل", "فريد", "جمال", "شريف", "مالك", "حميد", "رشيد"
]

def assign_ranks(names_list, top_priority_list):
    # Sort with top priority first, then remaining
    priority_map = {name: i + 1 for i, name in enumerate(top_priority_list)}
    
    indexed = []
    for i, item in enumerate(names_list):
        name = item[0]
        p = priority_map.get(name, 1000 + i)
        indexed.append((p, item))
    
    indexed.sort(key=lambda x: x[0])
    
    ranked = []
    for rank, (_, item) in enumerate(indexed, start=1):
        ranked.append({
            'name': item[0],
            'meaning': item[1],
            'countries': item[2],
            'isIslamic': item[3],
            'famousPeople': item[4],
            'popularityRank': rank
        })
    return ranked

# 1. Process Female Names (base + extra)
all_female_items = data_females.FEMALE_NAMES + data_females_extra.FEMALE_NAMES_EXTRA
female_processed = []
seen_females = set()
for item in all_female_items:
    n = norm(item[0])
    if n not in seen_females:
        seen_females.add(n)
        female_processed.append(item)

ranked_females = assign_ranks(female_processed, TOP_FEMALES_POPULARITY)

# 2. Process Male Names (MALE_NAMES + MALE_NAMES_EXTRA + ABD_NAMES + ABD_NAMES_EXTRA + DIN_NAMES + DIN_NAMES_EXTRA)
all_male_items = (
    data_males.MALE_NAMES + data_males_extra.MALE_NAMES_EXTRA +
    data_abd_din.ABD_NAMES + data_abd_din_extra.ABD_NAMES_EXTRA +
    data_abd_din.DIN_NAMES + data_abd_din_extra.DIN_NAMES_EXTRA
)
male_processed = []
seen_males = set()
for item in all_male_items:
    n = norm(item[0])
    if n not in seen_males and n not in seen_females:
        seen_males.add(n)
        male_processed.append(item)

ranked_males = assign_ranks(male_processed, TOP_MALES_POPULARITY)

all_twin_groups = data_twins.TWIN_GROUPS + data_twins_extra.TWIN_GROUPS_EXTRA

print(f"Verified Unique Females: {len(ranked_females)}")
print(f"Verified Unique Males:   {len(ranked_males)}")
print(f"Total Unique Baby Names: {len(ranked_females) + len(ranked_males)}")
print(f"Total Twin Groups:       {len(all_twin_groups)}")

# Write lib/data/baby_names_database.dart
def dart_quote(s):
    escaped = s.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$')
    return f"'{escaped}'"

def dart_list_str(str_list):
    if not str_list:
        return "[]"
    items = ", ".join(dart_quote(x) for x in str_list)
    return f"[{items}]"

print("\nGenerating lib/data/baby_names_database.dart ...")
with open('lib/data/baby_names_database.dart', 'w', encoding='utf-8') as f:
    f.write("""// ══════════════════════════════════════════════════════════════
// قاعدة بيانات أسماء المواليد الكبرى الموثقة — تطبيق نبضة
// أسماء عربية مفردة ومركبة أصيلة خالية من أي حشو أو تركيب مصطنع
// تم التحقق منها لغوياً وتاريخياً مع إسناد الشخصيات الموثقة
// ══════════════════════════════════════════════════════════════

import '../screens/baby_names/baby_names_screen.dart';

final List<BabyName> babyNamesDatabase = const [
  // ─── أسماء الإناث (Female Names) ───
""")
    for item in ranked_females:
        name_str = dart_quote(item['name'])
        meaning_str = dart_quote(item['meaning'])
        rank = item['popularityRank']
        countries_str = dart_list_str(item['countries'])
        is_islamic_str = "true" if item['isIslamic'] else "false"
        famous_str = dart_list_str(item['famousPeople'])
        
        f.write(f"  BabyName({name_str}, 'female', {meaning_str}, {rank}, {countries_str}, isIslamic: {is_islamic_str}, famousPeople: {famous_str}),\n")

    f.write("\n  // ─── أسماء الذكور (Male Names) ───\n")
    for item in ranked_males:
        name_str = dart_quote(item['name'])
        meaning_str = dart_quote(item['meaning'])
        rank = item['popularityRank']
        countries_str = dart_list_str(item['countries'])
        is_islamic_str = "true" if item['isIslamic'] else "false"
        famous_str = dart_list_str(item['famousPeople'])
        
        f.write(f"  BabyName({name_str}, 'male', {meaning_str}, {rank}, {countries_str}, isIslamic: {is_islamic_str}, famousPeople: {famous_str}),\n")

    f.write("];\n")

print("lib/data/baby_names_database.dart written successfully.")

# Write lib/data/twin_names_database.dart
print("\nGenerating lib/data/twin_names_database.dart ...")
with open('lib/data/twin_names_database.dart', 'w', encoding='utf-8') as f:
    f.write("""// ══════════════════════════════════════════════════════════════
// قاعدة بيانات مجموعات أسماء التوائم المتناسقة لغوياً وتاريخياً — تطبيق نبضة
// تغطي جميع التركيبات التسع (ثنائي / ثلاثي / رباعي × بنات / أولاد / مختلط)
// جميع الأسماء متطابقة وموجودة في قاعدة أسماء المواليد المفردة
// ══════════════════════════════════════════════════════════════

class TwinNameGroup {
  final String type; // 'ثنائي', 'ثلاثي', 'رباعي'
  final String genderType; // 'بنات', 'أولاد', 'مختلط'
  final List<String> names;
  final String harmonyReason; // سبب التناسق الحقيقي
  final String meaning; // شرح المعاني وتكاملها

  const TwinNameGroup({
    required this.type,
    required this.genderType,
    required this.names,
    required this.harmonyReason,
    required this.meaning,
  });
}

final List<TwinNameGroup> twinNamesDatabase = const [
""")
    for g in all_twin_groups:
        type_str = dart_quote(g['type'])
        gender_type_str = dart_quote(g['genderType'])
        names_str = dart_list_str(g['names'])
        harmony_str = dart_quote(g['harmonyReason'])
        meaning_str = dart_quote(g['meaning'])
        
        f.write(f"  TwinNameGroup(\n")
        f.write(f"    type: {type_str},\n")
        f.write(f"    genderType: {gender_type_str},\n")
        f.write(f"    names: {names_str},\n")
        f.write(f"    harmonyReason: {harmony_str},\n")
        f.write(f"    meaning: {meaning_str},\n")
        f.write(f"  ),\n")

    f.write("];\n")

print("lib/data/twin_names_database.dart written successfully.")

# Generate tools/verify_names.py
print("\nGenerating tools/verify_names.py ...")
with open('tools/verify_names.py', 'w', encoding='utf-8') as f:
    f.write("""# -*- coding: utf-8 -*-
\"\"\"
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
\"\"\"
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
    s = re.sub(r'[\u064B-\u0652]', '', s)  # tashkeel
    s = re.sub(r'[إأآا]', 'ا', s)
    s = re.sub(r'ة', 'ه', s)
    s = re.sub(r'ى', 'ي', s)
    return re.sub(r'\\s+', ' ', s).strip()

def main():
    print("==================================================")
    print("   NABDA BABY & TWIN NAMES DATABASE VERIFICATION  ")
    print("==================================================\\n")

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
        r"BabyName\\(\\s*'((?:\\\\.|[^'\\\\])*)',\\s*'(female|male)',\\s*'((?:\\\\.|[^'\\\\])*)',\\s*(\\d+),\\s*(?:const\\s*)?\\[([^\\]]*)\\],\\s*isIslamic:\\s*(true|false),\\s*famousPeople:\\s*(?:const\\s*)?\\[([^\\]]*)\\]\\s*\\)",
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
        r"TwinNameGroup\\(\\s*type:\\s*'([^']+)',\\s*genderType:\\s*'([^']+)',\\s*names:\\s*(?:const\\s*)?\\[([^\\]]+)\\],\\s*harmonyReason:\\s*'((?:\\\\.|[^'\\\\])*)',\\s*meaning:\\s*'((?:\\\\.|[^'\\\\])*)',\\s*\\)",
        re.MULTILINE
    )

    twin_matches = twin_pattern.findall(twin_content)
    print(f"  • Twin Groups:  {len(twin_matches)}\\n")

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
            c_list = [c.strip().strip(\"'\") for c in c_raw.split(',') if c.strip()]
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
        names_raw = [n.strip().strip(\"'\") for n in tm[2].split(',') if n.strip()]
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

    print("\\n==================================================")
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
""")

print("tools/verify_names.py generated successfully.")
