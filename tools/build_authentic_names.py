# -*- coding: utf-8 -*-
"""
tools/build_authentic_names.py
Builds the complete authentic baby_names_database.dart and twin_names_database.dart
"""
import os
import re
import sys

VALID_COUNTRIES = [
    'الجزائر', 'المغرب', 'تونس', 'ليبيا', 'مصر', 'السعودية', 'الإمارات', 'الكويت',
    'قطر', 'البحرين', 'عُمان', 'العراق', 'سوريا', 'الأردن', 'لبنان', 'فلسطين',
    'اليمن', 'السودان', 'موريتانيا', 'الصومال', 'جيبوتي', 'جزر القمر'
]

def normalize_ar(s):
    s = re.sub(r'[\u064B-\u0652]', '', s)  # tashkeel
    s = re.sub(r'[إأآا]', 'ا', s)
    s = re.sub(r'ة', 'ه', s)
    s = re.sub(r'ى', 'ي', s)
    s = re.sub(r'\s+', ' ', s).strip()
    return s

print("Normalizer ready.")
