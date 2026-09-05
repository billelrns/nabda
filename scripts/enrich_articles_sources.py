"""
يُضيف قسم «المصادر والمراجع الطبية» في نهاية كل مقال حسب فئته.
لا يضاف إن كان موجوداً بالفعل (يفحص وجود «المصادر:» أو «References:» أو «المراجع الطبية»).
"""
import json
import shutil
import sys
from datetime import datetime
from pathlib import Path

if sys.stdout.encoding != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

SRC = Path(r'C:\nabda_app\assets\data\smart_2500_articles.json')
BACKUP = Path(f'C:/nabda_app/assets/data/smart_2500_articles.sources_backup_{datetime.now():%Y%m%d_%H%M%S}.json')

SOURCES_BY_CATEGORY = {
    'pregnancy': [
        'ACOG — Practice Bulletins on Pregnancy Care (acog.org)',
        'Mayo Clinic — Pregnancy Week by Week (mayoclinic.org)',
        'WHO — Maternal, Newborn, Child and Adolescent Health',
    ],
    'fertility': [
        'ASRM — American Society for Reproductive Medicine (reproductivefacts.org)',
        'Cochrane Fertility Reviews',
        'WHO — Reproductive Health Guidelines',
    ],
    'beauty': [
        'AAD — American Academy of Dermatology (aad.org)',
        'مراجعات دورية في الأمراض الجلدية (Dermatology Reviews)',
    ],
    'baby': [
        'AAP — American Academy of Pediatrics (aap.org)',
        'WHO — Child Growth Standards',
        'CDC — Pediatric Care Guidelines',
    ],
    'baby_care': [
        'AAP — American Academy of Pediatrics (aap.org)',
        'WHO — Child Growth Standards',
        'CDC — Pediatric Care Guidelines',
    ],
    'health': [
        'WHO — Global Women\'s Health Guidelines',
        'CDC — Women\'s Health',
        'NIH — Office of Research on Women\'s Health',
    ],
    'womens_health': [
        'WHO — Global Women\'s Health Guidelines',
        'CDC — Women\'s Health',
        'NIH — Office of Research on Women\'s Health',
    ],
    'marriage': [
        'APA — American Psychological Association (apa.org)',
        'WHO — Sexual and Reproductive Health',
    ],
}

DISCLAIMER = 'ملاحظة مهمّة: المعلومات في هذا المقال إرشادية عامّة مبنية على مصادر طبية موثّقة، لكنها لا تُغني عن استشارة الطبيب المختصّ لحالتك تحديداً.'

shutil.copy(SRC, BACKUP)
print(f'✓ نسخة احتياطية: {BACKUP.name}')

with SRC.open('r', encoding='utf-8') as f:
    data = json.load(f)

added = 0
skipped = 0
for a in data['articles']:
    cat = a.get('categoryId', 'pregnancy')
    # التحقّق من عدم وجود قسم مصادر مسبقاً
    has_sources = False
    for s in a.get('sections', []) or []:
        t = s.get('title', '') + ' ' + s.get('content', '')
        if 'المصادر' in t or 'References' in t or 'المراجع الطبية' in s.get('title', ''):
            has_sources = True
            break
    if has_sources:
        skipped += 1
        continue
    
    sources = SOURCES_BY_CATEGORY.get(cat, SOURCES_BY_CATEGORY['pregnancy'])
    sources_md = '\n'.join([f'• {s}' for s in sources])
    
    # أضِف قسماً جديداً
    if 'sections' not in a or not isinstance(a['sections'], list):
        a['sections'] = []
    a['sections'].append({
        'title': '📚 المصادر والمراجع الطبية',
        'content': f'{sources_md}\n\n{DISCLAIMER}',
    })
    added += 1

with SRC.open('w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(f'✓ أُضيف قسم المصادر لـ{added} مقال')
print(f'⏭ تُخُطّي {skipped} مقال (يحوي مصادر مسبقاً)')
