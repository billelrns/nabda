"""
يحدّث imagePath لكل مقال ليستعمل الصور القالبية.
كل مقال يختار صورة حسب hash(id) % 5 + 1 → توزيع متوازن.
"""
import json
import hashlib
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
BACKUP = Path(f'C:/nabda_app/assets/data/smart_2500_articles.imgpath_backup_{datetime.now():%Y%m%d_%H%M%S}.json')

# categoryId في JSON → prefix في اسم الصورة
CATEGORY_TO_IMG = {
    'pregnancy': 'pregnancy',
    'beauty': 'beauty',
    'marriage': 'marriage',
    'fertility': 'fertility',
    'health': 'health',
    'womens_health': 'health',
    'baby': 'baby',
    'baby_care': 'baby',
}

shutil.copy(SRC, BACKUP)
print(f'✓ نسخة احتياطية: {BACKUP.name}')

with SRC.open('r', encoding='utf-8') as f:
    data = json.load(f)

changed = 0
for a in data['articles']:
    cat_id = a.get('categoryId', 'pregnancy')
    img_cat = CATEGORY_TO_IMG.get(cat_id, 'pregnancy')
    # اختيار متسق: نفس المقال يحصل دائماً على نفس القالب
    h = hashlib.md5(a['id'].encode()).hexdigest()
    img_num = (int(h[:8], 16) % 5) + 1  # 1-5
    new_path = f'assets/images/articles_bg/bg_{img_cat}_{img_num:02d}.jpg'
    if a.get('imagePath') != new_path:
        a['imagePath'] = new_path
        changed += 1

with SRC.open('w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(f'\n✓ {changed} مقال تم تحديث imagePath')
print(f'✓ توزيع متوازن: كل صورة تُستعمل في ~{len(data["articles"]) // 30} مقال في المتوسط')

# مزامنة الصور للويب أيضاً
web_target_dir = Path(r'C:\nabda_app\web\assets\images\articles_bg')
web_target_dir.mkdir(parents=True, exist_ok=True)
src_bg = Path(r'C:\nabda_app\assets\images\articles_bg')
for item in src_bg.glob('*.jpg'):
    dest = web_target_dir / item.name
    shutil.copy2(item, dest)
print(f'✓ تم نسخ الصور القالبية للويب: {web_target_dir}')
