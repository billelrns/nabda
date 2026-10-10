# -*- coding: utf-8 -*-
from curl_cffi import requests
import sys
import time

sys.stdout.reconfigure(encoding='utf-8')

for aid in ['123982', '123572', '122364', '123545', '124523']:
    url = f"https://malekah.info/Article/{aid}/"
    t0 = time.time()
    try:
        r = requests.get(url, impersonate='chrome120', timeout=10)
        dt = time.time() - t0
        print(f"ID {aid}: status={r.status_code}, time={dt:.2f}s, len={len(r.text)}")
    except Exception as e:
        dt = time.time() - t0
        print(f"ID {aid}: error={e}, time={dt:.2f}s")
