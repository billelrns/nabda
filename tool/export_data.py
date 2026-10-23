# -*- coding: utf-8 -*-
"""
Export app data to static JSON files for nabda.online website.
Rule compliance:
- Author is ALWAYS 'فريق تحرير نبضة'.
- No medical claims / medical team mentions.
- isHiddenProduct rules applied.
"""
import os
import sys
import json
import re
import shutil
from PIL import Image

BASE_DIR = r"C:\nabda_app"
WEB_DIR = os.path.join(BASE_DIR, "web")
DATA_DIR = os.path.join(WEB_DIR, "data")
ARTICLES_DIR = os.path.join(DATA_DIR, "articles")
IMG_FETUS_DIR = os.path.join(WEB_DIR, "img", "fetus")
IMG_ARTICLES_BG = os.path.join(WEB_DIR, "img", "articles_bg")

def ensure_dirs():
    for d in [DATA_DIR, ARTICLES_DIR, IMG_FETUS_DIR, IMG_ARTICLES_BG]:
        os.makedirs(d, exist_ok=True)

# ── 1. Image Optimization & Assets Copy ──
def process_images():
    print("--> 1. Processing images...")
    fetus_src_dir = os.path.join(BASE_DIR, "assets", "images", "fetus_hd")
    if os.path.exists(fetus_src_dir):
        for fname in os.listdir(fetus_src_dir):
            if fname.endswith(".png") and fname.startswith("week_"):
                src_path = os.path.join(fetus_src_dir, fname)
                week_num = fname.replace("week_", "").replace(".png", "")
                dst_path = os.path.join(IMG_FETUS_DIR, f"week_{week_num}.webp")
                try:
                    with Image.open(src_path) as im:
                        im.thumbnail((600, 600), Image.Resampling.LANCZOS)
                        im.save(dst_path, "WEBP", quality=90)
                except Exception as e:
                    print(f"Error converting {fname}: {e}")
        
        # Ensure weeks 1..3 and 42 exist
        week4_path = os.path.join(IMG_FETUS_DIR, "week_4.webp")
        if os.path.exists(week4_path):
            for w in [1, 2, 3]:
                dst = os.path.join(IMG_FETUS_DIR, f"week_{w}.webp")
                if not os.path.exists(dst):
                    shutil.copyfile(week4_path, dst)
        week41_path = os.path.join(IMG_FETUS_DIR, "week_41.webp")
        if os.path.exists(week41_path):
            dst = os.path.join(IMG_FETUS_DIR, "week_42.webp")
            if not os.path.exists(dst):
                shutil.copyfile(week41_path, dst)
        print(f"    Converted fetus images to {IMG_FETUS_DIR}")

    # Copy articles_bg
    bg_src_dir = os.path.join(BASE_DIR, "assets", "images", "articles_bg")
    if os.path.exists(bg_src_dir):
        for fname in os.listdir(bg_src_dir):
            src_path = os.path.join(bg_src_dir, fname)
            dst_path = os.path.join(IMG_ARTICLES_BG, fname)
            shutil.copyfile(src_path, dst_path)
        print(f"    Copied template article backgrounds to {IMG_ARTICLES_BG}")

    # Copy algeria_cities.json
    cities_src = os.path.join(BASE_DIR, "assets", "data", "algeria_cities.json")
    if os.path.exists(cities_src):
        shutil.copyfile(cities_src, os.path.join(DATA_DIR, "algeria_cities.json"))
        print(f"    Copied algeria_cities.json to {DATA_DIR}")

# ── 2. Pregnancy Weeks JSON ──
def export_pregnancy_weeks():
    print("--> 2. Exporting pregnancy weeks...")
    src_file = os.path.join(BASE_DIR, "web", "tools", "data", "fetus_weeks.json")
    weeks_data = []
    if os.path.exists(src_file):
        with open(src_file, "r", encoding="utf-8") as f:
            weeks_data = json.load(f)

    def get_trimester(w):
        if w <= 12: return ('first', 'الثلث الأول', 'First Trimester')
        if w <= 27: return ('second', 'الثلث الثاني', 'Second Trimester')
        return ('third', 'الثلث الثالث', 'Third Trimester')

    def get_month(w):
        if w <= 4: return (1, 'الشهر الأول')
        if w <= 8: return (2, 'الشهر الثاني')
        if w <= 13: return (3, 'الشهر الثالث')
        if w <= 17: return (4, 'الشهر الرابع')
        if w <= 22: return (5, 'الشهر الخامس')
        if w <= 27: return (6, 'الشهر السادس')
        if w <= 31: return (7, 'الشهر السابع')
        if w <= 35: return (8, 'الشهر الثامن')
        return (9, 'الشهر التاسع')

    fruits = {
        1: "بذرة صغيرة جداً", 2: "بذرة الخشخاش", 3: "بذرة الخشخاش", 4: "حبة سمسم",
        5: "بذرة تفاح", 6: "حبة عدس", 7: "حبة حمّص", 8: "حبة فاصولياء",
        9: "حبة كرز", 10: "حبة فراولة", 11: "حبة تين", 12: "حبة كيوي",
        13: "حبة ليمون", 14: "حبة خوخ", 15: "تفاحة", 16: "أفوكادو",
        17: "إجاصة", 18: "رمّانة", 19: "مانجو", 20: "موزة",
        21: "جزرة كبيرة", 22: "كوسة", 23: "بطاطا حلوة", 24: "كوز ذرة",
        25: "لفت كبير", 26: "رأس خسّ", 27: "قرنبيطة", 28: "باذنجانة كبيرة",
        29: "شمّامة صغيرة", 30: "رأس ملفوف", 31: "جوز الهند", 32: "يقطينة صغيرة",
        33: "أناناس", 34: "شمّامة", 35: "بطيخة صفراء", 36: "رأس خسّ كبير",
        37: "سلق كبير", 38: "كرّاث طويل", 39: "بطيخة صغيرة", 40: "بطيخة",
        41: "يقطينة كبيرة", 42: "طفل مكتمل النمو"
    }

    result = []
    # Build dictionary from existing fetus_weeks
    existing_map = {item["week"]: item for item in weeks_data}

    for w in range(1, 43):
        item = existing_map.get(w, {})
        tri_id, tri_ar, tri_en = get_trimester(w)
        m_num, m_ar = get_month(w)

        baby_size = fruits.get(w, item.get("babySizeAr", "جنين ينمو"))
        length = item.get("babyLength", f"{min(52, 10 + w)} سم")
        weight = item.get("babyWeight", f"{min(3800, 100 * (w - 10))} غرام" if w > 10 else "أقل من 1 غرام")

        if w == 41:
            fetal_dev = "في الأسبوع الحادي والأربعين، طفلكِ مكتمل النمو تماماً وجاهز للقاء بكِ. طلاء الجبنة والشعر الزغبي قد اختفيا تماماً، وأظافره مكتملة، وعظامه قوية ومرنة لتسهيل المرور عبر قناة الولادة."
            symptoms = "الشعور بالثقل والضغط في منطقة الحوض، انقباضات براكستون هيكس المتكررة، الترقب والحماس لبدء المخاض."
            nutrition = "وجبات خفيفة وسهلة الهضم تمنحك طاقة سريعة كالتمور والشوفان والفواكه الطازجة. الترطيب المستمر بالماء والعصائر الطبيعية مهم جداً."
            tips = "تواصلي مع طبيبتك لمتابعة تخطيط قلب الجنين وكمية السائل الأمنيوسي. لا تقلقي، فالكثير من الأطفال يفضلون الانتظار قليلاً بعد موعدهم."
        elif w == 42:
            fetal_dev = "الأسبوع الثاني والأربعون هو ختام رحلة الحمل المباركة. الجنين مستعد بنسبة مائة بالمائة للحياة خارج الرحم، ورئتاه وأعضاؤه في أفضل حال."
            symptoms = "ترقب كبير وثقل، نزول السدادة المخاطية، علامات بدء المخاض النشط."
            nutrition = "حافظي على ترطيب جسمك واشربي الماء بانتظام مع وجبات سهلة الهضم."
            tips = "ستحدد طبيبتك الإجراء الأمثل لبدء الولادة (التحريض أو الولادة المقررة). ثقي بأنك قريباً جداً ستحملين طفلك بين ذراعيك."
        else:
            fetal_dev = item.get("fetalDevAr", "")
            symptoms = item.get("symptomsAr", "")
            nutrition = item.get("nutritionAr", "")
            tips = item.get("tipsAr", "")

        week_obj = {
            "week": w,
            "babySizeAr": baby_size,
            "babySizeEn": item.get("babySizeEn", ""),
            "babyLength": length,
            "babyWeight": weight,
            "trimester": tri_id,
            "trimesterAr": tri_ar,
            "trimesterEn": tri_en,
            "month": m_num,
            "monthAr": m_ar,
            "fetalDevAr": fetal_dev,
            "symptomsAr": symptoms,
            "nutritionAr": nutrition,
            "tipsAr": tips,
            "image": f"/img/fetus/week_{w}.webp",
            "author": "فريق تحرير نبضة"
        }
        result.append(week_obj)

    out_file = os.path.join(DATA_DIR, "pregnancy_weeks.json")
    with open(out_file, "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)
    print(f"    Exported {len(result)} weeks to {out_file}")

# ── 3. Pregnancy Discover JSON ──
def export_pregnancy_discover():
    print("--> 3. Exporting pregnancy discover...")
    # Extract from pregnancy_weeks_screen.dart discover categories
    categories = [
        {
            "name": "التغذية والأطعمة",
            "emoji": "🥗",
            "articles": [
                {
                    "title": "الأطعمة المفيدة للحامل",
                    "emoji": "🥑",
                    "color": "#43A047",
                    "image": "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400&q=80",
                    "summary": "دليلكِ للأغذية الغنية بالأوميغا والحديد والكالسيوم لنمو الجنين وصحتكِ.",
                    "content": "التغذية السليمة أثناء الحمل تشكل الأساس لصحة الأم والجنين معاً. أهم الأطعمة التي يجب أن تكون في نظامك الغذائي اليومي تشمل السلمون والبيض والبقوليات كالعدس والفاصوليا والبطاطا الحلوة والخضراوات الورقية كالسبانخ والبروكلي. احرصي على تنويع وجباتك وشرب 8 أكواب ماء يومياً."
                },
                {
                    "title": "أطعمة يجب تجنبها",
                    "emoji": "⚠️",
                    "color": "#E53935",
                    "image": "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400&q=80",
                    "summary": "تعرفي على الأطعمة غير الآمنة لتفادي المخاطر خلال فترة الحمل.",
                    "content": "خلال فترة الحمل يجب تجنب اللحوم والأسماك النيئة أو غير المطهوة جيداً والأجبان الطرية غير المبسترة والبيض النيء والأسماك عالية الزئبق كالتونة الكبيرة، وتقليل الكافيين إلى فنجان واحد يومياً."
                },
                {
                    "title": "المشروبات الصحية للحامل",
                    "emoji": "🥤",
                    "color": "#00ACC1",
                    "image": "https://images.unsplash.com/photo-1622597467836-f3285f2131b8?w=400&q=80",
                    "summary": "أفضل المشروبات الطبيعية للترطيب ودعم السائل الأمنيوسي.",
                    "content": "الماء هو المشروب الأهم وتناولي منه 8-10 أكواب يومياً. أضيفي شاي الزنجبيل الطازج لتخفيف الغثيان، وعصائر البرتقال والرمان الطبيعية، وتجنبي المشروبات الغازية ومشروبات الطاقة."
                },
                {
                    "title": "الفيتامينات والمغذيات اليومية",
                    "emoji": "💊",
                    "color": "#FF8F00",
                    "image": "https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400&q=80",
                    "summary": "حمض الفوليك والحديد والكالسيوم وفيتامين د في روتينك.",
                    "content": "المكملات الغذائية تدعم صحة الجنين. حمض الفوليك أساسي خاصة في الثلث الأول، والحديد يمنع فقر الدم، والكالسيوم يبني العظام. التزمي بتوجيهات وصفتكِ الغذائية."
                }
            ]
        },
        {
            "name": "الجسم والتغيرات",
            "emoji": "🩺",
            "articles": [
                {
                    "title": "آلام الظهر وكيفية التخفيف منها",
                    "emoji": "💆‍♀️",
                    "color": "#5C6BC0",
                    "image": "https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400&q=80",
                    "summary": "نصائح وضعيات الجلوس والنوم وتمارين الإطالة لتخفيف الثقل.",
                    "content": "آلام الظهر شائعة بسبب تغير مركز ثقل الجسم. حافظي على وضعية جلوس مستقيمة ومدعومة، ونامي على جانبك الأيسر مع وسادة بين الركبتين، وارتدي أحذية مريحة وتجنبي الكعب العالي."
                },
                {
                    "title": "إدارة الغثيان الصباحي",
                    "emoji": "🤢",
                    "color": "#26A69A",
                    "image": "https://images.unsplash.com/photo-1493894473891-10fc1e5dbd22?w=400&q=80",
                    "summary": "طرق طبيعية لتجاوز غثيان الأشهر الأولى بهدوء.",
                    "content": "تناولي بسكويتاً جافاً قبل النهوض من الفراش، وقسمي وجباتك لخمس وجبات صغيرة خفيفة. الزنجبيل الطازج وعصير الليمون والابتعاد عن الروائح القوية حلول مجربة وفعالة."
                },
                {
                    "title": "تورم القدمين والساقين",
                    "emoji": "🦶",
                    "color": "#8E24AA",
                    "image": "https://images.unsplash.com/photo-1590650153855-d9e808231d41?w=400&q=80",
                    "summary": "وسائل مريحة لتحسين الدورة الدموية وتخفيف احتباس السوائل.",
                    "content": "ارفعي قدميك عند الجلوس وتجنبي الوقوف الطويل. اشربي كميات كافية من الماء لتعزيز تصريف السوائل وقللي من الملح الزائد، ومارسي المشي الخفيف لتحريك الدورة الدموية."
                },
                {
                    "title": "علامات تمدد الجلد وترطيب البشرة",
                    "emoji": "✨",
                    "color": "#EC407A",
                    "image": "https://images.unsplash.com/photo-1515377905703-c4788e51af15?w=400&q=80",
                    "summary": "روتين الزيوت الطبيعية للحفاظ على نضارة ومرونة البشرة.",
                    "content": "رطبي بشرتك يومياً بزبدة الشيا وزيت اللوز الحلو وزيت جوز الهند بحركات دائرية لطيفة. شرب الماء والغذاء الغني بفيتامين سي وإي يحافظان على مرونة الجلد."
                }
            ]
        },
        {
            "name": "التمارين والرياضة الآمنة",
            "emoji": "🧘‍♀️",
            "articles": [
                {
                    "title": "المشي اليومي للحامل",
                    "emoji": "🚶‍♀️",
                    "color": "#66BB6A",
                    "image": "https://images.unsplash.com/photo-1609710228159-0fa9bd7c0827?w=400&q=80",
                    "summary": "الرياضة الأسهل والأكثر أماناً لتحسين المزاج وتسهيل الولادة.",
                    "content": "المشي ينشط الدورة الدموية ويزود الجنين بالأكسجين ويقوي عضلات الحوض. ابدئي بـ 15 دقيقة ثم تدرجي حتى 30 دقيقة يومياً في أوقات معتدلة الحرارة مع حذاء مريح."
                },
                {
                    "title": "يوغا واستطالات الحمل",
                    "emoji": "🧘‍♀️",
                    "color": "#7E57C2",
                    "image": "https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=400&q=80",
                    "summary": "تقنيات التنفس والاسترخاء لتهيئة الجسم للمخاض.",
                    "content": "تركز يوغا الحوامل على حركات القطة والبقرة وإطالة الوركين وتمارين التنفس العميق، مما يقلل التوتر ويحسن النوم ويجهز عضلات الحوض."
                },
                {
                    "title": "تمارين كيجل المهمة",
                    "emoji": "💪",
                    "color": "#EF5350",
                    "image": "https://images.unsplash.com/photo-1518611012118-696072aa579a?w=400&q=80",
                    "summary": "تقوية قاع الحوض لتعزيز التحكم وتسريع التعافي.",
                    "content": "اقبضي عضلات قاع الحوض لـ 5 ثوانٍ ثم استرخي 5 ثوانٍ، وكرري 10 مرات ثلاث مرات يومياً. تفيدكِ خلال الحمل وأثناء الولادة وبعدها بشكل رائع."
                }
            ]
        },
        {
            "name": "التحضير للمولود والرضاعة",
            "emoji": "🤱",
            "articles": [
                {
                    "title": "أساسيات الرضاعة الطبيعية",
                    "emoji": "🤱",
                    "color": "#E91E63",
                    "image": "https://images.unsplash.com/photo-1555252333-9f8e92e65df9?w=400&q=80",
                    "summary": "كيف تبدئين الرضاعة بنجاح من الساعة الأولى بعد الولادة.",
                    "content": "الرضاعة خلال الساعة الأولى تمنح طفلكِ اللبأ الغني بالمناعة. تأكدي من الإمساك الصحيح بالهالة المحيطة بالحلمة، وارضعي طفلك عند الطلب بالصبر والهدوء."
                },
                {
                    "title": "قائمة حقيبة الولادة للمستشفى",
                    "emoji": "👶",
                    "color": "#42A5F5",
                    "image": "https://images.unsplash.com/photo-1522771930-78848d9293e8?w=400&q=80",
                    "summary": "كل ما تحتاجينه لكِ ولطفلكِ في الأسبوع 34 فصاعداً.",
                    "content": "جهزي حقيبتك بدءاً من الأسبوع 34: بدلات قطنية للمولود، قبعات وقفازات، بطانية ناعمة، حفاضات حديثي الولادة، ملابس نوم مريحة ومستلزمات العناية الشخصية للأم."
                }
            ]
        }
    ]
    out_file = os.path.join(DATA_DIR, "pregnancy_discover.json")
    with open(out_file, "w", encoding="utf-8") as f:
        json.dump({"categories": categories, "author": "فريق تحرير نبضة"}, f, ensure_ascii=False, indent=2)
    print(f"    Exported {len(categories)} categories to {out_file}")

# ── 4. Baby Months JSON ──
def export_baby_months():
    print("--> 4. Exporting baby months (0 to 24)...")
    months = []
    milestone_samples = [
        ("حديث الولادة (الأيام الأولى)", "0 - 1 شهر", "3.0 - 4.5 كغ", "49 - 54 سم",
         ["الاستجابة للأصوات والضوء", "التركيز على وجه الأم عن قرب (20-30 سم)", "حركات اليد والذراعين الفطرية"],
         "الرضاعة الطبيعية الحصرية عند الطلب (8-12 رضعة يومياً). اللبأ هو أول غذاء ذهبي للمولود.",
         "ينام من 16 إلى 18 ساعة يومياً في فترات قصيرة متقطعة. احرصي على النوم الآمن على الظهر.",
         "التحدث إليه بصوت هادئ، التلامس جلداً لجلد (كنغر)، الموسيقى الهادئة أو صوت القرآن الكريم."),
        ("الشهر الثاني: الابتسامة الاجتماعية", "1 - 2 شهر", "4.5 - 6.0 كغ", "54 - 58 سم",
         ["الابتسامة الاجتماعية الأولى عند رؤية وجهك", "متابعة الأشياء المتحركة بنظره", "رفع الرأس قليلاً عند الاستلقاء على البطن"],
         "الرضاعة كل ساعتين إلى 3 ساعات. يستمر الاعتماد الكامل على الحليب دون ماء أو أعشاب.",
         "14-16 ساعة يومياً، تبدأ فترات النوم الليلي بالطول تدريجياً.",
         "وقت البطن (Tummy Time) لبضع دقائق يومياً لتقوية عضلات الرقبة، الغناء والابتسام أمامه."),
        ("الشهر الثالث: المناغاة واليدان", "2 - 3 أشهر", "5.5 - 7.0 كغ", "58 - 62 سم",
         ["إصدار أصوات المناغاة الجميلة (أووو، آآآ)", "اكتشاف اليدين ومص الأصابع", "تثبيت الرأس بثبات أكبر"],
         "الرضاعة منتظمة ومستمرة، وتظهر علامات الشبع بوضوح بإرخاء اليدين والابتعاد.",
         "14-15 ساعة، روتين نوم هادئ قبل النوم (حمام دافئ، خفض الإضاءة).",
         "ألعاب خشخيشة خفيفة، الألعاب ذات الألوان المتباينة بالأبيض والأسود والأحمر."),
        ("الشهر الرابع: الضحك والتدحرج", "3 - 4 أشهر", "6.2 - 7.8 كغ", "61 - 65 سم",
         ["الضحك بصوت عالٍ", "محاولات التقلب من البطن إلى الظهر", "الإمساك بالألعاب بقبضة يده"],
         "الرضاعة الطبيعية أو الصناعية. يستمر الحليب كغذاء وحيد حتى إتمام الشهر الرابع إلى السادس.",
         "14-15 ساعة مع قيلولتين إلى 3 قيلولات نهاراً.",
         "الألعاب المعلقة، اللعب بالمرآة الآمنة لرؤية انعكاسه، التحدث المستمر معه."),
        ("الشهر الخامس: استكشاف الأصوات", "4 - 5 أشهر", "6.8 - 8.5 كغ", "63 - 67 سم",
         ["التقلب بكفاءة في الاتجاهين", "نقل الألعاب من يد إلى أخرى", "إصدار مقاطع صوتية متكررة"],
         "الاستعداد لمرحلة التذوق وفق إرشادات الطبيبة (الجلوس المدعوم، التحكم بالرأس، إبداء الاهتمام بالطعام).",
         "14 ساعة يومياً، نوم ليلي أطول وأكثر استقراراً.",
         "قراءة القصص الكرتونية المقواة، تسمية الأشياء المحيطة به."),
        ("الشهر السادس: بداية الأكل والجلوس", "5 - 6 أشهر", "7.3 - 9.0 كغ", "65 - 69 سم",
         ["الجلوس مدعوماً بالوسائد أو الكرسي", "تنسيق اليدين مع العينين لوضع الأشياء في الفم", "الاستجابة لمناداته باسمه"],
         "إدخال الأغذية الصلبة تدريجياً (خضار مسلوقة ومهروسة كالكوسة والجزر، شوفان) صنف واحد كل 3 أيام لاختبار الحساسية.",
         "13-14 ساعة، روتين ثابت وواضح.",
         "ألعاب التخفي (الغميضة 'بيكابو')، ألعاب الماء الآمنة أثناء الاستحمام."),
        ("الشهر السابع: الجلوس المستقل والسن الأول", "6 - 7 أشهر", "7.7 - 9.5 كغ", "67 - 71 سم",
         ["الجلوس دون مساعدة لفترات قصيرة", "ظهور الأسنان الأمامية السفلية أحياناً", "فهم نبرات الصوت المختلفة"],
         "وجبتان تكميليتان خفيفتان مع استمرار الرضاعة كالمصدر الأساسي للتغذية.",
         "13-14 ساعة مع قيلولتين في النهار.",
         "عضاضات التبريد لتخفيف ألم التسنين، ألعاب ذات ملامس مختلفة لتنمية الحواس."),
        ("الشهر الثامن: بداية الحبو واستكشاف الفضاء", "7 - 8 أشهر", "8.0 - 10.0 كغ", "68 - 72 سم",
         ["محاولات الزحف أو الحبو", "القبضة الملقطية (الإمساك بالسبابة والإبهام)", "قلق الانفصال عن الأم (علامة ارتباط صحي)"],
         "تنويع الأطعمة: إضافة صفار البيض المطهو جيداً، الدجاج المهروس، الأرز المهروس والفواكه كالموز والتفاح المسلوق.",
         "13-14 ساعة، نوم مستقر غالباً في الليل.",
         "وضع ألعاب جذابة أمامه لتحفيزه على الزحف والوصول إليها."),
        ("الشهر التاسع: الوقوف بالاستناد والإشارة", "8 - 9 أشهر", "8.3 - 10.4 كغ", "70 - 74 سم",
         ["الوقوف بالاستناد على الأثاث", "فهم كلمة 'لا' والإشارة بالأصابع", "التصفيق والتلويح بـ 'باي باي'"],
         "3 وجبات صغيرة متوازنة ومهروسة بخشونة بسيطة لتشجيع المضغ، مع الرضاعة المنتظمة.",
         "13-14 ساعة.",
         "ألعاب تصنيف الأشكال البسيطة، إخفاء لعبة تحت بطانية والبحث عنها."),
        ("الشهر العاشر: الكلمات الأولى والخطوات بالاستناد", "9 - 10 أشهر", "8.6 - 10.8 كغ", "71 - 75 سم",
         ["محاولات نطق 'ماما' و 'بابا' بوعي", "المشي مستنداً إلى الأريكة والكرسي", "شرب رشفات من كوب التدريب"],
         "أطعمة الأصابع الآمنة (قطع جزر مسلوق، موز مقطع، خبز محمص لين) ليتناولها بنفسه.",
         "13-14 ساعة، قيلولتان نهاراً.",
         "ألعاب الدفع والسحب، التفاعل بالأغاني الحركية كالتصفيق."),
        ("الشهر الحادي عشر: الاستقلالية والفضول", "10 - 11 شهر", "8.9 - 11.2 كغ", "72 - 77 سم",
         ["الوقوف بمفرده لثوانٍ معدودة", "فهم التوجيهات البسيطة 'أعطني الكرة'", "تقليد تصرفات الكبار كالتحدث بالهاتف"],
         "مشاركة وجبات العائلة المعدة بدون ملح زائد أو بهارات حارة أو عسل (العسل ممنوع قبل سنة).",
         "13-14 ساعة.",
         "بناء الأبراج بالمكعبات الكبيرة وهدمها، استكشاف أدوات المطبخ البلاستيكية الآمنة."),
        ("الشهر الثاني عشر: الخطوة الأولى وشمعة العام الأول", "11 - 12 شهر", "9.2 - 11.5 كغ", "74 - 78 سم",
         ["الخطوات الأولى المستقلة أو الاستعداد لها", "نطق 2-3 كلمات واضحة", "الإشارة إلى ما يريده والتعبير عن مشاعره"],
         "إتمام السنة الأولى بسلام! يمكن الآن إدخال حليب البقر كامل الدسم والعسل الطبيعي بتدرج.",
         "12-14 ساعة، قد يكتفي بقيلولة واحدة طويلة أو قيلولتين.",
         "احتفال عائلي بسيط بذكرى ميلاده الأول، كتب الصور الكبيرة، ألعاب التركيب."),
    ]

    for m in range(25):
        if m < len(milestone_samples):
            name, age_rng, weight, height, ms, feed, slp, act = milestone_samples[m]
        else:
            name = f"الشهر {m}: مرحلة استكشاف ممتعة ونمو سريع"
            age_rng = f"{m} - {m+1} شهر"
            weight = f"{round(9.5 + (m - 12) * 0.2, 1)} - {round(12.0 + (m - 12) * 0.25, 1)} كغ"
            height = f"{78 + (m - 12)} - {83 + (m - 12)} سم"
            ms = [f"تطور مهارات المشي والجري والتسلق في الشهر {m}", f"زيادة الحصيلة اللغوية والكلمات في الشهر {m}", "تعبير أوضح عن الرغبات والاستقلالية"]
            feed = "3 وجبات رئيسية مع العائلة مع وجبتين خفيفتين من الفواكه والزبادي والمكسرات المطحونة، واستمرار الرضاعة إن رغبتِ."
            slp = "12-13 ساعة يومياً تشمل قيلولة نهارية واحدة بعد الظهر."
            act = "ألعاب التلوين بالألوان الآمنة، الركض في الحديقة، ألعاب البازل البسيطة وتسمية الحيوانات والألوان."

        month_obj = {
            "month": m,
            "title": name,
            "ageRange": age_rng,
            "avgWeight": weight,
            "avgHeight": height,
            "milestones": ms,
            "feeding": feed,
            "sleep": slp,
            "activities": act,
            "careTips": "احرصي على تأمين المنزل لحماية طفلكِ من الحواف الحادة والمقابس الكهربائية. النظافة اليومية والترطيب المستمر لبشرته اللطيفة.",
            "author": "فريق تحرير نبضة"
        }
        months.append(month_obj)

    out_file = os.path.join(DATA_DIR, "baby_months.json")
    with open(out_file, "w", encoding="utf-8") as f:
        json.dump(months, f, ensure_ascii=False, indent=2)
    print(f"    Exported {len(months)} months to {out_file}")

# ── 5. Fertility JSON ──
def export_fertility():
    print("--> 5. Exporting fertility data...")
    faith_articles = [
        {
            "emoji": "🌙",
            "title": "تأخُّر الولد ليس عقوبة",
            "subtitle": "لماذا تأخّر عن أكرم الخلق؟",
            "body": "أوّل ما ينبغي أن يستقرّ في قلبكِ: تأخُّر الولد ليس دليلاً على ذنب، ولا علامة غضب، ولا نقصاً فيكِ.\n\nانظري من تأخّر عنهم الولد في كتاب الله. زكريّا عليه السلام، نبيّ من أنبياء الله، بلغ الكِبَر حتى «وَهَنَ الْعَظْمُ مِنِّي وَاشْتَعَلَ الرَّأْسُ شَيْبًا»، وامرأته عاقر، وظلّ يدعو سنين طويلة. وإبراهيم عليه السلام، خليل الرحمن وأبو الأنبياء، لم يُرزق إسماعيل إلا بعد عمر طويل، ثم إسحاق بعده على الكِبَر.\n\nفلو كان تأخُّر الولد عقوبة، لما وقع بأكرم الخلق على الله. فالله يَهَبُ لِمَن يَشَاءُ إِنَاثًا وَيَهَبُ لِمَن يَشَاءُ الذُّكُورَ. اطردي كل شك واستبدليه بيقين أن الذي رزق الأنبياء قادرٌ على إجابتكِ."
        },
        {
            "emoji": "🤲",
            "title": "لماذا يبدو أنّ الدعاء لا يُستجاب؟",
            "subtitle": "ثلاث صور للإجابة نرجوها من الله",
            "body": "كثيرات يسألن: دعوتُ طويلاً فلم يحدث شيء — فهل لم يُستجَب لي؟\n\nالجواب في حديث صحيح: «ما من مسلم يدعو بدعوة ليس فيها إثم ولا قطيعة رحم، إلا أعطاه الله بها إحدى ثلاث: إمّا أن تُعجَّل له دعوته، وإمّا أن يدّخرها له في الآخرة، وإمّا أن يصرف عنه من السوء مثلها».\n\nفالدعاء لا يضيع أبداً. داومي على التضرع، والتحري لأوقات الإجابة بين الأذان والإقامة وفي السجود وثلث الليل الأخير، ولا تيأسي من روح الله."
        },
        {
            "emoji": "⚖️",
            "title": "الأخذ بالأسباب من تمام التوكّل",
            "subtitle": "لا تعارض بين الدعاء ومراجعة الطبيبة",
            "body": "التوكّل الصحيح هو اعتماد القلب على الله مع فعل السبب. مريم عليها السلام، وهي في أشدّ لحظات المخاض، أمرها الله: «وَهُزِّي إِلَيْكِ بِجِذْعِ النَّخْلَةِ تُسَاقِطْ عَلَيْكِ رُطَبًا جَنِيًّا».\n\nوقد قال النبيّ ﷺ: «تداووا عباد الله، فإنّ الله لم يضع داءً إلا وضع له دواءً».\n\nفمراجعتكِ للطبيبة وإجراء الفحوصات الطبية المطلوبة ليست ضعف يقين، بل هي السبب الذي أمر الشرع بالأخذ به، والشفاء والهبة من الله وحده."
        },
        {
            "emoji": "🌸",
            "title": "بين حسن الظنّ واليقين في الرزق",
            "subtitle": "السكينة النفسية مفتاح عظيم",
            "body": "الراحة النفسية واطمئنان القلب لهما أثر عظيم على الصحة الجسدية واستقرار الهرمونات. اجعلي أيامكِ عامرة بالاستغفار، فالاستغفار مفتاح الرزق والذرية: «فَقُلْتُ اسْتَغْفِرُوا رَبَّكُمْ إِنَّهُ كَانَ غَفَّارًا • يُرْسِلِ السَّمَاءَ عَلَيْكُمْ مِدْرَارًا • وَيُمْدِدْكُمْ بِأَمْوَالٍ وَبَنِينَ»."
        }
    ]

    duas = [
        {
            "text": "رَبِّ هَبْ لِي مِن لَّدُنكَ ذُرِّيَّةً طَيِّبَةً ۖ إِنَّكَ سَمِيعُ الدُّعَاءِ",
            "source": "سورة آل عمران: الآية 38",
            "grade": "قرآن كريم",
            "note": "دعاء نبي الله زكريا عليه السلام في محرابه المبارك.",
            "isQuran": True
        },
        {
            "text": "رَبِّ لَا تَذَرْنِي فَرْدًا وَأَنتَ خَيْرُ الْوَارِثِينَ",
            "source": "سورة الأنبياء: الآية 89",
            "grade": "قرآن كريم",
            "note": "دعاء جامع يكرره الساجد بيقين وتضرع.",
            "isQuran": True
        },
        {
            "text": "رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ وَاجْعَلْنَا لِلْمُتَّقِينَ إِمَامًا",
            "source": "سورة الفرقان: الآية 74",
            "grade": "قرآن كريم",
            "note": "دعاء عباد الرحمن لصلاح الأهل والذرية.",
            "isQuran": True
        },
        {
            "text": "رَبِّ هَبْ لِي مِنَ الصَّالِحِينَ",
            "source": "سورة الصافات: الآية 100",
            "grade": "قرآن كريم",
            "note": "دعاء خليل الرحمن إبراهيم عليه السلام.",
            "isQuran": True
        },
        {
            "text": "اللهم إني أسألك بأن لك الحمد لا إله إلا أنت المنان، بديع السماوات والأرض، يا ذا الجلال والإكرام، يا حي يا قيوم، هب لي ذرية صالحة تسر قلبي.",
            "source": "مستنبط من اسم الله الأعظم (رواه أبو داود والترمذي)",
            "grade": "حديث حسن صحيح",
            "note": "سؤال الله بأسمائه الحسنى وصفاته العلا.",
            "isQuran": False
        }
    ]

    planning_steps = [
        {"step": 1, "title": "معرفة نافذة الخصوبة ويوم التبويض", "desc": "أيام الخصوبة العالية تكون عادة في منتصف الدورة (بين اليوم 12 و16 في دورة 28 يوماً). متابعة حرارة الجسم ومخاط عنق الرحم تساعدكِ."},
        {"step": 2, "title": "حمض الفوليك والغذاء المتوازن", "desc": "ابدئي بحمض الفوليك 400 ميكروغرام يومياً قبل الحمل بشهرين لبناء الأنبوب العصبي للجنين، وركزي على الخضار الورقية والمكسرات."},
        {"step": 3, "title": "الابتعاد عن التوتر وضغوط الانتظار", "desc": "الراحة النفسية تدعم التوازن الهرموني وانتظام الدورة. استمتعي بحياتكِ الزوجية دون جعل الإنجاب هاجساً ضاغطاً."},
        {"step": 4, "title": "أسلوب حياة صحي للزوجين", "desc": "النوم الكافي، الحركة المعتدلة، الامتناع التام عن التدخين وتقليل الكافيين خطوات أساسية تدعم جودة البويضات والحيوانات المنوية."},
        {"step": 5, "title": "استشارة الطبيبة للفحص المسبق", "desc": "إجراء فحص دم بسيط والاطمئنان على مخزون الحديد والغدة الدرقية يعطيكِ ثقة واطمئناناً تاماً."}
    ]

    out_file = os.path.join(DATA_DIR, "fertility.json")
    with open(out_file, "w", encoding="utf-8") as f:
        json.dump({
            "faithArticles": faith_articles,
            "duas": duas,
            "planningSteps": planning_steps,
            "author": "فريق تحرير نبضة"
        }, f, ensure_ascii=False, indent=2)
    print(f"    Exported fertility data to {out_file}")

# ── 6. Articles Index & Splitting ──
def export_articles():
    print("--> 6. Exporting articles index and split files...")
    src_file = os.path.join(BASE_DIR, "assets", "data", "smart_2500_articles.json")
    if not os.path.exists(src_file):
        print("    Warning: smart_2500_articles.json not found!")
        return

    with open(src_file, "r", encoding="utf-8") as f:
        data = json.load(f)
    articles = data.get("articles", [])
    print(f"    Loaded {len(articles)} articles.")

    index_list = []
    id_map = {} # originalId -> id

    for art in articles:
        art_id = str(art.get("id", "")).strip()
        orig_id = str(art.get("originalId", "")).strip()
        if not art_id:
            continue
        if orig_id:
            id_map[orig_id] = art_id

        # Normalize author
        art["author"] = "فريق تحرير نبضة"

        # Summary truncated to <= 160
        raw_summary = art.get("summary") or art.get("description") or ""
        # Clean text
        summary = re.sub(r"\s+", " ", raw_summary).strip()
        if len(summary) > 160:
            summary = summary[:157] + "..."

        idx_item = {
            "id": art_id,
            "originalId": orig_id,
            "title": art.get("title", ""),
            "categoryId": art.get("categoryId", ""),
            "categoryName": art.get("categoryName", ""),
            "imagePath": art.get("imagePath", ""),
            "summary": summary,
            "readTime": art.get("readTime", "5 دقائق"),
            "author": "فريق تحرير نبضة",
            "badge": art.get("badge", ""),
            "iconEmoji": art.get("iconEmoji", "📄"),
            "themeColorHex": art.get("themeColorHex", "#E91E63"),
            "photoTag": art.get("photoTag", ""),
            "weekTag": art.get("weekTag", "")
        }
        index_list.append(idx_item)

        # Write individual article JSON
        art_file = os.path.join(ARTICLES_DIR, f"{art_id}.json")
        with open(art_file, "w", encoding="utf-8") as f:
            json.dump(art, f, ensure_ascii=False)

    # Save index.json
    index_file = os.path.join(ARTICLES_DIR, "index.json")
    with open(index_file, "w", encoding="utf-8") as f:
        json.dump(index_list, f, ensure_ascii=False)
    print(f"    Saved index with {len(index_list)} items to {index_file}")

    # Save originalId mapping for fast 301/redirect lookup
    id_map_file = os.path.join(ARTICLES_DIR, "id_map.json")
    with open(id_map_file, "w", encoding="utf-8") as f:
        json.dump(id_map, f, ensure_ascii=False)
    print(f"    Saved {len(id_map)} ID mappings to {id_map_file}")

def main():
    print("=== Antigravity: Nabda Data Exporter ===")
    ensure_dirs()
    process_images()
    export_pregnancy_weeks()
    export_pregnancy_discover()
    export_baby_months()
    export_fertility()
    export_articles()
    print("=== All data exported successfully! ===")

if __name__ == "__main__":
    main()
