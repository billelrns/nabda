# -*- coding: utf-8 -*-
from curl_cffi import requests
import json
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

url = 'https://malekah.info/Article/120052/'
r = requests.get(url, impersonate='chrome120', timeout=20)
html = r.text

m = re.search(r'<script\s+type=[\'"]application/ld\+json[\'"][^>]*>(.*?)</script>', html, re.DOTALL)
if m:
    d = json.loads(m.group(1))
    articles = [x for x in d.get('@graph', []) if x.get('@type') == 'Article']
    if articles:
        art = articles[0]
        summary = {k: (art[k] if k != 'articleBody' else f"{len(art[k])} chars") for k in art}
        print(json.dumps(summary, ensure_ascii=False, indent=2))
