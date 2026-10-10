#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
scripts/classify_and_distribute_articles.py
===========================================
Classifies all 6,982 articles in Nabda into 28 subcategories and specialized domains.
Assigns:
  - subcategoryId
  - subcategoryName
  - specialty
  - tags
Updates:
  - assets/data/smart_2500_articles.json
  - assets/data/smart_7200_articles.json
  - assets/data/smart_7200_catalog.md
  - assets/data/smart_2500_catalog.md
"""

import json
import re
import os
import sys
from collections import Counter

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

# ══════════════════════════════════════════════════════════════
# TAXONOMY DEFINITIONS (28 Subcategories across 6 Major Categories)
# ══════════════════════════════════════════════════════════════

TAXONOMY = {
    "pregnancy": {
        "preg_nutrition_vitamins": {
            "name": "تغذية الحامل والفيتامينات والمكملات",
            "specialty": "تغذية الحمل والتمثيل الغذائي",
            "emoji": "🥗",
            "keywords": [
                "غذاء", "أكل", "طعام", "تغذية", "وجبات", "أطعمة", "فيتامين", "حمض الفوليك",
                "كالسيوم", "حديد", "مشروب", "عصائر", "مكسرات", "سمك", "حليب", "أوميغا",
                "قهوة", "شاي", "كافيين", "سكر الحمل", "سكري الحمل", "وزن الحامل", "نظام غذائي",
                "فواكه", "خضار", "تسمين", "دايت للحامل", "سوائل", "عصير", "موز", "تمر", "بيض"
            ]
        },
        "preg_labor_delivery": {
            "name": "المخاض والولادة والتحضير",
            "specialty": "طب التوليد والولادة الآمنة",
            "emoji": "🏥",
            "keywords": [
                "ولادة", "مخاض", "طلق", "قيصرية", "ولادة طبيعية", "حقيبة الولادة", "كيس الماء",
                "توسع الرحم", "عوارض الولادة", "علامات الولادة", "الولادة المبكرة", "التخدير",
                "إبرة الظهر", "إبيدورال", "غرفة العمليات", "المستشفى", "تسهيل الولادة", "طلق صناعي",
                "تمارين الولادة", "قاع الحوض", "انفجار كيس"
            ]
        },
        "preg_health_tests": {
            "name": "الفحوصات والسونار وعلاج المتاعب",
            "specialty": "طب الأجنة وصحة الأم الحامل",
            "emoji": "🔬",
            "keywords": [
                "سونار", "أشعة", "فحص", "تحليل", "إيكو", "تشوهات", "متلازمة داون", "ضغط الدم",
                "تسمم الحمل", "زلال", "نزيف", "مشيمة", "إجهاض", "تجلط", "فقر دم", "أنيميا",
                "التهاب البول", "إفرازات الحمل", "ريزوس", "rh", "سائل أمنيوسي", "ألم البطن",
                "تقلصات", "مغص", "دوالي", "بواسير الحمل", "سكر البول", "التهاب المهبل", "كلى",
                "إفرازات بنية", "إفرازات صفراء", "نزول دم"
            ]
        },
        "preg_postpartum": {
            "name": "ما بعد الولادة وفترة النفاس",
            "specialty": "التعافي وصحة ما بعد الولادة",
            "emoji": "🌸",
            "keywords": [
                "نفاس", "ما بعد الولادة", "اكتئاب الولادة", "دم النفاس", "الخياطة", "جرح القيصرية",
                "شد البطن بعد الولادة", "نزول الرحم", "طهارة النفاس", "أربعين", "كآبة الأمومة",
                "التعافي بعد الولادة", "رياضة بعد الولادة"
            ]
        },
        "preg_symptoms_weeks": {
            "name": "أعراض الحمل وتطور الجنين أسبوعياً",
            "specialty": "فسيولوجيا الحمل وتطور الأجنة",
            "emoji": "🤰",
            "keywords": [
                "أسبوع", "جنين", "حركة الجنين", "نبض الجنين", "بطن الحامل", "غثيان الحمل", "وحام",
                "إرهاق", "نوم الحامل", "ثقل", "تشققات", "علامات تمدد", "الشهر الأول", "الشهر الثاني",
                "الشهر الثالث", "الشهر الرابع", "الشهر الخامس", "الشهر السادس", "الشهر السابع",
                "الشهر الثامن", "الشهر التاسع", "أعراض الحمل", "نوع الجنين", "ولد أم بنت", "تحديد جنس"
            ]
        }
    },
    "baby": {
        "baby_breastfeeding_food": {
            "name": "الرضاعة الطبيعية والتغذية والفطام",
            "specialty": "تغذية الرضع والأطفال",
            "emoji": "🍼",
            "keywords": [
                "رضاعة", "حليب", "ثدي", "ببرونة", "زجاجة", "شفط", "طعام الرضيع", "أكل الطفل",
                "فطام", "وجبات الرضع", "سيريلاك", "شبع", "جوع", "تجشؤ", "إدرار الحليب", "حلمة",
                "حليب صناعي", "إطعام", "بلع", "طعام صلب", "هريس"
            ]
        },
        "baby_sleep_routine": {
            "name": "نوم الرضيع والروتين والتعامل مع البكاء",
            "specialty": "تنظيم سلوك ونوم الأطفال",
            "emoji": "😴",
            "keywords": [
                "نوم الرضيع", "أرق الرضيع", "بكاء", "صراخ", "مغص الرضع", "غازات الرضيع", "تهدئة",
                "لف الطفل", "قماط", "سرير الطفل", "قيلولة", "روتين النوم", "استيقاظ", "نوم متقطع",
                "مصاصة", "لهاية", "هز الطفل"
            ]
        },
        "baby_development_growth": {
            "name": "مراحل النمو والتطور الحركي واللغوي",
            "specialty": "نمو وتطور الطفل وطب الأطفال",
            "emoji": "🧸",
            "keywords": [
                "نمو", "تطور", "حبو", "زحف", "مشي", "جلوس", "وزن الرضيع", "طول الرضيع", "أسنان",
                "تسنين", "كلام", "نطق", "مناغاة", "ذكاء الطفل", "حواس", "ألعاب تعليمية", "حركة الطفل",
                "محيط الرأس", "تأخر النطق", "تأخر المشي"
            ]
        },
        "baby_safety_gear": {
            "name": "سلامة وأمان الطفل والمستلزمات",
            "specialty": "سلامة ورعاية حديثي الولادة",
            "emoji": "🛡️",
            "keywords": [
                "حفاضات", "سرير", "عربة", "كرسي سيارة", "أمان", "سقوط", "حروق", "تسمم",
                "ألعاب الرضع", "ملابس الرضيع", "مستلزمات", "حقيبة الطفل", "استحمام الطفل", "غسيل ملابس الرضيع"
            ]
        },
        "baby_health_care": {
            "name": "صحة الرضيع والتطعيمات والعناية اليومية",
            "specialty": "طب الأطفال الوقائي والعلاجي",
            "emoji": "👶",
            "keywords": [
                "حرارة", "حمى", "تطعيم", "لقاح", "سعال", "رشح", "إسهال", "إمساك", "طفح الحفاض",
                "حساسية الرضع", "صفار", "يرقان", "ختان", "مغص", "أطباء الأطفال", "سرة الرضيع",
                "تنظيف الأنف", "بلغم", "استفراغ", "ارتجاع المريء"
            ]
        }
    },
    "fertility": {
        "fert_ovulation_cycle": {
            "name": "حساب أيام التبويض وعلامات الخصوبة",
            "specialty": "فسيولوجيا التبويض والخصوبة",
            "emoji": "🗓️",
            "keywords": [
                "تبويض", "إباضة", "بويضة", "نافذة الخصوبة", "أيام التبويض", "إفرازات التبويض",
                "حرارة الجسم القاعدية", "شريط التبويض", "اختبار الإباضة", "تحديد التبويض",
                "حساب التبويض", "مخاط عنق الرحم"
            ]
        },
        "fert_pcos_hormones": {
            "name": "تكيس المبايض واضطرابات الهرمونات",
            "specialty": "الغدد الصماء التناسلية وتكيس المبايض",
            "emoji": "🩺",
            "keywords": [
                "تكيس", "تكيس المبايض", "متلازمة", "أكياس", "إنسولين", "مقاومة الإنسولين", "lh",
                "fsh", "هرمون الحليب", "برولاكتين", "الغدة الدرقية", "شعر زائد", "خربطة الدورة",
                "كيس على المبيض", "اضطراب الهرمونات"
            ]
        },
        "fert_ivf_medical": {
            "name": "الفحوصات والحقن المجهري والتلقيح",
            "specialty": "طب الإنجاب وتقنيات المساعدة على الحمل",
            "emoji": "🔬",
            "keywords": [
                "حقن مجهري", "طفل أنابيب", "تلقيح صناعي", "سحب البويضات", "إرجاع الأجنة",
                "أشعة بالصبغة", "انسداد فالوب", "تحليل السائل المنوي", "تشوهات الحيوانات",
                "مخزون المبيض", "amh", "منشطات", "كلوميد", "إبر تفجيرية"
            ]
        },
        "fert_boost_tips": {
            "name": "تعزيز الخصوبة وفرص الحمل الطبيعي",
            "specialty": "صحة الخصوبة ونمط الحياة",
            "emoji": "🌸",
            "keywords": [
                "زيادة الخصوبة", "فرص الحمل", "تنشيط", "حمل سريع", "أعشاب للحمل", "فيتامينات الخصوبة",
                "سن الإنجاب", "تأخر الحمل", "رغبة الحمل", "تحسين جودة البويضات", "نصائح للحمل",
                "عوامل الخصوبة"
            ]
        }
    },
    "health": {
        "health_period_cycle": {
            "name": "الدورة الشهرية ومتلازمة ما قبل الطمث",
            "specialty": "صحة الدورة الشهرية وأمراض النساء",
            "emoji": "🩸",
            "keywords": [
                "دورة شهرية", "حيض", "طمث", "غزارة الدورة", "انقطاع الدورة", "تأخر الدورة",
                "مغص الدورة", "pms", "متلازمة ما قبل الدورة", "فوط صحية", "إفرازات مهبلية",
                "نزيف رحمي", "ألم الحيض", "انتظام الدورة", "الدورة الشهرية"
            ]
        },
        "health_nutrition_fitness": {
            "name": "الرشاقة وإنقاص الوزن والطبخ الصحي",
            "specialty": "التغذية العلاجية واللياقة البدنية",
            "emoji": "🥗",
            "keywords": [
                "رجيم", "دايت", "تخسيس", "إنقاص الوزن", "حرق الدهون", "سعرات", "بطن", "كرش",
                "تمارين", "جيم", "لياقة", "كارديو", "كيتو", "صيام متقطع", "بروتين", "دهون ثلاثية",
                "وجبة", "وصفة", "طبخ", "حلويات", "كيك", "شوربة", "سلطة", "مبكبكة", "أكل صحي",
                "شحوم", "وزن مثالي", "نحت الجسم", "مشروبات حارقة"
            ]
        },
        "health_diseases_prevention": {
            "name": "الأمراض النسائية وصحة الثدي والوقاية",
            "specialty": "الطب الباطني والوقائي للمرأة",
            "emoji": "🩺",
            "keywords": [
                "سرطان", "ثدي", "ورم", "فحص الثدي", "التهاب", "بكتيريا", "فطريات", "مسالك بولية",
                "كلى", "كبد", "سكري", "ضغط", "قلب", "فقر دم", "حديد", "كولسترول", "مناعة",
                "فيروس", "جرثومة", "قولون", "معدة", "حموضة", "مرارة", "عظام", "هشاشة العظام"
            ]
        },
        "health_mental_wellness": {
            "name": "الصحة النفسية والاسترخاء والسكينة",
            "specialty": "علم النفس الإيجابي وصحة العقل",
            "emoji": "🕊️",
            "keywords": [
                "توتر", "قلق", "اكتئاب", "حزن", "ضغط نفسي", "وسواس", "استرخاء", "تأمل",
                "طاقة إيجابية", "سعادة", "راحة بال", "يوجا", "تنفس", "نوم", "أرق", "صداع",
                "شقيقة", "نوبات هلع", "تفريغ المشاعر"
            ]
        },
        "health_hormones_lifestyle": {
            "name": "الغدد والهرمونات ونمط الحياة الصحي",
            "specialty": "صحة المرأة العامة والطب الشامل",
            "emoji": "💗",
            "keywords": [
                "هرمونات", "غدة درقية", "كورتيزول", "نشاط", "كسل", "فيتامين د", "شرب الماء",
                "شاي أخضر", "أعشاب", "عادات", "صباح", "روتين صحي", "مناعة الجسم", "صحة المرأة",
                "فحوصات دورية", "سن اليأس", "انقطاع الطمث"
            ]
        }
    },
    "beauty": {
        "beauty_haircare": {
            "name": "العناية بالشعر ومنع التساقط والتقصف",
            "specialty": "علاج وأمراض وصحة الشعر",
            "emoji": "💇‍♀️",
            "keywords": [
                "شعر", "تساقط الشعر", "بصيلات", "قشرة", "بلسم", "شامبو", "زيت الشعر", "سيروم الشعر",
                "صبغة", "حناء", "بروتين الشعر", "كيراتين", "فرد الشعر", "تطويل الشعر", "كثافة",
                "أطراف الشعر", "تقصف", "شعر جاف", "شعر دهني", "شيب"
            ]
        },
        "beauty_natural_recipes": {
            "name": "الوصفات والخلطات الطبيعية والروتين المنزلي",
            "specialty": "العناية الطبيعية بالبشرة والجمال",
            "emoji": "🌿",
            "keywords": [
                "خلطة", "ماسك", "وصفة طبيعية", "زيت لوز", "زيت زيتون", "عسل", "ليمون", "شوفان",
                "ماء ورد", "زبادي للبشرة", "مقشر منزلي", "أعشاب تجميل", "نشاء", "كركم للوجه",
                "خيار للعينين", "صبار", "ألوفيرا"
            ]
        },
        "beauty_pregnancy_safe": {
            "name": "الجمال الآمن أثناء الحمل وما بعد الولادة",
            "specialty": "العناية بالبشرة للأمهات والحوامل",
            "emoji": "🤰",
            "keywords": [
                "حامل", "أثناء الحمل", "كلف الحمل", "تصبغات الحمل", "تشققات البطن", "مستحضرات آمنة",
                "ريتينول", "ساليسيليك", "بعد الولادة", "العناية بالحامل تجميل"
            ]
        },
        "beauty_body_perfume": {
            "name": "العناية بالجسم والتعطير والنعومة",
            "specialty": "العناية المتكاملة بالجسم والأنوثة",
            "emoji": "✨",
            "keywords": [
                "جسم", "تقشير الجسم", "ترطيب الجسم", "تفتيح المناطق", "إزالة الشعر", "ليزر",
                "شمع", "سويت", "رائحة", "عطر", "مسك", "استحمام", "حمام مغربي", "نعومة القدمين",
                "يدين", "أظافر", "مانيكير", "باديكير"
            ]
        },
        "beauty_skincare": {
            "name": "العناية بالبشرة والوجه والنضارة",
            "specialty": "طب الجلدية ونضارة الوجه",
            "emoji": "💄",
            "keywords": [
                "بشرة", "وجه", "حب الشباب", "بثور", "هالات سوداء", "تجاعيد", "كولاجين", "واقي شمس",
                "ترطيب الوجه", "نضارة", "مسام", "غسول", "سيروم", "مسامات", "بشرة دهنية", "بشرة جافة",
                "بشرة مختلطة", "تفتيح الوجه", "نظارة", "فيلر", "بوتوكس", "مكياج"
            ]
        }
    },
    "marriage": {
        "marr_intimacy": {
            "name": "العلاقة الحميمة والانسجام الجسدي",
            "specialty": "الصحة الجنسية والعلاقة الزوجية الخاصة",
            "emoji": "💕",
            "keywords": [
                "علاقة حميمة", "جماع", "رغبة", "لقاء خاص", "اتصال جسدي", "ليلة الزفاف", "سرير",
                "رومانسية خاصة", "جاذبية", "نشوة", "فراش الزوجية", "برود جنسي", "ألم الجماع",
                "حميمية", "إثارة"
            ]
        },
        "marr_conflicts_solutions": {
            "name": "إدارة الخلافات وتجاوز الضغوط الزوجية",
            "specialty": "الإرشاد والاستشارات الأسرية",
            "emoji": "🕊️",
            "keywords": [
                "خلاف", "مشكلة", "شجار", "غضب", "عتاب", "خصام", "طلاق", "انفصال", "نكد",
                "حماتي", "أهل الزوج", "صمت زوجي", "خيانة", "شك", "برود", "كذب", "إهانة",
                "تجاهل", "مشاكل زوجية", "حل الخلاف"
            ]
        },
        "marr_parenting_partnership": {
            "name": "الشراكة الوالدية وبناء الأسرة المستقرة",
            "specialty": "التربية الوالدية والشراكة الأسرية",
            "emoji": "👨‍👩‍👧",
            "keywords": [
                "أبناء", "أطفال", "تربية", "شراكة", "مسؤولية", "ميزانية الأسرة", "بيت سعيد",
                "استقرار", "تعاون الزوجين", "الوالدية", "أب", "دور الزوج", "أولاد", "تربية الأبناء"
            ]
        },
        "marr_communication": {
            "name": "التفاهم والحوار وبناء لغات الحب",
            "specialty": "التواصل والعلاقات الإنسانية",
            "emoji": "💍",
            "keywords": [
                "زوج", "حب", "تفاهم", "حوار", "كلام طيب", "اهتمام", "تقدير", "رومانسية",
                "هدية", "مفاجأة", "زوجي", "شريك الحياة", "مشاعر", "عاطفة", "لغات الحب",
                "كسب قلب", "تجديد الحب", "الاحتواء"
            ]
        }
    }
}

# Fallbacks for each category
FALLBACK_SUBCAT = {
    "pregnancy": "preg_symptoms_weeks",
    "baby": "baby_health_care",
    "fertility": "fert_boost_tips",
    "health": "health_hormones_lifestyle",
    "beauty": "beauty_skincare",
    "marriage": "marr_communication",
}

def classify_article(article):
    cat_id = article.get("categoryId", "health")
    if cat_id not in TAXONOMY:
        cat_id = "health"
    
    title = article.get("title", "")
    summary = article.get("summary", "")
    sections_text = " ".join([s.get("title", "") + " " + s.get("content", "") for s in article.get("sections", [])[:2]])
    text = f"{title} {title} {summary} {sections_text}".lower()
    
    cat_subcats = TAXONOMY[cat_id]
    best_subcat = None
    best_score = -1
    
    for sub_id, sub_info in cat_subcats.items():
        score = 0
        for kw in sub_info["keywords"]:
            if kw in title.lower():
                score += 5
            if kw in text:
                score += 1
        if score > best_score:
            best_score = score
            best_subcat = sub_id
            
    if not best_subcat or best_score == 0:
        best_subcat = FALLBACK_SUBCAT.get(cat_id, list(cat_subcats.keys())[-1])
        
    sub_meta = cat_subcats[best_subcat]
    
    tags = [cat_id, best_subcat, sub_meta["name"].split()[0]]
    if "تغذية" in text or "أكل" in text: tags.append("تغذية")
    if "طفل" in text or "رضيع" in text: tags.append("طفل")
    if "حمل" in text or "جنين" in text: tags.append("حمل")
    if "طبيعي" in text or "أعشاب" in text: tags.append("طبيعي")
    if "بشرة" in text or "جمال" in text: tags.append("جمال")
    
    return {
        "subcategoryId": best_subcat,
        "subcategoryName": sub_meta["name"],
        "specialty": sub_meta["specialty"],
        "subcategoryEmoji": sub_meta["emoji"],
        "tags": list(set(tags))
    }

def main():
    db_path = "assets/data/smart_2500_articles.json"
    export_path = "assets/data/smart_7200_articles.json"
    catalog_path = "assets/data/smart_7200_catalog.md"
    catalog2_path = "assets/data/smart_2500_catalog.md"
    
    print(f"[1/4] Loading {db_path}...")
    with open(db_path, "r", encoding="utf-8") as f:
        data = json.load(f)
        
    articles = data.get("articles", [])
    total = len(articles)
    print(f"Total articles loaded: {total}")
    
    subcat_counts = Counter()
    
    for idx, art in enumerate(articles):
        classification = classify_article(art)
        art["subcategoryId"] = classification["subcategoryId"]
        art["subcategoryName"] = classification["subcategoryName"]
        art["specialty"] = classification["specialty"]
        art["subcategoryEmoji"] = classification["subcategoryEmoji"]
        art["tags"] = classification["tags"]
        subcat_counts[art["subcategoryId"]] += 1
        
    data["taxonomy"] = TAXONOMY
    data["subcategoriesCount"] = len(subcat_counts)
    data["version"] = "6.2.0-classified"
    
    print("\n[2/4] Classification Distribution:")
    for cat_id, subcats in TAXONOMY.items():
        print(f"\n--- {cat_id.upper()} ---")
        for sub_id, sub_info in subcats.items():
            count = subcat_counts[sub_id]
            pct = (count / total) * 100
            print(f"  • {sub_info['emoji']} {sub_info['name']} ({sub_id}): {count:,} articles ({pct:.1f}%)")
            
    print(f"\n[3/4] Saving updated databases...")
    with open(db_path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"Saved {db_path} ({os.path.getsize(db_path)/(1024*1024):.1f} MB)")
    
    with open(export_path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"Saved {export_path} ({os.path.getsize(export_path)/(1024*1024):.1f} MB)")
    
    print(f"\n[4/4] Updating Markdown catalogs...")
    catalog_lines = [
        "# كتالوج موسوعة نبضة الطبية المصنفة الشاملة (6,982 مقالاً)",
        "## تصنيف وتوزيع الأقسام والتصنيفات الفرعية والتخصصات الدقيقة — إصدار v6.2.0",
        "",
        f"**إجمالي المقالات:** {total:,} مقالاً موثقاً بالكامل | **التصنيفات الفرعية:** {len(subcat_counts)} تصنيفاً طبياً متخصصاً",
        "",
        "### ملخص الأقسام والتصنيفات الفرعية:",
        "| القسم الرئيسي | الكود | التصنيف الفرعي | عدد المقالات | التخصص الطبي |",
        "| :--- | :--- | :--- | :---: | :--- |"
    ]
    
    for cat_id, subcats in TAXONOMY.items():
        for sub_id, sub_info in subcats.items():
            count = subcat_counts[sub_id]
            catalog_lines.append(f"| {cat_id} | `{sub_id}` | {sub_info['emoji']} {sub_info['name']} | **{count:,}** | {sub_info['specialty']} |")
            
    catalog_lines.extend([
        "",
        "---",
        "",
        "### فهرس المقالات الكامل مع التصنيفات الفرعية (عينة من أول 200 مقال):",
        "| الرقم | المعرف | القسم | التصنيف الفرعي | المشاهدات | العنوان المشوق المعتمد |",
        "| :---: | :---: | :---: | :--- | :---: | :--- |"
    ])
    
    for i, a in enumerate(articles[:200], start=1):
        catalog_lines.append(f"| {i} | `{a['id']}` | {a.get('categoryName','')} | {a.get('subcategoryEmoji','')} {a.get('subcategoryName','')} | {a.get('originalViews',0):,} | {a.get('title','')} |")
        
    catalog_content = "\n".join(catalog_lines) + "\n"
    with open(catalog_path, "w", encoding="utf-8") as f:
        f.write(catalog_content)
    with open(catalog2_path, "w", encoding="utf-8") as f:
        f.write(catalog_content)
        
    print(f"Catalogs written: {catalog_path} & {catalog2_path}")
    print("\n✅ Classification & distribution completed successfully!")

if __name__ == "__main__":
    main()
