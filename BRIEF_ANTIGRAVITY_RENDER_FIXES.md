# أمر تنفيذ لـAntigravity — أعطال العرض وحذف الحساب

21 سبتمبر 2026 · اكتُشفت باختبار يدوي على جهاز حقيقي

---

## ⛔ اقرأ هذا أولاً — المجلّد الصحيح

**مجلّد العمل الوحيد هو `C:\nabda_app`.**

المحاولة السابقة نُفّذت في `C:\Users\AMT mobile\OneDrive\nabda_app`، وهي **نسخة
أقدم** تسبق المرحلة 24. الدليل:

```
FavoritesService      C:\nabda_app = 3 مواضع   |   OneDrive = 0
_toggleBookmark       C:\nabda_app = 2 مواضع   |   OneDrive = 0
firestore.rules       C:\nabda_app = 365 سطرًا |   OneDrive = 289 سطرًا
```

نسخ ملفات OneDrive فوق المحلّية يمحو ميزة المفضّلة والحفظ بالكامل.

**لذلك:**
1. **لا تنسخ أي ملف من OneDrive** — أعد التعديلات في `C:\nabda_app` من الصفر.
2. `lib/utils/article_text.dart` **مُرحَّل بالفعل** إلى `C:\nabda_app` — استعمله كما هو ولا تُنشئه من جديد.
3. **لا تلمس `firestore.rules` إطلاقًا.** النسخة المحلّية (365 سطرًا) صحيحة وتحوي
   `allow delete` المطلوب منذ 18 سبتمبر. نسخة OneDrive ينقصها 8 مجموعات
   (`favorites`, `followers`, `following`, `blocked`, `article_stats`,
   `baby_name_likes`, `support_requests`, `user_baby_names`) — ونشرها يعطّل
   المفضّلة والمتابعة والحظر فورًا.
4. المهام 2 و3 و4 أدناه تُعاد كلّها في `C:\nabda_app`.

المسارات الفعلية للشاشتين اللتين لم يُعثر عليهما:
ابحث عن ملفّي فقه المرأة والمحتوى المتخصّص بـ`grep -r "womens_fiqh\|conditional"` داخل `lib/`
قبل تعديلهما، ولا تفترض مسارًا.

> **البيانات نُظّفت مسبقًا** عبر `tools/clean_article_content.py`:
> بقايا JSON‑LD 1,475→0 · كيانات HTML 546→0.
> ما تبقّى أعطال **عرض** في Dart، لا في المحتوى.

---

## المهمة 1 — 🔴 زرّ حذف الحساب لا يستجيب

### العطل الأول: رسائل التحقّق غير مرئية

`lib/screens/profile/data_control_screen.dart:230,236,253`

```dart
ScaffoldMessenger.of(ctx).showSnackBar(...)   // ctx = سياق الحوار
```

الـSnackBar يُعرض أسفل الشاشة **تحت حاجز الحوار المعتم**، فلا تراه المستخدمة.
النتيجة: تضغط الزرّ فلا يحدث شيء ظاهر — وهذا بالضبط ما بلّغ عنه الاختبار.

**الإصلاح**: لفّ محتوى الحوار بـ`StatefulBuilder` واعرض الخطأ **داخل الحوار**:

```dart
String? _error;
bool _busy = false;

// داخل الـColumn، فوق الأزرار:
if (_error != null)
  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(10),
    margin: const EdgeInsets.only(top: 12),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.red.shade200),
    ),
    child: Text(_error!,
        textAlign: TextAlign.right,
        style: TextStyle(color: Colors.red.shade900, fontSize: 13)),
  ),
```

وبدّل كل `showSnackBar` داخل الحوار بـ`setSheetState(() => _error = '…')`.
وأثناء التنفيذ اعرض `CircularProgressIndicator` في الزرّ (`_busy`) ليعرف المستخدم
أن شيئًا يجري.

### العطل الثاني: 🔴 مستخدمات الدخول الاجتماعي لا يستطعن الحذف إطلاقًا

`data_control_screen.dart:235` يشترط كلمة مرور. لكن `auth_service.dart:140-146`
يوفّر `signInWithGoogle` و`signInWithFacebook` و`signInWithApple` — وهؤلاء
**لا كلمة مرور لهنّ**. الشرط يوقفهنّ نهائيًا.

**هذه مخالفة صريحة لسياسة حذف الحساب في Google Play** — البند الذي ظنّناه مغلقًا
ما زال مفتوحًا لشريحة كاملة من المستخدمات.

**الإصلاح** — اكشف طريقة الدخول وتصرّف على أساسها:

```dart
final user = FirebaseAuth.instance.currentUser!;
final providers = user.providerData.map((p) => p.providerId).toList();
final isPasswordUser = providers.contains('password');
```

- **إن كانت `isPasswordUser`**: أظهر حقل كلمة المرور كما هو الآن.
- **وإلّا**: أخفِ الحقل تمامًا، وأعد التوثيق بالمزوّد نفسه قبل الحذف:

```dart
// في auth_service.dart — أضف قبل خطوة الحذف
if (!isPasswordUser) {
  final pid = providers.firstWhere((p) => p != 'password', orElse: () => '');
  if (pid == 'google.com') {
    await user.reauthenticateWithProvider(GoogleAuthProvider());
  } else if (pid == 'facebook.com') {
    await user.reauthenticateWithProvider(FacebookAuthProvider());
  } else if (pid == 'apple.com') {
    await user.reauthenticateWithProvider(AppleAuthProvider());
  }
}
```

وعالج `FirebaseAuthException` بـ`requires-recent-login` برسالة عربية واضحة:
«انتهت صلاحية جلستك — سجّلي الخروج ثم الدخول وأعيدي المحاولة».

### الاختبار المطلوب

ثلاث حالات، وكلها تنتهي بفتح Firestore والتأكّد **بالعين** أن `/users/{uid}`
ومجموعاتها الفرعية و`/users_directory/{uid}` اختفت:

1. حساب بالبريد وكلمة مرور
2. حساب بـGoogle
3. حساب جلسته قديمة (لاختبار `requires-recent-login`)

---

## المهمة 2 — النصّ يظهر كتلة واحدة بلا فقرات

`lib/screens/articles/smart_article_detail_screen.dart:559`

```dart
Text(sec.content, style: ...)   // المتن كلّه في ودجت واحدة
```

فواصل الفقرات في البيانات `\n` لكنها تُعرض كسطر جديد فقط، بلا مسافة بين
الفقرات — فيقرأها الناظر جدارًا متراصًّا.

**الإصلاح** — أنشئ `lib/utils/article_text.dart`:

```dart
/// يقسّم متن المقال إلى فقرات نظيفة، ويُسقط الفارغة والفضلات القصيرة.
List<String> splitParagraphs(String raw) {
  return raw
      .replaceAll(' ', ' ')
      .split(RegExp(r'\n+'))
      .map((p) => p.trim())
      .where((p) => p.length > 1)
      .toList();
}
```

واستعملها بدل `Text` الواحدة:

```dart
...splitParagraphs(sec.content).map((p) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: _RichArabic(p),      // من المهمة 3
    )),
```

`bottom: 14` هي الفرق بين «جدار نصّ» و«مقال مقروء». طبّقها أيضًا على
`calloutTip` و`calloutWarning` و`faqs`.

---

## المهمة 3 — `**عريض**` يظهر بالنجمتين

كل المقالات الـ6,982 تحوي تنسيق Markdown للعريض — أبرزه سطر التنويه الطبي
`**تنويه طبي إرشادي:**` — ويظهر بالنجمتين لأن `Text` لا يفسّر Markdown.

**لا تُضِف حزمة markdown** — الحاجة أبسط من ذلك وأخفّ. أضف في نفس الملف:

```dart
class _RichArabic extends StatelessWidget {
  final String text;
  const _RichArabic(this.text, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(fontSize: 14.5, color: Color(0xFF4A3F4F), height: 1.75);
    final spans = <TextSpan>[];
    final re = RegExp(r'\*\*(.+?)\*\*', dotAll: true);
    var i = 0;
    for (final m in re.allMatches(text)) {
      if (m.start > i) spans.add(TextSpan(text: text.substring(i, m.start)));
      spans.add(TextSpan(
        text: m.group(1),
        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1B1320)),
      ));
      i = m.end;
    }
    if (i < text.length) spans.add(TextSpan(text: text.substring(i)));
    return RichText(
      textAlign: TextAlign.start,
      textDirection: TextDirection.rtl,
      text: TextSpan(style: base, children: spans),
    );
  }
}
```

لاحظ `height: 1.75` بدل 1.65 — تباعد الأسطر في العربية يحتاج أكثر من اللاتينية،
خاصةً مع التشكيل والهمزات.

---

## المهمة 4 — طبّق نفس المعالجة على كل شاشات المقالات

الأعطال الثلاثة نفسها موجودة في كل شاشة تعرض متنًا. استعمل `splitParagraphs`
و`_RichArabic` في:

- `screens/articles/article_detail_screen.dart`
- `screens/pregnancy/discover_articles_screen.dart`
- شاشة فقه المرأة (`womens_fiqh_data.dart` تُعرض في شاشتها)
- بطاقات المقالات المتخصّصة

اجعل `_RichArabic` عامّة (`RichArabic`) في `lib/utils/article_text.dart`
حتى تُستعمل من كل مكان بدل تكرارها.

---

## التحقّق بعد التنفيذ

1. افتح مقالًا كان فيه بقايا JSON (مثلاً `smart_500_497`) — يجب أن ينتهي
   المتن بجملة عربية، لا بـ`{` ولا `@type`
2. افتح أي مقال — يجب أن ترى **فقرات مفصولة**، والتنويه الطبي **عريضًا بلا نجمتين**
3. احذف حسابًا بالبريد، ثم آخر بـGoogle — وتحقّق من Firestore في الحالتين
4. `flutter analyze` — أرسل المخرجات
