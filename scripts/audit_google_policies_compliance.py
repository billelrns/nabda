# -*- coding: utf-8 -*-
"""
Comprehensive Google Play Developer Policy Compliance Auditor for Nabda App Corpus.
Scans all 6,975+ articles for:
1. Health Misinformation & Dangerous Medical Claims
2. Prescription Drugs & Controlled Substances
3. Sexually Explicit Content vs Clinical Health Education
4. Intellectual Property & Competitor Scraping Artifacts (e.g., Malekah)
5. Deceptive Claims & Medical Clickbait
6. Infant Safety & Dangerous Remedies
7. Content Quality, Broken HTML Entities & Structural Integrity
"""

import os
import sys
import json
import re
from collections import defaultdict, Counter

sys.stdout.reconfigure(encoding='utf-8')

DATA_PATH = r"C:\nabda_app\assets\data\smart_2500_articles.json"
ARCHIVE_PATH = r"C:\nabda_app\_archive_data\smart_7200_articles.json"
SCRATCH_DIR = r"C:\Users\AMT mobile\.gemini\antigravity-ide\brain\5526a025-1f11-42ae-b9ac-7751c9c69ff3\scratch"
os.makedirs(SCRATCH_DIR, exist_ok=True)

# -------------------------------------------------------------
# REGEX PATTERNS & KEYWORDS FOR GOOGLE PLAY POLICY AUDIT
# -------------------------------------------------------------

# Category 1: Health Misinformation & Extreme Medical Claims
HEALTH_MISINFO_PATTERNS = [
    (r"علاج\s+نهائي\s+لل(سرطان|سكر|سكري|عقم|إيدز|توحد|بهاق|صدفية)", "Claim of definitive cure for chronic/incurable diseases"),
    (r"شفاء\s+تام\s+من\s+(السرطان|السكري|الإيدز|التوحد)", "Claim of absolute cure for serious conditions"),
    (r"يقضي\s+على\s+(السرطان|الأورام|الخلايا السرطانية)\s+نهائياً", "Absolute cancer elimination claim"),
    (r"بديل\s+(الكيماوي|العلاج الكيماوي|الأنسولين)", "Alternative medicine replacing chemotherapy/insulin"),
    (r"(استغنِ|استغناء|الاستغناء)\s+عن\s+(الطبيب|الأدوية|علاج الطبيب)", "Encouraging abandonment of medical doctors/prescriptions"),
    (r"دون\s+(الحاجة\s+إلى|مراجعة)\s+الطبيب", "Bypassing professional medical consultation"),
    (r"خلطة\s+سحرية\s+ت(عالج|شفي|قضي)", "Miracle concoction claims"),
    (r"علاج\s+معجزة", "Miracle treatment claim"),
    (r"سر\s+يخفيه\s+(الأطباء|عنك الأطباء)", "Conspiratorial medical claims (Doctors hide from you)"),
]

# Category 2: Dangerous Pregnancy / Abortion Claims
ABORTION_DANGER_PATTERNS = [
    (r"(طرق|خلطات|أعشاب|كيفية)\s+(إسقاط|تسقيط|تنزيل)\s+الجنين", "Dangerous DIY abortion / fetal termination remedies"),
    (r"(إجهاض|تسقيط)\s+(منزلي|بالأعشاب)", "Unsupervised herbal or home abortion instructions"),
    (r"(حبوب|دواء)\s+(إسقاط|تنزيل|إجهاض)\s+الحمل\s+(في البيت|بدون طبيب)", "Unregulated DIY medical abortion advice"),
]

# Category 3: Prescription Drugs & Controlled Substances
CONTROLLED_DRUG_PATTERNS = [
    (r"\b(سيتوتيك|سايتوتك|ميزوبروستول|cytotec|misoprostol)\b", "Restricted abortifacient / ulcer prescription drug"),
    (r"\b(ترامادول|tramadol)\b", "Controlled opioid painkiller"),
    (r"\b(كلوميد|clomid)\b", "Prescription ovulation stimulant (needs supervision check)"),
    (r"\b(ديازيبام|فاليوم|زاناكس|xanax|valium)\b", "Controlled psychotropic / benzodiazepine substance"),
]

# Category 4: Infant & Child Hazards
INFANT_HAZARD_PATTERNS = [
    (r"(إعطاء|إطعام|تناول)\s+الرضيع\s+العسل", "Infant honey feeding (Infant Botulism Risk under 1 year)"),
    (r"عسل\s+للرضع\s+(قبل|دون|أقل من)\s+(عمر\s+)?(سنة|عام)", "Honey for infants under 1 year (contextual check)"),
    (r"نوم\s+الرضيع\s+على\s+بطنه", "Prone infant sleep (Sudden Infant Death Syndrome - SIDS risk)"),
]

# Category 5: Sexual Content Policy (Vulgar / Non-clinical Erotica vs Education)
# Arabic explicit sexual slang/erotic literature tokens (excluding clinical words like جماع, مهبل, قضيب, رحم, تبويض)
SEXUAL_EXPLICIT_PATTERNS = [
    (r"\b(نيك|منيوك|شرموط|قحب|سكس|أفلام إباحية|بورنو|شاذ جنسيا)\b", "Vulgar slang or pornography references"),
    (r"\b(إثارة جنسية محرمة|شهوة جامحة|مداعبة جنسية ساخنة)\b", "Potentially erotic/titillating prose style"),
]

# Category 6: Third-party brand leakage / Scraping footprint
BRAND_LEAK_PATTERNS = [
    (r"\b(الملكة|مجلة الملكة|موقع الملكة|عالم الملكة)\b", "Legacy scraping source brand (الملكة)"),
    (r"malekah\.com", "Scraped source domain in content"),
    (r"supermama\.me|sayidaty\.net|webteb\.com|mawdoo3\.com|altibbi\.com", "Competitor portal links or watermarks"),
]

# Category 7: Clickbait & Extreme Exaggerations
CLICKBAIT_PATTERNS = [
    (r"(فقدان|خسارة)\s+\d+\s+كيلو\s+في\s+(يوم|يومين|3 أيام|أسبوع)", "Extreme unrealistic rapid weight loss"),
    (r"خلال\s+24\s+ساعة\s+فقط\s+ستشفى", "Unrealistic 24-hour cure guarantee"),
]

# Category 8: Data Quality & HTML Entities
HTML_ENTITY_PATTERN = re.compile(r"(&(?:nbsp|amp|quot|lt|gt|#39|#\d+|[a-zA-Z]+);)")
PLACEHOLDER_PATTERN = re.compile(r"\b(undefined|null|NaN|\[object Object\])\b", re.I)


def extract_all_text(article):
    """Concatenates all text fields of an article for scanning."""
    parts = []
    if article.get('title'):
        parts.append(('title', article['title']))
    if article.get('originalTitle'):
        parts.append(('originalTitle', article['originalTitle']))
    if article.get('summary'):
        parts.append(('summary', article['summary']))
    if article.get('description'):
        parts.append(('description', article['description']))
    
    sections = article.get('sections', [])
    for idx, sec in enumerate(sections):
        if isinstance(sec, dict):
            sec_title = sec.get('title', '')
            sec_content = sec.get('content', '')
            bullets = " ".join(sec.get('bulletPoints', []) or [])
            tip = sec.get('calloutTip', '') or ''
            warn = sec.get('calloutWarning', '') or ''
            sec_text = f"{sec_title} {sec_content} {bullets} {tip} {warn}"
            parts.append((f'section_{idx}', sec_text))
            
    faqs = article.get('faqs', [])
    for idx, faq in enumerate(faqs):
        if isinstance(faq, dict):
            q = faq.get('question', '') or ''
            a = faq.get('answer', '') or ''
            parts.append((f'faq_{idx}', f"{q} {a}"))
            
    tags = " ".join(article.get('tags', []) or [])
    if tags:
        parts.append(('tags', tags))
        
    return parts


def audit_corpus(json_path):
    print(f"\n========================================================")
    print(f"LOADING CORPUS: {json_path}")
    print(f"========================================================")
    
    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
        
    articles = data.get('articles', []) if isinstance(data, dict) else data
    total_articles = len(articles)
    print(f"Total articles loaded: {total_articles}")

    results = {
        'total_articles': total_articles,
        'policy_counts': defaultdict(int),
        'flagged_articles': defaultdict(list), # category -> list of {id, title, match, snippet, location}
        'articles_with_any_flag': set(),
        'html_entity_count': 0,
        'placeholder_count': 0,
        'external_links_count': 0,
        'articles_by_category': Counter(),
        'has_warning_callout_count': 0,
        'has_medical_sources_count': 0,
        'word_count_stats': [],
        'empty_sections_articles': [],
    }

    for art_idx, art in enumerate(articles):
        art_id = art.get('id', str(art_idx))
        art_title = art.get('title', 'بدون عنوان')
        category_name = art.get('categoryName', 'غير مصنف')
        subcategory_name = art.get('subcategoryName', 'غير مصنف')
        results['articles_by_category'][category_name] += 1

        text_parts = extract_all_text(art)
        full_text = " ".join([p[1] for p in text_parts])
        word_count = len(full_text.split())
        results['word_count_stats'].append(word_count)

        # Check for warning callouts & sources
        has_warning = False
        has_sources = False
        sections = art.get('sections', [])
        if not sections or len(sections) == 0:
            results['empty_sections_articles'].append({'id': art_id, 'title': art_title})

        for sec in sections:
            if isinstance(sec, dict):
                if sec.get('calloutWarning'):
                    has_warning = True
                content = sec.get('content', '') + sec.get('title', '')
                if "المصادر" in content or "المراجع" in content or "منظمة الصحة" in content:
                    has_sources = True

        if has_warning:
            results['has_warning_callout_count'] += 1
        if has_sources:
            results['has_medical_sources_count'] += 1

        # Check Category 1: Health Misinfo
        for pattern, label in HEALTH_MISINFO_PATTERNS:
            for loc, text in text_parts:
                m = re.search(pattern, text, re.I)
                if m:
                    snippet = text[max(0, m.start()-40):min(len(text), m.end()+40)]
                    results['policy_counts']['health_misinfo'] += 1
                    results['articles_with_any_flag'].add(art_id)
                    results['flagged_articles']['health_misinfo'].append({
                        'id': art_id,
                        'title': art_title,
                        'category': category_name,
                        'subcategory': subcategory_name,
                        'rule': label,
                        'match': m.group(0),
                        'location': loc,
                        'snippet': snippet.strip()
                    })
                    break

        # Check Category 2: Abortion & Pregnancy Danger
        for pattern, label in ABORTION_DANGER_PATTERNS:
            for loc, text in text_parts:
                m = re.search(pattern, text, re.I)
                if m:
                    snippet = text[max(0, m.start()-40):min(len(text), m.end()+40)]
                    results['policy_counts']['abortion_danger'] += 1
                    results['articles_with_any_flag'].add(art_id)
                    results['flagged_articles']['abortion_danger'].append({
                        'id': art_id,
                        'title': art_title,
                        'category': category_name,
                        'subcategory': subcategory_name,
                        'rule': label,
                        'match': m.group(0),
                        'location': loc,
                        'snippet': snippet.strip()
                    })
                    break

        # Check Category 3: Prescription Drugs
        for pattern, label in CONTROLLED_DRUG_PATTERNS:
            for loc, text in text_parts:
                m = re.search(pattern, text, re.I)
                if m:
                    snippet = text[max(0, m.start()-40):min(len(text), m.end()+40)]
                    results['policy_counts']['prescription_drugs'] += 1
                    results['articles_with_any_flag'].add(art_id)
                    results['flagged_articles']['prescription_drugs'].append({
                        'id': art_id,
                        'title': art_title,
                        'category': category_name,
                        'subcategory': subcategory_name,
                        'rule': label,
                        'match': m.group(0),
                        'location': loc,
                        'snippet': snippet.strip()
                    })
                    break

        # Check Category 4: Infant Hazards
        for pattern, label in INFANT_HAZARD_PATTERNS:
            for loc, text in text_parts:
                m = re.search(pattern, text, re.I)
                if m:
                    snippet = text[max(0, m.start()-40):min(len(text), m.end()+40)]
                    results['policy_counts']['infant_hazards'] += 1
                    results['articles_with_any_flag'].add(art_id)
                    results['flagged_articles']['infant_hazards'].append({
                        'id': art_id,
                        'title': art_title,
                        'category': category_name,
                        'subcategory': subcategory_name,
                        'rule': label,
                        'match': m.group(0),
                        'location': loc,
                        'snippet': snippet.strip()
                    })
                    break

        # Check Category 5: Explicit Sexual Content
        for pattern, label in SEXUAL_EXPLICIT_PATTERNS:
            for loc, text in text_parts:
                m = re.search(pattern, text, re.I)
                if m:
                    snippet = text[max(0, m.start()-40):min(len(text), m.end()+40)]
                    results['policy_counts']['sexual_content'] += 1
                    results['articles_with_any_flag'].add(art_id)
                    results['flagged_articles']['sexual_content'].append({
                        'id': art_id,
                        'title': art_title,
                        'category': category_name,
                        'subcategory': subcategory_name,
                        'rule': label,
                        'match': m.group(0),
                        'location': loc,
                        'snippet': snippet.strip()
                    })
                    break

        # Check Category 6: Brand Leaks / Competitor Mentions
        for pattern, label in BRAND_LEAK_PATTERNS:
            for loc, text in text_parts:
                m = re.search(pattern, text, re.I)
                if m:
                    # Ignore legitimate words like "الملكة إليزابيث" or "نحل الملكة" if any
                    matched_str = m.group(0)
                    snippet = text[max(0, m.start()-40):min(len(text), m.end()+40)]
                    if "ملكة النحل" in snippet or "الملكة إليزابيث" in snippet or "تاج الملكة" in snippet:
                        continue
                    results['policy_counts']['brand_leakage'] += 1
                    results['articles_with_any_flag'].add(art_id)
                    results['flagged_articles']['brand_leakage'].append({
                        'id': art_id,
                        'title': art_title,
                        'category': category_name,
                        'subcategory': subcategory_name,
                        'rule': label,
                        'match': matched_str,
                        'location': loc,
                        'snippet': snippet.strip()
                    })
                    break

        # Check Category 7: Clickbait & Deceptive Claims
        for pattern, label in CLICKBAIT_PATTERNS:
            for loc, text in text_parts:
                m = re.search(pattern, text, re.I)
                if m:
                    snippet = text[max(0, m.start()-40):min(len(text), m.end()+40)]
                    results['policy_counts']['clickbait'] += 1
                    results['articles_with_any_flag'].add(art_id)
                    results['flagged_articles']['clickbait'].append({
                        'id': art_id,
                        'title': art_title,
                        'category': category_name,
                        'subcategory': subcategory_name,
                        'rule': label,
                        'match': m.group(0),
                        'location': loc,
                        'snippet': snippet.strip()
                    })
                    break

        # Check Category 8: HTML Entities & Placeholders
        for loc, text in text_parts:
            html_m = HTML_ENTITY_PATTERN.search(text)
            if html_m:
                results['html_entity_count'] += 1
                results['flagged_articles']['html_entities'].append({
                    'id': art_id,
                    'title': art_title,
                    'match': html_m.group(0),
                    'location': loc
                })
                break

        for loc, text in text_parts:
            ph_m = PLACEHOLDER_PATTERN.search(text)
            if ph_m:
                results['placeholder_count'] += 1
                results['flagged_articles']['placeholders'].append({
                    'id': art_id,
                    'title': art_title,
                    'match': ph_m.group(0),
                    'location': loc
                })
                break

        # Check sourceUrl for external non-nabda links
        source_url = art.get('sourceUrl', '')
        if source_url and not source_url.startswith("https://nabda.online"):
            results['external_links_count'] += 1
            results['flagged_articles']['external_sources'].append({
                'id': art_id,
                'title': art_title,
                'sourceUrl': source_url
            })

    return results

# Run audit on active corpus
res = audit_corpus(DATA_PATH)

# Summary calculations
tot = res['total_articles']
avg_words = sum(res['word_count_stats']) / tot if tot else 0
flagged_total = len(res['articles_with_any_flag'])
clean_total = tot - flagged_total
compliance_rate = (clean_total / tot) * 100 if tot else 0

summary = {
    'total_analyzed': tot,
    'clean_articles_count': clean_total,
    'compliance_rate_percent': round(compliance_rate, 2),
    'articles_with_any_flag': flagged_total,
    'average_words_per_article': round(avg_words, 1),
    'articles_with_warning_callouts': res['has_warning_callout_count'],
    'articles_with_medical_sources': res['has_medical_sources_count'],
    'empty_sections_count': len(res['empty_sections_articles']),
    'html_entities_flagged': res['html_entity_count'],
    'placeholders_flagged': res['placeholder_count'],
    'external_non_nabda_sources': res['external_links_count'],
    'policy_breakdown': {k: res['policy_counts'][k] for k in res['policy_counts']},
}

print("\n========================================================")
print("AUDIT RESULTS SUMMARY:")
print("========================================================")
print(f"Total Articles Analyzed: {tot}")
print(f"Clean Articles (No Policy Flags): {clean_total} ({compliance_rate:.2f}%)")
print(f"Articles with Flags for Review: {flagged_total} ({(flagged_total/tot)*100:.2f}%)")
print(f"Average Words Per Article: {avg_words:.1f}")
print(f"Articles with Section Warning Callouts: {res['has_warning_callout_count']} ({(res['has_warning_callout_count']/tot)*100:.2f}%)")
print(f"Articles with Verified Medical References/Sources: {res['has_medical_sources_count']} ({(res['has_medical_sources_count']/tot)*100:.2f}%)")
print(f"Empty Sections Articles: {len(res['empty_sections_articles'])}")
print(f"HTML Entities Artifacts: {res['html_entity_count']}")
print(f"Placeholder Artifacts (null/undefined): {res['placeholder_count']}")
print(f"External Source URLs (Non-nabda.online): {res['external_links_count']}")

print("\nFlags by Policy Category:")
for k, v in res['policy_counts'].items():
    print(f"  - {k}: {v}")

# Save detailed report to scratch
summary_path = os.path.join(SCRATCH_DIR, "compliance_audit_summary.json")
with open(summary_path, 'w', encoding='utf-8') as f:
    json.dump(summary, f, ensure_ascii=False, indent=2)

details_path = os.path.join(SCRATCH_DIR, "flagged_articles_detail.json")
# Convert sets to lists
serializable_flagged = {k: v for k, v in res['flagged_articles'].items()}
with open(details_path, 'w', encoding='utf-8') as f:
    json.dump(serializable_flagged, f, ensure_ascii=False, indent=2)

print(f"\nDetailed report written to: {details_path}")
print(f"Summary written to: {summary_path}")
