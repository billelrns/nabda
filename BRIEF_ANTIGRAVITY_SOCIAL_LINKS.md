# أمر تنفيذ لـAntigravity — روابط التواصل الاجتماعي

24 سبتمبر 2026 · مجلّد العمل: **`C:\nabda_app` حصرًا**

---

## المبدأ الحاكم — لا تكتب الروابط في الكود

حسابا **إنستغرام وتيك توك لم يُنشآ بعد**. ولو كُتبت الروابط في Dart لاحتاجت
إضافة كلٍّ منهما:

> تعديل كود ← بناء ← رفع ← **مراجعة غوغل (أيام)** ← تحديث عند كل مستخدمة

وبالقراءة من Firestore: **حقل واحد، ويظهر فورًا عند الجميع بلا تحديث.**

مجموعة `app_config` موجودة أصلًا وقواعدها تسمح بالقراءة العامة
(`firestore.rules:289`).

---

## المهمة 1 — وثيقة الإعدادات في Firestore

أنشئ يدويًا في Firebase Console:

**`app_config/social`**

```json
{
  "youtube":   "https://www.youtube.com/@nabda_official",
  "facebook":  "https://www.facebook.com/profile.php?id=61591185501582",
  "instagram": "",
  "tiktok":    "",
  "whatsapp":  "",
  "telegram":  ""
}
```

**الحقول الفارغة لا تُعرض.** حين يجهز إنستغرام، يُملأ الحقل فيظهر الزرّ عند
كل مستخدمة خلال ثوانٍ.

---

## المهمة 2 — خدمة القراءة

`lib/services/social_links_service.dart` (ملف جديد):

```dart
class SocialLinksService {
  static Map<String, String> _cache = {};
  static bool _loaded = false;

  /// يُستدعى مرّة في main() بعد Firebase.initializeApp
  static Future<void> load() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config').doc('social').get();
      final d = doc.data() ?? {};
      _cache = {
        for (final e in d.entries)
          if (e.value is String && (e.value as String).trim().isNotEmpty)
            e.key: (e.value as String).trim()
      };
    } catch (_) {
      _cache = const {};          // فشل الشبكة → لا أزرار، ولا انهيار
    }
    _loaded = true;
  }

  static bool get hasAny => _cache.isNotEmpty;
  static Map<String, String> get links => Map.unmodifiable(_cache);
}
```

⚠️ **الفشل صامت هنا عن قصد** — غياب روابط التواصل لا يستحقّ رسالة خطأ
للمستخدمة. (هذا يخالف قاعدة «لا تبتلع الأخطاء» التي طبّقناها على المساعد
الذكي، والفرق أن ذاك ميزة أساسية وهذا تزيين.)

استدعِ `SocialLinksService.load()` في `main()` **بلا `await`** حتى لا يتأخّر
إقلاع التطبيق:

```dart
SocialLinksService.load();   // بلا await
```

---

## المهمة 3 — قسم «تابعينا» في الملف الشخصي

في `lib/screens/profile/profile_screen.dart` (أو شاشة الإعدادات في
`main.dart`)، **فوق قسم «التحكّم في بياناتي»**:

```dart
if (SocialLinksService.hasAny) ...[
  const Text('تابعي نبضة', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
  const SizedBox(height: 4),
  const Text('نصائح يومية ومحتوى جديد كل أسبوع',
      style: TextStyle(fontSize: 12.5, color: Color(0xFF8F8795))),
  const SizedBox(height: 12),
  Wrap(spacing: 12, children: [ /* الأزرار */ ]),
]
```

**الأزرار**: دائرة 44 بكسل، خلفية `#FDE8EF`، أيقونة بلون `#E0356F`، وعند
الضغط تفتح بـ`url_launcher` (موجود في `pubspec.yaml:10`):

```dart
await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
```

`externalApplication` مهمّ: يفتح تطبيق يوتيوب أو فيسبوك إن كان مثبّتًا، لا
متصفّحًا داخليًا.

**الأيقونات**: استعمل `Icons.play_circle_fill` ليوتيوب و`Icons.facebook`
لفيسبوك مؤقّتًا، أو أضف `font_awesome_flutter` إن أردت أيقونات دقيقة —
لكن لا تُضف حزمة من أجل أيقونتين.

**الترتيب**: يوتيوب · فيسبوك · إنستغرام · تيك توك · واتساب · تيليغرام —
ثابت بصرف النظر عن ترتيب الحقول في Firestore.

---

## المهمة 4 — بقيّة صفحات الموقع

تذييل `web/landing.html` **أُنجز بالفعل** (أيقونات SVG حقيقية + كتلتان
معلّقتان لإنستغرام وتيك توك).

انسخ نفس الكتلة إلى تذييلات:

- `web/articles.html`
- `web/privacy.html` · `web/terms.html`
- `web/tools/due-date.html` · `ovulation.html` · `fetus-size.html` · `baby-names.html`

> صفحات الأدوات تحديدًا: تجلب زائرات من غوغل لا يعرفن نبضة، وزرّ متابعة
> في تذييلها يحوّل زائرة عابرة إلى متابعة.

**لا تلمس** `web/tools/names/*.html` (1,765 ملفًا) يدويًا — عدّل القالب في
`tools/export_web_data.py` وأعد توليدها.

---

## المهمة 5 — Open Graph للمشاركة

أضف في `<head>` كل صفحة عامة:

```html
<meta property="og:site_name" content="نبضة">
<meta property="og:type" content="website">
<meta property="og:image" content="https://nabda.online/og-image.png">
<meta name="twitter:card" content="summary_large_image">
```

لـ`og-image.png` استعمل `marketing/store/out_v3/feature_graphic_1024x500.png`
وانسخها إلى `web/og-image.png`.

**الأثر**: حين تشارك مختبِرة رابط أداة في واتساب أو فيسبوك، تظهر بطاقة
بصورة الغلاف بدل رابط عارٍ. فرق كبير في نسبة النقر، وتكلفته صفر.

---

## التحقّق

1. افتح الملف الشخصي → **زرّان فقط** (يوتيوب وفيسبوك) — لا أزرار فارغة
2. اضغط يوتيوب → يفتح **تطبيق يوتيوب** إن كان مثبّتًا
3. في Firestore، املأ `instagram` برابط أي حساب → **أعد فتح الشاشة** →
   ظهر زرّ ثالث **بلا إعادة بناء**. هذا هو اختبار المعمارية كلّها.
4. أفرغ الحقل → اختفى الزرّ
5. اقطع الإنترنت وافتح الشاشة → **لا انهيار، لا أزرار، ولا رسالة خطأ**
6. `flutter analyze`

---

## ملاحظة لبلال — رابط فيسبوك

```
facebook.com/profile.php?id=61591185501582
```

هذا رابط خام طويل لا يُحفظ ولا يُنطق. اذهب إلى صفحتك على فيسبوك →
**Settings → Page setup → Username** واحجز اسمًا مثل `nabda.official`،
فيصير الرابط:

```
facebook.com/nabda.official
```

وحينها **غيّر الحقل في Firestore فقط** — لا كود ولا تحديث. وهذا بالضبط
سبب بناء المنظومة بهذا الشكل.

واحجز الاسم نفسه على إنستغرام وتيك توك قبل أن يأخذه غيرك — الحجز مجاني
والاتساق عبر المنصّات يستحقّ الدقائق الخمس.
