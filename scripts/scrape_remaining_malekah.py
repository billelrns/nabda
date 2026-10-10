# -*- coding: utf-8 -*-
"""
High-Performance Resumable Scraper for Remaining Malekah.info Articles
Optimized with:
- curl_cffi Chrome 120 impersonation
- json.loads(..., strict=False) to handle raw unescaped newlines in JSON-LD
- Robust regex fallback for articleBody extraction
- 18 async workers via continuous asyncio.Queue
- Resumable checkpointing every 50 articles to malekah_remaining_raw.json
"""
import asyncio
import json
import os
import re
import sys
import random
import time
from datetime import datetime
from curl_cffi.requests import AsyncSession

sys.stdout.reconfigure(encoding='utf-8', line_buffering=True)

CATALOG_PATH = 'C:/nabda_app/assets/data/malekah_articles_catalog.json'
SMART_2500_PATH = 'C:/nabda_app/assets/data/smart_2500_articles.json'
OUTPUT_RAW_PATH = 'C:/nabda_app/assets/data/malekah_remaining_raw.json'
OTHER_RAW_FILES = [
    'C:/nabda_app/assets/data/malekah_raw_articles.json',
    'C:/nabda_app/assets/data/malekah_1000_raw.json',
    'C:/nabda_app/assets/data/malekah_batch3_raw.json'
]

HEADERS = {
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8",
    "Accept-Language": "ar,en-US;q=0.9,en;q=0.8",
    "Sec-Fetch-Dest": "document",
    "Sec-Fetch-Mode": "navigate",
    "Sec-Fetch-Site": "none",
    "Sec-Fetch-User": "?1",
    "Upgrade-Insecure-Requests": "1"
}

NUM_WORKERS = 18
SAVE_EVERY = 50

def load_data():
    with open(CATALOG_PATH, 'r', encoding='utf-8') as f:
        catalog = json.load(f)['articles']
    cat_by_id = {str(a['id']).strip(): a for a in catalog}

    with open(SMART_2500_PATH, 'r', encoding='utf-8') as f:
        smart = json.load(f)['articles']
    smart_ids = {str(a.get('originalId', '')).strip() for a in smart if a.get('originalId')}

    current_scraped = {}
    # Load already saved in output raw file
    if os.path.exists(OUTPUT_RAW_PATH):
        try:
            with open(OUTPUT_RAW_PATH, 'r', encoding='utf-8') as f:
                for a in json.load(f).get('articles', []):
                    aid = str(a.get('id', '')).strip()
                    if aid and len(a.get('body', '')) > 100:
                        current_scraped[aid] = a
        except Exception as e:
            print(f"Warning loading checkpoint: {e}", flush=True)

    # Load from other raw files if not already in current_scraped and not in smart_ids
    for rf in OTHER_RAW_FILES:
        if os.path.exists(rf):
            with open(rf, 'r', encoding='utf-8') as f:
                for a in json.load(f).get('articles', []):
                    aid = str(a.get('id', '')).strip()
                    if aid and aid not in smart_ids and aid not in current_scraped:
                        cat_entry = cat_by_id.get(aid, {})
                        current_scraped[aid] = {
                            'id': aid,
                            'originalId': aid,
                            'title': a.get('title', cat_entry.get('title', '')),
                            'catalogTitle': cat_entry.get('title', ''),
                            'domain': cat_entry.get('domain', ''),
                            'author': a.get('author', ''),
                            'datePublished': a.get('datePublished', cat_entry.get('lastmod', '')),
                            'imageUrl': a.get('imageUrl', ''),
                            'articleSection': a.get('articleSection', ''),
                            'url': cat_entry.get('url', f'https://malekah.info/Article/{aid}/'),
                            'body': a.get('body', ''),
                            'scrapedAt': datetime.now().isoformat()
                        }

    target_ids = [aid for aid in cat_by_id if aid not in smart_ids]
    pending_ids = [aid for aid in target_ids if aid not in current_scraped]
    return cat_by_id, target_ids, pending_ids, current_scraped

def save_checkpoint(scraped_dict):
    articles_list = list(scraped_dict.values())
    temp_path = OUTPUT_RAW_PATH + ".tmp"
    with open(temp_path, 'w', encoding='utf-8') as f:
        json.dump({'articles': articles_list, 'count': len(articles_list), 'updated_at': datetime.now().isoformat()}, f, ensure_ascii=False, indent=2)
    if os.path.exists(OUTPUT_RAW_PATH):
        os.replace(temp_path, OUTPUT_RAW_PATH)
    else:
        os.rename(temp_path, OUTPUT_RAW_PATH)

def extract_article_from_html(html, aid, cat_entry, url):
    # Method 1: JSON-LD with strict=False
    m = re.search(r'<script\s+type=[\'"]application/ld\+json[\'"][^>]*>(.*?)</script>', html, re.DOTALL)
    if m:
        try:
            d = json.loads(m.group(1), strict=False)
            for item in d.get('@graph', []):
                if item.get('@type') == 'Article':
                    body = item.get('articleBody', '')
                    if len(body) > 100:
                        return {
                            'id': aid,
                            'originalId': aid,
                            'title': item.get('name', cat_entry.get('title', '')),
                            'catalogTitle': cat_entry.get('title', ''),
                            'domain': cat_entry.get('domain', ''),
                            'author': item.get('author', ''),
                            'datePublished': item.get('datePublished', cat_entry.get('lastmod', '')),
                            'imageUrl': item.get('image', ''),
                            'articleSection': item.get('articleSection', ''),
                            'url': cat_entry.get('url', url),
                            'body': body,
                            'scrapedAt': datetime.now().isoformat()
                        }
        except Exception:
            pass

    # Method 2: Regex extraction fallback from JSON-LD or meta tags
    body_m = re.search(r'"articleBody"\s*:\s*"((?:[^"\\]|\\.)*)"', html)
    if body_m:
        raw_body = body_m.group(1).encode('utf-8').decode('unicode-escape', errors='replace')
        if len(raw_body) > 100:
            name_m = re.search(r'"name"\s*:\s*"((?:[^"\\]|\\.)*)"', html)
            title = name_m.group(1).encode('utf-8').decode('unicode-escape', errors='replace') if name_m else cat_entry.get('title', '')
            img_m = re.search(r'"image"\s*:\s*"(https?://[^"]+)"', html)
            img = img_m.group(1) if img_m else ''
            return {
                'id': aid,
                'originalId': aid,
                'title': title,
                'catalogTitle': cat_entry.get('title', ''),
                'domain': cat_entry.get('domain', ''),
                'author': '',
                'datePublished': cat_entry.get('lastmod', ''),
                'imageUrl': img,
                'articleSection': '',
                'url': cat_entry.get('url', url),
                'body': raw_body,
                'scrapedAt': datetime.now().isoformat()
            }
    return None

async def worker(worker_id, queue, session, cat_by_id, current_scraped, stats, lock):
    while True:
        try:
            aid = await queue.get()
        except asyncio.CancelledError:
            break

        cat_entry = cat_by_id.get(aid, {})
        url = f"https://malekah.info/Article/{aid}/"
        success = False
        
        await asyncio.sleep(random.uniform(0.05, 0.12))

        for attempt in range(2):
            try:
                resp = await session.get(url, headers=HEADERS, timeout=14)
                if resp.status_code == 200:
                    art = extract_article_from_html(resp.text, aid, cat_entry, url)
                    if art:
                        async with lock:
                            current_scraped[aid] = art
                            stats['success'] += 1
                            stats['recent_success'] += 1
                        success = True
                        break
                elif resp.status_code in (429, 503):
                    await asyncio.sleep(2.0 + attempt)
            except Exception:
                await asyncio.sleep(1.0)

        if not success:
            async with lock:
                stats['failed'] += 1

        # Checkpoint and status printing
        async with lock:
            if stats['recent_success'] >= SAVE_EVERY:
                save_checkpoint(current_scraped)
                stats['recent_success'] = 0
                elapsed = time.time() - stats['start_time']
                speed = stats['success'] / elapsed if elapsed > 0 else 0
                remaining = stats['total_pending'] - stats['success']
                eta_min = (remaining / speed / 60) if speed > 0 else 0
                total_ready = len(current_scraped)
                print(f"📊 [تقدم]: {total_ready}/{stats['total_targets']} مقال | تم بنجاح في الجلسة: {stats['success']} | فشل: {stats['failed']} | سرعة: {speed:.1f} مقال/ث | متبقي: {eta_min:.1f} دقيقة", flush=True)

        queue.task_done()

async def main():
    print("=" * 65, flush=True)
    print("🚀 تشغيل المكشطة المحسنة بنظام strict=False والنسخ الاحتياطي بالتعابير النمطية", flush=True)
    print("=" * 65, flush=True)

    cat_by_id, target_ids, pending_ids, current_scraped = load_data()
    print(f"إجمالي المقالات المطلوبة: {len(target_ids)}", flush=True)
    print(f"المقالات المحفوظة مسبقاً: {len(current_scraped)}", flush=True)
    print(f"المقالات المتبقية للتحميل: {len(pending_ids)}", flush=True)

    save_checkpoint(current_scraped)

    if not pending_ids:
        print("✅ جميع المقالات محملة بالكامل!", flush=True)
        return

    queue = asyncio.Queue()
    for aid in pending_ids:
        queue.put_nowait(aid)

    stats = {
        'start_time': time.time(),
        'success': 0,
        'failed': 0,
        'recent_success': 0,
        'total_targets': len(target_ids),
        'total_pending': len(pending_ids)
    }
    lock = asyncio.Lock()

    print(f"⚡ تشغيل {NUM_WORKERS} مسارات متزامنة للتحميل السريع...", flush=True)
    async with AsyncSession(impersonate="chrome120") as session:
        workers = [
            asyncio.create_task(worker(i, queue, session, cat_by_id, current_scraped, stats, lock))
            for i in range(NUM_WORKERS)
        ]

        await queue.join()

        for w in workers:
            w.cancel()
        await asyncio.gather(*workers, return_exceptions=True)

    save_checkpoint(current_scraped)
    elapsed_min = (time.time() - stats['start_time']) / 60
    print("=" * 65, flush=True)
    print(f"🎉 اكتمل جلب المقالات بنجاح خلال {elapsed_min:.2f} دقيقة!", flush=True)
    print(f"إجمالي المقالات المحفوظة في {OUTPUT_RAW_PATH}: {len(current_scraped)}", flush=True)
    print("=" * 65, flush=True)

if __name__ == '__main__':
    asyncio.run(main())
