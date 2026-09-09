# -*- coding: utf-8 -*-
"""
Deep comprehensive audit of linguistics, spelling, typography,
citations, and medical references across all articles in Nabda.
"""
import json
import re
import os
import sys
from collections import Counter

sys.stdout.reconfigure(encoding='utf-8')

def audit_all():
    print("==================================================")
    print("1. AUDITING SMART_2500_ARTICLES.JSON")
    print("==================================================")
    json_path = 'assets/data/smart_2500_articles.json'
    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    articles = data.get('articles', [])
    print(f"Total articles loaded: {len(articles)}")

    # 1.1 Check the 7 missing sources
    missing_sources_articles = []
    sources_analysis = Counter()
    sample_sources_by_cat = {}

    for a in articles:
        aid = a.get('id')
        cat = a.get('categoryId')
        has_src = False
        for s in a.get('sections', []):
            st = s.get('title', '')
            if 'مصادر' in st or 'مراجع' in st or 'references' in st.lower():
                has_src = True
                content = s.get('content', '')
                # Count mentions of WHO, ACOG, etc.
                for ref in ['WHO', 'ACOG', 'AAP', 'AAD', 'ASRM', 'APA', 'Mayo Clinic', 'CDC', 'Cochrane', 'NIH']:
                    if ref.lower() in content.lower():
                        sources_analysis[ref] += 1
                if cat not in sample_sources_by_cat:
                    sample_sources_by_cat[cat] = (aid, st, content)
                break
        if not has_src:
            missing_sources_articles.append((aid, cat, a.get('title')))

    print(f"\nArticles missing sources section: {len(missing_sources_articles)}")
    for m in missing_sources_articles:
        print(f"  - [{m[1]}] {m[0]}: {m[2]}")

    print("\nMedical references frequency in sources sections:")
    for ref, count in sources_analysis.most_common():
        print(f"  - {ref}: {count} articles")

    # 1.2 Linguistic & Grammar & Spelling Audit
    print("\nLinguistic & Spelling Audit across smart_2500_articles.json:")
    
    # Common Hamzat mistakes in Arabic
    hamza_wasl_mistakes = {
        'إستخدام': 'استخدام',
        'إستشارة': 'استشارة',
        'إختبار': 'اختبار',
        'إكتئاب': 'اكتئاب',
        'إلتهاب': 'التهاب',
        'إفرازات': 'إفرازات', # correct
        'إنتفاخ': 'انتفاخ',
        'إسترخاء': 'استرخاء',
        'إستعداد': 'استعداد',
        'إرتفاع': 'ارتفاع',
        'إنخفاض': 'انخفاض',
        'إستجابة': 'استجابة',
    }
    hamza_qat_mistakes = {
        'اثناء': 'أثناء',
        'اعراض': 'أعراض',
        'اسابيع': 'أسابيع',
        'اسباب': 'أسباب',
        'اكثر': 'أكثر',
        'افضل': 'أفضل',
        'اهم': 'أهم',
        'اطعمة': 'أطعمة',
        'ادوية': 'أدوية',
        'اشهر': 'أشهر',
        'الم': 'ألم',
        'امومة': 'أمومة',
        'اطفال': 'أطفال',
    }
    alif_maqsura_mistakes = {
        'علي ': 'على ',
        ' إلي ': ' إلى ',
        ' حتي ': ' حتى ',
        'مستشفي ': 'مستشفى ',
    }
    taa_marbuta_mistakes = {
        ' صحه ': ' صحة ',
        ' دوره ': ' دورة ',
        ' حياه ': ' حياة ',
        ' طاقه ': ' طاقة ',
        ' رضاعه ': ' رضاعة ',
        ' عنايه ': ' عناية ',
        ' تغذيه ': ' تغذية ',
        ' حركه ': ' حركة ',
    }
    
    hamza_wasl_counts = Counter()
    hamza_qat_counts = Counter()
    alif_maqsura_counts = Counter()
    taa_marbuta_counts = Counter()
    punctuation_issues = 0
    unbalanced_quotes = 0
    
    # Analyze all text
    for a in articles:
        title = a.get('title', '')
        desc = a.get('description', '')
        text = title + ' ' + desc + ' ' + ' '.join(s.get('title','') + ' ' + s.get('content','') for s in a.get('sections', []))
        
        # Check Hamza Wasl
        for w, correct in hamza_wasl_mistakes.items():
            if w in text:
                hamza_wasl_counts[w] += text.count(w)
                
        # Check Hamza Qat (using word boundaries where possible)
        for w, correct in hamza_qat_mistakes.items():
            pattern = rf'\b{w}\b'
            matches = re.findall(pattern, text)
            if matches:
                hamza_qat_counts[w] += len(matches)
                
        # Check Alif Maqsura
        for w, correct in alif_maqsura_mistakes.items():
            if w in text:
                alif_maqsura_counts[w.strip()] += text.count(w)
                
        # Check Taa Marbuta
        for w, correct in taa_marbuta_mistakes.items():
            if w in text:
                taa_marbuta_counts[w.strip()] += text.count(w)
                
        # Space before punctuation
        if re.search(r'\s+[،,؛;.!؟]', text):
            punctuation_issues += 1
            
        # Unbalanced quotes
        q_count = text.count('"')
        if q_count % 2 != 0:
            unbalanced_quotes += 1

    print(f"Total articles with space before punctuation: {punctuation_issues}")
    print(f"Articles with unbalanced double quotes: {unbalanced_quotes}")
    
    print("\nTop Hamzat Al-Wasl mistakes (written with Hamza instead of Wasl):")
    for w, c in hamza_wasl_counts.most_common(8):
        print(f"  - {w} -> {hamza_wasl_mistakes[w]}: {c} occurrences")

    print("\nTop Hamzat Al-Qat mistakes (written without Hamza):")
    for w, c in hamza_qat_counts.most_common(8):
        print(f"  - {w} -> {hamza_qat_mistakes[w]}: {c} occurrences")

    print("\nTop Taa Marbuta mistaken for Haa:")
    for w, c in taa_marbuta_counts.most_common(8):
        print(f"  - {w}: {c} occurrences")

    print("\nTop Alif Maqsura mistaken for Yaa:")
    for w, c in alif_maqsura_counts.most_common(8):
        print(f"  - {w}: {c} occurrences")

    # 1.3 Citation content check
    print("\nChecking quotes and in-text citations:")
    citation_samples = []
    quote_regex = re.compile(r'«([^»]{10,120})»|"([^"]{10,120})"')
    study_regex = re.compile(r'((?:أظهرت|أثبتت|أشارت|كشفت|أكدت|حسب|وفقاً لـ)\s+(?:دراسة|أبحاث|تقرير|توصيات|منظمة|الجمعية|الأكاديمية)[^.\n]{15,100})')
    
    study_mentions = 0
    for a in articles:
        text = ' '.join(s.get('content','') for s in a.get('sections', []))
        m = study_regex.findall(text)
        if m:
            study_mentions += len(m)
            if len(citation_samples) < 5:
                citation_samples.append((a.get('id'), m[0].strip()))

    print(f"Total in-text scientific/medical study citations found: {study_mentions}")
    print("Sample in-text citations from articles:")
    for s in citation_samples:
        print(f"  [{s[0]}]: \"{s[1]}\"")

    print("\n==================================================")
    print("2. AUDITING IN-APP HARDCODED ARTICLES & WEB")
    print("==================================================")
    
    other_files = [
        ('lib/data/baby_care_age_articles.dart', 'Baby Care Age Articles'),
        ('lib/models/pregnancy_week_articles.dart', 'Pregnancy Week Articles'),
        ('lib/screens/pregnancy/discover_articles_screen.dart', 'Discover Articles'),
        ('lib/data/specialized_articles.dart', 'Specialized Articles'),
        ('web/landing.html', 'Landing Page'),
    ]
    
    for fpath, label in other_files:
        if os.path.exists(fpath):
            with open(fpath, 'r', encoding='utf-8', errors='ignore') as f:
                c = f.read()
            punc_issues = len(re.findall(r'\s+[،,؛;.!؟]', c))
            has_src = 'مصادر' in c or 'مراجع' in c or 'ACOG' in c or 'WHO' in c
            print(f"- {label} ({fpath}):")
            print(f"    Size: {len(c):,} chars")
            print(f"    Mentions medical sources/references: {has_src}")
            print(f"    Punctuation spacing issues: {punc_issues}")
        else:
            print(f"- {label} ({fpath}): NOT FOUND")

if __name__ == '__main__':
    audit_all()
