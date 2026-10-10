# -*- coding: utf-8 -*-
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

smart_path = 'C:/nabda_app/assets/data/smart_2500_articles.json'
with open(smart_path, 'r', encoding='utf-8') as f:
    smart_data = json.load(f)

articles = smart_data.get('articles', [])
cat_dist = smart_data.get('categories_distribution', {})

lines = []
lines.append("# 📚 الموسوعة الطبية الكبرى — فهرس الـ 2,500 مقال لتطبيق وموقع نبضة")
lines.append("")
lines.append("> **تاريخ التحديث:** سبتمبر 2026 | **إجمالي المقالات:** 2500 مقال بشري موثق بالكامل.")
lines.append("")
lines.append("## 📊 توزيع المقالات حسب الأقسام")
lines.append("")
for cat, count in cat_dist.items():
    lines.append(f"- **{cat}:** {count} مقال")
lines.append("")
lines.append("---")
lines.append("")
lines.append("## 📑 قائمة المقالات الكاملة (2,500 مقال)")
lines.append("")
lines.append("| الرقم | المعرف | القسم | العنوان الإرشادي المنقح | المشاهدات |")
lines.append("| :---: | :---: | :---: | :--- | :---: |")

for idx, a in enumerate(articles, 1):
    aid = a.get('id', '')
    cat = a.get('categoryName', '')
    title = a.get('title', '').replace('|', '-')
    views = a.get('originalViews', 0)
    lines.append(f"| {idx} | `{aid}` | {cat} | **{title}** | {views} |")

catalog_path = 'C:/nabda_app/assets/data/smart_2500_catalog.md'
with open(catalog_path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))

print(f"✅ Successfully updated {catalog_path} with {len(articles)} entries.")
