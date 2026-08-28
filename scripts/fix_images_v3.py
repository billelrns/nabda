"""
Fix images - Download 62 unique images using Lorem Picsum (no API key needed).
Picsum provides beautiful, royalty-free photos with guaranteed unique IDs.
"""
import json, sys, io, hashlib, os, shutil, time, random, urllib.request
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.stdout.reconfigure(line_buffering=True)

IMG_DIR = r'c:\nabda_app\assets\images\smart_articles'
BACKUP_DIR = r'c:\nabda_app\assets\images\smart_articles_old_backup'

# ═══════════════════════════════════════
# STEP 1: Catalog existing unique images
# ═══════════════════════════════════════
print("STEP 1: Cataloging existing images...", flush=True)

source = BACKUP_DIR if os.path.exists(BACKUP_DIR) else IMG_DIR
all_content = {}
all_hashes = {}

for f in sorted(os.listdir(source)):
    fp = os.path.join(source, f)
    if not os.path.isfile(fp):
        continue
    with open(fp, 'rb') as fh:
        data = fh.read()
    h = hashlib.md5(data).hexdigest()
    all_content[f] = data
    all_hashes[f] = h

# The mass-duplicate hash (art_001.jpg = 33721 bytes, duplicated 76 times)
mass_dup_hash = all_hashes.get('art_001.jpg', '')

# Build pool of unique images (excluding mass dup)
pool = {}
pool_hashes = set()
for f in sorted(all_content.keys()):
    h = all_hashes[f]
    if h == mass_dup_hash:
        continue
    if h in pool_hashes:
        continue
    pool_hashes.add(h)
    if f.startswith('photo_'):
        tag = f.replace('photo_', '').replace('.jpg', '')
        pool[tag] = all_content[f]
    elif f.startswith('art_'):
        pool[f] = all_content[f]

print(f"  Unique images in pool: {len(pool)}", flush=True)

# ═══════════════════════════════════════
# STEP 2: Assign existing images
# ═══════════════════════════════════════
print("\nSTEP 2: Assigning existing images...", flush=True)

with open(r'c:\nabda_app\assets\data\smart_100_articles.json', 'r', encoding='utf-8') as f:
    articles = json.load(f)['articles']

assignment = {}  # num -> bytes
used_hashes = set()

# First: assign unique art_076-100
for num in range(76, 101):
    key = f'art_{num:03d}.jpg'
    if key in pool:
        h = hashlib.md5(pool[key]).hexdigest()
        if h not in used_hashes:
            assignment[num] = pool[key]
            used_hashes.add(h)

# Second: assign photo tags (first article per tag wins)
used_tags = set()
for art in articles:
    num = int(art['id'].replace('smart_', ''))
    if num in assignment:
        continue
    tag = art.get('photoTag', '')
    if tag and tag in pool and tag not in used_tags:
        content = pool[tag]
        h = hashlib.md5(content).hexdigest()
        if h not in used_hashes:
            assignment[num] = content
            used_hashes.add(h)
            used_tags.add(tag)

needs = []
for art in articles:
    num = int(art['id'].replace('smart_', ''))
    if num not in assignment:
        needs.append(num)

print(f"  Pre-assigned: {len(assignment)} articles", flush=True)
print(f"  Need download: {len(needs)} articles", flush=True)

# ═══════════════════════════════════════
# STEP 3: Download from Lorem Picsum
# ═══════════════════════════════════════
print(f"\nSTEP 3: Downloading {len(needs)} images from Lorem Picsum...", flush=True)

# Picsum has IDs from 0 to ~1084. We'll use unique IDs for each download.
# Shuffle to avoid predictable patterns
available_ids = list(range(1, 1085))
random.shuffle(available_ids)
id_index = 0

def download_picsum(picsum_id, width=800, height=530):
    """Download a specific Picsum image by ID. Returns bytes or None."""
    url = f'https://picsum.photos/id/{picsum_id}/{width}/{height}'
    try:
        req = urllib.request.Request(url, headers={
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        })
        resp = urllib.request.urlopen(req, timeout=20)
        data = resp.read()
        if len(data) > 10000:
            return data
    except Exception as e:
        pass
    return None

success = 0
failed_nums = []

for i, num in enumerate(needs):
    print(f"  [{i+1}/{len(needs)}] art_{num:03d}.jpg ... ", end='', flush=True)
    
    downloaded = False
    attempts = 0
    
    while not downloaded and attempts < 10 and id_index < len(available_ids):
        pid = available_ids[id_index]
        id_index += 1
        attempts += 1
        
        img_data = download_picsum(pid)
        if img_data:
            h = hashlib.md5(img_data).hexdigest()
            if h not in used_hashes:
                assignment[num] = img_data
                used_hashes.add(h)
                downloaded = True
                success += 1
                print(f"OK (picsum/{pid}, {len(img_data)} bytes)", flush=True)
    
    if not downloaded:
        failed_nums.append(num)
        print("FAILED", flush=True)
    
    # Small delay to be respectful
    time.sleep(random.uniform(0.3, 0.8))

print(f"\n  Results: {success} downloaded, {len(failed_nums)} failed", flush=True)

# Retry any failures with different size to get unique images
if failed_nums:
    print(f"\n  Retrying {len(failed_nums)} failures with different dimensions...", flush=True)
    still_failed = []
    for num in failed_nums:
        downloaded = False
        for _ in range(15):
            if id_index >= len(available_ids):
                break
            pid = available_ids[id_index]
            id_index += 1
            # Use slightly different dimensions to get unique content
            w = random.choice([640, 720, 800, 850])
            h_dim = random.choice([420, 450, 480, 530])
            img_data = download_picsum(pid, w, h_dim)
            if img_data:
                h = hashlib.md5(img_data).hexdigest()
                if h not in used_hashes:
                    assignment[num] = img_data
                    used_hashes.add(h)
                    downloaded = True
                    success += 1
                    print(f"  art_{num:03d}.jpg retried OK (picsum/{pid})", flush=True)
                    break
            time.sleep(0.5)
        if not downloaded:
            still_failed.append(num)
    
    if still_failed:
        print(f"  Still failed: {still_failed}", flush=True)

# ═══════════════════════════════════════
# STEP 4: Rebuild directory
# ═══════════════════════════════════════
print(f"\nSTEP 4: Rebuilding image directory...", flush=True)

# Clear existing files
for f in os.listdir(IMG_DIR):
    fp = os.path.join(IMG_DIR, f)
    if os.path.isfile(fp):
        os.remove(fp)

# Write all assigned images
written = 0
for num in range(1, 101):
    if num in assignment:
        path = os.path.join(IMG_DIR, f'art_{num:03d}.jpg')
        with open(path, 'wb') as f:
            f.write(assignment[num])
        written += 1

print(f"  Written: {written} files", flush=True)

# ═══════════════════════════════════════
# STEP 5: Final validation
# ═══════════════════════════════════════
print(f"\nSTEP 5: Final validation...", flush=True)

files = sorted(os.listdir(IMG_DIR))
hashes = {}
dupes = []
for f in files:
    fp = os.path.join(IMG_DIR, f)
    with open(fp, 'rb') as fh:
        h = hashlib.md5(fh.read()).hexdigest()
    if h in hashes:
        dupes.append((f, hashes[h]))
    else:
        hashes[h] = f

missing = [n for n in range(1, 101) if f'art_{n:03d}.jpg' not in files]

print(f"  Total files: {len(files)}", flush=True)
print(f"  Unique images: {len(hashes)}", flush=True)
print(f"  Duplicates: {len(dupes)}", flush=True)
if dupes:
    for f1, f2 in dupes[:5]:
        print(f"    {f1} == {f2}")
print(f"  Missing articles: {len(missing)}", flush=True)
if missing:
    print(f"    Missing: {missing[:20]}")

if len(files) == 100 and len(hashes) == 100 and not missing:
    print(f"\n{'='*50}", flush=True)
    print(f"  SUCCESS! 100 unique images!", flush=True)
    print(f"{'='*50}", flush=True)
elif len(files) >= 90:
    print(f"\n  Nearly complete ({len(files)}/100).", flush=True)
else:
    print(f"\n  Gaps remain ({len(files)}/100).", flush=True)
