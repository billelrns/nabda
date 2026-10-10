# أمر تنفيذ لـAntigravity — بيانات الجنين · تجربة القراءة · مساحات الإعلان

22 سبتمبر 2026 · مجلّد العمل: **`C:\nabda_app` حصرًا**

---

## ⛔ قبل البدء

- `C:\nabda_app` فقط. نسخة OneDrive أقدم ولا يُنسخ منها شيء.
- **لا تلمس `firestore.rules`** (365 سطرًا، صحيحة).
- استعمل `lib/utils/article_text.dart` الموجود (`splitParagraphs` + `RichArabic`).

---

## المهمة 1 — 🔴 أرقام الجنين مُختلقة في الصفحة الرئيسية

**هذا ليس خطأ عرض، بل معلومة طبية خاطئة في تطبيق صحّي.**

```dart
// lib/main.dart:3583-3584
_metricCell('${(week * 1.3).toStringAsFixed(0)} سم', 'الطول', false, false),
_metricCell('${(week * 28).toStringAsFixed(0)} غ',  'الوزن', false, true),
```

معادلتان خطّيتان لا أساس طبّي لهما. نموّ الجنين أُسّي.

| الأسبوع 10 | المعادلة الحالية | الحقيقة الطبية |
|---|---|---|
| الطول | 13 سم | **3.1 سم** |
| الوزن | 280 غ | **4 غرام** |

فرق **70 ضعفًا** في الوزن. وأم في أسبوعها العاشر ترى «280 غرام» قد تظنّ أن
حملها متقدّم أو أن هناك خطأً في حساب موعدها.

### المصدر الصحيح موجود أصلًا

`lib/models/pregnancy_week_articles.dart` يحمل `babyLength` و`babyWeight` لكل
أسبوع بقيم صحيحة (الأسبوع 10 = `'3.1 سم'` / `'4 غرام'`، والأسبوع 40 = `'3.1 كغ'`).
وهو ما تعرضه `pregnancy_weeks_screen.dart` — ولهذا كانت صحيحة.

### المطلوب

1. أنشئ `lib/utils/fetus_metrics.dart` يقرأ من `pregnancy_week_articles.dart`
   ويعيد `(length, weight, fruitLabel)` لأي أسبوع، مع تعامل آمن مع الأسابيع
   الناقصة (أقرب أسبوع متاح، لا معادلة).
2. استبدل السطرين 3583-3584 في `main.dart` بالقراءة منه.
3. **ابحث في المشروع كلّه عن أي معادلة مشابهة** — `week *`، `* 1.3`، `* 28` —
   وبدّلها. تحقّق خاصةً من `lib/web/web_home.dart` (فيه `_fruitFor`) و
   `share_progress_screen.dart`.
4. وحّد مصدر **الفاكهة** أيضًا: `FetusSize.labeled()` في
   `lib/utils/fetus_size.dart` يجب أن يتطابق مع جدول `pregnancy_week_articles`.
   (سجلّ المشروع يذكر تناقضًا قديمًا في الأسبوع 12: كيوي مقابل ليمون في أربعة ملفات.)

### التحقّق

افتح الرئيسية وصفحة الحمل في نفس اللحظة للأسابيع 8 و10 و20 و30 و40 —
الطول والوزن والفاكهة وتاريخ الولادة المتوقّع **متطابقة في الشاشتين**.

---

## المهمة 2 — إخفاء أزرار الأدوات التي لا تعمل

`toolType` في `smart_2500_articles.json` نصّ حرّ، وثلاثة أنواع منه لا تقابلها
أي شاشة:

| toolType | المقالات | الحالة |
|---|---|---|
| `health_tracker` | 2,718 | تحقّق من وجود شاشة |
| `pregnancy_tracker` | 1,126 | ✅ `PregnancyWeeksScreen` |
| `beauty_routine` | 1,101 | ❌ **لا شاشة** |
| `baby_growth` | 620 | تحقّق |
| `family_harmony` | 478 | ❌ **لا شاشة** |
| `relationship_quiz` | 312 | ❌ **لا شاشة** |
| `pregnancy_wheel` | 254 | ✅ `PregnancyCalendarScreen` |
| `ovulation_calc` | 242 | ✅ `FertilityScreen` |
| `period_tracker` | 115 | تحقّق |
| `baby_tracker` | 9 | تحقّق |

**المطلوب** — في `lib/utils/article_tools.dart` (ملف جديد):

```dart
/// الخريطة الوحيدة المعتمدة: toolType -> باني الشاشة.
/// ما ليس هنا = لا زرّ. لا تُضِف مفتاحًا بلا شاشة حقيقية.
final Map<String, WidgetBuilder> kArticleTools = {
  'pregnancy_tracker': (_) => const PregnancyWeeksScreen(),
  'pregnancy_wheel'  : (_) => const PregnancyCalendarScreen(),
  'ovulation_calc'   : (_) => const FertilityScreen(userData: {}),
  // أضف الباقي بعد التحقّق الفعلي من وجود الشاشة وعملها
};

bool hasTool(String? t) => t != null && kArticleTools.containsKey(t);
```

وفي `smart_article_detail_screen.dart:471` بدّل الشرط إلى `if (hasTool(art.toolType))`.

**لا تحذف الحقل من البيانات** — أخفِ الزرّ فقط. فإن بنيت شاشة «روتين الجمال»
لاحقًا يكفي سطر واحد في الخريطة لتعود 1,101 مقالًا للعمل.

---

## المهمة 3 — تحسين تجربة قراءة المقال

اللقطة الحالية تُظهر نصًّا يمتدّ من حافة إلى حافة بلا تنفّس. المطلوب في
`smart_article_detail_screen.dart` (وتُعمَّم على بقية شاشات المقالات):

### الطباعة والمسافات

```dart
// حاوية المتن
padding: const EdgeInsets.symmetric(horizontal: 22)   // كان أقلّ
// الفقرة
RichArabic(p, style: const TextStyle(
  fontSize: 16,          // كان 14.5 — العربية تحتاج أكبر للقراءة الطويلة
  height: 1.9,           // كان 1.75
  color: Color(0xFF3A3340),
))
// المسافة بين الفقرات
const EdgeInsets.only(bottom: 18)   // كان 14
```

### عناوين الأقسام

اجعلها مميّزة بصريًا لا مجرد نصّ أثقل: شريط وردي رفيع (4×22 بكسل، نصف قطر 2)
على يمين العنوان، ومسافة 28 فوقه و14 تحته.

### تقدّم القراءة

شريط رفيع (3 بكسل) أعلى الشاشة يمتلئ مع التمرير. عنصر بسيط يرفع إحساس
الجودة كثيرًا في المقالات الطويلة، ويُنفَّذ بـ`ScrollController` واحد.

### قوائم النقاط

النقاط الحالية نصّ عادي. اجعل لكل نقطة دائرة وردية 6 بكسل ومسافة 10 بينها
وبين النصّ، ومحاذاة علوية (`CrossAxisAlignment.start`) حتى لا تنزلق الدائرة
مع الأسطر المتعدّدة.

### صندوقا النصيحة والتحذير

`calloutTip` و`calloutWarning` يُعرضان الآن كنصّ. اجعلهما بطاقتين:
حافة يمنى ملوّنة 4 بكسل (أخضر للنصيحة، عنبري للتحذير)، خلفية بنفس اللون
بشفافية 8٪، ونصف قطر 12.

---

## المهمة 4 — مساحات الإعلان

### القواعد أولًا — قبل أي كود

1. **إعلانات Google تُوسَم «إعلان»** بوضوح فوق كل وحدة. سياسة AdMob صريحة،
   ومخالفتها تعني إيقاف الحساب لا مجرد تحذير.
2. **منتجاتك الخاصة ليست إعلانات** — سمِّها **«منتج مقترح»** أو «من متجر نبضة».
   وسمها بـ«إعلان» يضلّل ويخالف قواعد الوسم.
3. **لا إعلان داخل تدفّق النصّ الطبي** بحيث يُلتبس بالمحتوى. افصله ببياض
   واضح وحافة خفيفة.
4. **كثافة معقولة**: إعلان واحد لكل ~3 أقسام، وبحدّ أقصى 3 في المقال الواحد.
   AdMob يعاقب الكثافة المفرطة.
5. ⚠️ **راجع سياسة AdMob للمحتوى الصحّي والحمل والدورة قبل التفعيل.** بعض
   فئات الإعلانات محظورة أو مقيّدة على هذا المحتوى، وبعض المعلنين يرفضونه.

### البنية المطلوبة

`lib/widgets/ad_slot.dart` (ملف جديد) — عنصر واحد يخدم الحالتين:

```dart
enum AdSlotKind { google, ownProduct }

class AdSlot extends StatelessWidget {
  final AdSlotKind kind;
  final String placement;   // 'article_mid' | 'article_end' | 'list_inline'
  const AdSlot({required this.kind, required this.placement, Key? key})
      : super(key: key);
  // ...
}
```

**السلوك المطلوب:**

- يقرأ مفتاح تشغيل من Firestore `app_config/ads`:
  `{ googleEnabled: bool, ownEnabled: bool, maxPerArticle: int }`
  فتتحكّم في الإعلانات من لوحة الأدمن **دون تحديث التطبيق**.
- `googleEnabled == false` (الوضع الحالي، AdMob غير مفعّل) → **لا يحجز مساحة
  ولا يرسم شيئًا**. `SizedBox.shrink()`. لا صندوق رمادي فارغ.
- `ownProduct` → يقرأ من `NabdaAds` الموجود ويعرض بطاقة منتج مع وسم
  **«منتج مقترح»** بخطّ صغير أعلى البطاقة.
- عند تفعيل Google لاحقًا: وسم **«إعلان»** إلزامي، وحجم `banner` أو
  `mediumRectangle` فقط.

### مواضع الإدراج

في `smart_article_detail_screen.dart`، داخل `...art.sections.map(...)`:

- بعد **القسم الثاني**: `AdSlot(kind: ownProduct, placement: 'article_mid')`
- قبل **الأسئلة الشائعة**: `AdSlot(kind: google, placement: 'article_end')`
- بعد **المصادر الطبية**: بطاقة منتج ثانية (إن كان `maxPerArticle >= 2`)

**لا تضع إعلانًا** بين عنوان القسم ومتنه، ولا داخل صندوقَي النصيحة والتحذير،
ولا فوق التنويه الطبي.

### تحضير AdMob بلا تفعيل

أضف `google_mobile_ads` إلى `pubspec.yaml` واكتب طبقة التهيئة، لكن
**أبقِ `googleEnabled: false`** في Firestore. هكذا يكون التفعيل قرارًا في لوحة
الأدمن لا إصدارًا جديدًا — ويمنحك وقتًا لاستيفاء متطلّبات AdMob للمحتوى الصحّي.

> ملاحظة: `news_section.dart:511` فيه `kAdmobReady = false` — وحّده مع المفتاح
> الجديد في Firestore بدل ثابتين منفصلين.

---

## التحقّق بعد التنفيذ

1. **الأسابيع 8 · 10 · 20 · 30 · 40**: الطول والوزن والفاكهة متطابقة بين
   الرئيسية وصفحة الحمل، ومطابقة لجدول `pregnancy_week_articles.dart`
2. افتح مقالًا `beauty_routine` — **لا زرّ أداة**
3. افتح مقالًا `pregnancy_wheel` — الزرّ يعمل ويفتح الشاشة الصحيحة
4. المقال: فقرات متباعدة، عناوين بشريط وردي، نقاط بدوائر، شريط تقدّم يمتلئ
5. `googleEnabled: false` → **لا فراغ ولا صندوق رمادي** في أي مقال
6. بدّلها إلى `true` من Firestore → تظهر المساحة مع وسم «إعلان»
7. `flutter analyze` — أرسل المخرجات
