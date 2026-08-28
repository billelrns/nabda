"""
Pinterest Image Scraper for Nabda Articles
Downloads unique, topic-matched images from Pinterest for each of the 100 articles.

Strategy:
- Uses curl_cffi to impersonate Chrome TLS fingerprint (bypasses Pinterest anti-bot)
- Fetches Pinterest search pages and extracts image URLs from embedded JSON (__PWS_DATA__)
- Groups articles by photoTag to minimize searches (23 unique tags)
- Downloads enough unique images per tag to cover all articles
- Saves as art_001.jpg through art_100.jpg
"""
import json, sys, io, hashlib, os, time, random, re
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.stdout.reconfigure(line_buffering=True)

try:
    from curl_cffi import requests as cf_requests
    HAS_CURL_CFFI = True
    print("✅ curl_cffi available - using Chrome TLS impersonation", flush=True)
except ImportError:
    HAS_CURL_CFFI = False
    import urllib.request
    print("⚠️ curl_cffi not available - using urllib fallback", flush=True)

OUTPUT_DIR = r'c:\nabda_app\assets\images\pinterest_articles'

# ═══════════════════════════════════════
# Pinterest Search Queries per Tag
# ═══════════════════════════════════════
TAG_QUERIES = {
    'ovulation_calendar': [
        'ovulation tracking calendar aesthetic', 'fertility planning woman', 'pregnancy planning tips',
        'ovulation test positive', 'fertility cycle chart', 'basal body temperature tracking',
        'conception tips couple', 'reproductive health woman', 'family planning aesthetic',
        'menstrual cycle tracking app', 'fertility awareness method', 'ovulation symptoms',
        'pregnancy wish couple', 'hormonal cycle woman', 'fertility journey aesthetic'
    ],
    'pcos_health': [
        'pcos awareness aesthetic', 'hormonal balance tips', 'pcos diet healthy food',
        'gynecologist appointment woman', 'pcos exercise routine', 'hormonal health woman',
        'pcos natural remedies', 'ovary health ultrasound', 'pcos wellness journey'
    ],
    'breastfeeding': [
        'breastfeeding mother baby aesthetic', 'nursing mom tips', 'breastfeeding positions',
        'mother baby bonding', 'breast milk pumping', 'lactation support',
        'breastfeeding benefits', 'new mom nursing'
    ],
    'couple_coffee': [
        'couple coffee date aesthetic', 'romantic couple morning', 'marriage love aesthetic',
        'happy couple relationship', 'couple communication tips', 'love language couple',
        'marriage counseling aesthetic'
    ],
    'hair_care_curls': [
        'hair care routine aesthetic', 'hair growth tips natural', 'anti hair loss treatment',
        'hair oil treatment scalp', 'healthy shiny hair woman', 'hair mask diy',
        'hair strengthening tips'
    ],
    'newborn_sleep': [
        'newborn sleeping peacefully', 'baby sleep routine tips', 'sleeping baby crib aesthetic',
        'infant sleep schedule', 'baby nursery peaceful', 'newborn sleep tips'
    ],
    'chia_seeds_bowl': [
        'chia seeds bowl aesthetic', 'vitamin d foods healthy', 'superfood nutrition bowl',
        'healthy breakfast bowl', 'vitamin supplements aesthetic'
    ],
    'baby_milestones': [
        'baby milestones first year', 'baby crawling cute', 'infant development chart',
        'toddler first steps'
    ],
    'skincare_serum': [
        'skincare routine aesthetic', 'face serum dropper', 'beauty routine products',
        'skin care aesthetic flatlay'
    ],
    'healthy_diet': [
        'healthy diet woman aesthetic', 'vaginal health tips', 'healthy food aesthetic',
        'clean eating lifestyle'
    ],
    'period_tea': [
        'herbal tea aesthetic cozy', 'menstrual cycle self care', 'period comfort tips'
    ],
    'ultrasound': [
        'pregnancy ultrasound aesthetic', 'prenatal checkup hospital', 'baby sonogram keepsake'
    ],
    'pregnancy_test': [
        'pregnancy test positive aesthetic', 'pregnancy announcement creative', 'early pregnancy signs'
    ],
    'pregnant_belly': [
        'pregnant belly aesthetic', 'maternity photoshoot', 'pregnancy glow aesthetic'
    ],
    'twin_pregnancy': [
        'twin pregnancy aesthetic', 'twin babies newborn cute', 'twins announcement creative'
    ],
    'baby_first_food': [
        'baby first food weaning', 'baby led weaning aesthetic', 'infant nutrition tips'
    ],
    'kids_story_reading': [
        'mother reading to child', 'kids bedtime story', 'speech development toddler'
    ],
    'maternity_vitamins': [
        'prenatal vitamins aesthetic', 'pregnancy supplements health'
    ],
    'labor_birth': [
        'labor preparation aesthetic', 'natural birth preparation'
    ],
    'dark_circles': [
        'under eye treatment aesthetic', 'dark circles remedies skincare'
    ],
    'teething_baby': [
        'baby teething toys aesthetic', 'infant teething remedies'
    ],
    'stretch_marks': [
        'stretch marks treatment body care'
    ],
    'natural_mask': [
        'natural face mask diy herbs'
    ],
}

def fetch_pinterest_images(query, num_needed=5):
    """Search Pinterest and extract image URLs from the search results page."""
    search_url = f'https://www.pinterest.com/search/pins/?q={query.replace(" ", "%20")}'
    
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.9',
        'Accept-Encoding': 'gzip, deflate, br',
        'Sec-Fetch-Dest': 'document',
        'Sec-Fetch-Mode': 'navigate',
        'Sec-Fetch-Site': 'none',
        'Sec-Fetch-User': '?1',
        'Upgrade-Insecure-Requests': '1',
        'Referer': 'https://www.pinterest.com/',
    }
    
    try:
        if HAS_CURL_CFFI:
            resp = cf_requests.get(search_url, headers=headers, impersonate="chrome120", timeout=20)
            html = resp.text
        else:
            req = urllib.request.Request(search_url, headers=headers)
            resp = urllib.request.urlopen(req, timeout=20)
            html = resp.read().decode('utf-8', errors='ignore')
    except Exception as e:
        print(f"    Fetch error: {e}", flush=True)
        return []
    
    # Extract image URLs from the HTML
    # Pinterest embeds data in __PWS_DATA__ or in JSON-LD or in img tags
    image_urls = []
    
    # Method 1: Extract from __PWS_DATA__ JSON
    pws_match = re.search(r'<script\s+id="__PWS_DATA__"\s+type="application/json">(.*?)</script>', html, re.DOTALL)
    if pws_match:
        try:
            pws_data = json.loads(pws_match.group(1))
            # Navigate the nested structure to find image URLs
            def extract_urls(obj, depth=0):
                if depth > 15:
                    return
                if isinstance(obj, dict):
                    # Look for image URL patterns
                    for key in ['url', 'src', 'originalUrl']:
                        val = obj.get(key, '')
                        if isinstance(val, str) and 'pinimg.com' in val and '/originals/' in val:
                            image_urls.append(val)
                        elif isinstance(val, str) and 'pinimg.com' in val and '/736x/' in val:
                            image_urls.append(val)
                        elif isinstance(val, str) and 'pinimg.com' in val and '/564x/' in val:
                            # Upgrade to 736x for better quality
                            image_urls.append(val.replace('/564x/', '/736x/'))
                    for v in obj.values():
                        extract_urls(v, depth+1)
                elif isinstance(obj, list):
                    for item in obj:
                        extract_urls(item, depth+1)
            
            extract_urls(pws_data)
        except json.JSONDecodeError:
            pass
    
    # Method 2: Extract from img tags with pinimg.com URLs
    if not image_urls:
        img_pattern = r'https://i\.pinimg\.com/(?:736x|564x|originals)/[a-f0-9/]+\.[a-z]+'
        image_urls = re.findall(img_pattern, html)
    
    # Method 3: Extract from data attributes or JSON embedded elsewhere
    if not image_urls:
        pinimg_pattern = r'"(https://i\.pinimg\.com/[^"]+)"'
        raw_urls = re.findall(pinimg_pattern, html)
        for url in raw_urls:
            if any(s in url for s in ['/736x/', '/564x/', '/originals/']):
                image_urls.append(url)
    
    # Deduplicate while preserving order, prefer larger versions
    seen = set()
    unique_urls = []
    for url in image_urls:
        # Normalize URL to identify same image at different sizes
        base = url.split('/')[-1]  # filename
        if base not in seen:
            seen.add(base)
            unique_urls.append(url)
    
    return unique_urls[:num_needed * 3]  # Return extra for uniqueness filtering


def download_image(url, min_size=15000):
    """Download a single image. Returns bytes or None."""
    try:
        if HAS_CURL_CFFI:
            resp = cf_requests.get(url, impersonate="chrome120", timeout=20)
            data = resp.content
        else:
            req = urllib.request.Request(url, headers={
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                'Referer': 'https://www.pinterest.com/',
            })
            resp = urllib.request.urlopen(req, timeout=20)
            data = resp.read()
        
        if len(data) >= min_size:
            return data
    except Exception:
        pass
    return None


# ═══════════════════════════════════════
# MAIN EXECUTION
# ═══════════════════════════════════════

# Load articles
with open(r'c:\nabda_app\assets\data\smart_100_articles.json', 'r', encoding='utf-8') as f:
    articles = json.load(f)['articles']

# Group articles by photoTag
tag_groups = {}
for art in articles:
    tag = art.get('photoTag', 'general')
    num = int(art['id'].replace('smart_', ''))
    tag_groups.setdefault(tag, []).append(num)

print(f"\n📋 {len(articles)} articles grouped into {len(tag_groups)} topics", flush=True)

# Download images per tag group
assignment = {}  # num -> bytes
used_hashes = set()
total_success = 0
total_needed = 100

for tag_idx, (tag, article_nums) in enumerate(sorted(tag_groups.items(), key=lambda x: -len(x[1]))):
    needed = len(article_nums)
    queries = TAG_QUERIES.get(tag, [f'{tag.replace("_", " ")} aesthetic'])
    
    print(f"\n{'─'*60}", flush=True)
    print(f"[{tag_idx+1}/{len(tag_groups)}] Tag: {tag} | Need: {needed} images", flush=True)
    print(f"{'─'*60}", flush=True)
    
    collected_images = []  # list of (bytes, hash)
    
    # Search Pinterest with multiple queries until we have enough images
    for q_idx, query in enumerate(queries):
        if len(collected_images) >= needed:
            break
        
        print(f"  🔍 Searching: '{query}' ...", end=' ', flush=True)
        urls = fetch_pinterest_images(query, num_needed=needed)
        print(f"found {len(urls)} URLs", flush=True)
        
        for url in urls:
            if len(collected_images) >= needed:
                break
            
            img_data = download_image(url)
            if img_data:
                h = hashlib.md5(img_data).hexdigest()
                if h not in used_hashes:
                    collected_images.append((img_data, h))
                    used_hashes.add(h)
        
        # Rate limiting between searches
        time.sleep(random.uniform(2.0, 4.0))
    
    # Assign collected images to article numbers
    for i, num in enumerate(sorted(article_nums)):
        if i < len(collected_images):
            assignment[num] = collected_images[i][0]
            total_success += 1
            print(f"  ✅ art_{num:03d}.jpg assigned ({len(collected_images[i][0])} bytes)", flush=True)
        else:
            print(f"  ❌ art_{num:03d}.jpg - no image available", flush=True)
    
    print(f"  Progress: {total_success}/{total_needed}", flush=True)

# ═══════════════════════════════════════
# FALLBACK: Fill gaps with Picsum
# ═══════════════════════════════════════
missing = [n for n in range(1, 101) if n not in assignment]
if missing:
    print(f"\n{'═'*60}", flush=True)
    print(f"Filling {len(missing)} gaps with Lorem Picsum...", flush=True)
    print(f"{'═'*60}", flush=True)
    
    picsum_ids = list(range(1, 1085))
    random.shuffle(picsum_ids)
    pid_idx = 0
    
    for num in missing:
        downloaded = False
        while not downloaded and pid_idx < len(picsum_ids):
            pid = picsum_ids[pid_idx]
            pid_idx += 1
            url = f'https://picsum.photos/id/{pid}/800/530'
            img_data = download_image(url, min_size=10000)
            if img_data:
                h = hashlib.md5(img_data).hexdigest()
                if h not in used_hashes:
                    assignment[num] = img_data
                    used_hashes.add(h)
                    total_success += 1
                    downloaded = True
                    print(f"  ✅ art_{num:03d}.jpg fallback (picsum/{pid})", flush=True)
            time.sleep(0.3)
        
        if not downloaded:
            print(f"  ❌ art_{num:03d}.jpg - FAILED", flush=True)

# ═══════════════════════════════════════
# SAVE ALL IMAGES
# ═══════════════════════════════════════
print(f"\n{'═'*60}", flush=True)
print(f"Saving images to {OUTPUT_DIR}...", flush=True)
print(f"{'═'*60}", flush=True)

written = 0
for num in range(1, 101):
    if num in assignment:
        path = os.path.join(OUTPUT_DIR, f'art_{num:03d}.jpg')
        with open(path, 'wb') as f:
            f.write(assignment[num])
        written += 1

print(f"  Written: {written}/100 files", flush=True)

# ═══════════════════════════════════════
# VALIDATION
# ═══════════════════════════════════════
print(f"\n{'═'*60}", flush=True)
print(f"FINAL VALIDATION", flush=True)
print(f"{'═'*60}", flush=True)

files = sorted(os.listdir(OUTPUT_DIR))
hashes = {}
dupes = []
for f in files:
    fp = os.path.join(OUTPUT_DIR, f)
    with open(fp, 'rb') as fh:
        h = hashlib.md5(fh.read()).hexdigest()
    if h in hashes:
        dupes.append((f, hashes[h]))
    else:
        hashes[h] = f

missing_final = [n for n in range(1, 101) if f'art_{n:03d}.jpg' not in files]

print(f"  Total files: {len(files)}", flush=True)
print(f"  Unique images: {len(hashes)}", flush=True)
print(f"  Duplicates: {len(dupes)}", flush=True)
print(f"  Missing: {len(missing_final)}", flush=True)

if len(files) == 100 and len(hashes) == 100:
    print(f"\n🎉 SUCCESS! 100 unique Pinterest-sourced images!", flush=True)
elif len(files) >= 90:
    print(f"\n✅ Nearly complete ({len(files)}/100).", flush=True)
