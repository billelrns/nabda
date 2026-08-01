import json

with open("scratch/processed_medical_data.json", encoding="utf-8") as f:
    data = json.load(f)

gyns = [x for x in data if x['is_gyn']]

print(f"Total Gynecologists: {len(gyns)}")
print("First 15 Gynecologists:")
for i, g in enumerate(gyns[:15]):
    print(f"{i+1}. Name: {g['name']} | City: {g['city']} | Lat: {g['lat']} | Lon: {g['lon']} | Phone: {g['phone']}")

# Let's save a smaller file of only gynaecologists for easy reference or import into the app.
with open("scratch/gyn_data_only.json", "w", encoding="utf-8") as f:
    json.dump(gyns, f, ensure_ascii=False, indent=2)

print("Saved gyn_data_only.json")
