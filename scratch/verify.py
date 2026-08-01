import json

with open("assets/data/algeria_doctors_clinics.json", "r", encoding="utf-8") as f:
    data = json.load(f)

print("Checking 'Ouled Djellal' (أولاد جلال) matches:")
found = False
for x in data:
    addr = x["address"].lower()
    city = x["city"].lower()
    name = x["name_ar"]
    if "اولاد جلال" in addr or "djellal" in addr or "اولاد جلال" in city or "djellal" in city or x["wilaya_id"] == 51:
        print(f"Name: {name} | Wilaya: {x['wilaya_name_ar']} (id: {x['wilaya_id']}) | City: {x['city']} | Address: {x['address']}")
        found = True

if not found:
    print("No records found.")
