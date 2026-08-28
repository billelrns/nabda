import json, sys, io, hashlib, os
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

# Check duplicates by file hash
img_dir = r'c:\nabda_app\assets\images\smart_articles'
hashes = {}
for f in sorted(os.listdir(img_dir)):
    fp = os.path.join(img_dir, f)
    if os.path.isfile(fp):
        sz = os.path.getsize(fp)
        with open(fp, 'rb') as fh:
            h = hashlib.md5(fh.read()).hexdigest()
        if h not in hashes:
            hashes[h] = []
        hashes[h].append(f)

print("=== DUPLICATE ANALYSIS ===")
print(f"Total files: {sum(len(v) for v in hashes.values())}")
print(f"Unique images: {len(hashes)}")
print()
for h, files in sorted(hashes.items(), key=lambda x: -len(x[1])):
    if len(files) > 1:
        print(f"DUPLICATE (count={len(files)}, hash={h[:8]}): {files[0]} ... {files[-1]}")
    
print()
print("=== UNIQUE FILES (non-art_XXX) ===")
for f in sorted(os.listdir(img_dir)):
    if not f.startswith('art_'):
        sz = os.path.getsize(os.path.join(img_dir, f))
        print(f"  {f} ({sz} bytes)")
