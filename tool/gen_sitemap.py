#!/usr/bin/env python3
"""يولّد خرائط الموقع لـ nabda.online:
   web/sitemap.xml (فهرس) + sitemap-pages.xml + sitemap-articles.xml
   (sitemap-products.xml تولّده Cloud Function «sitemapProducts» حيّاً من Firestore)
تشغيل: python tool/gen_sitemap.py"""
import json, datetime, os
ROOT = os.path.join(os.path.dirname(__file__), '..', 'web')
BASE = 'https://nabda.online'
today = datetime.date.today().isoformat()
MED = {'health_diseases_prevention','preg_health_tests','fert_pcos_hormones','fert_ivf_medical','baby_health_care'}

def urlset(urls):
    out = ['<?xml version="1.0" encoding="UTF-8"?>', '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">']
    for loc, pr, fq in urls:
        out.append(f'  <url><loc>{loc}</loc><lastmod>{today}</lastmod><changefreq>{fq}</changefreq><priority>{pr}</priority></url>')
    out.append('</urlset>')
    return '\n'.join(out) + '\n'

pages = [(BASE + '/', '1.0', 'daily')] + [(BASE + p, pr, f) for p, pr, f in [
    ('/pregnancy', '0.9', 'weekly'), ('/baby', '0.9', 'weekly'), ('/cycle', '0.8', 'monthly'), ('/fertility', '0.8', 'monthly'),
    ('/community', '0.6', 'daily'), ('/shop', '0.9', 'daily'), ('/articles', '0.8', 'daily'),
    ('/tools/due-date.html', '0.7', 'monthly'), ('/tools/ovulation.html', '0.7', 'monthly'), ('/tools/fetus-size.html', '0.7', 'monthly'), ('/tools/baby-names.html', '0.7', 'monthly'), ('/fiqh', '0.7', 'monthly'), ('/qadaa', '0.6', 'monthly'),
    ('/privacy.html', '0.2', 'yearly'), ('/terms.html', '0.2', 'yearly')]]
pages += [(f'{BASE}/pregnancy/week-{w}', '0.8', 'monthly') for w in range(1, 43)]
pages += [(f'{BASE}/baby/month-{m}', '0.7', 'monthly') for m in range(0, 25)]
cats = ['pregnancy', 'baby', 'beauty', 'fertility', 'health', 'marriage']
pages += [(f'{BASE}/articles?cat={c}', '0.6', 'weekly') for c in cats]

arts = []
for c in cats:
    p = os.path.join(ROOT, 'data', 'articles', f'index_{c}.json')
    if os.path.exists(p):
        arts += [(f'{BASE}/article/{a["id"]}', '0.6', 'monthly') for a in json.load(open(p, encoding='utf-8')) if a.get('s') not in MED]

open(os.path.join(ROOT, 'sitemap-pages.xml'), 'w', encoding='utf-8').write(urlset(pages))
open(os.path.join(ROOT, 'sitemap-articles.xml'), 'w', encoding='utf-8').write(urlset(arts))
idx = ['<?xml version="1.0" encoding="UTF-8"?>', '<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">']
# أضيفي 'sitemap-products.xml' هنا عند تفعيل Cloud Functions (خطة Blaze)
for n in ['sitemap-pages.xml', 'sitemap-articles.xml']:
    idx.append(f'  <sitemap><loc>{BASE}/{n}</loc><lastmod>{today}</lastmod></sitemap>')
idx.append('</sitemapindex>')
open(os.path.join(ROOT, 'sitemap.xml'), 'w', encoding='utf-8').write('\n'.join(idx) + '\n')
print(f'pages={len(pages)} articles={len(arts)}')
