"""
Step 1: Clean up the image directory
- Remove all duplicates
- Keep only truly unique images
- Map each unique image to the right article based on photoTag
"""
import json, sys, io, hashlib, os, shutil
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

img_dir = r'c:\nabda_app\assets\images\smart_articles'
backup_dir = r'c:\nabda_app\assets\images\smart_articles_backup'
clean_dir = r'c:\nabda_app\assets\images\smart_articles_clean'

# Load articles
with open(r'c:\nabda_app\assets\data\smart_100_articles.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

articles = data['articles']

# Step 1: Hash all existing files
file_hashes = {}
for f in sorted(os.listdir(img_dir)):
    fp = os.path.join(img_dir, f)
    if os.path.isfile(fp):
        with open(fp, 'rb') as fh:
            h = hashlib.md5(fh.read()).hexdigest()
        sz = os.path.getsize(fp)
        file_hashes[f] = {'hash': h, 'size': sz, 'path': fp}

# Step 2: Identify truly unique images (one per hash, keep largest / best named)
unique_by_hash = {}
for fname, info in file_hashes.items():
    h = info['hash']
    if h not in unique_by_hash:
        unique_by_hash[h] = fname
    else:
        # Prefer photo_* named files (more descriptive) over art_XXX
        existing = unique_by_hash[h]
        if fname.startswith('photo_') and existing.startswith('art_'):
            unique_by_hash[h] = fname
        elif info['size'] > file_hashes[existing]['size']:
            unique_by_hash[h] = fname

# Get set of truly unique files
unique_files = set(unique_by_hash.values())
print(f"Truly unique images: {len(unique_files)}")

# Step 3: Map photoTags to unique photo_* images
tag_to_photo = {}
for fname in sorted(unique_files):
    if fname.startswith('photo_'):
        tag = fname.replace('photo_', '').replace('.jpg', '')
        tag_to_photo[tag] = fname

print(f"\nAvailable photo tags: {len(tag_to_photo)}")
for tag, fname in sorted(tag_to_photo.items()):
    print(f"  {tag} -> {fname}")

# Step 4: Map articles to images
assigned = {}  # art_id -> source_file
unassigned = []  # articles that need new images

for art in articles:
    art_id = art['id']  # e.g., smart_001
    num = art_id.replace('smart_', '')  # e.g., 001
    art_file = f'art_{num}.jpg'
    photo_tag = art.get('photoTag', '')
    
    # Check if this art file is already unique (not the duplicated one)
    if art_file in unique_files:
        dup_hash = file_hashes.get(art_file, {}).get('hash', '')
        # The mass-duplicate hash
        if dup_hash == '543ac54d2f7fdf2e0db7b19afcadd2fa' or dup_hash.startswith('543ac54d'):
            # This is the duplicated image - needs replacement
            if photo_tag in tag_to_photo:
                assigned[art_id] = tag_to_photo[photo_tag]
            else:
                unassigned.append({'id': art_id, 'num': num, 'tag': photo_tag, 'cat': art.get('categoryId', ''), 'title': art['title'][:50]})
        else:
            # Unique art file - keep it
            assigned[art_id] = art_file
    elif photo_tag in tag_to_photo:
        assigned[art_id] = tag_to_photo[photo_tag]
    else:
        unassigned.append({'id': art_id, 'num': num, 'tag': photo_tag, 'cat': art.get('categoryId', ''), 'title': art['title'][:50]})

print(f"\n=== ASSIGNMENT RESULTS ===")
print(f"Assigned (have image): {len(assigned)}")
print(f"Unassigned (need new image): {len(unassigned)}")

# Check for duplicate assignments (same image assigned to multiple articles)
from collections import Counter
source_counts = Counter(assigned.values())
dup_sources = {src: cnt for src, cnt in source_counts.items() if cnt > 1}
if dup_sources:
    print(f"\n⚠️  WARNING: {len(dup_sources)} images assigned to multiple articles:")
    for src, cnt in sorted(dup_sources.items(), key=lambda x: -x[1]):
        arts = [aid for aid, s in assigned.items() if s == src]
        print(f"  {src} -> {cnt} articles: {arts}")

print(f"\n=== UNASSIGNED ARTICLES (need images) ===")
for u in unassigned:
    print(f"  {u['id']} | {u['cat']} | tag:{u['tag']} | {u['title']}")

# Save results for next step
results = {
    'assigned': assigned,
    'unassigned': [u for u in unassigned],
    'unique_files': list(unique_files),
    'duplicate_assignments': {src: [aid for aid, s in assigned.items() if s == src] for src, cnt in source_counts.items() if cnt > 1}
}

with open(r'c:\nabda_app\scripts\image_assignment_plan.json', 'w', encoding='utf-8') as f:
    json.dump(results, f, ensure_ascii=False, indent=2)

print(f"\nPlan saved to image_assignment_plan.json")
