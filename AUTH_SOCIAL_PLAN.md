# خطة المصادقة الجديدة — بريد + شبكات اجتماعية (Google / Facebook / Apple) عبر Firebase

> **يحلّ هذا الملف محلّ [AUTH_HYBRID_PLAN.md](AUTH_HYBRID_PLAN.md) ويُلغيه.** لا تنفّذ خطة الهاتف.
> **الموديل:** Claude Opus — **المجلد:** `C:\nabda_app` — **عربي RTL، لا تترجم النصوص.**
> **القاعدة الذهبية:** يبقى **Firebase Auth** هو مزوّد الهوية الوحيد. لا Clerk ولا طرف ثالث (يكسر فهرسة `users/{uid}` وقواعد `firestore.rules`).

## القرار (مُعتمَد)
- **إلغاء الدخول بالهاتف نهائيًا** (لا بريد اصطناعي `@phone.nabda.app`، لا تطبيع، لا استرجاع واتساب).
- **الدخول/التسجيل المدعوم:** بريد + كلمة مرور، **Google**، **Facebook**، و**Apple** (إلزامي على iOS متى وُجد دخول اجتماعي آخر).
- **TikTok / Instagram: خارج النطاق** (Instagram أوقفت الدخول العام منذ ديسمبر ٢٠٢٤؛ TikTok يحتاج OIDC مخصّص ومراجعة — يُؤجَّل، لا يُنفَّذ الآن).
- **الحساب موحّد على الويب والموبايل تلقائيًا** لأن المزوّد واحد ونفس مشروع Firebase. دخول Google على الويب = نفس UID على الموبايل = نفس `users/{uid}`.

---

## الخطوة 1: الحزم — **لا حزم إضافية** ✅ (مُنفَّذ)
اعتمدنا `firebase_auth` وحده: الويب عبر `signInWithPopup(provider)`، والموبايل عبر
`signInWithProvider(provider)`. لا حاجة لـ google_sign_in/flutter_facebook_auth/sign_in_with_apple
ولا لإعداداتها الأصلية المعقّدة. (إن أردتِ لاحقًا واجهة Google الأصلية على أندرويد يمكن إضافة
google_sign_in، لكنّه غير مطلوب.)

## الخطوة 2: إعادة هيكلة `lib/services/auth_service.dart`
**احذف:** `toAuthEmail`, `normalizePhone`, `isValidIdentifier` (الجزء الخاص بالهاتف)، حقول `recoveryEmail`/`phone`/`authEmail`/`loginType`، ودوال WhatsApp (`getSupportWhatsAppNumber`, `requestPasswordResetViaWhatsApp`, `defaultSupportWhatsApp`).

**أبقِ:** `register`/`login` بالبريد + كلمة المرور (بسّطهما ليأخذا `email` مباشرة بدل `identifier`)، `logout`, `getCurrentUser`, `updateUserProfile`, و`resetPassword(email)` عبر `sendPasswordResetEmail` فقط.

**أضِف دوال الدخول الاجتماعي** (كلها تُرجع `UserCredential` ثم تستدعي `_ensureUserDoc`):
```dart
Future<UserCredential> signInWithGoogle() async {
  if (kIsWeb) {
    return _auth.signInWithPopup(GoogleAuthProvider());
  }
  final g = await GoogleSignIn().signIn();          // Android/iOS
  if (g == null) throw Exception('أُلغي تسجيل الدخول');
  final auth = await g.authentication;
  final cred = GoogleAuthProvider.credential(
      idToken: auth.idToken, accessToken: auth.accessToken);
  return _auth.signInWithCredential(cred);
}

Future<UserCredential> signInWithFacebook() async {
  if (kIsWeb) {
    return _auth.signInWithPopup(FacebookAuthProvider());
  }
  final res = await FacebookAuth.instance.login();  // يطلب email
  final cred = FacebookAuthProvider.credential(res.accessToken!.tokenString);
  return _auth.signInWithCredential(cred);
}

Future<UserCredential> signInWithApple() async {
  final provider = OAuthProvider('apple.com')..addScope('email')..addScope('name');
  if (kIsWeb) return _auth.signInWithPopup(provider);
  // iOS/Android: sign_in_with_apple مع nonce (SHA256)
  // getAppleIDCredential → provider.credential(idToken, rawNonce) → signInWithCredential
}
```

**`_ensureUserDoc(User user, String provider)`** — تُنشئ وثيقة `users/{uid}` **فقط إن لم تكن موجودة** (حتى لا تُتلف بيانات الدخول السابق):
```dart
final ref = _firestore.collection('users').doc(user.uid);
final snap = await ref.get();
if (!snap.exists) {
  await ref.set({
    'name': user.displayName ?? '',
    'email': user.email ?? '',
    'avatar': user.photoURL ?? '',
    'provider': provider,            // 'google' | 'facebook' | 'apple' | 'email'
    'language': 'ar', 'mode': 'cycle',
    'createdAt': DateTime.now().toIso8601String(),
    // ملاحظة: بلا lifeStage → AuthGate يوجّهها لـ onboarding تلقائيًا
  });
}
```

## الخطوة 3: ربط الحسابات (مهمّ — عالِجه)
عند `signInWithCredential` قد يُرمى `account-exists-with-different-credential` (نفس البريد بمزوّد مختلف):
1. `final email = e.email; final methods = await _auth.fetchSignInMethodsForEmail(email);`
2. اطلب من المستخدمة الدخول بالطريقة الموجودة (مثلًا بريد/كلمة مرور أو Google).
3. بعد نجاح الدخول: `await _auth.currentUser!.linkWithCredential(pendingCredential);`
أظهِر رسالة عربية واضحة: «هذا البريد مسجّل بطريقة أخرى — سجّلي الدخول بها لربط الحسابين».

## الخطوة 4: واجهة شاشات الدخول/التسجيل
- في `lib/screens/auth/login_screen.dart` و`main.dart` (`LoginPage` ~1140، والمصادقة المباشرة ~1240/1257):
  - **حقل واحد للبريد** بعنوان «البريد الإلكتروني» (احذف «رقم الهاتف أو البريد» وكل تلميحات الهاتف/213).
  - احذف حقل «بريد الاسترجاع» وزر/مسار استرجاع واتساب.
  - **«نسيت كلمة المرور؟»** → `sendPasswordResetEmail` للبريد فقط.
  - أضِف أزرار اجتماعية أسفل النموذج: **Google** و**Facebook** دائمًا، و**Apple** عبر `if (!kIsWeb && Platform.isIOS) || kIsWeb`.
  - وحّد المنطق عبر استدعاء `AuthService` بدل التكرار في `main.dart` قدر الإمكان.

## الخطوة 5: لا تغيير على `firestore.rules`
`request.auth.uid` يعمل بصرف النظر عن المزوّد. تأكّد فقط أن الوثائق القديمة بلا `provider` تُعامَل كـ `'email'` افتراضيًا في القراءة.

## الخطوة 6: إعداد لوحات المزوّدين (خطوات المالك)
**Firebase Console → Authentication → Sign-in method:** فعّل Email/Password، Google، Facebook، Apple. وفي **Settings → Authorized domains** أضِف نطاقات الويب (`app.nabda.online`, `localhost`, `*.web.app`).
- **Google:** أندرويد يتطلّب بصمات **SHA-1 + SHA-256** في إعدادات تطبيق Firebase + تحديث `google-services.json`. iOS يتطلّب `REVERSED_CLIENT_ID` في URL schemes.
- **Facebook:** أنشئ تطبيق Meta + منتج Facebook Login → ضع App ID/Secret في Firebase. أضِف **OAuth redirect URI:** `https://nabda-app-ca864.firebaseapp.com/__/auth/handler`. على أندرويد: Key Hashes؛ على iOS: URL scheme `fb<APP_ID>`. (مراجعة Meta لصلاحية `email`.)
- **Apple:** حساب مطوّر آبل → Services ID + Key → في Firebase. على iOS أضِف قدرة **Sign in with Apple**. **إلزامي على iOS** متى عُرض دخول اجتماعي آخر (شرط App Store).

## الخطوة 7: الترحيل
- ابحث في Firebase Auth عن مستخدمين ببريد `@phone.nabda.app`. **غالبًا لا يوجد** (خطة الهاتف لم تُطلَق). إن وُجدت قلّة، أبلغ المالك لمعالجتها يدويًا (لا يمكن استرجاعها آليًا).
- مستخدمو البريد الحقيقي الحاليون: **لا يتأثّرون إطلاقًا.**

## الخطوة 8: التحقّق والبناء والرفع
```bash
flutter analyze            # 0 errors
flutter build apk --release && copy build\app\outputs\flutter-apk\app-release.apk nabda.apk
flutter build web --release -t lib/main.dart   # عند تجهيز نسخة الويب
git add -A
git commit -m "feat(auth): بريد + Google/Facebook/Apple عبر Firebase (إلغاء الهاتف)"
git push origin main
```

## اختبارات القبول
1. تسجيل ببريد + كلمة مرور → ينشئ `users/{uid}` بـ `provider:'email'`، ويصل بريد التحقّق.
2. دخول بـ Google على الموبايل ثم على الويب بنفس حساب Google → **نفس UID ونفس البيانات.**
3. دخول بـ Facebook → ينجح وينشئ الوثيقة عند أول مرة فقط.
4. دخول بـ Apple على iOS → ينجح.
5. بريد مسجّل سابقًا بكلمة مرور ثم محاولة Google بنفس البريد → يظهر مسار ربط الحسابات لا خطأ صامت.
6. مستخدم اجتماعي جديد (بلا lifeStage) → يُوجَّه إلى onboarding.

## قيود
- لا Clerk/طرف ثالث للهوية.
- Apple إلزامي على iOS عند وجود دخول اجتماعي آخر.
- اعزِل حزم الموبايل خلف `kIsWeb`/`Platform` حتى لا تكسر بناء الويب.
