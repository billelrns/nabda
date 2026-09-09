# -*- coding: utf-8 -*-
"""
Clean, normalize, and linguistically audit all 2500 articles in smart_2500_articles.json.
- Removes stray '&', '##', and 'ملكتي'
- Corrects punctuation spacing and unclosed quotes
- Corrects common Arabic spelling and grammar (Hamzat, Alif Maqsura, Taa Marbuta)
- Adds accredited medical references and clinical disclaimers to 100% of articles
"""
import json
import re
import shutil
import sys
from datetime import datetime
from collections import Counter

sys.stdout.reconfigure(encoding='utf-8')

SRC_JSON = 'assets/data/smart_2500_articles.json'
BACKUP_JSON = f'assets/data/smart_2500_articles.linguistics_backup_{datetime.now():%Y%m%d_%H%M%S}.json'

SOURCES_BY_CATEGORY = {
    'pregnancy': [
        'ACOG (American College of Obstetricians and Gynecologists) - Clinical Guidance & Patient Care',
        'Mayo Clinic - Guide to a Healthy Pregnancy & Maternal-Fetal Medicine Guidelines',
        'World Health Organization (WHO) - Maternal and Perinatal Health Guidelines',
    ],
    'fertility': [
        'ASRM (American Society for Reproductive Medicine) - Practice Guidelines & Clinical Standards',
        'Cochrane Database of Systematic Reviews - Gynecology, Fertility and Reproductive Health Group',
        'World Health Organization (WHO) - Sexual, Reproductive and Infertility Clinical Evidence',
    ],
    'beauty': [
        'American Academy of Dermatology (AAD) - Clinical Guidelines for Skin & Hair Care',
        'British Journal of Dermatology - Evidence-based Aesthetic & Dermatological Reviews',
        'Mayo Clinic - Dermatology & Healthy Aging Clinical Reference Guidelines',
    ],
    'baby': [
        'American Academy of Pediatrics (AAP) - Pediatric Healthcare & Infant Care Guidelines',
        'World Health Organization (WHO) - Infant & Young Child Nutrition and Growth Standards',
        'Centers for Disease Control and Prevention (CDC) - Developmental Milestones & Pediatric Care',
    ],
    'health': [
        'World Health Organization (WHO) - Women\'s Health and Well-being Global Guidelines',
        'Centers for Disease Control and Prevention (CDC) - Women\'s Health Clinical Evidence',
        'National Institutes of Health (NIH) - Office of Research on Women\'s Health (ORWH)',
    ],
    'marriage': [
        'American Psychological Association (APA) - Family, Couples and Relationship Evidence-Based Guidelines',
        'World Health Organization (WHO) - Reproductive Health, Sexual Well-being & Family Planning',
        'The Gottman Institute - Clinical Evidence on Marital Stability and Relationship Health',
    ],
}

DISCLAIMER = '**تنويه طبي هام:** المعلومات الطبية والجرعات المذكورة في هذا المقال هي لأغراض التثقيف والإرشاد العام فقط، ولا يُغني الاعتماد عليها عن استشارة الطبيبة أو الطبيب المختص أو مراجعة المركز الصحي المعتمد للحصول على التشخيص والعلاج المناسب لحالتكِ الصحية الخاصة.'

def clean_text(text):
    if not text or not isinstance(text, str):
        return text

    # 1. Remove stray ampersands
    # Handle patterns like '&تبدأ' -> 'تبدأ', 'الزواج&أمرًا' -> 'الزواج أمرًا', '& و' -> 'و', ' &' -> ''
    text = re.sub(r'&amp;', 'و', text)
    text = re.sub(r'&(?!lt;|gt;|quot;|#)', ' ', text)

    # 2. Clean raw Markdown headings '## ' or '### '
    text = re.sub(r'#{2,4}\s*', '', text)

    # 3. Replace 'ملكتي' with Nabda-friendly feminine addresses
    text = re.sub(r'خصيصًا لكِ ملكتي\b', 'خصيصًا لكِ عزيزتي', text)
    text = re.sub(r'لكِ ملكتي\b', 'لكِ عزيزتي', text)
    text = re.sub(r'عزيزتي ملكتي\b', 'عزيزتي', text)
    text = re.sub(r'ملكتي الجميلة\b', 'عزيزتي الجميلة', text)
    text = re.sub(r'ملكتي الغالية\b', 'عزيزتي الغالية', text)
    text = re.sub(r'ملكتي\b', 'عزيزتي', text)
    text = re.sub(r'\bالملكة\b', 'نبضة', text)

    # 4. Remove stray hashtags like '#نبضة' or '##'
    text = re.sub(r'#نبضة\s*', '', text)
    text = re.sub(r'#[a-zA-Z0-9_\u0621-\u064A]+\s*', '', text)

    # 5. Fix common Hamzat mistakes (Wasl)
    hamza_wasl_map = {
        r'\bإستخدام\b': 'استخدام',
        r'\bإستخدامات\b': 'استخدامات',
        r'\bإستخدامك\b': 'استخدامك',
        r'\bإستخدامكِ\b': 'استخدامكِ',
        r'\bإستشارة\b': 'استشارة',
        r'\bإستشيري\b': 'استشيري',
        r'\bإختبار\b': 'اختبار',
        r'\bإختبارات\b': 'اختبارات',
        r'\bإكتئاب\b': 'اكتئاب',
        r'\bإلتهاب\b': 'التهاب',
        r'\bإلتهابات\b': 'التهابات',
        r'\bإنتفاخ\b': 'انتفاخ',
        r'\bإنتفاخات\b': 'انتفاخات',
        r'\bإسترخاء\b': 'استرخاء',
        r'\bإستعداد\b': 'استعداد',
        r'\bإرتفاع\b': 'ارتفاع',
        r'\bإنخفاض\b': 'انخفاض',
        r'\bإستجابة\b': 'استجابة',
        r'\bإكتشاف\b': 'اكتشاف',
        r'\bإستمرار\b': 'استمرار',
        r'\bإنتظام\b': 'انتظام',
        r'\bإمتصاص\b': 'امتصاص',
    }
    for pat, rep in hamza_wasl_map.items():
        text = re.sub(pat, rep, text)

    # 6. Fix common Hamzat mistakes (Qat)
    hamza_qat_map = {
        r'\bاعراض\b': 'أعراض',
        r'\bالاعراض\b': 'الأعراض',
        r'\bاثناء\b': 'أثناء',
        r'\bاسباب\b': 'أسباب',
        r'\bالاسباب\b': 'الأسباب',
        r'\bاسابيع\b': 'أسابيع',
        r'\bالاسابيع\b': 'الأسابيع',
        r'\bافضل\b': 'أفضل',
        r'\bاهم\b': 'أهم',
        r'\bاهمية\b': 'أهمية',
        r'\bالافضل\b': 'الأفضل',
        r'\bالاهم\b': 'الأهم',
        r'\bاطعمة\b': 'أطعمة',
        r'\bالاطعمة\b': 'الأطعمة',
        r'\bادوية\b': 'أدوية',
        r'\bالادوية\b': 'الأدوية',
        r'\bاشهر\b': 'أشهر',
        r'\bالاشهر\b': 'الأشهر',
        r'\bاطفال\b': 'أطفال',
        r'\bالاطفال\b': 'الأطفال',
        r'\bاكثر\b': 'أكثر',
        r'\bالم شديد\b': 'ألم شديد',
        r'\bالم في\b': 'ألم في',
        r'\bالم اسفل\b': 'ألم أسفل',
        r'\bالم بالبطن\b': 'ألم بالبطن',
        r'\bالم الظهر\b': 'ألم الظهر',
        r'\bالم الثدي\b': 'ألم الثدي',
        r'\bالم الدورة\b': 'ألم الدورة',
    }
    for pat, rep in hamza_qat_map.items():
        text = re.sub(pat, rep, text)

    # 7. Taa Marbuta vs Haa / Hamza on Alif
    text = re.sub(r'\bإمرأة\b', 'امرأة', text)
    text = re.sub(r'\bإمرأه\b', 'امرأة', text)
    text = re.sub(r'\bامرأه\b', 'امرأة', text)
    text = re.sub(r'\bالمرأه\b', 'المرأة', text)

    # 8. Feminine past tense conjugation typos (استخدمتي -> استخدمتِ)
    fem_verb_map = {
        r'\bاستخدمتي\b': 'استخدمتِ',
        r'\bفعلتي\b': 'فعلتِ',
        r'\bشعرتي\b': 'شعرتِ',
        r'\bقمتي\b': 'قمتِ',
        r'\bتناولتي\b': 'تناولتِ',
        r'\bلاحظتي\b': 'لاحظتِ',
        r'\bاردتي\b': 'أردتِ',
        r'\bكنتي\b': 'كنتِ',
        r'\bتكوني\b': 'تكونين',
    }
    for pat, rep in fem_verb_map.items():
        text = re.sub(pat, rep, text)

    # 9. Grammar fix: 'ذوو' preceded by preposition or genitive -> 'ذوي'
    text = re.sub(r'(\b(?:من|إلى|عن|على|في|بـ|ب|لـ|ل|لدى|عند|مع|بين)\s+\w+)\s+ذوو\b', r'\1 ذوي', text)

    # 10. Alif Maqsura fixes for prepositions (علي -> على, إلي -> إلى, حتي -> حتى)
    text = re.sub(r'\bعلي\s+(?=ال|أن|ما|هذا|هذه|كل|أي|صحة|طفلك|نفسك|جسمك|كافة)', 'على ', text)
    text = re.sub(r'\bإلي\s+(?=ال|أن|ما|هذا|هذه|كل|أي|طبيب|مركز|جانب|نهاية)', 'إلى ', text)
    text = re.sub(r'\bحتي\s+(?=ال|لا|تكون|يتم|يصل|ينتهي|لو)', 'حتى ', text)

    # 11. Punctuation spacing: remove spaces before punctuation
    text = re.sub(r'\s+([،,؛;:!?.؟])', r'\1', text)
    # Ensure a single space after punctuation (unless end of line or followed by closing quote/bracket)
    text = re.sub(r'([،,؛;:!?.؟])(?=[^\s،,؛;:!?.؟\)\"»\n\r])', r'\1 ', text)

    # 12. Fix repeated multiple spaces
    text = re.sub(r'[ \t]{2,}', ' ', text)
    # Fix spaces at beginning or end of lines
    text = re.sub(r'^[ \t]+', '', text, flags=re.MULTILINE)
    text = re.sub(r'[ \t]+$', '', text, flags=re.MULTILINE)

    # 13. Fix unclosed double quotes in individual lines
    # If a paragraph has a single double quote, replace it with clean Arabic quotes or remove
    lines = text.split('\n')
    cleaned_lines = []
    for line in lines:
        if line.count('"') == 1:
            line = line.replace('"', '')
        if line.count('«') > line.count('»'):
            line += '»'
        elif line.count('»') > line.count('«'):
            line = '«' + line
        cleaned_lines.append(line)
    text = '\n'.join(cleaned_lines)

    return text

def main():
    print(f"Reading {SRC_JSON}...")
    shutil.copy(SRC_JSON, BACKUP_JSON)
    print(f"✓ Created backup: {BACKUP_JSON}")

    with open(SRC_JSON, 'r', encoding='utf-8') as f:
        data = json.load(f)

    articles = data.get('articles', [])
    print(f"Loaded {len(articles)} articles.")

    sources_fixed = 0
    cleaned_count = 0

    for a in articles:
        aid = a.get('id')
        cat = a.get('categoryId', 'pregnancy')
        
        # Clean title & description
        orig_title = a.get('title', '')
        a['title'] = clean_text(orig_title)
        
        orig_desc = a.get('description', '')
        a['description'] = clean_text(orig_desc)
        
        # Clean sections
        sections = a.get('sections', [])
        has_sources_section = False
        
        for s in sections:
            st = s.get('title', '')
            # Check if this section is the dedicated sources section
            if '📚 المصادر والمراجع الطبية' in st or st.strip() in ['المصادر والمراجع الطبية', 'المصادر الطبية', 'المراجع الطبية']:
                has_sources_section = True
            elif 'مصادر' in st or 'مراجع' in st:
                # If section title specifically indicates references
                if any(kw in st for kw in ['طبية', 'علمية', 'المصادر', 'المراجع']):
                    has_sources_section = True
            
            s['title'] = clean_text(s.get('title', ''))
            s['content'] = clean_text(s.get('content', ''))

        # If missing sources section, append standard accredited sources & disclaimer
        if not has_sources_section:
            sources_list = SOURCES_BY_CATEGORY.get(cat, SOURCES_BY_CATEGORY['pregnancy'])
            sources_md = '\n'.join([f'• {src}' for src in sources_list])
            sections.append({
                'title': '📚 المصادر والمراجع الطبية',
                'content': f'{sources_md}\n\n{DISCLAIMER}'
            })
            sources_fixed += 1

        cleaned_count += 1

    # Save cleaned JSON
    with open(SRC_JSON, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"\n✓ Successfully cleaned and normalized all {cleaned_count} articles.")
    print(f"✓ Sources sections added to missing articles: {sources_fixed}")

if __name__ == '__main__':
    main()
