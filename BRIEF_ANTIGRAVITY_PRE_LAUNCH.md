# أمر تنفيذ لـAntigravity — إصلاحات ما قبل النشر

مرجع الفحص: `PRE_LAUNCH_AUDIT.md` · 18 سبتمبر 2026

> **اقرأ هذا القسم قبل أي تعديل.** ثلاث نقاط فيه لا رجعة فيها.

---

## ⛔ قواعد غير قابلة للتفاوض

1. **الـkeystore**: بعد توليده، انسخه إلى مكانين خارج المشروع وخارج git.
   ضياعه = استحالة تحديث التطبيق مدى الحياة. لا حلّ لدى Google، ولا استثناء.
2. **معرّف الحزمة** `com.nabda.app`: لا يتغيّر بعد أول نشر. اعتمده الآن نهائياً.
3. **لا تفعّل `minifyEnabled` في هذه الدفعة.** (التفصيل في المهمة 12 — مؤجّلة عمداً.)

---

## المهمة 1 — تغيير معرّف الحزمة إلى `com.nabda.app`

### أندرويد

**`android/app/build.gradle.kts`**
```kotlin
// السطر 8
namespace = "com.nabda.app"          // كان com.example.nabda
// السطر 21
applicationId = "com.nabda.app"      // كان com.example.nabda
```

**نقل ملف Kotlin** — أنشئ المسار الجديد وانقل الملف:
```
من : android/app/src/main/kotlin/com/example/nabda/MainActivity.kt
إلى : android/app/src/main/kotlin/com/nabda/app/MainActivity.kt
```
وبداخله غيّر السطر الأول:
```kotlin
package com.nabda.app                // كان package com.example.nabda
```
ثم احذف المجلّد الفارغ `com/example/`.

**`android/app/google-services.json`** — هذا الملف **لا يُحرَّر يدوياً**.
في وحدة تحكّم Firebase → إعدادات المشروع → «إضافة تطبيق» → Android →
اسم الحزمة `com.nabda.app` → نزّل الملف الجديد واستبدل القديم.
(لا تحذف تطبيق `com.example.nabda` من Firebase الآن — احذفه بعد نجاح البناء.)

### iOS

**`ios/Runner.xcodeproj/project.pbxproj`** — الأسطر 375 و554 و576:
```
PRODUCT_BUNDLE_IDENTIFIER = com.nabda.app;      // كان com.example.nabda
```
والأسطر 391 و408 و423 (هدف الاختبارات):
```
PRODUCT_BUNDLE_IDENTIFIER = com.nabda.app.RunnerTests;
```

في Firebase → إضافة تطبيق → iOS → `com.nabda.app` → نزّل
`GoogleService-Info.plist` وضعه في `ios/Runner/`، **وأضفه إلى هدف Runner
في Xcode** (وجوده في المجلّد وحده لا يكفي — يجب أن يظهر في Build Phases →
Copy Bundle Resources).

### التحقّق
```
flutter clean && flutter pub get && flutter build apk --debug
```
يجب أن يمرّ البناء، وأن يُظهر `aapt dump badging` الحزمة `com.nabda.app`.

---

## المهمة 2 — تصحيح `firebase_options.dart`

**`lib/firebase_options.dart`** — الملف حالياً يستعمل **معرّف تطبيق الويب**
في الأقسام الثلاثة. بعد إضافة تطبيقَي Android وiOS في Firebase (المهمة 1)،
أعد توليد الملف كاملاً بالأمر الرسمي بدل التحرير اليدوي:

```
dart pub global activate flutterfire_cli
flutterfire configure --project=nabda-app-ca864
```

### التحقّق
افتح الملف الناتج وتأكّد أن:
- `android.appId` يحتوي `:android:` لا `:web:`
- `ios.appId` يحتوي `:ios:` لا `:web:`
- `ios.iosBundleId == 'com.nabda.app'` ويطابق ما في Xcode

---

## المهمة 3 — توقيع نسخة الإصدار

```
keytool -genkey -v -keystore nabda-release.jks -keyalg RSA \
  -keysize 2048 -validity 10000 -alias nabda
```

ضع الملف **خارج مجلّد المشروع** (مثلاً `C:\keys\nabda-release.jks`).

**`android/key.properties`** (ملف جديد):
```properties
storePassword=<كلمة السر>
keyPassword=<كلمة السر>
keyAlias=nabda
storeFile=C:/keys/nabda-release.jks
```

**`.gitignore`** — أضف سطراً:
```
android/key.properties
```

**`android/app/build.gradle.kts`** — أضف قبل كتلة `android {`:
```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

وداخل `android { }` استبدل كتلة `buildTypes` بالكامل:
```kotlin
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false      // تُفعَّل لاحقاً في مهمة منفصلة
            isShrinkResources = false
        }
    }
```

### التحقّق
```
flutter build appbundle --release
```
ثم `keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab`
يجب ألا يظهر `CN=Android Debug`.

---

## المهمة 4 — إزالة مخالفة `USE_EXACT_ALARM`

**`android/app/src/main/AndroidManifest.xml`** — احذف السطرين 3 و4:
```xml
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>   ← احذف
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>        ← احذف
```
أبقِ `POST_NOTIFICATIONS` و`RECEIVE_BOOT_COMPLETED` و`VIBRATE`.

**`lib/main.dart`** — الأسطر 1170 و1317 و1330:
```dart
androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
// كان AndroidScheduleMode.alarmClock
```

### التحقّق
ابحث في المشروع كله عن `alarmClock` و`exactAllowWhileIdle` — يجب ألا تبقى نتيجة.

---

## المهمة 5 — أوصاف صلاحيات iOS

**`ios/Runner/Info.plist`** — أضف داخل `<dict>` الرئيسي:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>يحتاج نبضة إلى الوصول لصورك لاختيار صورة ملفك الشخصي أو صورة طفلك.</string>
<key>NSCameraUsageDescription</key>
<string>يحتاج نبضة إلى الكاميرا لالتقاط صورة ملفك الشخصي أو صورة طفلك.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>يحتاج نبضة إلى الإذن لحفظ الصور في معرض هاتفك.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>يستعمل نبضة موقعك عند طلبك فقط للبحث عن أقرب طبيبة نساء أو مستشفى ولادة.</string>
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

> `NSLocationWhenInUseUsageDescription` **إلزامي** — `geolocator: ^10.1.0`
> موجود في `pubspec.yaml:42` وتستعمله شاشة الأطبّاء. غيابه = انهيار ورفض،
> تمامًا كأوصاف الكاميرا.

وفي نفس الملف، قصر الاتجاه على العمودي (الأسطر 56-61):
```xml
<key>UISupportedInterfaceOrientations</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
</array>
```
(اترك `UISupportedInterfaceOrientations~ipad` كما هو.)

---

## المهمة 6 — ملف خصوصية Apple

أنشئ **`ios/Runner/PrivacyInfo.xcprivacy`**:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>NSPrivacyTracking</key>
  <false/>
  <key>NSPrivacyTrackingDomains</key>
  <array/>
  <key>NSPrivacyCollectedDataTypes</key>
  <array>
    <dict>
      <key>NSPrivacyCollectedDataType</key>
      <string>NSPrivacyCollectedDataTypeEmailAddress</string>
      <key>NSPrivacyCollectedDataTypeLinked</key><true/>
      <key>NSPrivacyCollectedDataTypeTracking</key><false/>
      <key>NSPrivacyCollectedDataTypePurposes</key>
      <array><string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string></array>
    </dict>
    <dict>
      <key>NSPrivacyCollectedDataType</key>
      <string>NSPrivacyCollectedDataTypeName</string>
      <key>NSPrivacyCollectedDataTypeLinked</key><true/>
      <key>NSPrivacyCollectedDataTypeTracking</key><false/>
      <key>NSPrivacyCollectedDataTypePurposes</key>
      <array><string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string></array>
    </dict>
    <dict>
      <key>NSPrivacyCollectedDataType</key>
      <string>NSPrivacyCollectedDataTypeHealth</string>
      <key>NSPrivacyCollectedDataTypeLinked</key><true/>
      <key>NSPrivacyCollectedDataTypeTracking</key><false/>
      <key>NSPrivacyCollectedDataTypePurposes</key>
      <array><string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string></array>
    </dict>
    <dict>
      <key>NSPrivacyCollectedDataType</key>
      <string>NSPrivacyCollectedDataTypeUserContent</string>
      <key>NSPrivacyCollectedDataTypeLinked</key><true/>
      <key>NSPrivacyCollectedDataTypeTracking</key><false/>
      <key>NSPrivacyCollectedDataTypePurposes</key>
      <array><string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string></array>
    </dict>
  </array>
  <key>NSPrivacyAccessedAPITypes</key>
  <array>
    <dict>
      <key>NSPrivacyAccessedAPIType</key>
      <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array><string>CA92.1</string></array>
    </dict>
    <dict>
      <key>NSPrivacyAccessedAPIType</key>
      <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array><string>C617.1</string></array>
    </dict>
    <dict>
      <key>NSPrivacyAccessedAPIType</key>
      <string>NSPrivacyAccessedAPICategoryDiskSpace</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array><string>E174.1</string></array>
    </dict>
    <dict>
      <key>NSPrivacyAccessedAPIType</key>
      <string>NSPrivacyAccessedAPICategorySystemBootTime</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array><string>35F9.1</string></array>
    </dict>
  </array>
</dict>
</plist>
```

**مهم**: أضفه إلى هدف Runner في Xcode (Copy Bundle Resources)، وإلا لن يُشحن.

---

## المهمة 7 — حذف الحساب يحذف البيانات فعلياً

> **ملاحظة مهمّة**: لا حاجة إلى Cloud Functions ولا إلى خطة Blaze المدفوعة.
> قواعد Firestore الحالية تسمح لصاحبة الحساب بالكتابة في كل مجموعاتها
> الفرعية (`match /{subCollection=**}` السطر 81)، فالحذف من التطبيق ممكن —
> ينقصه فقط فتح حذف الوثيقة الأم.

### 7-أ · قواعد Firestore

**`firestore.rules`** السطر 45:
```
allow delete: if isAuthenticated() && isOwner(userId);
// كان: allow delete: if false;
```

**`firestore.rules`** السطر 106 (داخل `users_directory`):
```
allow delete: if isAuthenticated() && isOwner(userId);
// كان: allow delete: if false;
```
> السبب: `auth_service.dart:118` يحاول حذف هذه الوثيقة اليوم، والقاعدة
> ترفض بصمت داخل `try/catch` — فيبقى الاسم والبريد والصورة في الدليل العام
> بعد «حذف» الحساب.

ثم انشر القواعد: `firebase deploy --only firestore:rules`

### 7-ب · الحذف المتتالي في التطبيق

**`lib/services/auth_service.dart`** — استبدل جسم `deleteAccount` (الأسطر 115-133)
بالترتيب التالي. **الترتيب إلزامي**: كل الحذف قبل `user.delete()`، لأن حذف
حساب المصادقة يُسقط الصلاحيات فوراً ويصبح ما بعده مرفوضاً.

```dart
final db = FirebaseFirestore.instance;

// ① المجموعات الفرعية تحت /users/{uid}
for (final sub in const [
  'followers', 'following', 'blocked', 'favorites',
  'babies', 'baby_logs', 'cycle_logs', 'weight_tracker',
  'vaccines', 'logs', 'journal', 'kicks', 'hospital_bag',
]) {
  while (true) {
    final snap = await db.collection('users').doc(uid)
        .collection(sub).limit(400).get();
    if (snap.docs.isEmpty) break;
    final batch = db.batch();
    for (final d in snap.docs) { batch.delete(d.reference); }
    await batch.commit();
    if (snap.docs.length < 400) break;
  }
}

// ② المجموعات العليا المرتبطة بالمستخدمة
for (final col in const ['cycles', 'pregnancies', 'babies', 'messages']) {
  while (true) {
    final snap = await db.collection(col)
        .where('userId', isEqualTo: uid).limit(400).get();
    if (snap.docs.isEmpty) break;
    final batch = db.batch();
    for (final d in snap.docs) { batch.delete(d.reference); }
    await batch.commit();
    if (snap.docs.length < 400) break;
  }
}

// ③ منشورات المجتمع وحصّة الذكاء الاصطناعي
final posts = await db.collection('community_posts')
    .where('userId', isEqualTo: uid).get();
for (final p in posts.docs) { await p.reference.delete(); }
try { await db.collection('ai_quota').doc(uid).delete(); } catch (_) {}

// ④ الدليل العام ثم الوثيقة الأم
try { await db.collection('users_directory').doc(uid).delete(); } catch (_) {}
await db.collection('users').doc(uid).delete();

// ⑤ أخيراً: حساب المصادقة
await user.delete();
```

**احذف تماماً** الكتلة القديمة التي تكتب `deletionRequested: true` — فهي
تَعِد بحذف لا يحدث، ولا يوجد في المشروع أي Cloud Function تقرؤها.

### 7-ج · إفصاح صادق عمّا لا يُحذف

الرسائل المباشرة في `/direct_chats/{id}/messages` لا تُحذف (القاعدة السطر 336
تمنع الحذف)، لأنها تخصّ طرفين. وسجلّات `/orders` تبقى لأسباب محاسبية.
هذا مقبول — **بشرط ذكره صراحةً**.

في **`lib/screens/profile/data_control_screen.dart`** أضف تحت تحذير الحذف:
```
ما يبقى بعد الحذف: رسائلك في المحادثات الثنائية (لأنها تخصّ طرفين)،
وسجلّات طلبات المتجر (التزام محاسبي). ما عدا ذلك يُحذف نهائياً.
```
وأضف السطر نفسه في `onboarding_screen.dart` داخل قسم «6. حقوقك».

---

## المهمة 8 — زر الإبلاغ عن المحتوى

> **الخلفية جاهزة أصلاً.** مجموعة `/reports` معرَّفة في `firestore.rules`
> السطر 355 وتقبل الإنشاء من أي مستخدمة مصادَقة بشرط
> `reporterUid == request.auth.uid`. المطلوب واجهة فقط.

في **`lib/main.dart`** عند بطاقة منشور المجتمع (حوالي السطر 8760، حيث
`isAnonymous` و`authorName`): أضف زرّ `PopupMenuButton` بأيقونة `more_vert`
في أعلى البطاقة، يحوي:

- **«إبلاغ عن المنشور»** (لكل من ليست صاحبة المنشور)
- **«حظر هذه المستخدمة»** (يستدعي المنطق الموجود في `messaging_service.dart:94`)
- **«حذف»** (لصاحبة المنشور فقط — إن لم يكن موجوداً)

عند اختيار «إبلاغ» اعرض `AlertDialog` بأسباب:
`محتوى مسيء · معلومات طبية خاطئة · إعلان أو احتيال · انتحال شخصية · أخرى`
ثم اكتب:

```dart
await FirebaseFirestore.instance.collection('reports').add({
  'reporterUid'  : FirebaseAuth.instance.currentUser!.uid,
  'targetType'   : 'community_post',
  'targetId'     : postId,
  'targetUserId' : postAuthorUid,
  'reason'       : selectedReason,
  'note'         : noteController.text,
  'status'       : 'pending',
  'createdAt'    : FieldValue.serverTimestamp(),
});
```
ثم `SnackBar`: «تم استلام بلاغك، سيراجعه الفريق خلال 24 ساعة.»

طبّق الشيء نفسه على **التعليقات** وعلى **المحادثات المباشرة**
(`targetType: 'comment'` و`'direct_chat'`).

**وأضف صفحة مراجعة البلاغات في لوحة الأدمن** — قائمة `/reports` مرتَّبة
بـ`createdAt` مع زرَّي «حذف المنشور» و«تجاهل». وجود البلاغات دون من يراجعها
مخالفة أيضاً.

---

## المهمة 9 — صفحات الخصوصية والشروط على الويب

أنشئ **`web/privacy.html`** و**`web/terms.html`** بنفس تنسيق
`web/delete-account.html` (RTL، نفس الألوان)، ومحتواهما **منقول حرفياً**
من الكود الموجود:

- الخصوصية: `lib/screens/onboarding_screen.dart:1492` فما بعد
- الشروط: `TermsOfServicePage` في الملف نفسه

أضف في تذييل `web/index.html` و`web/landing.html` و`web/articles.html`:
```html
<a href="/privacy.html">سياسة الخصوصية</a> ·
<a href="/terms.html">شروط الاستخدام</a> ·
<a href="/delete-account.html">حذف الحساب</a>
```

**الروابط المطلوبة في بيانات المتجرين:**
```
https://nabda.online/privacy.html
https://nabda.online/delete-account.html
```

---

## المهمة 10 — إصلاح صفحة حذف الحساب

**`web/delete-account.html`** السطر 25: النموذج الحالي
`<form action="mailto:…" method="post">` **لا يعمل في أي متصفّح حديث** —
الزر لا يفعل شيئاً. ومراجع Google Play يفتح هذا الرابط ويجرّبه.

استبدله بخدمة نماذج حقيقية (Formspree أو Web3Forms — كلاهما مجاني):
```html
<form action="https://formspree.io/f/XXXXXXX" method="POST">
```
وبدّل البريد المكشوف `matbakhwalid@gmail.com` إلى `privacy@nabda.online`.

أضف بعد الإرسال رسالة تأكيد ظاهرة: «تم استلام طلبك، سيُنفَّذ خلال 30 يوماً.»

---

## المهمة 11 — تنظيف الادّعاءات غير الصحيحة

احذف شارة App Store وروابطها (التطبيق غير منشور عليه بعد):
```
web/articles.html:1152 و1303
scripts/build_web_articles_portal.py:1177 و1328
```
استبدلها بنص «قريباً على App Store» بلا رابط، أو احذف الشارة كلياً.

وأضف إلى `.gitignore`:
```
nabda-import/node_modules/
android/hs_err_pid*.log
android/replay_pid*.log
```
ثم احذف ملفات `hs_err_pid*` و`replay_pid*` الثلاثة عشر من `android/`.

---

## المهمة 12 — تحذير الذكاء الاصطناعي وموافقة أولى

مصدر البند: `STORE_COMPLIANCE_AUDIT.md` رقم 6 و14 — سياسة Generative AI في
Google Play وقاعدة Apple 5.1.1(iv). تطبيق يعطي إجابات صحّية بالذكاء
الاصطناعي دون تحذير = رفض.

في شاشة المساعد الذكي (`lib/main.dart` حول `_callGemini` السطر 9268):

**أ. بانر ثابت أعلى الشاشة** بخلفية عنبرية فاتحة:
```
⚠️ إجابات مساعد نبضة إرشادية فقط وقد تحتوي أخطاء.
   للحالات الطبية أو الطارئة استشيري طبيبتك مباشرة.
```

**ب. نافذة موافقة أول مرة** (تُحفظ في `SharedPreferences` بمفتاح
`ai_consent_v1`، تظهر مرّة واحدة):
```
مساعد نبضة الذكي يعمل بواسطة Google Gemini.
أسئلتك تُرسَل إلى خوادم Google لمعالجتها ولا تُستعمل لتدريب النماذج.
لا تُدخلي معلومات تعريفية أو نتائج تحاليل تخصّك.
                                   [موافقة]  [إلغاء]
```
عند الإلغاء: أغلقي الشاشة ولا تُرسلي أي طلب.

**ج. زر «الإبلاغ عن هذه الإجابة»** تحت كل ردّ من المساعد، يكتب في `/reports`
بنفس الصيغة في المهمة 8 مع `targetType: 'ai_response'` ونصّ السؤال والجواب.

---

## المهمة 13 — بصمات SHA للدخول الاجتماعي

الدخول بـGoogle وFacebook وApple **مُفعَّل فعلاً**
(`lib/services/auth_service.dart:140-146`). بدون بصمات التوقيع، زرّ Google
**لن يعمل في نسخة المتجر** رغم عمله في التطوير.

بعد توليد الـkeystore (المهمة 3):
```
cd android
gradlew signingReport
```
انسخ **SHA-1 و SHA-256** لـdebug و release، وأضفها في
Firebase Console → إعدادات المشروع → تطبيق Android → SHA certificate fingerprints.

وبعد أول رفع إلى Play، أضف **بصمة Play App Signing** أيضًا (تجدها في
Play Console → Setup → App signing) — وإلا تعطّل الدخول للمستخدمات الحقيقيات
بينما يعمل عندك.

---

## المهمة 14 — Crashlytics

ليس حاجز نشر، لكنه الفارق بين معرفة سبب انهيار التطبيق عند مستخدماتك وبين
التخمين.

```yaml
firebase_crashlytics: ^4.1.0
```
وفي `main()` بعد `Firebase.initializeApp`:
```dart
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
PlatformDispatcher.instance.onError = (error, stack) {
  FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  return true;
};
```

---

## المهمة 15 — 🔶 مؤجّلة: تأمين مفتاح Gemini + minify

**لا تنفّذ هاتين في هذه الدفعة.** كلتاهما تحمل خطر كسر التطبيق، والأفضل
تنفيذهما بعد أن تستقرّ الدفعة الأولى ويمرّ بناء إصدار ناجح.

- **مفتاح Gemini** (`lib/main.dart:9164`): الحلّ الصحيح نقل النداء إلى
  خادم وسيط. الحلّ الفوري بلا كود: في Google Cloud Console → Credentials →
  قيّد المفتاح بـ«Android apps» مع `com.nabda.app` وبصمة SHA-1 للـkeystore،
  وبـ«iOS apps» مع نفس المعرّف. يبقى المفتاح في الـAPK لكنه يصبح عديم
  النفع خارج تطبيقك. **نفّذ هذا بعد المهمتين 1 و3 لأنه يحتاج المعرّف
  والبصمة النهائيين.**
- **`isMinifyEnabled`**: مؤجّلة إلى دفعة مستقلّة مع ملف
  `proguard-rules.pro` واختبار كامل (السبب في القسم التالي).

---

## ترتيب التنفيذ والتحقّق

| # | المهمة | تتوقّف على |
|---|---|---|
| 1 | معرّف الحزمة | — |
| 2 | firebase_options | 1 |
| 3 | التوقيع | 1 |
| 4 | USE_EXACT_ALARM | — |
| 5 | Info.plist | 1 |
| 6 | PrivacyInfo | — |
| 7 | الحذف المتتالي | — |
| 8 | زر الإبلاغ | — |
| 9 | صفحات الويب | — |
| 10 | صفحة الحذف | 9 |
| 11 | التنظيف | — |
| 12 | تحذير AI + موافقة | — |
| 13 | بصمات SHA | 1، 3 |
| 14 | Crashlytics | — |

**بعد كل شيء:**
```
flutter clean
flutter pub get
flutter analyze            ← أرسل المخرجات
flutter test               ← أرسل المخرجات
flutter build appbundle --release
```

**اختبار يدوي إلزامي قبل الرفع:**
1. تسجيل حساب جديد → إدخال بيانات دورة وحمل وطفل ومنشور مجتمع
2. حذف الحساب → التحقّق في وحدة تحكّم Firestore أن `/users/{uid}` اختفت
   ومعها المجموعات الفرعية و`/users_directory/{uid}`
3. الإبلاغ عن منشور → ظهور وثيقة في `/reports`
4. تذكير الدورة يصل (قد يتأخّر دقائق — هذا متوقّع، اقرأ القسم التالي)
5. اختيار صورة ملف شخصي على iPhone حقيقي دون انهيار
