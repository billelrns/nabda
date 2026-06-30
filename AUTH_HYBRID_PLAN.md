> ⛔ **مُلغاة ومُستبدَلة بـ [AUTH_SOCIAL_PLAN.md](AUTH_SOCIAL_PLAN.md)** (بريد + Google/Facebook/Apple، وإلغاء الدخول بالهاتف). لا تنفّذ ما يلي — محفوظ للمرجع فقط.

# خطة المصادقة الهجينة (هاتف أو بريد + كلمة مرور، بلا OTP) — لتنفيذ Antigravity

> **الموديل:** Claude Opus 4.6 — **المجلد:** `C:\nabda_app` — **عربي RTL، لا تترجم النصوص.**
> **الهدف:** السماح بتسجيل الدخول/التسجيل **برقم الهاتف أو البريد** + كلمة مرور، **بدون أي رسالة SMS/OTP** (صفر تكلفة). يبقى كل شيء على مزوّد Email/Password المجاني في Firebase.

## الفكرة التقنية (حيلة البريد الاصطناعي)
Firebase لا يدعم «هاتف + كلمة مرور». الحل: تحويل رقم الهاتف داخليًا إلى بريد اصطناعي ثابت، ثم استخدام نفس دوال `createUserWithEmailAndPassword` / `signInWithEmailAndPassword`.

- إن احتوى المُدخَل على `@` → بريد حقيقي، استعمله كما هو.
- إن كان رقم هاتف → طبّعه إلى صيغة دولية بالأرقام فقط ثم ابنِ بريدًا: `<digits>@phone.nabda.app`.

## الخطوة 1: دالة تطبيع موحّدة
أنشئ في `lib/services/auth_service.dart` (أو ملف `lib/utils/auth_identifier.dart`) دالتين ثابتتين:

```dart
/// هل المُدخَل بريد إلكتروني؟
static bool isEmail(String input) => input.contains('@');

/// يحوّل المُدخَل (هاتف أو بريد) إلى بريد صالح لـ Firebase.
/// الهاتف الجزائري الافتراضي بمفتاح +213؛ يزيل المسافات والرموز والصفر البادئ.
static String toAuthEmail(String input) {
  final v = input.trim();
  if (isEmail(v)) return v.toLowerCase();
  var digits = v.replaceAll(RegExp(r'[^0-9+]'), '');
  if (digits.startsWith('+')) digits = digits.substring(1);
  else if (digits.startsWith('00')) digits = digits.substring(2);
  else if (digits.startsWith('0')) digits = '213${digits.substring(1)}'; // الجزائر افتراضيًا
  return '$digits@phone.nabda.app';
}

/// يطبّع رقم الهاتف للتخزين في وثيقة المستخدم (بالأرقام الدولية فقط).
static String normalizePhone(String input) {
  var digits = input.trim().replaceAll(RegExp(r'[^0-9+]'), '');
  if (digits.startsWith('+')) digits = digits.substring(1);
  else if (digits.startsWith('00')) digits = digits.substring(2);
  else if (digits.startsWith('0')) digits = '213${digits.substring(1)}';
  return digits;
}
```

## الخطوة 2: تعديل `AuthService.register` و`login`
- غيّر التوقيع ليقبل `identifier` (هاتف أو بريد) بدل `email` فقط، أو أبقِ الاسم وعامِله كمعرّف.
- في `register`: استعمل `toAuthEmail(identifier)` للمصادقة. خزّن في وثيقة `users/{uid}`:
  - `loginType`: `'phone'` أو `'email'`.
  - `phone`: `normalizePhone(identifier)` إن كان هاتفًا (وإلا فارغ).
  - `email`: البريد الحقيقي إن كان بريدًا (وإلا فارغ).
  - `recoveryEmail`: بريد استرجاع اختياري (انظر الخطوة 5).
  - احتفظ بـ `name`.
- **لا ترسل `sendEmailVerification()` لحسابات الهاتف** (البريد اصطناعي لا يصل). أرسلها فقط إن كان `loginType == 'email'`.
- في `login`: استعمل `signInWithEmailAndPassword(email: toAuthEmail(identifier), ...)`.
- حدّث رسائل الأخطاء العربية لتقول «الهاتف/البريد أو كلمة المرور غير صحيحة».

## الخطوة 3: تعديل المصادقة المباشرة في `main.dart` (~السطور 1240، 1257)
طبّق نفس التحويل: استبدل تمرير البريد الخام بـ `AuthService.toAuthEmail(identifier)`، واكتب نفس حقول Firestore (`loginType`/`phone`/`email`). وحّد المنطق عبر استدعاء `AuthService` بدل التكرار إن أمكن.

## الخطوة 4: واجهة شاشات التسجيل/الدخول
- حقل واحد ذكيّ بعنوان **«رقم الهاتف أو البريد الإلكتروني»** بدل حقل البريد.
- `keyboardType: TextInputType.emailAddress` (يسمح بالاثنين)، وعطّل التصحيح التلقائي.
- تلميح: «أدخلي رقم هاتفك (مثال: 0555…) أو بريدك الإلكتروني».
- في التسجيل: أبقِ حقل الاسم وكلمة المرور كما هي.
- تحقّق من الصحة: المُدخَل إمّا بريد صالح أو رقم هاتف ≥ 9 أرقام (استعمل/وسّع `lib/utils/validators.dart`).

## الخطوة 5: استرجاع كلمة المرور (القيد الوحيد — عالِجه)
- حسابات **البريد الحقيقي**: `sendPasswordResetEmail` يعمل طبيعيًا.
- حسابات **الهاتف فقط**: لا بريد للاسترجاع. الحل بلا OTP:
  - أضِف حقل **«بريد استرجاع (اختياري)»** عند التسجيل بالهاتف، خزّنه في `recoveryEmail`، وأرسل إعادة التعيين إليه عند الحاجة.
  - وأضِف **إعادة تعيين من لوحة الأدمن** (المشرف يضبط كلمة مرور مؤقتة) كخطّة بديلة.
- في شاشة «نسيت كلمة المرور»: إن أدخلت المستخدمة هاتفًا، اقرأ `recoveryEmail` من وثيقتها وأرسل إليه؛ إن لم يوجد، اعرض رسالة «تواصلي مع الدعم لإعادة التعيين».

## الخطوة 6: الترحيل (المستخدمون الحاليون)
المستخدمون الحاليون سجّلوا ببريد حقيقي — يبقون كما هم (loginType='email'). لا حاجة لترحيل. فقط تأكّد أن الوثائق القديمة بلا `loginType` تُعامَل كـ `'email'` افتراضيًا.

## الخطوة 7: التحقّق والبناء والرفع
```bash
flutter analyze            # 0 errors
flutter build apk --release && copy build\app\outputs\flutter-apk\app-release.apk nabda.apk
git add -A
git commit -m "feat(auth): مصادقة هجينة (هاتف أو بريد + كلمة مرور بلا OTP)"
git push origin main
```

## اختبارات القبول
1. تسجيل برقم `0555123456` + كلمة مرور → ينشئ حسابًا، ويُخزّن `phone=213555123456`, `loginType='phone'`.
2. تسجيل الخروج ثم الدخول بنفس الرقم وكلمة المرور → ينجح.
3. تسجيل ببريد `x@y.com` → يعمل كالسابق، ويصل بريد التحقّق.
4. الدخول ببريد حقيقي → ينجح.
5. لا تُرسَل أي رسالة SMS في أي مسار.

## قيود
- لا تستعمل `verifyPhoneNumber`/`PhoneAuthProvider` (تعني SMS مدفوع).
- نطاق البريد الاصطناعي `@phone.nabda.app` ثابت ولا يُغيَّر بعد الإطلاق (وإلا تُكسر الحسابات).
- طبّع الهاتف بنفس الدالة في كل المسارات حتى لا يختلف البريد الاصطناعي بين التسجيل والدخول.
