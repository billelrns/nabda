import sys
sys.path.insert(0, 'tools')
import data_females
import data_males
import data_abd_din
import re

def norm(s):
    s = re.sub(r'[\u064B-\u0652]', '', s)
    s = re.sub(r'[إأآا]', 'ا', s)
    s = re.sub(r'ة', 'ه', s)
    s = re.sub(r'ى', 'ي', s)
    return re.sub(r'\s+', ' ', s).strip()

females = {norm(item[0]): item[0] for item in data_females.FEMALE_NAMES}
males = {norm(item[0]): item[0] for item in data_males.MALE_NAMES}
abds = {norm(item[0]): item[0] for item in data_abd_din.ABD_NAMES}
dins = {norm(item[0]): item[0] for item in data_abd_din.DIN_NAMES}

overlap_fm = set(females.keys()).intersection(set(males.keys()))
print("Overlap between Females and Males:", len(overlap_fm))
for k in overlap_fm:
    print(f"  - '{females[k]}' (F) vs '{males[k]}' (M)")

overlap_fa = set(females.keys()).intersection(set(abds.keys()))
overlap_ma = set(males.keys()).intersection(set(abds.keys()))
overlap_fd = set(females.keys()).intersection(set(dins.keys()))
overlap_md = set(males.keys()).intersection(set(dins.keys()))
print("Overlap with Abd/Din:", len(overlap_fa), len(overlap_ma), len(overlap_fd), len(overlap_md))
