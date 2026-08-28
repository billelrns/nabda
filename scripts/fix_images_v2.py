"""
Download 62 unique images using multiple free sources (no API key needed):
1. Lorem Picsum (picsum.photos) - random beautiful photos
2. Unsplash Source (source.unsplash.com) - topic-based photos
"""
import json, sys, io, hashlib, os, shutil, time, random, urllib.request, urllib.parse
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

IMG_DIR = r'c:\nabda_app\assets\images\smart_articles'
BACKUP_DIR = r'c:\nabda_app\assets\images\smart_articles_old_backup'

# ═══════════════════════════════════════
# STEP 1: Catalog existing unique images
# ═══════════════════════════════════════
print("STEP 1: Cataloging existing images...")

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

# The mass-duplicate hash
mass_dup_hash = all_hashes.get('art_001.jpg', '')

# Build pool of unique images
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

print(f"  Unique images in pool: {len(pool)}")

# ═══════════════════════════════════════
# STEP 2: Assign existing images
# ═══════════════════════════════════════
print("\nSTEP 2: Assigning existing images...")

with open(r'c:\nabda_app\assets\data\smart_100_articles.json', 'r', encoding='utf-8') as f:
    articles = json.load(f)['articles']

assignment = {}
used_hashes = set()

# Assign unique art_076-100
for num in range(76, 101):
    key = f'art_{num:03d}.jpg'
    if key in pool:
        h = hashlib.md5(pool[key]).hexdigest()
        if h not in used_hashes:
            assignment[num] = pool[key]
            used_hashes.add(h)

# Assign photo tags (first use only)
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

# List what we need
needs = []
for art in articles:
    num = int(art['id'].replace('smart_', ''))
    if num not in assignment:
        tag = art.get('photoTag', '')
        cat = art.get('categoryId', '')
        needs.append((num, tag, cat))

print(f"  Pre-assigned: {len(assignment)}")
print(f"  Need download: {len(needs)}")

# ═══════════════════════════════════════
# STEP 3: Download from free sources
# ═══════════════════════════════════════
print(f"\nSTEP 3: Downloading {len(needs)} images...")

# Topic keywords for Unsplash
topic_keywords = {
    'ovulation_calendar': ['fertility', 'pregnancy+planning', 'woman+health', 'calendar+planning', 'conception', 'female+health', 'reproductive+health', 'family+planning', 'menstrual+cycle', 'fertility+tracking', 'woman+thermometer', 'pregnancy+test', 'health+tracking', 'prenatal+care', 'ovulation'],
    'pcos_health': ['hormones', 'woman+doctor', 'gynecology', 'health+checkup', 'medical+consultation', 'exercise+woman', 'ultrasound+medical', 'therapy+health', 'spa+wellness', 'doctor+office'],
    'baby_milestones': ['baby+crawling', 'baby+first+steps', 'baby+standing', 'toddler+playing'],
    'skincare_serum': ['skincare+routine', 'face+serum', 'beauty+products', 'skin+care'],
    'period_tea': ['herbal+tea', 'tea+cup+warm', 'chamomile+tea'],
    'couple_coffee': ['couple+coffee', 'romantic+couple', 'happy+couple'],
    'ultrasound': ['pregnancy+ultrasound', 'prenatal+checkup', 'sonogram'],
    'pregnancy_test': ['pregnancy+test', 'pregnancy+announcement', 'early+pregnancy'],
    'pregnant_belly': ['pregnant+woman', 'maternity+dress', 'pregnancy+belly'],
    'chia_seeds_bowl': ['superfood+bowl', 'vitamins+health', 'chia+seeds'],
    'breastfeeding': ['mother+nursing', 'mother+baby', 'breastfeeding'],
    'maternity_vitamins': ['prenatal+vitamins', 'pregnancy+supplements'],
    'hair_care_curls': ['hair+treatment', 'shiny+hair', 'hair+oil', 'hair+loss+treatment', 'scalp+massage', 'hairstyle+woman', 'hair+mask'],
    'dark_circles': ['eye+cream', 'skincare+face', 'facial+mask'],
    'newborn_sleep': ['baby+sleeping', 'newborn+blanket', 'infant+sleep', 'baby+crib', 'sleeping+baby'],
    'stretch_marks': ['body+care+lotion'],
    'labor_birth': ['hospital+birth', 'natural+birth'],
    'twin_pregnancy': ['twin+babies', 'twins+newborn', 'twin+pregnancy'],
    'teething_baby': ['baby+teething'],
    'couple_hands': ['wedding+rings'],
}

def download_image(url, min_size=15000):
    """Download image from URL, return bytes or None."""
    try:
        req = urllib.request.Request(url, headers={
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
        })
        resp = urllib.request.urlopen(req, timeout=25)
        data = resp.read()
        if len(data) >= min_size:
            return data
    except Exception as e:
        pass
    return None

success = 0
failed = []
tag_counters = {}

for i, (num, tag, cat) in enumerate(needs):
    print(f"  [{i+1}/{len(needs)}] art_{num:03d}.jpg | {tag} ... ", end='', flush=True)
    
    # Track per-tag counter
    tag_counters[tag] = tag_counters.get(tag, 0)
    
    downloaded = False
    
    # Strategy 1: Unsplash Source with topic keyword
    if tag in topic_keywords:
        keywords = topic_keywords[tag]
        kw = keywords[tag_counters[tag] % len(keywords)]
        tag_counters[tag] += 1
    elif cat == 'pregnancy':
        kw = random.choice(['pregnant+woman', 'maternity', 'prenatal+care', 'pregnancy'])
    elif cat == 'beauty':
        kw = random.choice(['skincare', 'beauty+woman', 'cosmetics', 'natural+beauty'])
    elif cat == 'baby':
        kw = random.choice(['baby+cute', 'infant+care', 'newborn', 'mother+baby'])
    elif cat == 'marriage':
        kw = random.choice(['couple+love', 'wedding', 'romantic+couple', 'happy+couple'])
    elif cat == 'health':
        kw = random.choice(['healthy+food', 'woman+exercise', 'wellness', 'nutrition'])
    elif cat == 'fertility':
        kw = random.choice(['fertility', 'woman+health', 'conception', 'family+planning'])
    else:
        kw = 'woman+health'
    
    # Try Unsplash Source (640x480)
    # Use unique random seed per image
    seed = num * 1000 + random.randint(1, 999)
    unsplash_url = f'https://source.unsplash.com/640x480/?{kw}&sig={seed}'
    
    img_data = download_image(unsplash_url)
    if img_data:
        h = hashlib.md5(img_data).hexdigest()
        if h not in used_hashes:
            assignment[num] = img_data
            used_hashes.add(h)
            success += 1
            downloaded = True
            print(f"✅ Unsplash ({len(img_data)} bytes)")
    
    # Strategy 2: Lorem Picsum (random beautiful photo)
    if not downloaded:
        picsum_id = 100 + num + random.randint(0, 800)
        picsum_url = f'https://picsum.photos/id/{picsum_id}/640/480'
        
        img_data = download_image(picsum_url)
        if img_data:
            h = hashlib.md5(img_data).hexdigest()
            if h not in used_hashes:
                assignment[num] = img_data
                used_hashes.add(h)
                success += 1
                downloaded = True
                print(f"✅ Picsum ({len(img_data)} bytes)")
    
    # Strategy 3: Picsum with different ID
    if not downloaded:
        for attempt in range(5):
            pid = random.randint(1, 1084)
            url3 = f'https://picsum.photos/id/{pid}/640/480'
            img_data = download_image(url3)
            if img_data:
                h = hashlib.md5(img_data).hexdigest()
                if h not in used_hashes:
                    assignment[num] = img_data
                    used_hashes.add(h)
                    success += 1
                    downloaded = True
                    print(f"✅ Picsum-alt ({len(img_data)} bytes)")
                    break
            time.sleep(0.5)
    
    if not downloaded:
        print("❌ FAILED")
        failed.append(num)
    
    # Rate limiting
    time.sleep(random.uniform(1.0, 2.0))

print(f"\n  Results: {success} downloaded, {len(failed)} failed")

# ═══════════════════════════════════════
# STEP 4: Rebuild directory
# ═══════════════════════════════════════
print(f"\nSTEP 4: Rebuilding image directory...")

# Clear
for f in os.listdir(IMG_DIR):
    fp = os.path.join(IMG_DIR, f)
    if os.path.isfile(fp):
        os.remove(fp)

# Write all assigned
written = 0
for num in range(1, 101):
    if num in assignment:
        path = os.path.join(IMG_DIR, f'art_{num:03d}.jpg')
        with open(path, 'wb') as f:
            f.write(assignment[num])
        written += 1

print(f"  Written: {written} files")

# ═══════════════════════════════════════
# STEP 5: Validation
# ═══════════════════════════════════════
print(f"\nSTEP 5: Final validation...")

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

print(f"  Total files: {len(files)}")
print(f"  Unique images: {len(hashes)}")
print(f"  Duplicates: {len(dupes)}")
if dupes:
    for f1, f2 in dupes:
        print(f"    {f1} == {f2}")
print(f"  Missing articles: {missing}")

if len(files) == 100 and len(hashes) == 100 and not missing:
    print(f"\n{'='*50}")
    print(f"  🎉 SUCCESS! 100 unique images!")
    print(f"{'='*50}")
elif len(files) >= 90:
    print(f"\n  ✅ Nearly complete ({len(files)}/100). Gaps can be filled with AI generation.")
else:
    print(f"\n  ⚠️  Significant gaps remain.")
