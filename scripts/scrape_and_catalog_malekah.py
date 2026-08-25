# -*- coding: utf-8 -*-
import urllib.request
import re
import json
import ssl
from urllib.parse import unquote
from collections import defaultdict, Counter

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36'
}

def fetch(url):
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, timeout=30, context=ctx) as resp:
        return resp.read().decode('utf-8', errors='ignore')

def clean_arabic_title(raw_slug):
    text = unquote(raw_slug)
    text = re.sub(r'[-_]+', ' ', text)
    text = re.sub(r'\s+', ' ', text).strip()
    return text

def categorize_title(title):
    title_lower = title.lower()
    
    # Pregnancy & Birth
    if any(k in title_lower for k in ['حمل', 'حامل', 'جنين', 'ولادة', 'مخاض', 'قيصري', 'بويضة', 'سونار', 'انغراس', 'إجهاض', 'رحم', 'سلى', 'مشيمة', 'توأم', 'ولاده']):
        return 'الحمل والولادة'
    
    # Cycle & Fertility & Ovulation
    if any(k in title_lower for k in ['دورة', 'حيض', 'تبويض', 'خصوبة', 'طمث', 'تكيس', 'استحاضة', 'إفرازات', 'هرمون', 'تأخر الإنجاب', 'مبايض']):
        return 'الدورة والخصوبة والصحة النسائية'
    
    # Baby & Kids
    if any(k in title_lower for k in ['رضيع', 'رضاعة', 'طفل', 'أطفال', 'فطام', 'تسنين', 'حفاض', 'تطعيم', 'نوم الرضيع', 'حديث الولادة', 'مولود', 'تربية']):
        return 'رعاية الرضيع والأمومة والطفل'
    
    # Beauty, Skin & Hair
    if any(k in title_lower for k in ['بشرة', 'شعر', 'وجه', 'مكياج', 'تجميل', 'كولاجين', 'سيروم', 'حب الشباب', 'تقشير', 'أظافر', 'كيراتين', 'ماسك', 'كريم', 'خلطة', 'هالات']):
        return 'الجمال والعناية بالبشرة والشعر'
        
    # Marriage & Relationships
    if any(k in title_lower for k in ['زوج', 'زوجة', 'زواج', 'علاقة', 'خلافات', 'خطوبة', 'معاشرة', 'عروس', 'حبيب', 'شريك', 'حب', 'رومانسية']):
        return 'العلاقات الزوجية والحياة الأسرية'
        
    # Health, Diet & Nutrition
    if any(k in title_lower for k in ['رجيم', 'دايت', 'وزن', 'تغذية', 'سعرات', 'صحة', 'فيتامين', 'أعشاب', 'مناعة', 'سكر', 'ضغط', 'التهاب', 'قولون', 'معدة', 'صداع', 'نوم', 'تمارين']):
        return 'الصحة والرشاقة والتغذية'
        
    # Cooking & Kitchen & Decor
    if any(k in title_lower for k in ['طبخ', 'وصفة', 'أكلة', 'كيك', 'حلوى', 'شوربة', 'سلطة', 'تنظيف', 'ديكور', 'منزل', 'مطبخ', 'طريقة عمل', 'دجاج', 'لحم', 'حلويات']):
        return 'المطبخ والمنزل والوصفات'
        
    return 'لايف ستايل وتطوير الذات وثقافة عامة'

def main():
    sitemaps = [f'https://malekah.info/sitemap-posts-{i}.xml' for i in range(1, 16)]
    all_articles = []
    seen_ids = set()
    domain_counts = Counter()
    domain_groups = defaultdict(list)
    
    for sm in sitemaps:
        try:
            xml_data = fetch(sm)
            url_blocks = re.findall(r'<url>(.*?)</url>', xml_data, re.DOTALL)
            
            for block in url_blocks:
                loc_match = re.search(r'<loc>(https://malekah\.info/[^<]+)</loc>', block)
                if not loc_match:
                    continue
                url = loc_match.group(1)
                lastmod_match = re.search(r'<lastmod>([^<]+)</lastmod>', block)
                lastmod = lastmod_match.group(1) if lastmod_match else ''
                
                parts = url.split('/')
                if len(parts) >= 5:
                    article_id = parts[4]
                    raw_slug = parts[5] if len(parts) > 5 else ''
                else:
                    article_id = parts[-1]
                    raw_slug = parts[-1]
                
                if article_id in seen_ids:
                    continue
                seen_ids.add(article_id)
                
                title = clean_arabic_title(raw_slug)
                if not title or title.isdigit():
                    title = f"مقال رقم {article_id}"
                    
                domain = categorize_title(title)
                domain_counts[domain] += 1
                
                item = {
                    'id': article_id,
                    'title': title,
                    'domain': domain,
                    'url': url,
                    'lastmod': lastmod
                }
                all_articles.append(item)
                domain_groups[domain].append(item)
        except Exception as e:
            pass
            
    output_path = r'C:\nabda_app\assets\data\malekah_articles_catalog.json'
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump({
            'total_articles': len(all_articles),
            'domain_distribution': dict(domain_counts),
            'articles': all_articles
        }, f, ensure_ascii=False, indent=2)
        
    # Generate an analysis summary file
    summary_path = r'C:\nabda_app\assets\data\malekah_gap_analysis.json'
    with open(summary_path, 'w', encoding='utf-8') as f:
        json.dump({
            'total_articles': len(all_articles),
            'domains': {
                d: {
                    'count': len(domain_groups[d]),
                    'percentage': round(len(domain_groups[d]) / len(all_articles) * 100, 2),
                    'sample_titles': [x['title'] for x in domain_groups[d][:20]]
                }
                for d in domain_groups
            }
        }, f, ensure_ascii=False, indent=2)
        
    print(f"SUCCESS_SAVED_{len(all_articles)}")

if __name__ == '__main__':
    main()
