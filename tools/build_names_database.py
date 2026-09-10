# -*- coding: utf-8 -*-
"""
Script to build and curate the authentic Arabic Baby Names and Twin Names databases for Nabda App.
Adheres strictly to all linguistic, cultural, and technical constraints:
- Zero programmatic padding / synthetic compounding
- Single authentic Arabic names (plus classic Abdul- and -al-Din compounds)
- True linguistic meanings from Arabic lexicons (length >= 20 chars)
- Documented famous personalities (famousPeople field, priority to Algerian/Maghrebi figures)
- Real popularity ranks and regional country distribution
- 100% integration with twin names database
"""

import os
import re
import sys

VALID_COUNTRIES = {
    'الجزائر', 'المغرب', 'تونس', 'ليبيا', 'مصر', 'السعودية', 'الإمارات', 'الكويت',
    'قطر', 'البحرين', 'عُمان', 'العراق', 'سوريا', 'الأردن', 'لبنان', 'فلسطين',
    'اليمن', 'السودان', 'موريتانيا', 'الصومال', 'جيبوتي', 'جزر القمر'
}

# Regional helpers
ALL_ARAB = list(VALID_COUNTRIES)
MAGHREB = ['الجزائر', 'المغرب', 'تونس', 'ليبيا', 'موريتانيا']
ALGERIA_COMMON = ['الجزائر', 'المغرب', 'تونس', 'ليبيا', 'مصر']
GULF_SHAM_MAGHREB = ['الجزائر', 'المغرب', 'تونس', 'مصر', 'السعودية', 'الإمارات', 'الأردن', 'سوريا']
PAN_ARAB = ['الجزائر', 'المغرب', 'تونس', 'مصر', 'السعودية', 'الإمارات', 'الكويت', 'العراق', 'سوريا', 'الأردن', 'لبنان', 'فلسطين', 'اليمن', 'السودان']

def normalize_ar(s):
    s = re.sub(r'[\u064B-\u0652]', '', s)  # tashkeel
    s = re.sub(r'[إأآا]', 'ا', s)
    s = re.sub(r'ة', 'ه', s)
    s = re.sub(r'ى', 'ي', s)
    s = re.sub(r'\s+', ' ', s).strip()
    return s

print("Module loaded.")
