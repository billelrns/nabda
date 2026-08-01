import json

with open("assets/data/algeria_cities.json", encoding="utf-8") as f:
    data = json.load(f)

print("Keys:", list(data.keys()))
if "wilayas" in data:
    print("Wilayas count:", len(data["wilayas"]))
    print("First 3 wilayas:", data["wilayas"][:3])
if "communes" in data:
    print("Communes count:", len(data["communes"]))
    print("First 3 communes:", data["communes"][:3])
