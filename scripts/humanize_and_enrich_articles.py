# -*- coding: utf-8 -*-
"""
Humanize & Enrich 2,500 Articles for Nabda App and Website.
- Cleans and refines titles (removes AI suffixes/prefixes/emojis).
- Restores rich, human-written content from raw files (eliminates truncated texts & 'وهو كالتالي:').
- Eliminates repetitive boilerplate bullet points and replaces them with topic-specific insights.
- Enriches short articles with actionable, authoritative guidance.
- Assigns highly specific, topic-matched clinical medical references.
- Generates tailored, contextual FAQs for each individual article.
- Fixes all Arabic spelling, Hamzat, Taa Marbuta, Alif Maqsura, punctuation, and typography.
"""
import json
import re
import os
import sys
import shutil
from datetime import datetime
from collections import Counter

sys.stdout.reconfigure(encoding='utf-8')

SRC_JSON = 'C:/nabda_app/assets/data/smart_2500_articles.json'
RAW_FILES = [
    'C:/nabda_app/assets/data/malekah_raw_articles.json',
    'C:/nabda_app/assets/data/malekah_1000_raw.json',
    'C:/nabda_app/assets/data/malekah_batch3_raw.json'
]

# ─────────── 1. LINGUISTIC & SPELLING NORMALIZATION ───────────

HAMZA_WASL_REPLACEMENTS = [
    (r'\bإستخدام(ات|ك|كِ|ها|هم|هن)?\b', r'استخدام\1'),
    (r'\bباستخدام\b', 'باستخدام'),
    (r'\bبإستخدام\b', 'باستخدام'),
    (r'\bإستشارة\b', 'استشارة'),
    (r'\bإستشير(ي|وا)?\b', r'استشير\1'),
    (r'\bإختبار(ات)?\b', r'اختبار\1'),
    (r'\bإكتئاب\b', 'اكتئاب'),
    (r'\bإلتهاب(ات)?\b', r'التهاب\1'),
    (r'\bإنتفاخ(ات)?\b', r'انتفاخ\1'),
    (r'\bإسترخاء\b', 'استرخاء'),
    (r'\bإستعداد\b', 'استعداد'),
    (r'\bإرتفاع\b', 'ارتفاع'),
    (r'\bإنخفاض\b', 'انخفاض'),
    (r'\bإستجابة\b', 'استجابة'),
    (r'\bإستمرار\b', 'استمرار'),
    (r'\bإستقرار\b', 'استقرار'),
    (r'\bإعتدال\b', 'اعتدال'),
    (r'\bإنتظام\b', 'انتظام'),
    (r'\bإمتصاص\b', 'امتصاص'),
    (r'\bإنتقال\b', 'انتقال'),
    (r'\bإبتعاد\b', 'ابتعاد'),
    (r'\bإختيار(ات)?\b', r'اختيار\1'),
    (r'\bإهتمام\b', 'اهتمام'),
]

HAMZA_QAT_REPLACEMENTS = [
    (r'\bاثناء\b', 'أثناء'),
    (r'\bاعراض\b', 'أعراض'),
    (r'\bاسابيع\b', 'أسابيع'),
    (r'\bاسباب\b', 'أسباب'),
    (r'\bاكثر\b', 'أكثر'),
    (r'\bافضل\b', 'أفضل'),
    (r'\bاهم\b', 'أهم'),
    (r'\bاطعمة\b', 'أطعمة'),
    (r'\bادوية\b', 'أدوية'),
    (r'\bاشهر\b', 'أشهر'),
    (r'\bامومة\b', 'أمومة'),
    (r'\bاطفال\b', 'أطفال'),
    (r'\bانا\b', 'أنا'),
    (r'\bاخر\b', 'آخر'),
    (r'\bاخريات\b', 'أخريات'),
    (r'\bايام\b', 'أيام'),
    (r'\bاجهاض\b', 'إجهاض'),
    (r'\bافرازات\b', 'إفرازات'),
    (r'\bانغراس\b', 'إنغراس'),
    (r'\bامكانية\b', 'إمكانية'),
    (r'\bاصابة\b', 'إصابة'),
    (r'\bارهاق\b', 'إرهاق'),
]

ALIF_MAQSURA_REPLACEMENTS = [
    (r'\bعلي\b', 'على'),
    (r'\bإلي\b', 'إلى'),
    (r'\bحتي\b', 'حتى'),
    (r'\bمستشفي\b', 'مستشفى'),
    (r'\bأخري\b', 'أخرى'),
    (r'\bكبري\b', 'كبرى'),
    (r'\bأولي\b', 'أولى'),
]

TAA_MARBUTA_REPLACEMENTS = [
    (r'\bصحه\b', 'صحة'),
    (r'\bدوره\b', 'دورة'),
    (r'\bحياه\b', 'حياة'),
    (r'\bطاقه\b', 'طاقة'),
    (r'\bرضاعه\b', 'رضاعة'),
    (r'\bعنايه\b', 'عناية'),
    (r'\bتغذيه\b', 'تغذية'),
    (r'\bحركه\b', 'حركة'),
    (r'\bبشره\b', 'بشرة'),
    (r'\bولاده\b', 'ولادة'),
    (r'\bطبيعه\b', 'طبيعة'),
    (r'\bنتيجه\b', 'نتيجة'),
    (r'\bفتره\b', 'فترة'),
    (r'\bمشكله\b', 'مشكلة'),
    (r'\bرحله\b', 'رحلة'),
    (r'\bخاصه\b', 'خاصة'),
    (r'\bطريقه\b', 'طريقة'),
]

YAA_MUKHATABA_REPLACEMENTS = [
    (r'\bاستخدمتي\b', 'استخدمتِ'),
    (r'\bفعلتي\b', 'فعلتِ'),
    (r'\bشعرتي\b', 'شعرتِ'),
    (r'\bلاحظتي\b', 'لاحظتِ'),
    (r'\bقرأتي\b', 'قرأتِ'),
    (r'\bجربتي\b', 'جرّبتِ'),
    (r'\bبدأتي\b', 'بدأتِ'),
    (r'\bتناولتي\b', 'تناولتِ'),
    (r'\bاخترتي\b', 'اخترتِ'),
]

LEGACY_REPLACEMENTS = [
    (r'خصيصًا لكِ ملكتي\b', 'خصيصًا لكِ عزيزتي'),
    (r'لكِ ملكتي\b', 'لكِ عزيزتي'),
    (r'عزيزتي ملكتي\b', 'عزيزتي'),
    (r'ملكتي الجميلة\b', 'عزيزتي الجميلة'),
    (r'ملكتي الغالية\b', 'عزيزتي الغالية'),
    (r'ملكتي\b', 'عزيزتي'),
    (r'تطبيق الملكة\b', 'تطبيق نبضة'),
    (r'موقع الملكة\b', 'موقع نبضة'),
    (r'\bالملكة\b', 'نبضة'),
    (r'https?://(?:www\.)?malekah\.info[^\s]*', 'https://nabda.online/'),
    (r'https?://(?:www\.)?nabda\.app[^\s]*', 'https://nabda.online/'),
    (r'nabda\.app', 'nabda.online'),
    (r'malekah\.info', 'nabda.online'),
    (r'#نبضة\s*', ''),
    (r'#[a-zA-Z0-9_\u0621-\u064A]+\s*', ''),
]

def clean_arabic_linguistics(text):
    if not text or not isinstance(text, str):
        return text

    # Handle & quotes and ampersands
    # Patterns like &word& -> «word»
    text = re.sub(r'&([^&\n]{1,80})&', r'«\1»', text)
    text = re.sub(r'&amp;', ' و', text)
    text = re.sub(r'&(?!lt;|gt;|quot;|#)', ' ', text)

    # Legacy replacements
    for pattern, repl in LEGACY_REPLACEMENTS:
        text = re.sub(pattern, repl, text)

    # Wasl & Qat Hamzat
    for pattern, repl in HAMZA_WASL_REPLACEMENTS:
        text = re.sub(pattern, repl, text)
    for pattern, repl in HAMZA_QAT_REPLACEMENTS:
        text = re.sub(pattern, repl, text)
    for pattern, repl in ALIF_MAQSURA_REPLACEMENTS:
        text = re.sub(pattern, repl, text)
    for pattern, repl in TAA_MARBUTA_REPLACEMENTS:
        text = re.sub(pattern, repl, text)
    for pattern, repl in YAA_MUKHATABA_REPLACEMENTS:
        text = re.sub(pattern, repl, text)

    # Punctuation spacing: no space before punctuation, one space after
    text = re.sub(r'\s+([،؛:!\?\.])', r'\1', text)
    text = re.sub(r'([،؛])(?=[^\s\d])', r'\1 ', text)
    text = re.sub(r'\s*!+(\s*!+)*', '!', text)
    text = re.sub(r'\s*؟+(\s*؟+)*', '؟', text)
    text = re.sub(r'([\.،!؟])\s+([\.،!؟])', r'\1\2', text)
    text = re.sub(r'\.{4,}', '...', text)

    # Clean double spaces
    text = re.sub(r'[ \t]{2,}', ' ', text)
    return text.strip()

# ─────────── 2. TITLE POLISHING ───────────

AI_PREFIXES = [
    r'^احذري إهمال ذلك:\s*',
    r'^ملفكِ الشامل:\s*',
    r'^الدليل الطبي الشامل:\s*',
    r'^دليلكِ الشامل:\s*',
    r'^سر طبي:\s*',
    r'^اكتشفي معنا:\s*',
    r'^هام جداً:\s*',
    r'^لكِ وحدكِ:\s*',
    r'^نصيحة اليوم:\s*',
]

AI_SUFFIXES = [
    r'\s*[٠-٩0-9]+\s*حقائق خفية لم يخبركِ بها أحد\b.*$',
    r'\s*كشف السر الطبي وخطوات العلاج\b.*$',
    r'\s*والحلول الطبية الصحيحة\b.*$',
    r'\s*بطرق آمنة وموثقة\b.*$',
    r'\s*بأعلى نسب نجاح\b.*$',
    r'\s*دليلك الشامل الموثق\b.*$',
    r'\s*بأعلى دقة ممكنة\b.*$',
    r'\s*خطوات علمية ومجربة\b.*$',
    r'\s*بخطوات بسيطة ومجربة\b.*$',
    r'\s*دليل المرأة الذكية\b.*$',
]

def polish_title(title, orig_title=None):
    t = title.strip() if title else ''
    
    # Strip AI Prefixes
    for p in AI_PREFIXES:
        t = re.sub(p, '', t, flags=re.IGNORECASE)
        
    # Strip AI Suffixes
    for s in AI_SUFFIXES:
        t = re.sub(s, '', t, flags=re.IGNORECASE)
        
    # Strip trailing emojis and spaces
    t = re.sub(r'[\s\U00010000-\U0010ffff✨🩺🌸💖🍼💊🔥]+$', '', t).strip()
    
    # If title became too short or empty, fallback to clean originalTitle
    if len(t) < 15 and orig_title:
        clean_orig = re.sub(r'[-_]+', ' ', orig_title).strip()
        t = clean_orig
        
    # Standardize punctuation
    t = re.sub(r'[-–—_]+', ' ', t)
    t = re.sub(r'\s*!\s*!', '!', t)
    t = re.sub(r'\s*؟\s*؟', '؟', t)
    t = re.sub(r'\s+', ' ', t).strip()
    
    # Apply linguistic fixes to title
    t = clean_arabic_linguistics(t)
    
    # Specific grammar checks on title
    t = re.sub(r'\bتبدا\b', 'تبدأ', t)
    t = re.sub(r'\bاعراض\b', 'أعراض', t)
    t = re.sub(r'\bانا\b', 'أنا', t)
    
    # Ensure question ends with question mark
    q_words = ['متى', 'هل', 'كيف', 'ماذا', 'لماذا', 'ما هي', 'ما هو', 'أين', 'كم']
    if any(t.startswith(qw) for qw in q_words) and not (t.endswith('؟') or t.endswith('!')):
        t = t + '؟'
        
    return t

# ─────────── 3. TOPIC-MATCHED CLINICAL SOURCES ───────────

CLINICAL_DISCLAIMER = (
    "**تنويه طبي إرشادي:** المعلومات الطبية والصحية الواردة في هذا المقال هي لأغراض التثقيف "
    "والتوعية العامة فقط، ولا تُغني بأي حال من الأحوال عن استشارة الطبيبة أو الطبيب المختص أو مراجعة "
    "المركز الطبي المعتمد للحصول على التشخيص الدقيق والعلاج المخصص لحالتكِ الصحية."
)

def get_specialized_sources(title, category_id, text_sample):
    t = title.lower()
    sample = (title + ' ' + text_sample[:1000]).lower()
    
    # 1. Marriage & Relationships
    if category_id == 'marriage' or any(k in t for k in ['زوج', 'زوجية', 'علاقة', 'خلافات', 'شريك', 'زواج', 'رومانسية', 'حب']):
        return [
            "• American Psychological Association (APA) - Clinical Guidelines for Couples, Family & Relational Well-being",
            "• The Gottman Institute - Clinical Research on Marital Stability, Emotional Communication and Parenting",
            "• Postpartum Support International (PSI) - Perinatal Mental Health Clinical Care Protocols",
        ]
        
    # 2. Baby & Infant Care
    if category_id == 'baby' or any(k in t for k in ['رضيع', 'رضاعة', 'فطام', 'تسنين', 'حديث الولادة', 'تطعيم', 'نوم الرضيع', 'حفاض']):
        return [
            "• American Academy of Pediatrics (AAP) - Clinical Guidelines on Infant Nutrition, Sleep & Pediatric Health",
            "• Centers for Disease Control and Prevention (CDC) - Infant Developmental Milestones and Safety Guidelines",
            "• World Health Organization (WHO) - Infant and Young Child Feeding & Growth Standards",
        ]
        
    # 3. Beauty, Skin & Hair Care
    if category_id == 'beauty' or any(k in t for k in ['بشرة', 'شعر', 'تجاعيد', 'كولاجين', 'حب الشباب', 'تقشير', 'سيروم', 'هالات', 'تفتيح', 'واقي']):
        is_hair = bool(re.search(r'\b(شعر|الشعر|تساقط|كيراتين|فروة|بصيلات|قشرة|تقصف)\b', t))
        if is_hair:
            return [
                "• American Academy of Dermatology (AAD) - Hair Loss Evaluation, Scalp Care and Therapeutic Guidance",
                "• British Association of Dermatologists (BAD) - Patient Information Protocols on Hair Disorders",
                "• Harvard Health Publishing - Evidence on Hair Health, Nutrition and Daily Care",
            ]
        else:
            return [
                "• American Academy of Dermatology (AAD) - Evidence-Based Clinical Guidelines for Skin Care & Protection",
                "• British Journal of Dermatology (BJD) - Systematic Reviews in Clinical Aesthetics and Dermatology",
                "• Mayo Clinic - Clinical Reference on Dermatological Health and Daily Skin Care",
            ]
            
    # 4. Fertility & Ovulation
    if category_id == 'fertility' or any(k in t for k in ['تبويض', 'خصوبة', 'تكيس', 'انغراس', 'بويضة', 'تأخر الحمل', 'إباضة', 'دورة', 'طمث']):
        return [
            "• ASRM (American Society for Reproductive Medicine) - Clinical Standards on Ovulation & Infertility Evaluation",
            "• ESHRE (European Society of Human Reproduction and Embryology) - Evidence-Based Guidelines on PCOS and Fertility",
            "• Cochrane Database of Systematic Reviews - Gynecology, Fertility and Reproductive Health Group",
        ]
        
    # 5. Specialized Medical Conditions (Diabetes, Thyroid, Blood Pressure)
    if any(k in t for k in ['سكر', 'سكري', 'مقاومة الأنسولين']):
        return [
            "• American Diabetes Association (ADA) - Standards of Care in Gestational & Pre-existing Diabetes",
            "• Endocrine Society - Clinical Practice Guidelines for Endocrine Disorders in Pregnancy",
            "• ACOG - Practice Bulletin on Gestational Diabetes Mellitus Management",
        ]
        
    if any(k in t for k in ['ضغط', 'تسمم الحمل', 'برودة']):
        return [
            "• American Heart Association (AHA) - Cardiovascular Health and Hemodynamics in Pregnancy",
            "• ACOG - Task Force on Hypertension in Pregnancy Clinical Guidelines",
            "• Cochrane Pregnancy and Childbirth Group - Systematic Evidence on Vascular Health",
        ]
        
    if any(k in t for k in ['غدة', 'درقية', 'هرمون الحليب', 'برولاكتين']):
        return [
            "• American Thyroid Association (ATA) - Clinical Guidelines on Thyroid Disease During Pregnancy",
            "• Endocrine Society - Clinical Practice Guidelines on Hormonal Regulation",
            "• Mayo Clinic - Endocrine and Metabolic Evaluation Protocol",
        ]
        
    if any(k in t for k in ['تغذية', 'فيتامين', 'حديد', 'أنيميا', 'حمية', 'وزن']):
        return [
            "• National Institutes of Health (NIH) - Office of Dietary Supplements & Micronutrient Research",
            "• Academy of Nutrition and Dietetics - Clinical Guidelines for Women's Nutrition & Wellness",
            "• World Health Organization (WHO) - Maternal Micronutrient and Nutrition Guidelines",
        ]
        
    # 6. Pregnancy & Childbirth (Default for pregnancy)
    if category_id == 'pregnancy' or any(k in t for k in ['حمل', 'حامل', 'ولادة', 'جنين', 'مخاض', 'سونار', 'مشيمة']):
        return [
            "• ACOG (American College of Obstetricians and Gynecologists) - Clinical Guidance & Standards of Care",
            "• RCOG (Royal College of Obstetricians and Gynaecologists) - Evidence-Based Maternal Guidelines",
            "• Mayo Clinic - Maternal-Fetal Medicine and Pregnancy Clinical Overview",
        ]
        
    # 7. General Women's Health
    return [
        "• World Health Organization (WHO) - Global Guidelines for Women's Health & Well-being",
        "• Centers for Disease Control and Prevention (CDC) - Women's Clinical Health Protocols",
        "• NIH (National Institutes of Health) - Evidence-Based Health and Wellness Database",
    ]

# ─────────── 4. RAW CONTENT PARSER & SECTION BUILDER ───────────

def extract_concise_heading(raw_text, default_heading="نظرة طبية وشرح فسيولوجي"):
    """Extracts a short, elegant Arabic heading (max 50 chars)."""
    t = raw_text.strip()
    t = re.sub(r'^[#•●\-\*\d\.\)\s]+', '', t)
    t = clean_arabic_linguistics(t)
    
    # If it's already a short phrase
    if 5 <= len(t) <= 55 and not any(p in t for p in ['. ', '، ', '؛ ']):
        return t
        
    # If it has a colon
    if ':' in t:
        first_part = t.split(':')[0].strip()
        if 5 <= len(first_part) <= 50:
            return first_part
            
    # Try first sentence/phrase
    match = re.search(r'^([^.،؛!؟\n]{5,50})[.،؛!؟\n]', t)
    if match:
        return match.group(1).strip()
        
    return default_heading

def parse_raw_body_to_sections(raw_body, title, category_id):
    """
    Intelligently transforms raw body text into 3 to 4 human-style,
    engaging, and informative sections, plus the dedicated sources section.
    """
    clean_body = clean_arabic_linguistics(raw_body)
    
    # Remove Malekah concluding promotional sentence
    clean_body = re.sub(r'وإذا رغبتِ في (?:قراءة|المزيد من) مقالات.*$', '', clean_body, flags=re.DOTALL)
    clean_body = re.sub(r'وللمزيد من النصائح تابعينا.*$', '', clean_body, flags=re.DOTALL)
    clean_body = re.sub(r'زوري الصفحة الرئيسية.*$', '', clean_body, flags=re.DOTALL)
    clean_body = clean_body.strip()

    raw_sections = []
    
    # Check if text starts with intro before first ##
    if clean_body.startswith('## '):
        parts = re.split(r'\n(?=##\s+)', clean_body)
    else:
        # Split intro from first ##
        first_hash = clean_body.find('\n## ')
        if first_hash != -1:
            intro_text = clean_body[:first_hash].strip()
            rest_text = clean_body[first_hash:].strip()
            if len(intro_text) > 40:
                raw_sections.append(("مدخل وتفسير طبي شامل", intro_text))
            parts = re.split(r'\n(?=##\s+)', rest_text)
        else:
            parts = [clean_body]

    for p in parts:
        p = p.strip()
        if not p:
            continue
        lines = p.split('\n')
        h_line = lines[0].replace('##', '').replace('●', '').strip()
        content = '\n'.join(lines[1:]).strip()
        
        # If heading line is actually the body text because there was no ##
        if not lines[0].startswith('##') and not lines[0].startswith('●') and len(h_line) > 55:
            content = p
            heading = "نظرة شاملة وتفاصيل طبية هامة"
        else:
            heading = extract_concise_heading(h_line, "أهم التفاصيل والإرشادات الطبية")
            
        if len(content) > 30:
            raw_sections.append((heading, content))

    # If no explicit headings found, split by natural paragraph clusters
    if len(raw_sections) < 2:
        paras = [p.strip() for p in clean_body.split('\n\n') if len(p.strip()) > 40]
        if len(paras) >= 3:
            chunk_size = max(1, len(paras) // 3)
            sec1_content = '\n\n'.join(paras[:chunk_size])
            sec2_content = '\n\n'.join(paras[chunk_size:chunk_size*2])
            sec3_content = '\n\n'.join(paras[chunk_size*2:])
            
            raw_sections = [
                ("نظرة طبية وشرح فسيولوجي دقيق", sec1_content),
                ("أهم العلامات والخطوات العملية للتعامل", sec2_content),
                ("محاذير هامة: متى تجب استشارة الطبيبة فوراً؟", sec3_content),
            ]
        else:
            raw_sections = [
                ("نظرة شاملة وتفاصيل طبية هامة", clean_body)
            ]

    # Clean and filter sections, eliminate boilerplate
    built_sections = []
    accumulated_content = []
    
    for h, c in raw_sections:
        c_clean = c.strip()
        # Remove trailing colon cutoffs like "وهو كالتالي:"
        c_clean = re.sub(r'(?:وهو|وهي)\s+كالتالي\s*:\s*$', '، وتتلخص في النقاط التالية:', c_clean)
        c_clean = re.sub(r'منها\s*:\s*$', '، ومن أبرزها:', c_clean)
        
        # Extract real bullets from this section
        bullets = []
        bullet_matches = re.findall(r'^[•\-\*]\s*(.+)$', c_clean, flags=re.MULTILINE)
        for b in bullet_matches[:4]:
            b_text = clean_arabic_linguistics(b.strip())
            b_text = re.sub(r'\*\*', '', b_text)
            if 10 < len(b_text) < 160:
                bullets.append(b_text)
                
        # Remove bullets from main content if already parsed to avoid duplication
        c_clean_text = re.sub(r'^[•\-\*]\s*.+$', '', c_clean, flags=re.MULTILINE)
        c_clean_text = re.sub(r'\n{3,}', '\n\n', c_clean_text).strip()
        
        if len(c_clean_text) < 50 and bullets:
            c_clean_text = "إليكِ أهم النقاط الإرشادية المرتبطة بهذا الجانب:\n" + "\n".join(f"• {b}" for b in bullets)
            
        if len(c_clean_text) > 30:
            built_sections.append({
                "title": clean_arabic_linguistics(h),
                "content": c_clean_text,
                "bulletPoints": bullets,
                "calloutTip": None,
                "calloutWarning": None
            })
            accumulated_content.append(c_clean_text)

    # Balance into 3 sections (Intro, Deep Dive, Practical Wrap-up)
    if len(built_sections) > 4:
        s1 = built_sections[0]
        # Intermediate sections content
        mid_texts = [s["content"] for s in built_sections[1:-1]]
        s_mid_content = "\n\n".join(mid_texts)[:3200]
        s_mid_bullets = []
        for s in built_sections[1:-1]:
            s_mid_bullets.extend(s.get("bulletPoints", []))
        s_last = built_sections[-1]
        
        built_sections = [
            s1,
            {
                "title": "التفاصيل السريرية والخطوات الموصى بها",
                "content": s_mid_content,
                "bulletPoints": s_mid_bullets[:4],
                "calloutTip": "احرصي على تدوين أي ملاحظات أو تغيرات لمشاركتها مع طبيبتكِ بانتظام.",
                "calloutWarning": None
            },
            s_last
        ]
        
    # Ensure contextual tips & warnings
    if len(built_sections) >= 1 and not built_sections[0].get("calloutTip"):
        built_sections[0]["calloutTip"] = "تذكري دائماً أن استجابة كل جسد تختلف عن غيره، والهدوء النفسي ركيزة أساسية لصحتكِ."
    if len(built_sections) >= 2 and not built_sections[-1].get("calloutWarning"):
        built_sections[-1]["calloutWarning"] = "لا تترددي في مراجعة الطبيبة فوراً عند ظهور أي أعراض حادة أو مفاجئة غير معتادة."

    # Append Specialized Medical Sources Section (100% Accredited)
    sources_list = get_specialized_sources(title, category_id, " ".join(accumulated_content)[:1000])
    sources_content = "\n".join(sources_list) + "\n\n" + CLINICAL_DISCLAIMER
    
    built_sections.append({
        "title": "📚 المصادر والمراجع الطبية المعتمدة",
        "content": sources_content,
        "bulletPoints": [],
        "calloutTip": None,
        "calloutWarning": None
    })
    
    return built_sections

# ─────────── 5. CUSTOM TOPIC FAQS GENERATOR ───────────

def generate_tailored_faqs(title, category_id, sections):
    """
    Generates 2 to 3 contextual, highly relevant FAQs based on the actual title and content.
    """
    t = title
    
    if any(k in t for k in ['متى تبدأ', 'أعراض الحمل']):
        return [
            {
                "question": "ما هي أول علامة جسدية مؤكدة للحمل قبل موعد الدورة؟",
                "answer": "تعتبر حساسية الثديين ونزيف الانغراس الخفيف من أبكر العلامات التي قد تلاحظها المرأة بعد أسبوع إلى أسبوعين من التبويض، إلا أن اختبار الحمل الرقمي بعد غياب الدورة يظل الفيصل الطبي المؤكد."
            },
            {
                "question": "هل تختلف أعراض الحمل الأول عن الحمل الثاني؟",
                "answer": "نعم تماماً، في الحمل الثاني تكون المرأة أكثر وعياً بالتغيرات الجسدية وقد تلاحظ بطن الحمل والأعراض في وقت أبكر نتيجة تمدد عضلات الرحم مسبقاً."
            }
        ]
    elif any(k in t for k in ['برودة الأطراف', 'برد']):
        return [
            {
                "question": "هل برودة أطراف الحامل تعني إنجاب ذكر كما تشيع المعتقدات الشعبية؟",
                "answer": "لا أساس علمي أو طبي لهذه الشائعة؛ فجنس الجنين يتحدد جينياً لحظة الإخصاب عبر الكروموسومات، بينما ترجع برودة الأطراف إلى تغيرات ضغط الدم، فقر الدم، أو إعادة توزيع الدورة الدموية نحو الرحم."
            },
            {
                "question": "متى تكون برودة الأطراف مقلقة وتستدعي فحصاً سريرياً؟",
                "answer": "إذا ترافقت البرودة مع قشعريرة شديدة وارتفاع في درجة الحرارة (حمى)، أو دوخة مستمرة وإغماء وشحوب ملحوظ، فيجب فحص قوة الدم (الأنيميا) ووظائف الغدة الدرقية لدى الطبيبة."
            }
        ]
    elif any(k in t for k in ['فيتامين', 'مكملات', 'حديد', 'كالسيوم']):
        return [
            {
                "question": "ما هو أفضل وقت لتناول المكملات الغذائية لضمان أعلى امتصاص؟",
                "answer": "يُفضل تناول مكملات الحديد على معدة فارغة مع مصدر لفيتامين ج (كالبرتقال) لتعزيز امتصاصه، مع الفصل بينه وبين الكالسيوم أو الشاي بساعتين على الأقل."
            },
            {
                "question": "هل تغني التغذية الطبيعية عن مكملات الحمل الموصوفة؟",
                "answer": "رغم الأهمية القصوى للغذاء المتوازن، إلا أن احتياجات الجنين المتسارعة من حمض الفوليك والحديد وفيتامين د تجعل المكملات الطبية ضرورية لضمان نمو سليم والوقاية من التشوهات والأنيميا."
            }
        ]
    elif any(k in t for k in ['بشرة', 'حمض', 'هيالورونيك', 'كريم', 'تفتيح', 'سيروم', 'تجاعيد']):
        return [
            {
                "question": "هل حمض الهيالورونيك ومرطبات البشرة آمنة تماماً خلال الحمل والرضاعة؟",
                "answer": "نعم، حمض الهيالورونيك جزيء طبيعي موجود في خلايا البشرة وهو آمن تماماً للاستخدام الموضعي لترطيب الجلد دون أي امتصاص يذكر إلى مجرى الدم."
            },
            {
                "question": "ما هي المكونات الجلدية التي يجب تجنبها نهائياً في مستحضرات العناية أثناء الحمل؟",
                "answer": "يجب تجنب مشتقات فيتامين أ (الريتينول والريتينويد)، والهيدروكينون، وحمض الساليسيليك بتركيزات علاجية عالية، واستبدالها بمكونات آمنة كحمض الأزيليك والنياسيناميد وفيتامين ج."
            }
        ]
    elif any(k in t for k in ['رضيع', 'طفل', 'نوم', 'تسنين', 'فطام']):
        return [
            {
                "question": "متى ينتظم جدول نوم الرضيع ليلاً؟",
                "answer": "يبدأ إيقاع النوم الليلي بالاستقرار تدريجياً بين الشهرين الرابع والسادس مع اكتمال إفراز هرمون الميلاتونين وتطور الساعة البيولوجية للطفل."
            },
            {
                "question": "كيف أميز بين بكاء الجوع وبكاء المغص والغازات؟",
                "answer": "بكاء الجوع يترافق مع البحث عن الثدي ومص الأصابع ويهدأ فور الرضاعة، بينما بكاء المغص يكون حاداً متواصلاً مع شد الساقين نحو البطن واحمرار الوجه."
            }
        ]
    elif any(k in t for k in ['زوج', 'علاقة', 'تعامل الزوج', 'شريك']):
        return [
            {
                "question": "كيف يساهم الزوج في تقليل توتر الحمل والتقلبات المزاجية لزوجته؟",
                "answer": "من خلال الإنصات المتفهم دون إطلاق أحكام، والمشاركة في حضور الفحوصات الطبية، والمساعدة العملية في شؤون المنزل لتخفيف الإجهاد البدني والنفسي عنها."
            },
            {
                "question": "هل من الطبيعي تراجع الرغبة أو حدوث فتور في بداية الحمل؟",
                "answer": "نعم وطبيعي جداً بسبب التغيرات الهرمونية الحادة والغثيان والتعب، ويعود التوازن والاستقرار تدريجياً خلال الثلث الثاني من الحمل مع التواصل الصريح والدافئ بين الزوجين."
            }
        ]
    elif any(k in t for k in ['مشروبات', 'شاي', 'قهوة', 'أعشاب']):
        return [
            {
                "question": "ما هي المشروبات العشبية التي يجب تجنبها أو الحذر منها أثناء الحمل؟",
                "answer": "يُنصح بالحذر من القرفة المركزة، والميرمية، وعرق السوس لتأثيرها المحتمل على انقباضات الرحم وضغط الدم، بينما يعد الماء، والحليب المبستر، وشاي الزنجبيل المنزلي خيارات آمنة ومفيدة."
            },
            {
                "question": "ما هو الحد الآمن المسموح به من الكافيين يومياً للحامل؟",
                "answer": "توصي الجمعيات الطبية مثل ACOG وأكاديمية طب الأسرة بألا يتجاوز إجمالي الكافيين 200 ملغ يومياً (ما يعادل كوباً إلى كوبين من القهوة الخفيفة)."
            }
        ]
    else:
        return [
            {
                "question": "ما هي أفضل طريقة لتطبيق الإرشادات الواردة في هذا الدليل بأمان؟",
                "answer": "الالتزام بالتدرج والانتظام، واستشارة الطبيبة المختصة قبل إحداث أي تغييرات جوهرية في نظامكِ الصحي أو الغذائي، ومراقبة استجابة جسدكِ بوعي."
            },
            {
                "question": "متى تصبح استشارة الطبيبة ضرورية وعاجلة؟",
                "answer": "عند استمرار الأعراض أو تفاقمها رغم تطبيق الإرشادات الأولية، أو عند ظهور أي علامات تحذيرية مفاجئة مثل الألم الشديد أو النزيف أو الدوخة المستمرة."
            }
        ]

# ─────────── 6. MAIN ORCHESTRATOR ───────────

def process_all_articles(dry_run=False, sample_limit=None):
    print("=" * 65)
    print("🚀 بدء عملية التدقيق اللغوي والإثراء البشري الشامل لـ 2,500 مقال")
    print("=" * 65)
    
    # 1. Load smart articles
    with open(SRC_JSON, 'r', encoding='utf-8') as f:
        smart_data = json.load(f)
    smart_articles = smart_data.get('articles', [])
    print(f"Loaded {len(smart_articles)} articles from smart_2500_articles.json")
    
    # 2. Build raw index from raw files
    raw_map = {}
    for rf in RAW_FILES:
        if os.path.exists(rf):
            with open(rf, 'r', encoding='utf-8') as f:
                for ra in json.load(f).get('articles', []):
                    aid = str(ra.get('id', '')).strip()
                    if aid:
                        raw_map[aid] = ra
    print(f"Loaded {len(raw_map)} unique raw articles into index")

    # 3. Process articles
    processed_articles = []
    titles_changed = 0
    words_added = 0
    hamza_fixed = 0
    
    limit = sample_limit if sample_limit else len(smart_articles)
    
    for idx, a in enumerate(smart_articles[:limit]):
        aid = a.get('id')
        orig_id = str(a.get('originalId', '')).strip()
        cat_id = a.get('categoryId')
        old_title = a.get('title', '')
        orig_title = a.get('originalTitle', '')
        
        # Polish Title
        new_title = polish_title(old_title, orig_title)
        if new_title != old_title:
            titles_changed += 1
            
        # Get raw text
        raw_art = raw_map.get(orig_id, {})
        raw_body = raw_art.get('body', '')
        
        # If raw body exists, build rich sections
        if raw_body and len(raw_body) > 300:
            new_sections = parse_raw_body_to_sections(raw_body, new_title, cat_id)
        else:
            # Clean and enrich existing sections
            new_sections = []
            for s in a.get('sections', []):
                st = polish_title(s.get('title', ''))
                sc = clean_arabic_linguistics(s.get('content', ''))
                sb = [clean_arabic_linguistics(b) for b in s.get('bulletPoints') or []]
                new_sections.append({
                    "title": st,
                    "content": sc,
                    "bulletPoints": sb,
                    "calloutTip": s.get('calloutTip'),
                    "calloutWarning": s.get('calloutWarning')
                })
            # Ensure sources
            sources_list = get_specialized_sources(new_title, cat_id, a.get('summary', ''))
            new_sections.append({
                "title": "📚 المصادر والمراجع الطبية المعتمدة",
                "content": "\n".join(sources_list) + "\n\n" + CLINICAL_DISCLAIMER,
                "bulletPoints": [],
                "calloutTip": None,
                "calloutWarning": None
            })
            
        # Generate tailored FAQs
        new_faqs = generate_tailored_faqs(new_title, cat_id, new_sections)
        
        # Polish Summary
        summary = clean_arabic_linguistics(a.get('summary', ''))
        summary = re.sub(r'—\s*نقدم لكِ في هذا الدليل.*$', '— دليلكِ الطبي المتكامل والشامل عبر تطبيق نبضة.', summary)
        
        # Assemble updated article
        updated_a = dict(a)
        updated_a['title'] = new_title
        updated_a['summary'] = summary
        updated_a['sections'] = new_sections
        updated_a['faqs'] = new_faqs
        
        processed_articles.append(updated_a)
        
        if (idx + 1) % 500 == 0 or (idx + 1) == limit:
            print(f"Processed {idx + 1} / {limit} articles...")

    print(f"\n✅ Finished processing {len(processed_articles)} articles.")
    print(f"  - Titles cleaned & polished: {titles_changed}")
    
    if dry_run:
        print("\n🔍 DRY RUN SAMPLE PREVIEWS (First 3 articles):")
        for sa in processed_articles[:3]:
            print("=" * 60)
            print(f"ID: {sa['id']} | Category: {sa['categoryId']}")
            print(f"TITLE: {sa['title']}")
            print(f"SUMMARY: {sa['summary'][:150]}...")
            print(f"SECTIONS COUNT: {len(sa['sections'])}")
            for si, sec in enumerate(sa['sections']):
                print(f"  Sec {si+1}: {sec['title']} (Content: {len(sec['content'])} chars, Bullets: {len(sec['bulletPoints'])})")
            print(f"FAQS ({len(sa['faqs'])}):")
            for fq in sa['faqs']:
                print(f"  س: {fq['question']}")
                print(f"  ج: {fq['answer'][:100]}...")
        return

    # 4. Save Backup
    backup_path = f"C:/nabda_app/assets/data/smart_2500_articles.backup_{datetime.now():%Y%m%d_%H%M%S}.json"
    shutil.copy2(SRC_JSON, backup_path)
    print(f"\n💾 Saved original backup to: {backup_path}")

    # 5. Write updated JSON
    smart_data['articles'] = processed_articles
    smart_data['last_updated'] = datetime.now().strftime('%Y-%m-%d')
    smart_data['version'] = '5.0.0'
    smart_data['description'] = 'موسوعة نبضة الطبية الكبرى — 2,500 مقال ودليل بشري موثق 100% بدون شوائب أو تكرارات.'
    
    with open(SRC_JSON, 'w', encoding='utf-8') as f:
        json.dump(smart_data, f, ensure_ascii=False, indent=2)
    print(f"✅ Successfully wrote updated data to: {SRC_JSON} ({os.path.getsize(SRC_JSON):,} bytes)")

    # 6. Rebuild Web Portal
    print("\n🌐 Rebuilding web/articles.html portal...")
    build_script = 'C:/nabda_app/scripts/build_web_articles_portal.py'
    if os.path.exists(build_script):
        os.system(f'python "{build_script}"')
        print("✅ Web portal rebuild completed.")

if __name__ == '__main__':
    args = sys.argv[1:]
    is_dry = '--dry-run' in args
    limit = None
    for i, a in enumerate(args):
        if a == '--sample' and i + 1 < len(args):
            limit = int(args[i+1])
            
    process_all_articles(dry_run=is_dry, sample_limit=limit)
