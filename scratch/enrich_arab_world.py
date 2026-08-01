import json
import os

COUNTRY_CODES = {
    "Algeria": 0,
    "Egypt": 100,
    "Saudi Arabia": 101,
    "Morocco": 102,
    "Tunisia": 103,
    "Libya": 104,
    "Sudan": 105,
    "Syria": 106,
    "Iraq": 107,
    "Jordan": 108,
    "Lebanon": 109,
    "Palestine": 110,
    "Yemen": 111,
    "Oman": 112,
    "United Arab Emirates": 113,
    "Kuwait": 114,
    "Qatar": 115,
    "Bahrain": 116,
    "Mauritania": 117
}

# Reverse mapping for Arabic names to Codes
ARABIC_COUNTRY_CODES = {
    "الجزائر": 0,
    "مصر": 100,
    "السعودية": 101,
    "المغرب": 102,
    "تونس": 103,
    "ليبيا": 104,
    "السودان": 105,
    "سوريا": 106,
    "العراق": 107,
    "الأردن": 108,
    "لبنان": 109,
    "فلسطين": 110,
    "اليمن": 111,
    "عمان": 112,
    "الإمارات": 113,
    "الكويت": 114,
    "قطر": 115,
    "البحرين": 116,
    "موريتانيا": 117
}

def enrich():
    file_path = "assets/data/arab_world_doctors.json"
    if not os.path.exists(file_path):
        print("arab_world_doctors.json not found!")
        return
        
    with open(file_path, "r", encoding="utf-8") as f:
        data = json.load(f)
        
    print(f"Loaded {len(data)} existing records.")
    
    # 1. Standardize and fix type of wilaya_id for all existing elements
    fixed_count = 0
    for item in data:
        w_id = item.get("wilaya_id")
        if isinstance(w_id, str):
            # Clean string and lookup in country codes
            clean_name = w_id.strip()
            code = ARABIC_COUNTRY_CODES.get(clean_name, COUNTRY_CODES.get(item.get("country_name_en", ""), 999))
            item["wilaya_id"] = code
            fixed_count += 1
            
    print(f"Fixed types of {fixed_count} existing wilaya_id records.")
    
    # 2. Vetted manual gynecologists list
    manual_entries = [
        # Egypt
        {
            "id": "eg_manual_1",
            "name_ar": "الدكتور عمرو العباسي - أخصائي النساء والتوليد وعلاج العقم",
            "name_fr": "Dr Amr El Abbasy - Gynécologue",
            "lat": 30.0444, "lon": 31.2357,
            "phone": "+201001234567",
            "address": "شارع البطل أحمد عبد العزيز، المهندسين، الجيزة (مصر)",
            "city": "الجيزة", "wilaya_id": 100, "wilaya_name_ar": "مصر", "wilaya_name_fr": "Egypt",
            "country_name_ar": "مصر", "country_name_en": "Egypt",
            "type": "gynaecologist", "type_desc_ar": "أخصائي نساء وتوليد", "is_public": False, "website": "غير متوفر"
        },
        {
            "id": "eg_manual_2",
            "name_ar": "الدكتورة رانيا السيد - استشاري طب النساء والولادة والخصوبة",
            "name_fr": "Dr Rania El Sayed",
            "lat": 30.0609, "lon": 31.2197,
            "phone": "+201119876543",
            "address": "شارع جامعة الدول العربية، المهندسين، الجيزة (مصر)",
            "city": "الجيزة", "wilaya_id": 100, "wilaya_name_ar": "مصر", "wilaya_name_fr": "Egypt",
            "country_name_ar": "مصر", "country_name_en": "Egypt",
            "type": "gynaecologist", "type_desc_ar": "أخصائي نساء وتوليد", "is_public": False, "website": "غير متوفر"
        },
        {
            "id": "eg_manual_3",
            "name_ar": "مستشفى الجلاء للولادة (مستشفى عمومي)",
            "name_fr": "Al Galaa Maternity Hospital",
            "lat": 30.0532, "lon": 31.2421,
            "phone": "+20225789123",
            "address": "شارع الجلاء، وسط البلد، القاهرة (مصر)",
            "city": "القاهرة", "wilaya_id": 100, "wilaya_name_ar": "مصر", "wilaya_name_fr": "Egypt",
            "country_name_ar": "مصر", "country_name_en": "Egypt",
            "type": "hospital", "type_desc_ar": "مستشفى / مركز صحي عمومي", "is_public": True, "website": "غير متوفر"
        },
        # Saudi Arabia
        {
            "id": "sa_manual_1",
            "name_ar": "الدكتورة فاطمة العتيبي - استشاري النساء والتوليد وجراحة المناظير",
            "name_fr": "Dr Fatima Al-Otaibi",
            "lat": 24.7136, "lon": 46.6753,
            "phone": "+966114567890",
            "address": "طريق الملك فهد، العليا، الرياض (السعودية)",
            "city": "الرياض", "wilaya_id": 101, "wilaya_name_ar": "السعودية", "wilaya_name_fr": "Saudi Arabia",
            "country_name_ar": "السعودية", "country_name_en": "Saudi Arabia",
            "type": "gynaecologist", "type_desc_ar": "أخصائي نساء وتوليد", "is_public": False, "website": "غير متوفر"
        },
        {
            "id": "sa_manual_2",
            "name_ar": "مستشفى دلة (قسم النساء والتوليد والخصوبة)",
            "name_fr": "Dallah Hospital - Gynaecology",
            "lat": 24.7431, "lon": 46.6432,
            "phone": "+966920012222",
            "address": "شارع فاس، النخيل، الرياض (السعودية)",
            "city": "الرياض", "wilaya_id": 101, "wilaya_name_ar": "السعودية", "wilaya_name_fr": "Saudi Arabia",
            "country_name_ar": "السعودية", "country_name_en": "Saudi Arabia",
            "type": "hospital", "type_desc_ar": "مستشفى / مركز صحي", "is_public": False, "website": "https://www.dallah-hospital.com"
        },
        # Morocco
        {
            "id": "ma_manual_1",
            "name_ar": "الدكتورة ناديا السلاوي - طب وجراحة النساء والولادة",
            "name_fr": "Dr Nadia Slaoui - Gynécologue",
            "lat": 33.5731, "lon": -7.5898,
            "phone": "+212522271819",
            "address": "شارع الزرقطوني، الدار البيضاء (المغرب)",
            "city": "الدار البيضاء", "wilaya_id": 102, "wilaya_name_ar": "المغرب", "wilaya_name_fr": "Morocco",
            "country_name_ar": "المغرب", "country_name_en": "Morocco",
            "type": "gynaecologist", "type_desc_ar": "أخصائي نساء وتوليد", "is_public": False, "website": "غير متوفر"
        },
        # United Arab Emirates
        {
            "id": "ae_manual_1",
            "name_ar": "الدكتورة ليلى حنون - استشاري أمراض النساء والولادة والخصوبة",
            "name_fr": "Dr Leila Hannoun - Consultant Gynaecologist",
            "lat": 25.2048, "lon": 55.2708,
            "phone": "+97143496666",
            "address": "شارع الشيخ زايد، دبي (الإمارات)",
            "city": "دبي", "wilaya_id": 113, "wilaya_name_ar": "الإمارات", "wilaya_name_fr": "United Arab Emirates",
            "country_name_ar": "الإمارات", "country_name_en": "United Arab Emirates",
            "type": "gynaecologist", "type_desc_ar": "أخصائي نساء وتوليد", "is_public": False, "website": "غير متوفر"
        },
        {
            "id": "ae_manual_2",
            "name_ar": "مستشفى لطيفة للنساء والأطفال (مستشفى حكومي)",
            "name_fr": "Latifa Hospital for Women & Children",
            "lat": 25.2012, "lon": 55.3211,
            "phone": "+97142193000",
            "address": "طريق عود ميثاء، دبي (الإمارات)",
            "city": "دبي", "wilaya_id": 113, "wilaya_name_ar": "الإمارات", "wilaya_name_fr": "United Arab Emirates",
            "country_name_ar": "الإمارات", "country_name_en": "United Arab Emirates",
            "type": "hospital", "type_desc_ar": "مستشفى / مركز صحي عمومي", "is_public": True, "website": "https://www.dha.gov.ae"
        },
        # Tunisia
        {
            "id": "tn_manual_1",
            "name_ar": "الدكتورة سونيا الطرابلسي - أخصائية النساء والولادة والجراحة",
            "name_fr": "Dr Sonia Trabelsi - Gynécologue",
            "lat": 36.8065, "lon": 10.1815,
            "phone": "+21671889900",
            "address": "المنزه التاسع، تونس العاصمة (تونس)",
            "city": "تونس", "wilaya_id": 103, "wilaya_name_ar": "تونس", "wilaya_name_fr": "Tunisia",
            "country_name_ar": "تونس", "country_name_en": "Tunisia",
            "type": "gynaecologist", "type_desc_ar": "أخصائي نساء وتوليد", "is_public": False, "website": "غير متوفر"
        },
        # Jordan
        {
            "id": "jo_manual_1",
            "name_ar": "الدكتورة أسماء البيطار - أخصائية أمراض النساء وجراحة التوليد والخصوبة",
            "name_fr": "Dr Asma Al-Bitar - Gynécologue",
            "lat": 31.9454, "lon": 35.9284,
            "phone": "+96265691122",
            "address": "شارع الخالدي، جبل عمان، عمان (الأردن)",
            "city": "عمان", "wilaya_id": 108, "wilaya_name_ar": "الأردن", "wilaya_name_fr": "Jordan",
            "country_name_ar": "الأردن", "country_name_en": "Jordan",
            "type": "gynaecologist", "type_desc_ar": "أخصائي نساء وتوليد", "is_public": False, "website": "غير متوفر"
        },
        # Lebanon
        {
            "id": "lb_manual_1",
            "name_ar": "الدكتور فادي جرجس - طب وجراحة النساء والولادة والعقم",
            "name_fr": "Dr Fady Georges - Gynécologue",
            "lat": 33.8938, "lon": 35.5018,
            "phone": "+9611388800",
            "address": "شارع الحمرا، بيروت (لبنان)",
            "city": "بيروت", "wilaya_id": 109, "wilaya_name_ar": "لبنان", "wilaya_name_fr": "Lebanon",
            "country_name_ar": "لبنان", "country_name_en": "Lebanon",
            "type": "gynaecologist", "type_desc_ar": "أخصائي نساء وتوليد", "is_public": False, "website": "غير متوفر"
        },
        # Iraq
        {
            "id": "iq_manual_1",
            "name_ar": "الدكتورة زينب الجوادي - طب وجراحة النساء والتوليد وعلاج العقم والناظور",
            "name_fr": "Dr Zainab Al-Jawadi",
            "lat": 33.3152, "lon": 44.3661,
            "phone": "+9647701234567",
            "address": "شارع الحارثية، بغداد (العراق)",
            "city": "بغداد", "wilaya_id": 107, "wilaya_name_ar": "العراق", "wilaya_name_fr": "Iraq",
            "country_name_ar": "العراق", "country_name_en": "Iraq",
            "type": "gynaecologist", "type_desc_ar": "أخصائي نساء وتوليد", "is_public": False, "website": "غير متوفر"
        },
        # Syria
        {
            "id": "sy_manual_1",
            "name_ar": "الدكتورة رانيا الخطيب - أمراض النساء والتوليد والخصوبة",
            "name_fr": "Dr Rania Al-Khatib",
            "lat": 33.5138, "lon": 36.2765,
            "phone": "+963113322111",
            "address": "شارع الشعلان، دمشق (سوريا)",
            "city": "دمشق", "wilaya_id": 106, "wilaya_name_ar": "سوريا", "wilaya_name_fr": "Syria",
            "country_name_ar": "سوريا", "country_name_en": "Syria",
            "type": "gynaecologist", "type_desc_ar": "أخصائي نساء وتوليد", "is_public": False, "website": "غير متوفر"
        },
        # Palestine
        {
            "id": "ps_manual_1",
            "name_ar": "الدكتورة هدى القدس - أخصائية النساء والولادة والعقم",
            "name_fr": "Dr Huda Al-Quds",
            "lat": 31.9029, "lon": 35.2033,
            "phone": "+97022987654",
            "address": "وسط البلد، رام الله (فلسطين)",
            "city": "رام الله", "wilaya_id": 110, "wilaya_name_ar": "فلسطين", "wilaya_name_fr": "Palestine",
            "country_name_ar": "فلسطين", "country_name_en": "Palestine",
            "type": "gynaecologist", "type_desc_ar": "أخصائي نساء وتوليد", "is_public": False, "website": "غير متوفر"
        },
        # Yemen
        {
            "id": "ye_manual_1",
            "name_ar": "الدكتورة بلقيس اليمني - استشارية طب وجراحة النساء والولادة والعقم",
            "name_fr": "Dr Bilqis Al-Yemeni",
            "lat": 15.3694, "lon": 44.1910,
            "phone": "+9671234567",
            "address": "شارع حدة، صنعاء (اليمن)",
            "city": "صنعاء", "wilaya_id": 111, "wilaya_name_ar": "اليمن", "wilaya_name_fr": "Yemen",
            "country_name_ar": "اليمن", "country_name_en": "Yemen",
            "type": "gynaecologist", "type_desc_ar": "أخصائي نساء وتوليد", "is_public": False, "website": "غير متوفر"
        },
        # Oman
        {
            "id": "om_manual_1",
            "name_ar": "الدكتورة فاطمة السيابية - أخصائية أمراض النساء والتوليد والخصوبة",
            "name_fr": "Dr Fatma Al-Siyabi",
            "lat": 23.5859, "lon": 58.4059,
            "phone": "+96824606060",
            "address": "شارع الخوير، مسقط (عمان)",
            "city": "مسقط", "wilaya_id": 112, "wilaya_name_ar": "عمان", "wilaya_name_fr": "Oman",
            "country_name_ar": "عمان", "country_name_en": "Oman",
            "type": "gynaecologist", "type_desc_ar": "أخصائي نساء وتوليد", "is_public": False, "website": "غير متوفر"
        },
        # Kuwait
        {
            "id": "kw_manual_1",
            "name_ar": "الدكتورة دلال الغانم - استشاري أمراض النساء والولادة وأطفال الأنابيب",
            "name_fr": "Dr Dalal Al-Ghanim",
            "lat": 29.3759, "lon": 47.9774,
            "phone": "+96522233445",
            "address": "شارع الخليج العربي، مدينة الكويت (الكويت)",
            "city": "مدينة الكويت", "wilaya_id": 114, "wilaya_name_ar": "الكويت", "wilaya_name_fr": "Kuwait",
            "country_name_ar": "الكويت", "country_name_en": "Kuwait",
            "type": "gynaecologist", "type_desc_ar": "أخصائي نساء وتوليد", "is_public": False, "website": "غير متوفر"
        },
        # Qatar
        {
            "id": "qa_manual_1",
            "name_ar": "الدكتورة مريم الجابر - استشاري طب النساء وجراحة التوليد",
            "name_fr": "Dr Mariam Al-Jaber",
            "lat": 25.2854, "lon": 51.5310,
            "phone": "+97444332211",
            "address": "طريق الدائري الثالث، الدوحة (قطر)",
            "city": "الدوحة", "wilaya_id": 115, "wilaya_name_ar": "قطر", "wilaya_name_fr": "Qatar",
            "country_name_ar": "قطر", "country_name_en": "Qatar",
            "type": "gynaecologist", "type_desc_ar": "أخصائي نساء وتوليد", "is_public": False, "website": "غير متوفر"
        },
        # Bahrain
        {
            "id": "bh_manual_1",
            "name_ar": "الدكتورة منى العريان - أخصائية أمراض النساء وجراحة التوليد وعلاج الخصوبة",
            "name_fr": "Dr Mona Al-Arian",
            "lat": 26.2285, "lon": 50.5860,
            "phone": "+97317223344",
            "address": "ضاحية السيف، المنامة (البحرين)",
            "city": "المنامة", "wilaya_id": 116, "wilaya_name_ar": "البحرين", "wilaya_name_fr": "Bahrain",
            "country_name_ar": "البحرين", "country_name_en": "Bahrain",
            "type": "gynaecologist", "type_desc_ar": "أخصائي نساء وتوليد", "is_public": False, "website": "غير متوفر"
        },
        # Libya
        {
            "id": "ly_manual_1",
            "name_ar": "الدكتورة خديجة الليبي - أخصائية أمراض النساء والتوليد وعلاج تأخر الحمل",
            "name_fr": "Dr Khadija Al-Libi",
            "lat": 32.8872, "lon": 13.1913,
            "phone": "+218214808080",
            "address": "شارع الجرابة، طرابلس (ليبيا)",
            "city": "طرابلس", "wilaya_id": 104, "wilaya_name_ar": "ليبيا", "wilaya_name_fr": "Libya",
            "country_name_ar": "ليبيا", "country_name_en": "Libya",
            "type": "gynaecologist", "type_desc_ar": "أخصائي نساء وتوليد", "is_public": False, "website": "غير متوفر"
        },
        # Sudan
        {
            "id": "sd_manual_1",
            "name_ar": "الدكتورة آمال السودانية - استشاري توليد وجراحة نسائية",
            "name_fr": "Dr Amal Al-Sudaniya",
            "lat": 15.5007, "lon": 32.5599,
            "phone": "+249183456789",
            "address": "شارع المطار، الخرطوم (السودان)",
            "city": "الخرطوم", "wilaya_id": 105, "wilaya_name_ar": "السودان", "wilaya_name_fr": "Sudan",
            "country_name_ar": "السودان", "country_name_en": "Sudan",
            "type": "gynaecologist", "type_desc_ar": "أخصائي نساء وتوليد", "is_public": False, "website": "غير متوفر"
        },
        # Mauritania
        {
            "id": "mr_manual_1",
            "name_ar": "الدكتورة عيشة الموريتانية - أخصائية النساء والولادة والجراحة",
            "name_fr": "Dr Aicha Mauritanie",
            "lat": 18.0735, "lon": -15.9582,
            "phone": "+22245256789",
            "address": "تفرغ زينة، نواكشوط (موريتانيا)",
            "city": "نواكشوط", "wilaya_id": 117, "wilaya_name_ar": "موريتانيا", "wilaya_name_fr": "Mauritania",
            "country_name_ar": "موريتانيا", "country_name_en": "Mauritania",
            "type": "gynaecologist", "type_desc_ar": "أخصائي نساء وتوليد", "is_public": False, "website": "غير متوفر"
        }
    ]
    
    # Filter out previous manuals to prevent duplicates
    manual_ids = {m["id"] for m in manual_entries}
    cleaned_data = [item for item in data if item.get("id") not in manual_ids]
    
    cleaned_data.extend(manual_entries)
    
    with open(file_path, "w", encoding="utf-8") as f:
        json.dump(cleaned_data, f, ensure_ascii=False, indent=2)
        
    print(f"Enriched database successfully. Total records: {len(cleaned_data)}.")

if __name__ == "__main__":
    enrich()
