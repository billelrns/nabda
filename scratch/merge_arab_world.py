import json
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')

def merge():
    algeria_path = "assets/data/algeria_doctors_clinics.json"
    arab_world_path = "assets/data/arab_world_doctors.json"
    
    if not os.path.exists(algeria_path) or not os.path.exists(arab_world_path):
        print("Missing required files!")
        return

    with open(algeria_path, "r", encoding="utf-8") as f:
        clean_algeria = json.load(f)

    with open(arab_world_path, "r", encoding="utf-8") as f:
        arab_world = json.load(f)

    print(f"Loaded {len(clean_algeria)} clean Algerian records.")
    print(f"Loaded {len(arab_world)} total records from arab_world_doctors.json.")

    # Keep records from other Arab countries (wilaya_id >= 100)
    other_arab_records = [item for item in arab_world if (item.get("wilaya_id") or 0) >= 100]
    print(f"Other Arab Countries records: {len(other_arab_records)}")

    # Merge clean Algerian records + Other Arab countries records
    final_merged = clean_algeria + other_arab_records
    print(f"Total Merged Database Records: {len(final_merged)}")

    # Save to arab_world_doctors.json
    with open(arab_world_path, "w", encoding="utf-8") as f:
        json.dump(final_merged, f, ensure_ascii=False, indent=2)

    print(f"Successfully updated {arab_world_path} with {len(final_merged)} clean records!")

if __name__ == "__main__":
    merge()
