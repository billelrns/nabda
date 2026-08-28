"""
Complete image fix: 
1. Identify truly unique images from existing files
2. Download missing images from Pixabay  
3. Rebuild directory with exactly 100 unique art_XXX.jpg files
"""
import json, sys, io, hashlib, os, shutil, time, random, urllib.request, urllib.parse, urllib.error
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

IMG_DIR = r'c:\nabda_app\assets\images\smart_articles'
BACKUP_DIR = r'c:\nabda_app\assets\images\smart_articles_old_backup'
PIXABAY_KEY = '47108729-e9a0e958a4c2e419d14e8e9b3'

# ═══════════════════════════════════════
# STEP 1: Catalog existing unique images
# ═══════════════════════════════════════
print("STEP 1: Cataloging existing images...")

source = BACKUP_DIR if os.path.exists(BACKUP_DIR) else IMG_DIR
all_content = {}  # filename -> bytes
all_hashes = {}   # filename -> hash

for f in sorted(os.listdir(source)):
    fp = os.path.join(source, f)
    if not os.path.isfile(fp):
        continue
    with open(fp, 'rb') as fh:
        data = fh.read()
    h = hashlib.md5(data).hexdigest()
    all_content[f] = data
    all_hashes[f] = h

# Find the mass-duplicate hash (33721 bytes)
mass_dup_hash = all_hashes.get('art_001.jpg', '')

# Build unique image pool (exclude mass duplicate)
pool = {}  # tag/name -> bytes
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
# STEP 2: Load articles & assign images
# ═══════════════════════════════════════
print("\nSTEP 2: Assigning images to articles...")

with open(r'c:\nabda_app\assets\data\smart_100_articles.json', 'r', encoding='utf-8') as f:
    articles = json.load(f)['articles']

# Image assignment: num -> bytes
assignment = {}
used_hashes = set()

# First: assign unique art_076-art_100 files
for num in range(76, 101):
    key = f'art_{num:03d}.jpg'
    if key in pool:
        h = hashlib.md5(pool[key]).hexdigest()
        if h not in used_hashes:
            assignment[num] = pool[key]
            used_hashes.add(h)

# Second: assign photo_tag images (1 per tag, first article wins)
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

print(f"  Pre-assigned: {len(assignment)} articles")
print(f"  Need download: {100 - len(assignment)} articles")

# ═══════════════════════════════════════
# STEP 3: Download missing from Pixabay
# ═══════════════════════════════════════

# Build download list with unique search queries
queries_map = {
    'ovulation_calendar': [
        'fertility calendar planning', 'ovulation test positive', 'woman health tracking app',
        'pregnancy planning couple', 'fertility cycle chart', 'basal thermometer woman',
        'reproductive health woman', 'family planning couple', 'menstrual cycle health',
        'conception planning', 'fertility monitor', 'woman health diary',
        'prenatal planning woman', 'hormone health', 'fertility awareness'
    ],
    'pcos_health': [
        'polycystic ovary health', 'hormonal balance woman yoga', 'gynecology doctor consultation',
        'medical checkup woman', 'healthy lifestyle exercise', 'ultrasound medical',
        'hormonal therapy health', 'wellness spa woman', 'health diagnosis'
    ],
    'baby_milestones': ['baby crawling', 'infant first steps', 'baby standing', 'toddler playing'],
    'skincare_serum': ['skincare routine products', 'face serum dropper', 'beauty flat lay', 'skin glow woman'],
    'period_tea': ['herbal tea cup', 'menstrual health woman', 'chamomile tea relaxing'],
    'couple_coffee': ['couple morning coffee', 'romantic couple love', 'couple date happy'],
    'ultrasound': ['pregnancy ultrasound doctor', 'prenatal checkup hospital', 'baby sonogram screen'],
    'pregnancy_test': ['pregnancy test positive joy', 'early pregnancy woman', 'maternity announcement'],
    'pregnant_belly': ['pregnant woman beautiful', 'maternity dress fashion', 'pregnancy belly profile'],
    'chia_seeds_bowl': ['superfood healthy bowl', 'vitamin supplements nutrition', 'chia seeds smoothie'],
    'breastfeeding': ['mother nursing baby', 'mother baby bonding', 'new mom breastfeeding'],
    'maternity_vitamins': ['prenatal vitamins pills', 'pregnancy supplements bottle'],
    'hair_care_curls': [
        'hair treatment salon woman', 'healthy shiny hair beauty', 'hair growth oil treatment',
        'anti hair loss serum', 'scalp massage oil', 'beautiful hairstyle woman', 'hair mask natural'
    ],
    'dark_circles': ['under eye cream woman', 'eye skincare routine', 'face mask spa'],
    'newborn_sleep': [
        'baby sleeping crib', 'newborn swaddle blanket', 'infant peaceful nap',
        'baby sleep stars moon', 'mother holding sleeping baby'
    ],
    'stretch_marks': ['body lotion skincare'],
    'labor_birth': ['hospital birth delivery', 'natural birth yoga preparation'],
    'twin_pregnancy': ['twin babies cute', 'twins ultrasound', 'twin newborns matching'],
    'teething_baby': ['baby teething ring toy'],
    'couple_hands': ['wedding rings couple hands'],
}

# Fallback queries by category
cat_queries = {
    'pregnancy': ['pregnant woman garden', 'maternity photo sunset', 'expecting mother joy', 'prenatal care woman'],
    'beauty': ['beauty woman natural glow', 'skincare woman mirror', 'beauty routine morning', 'natural beauty woman'],
    'baby': ['cute baby playing', 'mother baby outdoors', 'infant happy smile', 'baby toy colorful'],
    'marriage': ['couple love sunset', 'wedding couple happy', 'romantic couple home', 'couple conversation'],
    'health': ['healthy food woman', 'woman exercise yoga', 'wellness health woman', 'medical health woman'],
    'fertility': ['fertility health woman', 'woman doctor visit', 'health planning woman', 'pregnancy hope woman'],
}

needs = []
for art in articles:
    num = int(art['id'].replace('smart_', ''))
    if num in assignment:
        continue
    tag = art.get('photoTag', '')
    cat = art.get('categoryId', '')
    
    # Pick a query
    if tag in queries_map:
        tag_count = sum(1 for n, q in needs if q.startswith(tag + ':'))
        qlist = queries_map[tag]
        query = qlist[tag_count % len(qlist)]
    elif cat in cat_queries:
        cat_count = sum(1 for n, q in needs if q.startswith(cat + ':'))
        qlist = cat_queries[cat]
        query = qlist[cat_count % len(qlist)]
    else:
        query = 'women health wellness lifestyle'
    
    needs.append((num, f"{tag or cat}:{query}"))

print(f"\nSTEP 3: Downloading {len(needs)} images from Pixabay...")

def download_from_pixabay(query, skip_hashes):
    """Download one unique image from Pixabay. Returns bytes or None."""
    clean_q = query.split(':', 1)[-1] if ':' in query else query
    safe_q = urllib.parse.quote(clean_q)
    url = f'https://pixabay.com/api/?key={PIXABAY_KEY}&q={safe_q}&image_type=photo&orientation=horizontal&per_page=30&safesearch=true&min_width=640'
    
    try:
        req = urllib.request.Request(url, headers={
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        })
        resp = urllib.request.urlopen(req, timeout=15)
        result = json.loads(resp.read().decode('utf-8'))
    except Exception as e:
        print(f"    API error: {e}")
        return None
    
    hits = result.get('hits', [])
    if not hits:
        print(f"    No results for: {clean_q}")
        return None
    
    # Shuffle to add variety
    random.shuffle(hits)
    
    for hit in hits:
        img_url = hit.get('webformatURL', '')
        if not img_url:
            continue
        try:
            req2 = urllib.request.Request(img_url, headers={
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            })
            resp2 = urllib.request.urlopen(req2, timeout=20)
            img_data = resp2.read()
            
            if len(img_data) < 15000:
                continue
            
            h = hashlib.md5(img_data).hexdigest()
            if h in skip_hashes:
                continue
            
            return img_data
        except Exception:
            continue
    
    return None

success = 0
failed = []

for i, (num, query) in enumerate(needs):
    print(f"  [{i+1}/{len(needs)}] art_{num:03d}.jpg | {query} ... ", end='', flush=True)
    
    img_data = download_from_pixabay(query, used_hashes)
    if img_data:
        h = hashlib.md5(img_data).hexdigest()
        assignment[num] = img_data
        used_hashes.add(h)
        success += 1
        print(f"OK ({len(img_data)} bytes)")
    else:
        failed.append((num, query))
        print("FAILED")
    
    time.sleep(random.uniform(1.2, 2.5))

# Retry failed with broader queries
if failed:
    print(f"\n  Retrying {len(failed)} failed downloads...")
    broad_queries = [
        'woman health wellness', 'mother baby love', 'healthy food nutrition',
        'beauty skincare products', 'family happy home', 'medical doctor office',
        'pregnancy prenatal care', 'cute baby sleeping', 'couple love together',
        'vitamins supplements health', 'yoga meditation woman', 'fruit vegetables healthy',
        'woman running exercise', 'spa relaxation massage', 'doctor stethoscope medical',
        'nurse hospital care', 'cooking kitchen healthy', 'garden flowers nature',
        'sunrise morning routine', 'books reading education', 'tea morning calm',
        'water bottle hydration', 'salad bowl fresh', 'smoothie fruit blend',
        'woman smiling happy', 'baby laughing joy', 'hands heart love',
        'sunset peaceful calm', 'herbs natural remedy', 'essential oils aromatherapy',
    ]
    
    retry_idx = 0
    still_failed = []
    for num, query in failed:
        for attempt in range(3):
            bq = broad_queries[(retry_idx + attempt) % len(broad_queries)]
            retry_idx += 1
            img_data = download_from_pixabay(bq, used_hashes)
            if img_data:
                h = hashlib.md5(img_data).hexdigest()
                assignment[num] = img_data
                used_hashes.add(h)
                success += 1
                print(f"  art_{num:03d}.jpg retried OK ({bq})")
                break
            time.sleep(1.5)
        else:
            still_failed.append(num)
    
    if still_failed:
        print(f"  Still failed: {still_failed}")

print(f"\n  Downloads: {success} OK, {len(failed)} initially failed")

# ═══════════════════════════════════════
# STEP 4: Rebuild directory
# ═══════════════════════════════════════
print(f"\nSTEP 4: Rebuilding image directory...")

# Clear existing
for f in os.listdir(IMG_DIR):
    fp = os.path.join(IMG_DIR, f)
    if os.path.isfile(fp):
        os.remove(fp)

# Write all
written = 0
for num in range(1, 101):
    if num in assignment:
        path = os.path.join(IMG_DIR, f'art_{num:03d}.jpg')
        with open(path, 'wb') as f:
            f.write(assignment[num])
        written += 1

print(f"  Written: {written} files")

# ═══════════════════════════════════════
# STEP 5: Final validation
# ═══════════════════════════════════════
print(f"\nSTEP 5: Validation...")

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

missing = [f'art_{n:03d}.jpg' for n in range(1, 101) if f'art_{n:03d}.jpg' not in files]

print(f"  Total files: {len(files)}")
print(f"  Unique images: {len(hashes)}")
print(f"  Duplicates: {len(dupes)}")
print(f"  Missing: {len(missing)}")

if dupes:
    for f1, f2 in dupes:
        print(f"    DUP: {f1} == {f2}")
if missing:
    print(f"    MISSING: {missing}")

if len(files) == 100 and len(hashes) == 100 and not missing:
    print(f"\n{'='*50}")
    print(f"  🎉 SUCCESS! 100 unique images assigned!")
    print(f"{'='*50}")
else:
    print(f"\n⚠️  Not perfect yet. May need AI-generated images for gaps.")
