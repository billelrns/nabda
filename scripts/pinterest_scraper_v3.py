"""
Pinterest Image Scraper v3 - Uses Pinterest's internal JSON API
Strategy:
1. First visit Pinterest homepage to get session cookies
2. Use BaseSearchResource/get endpoint which returns JSON with image URLs
3. Download images from i.pinimg.com
4. Fill any gaps with Picsum fallback
"""
import json, sys, io, hashlib, os, time, random, re, urllib.request, urllib.parse
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.stdout.reconfigure(line_buffering=True)

from curl_cffi import requests as cfreq

OUTPUT_DIR = r'c:\nabda_app\assets\images\pinterest_articles'
os.makedirs(OUTPUT_DIR, exist_ok=True)

# ═══════════════════════════════════════
# Search queries per tag (English for Pinterest)
# ═══════════════════════════════════════
TAG_QUERIES = {
    'ovulation_calendar': 'ovulation fertility tracking woman planning pregnancy',
    'pcos_health': 'pcos polycystic ovary health tips diet',
    'breastfeeding': 'breastfeeding mother nursing baby bonding',
    'couple_coffee': 'couple love relationship marriage romance',
    'hair_care_curls': 'hair care treatment growth anti hair loss woman',
    'newborn_sleep': 'newborn baby sleeping peaceful crib nursery',
    'chia_seeds_bowl': 'vitamin healthy food nutrition bowl superfood',
    'baby_milestones': 'baby milestones development crawling first steps',
    'skincare_serum': 'skincare routine serum beauty products aesthetic',
    'healthy_diet': 'healthy diet food woman nutrition clean eating',
    'period_tea': 'herbal tea cozy relaxation menstrual self care',
    'ultrasound': 'pregnancy ultrasound prenatal checkup sonogram',
    'pregnancy_test': 'pregnancy test positive announcement surprise',
    'pregnant_belly': 'pregnant belly maternity photoshoot woman',
    'twin_pregnancy': 'twin babies newborn cute matching outfits',
    'baby_first_food': 'baby weaning first food nutrition infant',
    'kids_story_reading': 'mother reading child bedtime story books',
    'maternity_vitamins': 'prenatal vitamins pregnancy supplements health',
    'labor_birth': 'labor birth preparation hospital natural',
    'dark_circles': 'under eye care dark circles treatment skincare',
    'teething_baby': 'baby teething toys remedies infant',
    'stretch_marks': 'stretch marks body care treatment skin',
    'natural_mask': 'natural face mask diy herbal remedies skin',
}

def pinterest_search(session, query, num_images=20):
    """Search Pinterest using internal API and return image URLs."""
    
    # Method 1: Use the search page and parse embedded JSON
    search_url = f'https://www.pinterest.com/search/pins/?q={urllib.parse.quote(query)}'
    
    try:
        resp = session.get(search_url, timeout=25)
        html = resp.text
    except Exception as e:
        print(f"    Search error: {e}", flush=True)
        return []
    
    image_urls = []
    
    # Parse __PWS_DATA__ JSON blob
    pws_match = re.search(r'<script\s+id=["\']__PWS_DATA__["\']\s+type=["\']application/json["\']>\s*({.*?})\s*</script>', html, re.DOTALL)
    if pws_match:
        try:
            pws_raw = pws_match.group(1)
            # Find all pinimg.com URLs in the JSON
            urls_in_json = re.findall(r'https://i\.pinimg\.com/(?:originals|736x|564x|474x)/[a-f0-9]{2}/[a-f0-9]{2}/[a-f0-9]{2}/[a-f0-9]+\.\w+', pws_raw)
            for u in urls_in_json:
                # Upgrade to 736x quality
                upgraded = re.sub(r'/(?:236x|474x|564x)/', '/736x/', u)
                if upgraded not in image_urls:
                    image_urls.append(upgraded)
        except Exception:
            pass
    
    # Fallback: find all pinimg URLs in the entire HTML
    if len(image_urls) < 3:
        all_urls = re.findall(r'https://i\.pinimg\.com/(?:originals|736x|564x|474x)/[^\s"\'<>]+\.(?:jpg|jpeg|png|webp)', html)
        for u in all_urls:
            upgraded = re.sub(r'/(?:236x|474x|564x)/', '/736x/', u)
            if upgraded not in image_urls:
                image_urls.append(upgraded)
    
    # Deduplicate by filename
    seen_files = set()
    unique = []
    for u in image_urls:
        fname = u.split('/')[-1]
        if fname not in seen_files:
            seen_files.add(fname)
            unique.append(u)
    
    return unique[:num_images]


def download_image(session, url, min_size=10000):
    """Download an image. Returns bytes or None."""
    try:
        resp = session.get(url, timeout=20)
        if len(resp.content) >= min_size:
            return resp.content
    except Exception:
        pass
    return None


# ═══════════════════════════════════════
# MAIN
# ═══════════════════════════════════════
print("="*60, flush=True)
print("Pinterest Image Scraper v3", flush=True)
print("="*60, flush=True)

# Create session with Chrome impersonation
session = cfreq.Session(impersonate="chrome120")
session.headers.update({
    'Accept-Language': 'en-US,en;q=0.9',
    'Sec-Fetch-Dest': 'document',
    'Sec-Fetch-Mode': 'navigate',
    'Sec-Fetch-Site': 'none',
    'Sec-Fetch-User': '?1',
})

# Visit homepage first to get cookies
print("\n🌐 Visiting Pinterest homepage for cookies...", flush=True)
try:
    home_resp = session.get('https://www.pinterest.com/', timeout=20)
    print(f"  Homepage status: {home_resp.status_code}", flush=True)
    time.sleep(2)
except Exception as e:
    print(f"  Homepage error: {e}", flush=True)

# Load articles
with open(r'c:\nabda_app\assets\data\smart_100_articles.json', 'r', encoding='utf-8') as f:
    articles = json.load(f)['articles']

tag_groups = {}
for art in articles:
    tag = art.get('photoTag', 'general')
    num = int(art['id'].replace('smart_', ''))
    tag_groups.setdefault(tag, []).append(num)

print(f"\n📋 {len(articles)} articles, {len(tag_groups)} topics\n", flush=True)

# Search and download
assignment = {}  # num -> bytes
used_hashes = set()
all_collected_urls = {}  # tag -> [urls]
total_pinterest = 0

for tag_idx, (tag, nums) in enumerate(sorted(tag_groups.items(), key=lambda x: -len(x[1]))):
    needed = len(nums)
    query = TAG_QUERIES.get(tag, tag.replace('_', ' '))
    
    print(f"{'─'*60}", flush=True)
    print(f"[{tag_idx+1}/{len(tag_groups)}] {tag} | Need: {needed} | Query: {query}", flush=True)
    
    # Search Pinterest
    urls = pinterest_search(session, query, num_images=needed + 5)
    all_collected_urls[tag] = urls
    print(f"  Found {len(urls)} image URLs", flush=True)
    
    # Download and assign
    url_idx = 0
    for num in sorted(nums):
        downloaded = False
        while url_idx < len(urls) and not downloaded:
            url = urls[url_idx]
            url_idx += 1
            img_data = download_image(session, url)
            if img_data:
                h = hashlib.md5(img_data).hexdigest()
                if h not in used_hashes:
                    assignment[num] = img_data
                    used_hashes.add(h)
                    downloaded = True
                    total_pinterest += 1
                    print(f"  ✅ art_{num:03d}.jpg ({len(img_data):,} bytes) from Pinterest", flush=True)
        
        if not downloaded:
            print(f"  ⏳ art_{num:03d}.jpg - pending (will use fallback)", flush=True)
    
    # Rate limit between topic searches
    delay = random.uniform(3.0, 5.0)
    print(f"  ⏱️  Waiting {delay:.1f}s...", flush=True)
    time.sleep(delay)

print(f"\n{'='*60}", flush=True)
print(f"Pinterest results: {total_pinterest}/100 images downloaded", flush=True)

# ═══════════════════════════════════════
# FALLBACK: Picsum for gaps
# ═══════════════════════════════════════
missing = sorted([n for n in range(1, 101) if n not in assignment])
if missing:
    print(f"\n🔄 Filling {len(missing)} gaps with Lorem Picsum...", flush=True)
    
    pids = list(range(1, 1085))
    random.shuffle(pids)
    pi = 0
    
    for num in missing:
        done = False
        attempts = 0
        while not done and pi < len(pids) and attempts < 10:
            pid = pids[pi]; pi += 1; attempts += 1
            try:
                url = f'https://picsum.photos/id/{pid}/800/530'
                req = urllib.request.Request(url, headers={
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
                })
                resp = urllib.request.urlopen(req, timeout=15)
                img_data = resp.read()
                if len(img_data) > 8000:
                    h = hashlib.md5(img_data).hexdigest()
                    if h not in used_hashes:
                        assignment[num] = img_data
                        used_hashes.add(h)
                        done = True
                        print(f"  ✅ art_{num:03d}.jpg (picsum/{pid})", flush=True)
            except Exception:
                pass
            time.sleep(0.3)
        
        if not done:
            print(f"  ❌ art_{num:03d}.jpg FAILED", flush=True)

# ═══════════════════════════════════════
# SAVE
# ═══════════════════════════════════════
print(f"\n💾 Saving images...", flush=True)

# Clear existing
for f in os.listdir(OUTPUT_DIR):
    fp = os.path.join(OUTPUT_DIR, f)
    if os.path.isfile(fp):
        os.remove(fp)

written = 0
for num in range(1, 101):
    if num in assignment:
        path = os.path.join(OUTPUT_DIR, f'art_{num:03d}.jpg')
        with open(path, 'wb') as f:
            f.write(assignment[num])
        written += 1

# ═══════════════════════════════════════
# VALIDATE
# ═══════════════════════════════════════
files = sorted(os.listdir(OUTPUT_DIR))
hashes = {}
dupes = []
for f in files:
    with open(os.path.join(OUTPUT_DIR, f), 'rb') as fh:
        h = hashlib.md5(fh.read()).hexdigest()
    if h in hashes:
        dupes.append((f, hashes[h]))
    else:
        hashes[h] = f

missing_final = [n for n in range(1, 101) if f'art_{n:03d}.jpg' not in files]

print(f"\n{'='*60}", flush=True)
print(f"FINAL RESULTS", flush=True)
print(f"{'='*60}", flush=True)
print(f"  Pinterest images: {total_pinterest}", flush=True)
print(f"  Picsum fallback:  {written - total_pinterest}", flush=True)
print(f"  Total files:      {len(files)}", flush=True)
print(f"  Unique images:    {len(hashes)}", flush=True)
print(f"  Duplicates:       {len(dupes)}", flush=True)
print(f"  Missing:          {len(missing_final)}", flush=True)

if len(files) == 100 and len(hashes) == 100:
    print(f"\n🎉 SUCCESS! 100 unique images in pinterest_articles!", flush=True)

# Save URL collection log
with open(r'c:\nabda_app\scripts\pinterest_urls_log.json', 'w', encoding='utf-8') as f:
    json.dump(all_collected_urls, f, ensure_ascii=False, indent=2)
print(f"\nURL log saved to pinterest_urls_log.json", flush=True)
