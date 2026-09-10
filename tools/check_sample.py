import sys
sys.path.insert(0, 'tools')
import data_females

names = [item[0] for item in data_females.FEMALE_NAMES]
print(f"Total female names: {len(names)}")
sample_check = ["مليكة", "زليخة", "وريدة", "باية", "كنزة", "زهرة", "فضيلة", "صفية", "ميمونة", "جويرية", "سودة", "بلقيس", "أروى"]
for name in sample_check:
    print(f"{name}: {'Found' if name in names else 'Missing'}")
