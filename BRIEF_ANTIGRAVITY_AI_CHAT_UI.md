# أمر تنفيذ لـAntigravity — إعادة تصميم شاشة المساعد الذكي

24 سبتمبر 2026 · مجلّد العمل: **`C:\nabda_app` حصرًا**

> الشاشة: `AIChatPage` / `_AIChatPageState` في `lib/main.dart` (نحو السطر 9374).
> **لا تلمس منطق `_callGemini` ولا `_checkAndConsumeQuota` ولا نافذة الموافقة
> ولا بانر التحذير ولا زرّ الإبلاغ** — كلّها تعمل وتمّ التحقّق منها.
> المطلوب **الشكل فقط**.

---

## المشكلة الحالية

من لقطة المستخدم:

1. **صورة المساعد وصورة المستخدمة كلتاهما على اليمين** — لا يُفرَّق بينهما بصريًا
2. أيقونة روبوت 🤖 رمادية بدل هوية نبضة
3. خلفية بيضاء جرداء
4. ألوان تركوازية باردة لا تناسب تطبيق أمومة

---

## المهمة 1 — تصحيح اتجاه المحادثة

هذا أهمّ من الألوان: **الفقاعتان تبدوان الآن كأنهما من متحدّث واحد.**

| | المحاذاة | الصورة |
|---|---|---|
| **المساعد** | يسار الشاشة | **يسار الفقاعة** |
| **المستخدمة** | يمين الشاشة | **يمين الفقاعة** |

```dart
Row(
  textDirection: isUser ? TextDirection.rtl : TextDirection.ltr,
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
  children: [ avatar, const SizedBox(width: 8), bubble ],
)
```

الشاشة كلّها داخل `Directionality(rtl)`، لذا **اضبط `textDirection` على الصفّ
نفسه** — وإلا انقلبت الصورة إلى الجهة الخطأ. هذا هو الفخّ هنا.

النصّ داخل الفقاعة يبقى `TextDirection.rtl` دائمًا.

---

## المهمة 2 — الصور الرمزية

**المساعد** — شعار نبضة بدل أيقونة الروبوت:

```dart
Container(
  width: 38, height: 38,
  decoration: const BoxDecoration(
    shape: BoxShape.circle,
    gradient: LinearGradient(
      colors: [Color(0xFFFFF0F5), Color(0xFFFFE0EC)],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    ),
  ),
  padding: const EdgeInsets.all(5),
  child: Image.asset('assets/images/logo_nabda.png', fit: BoxFit.contain),
)
```

> تحقّق من وجود `assets/images/logo_nabda.png` (مستعمل في
> `smart_article_detail_screen.dart:68`). إن لم يوجد بحجم مناسب، استعمل
> `web/landing-assets/heart-big.png` وسجّله في `pubspec.yaml`.

**المستخدمة** — صورتها الحقيقية مع تدرّج آمن:

```dart
final photo = FirebaseAuth.instance.currentUser?.photoURL;
CircleAvatar(
  radius: 19,
  backgroundColor: const Color(0xFFF8BBD0),
  backgroundImage: (photo != null && photo.isNotEmpty) ? NetworkImage(photo) : null,
  child: (photo == null || photo.isEmpty)
      ? Text(initial, style: const TextStyle(color: Color(0xFFAD1457),
              fontWeight: FontWeight.w800, fontSize: 15))
      : null,
)
```

`initial` = أول حرف من `displayName`، وإن غاب فأيقونة `Icons.person`.
**لا تترك الصورة فارغة بيضاء.**

---

## المهمة 3 — الخلفية

الأصل جاهز: **`assets/images/chat_bg_pattern.png`** (600×600 · 157 كيلوبايت)
— رسوم خطّية وردية: حوامل، رضّع، دِببة، خشخيشات، رضّاعات، أحذية، قلوب، أهلّة.

سجّله في `pubspec.yaml` ثم:

```dart
Container(
  decoration: const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFFFFF8FB), Color(0xFFFDF3F7)],
    ),
  ),
  child: Opacity(
    opacity: 0.16,                       // ← لا تتجاوزها
    child: Image.asset(
      'assets/images/chat_bg_pattern.png',
      repeat: ImageRepeat.repeat,
      scale: 2.2,                        // موتيفات صغيرة ومتباعدة
    ),
  ),
)
```

ثم قائمة الرسائل فوقه داخل `Stack`.

⚠️ **0.16 حدّ أقصى لا اقتراح.** خلفية أوضح من ذلك تُتعب العين وتُصعّب قراءة
العربية بتشكيلها — وهذه شاشة تُقرأ فيها إجابات صحّية طويلة. جمالٌ يُضعف
القراءة ليس جمالًا.

---

## المهمة 4 — الفقاعات والألوان

### اللوحة

| الاستعمال | اللون |
|---|---|
| خلفية الشاشة | `#FFF8FB` → `#FDF3F7` |
| فقاعة المستخدمة | تدرّج `#F48FB1` → `#EC407A` · نصّ أبيض |
| فقاعة المساعد | `#FFFFFF` بشفافية 0.94 · نصّ `#3A2F38` |
| حافّة فقاعة المساعد | `#F8BBD0` بعرض 1 |
| شريط التطبيق | تدرّج `#EC407A` → `#F06292` |
| زرّ الإرسال | `#EC407A` |

**احذف التركوازي `#00897B` من هذه الشاشة كليًا** — بما فيه شريط التطبيق.

### الشكل

```dart
borderRadius: BorderRadius.only(
  topLeft:  const Radius.circular(18),
  topRight: const Radius.circular(18),
  bottomLeft:  Radius.circular(isUser ? 18 : 4),   // الذيل عند الصورة
  bottomRight: Radius.circular(isUser ? 4 : 18),
)
```

- ظلّ ناعم: `BoxShadow(color: Color(0x14AD1457), blurRadius: 8, offset: Offset(0,2))`
- عرض أقصى للفقاعة: **78٪** من عرض الشاشة
- حشو: `EdgeInsets.symmetric(horizontal: 14, vertical: 11)`
- نصّ: مقاس 15 · `height: 1.8` (العربية تحتاج تباعدًا أكبر)
- **وقت الرسالة** بمقاس 10 ولون `#B49AA8` أسفل كل فقاعة

### الأزرار السريعة (`quickQuestions`)

`Wrap` من رقائق: خلفية `#FFFFFF`، حافّة `#F8BBD0`، نصّ `#AD1457`، نصف قطر 20.
تظهر **فقط عند بداية المحادثة** وتختفي بعد أول سؤال.

### مؤشّر الكتابة

استبدل `_isLoading` الحالي بثلاث نقاط وردية تنبض داخل فقاعة مساعد فارغة —
تُشعر المستخدمة أن أحدًا يفكّر لا أن التطبيق تجمّد.

---

## المهمة 5 — تفاصيل تصنع الفارق

1. **شريط التطبيق**: أضف شعار نبضة صغيرًا (26 بكسل) يمين العنوان
2. **رسالة الترحيب**: اجعلها فقاعة مساعد عادية بالصورة، لا نصًّا معلّقًا
3. **حقل الإدخال**: خلفية بيضاء، حافّة `#F8BBD0`، نصف قطر 24، وظلّ خفيف
4. **زرّ المسح 🗑** في الشريط: أضف تأكيدًا قبل الحذف
5. **بانر التحذير**: أبقِه كما هو لكن لوّنه `#FFF3E0` بحافّة يمنى عنبرية 3 بكسل
6. **`SafeArea`** حول حقل الإدخال — هواتف كثيرة فيها شريط إيماءات سفلي

---

## ما لا يُمسّ

- `_callGemini()` ومفتاح API
- `_checkAndConsumeQuota()` والحدّ اليومي
- `_checkAiConsent()` و`ai_consent_v1`
- نصّ بانر التحذير الطبي (اللون فقط)
- `ReportService.showReportDialog` وزرّ «إبلاغ عن هذه الإجابة»

---

## التحقّق

1. **فقاعة المساعد يسارًا وصورته يسارها · فقاعة المستخدمة يمينًا وصورتها يمينها**
2. شعار نبضة ظاهر مكان الروبوت
3. صورة المستخدمة الحقيقية تظهر — وإن لم توجد فحرفها الأول لا دائرة فارغة
4. النمط ظاهر بوضوح **دون أن يُتعب قراءة إجابة طويلة**
5. لا أثر للتركوازي في الشاشة
6. المساعد ما زال يجيب (اكتب «كوكو») · نافذة الموافقة تعمل · زرّ الإبلاغ يعمل
7. جرّب على شاشة صغيرة (5 بوصات) وتأكّد ألّا تتجاوز الفقاعة 78٪
8. `flutter analyze` — أرسل المخرجات
