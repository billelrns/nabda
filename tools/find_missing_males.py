import sys
sys.path.insert(0, 'tools')
import data_males
import re

def norm(s):
    s = re.sub(r'[\u064B-\u0652]', '', s)
    s = re.sub(r'[إأآا]', 'ا', s)
    s = re.sub(r'ة', 'ه', s)
    s = re.sub(r'ى', 'ي', s)
    return s.strip()

current_names = {norm(item[0]): item[0] for item in data_males.MALE_NAMES}
print("Current unique male names:", len(current_names))

candidates = [
    "أصيل", "أمان", "أيسر", "بدران", "بهير", "تالد", "تامر", "ثائر", "جلول", "حسيب",
    "حفص", "خنفر", "خضر", "داني", "دياب", "ذاخر", "ذو الفقار", "زعيم", "زرياب", "سرحان",
    "سطام", "سعدان", "سعدي", "سميح", "شداد", "شكيب", "صباح", "طيب", "ظهير", "عاقل",
    "عساف", "عصمت", "عطية", "علام", "عمير", "عنان", "عواد", "عوض", "عوف", "غالي",
    "فرات", "فرج", "فرحان", "فطين", "فهيم", "فياض", "قتادة", "قدري", "قطز", "كميل",
    "كنعان", "محفوظ", "مختار", "مدين", "مرعي", "مطر", "مقداد", "منصف", "موفق", "مؤنس",
    "ميمون", "ناصح", "نبراس", "نبهان", "نجدت", "نصري", "نصوح", "نمير", "نوار", "هتان",
    "هلال", "وافي", "وصفي", "وفيق", "وقار", "ونيس"
]

missing = [c for c in candidates if norm(c) not in current_names]
print(f"Candidates checked: {len(candidates)}, Missing in data_males: {len(missing)}")
print("Missing samples:", missing)
