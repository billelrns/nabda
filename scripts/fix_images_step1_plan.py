"""
Master image fix script:
1. Backup existing images
2. Clear the directory
3. Copy unique existing images to their correct art_XXX positions
4. Download new images from Pixabay (free, no auth needed for small usage) for missing slots
5. Validate: exactly 100 unique files, no duplicates
"""
import json, sys, io, hashlib, os, shutil, urllib.request, time, random
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

IMG_DIR = r'c:\nabda_app\assets\images\smart_articles'
BACKUP_DIR = r'c:\nabda_app\assets\images\smart_articles_old_backup'

# Load articles
with open(r'c:\nabda_app\assets\data\smart_100_articles.json', 'r', encoding='utf-8') as f:
    data = json.load(f)
articles = data['articles']

# ── Step 1: Backup ──
if not os.path.exists(BACKUP_DIR):
    shutil.copytree(IMG_DIR, BACKUP_DIR)
    print(f"✅ Backed up to {BACKUP_DIR}")
else:
    print(f"ℹ️  Backup already exists at {BACKUP_DIR}")

# ── Step 2: Catalog unique images before cleanup ──
unique_images = {}  # hash -> {'path': ..., 'name': ...}
for f in sorted(os.listdir(IMG_DIR)):
    fp = os.path.join(IMG_DIR, f)
    if os.path.isfile(fp):
        with open(fp, 'rb') as fh:
            content = fh.read()
        h = hashlib.md5(content).hexdigest()
        if h not in unique_images:
            unique_images[h] = {'name': f, 'content': content, 'size': len(content)}

# Identify the mass-duplicate hash (76 copies of same image)
mass_dup_hash = None
for h, info in unique_images.items():
    if info['name'] == 'art_001.jpg' and info['size'] == 33721:
        mass_dup_hash = h
        break

print(f"Found {len(unique_images)} unique images (excluding the mass-duplicate)")

# ── Step 3: Build tag->content mapping (unique photo_* files only) ──
tag_to_content = {}
for h, info in unique_images.items():
    if h == mass_dup_hash:
        continue  # Skip the duplicated junk image
    name = info['name']
    if name.startswith('photo_'):
        tag = name.replace('photo_', '').replace('.jpg', '')
        tag_to_content[tag] = info['content']

# Also keep unique art_XXX files (076-100 range, excluding the dup)
unique_art_files = {}
for h, info in unique_images.items():
    if h == mass_dup_hash:
        continue
    name = info['name']
    if name.startswith('art_') and name.endswith('.jpg'):
        try:
            num = int(name.replace('art_', '').replace('.jpg', ''))
            if num >= 76 and num <= 100:
                unique_art_files[num] = info['content']
        except ValueError:
            pass

print(f"Unique photo tags: {len(tag_to_content)}")
print(f"Unique art files (76-100): {len(unique_art_files)}")

# ── Step 4: Assign images to articles ──
# Strategy: each article gets a unique image
# - If art_XXX (76-100) already has a unique image, keep it
# - Otherwise, match by photoTag
# - For articles sharing the same photoTag, only the FIRST gets the photo_* image
#   The rest go into "needs_download" list

assignment = {}  # num -> content (bytes)
needs_image = []  # list of (num, search_query)

# Track which tags have been used
used_tags = set()
used_hashes = set()

for art in articles:
    num = int(art['id'].replace('smart_', ''))
    tag = art.get('photoTag', '')
    cat = art.get('categoryId', '')
    title = art.get('title', '')
    
    # Check if this num has a unique art file
    if num in unique_art_files:
        content = unique_art_files[num]
        h = hashlib.md5(content).hexdigest()
        if h not in used_hashes:
            assignment[num] = content
            used_hashes.add(h)
            continue
    
    # Try to use the photo tag (only if not already used)
    if tag and tag in tag_to_content and tag not in used_tags:
        content = tag_to_content[tag]
        h = hashlib.md5(content).hexdigest()
        if h not in used_hashes:
            assignment[num] = content
            used_hashes.add(h)
            used_tags.add(tag)
            continue
    
    # Need a new image - build a search query from the article topic
    # Extract key terms for image search
    search_terms = {
        'ovulation_calendar': ['fertility tracking', 'pregnancy planning', 'women health calendar', 'ovulation test', 'fertility cycle'],
        'pcos_health': ['polycystic ovary', 'hormonal balance', 'women health checkup', 'medical consultation women', 'healthy lifestyle woman'],
        'baby_milestones': ['baby development', 'infant milestones', 'baby growth', 'toddler achievement'],
        'skincare_serum': ['skincare routine', 'face serum', 'beauty products', 'skin glow'],
        'period_tea': ['herbal tea health', 'menstrual health', 'relaxing tea cup'],
        'couple_coffee': ['happy couple', 'marriage love', 'couple relationship'],
        'ultrasound': ['pregnancy ultrasound', 'prenatal checkup', 'baby sonogram'],
        'pregnancy_test': ['pregnancy test positive', 'early pregnancy', 'maternity announcement'],
        'pregnant_belly': ['pregnant woman', 'maternity fashion', 'pregnancy glow'],
        'chia_seeds_bowl': ['healthy food bowl', 'superfood nutrition', 'vitamin supplements'],
        'breastfeeding': ['breastfeeding mother', 'nursing baby', 'mother child bond'],
        'maternity_vitamins': ['prenatal vitamins', 'pregnancy nutrition', 'health supplements'],
        'hair_care_curls': ['hair care treatment', 'healthy shiny hair', 'hair growth', 'anti hair loss', 'hair oil treatment', 'hair styling', 'hair strengthening'],
        'dark_circles': ['under eye care', 'eye cream beauty', 'facial skincare routine'],
        'newborn_sleep': ['sleeping baby', 'baby crib peaceful', 'infant nap', 'baby sleep routine', 'newborn peaceful'],
        'stretch_marks': ['skin care body', 'body moisturizer', 'skin treatment'],
        'labor_birth': ['hospital birth', 'delivery preparation', 'natural birth preparation'],
        'twin_pregnancy': ['twin babies', 'twin pregnancy belly', 'double joy babies'],
        'teething_baby': ['baby teeth', 'infant teething', 'baby chewing toy'],
        'couple_hands': ['couple holding hands', 'wedding rings couple'],
    }
    
    if tag in search_terms:
        queries = search_terms[tag]
        # Pick a unique query based on how many times this tag has been used
        tag_use_count = sum(1 for n in needs_image if n[2] == tag)
        query = queries[tag_use_count % len(queries)]
    elif 'حمل' in title or 'pregnancy' in cat:
        query = 'pregnant woman healthy lifestyle'
    elif 'جمال' in title or 'beauty' in cat:
        query = 'beauty skincare woman'
    elif 'طفل' in title or 'رضيع' in title or 'baby' in cat:
        query = 'baby infant care'
    elif 'زواج' in title or 'marriage' in cat:
        query = 'happy couple love'
    elif 'صحة' in title or 'health' in cat:
        query = 'healthy lifestyle woman'
    else:
        query = 'women health wellness'
    
    needs_image.append((num, query, tag))

print(f"\n✅ Already assigned: {len(assignment)}")
print(f"🔍 Need download: {len(needs_image)}")
for num, query, tag in needs_image:
    art = articles[num-1]
    print(f"  art_{num:03d} | tag:{tag} | query: {query}")

# Save the needs list
with open(r'c:\nabda_app\scripts\needs_image_list.json', 'w', encoding='utf-8') as f:
    json.dump([{'num': n, 'query': q, 'tag': t} for n, q, t in needs_image], f, ensure_ascii=False, indent=2)

print(f"\n📋 Saved needs list to needs_image_list.json")
print(f"Next step: Download {len(needs_image)} images using Pixabay API or generate them")
