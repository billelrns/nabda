import json

with open("assets/data/algeria_cities.json", encoding="utf-8") as f:
    data = json.load(f)

# Search for "جلال" in communes and wilayas
print("Searching for 'جلال' in Wilayas...")
for w in data.get("wilayas", []):
    if "جلال" in w.get("wilaya_name_arabic", "") or "Djalal" in w.get("wilaya_name_latin", "") or "Djellal" in w.get("wilaya_name_latin", ""):
        print("Wilaya:", w)

print("\nSearching for 'جلال' in Communes...")
for c in data.get("communes", []):
    if "جلال" in c.get("commune_name_arabic", "") or "Djalal" in c.get("commune_name_latin", "") or "Djellal" in c.get("commune_name_latin", ""):
        print("Commune:", c)

# Print total counts
print(f"\nTotal wilayas: {len(data.get('wilayas', []))}")
print(f"Total communes: {len(data.get('communes', []))}")
