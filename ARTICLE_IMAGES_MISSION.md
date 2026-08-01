# 🎯 مهمة: صورة HOOK فريدة لكل مقال في تطبيق نبضة

> وثيقة تنفيذ ذاتية — أعطها لـ Claude (Sonnet أو أعلى) مع اتصال Higgsfield MCP + مجلد المشروع `C:\nabda_app`، واطلب: **«نفّذ ARTICLE_IMAGES_MISSION.md»**

---

## السياق (اقرأه أولاً)

- تطبيق نبضة (Flutter، عربي RTL) لصحة المرأة والأمومة. الجمهور: نساء عربيات مسلمات.
- يوجد نظام صور فئات في `lib/utils/article_images.dart` (39 صورة في `assets/images/articles/`) — **لا تحذفه**، سيبقى احتياطاً. المهمة: طبقة أدق فوقه = صورة فريدة لكل مقال.
- التوليد عبر Higgsfield MCP بموديل `nano_banana_pro` (يتحول تلقائياً إلى nano_banana_2، ~1.5 كريدت/صورة). تحقق من الرصيد بأداة `balance` قبل البدء وبعد كل 50 صورة.
- التنزيل المباشر محجوب في بيئة Claude — التسليم يكون بملف `.bat` يشغّله المستخدم (انظر الخطوة 6).

## الخطوة 1 — استخراج كل عناوين المقالات

ابحث واستخرج العناوين من هذه الملفات (احفظ القائمة في `article_titles.json` مع القسم):

| الملف | نمط الاستخراج | القسم |
|---|---|---|
| `lib/main.dart` | خرائط المقالات `'title': '...'` (~200 مقال) | حسب السياق: home/pregnancy/cycle/baby |
| `lib/data/baby_care_age_articles.dart` | حقول العناوين | baby |
| `lib/screens/pregnancy/discover_articles_screen.dart` | كائنات المقالات | pregnancy |
| `lib/data/specialized_articles.dart` | العناوين | حسب التصنيف |
| `lib/data/religious_articles.dart` | العناوين | spiritual |

استخدم bash/grep + python لاستخراج JSON: `[{"id": "a001", "title": "...", "section": "baby"}, ...]`
- `id` = تسلسلي ثابت مرتب حسب (الملف، ثم ترتيب الظهور) — **لا يتغير بين التشغيلات**.
- استبعد المقالات المكررة بالعنوان الحرفي.

## الخطوة 2 — تأكيد الميزانية مع المستخدم

- العدد المتوقع: 250–300 عنوان. التكلفة ≈ العدد × 1.5 كريدت.
- اعرض على المستخدم: العدد الفعلي + التكلفة + الرصيد الحالي، واطلب موافقة صريحة قبل التوليد. إن كان الرصيد أقل من التكلفة + 100 (هامش أمان)، اقترح توليد الأقسام الأهم أولاً (home ثم pregnancy ثم baby ثم cycle).

## الخطوة 3 — قالب برومبت HOOK الموحد

لكل مقال، ابنِ برومبت بهذا الهيكل الإلزامي:

```
Scroll-stopping editorial photo for an Arabic maternity app article titled "{ترجمة إنجليزية موجزة للعنوان}":
{SCENE — مشهد محدد مشتق من العنوان، انظر قواعد المشاهد أدناه},
dramatic close-up composition with strong subject focus, genuine captivating emotion,
vibrant colors with soft pink brand accents (#F0347C), beautiful bokeh background,
premium magazine-cover quality, eye-catching hook framing,
{MODESTY — إن ظهرت امرأة: "modest Arab Muslim woman in elegant hijab, fully modest clothing"},
warm golden-pink light, 4:3 landscape, no text, no logos
```

### قواعد بناء المشهد (SCENE) من العنوان:
1. **ترجم العنوان لفكرة بصرية واحدة قوية** — ليس وصفاً عاماً. مثال: «الحمى عند الرضع: متى تقلقين» ← close-up of a mother's hand holding a digital thermometer near her calm baby's forehead, worried-but-tender eyes in soft focus.
2. **Close-up أو تفصيلة درامية** أفضل من لقطة واسعة: يد، نظرة، ابتسامة، شيء رمزي كبير في الكادر.
3. **عنصر مفاجئ/فضولي** حيث أمكن (Hook): وجه طفل مندهش، حركة ملتقطة لحظياً، تباين لوني.
4. **الحشمة إلزامية دائماً**: أي امرأة = حجاب أنيق ولباس فضفاض محتشم. الرضاعة = تغطية كاملة (nursing cover). لا أكتاف/أذرع مكشوفة.
5. مواضيع حساسة (اكتئاب، فقدان، ألم): مشهد متعاطف هادئ فيه أمل — لا دراما قاتمة.
6. مواضيع مجردة (هرمونات، دورة، تحاليل): flat-lay رمزي أنيق أو مشهد طبي دافئ — بلا نساء إن كان أنسب.
7. **التنويع**: لا تكرر نفس تكوين المشهد لعنوانين متتاليين (بدّل: close-up يد / وجه / flat-lay / لقطة علوية / silhouette خلف ستارة...).

## الخطوة 4 — التوليد والتتبع

- ولّد بدفعات 3–4 متوازية، `aspect_ratio: "4:3"`, `count: 1`.
- إن ظهر `preset_recommendation` ارفضه بـ `declined_preset_id` وأعد literal.
- بعد كل ~30 توليداً: اجمع النتائج بـ `show_generations` (size 40) وسجّل في `article_images_progress.json`: `{"id": "a001", "job": "...", "url": "..."}`. هذا يسمح بالاستئناف إذا انقطعت الجلسة.
- الفشل النادر: أعد المحاولة مرة واحدة، وإلا سجّله في قائمة `failed` وواصل.

## الخطوة 5 — دمج الكود

1. أنشئ `lib/utils/article_image_map.g.dart`:
```dart
// GENERATED — خريطة عنوان المقال → صورته الفريدة
const Map<String, String> kArticleImageMap = {
  'العنوان الحرفي الكامل': 'assets/images/article_pics/a001.png',
  // ...
};
```
2. عدّل `ArticleImages.resolve` في `lib/utils/article_images.dart` — أضف في أول السطر:
```dart
final exact = kArticleImageMap[title.trim()];
if (exact != null) return exact;
```
(مع import للملف المولد). نظام الفئات القديم يبقى fallback لأي مقال جديد مستقبلاً.
3. أضف `- assets/images/article_pics/` إلى pubspec.yaml.

## الخطوة 6 — التسليم

1. اكتب `download_article_pics.bat` في جذر المشروع: mkdir `assets\images\article_pics` + سطر curl لكل صورة `a{id}.png` بالرابط النهائي (نمط السكريبتات السابقة في المشروع).
2. قدّم الملف للمستخدم بأداة present_files واطلب تشغيله ثم `flutter run` (إعادة تشغيل كاملة).
3. قدّم تقريراً: عدد الصور، الكريدتات المستهلكة، الرصيد المتبقي، قائمة failed إن وجدت.

## معايير النجاح
- [ ] كل عنوان في `article_titles.json` له صورة فريدة أو مسجل في failed
- [ ] لا صورة مكررة بين مقالين مختلفين
- [ ] كل النساء محجبات محتشمات في كل الصور
- [ ] `flutter analyze` يمر بدون أخطاء بعد تعديل الكود
- [ ] الرصيد النهائي > 100 كريدت
