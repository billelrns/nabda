# -*- coding: utf-8 -*-
"""
tools/generate_expansion.py
Prepares expanded vetted datasets for:
1. Female Names
2. Male Names
3. Abd & Din Names
4. Twin Groups
"""
import sys
import os
import re

sys.path.insert(0, 'tools')
import data_females
import data_males
import data_abd_din
import data_twins
from verify_names import normalize_ar, VALID_COUNTRIES, FORBIDDEN_TEMPLATES, OLD_ADJECTIVES

sys.stdout.reconfigure(encoding='utf-8')

# Collect all existing normalized names
existing_norms = set()
for item in data_females.FEMALE_NAMES:
    existing_norms.add(normalize_ar(item[0]))
for item in data_males.MALE_NAMES + data_abd_din.ABD_NAMES + data_abd_din.DIN_NAMES:
    existing_norms.add(normalize_ar(item[0]))

print(f"Base existing normalized count: {len(existing_norms)}")
