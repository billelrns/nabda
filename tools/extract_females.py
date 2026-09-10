import re
import sys

def extract_female_data():
    with open('tools/build_master_databases.py', 'r', encoding='utf-8') as f:
        content = f.read()

    # Find FEMALE_DATA
    m = re.search(r'FEMALE_DATA\s*=\s*\[(.*?)\]\s*print\(', content, re.DOTALL)
    if not m:
        print("Could not find FEMALE_DATA")
        return []
    
    body = m.group(1)
    
    # We can evaluate body with a local scope that has the country lists
    scope = {
        'ALL_C': ['الجزائر', 'المغرب', 'تونس', 'ليبيا', 'مصر', 'السعودية', 'الإمارات', 'الكويت', 'قطر', 'البحرين', 'عُمان', 'العراق', 'سوريا', 'الأردن', 'لبنان', 'فلسطين', 'اليمن', 'السودان', 'موريتانيا', 'الصومال', 'جيبوتي', 'جزر القمر'],
        'MAG': ['الجزائر', 'المغرب', 'تونس', 'ليبيا', 'موريتانيا'],
        'ALG_EGY_GLF': ['الجزائر', 'المغرب', 'تونس', 'مصر', 'السعودية', 'الإمارات', 'الكويت'],
        'PAN': ['الجزائر', 'المغرب', 'تونس', 'مصر', 'السعودية', 'الإمارات', 'العراق', 'سوريا', 'الأردن', 'فلسطين', 'لبنان', 'اليمن', 'السودان'],
        'ALG_LEV': ['الجزائر', 'المغرب', 'تونس', 'مصر', 'سوريا', 'لبنان', 'الأردن', 'فلسطين'],
        'ALG_MAIN': ['الجزائر', 'المغرب', 'تونس', 'ليبيا', 'مصر'],
    }
    
    exec("data = [" + body + "]", scope)
    data = scope['data']
    print(f"Successfully extracted {len(data)} female items.")
    return data

if __name__ == '__main__':
    data = extract_female_data()
    # Normalize and dedup
    seen = set()
    unique_data = []
    for item in data:
        name = item[0]
        norm = re.sub(r'[\u064B-\u0652]', '', name)
        norm = re.sub(r'[إأآا]', 'ا', norm)
        norm = re.sub(r'ة', 'ه', norm)
        norm = re.sub(r'ى', 'ي', norm)
        norm = norm.strip()
        if norm not in seen:
            seen.add(norm)
            unique_data.append(item)
    print(f"Unique female names: {len(unique_data)}")
    
    # Save to tools/data_females.py
    with open('tools/data_females.py', 'w', encoding='utf-8') as f:
        f.write('# -*- coding: utf-8 -*-\n')
        f.write('"""Unique vetted female names."""\n\n')
        f.write('FEMALE_NAMES = [\n')
        for item in unique_data:
            name, meaning, countries, is_islamic, famous = item
            f.write(f'    ({repr(name)}, {repr(meaning)}, {repr(countries)}, {repr(is_islamic)}, {repr(famous)}),\n')
        f.write(']\n')
    print("Saved to tools/data_females.py")
