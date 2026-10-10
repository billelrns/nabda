# -*- coding: utf-8 -*-
"""
Prototype Humanizer & Linguistic Polisher for Nabda Articles.
Tests transformations on sample articles.
"""
import json
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

# 1. Title Polishing
AI_PREFIXES = [
    r'^احذري إهمال ذلك:\s*',
    r'^ملفكِ الشامل:\s*',
    r'^الدليل الطبي الشامل:\s*',
    r'^دليلكِ الشامل:\s*',
    r'^سر طبي:\s*',
    r'^اكتشفي معنا:\s*',
    r'^هام جداً:\s*',
    r'^لكِ وحدكِ:\s*',
]

AI_SUFFIXES = [
    r'\s*[٠-٩0-9]+\s*حقائق خفية لم يخبركِ بها أحد\s*[✨🩺🌸💖🍼]*',
    r'\s*كشف السر الطبي وخطوات العلاج\s*[✨🩺🌸💖🍼]*',
    r'\s*والحلول الطبية الصحيحة\s*[✨🩺🌸💖🍼]*',
    r'\s*بطرق آمنة وموثقة\s*[✨🩺🌸💖🍼]*',
    r'\s*بأعلى نسب نجاح\s*[✨🩺🌸💖🍼]*',
    r'\s*دليلك الشامل الموثق\s*[✨🩺🌸💖🍼]*',
    r'\s*بأعلى دقة ممكنة\s*[✨🩺🌸💖🍼]*',
    r'\s*خطوات علمية ومجربة\s*[✨🩺🌸💖🍼]*',
    r'\s*[✨🩺🌸💖🍼]+$',
]

def clean_title(title):
    t = title.strip()
    for p in AI_PREFIXES:
        t = re.sub(p, '', t, flags=re.IGNORECASE)
    for s in AI_SUFFIXES:
        t = re.sub(s, '', t, flags=re.IGNORECASE)
    
    # Clean redundant punctuation
    t = re.sub(r'[-–—_]+', ' ', t)
    t = re.sub(r'\s*!\s*!', '!', t)
    t = re.sub(r'\s*؟\s*؟', '؟', t)
    t = re.sub(r'\s+', ' ', t).strip()
    
    # Common title spelling fixes
    t = re.sub(r'\bتبدا\b', 'تبدأ', t)
    t = re.sub(r'\bاعراض\b', 'أعراض', t)
    t = re.sub(r'\bانا\b', 'أنا', t)
    t = re.sub(r'\bاهم\b', 'أهم', t)
    t = re.sub(r'\bافضل\b', 'أفضل', t)
    t = re.sub(r'\bاثناء\b', 'أثناء', t)
    t = re.sub(r'\bاسباب\b', 'أسباب', t)
    t = re.sub(r'\bادوية\b', 'أدوية', t)
    t = re.sub(r'\bاطعمة\b', 'أطعمة', t)
    t = re.sub(r'\bاشهر\b', 'أشهر', t)
    t = re.sub(r'\bاسابيع\b', 'أسابيع', t)
    t = re.sub(r'\bاطفال\b', 'أطفال', t)
    t = re.sub(r'\bالم\b', 'ألم', t)
    t = re.sub(r'\bعلي\b', 'على', t)
    t = re.sub(r'\bإلي\b', 'إلى', t)
    
    # Ensure question ends with question mark if it starts with question word
    q_words = ['متى', 'هل', 'كيف', 'ماذا', 'لماذا', 'ما هي', 'ما هو', 'أين', 'كم']
    starts_with_q = any(t.startswith(qw) for qw in q_words)
    if starts_with_q and not t.endswith('؟') and not t.endswith('!'):
        t = t + '؟'
    
    return t

print("--- TESTING TITLE CLEANING ---")
sample_titles = [
    "متى تبدا أعراض الحمل بالظهور! وما الفرق بينها وبين الدورة؟ ٥ حقائق خفية لم يخبركِ بها أحد ✨",
    "متى تكون برودة الأطراف مقلقة أثناء الحمل وما العلاج؟ ٥ حقائق خفية لم يخبركِ بها أحد 🩺",
    "ملفكِ الشامل: انا حامل 13 طريقة مثالية لـ تعامل الزوج مع زوجته الحامل بأعلى نسب نجاح 💖",
    "احذري إهمال ذلك: أهم فوائد فيتامين د للنساء للحوامل والحلول الطبية الصحيحة 💊",
    "هل يمكن ترطيب البشرة أثناء الحمل بـ حمض الهيالورونيك؟ كشف السر الطبي وخطوات العلاج 🌸",
]
for st in sample_titles:
    print(f"BEFORE: {st}")
    print(f"AFTER : {clean_title(st)}\n")
