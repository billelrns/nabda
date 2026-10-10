# أمر تنفيذ لـAntigravity — البنود الثلاثة الأخيرة قبل النشر

24 سبتمبر 2026 · مجلّد العمل: **`C:\nabda_app` حصرًا**

> حساب Google Play Console أُنشئ («نبضة | Nabda»). هذه البنود الثلاثة هي ما
> يفصل بين نسخة اختبار ونسخة تُرفع بثقة.
> **لا تلمس `firestore.rules`. لا نسخ من OneDrive.**

---

## 🔴 المهمة 1 — أرقام الجنين المُختلَقة

### المشكلة

```dart
// lib/main.dart:3704-3705
_metricCell('${(week * 1.3).toStringAsFixed(0)} سم', 'الطول', false, false),
_metricCell('${(week * 28).toStringAsFixed(0)} غ',  'الوزن', false, true),
```

معادلتان خطّيتان لا أساس طبّي لهما. نموّ الجنين أُسّي لا خطّي.

| الأسبوع 10 | ما تعرضه الرئيسية | الحقيقة الطبية | الفرق |
|---|---|---|---|
| الطول | 13 سم | **3.1 سم** | 4× |
| الوزن | 280 غ | **4 غرام** | **70×** |

**هذه ليست مشكلة عرض.** أمّ في أسبوعها العاشر ترى «280 غرام» قد تظنّ أن
حسابها خاطئ أو أن بجنينها شيئًا. وصفحة الحمل تعرض الرقم الصحيح في اللحظة
نفسها — فالتطبيق يناقض نفسه أمام المستخدمة.

### المصدر الصحيح موجود أصلًا

`lib/models/pregnancy_week_articles.dart` يحمل `babyLength` و`babyWeight`
لكل أسبوع بقيم صحيحة (الأسبوع 10 = `'3.1 سم'` / `'4 غرام'`، الأسبوع 40 =
`'3.1 كغ'`). وهو ما تقرأ منه `pregnancy_weeks_screen.dart` — ولهذا كانت سليمة.

### المطلوب

**١. أنشئ `lib/utils/fetus_metrics.dart`** — مصدر وحيد لكل الشاشات:

```dart
import '../models/pregnancy_week_articles.dart';

class FetusMetrics {
  final String length;   // '3.1 سم'
  final String weight;   // '4 غرام'
  final String fruit;    // 'فراولة'
  final String emoji;    // '🍓'
  const FetusMetrics(this.length, this.weight, this.fruit, this.emoji);

  /// يقرأ من pregnancyWeekArticles. عند غياب الأسبوع يعود بأقرب أسبوع
  /// متاح — ولا يحسب أبدًا بمعادلة.
  static FetusMetrics forWeek(int week) { … }
}
```

**قاعدة صارمة**: عند غياب بيانات أسبوع، ابحث عن **أقرب أسبوع موجود**.
**ممنوع** الاستيفاء الرياضي أو أي معادلة — رقم تقريبي خاطئ أسوأ من رقم
الأسبوع المجاور الصحيح.

**٢. استبدل السطرين 3704-3705** بالقراءة من `FetusMetrics.forWeek(week)`.

**٣. امسح المشروع كلّه بحثًا عن معادلات مشابهة**:

```
week *    ·    * 1.3    ·    * 28    ·    * 7 (في سياق الطول/الوزن)
```

تحقّق خاصةً من: `lib/web/web_home.dart` (فيه `_fruitFor`) ·
`lib/web/web_pregnancy.dart` · `share_progress_screen.dart` ·
`fetus_size_screen.dart`.

**٤. وحّد الفاكهة**: `FetusSize.labeled()` في `lib/utils/fetus_size.dart`
يجب أن يقرأ من نفس المصدر. سجلّ المشروع يوثّق تناقضًا قديمًا في الأسبوع 12
(كيوي مقابل ليمون في أربعة ملفات) — أغلقه الآن.

**٥. وأهمّ من ذلك**: `web/tools/data/fetus_weeks.json` الذي يغذّي
`due-date.html` و`fetus-size.html` على الموقع **مُصدَّر من نفس الملف**.
شغّل `tools/export_web_data.py` بعد التوحيد وتأكّد أن الموقع والتطبيق
يعرضان الرقم نفسه.

### التحقّق

افتح الرئيسية وصفحة الحمل **في اللحظة نفسها** للأسابيع **8 · 10 · 20 · 30 · 40**.
الطول والوزن والفاكهة **متطابقة في الشاشتين**، ومطابقة لـ
`pregnancy_week_articles.dart`، ومطابقة لـ`nabda.online/tools/fetus-size.html`.

---

## 🟠 المهمة 2 — أزرار أدوات لا تؤدّي إلى شيء

`toolType` في `smart_2500_articles.json` نصّ حرّ، وثلاثة أنواع منه لا تقابلها
أي شاشة في التطبيق:

| toolType | المقالات | الشاشة |
|---|---|---|
| `health_tracker` | 2,718 | تحقّق |
| `pregnancy_tracker` | 1,126 | ✅ `PregnancyWeeksScreen` |
| **`beauty_routine`** | **1,101** | ❌ **لا شاشة** |
| `baby_growth` | 620 | تحقّق |
| **`family_harmony`** | **478** | ❌ **لا شاشة** |
| **`relationship_quiz`** | **312** | ❌ **لا شاشة** |
| `pregnancy_wheel` | 254 | ✅ `PregnancyCalendarScreen` |
| `ovulation_calc` | 242 | ✅ `FertilityScreen` |
| `period_tracker` | 115 | تحقّق |
| `baby_tracker` | 9 | تحقّق |

**1,891 مقالًا فيها زرّ «افتحي الأداة» يؤدّي إلى لا شيء.**

### المطلوب

**أنشئ `lib/utils/article_tools.dart`** — خريطة بيضاء صريحة:

```dart
/// الخريطة المعتمدة الوحيدة: toolType -> باني الشاشة.
/// ما ليس هنا = لا زرّ.
/// ⛔ لا تُضِف مفتاحًا قبل فتح الشاشة بنفسك والتأكّد أنها تعمل.
final Map<String, WidgetBuilder> kArticleTools = {
  'pregnancy_tracker': (_) => const PregnancyWeeksScreen(),
  'pregnancy_wheel'  : (_) => const PregnancyCalendarScreen(),
  'ovulation_calc'   : (_) => const FertilityScreen(userData: {}),
  // الأربعة المتبقّية (health_tracker · baby_growth · period_tracker ·
  // baby_tracker): افتح الشاشة يدويًا أولًا، ثم أضف.
};

bool hasArticleTool(String? t) => t != null && kArticleTools.containsKey(t);
```

وفي `smart_article_detail_screen.dart:471` بدّل الشرط:

```dart
if (hasArticleTool(art.toolType) && art.toolTitle != null) ...[
```

**لا تحذف الحقل من البيانات.** أخفِ الزرّ فقط — فإن بنيت شاشة «روتين الجمال»
لاحقًا يكفي سطر واحد لتعود 1,101 مقالًا للعمل.

### التحقّق

1. افتح مقالًا `beauty_routine` → **لا زرّ أداة، ولا مساحة فارغة مكانه**
2. افتح مقالًا `pregnancy_wheel` → الزرّ يعمل ويفتح الشاشة الصحيحة
3. جرّب الأربعة «تحقّق» واحدًا واحدًا وأضف ما يعمل فقط

---

## 🟠 المهمة 3 — مفتاح Gemini مكشوف

```dart
// lib/main.dart:9379
final String _apiKey = 'AIzaSyB09gZH…';
```

المفتاح في كود مرفوع إلى **مستودع عام** على GitHub، ويُستخرج من الـAPK بأداة
مجانية في دقيقة. ومفتاح Firebase المكشوف سابقًا أنقذته Google تلقائيًا —
**مفاتيح Gemini لا تملك هذه الحماية**.

### أ. اليوم — تقليل الضرر (10 دقائق، بلا كود)

Google Cloud Console → **APIs & Services → Credentials**:

1. **ولّد مفتاحًا جديدًا** واستبدل القديم في الكود. القديم عام منذ أشهر —
   افترض أنه مقروء.
2. **API restrictions** → اقصره على **Generative Language API** وحدها.
   هذا يعمل دائمًا ويحدّ من نطاق الضرر.
3. **احذف المفتاح القديم** بعد التأكّد من عمل الجديد.
4. **Quotas** → ضع حدًّا يوميًا للطلبات. هذا سقف الفاتورة إن سُرق الجديد.

> ⚠️ **لا تضع Application restriction (Android apps)** الآن. أنت تستدعي
> Gemini عبر `http` مباشرةً من Dart (`_callGemini`)، ولا تُرسل تلك الطلبات
> توقيع التطبيق الذي يفحصه هذا القيد — فقد يتعطّل المساعد الذكي كليًا.
> إن أردت تجربته فاختبره على جهاز حقيقي بنسخة release **قبل** الاعتماد عليه.

### ب. الحلّ الصحيح — وسيط على الخادم

مشروعك على خطة **Blaze**، فـCloud Functions متاحة:

```
functions/
  index.js     →  askGemini (onCall)
```

- المفتاح يعيش في `firebase functions:config:set gemini.key="…"`
  أو Secret Manager — **لا يغادر الخادم أبدًا**
- الدالة تتحقّق من `context.auth` — لا استدعاء بلا تسجيل دخول
- تفرض الحدّ اليومي على الخادم (`/ai_quota` الحالي يُفرض من العميل، ومفتاح
  مسروق يتجاوز التطبيق كلّه)
- التطبيق يستدعي الدالة بدل Gemini مباشرةً

### التحقّق

1. المساعد الذكي يعمل بعد التبديل
2. `grep -rn "AIzaSy" lib/` → **صفر نتيجة** بعد الوسيط
3. حدّ الحصّة ظاهر في Google Cloud Console

---

## ترتيب التنفيذ

| # | المهمة | لماذا هذا الترتيب |
|---|---|---|
| 1 | أرقام الجنين | معلومة طبية خاطئة — الأخطر |
| 2 | أزرار الأدوات | يمسّ 1,891 مقالًا |
| 3-أ | تقييد مفتاح Gemini | 10 دقائق، بلا كود، يوقف النزيف |
| 3-ب | وسيط Cloud Function | يحتاج وقتًا — بعد الاختبار المغلق |

**بعد الانتهاء:**

```powershell
cd C:\nabda_app
python tools/export_web_data.py     # بعد توحيد بيانات الجنين
flutter clean && flutter pub get
flutter analyze                      # أرسل المخرجات
flutter build appbundle --release --no-tree-shake-icons
```

وارفع الحزمة على **مسار الاختبار المغلق** في Play Console — الاثنتا عشرة
مختبِرة والأربعة عشر يومًا تبدأ من لحظة الرفع لا من لحظة الجاهزية.
