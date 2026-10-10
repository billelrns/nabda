# -*- coding: utf-8 -*-
from curl_cffi import requests
import json
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

for aid in ['124460', '122893', '123513', '123982', '123572']:
    url = f"https://malekah.info/Article/{aid}/"
    try:
        r = requests.get(url, impersonate='chrome120', timeout=15)
        m = re.search(r'<script\s+type=[\'"]application/ld\+json[\'"][^>]*>(.*?)</script>', r.text, re.DOTALL)
        if m:
            raw_json = m.group(1)
            # Try strict=False
            d = json.loads(raw_json, strict=False)
            arts = [x for x in d.get('@graph', []) if x.get('@type') == 'Article']
            if arts:
                art = arts[0]
                print(f"SUCCESS {aid}: name={art.get('name')[:35]} | body={len(art.get('articleBody',''))} chars | image={art.get('image')}")
            else:
                print(f"FAILED {aid}: No Article in graph")
        else:
            print(f"FAILED {aid}: No script tag")
    except Exception as e:
        print(f"ERROR {aid}: {e}")
