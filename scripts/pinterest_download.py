"""
Pinterest Browser Scraper - Step 1: Extract image URLs using browser
This script will be called by the browser subagent to extract Pinterest image URLs.
It processes the URLs collected by the browser and downloads them.
"""
import json, sys, io, hashlib, os, time, random, urllib.request
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.stdout.reconfigure(line_buffering=True)

OUTPUT_DIR = r'c:\nabda_app\assets\images\pinterest_articles'
URLS_FILE = r'c:\nabda_app\scripts\pinterest_urls.json'

def download_image(url, min_size=10000):
    """Download image from URL."""
    try:
        req = urllib.request.Request(url, headers={
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Referer': 'https://www.pinterest.com/',
            'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
        })
        resp = urllib.request.urlopen(req, timeout=20)
        data = resp.read()
        if len(data) >= min_size:
            return data
    except Exception as e:
        pass
    return None

# Load URLs collected by browser
if not os.path.exists(URLS_FILE):
    print("ERROR: No URLs file found. Run browser collection first.", flush=True)
    sys.exit(1)

with open(URLS_FILE, 'r', encoding='utf-8') as f:
    url_data = json.load(f)

# url_data format: { "tag_name": ["url1", "url2", ...], ... }

# Load articles to build assignment map
with open(r'c:\nabda_app\assets\data\smart_100_articles.json', 'r', encoding='utf-8') as f:
    articles = json.load(f)['articles']

tag_groups = {}
for art in articles:
    tag = art.get('photoTag', 'general')
    num = int(art['id'].replace('smart_', ''))
    tag_groups.setdefault(tag, []).append(num)

# Download and assign
assignment = {}
used_hashes = set()
total = 0

for tag, nums in sorted(tag_groups.items(), key=lambda x: -len(x[1])):
    urls = url_data.get(tag, [])
    print(f"\n[{tag}] Need: {len(nums)} | URLs available: {len(urls)}", flush=True)
    
    img_idx = 0
    for num in sorted(nums):
        downloaded = False
        while img_idx < len(urls) and not downloaded:
            url = urls[img_idx]
            img_idx += 1
            img_data = download_image(url)
            if img_data:
                h = hashlib.md5(img_data).hexdigest()
                if h not in used_hashes:
                    assignment[num] = img_data
                    used_hashes.add(h)
                    downloaded = True
                    total += 1
                    print(f"  ✅ art_{num:03d}.jpg ({len(img_data)} bytes)", flush=True)
        
        if not downloaded:
            print(f"  ❌ art_{num:03d}.jpg - no image", flush=True)

# Fill gaps with Picsum
missing = [n for n in range(1, 101) if n not in assignment]
if missing:
    print(f"\nFilling {len(missing)} gaps with Picsum...", flush=True)
    pids = list(range(1, 1085))
    random.shuffle(pids)
    pi = 0
    for num in missing:
        done = False
        while not done and pi < len(pids):
            pid = pids[pi]; pi += 1
            url = f'https://picsum.photos/id/{pid}/800/530'
            img_data = download_image(url, 8000)
            if img_data:
                h = hashlib.md5(img_data).hexdigest()
                if h not in used_hashes:
                    assignment[num] = img_data
                    used_hashes.add(h)
                    done = True
                    total += 1
                    print(f"  ✅ art_{num:03d}.jpg fallback (picsum/{pid})", flush=True)
            time.sleep(0.3)

# Save
for num in range(1, 101):
    if num in assignment:
        path = os.path.join(OUTPUT_DIR, f'art_{num:03d}.jpg')
        with open(path, 'wb') as f:
            f.write(assignment[num])

# Validate
files = sorted(os.listdir(OUTPUT_DIR))
hashes = set()
for f in files:
    with open(os.path.join(OUTPUT_DIR, f), 'rb') as fh:
        hashes.add(hashlib.md5(fh.read()).hexdigest())

print(f"\n{'='*50}", flush=True)
print(f"Total files: {len(files)}", flush=True)
print(f"Unique: {len(hashes)}", flush=True)
print(f"{'='*50}", flush=True)
