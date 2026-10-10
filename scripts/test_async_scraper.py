# -*- coding: utf-8 -*-
import asyncio
import json
import re
import sys
import random
import time
from curl_cffi.requests import AsyncSession

sys.stdout.reconfigure(encoding='utf-8')

TEST_IDS = ["120052", "120053", "120054", "120055", "120056"]

async def fetch_article(session, aid):
    url = f"https://malekah.info/Article/{aid}/"
    headers = {
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8",
        "Accept-Language": "ar,en-US;q=0.9,en;q=0.8",
        "Sec-Fetch-Dest": "document",
        "Sec-Fetch-Mode": "navigate",
        "Sec-Fetch-Site": "none",
        "Sec-Fetch-User": "?1",
        "Upgrade-Insecure-Requests": "1"
    }
    for attempt in range(3):
        try:
            resp = await session.get(url, headers=headers, timeout=15)
            if resp.status_code == 200:
                html = resp.text
                m = re.search(r'<script\s+type=[\'"]application/ld\+json[\'"][^>]*>(.*?)</script>', html, re.DOTALL)
                if m:
                    try:
                        d = json.loads(m.group(1))
                        for item in d.get('@graph', []):
                            if item.get('@type') == 'Article':
                                return {
                                    'id': aid,
                                    'title': item.get('name', ''),
                                    'author': item.get('author', ''),
                                    'datePublished': item.get('datePublished', ''),
                                    'imageUrl': item.get('image', ''),
                                    'articleSection': item.get('articleSection', ''),
                                    'body': item.get('articleBody', ''),
                                    'success': True
                                }
                    except Exception as je:
                        pass
                return {'id': aid, 'success': False, 'error': 'No article in ld+json'}
            elif resp.status_code in (429, 503):
                await asyncio.sleep(2 ** attempt + random.uniform(0.5, 1.5))
            else:
                return {'id': aid, 'success': False, 'error': f'Status {resp.status_code}'}
        except Exception as e:
            await asyncio.sleep(1 + attempt)
    return {'id': aid, 'success': False, 'error': 'Max retries exceeded'}

async def main():
    async with AsyncSession(impersonate="chrome120") as session:
        tasks = [fetch_article(session, aid) for aid in TEST_IDS]
        results = await asyncio.gather(*tasks)
        for r in results:
            print(f"ID: {r['id']} | Success: {r['success']} | Title: {r.get('title')} | Body length: {len(r.get('body', ''))}")

if __name__ == '__main__':
    asyncio.run(main())
