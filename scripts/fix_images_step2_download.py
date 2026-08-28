"""
Step 2: Download unique images from Pixabay for articles that need them.
Then rebuild the entire art_XXX directory with all 100 unique images.
"""
import json, sys, io, hashlib, os, shutil, time, random
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

try:
    from urllib.request import urlopen, Request
    from urllib.error import URLError, HTTPError
except ImportError:
    import urllib2
    urlopen = urllib2.urlopen

IMG_DIR = r'c:\nabda_app\assets\images\smart_articles'
PIXABAY_KEY = '47108729-e9a0e958a4c2e419d14e8e9b3'  # Free tier key

def download_pixabay(query, target_path, min_size=20000):
    """Download a single image from Pixabay matching the query."""
    import urllib.parse
    safe_query = urllib.parse.quote(query)
    url = f'https://pixabay.com/api/?key={PIXABAY_KEY}&q={safe_query}&image_type=photo&orientation=horizontal&per_page=20&safesearch=true&min_width=640&min_height=400'
    
    req = Request(url, headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'})
    try:
        response = urlopen(req, timeout=15)
        data = json.loads(response.read().decode('utf-8'))
    except Exception as e:
        return False, f"API error: {e}"
    
    hits = data.get('hits', [])
    if not hits:
        return False, f"No results for: {query}"
    
    # Try each hit until we get a valid unique image
    for hit in hits:
        img_url = hit.get('webformatURL', '')
        if not img_url:
            continue
        
        try:
            img_req = Request(img_url, headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'})
            img_response = urlopen(img_req, timeout=20)
            img_data = img_response.read()
            
            if len(img_data) < min_size:
                continue  # Too small, skip
            
            # Check if this image is already used
            img_hash = hashlib.md5(img_data).hexdigest()
            if img_hash in used_hashes:
                continue  # Duplicate, try next
            
            # Save it
            with open(target_path, 'wb') as f:
                f.write(img_data)
            
            used_hashes.add(img_hash)
            return True, f"OK ({len(img_data)} bytes)"
        except Exception as e:
            continue
    
    return False, f"All hits exhausted for: {query}"

# Load the assignment data from step 1
# Re-run the assignment logic
with open(r'c:\nabda_app\assets\data\smart_100_articles.json', 'r', encoding='utf-8') as f:
    data = json.load(f)
articles = data['articles']

# Catalog existing unique images from the backup
BACKUP_DIR = r'c:\nabda_app\assets\images\smart_articles_old_backup'
source_dir = BACKUP_DIR if os.path.exists(BACKUP_DIR) else IMG_DIR

existing_unique = {}  # filename -> content
existing_hashes = {}  # hash -> filename
mass_dup_hash = None

for f in sorted(os.listdir(source_dir)):
    fp = os.path.join(source_dir, f)
    if os.path.isfile(fp):
        with open(fp, 'rb') as fh:
            content = fh.read()
        h = hashlib.md5(content).hexdigest()
        sz = len(content)
        
        # Detect the mass-duplicate (33721 bytes, art_001)
        if f == 'art_001.jpg' and sz == 33721:
            mass_dup_hash = h
        
        if h not in existing_hashes:
            existing_hashes[h] = f
            existing_unique[f] = content

# Remove the mass-duplicate from the pool
if mass_dup_hash and mass_dup_hash in existing_hashes:
    dup_name = existing_hashes[mass_dup_hash]
    if dup_name in existing_unique:
        del existing_unique[dup_name]
    del existing_hashes[mass_dup_hash]

# Build tag -> content mapping
tag_to_content = {}
for fname, content in existing_unique.items():
    if fname.startswith('photo_'):
        tag = fname.replace('photo_', '').replace('.jpg', '')
        tag_to_content[tag] = content

# Build art_num -> content for unique art files (76-100)
art_content = {}
for fname, content in existing_unique.items():
    if fname.startswith('art_') and fname.endswith('.jpg'):
        try:
            num = int(fname.replace('art_', '').replace('.jpg', ''))
            if num >= 76 and num <= 100:
                art_content[num] = content
        except ValueError:
            pass

# ── Build the final assignment ──
used_hashes = set()
assignment = {}  # num -> content
needs_download = []  # (num, query)

# First pass: assign unique images from existing pool
used_tags = set()
for art in articles:
    num = int(art['id'].replace('smart_', ''))
    tag = art.get('photoTag', '')
    
    # Art file already unique?
    if num in art_content:
        h = hashlib.md5(art_content[num]).hexdigest()
        if h not in used_hashes:
            assignment[num] = art_content[num]
            used_hashes.add(h)
            continue
    
    # Photo tag available and unused?
    if tag and tag in tag_to_content and tag not in used_tags:
        content = tag_to_content[tag]
        h = hashlib.md5(content).hexdigest()
        if h not in used_hashes:
            assignment[num] = content
            used_hashes.add(h)
            used_tags.add(tag)
            continue
    
    # Build search query
    title = art.get('title', '')
    cat = art.get('categoryId', '')
    
    search_terms = {
        'ovulation_calendar': ['fertility tracking calendar', 'pregnancy planning woman', 'women health calendar app', 'ovulation test kit', 'fertility cycle chart', 'woman thermometer basal', 'conception planning couple', 'reproductive health', 'family planning', 'menstrual cycle tracking', 'positive ovulation test', 'fertility monitor device', 'woman health journal', 'prenatal care planning', 'hormone cycle woman'],
        'pcos_health': ['polycystic ovary syndrome', 'hormonal balance woman', 'women health checkup doctor', 'medical consultation gynecology', 'healthy lifestyle exercise woman', 'ultrasound ovary', 'hormonal therapy', 'women wellness spa', 'health diagnosis doctor'],
        'baby_milestones': ['baby crawling floor', 'infant standing milestone', 'baby first steps', 'toddler playing blocks'],
        'skincare_serum': ['skincare routine face', 'hyaluronic acid serum', 'beauty products flat lay', 'skin glow natural'],
        'period_tea': ['herbal tea relaxing cup', 'menstrual health comfort', 'chamomile tea warm'],
        'couple_coffee': ['happy couple morning coffee', 'marriage love relationship', 'couple romantic date'],
        'ultrasound': ['pregnancy ultrasound screen', 'prenatal doctor checkup', 'sonogram baby image'],
        'pregnancy_test': ['positive pregnancy test hand', 'early pregnancy symptoms', 'maternity announcement surprise'],
        'pregnant_belly': ['pregnant woman profile', 'maternity dress elegant', 'pregnancy belly beautiful'],
        'chia_seeds_bowl': ['healthy food superfood bowl', 'nutrition vitamin supplements', 'chia seeds smoothie bowl'],
        'breastfeeding': ['breastfeeding mother nursing', 'mother baby bonding love', 'new mom baby care'],
        'maternity_vitamins': ['prenatal vitamins bottle', 'pregnancy supplements health'],
        'hair_care_curls': ['hair treatment salon', 'healthy shiny hair woman', 'hair growth serum oil', 'anti hair loss treatment', 'hair oil massage scalp', 'beautiful hair styling woman', 'hair mask strengthening'],
        'dark_circles': ['under eye cream skincare', 'eye cream beauty routine', 'facial mask relaxation'],
        'newborn_sleep': ['baby sleeping peaceful crib', 'newborn swaddled blanket', 'infant nap cozy', 'baby sleep moon stars', 'mother holding sleeping baby'],
        'stretch_marks': ['body lotion moisturizer care'],
        'labor_birth': ['hospital labor delivery room', 'natural birth preparation yoga'],
        'twin_pregnancy': ['twin babies sleeping cute', 'twins ultrasound pregnancy', 'twin newborns matching outfits'],
        'teething_baby': ['baby teething ring chewing'],
        'couple_hands': ['couple wedding rings hands'],
    }
    
    if tag in search_terms:
        queries = search_terms[tag]
        # Count how many of this tag are already in needs_download
        count = sum(1 for _, _, t in needs_download if t == tag)
        query = queries[count % len(queries)]
    elif 'حمل' in title or cat == 'pregnancy':
        query = f'pregnant woman healthy lifestyle {random.randint(1,100)}'
    elif 'جمال' in title or cat == 'beauty':
        query = f'beauty skincare woman natural {random.randint(1,100)}'
    elif 'طفل' in title or 'رضيع' in title or cat == 'baby':
        query = f'baby infant mother care {random.randint(1,100)}'
    elif 'زواج' in title or cat == 'marriage':
        query = f'happy couple love romance {random.randint(1,100)}'
    else:
        query = f'women health wellness {random.randint(1,100)}'
    
    needs_download.append((num, query, tag))

print(f"✅ Pre-assigned: {len(assignment)} articles from existing unique images")
print(f"🔍 Need to download: {len(needs_download)} images")

# ── Step 2: Download from Pixabay ──
print(f"\n{'='*60}")
print(f"DOWNLOADING {len(needs_download)} IMAGES FROM PIXABAY")
print(f"{'='*60}\n")

# Use a temp directory for downloads
temp_dir = r'c:\nabda_app\assets\images\temp_downloads'
os.makedirs(temp_dir, exist_ok=True)

success_count = 0
fail_list = []

for i, (num, query, tag) in enumerate(needs_download):
    target = os.path.join(temp_dir, f'art_{num:03d}.jpg')
    print(f"[{i+1}/{len(needs_download)}] Downloading art_{num:03d}.jpg | query: {query} ...", end=' ')
    
    ok, msg = download_pixabay(query, target)
    if ok:
        # Read and store
        with open(target, 'rb') as f:
            content = f.read()
        assignment[num] = content
        success_count += 1
        print(f"✅ {msg}")
    else:
        print(f"❌ {msg}")
        fail_list.append((num, query, tag))
    
    # Rate limiting: 1-2 second delay between requests
    time.sleep(random.uniform(1.0, 2.0))

# Retry failures with alternative queries
if fail_list:
    print(f"\n⚠️  Retrying {len(fail_list)} failed downloads with alternative queries...")
    for num, orig_query, tag in list(fail_list):
        # Try broader queries
        alt_queries = [
            'woman health wellness',
            'mother baby love',
            'healthy lifestyle food',
            'beauty skincare natural',
            'happy family home',
            'medical doctor woman',
            'pregnancy care prenatal',
            'baby cute sleeping',
            'couple love marriage',
            'nutrition vitamins health',
        ]
        
        target = os.path.join(temp_dir, f'art_{num:03d}.jpg')
        for alt_q in alt_queries:
            ok, msg = download_pixabay(alt_q, target)
            if ok:
                with open(target, 'rb') as f:
                    content = f.read()
                assignment[num] = content
                success_count += 1
                fail_list = [(n,q,t) for n,q,t in fail_list if n != num]
                print(f"  art_{num:03d}.jpg ✅ (alt: {alt_q})")
                break
            time.sleep(1.0)

print(f"\n{'='*60}")
print(f"DOWNLOAD COMPLETE: {success_count} successful, {len(fail_list)} failed")
print(f"{'='*60}")

# ── Step 3: Rebuild the image directory ──
print(f"\nRebuilding image directory...")

# Clear the main directory
for f in os.listdir(IMG_DIR):
    fp = os.path.join(IMG_DIR, f)
    if os.path.isfile(fp):
        os.remove(fp)

# Write all assigned images
written = 0
for num in sorted(assignment.keys()):
    target = os.path.join(IMG_DIR, f'art_{num:03d}.jpg')
    with open(target, 'wb') as f:
        f.write(assignment[num])
    written += 1

print(f"✅ Written {written} images to {IMG_DIR}")

# ── Step 4: Validation ──
final_files = sorted(os.listdir(IMG_DIR))
final_hashes = {}
for f in final_files:
    fp = os.path.join(IMG_DIR, f)
    with open(fp, 'rb') as fh:
        h = hashlib.md5(fh.read()).hexdigest()
    if h in final_hashes:
        print(f"⚠️  DUPLICATE: {f} has same hash as {final_hashes[h]}")
    else:
        final_hashes[h] = f

print(f"\n{'='*60}")
print(f"FINAL VALIDATION")
print(f"{'='*60}")
print(f"Total files: {len(final_files)}")
print(f"Unique images: {len(final_hashes)}")
print(f"Expected: 100 files, 100 unique")

if len(final_files) == 100 and len(final_hashes) == 100:
    print(f"\n🎉 SUCCESS! 100 unique images, perfectly mapped!")
elif len(fail_list) > 0:
    print(f"\n⚠️  Missing images for: {[f'art_{n:03d}' for n,_,_ in fail_list]}")
    print(f"These will need to be generated with AI image generation")
else:
    print(f"\n⚠️  Check needed - count mismatch")

# Clean up temp
shutil.rmtree(temp_dir, ignore_errors=True)
