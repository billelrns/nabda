import re

with open("lib/data/baby_names_database.dart", "r", encoding="utf-8") as f:
    content = f.read()

names = re.findall(r'BabyName\(\s*"([^"]+)"', content)
print(f"Total BabyName matches: {len(names)}")

famous_mentions = re.findall(r'أشهر من سُمّي به', content)
print(f"Total 'أشهر من سُمّي به' matches: {len(famous_mentions)}")

male_count = len(re.findall(r"BabyName\([^,]+,\s*'male'", content))
female_count = len(re.findall(r"BabyName\([^,]+,\s*'female'", content))
print(f"Male: {male_count}, Female: {female_count}")
