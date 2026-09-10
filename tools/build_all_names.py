# -*- coding: utf-8 -*-
"""
Main Builder Script for Nabda Authentic Baby Names & Twin Names Databases.
Generates:
1. lib/data/baby_names_database.dart
2. lib/data/twin_names_database.dart
3. tools/verify_names.py
"""
import os
import re
import sys

# 22 Approved Arab Countries
VALID_COUNTRIES = [
    'الجزائر', 'المغرب', 'تونس', 'ليبيا', 'مصر', 'السعودية', 'الإمارات', 'الكويت',
    'قطر', 'البحرين', 'عُمان', 'العراق', 'سوريا', 'الأردن', 'لبنان', 'فلسطين',
    'اليمن', 'السودان', 'موريتانيا', 'الصومال', 'جيبوتي', 'جزر القمر'
]

def normalize_ar(s):
    s = re.sub(r'[\u064B-\u0652]', '', s)
    s = re.sub(r'[إأآا]', 'ا', s)
    s = re.sub(r'ة', 'ه', s)
    s = re.sub(r'ى', 'ي', s)
    s = re.sub(r'\s+', ' ', s).strip()
    return s

print("Builder ready.")
