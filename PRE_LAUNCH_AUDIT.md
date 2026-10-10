# فحص ما قبل النشر — تطبيق نبضة

17 سبتمبر 2026 · Google Play + App Store

---

## الخلاصة في سطر

**التطبيق غير جاهز للرفع الآن.** وجدتُ **11 حاجز نشر** (رفض شبه مؤكّد)،
و**5 مخاطر مرتفعة**، و**4 تحسينات**. أغلب الحواجز إصلاحها دقائق لا أيام —
لكن أربعة منها ستُرفض آلياً عند الرفع قبل أن يراها مراجع بشري.

قبل ذلك، ما تحقّقتُ أنه **سليم فعلاً** (لأن المراجعة التي تذكر الأخطاء فقط
مضلِّلة):

| ✅ | الدليل |
|---|---|
| قواعد Firestore تمنع الأدمن من قراءة البيانات الصحّية | `firestore.rules` — قراءة `/users/{uid}` للمالك فقط |
| شاشة حذف الحساب موجودة داخل التطبيق | `lib/screens/profile/data_control_screen.dart` |
| سياسة خصوصية مفصّلة تذكر البيانات الصحّية صراحةً | `onboarding_screen.dart:1492` |
| إخلاء المسؤولية الطبي على المقالات | `smart_article_detail_screen.dart:500` |
| حظر المستخدمين | `blocked_users_screen.dart` + `messaging_service.dart:94` |
| النشر باسم مجهول في المجتمع | `community_post_model.dart` |
| كيانات HTML المكسورة (426 مقالًا) | **أُصلحت** — 0 نتيجة الآن |
| صور المقالات | 6,982 مقالًا · 15 صورة · 0 مفقود |

---

## 🔴 حواجز نشر — لا تُرفع قبل إصلاحها

### 1. معرّف التطبيق `com.example` — رفض آلي في المتجرين

```
android/app/build.gradle.kts:8   namespace   = "com.example.nabda"
android/app/build.gradle.kts:21  applicationId = "com.example.nabda"
ios/Runner.xcodeproj/project.pbxproj:375,554,576  PRODUCT_BUNDLE_IDENTIFIER = com.example.nabda
```

Google Play وApple يرفضان أي حزمة تبدأ بـ`com.example` — رفض آلي عند الرفع،
لا يصل إلى مراجع بشري. **وهذا القرار لا رجعة فيه**: معرّف الحزمة لا يمكن
تغييره بعد أول نشر، فالخطأ هنا يعني حساب تطبيق جديد من الصفر.

المطلوب: `com.nabda.app` (وهو ما يتوقّعه `firebase_options.dart` أصلاً).
التغيير يشمل أيضاً مسار المجلّد
`android/app/src/main/kotlin/com/example/nabda/MainActivity.kt` وسطر `package`
بداخله، وإعادة توليد `google-services.json` من وحدة تحكّم Firebase.

---

### 2. نسخة الإصدار موقَّعة بمفتاح التصحيح

```
android/app/build.gradle.kts:31-34
    release {
        // TODO: Add your own signing config for the release build.
        signingConfig = signingConfigs.getByName("debug")
    }
```

Play يرفض أي AAB موقَّع بمفتاح debug. المطلوب: توليد keystore،
وملف `android/key.properties` (خارج git)، وربطه في `build.gradle.kts`.

⚠️ **احتفظ بنسخة من الـkeystore في مكان آمن.** فقدانه = استحالة تحديث
التطبيق مدى الحياة، ولا حلّ لدى Google.

---

### 3. صلاحية `USE_EXACT_ALARM` — مخالفة سياسة صريحة

```
android/app/src/main/AndroidManifest.xml:4   USE_EXACT_ALARM
lib/main.dart:1170, 1317, 1330   androidScheduleMode: AndroidScheduleMode.alarmClock
```

Google Play يقصر `USE_EXACT_ALARM` على التطبيقات التي **وظيفتها الأساسية**
منبّه أو ساعة أو تقويم. تطبيق متابعة دورة يذكّر بموعد ليس منها — ستُطالَب
بتبرير، والنتيجة الغالبة رفض.

الإصلاح: احذف السطر 4 من الـManifest، وبدّل الأوضاع الثلاثة إلى
`AndroidScheduleMode.inexactAllowWhileIdle`. فرق الدقّة بضع دقائق —
لا يُلاحَظ في تذكير دورة، ويزيل المخالفة نهائياً.

---

### 4. iOS: أوصاف استخدام الصلاحيات مفقودة — تعطُّل مؤكَّد

`image_picker` من ضمن التبعيات (`pubspec.yaml:33`)، بينما
`ios/Runner/Info.plist` **لا يحتوي** على:

```
NSPhotoLibraryUsageDescription
NSCameraUsageDescription
```

على iOS هذا ليس تحذيراً: التطبيق **ينهار فوراً** لحظة فتح منتقي الصور،
والمراجعة ترفض لهذا السبب وحده.

---

### 5. iOS: ملف الخصوصية `PrivacyInfo.xcprivacy` مفقود

Apple تشترطه منذ مايو 2024 لكل تطبيق يستعمل «واجهات ذات سبب مطلوب».
نبضة تستعملها عبر ثلاث حزم: `shared_preferences` (UserDefaults)،
`sqflite` و`path_provider` (طوابع زمنية للملفات ومساحة القرص).

بدونه يُرفض الرفع من App Store Connect قبل المراجعة.

---

### 6. iOS: `GoogleService-Info.plist` غير موجود

`ios/Runner/` لا يحتوي الملف. Firebase على iOS لن يعمل بشكل صحيح
(المصادقة والإشعارات خاصة)، رغم وجود `firebase_options.dart`.

---

### 7. خطأ في إعداد Firebase: معرّف تطبيق الويب على أندرويد وiOS

```
lib/firebase_options.dart:24  android → appId: '1:911912460091:web:d93a70…'
lib/firebase_options.dart:31  ios     → appId: '1:911912460091:web:d93a70…'
```

الثلاثة يستعملون **معرّف الويب**. الصحيح `…:android:…` و`…:ios:…`.
النتيجة: تحليلات مختلطة، وسلوك غير متوقّع في المصادقة والإشعارات على iOS.

وبالإضافة: `iosBundleId: 'com.nabda.app'` (السطر 35) **يخالف**
`com.example.nabda` في مشروع Xcode. تناقض سيكسر Firebase على iOS.

---

### 8. لا رابط عام لسياسة الخصوصية

السياسة موجودة **داخل التطبيق فقط** (`onboarding_screen.dart:1492`).
Google Play وApple يشترطان رابطاً عاماً يُفتح دون تثبيت التطبيق، ويُدخَل
في بيانات القائمة. لا يوجد `web/privacy.html` ولا `terms.html`.

الإصلاح سريع: تحويل نصّ السياسة الموجود إلى `web/privacy.html` +
`web/terms.html` ونشرهما على nabda.online.

---

### 9. حذف الحساب **لا يحذف البيانات فعلياً**

```
lib/services/auth_service.dart:126-130
    await …collection('users').doc(uid).set({
      'deletionRequested': true,      // ← علامة فقط
    }, SetOptions(merge: true));
```

التعليق في الكود يقول إن الحذف الكامل «يتم من جهة الخادم».
**لا يوجد مجلّد `functions/` في المشروع، ولا أي Cloud Function.**
أي أن العلامة تُكتب ولا يقرؤها أحد، والبيانات الصحّية تبقى إلى الأبد.

وفي الوقت نفسه سياسة الخصوصية تَعِد: «الحذف: يمكنكِ طلب حذف حسابك
**وجميع بياناتك**» (السطر 1562).

هذا تناقض بين الوعد والتنفيذ في تطبيق صحّي — وهو بالضبط ما يبحث عنه
مراجعو Data Safety. المطلوب: Cloud Function على `onDelete` أو على
`deletionRequested` تحذف `/users/{uid}` ومجموعاته الفرعية.

---

### 10. صفحة حذف الحساب على الويب معطّلة فعلياً

```
web/delete-account.html:25
  <form action="mailto:matbakhwalid@gmail.com…" method="post" enctype="text/plain">
```

المتصفّحات الحديثة **لا ترسل** نموذجاً بـ`method="post"` إلى `mailto:`.
الضغط على الزر لا يفعل شيئاً عند أغلب المستخدمات. ومراجع Play يفتح هذا
الرابط ويجرّبه بنفسه.

وإضافةً: الصفحة تكشف بريدك الشخصي علناً — مصدر بريد مزعج، ومظهر غير مهني
لتطبيق صحّي. استعمل بريد نطاق مثل `privacy@nabda.online` ونموذجاً حقيقياً
(Formspree أو Cloud Function).

---

### 11. لا آلية إبلاغ عن محتوى المجتمع

التطبيق فيه **حظر** (`blocked_users_screen.dart`) لكن لا يوجد أي زرّ
«إبلاغ» عن منشور أو تعليق — بحثتُ عن `report/إبلاغ/تبليغ/شكوى` فلم أجد شيئاً.

سياسة المحتوى من المستخدمين في Google Play تشترط **الاثنين معاً**:
إبلاغ داخل التطبيق **و** حظر. وجود الحظر وحده لا يكفي.

---

## 🟠 مخاطر مرتفعة

### 12. مفتاح Gemini مكشوف في الكود

```
lib/main.dart:9164   final String _apiKey = 'AIzaSy…kTI';
```

يُشحن داخل الـAPK، ويُستخرج بأداة مجانية في دقيقة. النتيجة المعتادة:
استنزاف حصّتك أو فاتورة ليست لك. الحل الصحيح: نقل النداء إلى Cloud Function
تحمل المفتاح على الخادم. الحلّ المؤقّت: تقييد المفتاح بالحزمة وتوقيع SHA-1
في Google Cloud Console — **بعد** تثبيت معرّف الحزمة النهائي (البند 1).

### 13. روابط App Store وهمية

```
web/articles.html:1152, 1303
scripts/build_web_articles_portal.py:1177, 1328
  https://apps.apple.com/app/nabda
```

الادّعاء بتوفّر التطبيق على App Store قبل نشره سبب رفض متكرر، وهو أيضاً
غير صحيح. احذف الشارة أو استبدلها بـ«قريباً».

### 14. لا تصغير ولا تعتيم للكود

`build.gradle.kts` بلا `isMinifyEnabled`، ولا ملف `proguard-rules.pro`.
النتيجة: حزمة أكبر، وكود Dart/Java قابل للقراءة بعد فكّ الـAPK.

### 15. حقوق محتوى «موقع الملكة»

مسألة مفتوحة منذ جلسات سابقة ولم تُحسم. آلاف المقالات المستخرجة من موقع
خارجي داخل تطبيق تجاري = خطر بلاغ DMCA بعد النشر لا قبله. قرارٌ يخصّك،
لكنه يجب أن يُتَّخذ قبل الرفع لا بعده.

### 16. الاتجاه الأفقي مفعَّل على iPhone

`Info.plist:56-61` يسمح بـLandscapeLeft/Right بينما الواجهة مصمَّمة عمودياً.
المراجعة تفتح التطبيق وتُديره — وتخطيط مكسور سبب رفض شائع.

---

## 🟡 تحسينات

17. `ITSAppUsesNonExemptEncryption` غير معرَّف في `Info.plist` — سيُسأل عنه
    في كل رفع. أضف `<false/>` إن كنت تستعمل HTTPS فقط.
18. `nabda-import/node_modules` داخل المستودع — آلاف الملفات لا علاقة لها
    بالتطبيق. أضفه إلى `.gitignore`.
19. ملفات `android/hs_err_pid*.log` و`replay_pid*.log` (13 ملفاً) — مخلّفات
    انهيار JVM، احذفها.
20. `version: 1.0.0+1` في `pubspec.yaml` — تأكّد من رفع `+1` مع كل رفع
    جديد، فـPlay يرفض إعادة استعمال نفس `versionCode`.

---

## ⚪ ما لم أستطع فحصه — وأقولها صراحةً

الثلاثة التالية **لم تُنفَّذ**، لأن بيئة Linux المعزولة لدي نفد قرصها أثناء
الفحص، ولأن Flutter غير مثبّت فيها أصلاً:

- `flutter analyze` — أخطاء وتحذيرات التحليل الثابت
- `flutter test` — حالة الاختبارات
- قياس حجم الـAAB النهائي

شغّلها بنفسك وأرسل لي المخرجات، أو اعتبر هذا القسم فجوة معروفة في التقرير.
لن أدّعي أنها سليمة لأنني لم أرها.

---

## ترتيب التنفيذ المقترح

**اليوم — يفتح الطريق للرفع أصلاً**
1. معرّف الحزمة `com.nabda.app` في المنصّتين + Firebase (البنود 1، 7)
2. keystore وتوقيع الإصدار (2)
3. `USE_EXACT_ALARM` → `inexactAllowWhileIdle` (3)
4. أوصاف الصلاحيات + `PrivacyInfo.xcprivacy` + `GoogleService-Info.plist` (4، 5، 6)

**هذا الأسبوع — يمنع الرفض في المراجعة**
5. `web/privacy.html` + `web/terms.html` منشورتان (8)
6. Cloud Function تحذف البيانات فعلياً (9)
7. إصلاح `delete-account.html` (10)
8. زر الإبلاغ عن المنشورات (11)
9. حذف روابط آبل الوهمية (13)

**قبل الإطلاق**
10. تأمين مفتاح Gemini (12)
11. تفعيل minify + ProGuard (14)
12. حسم مسألة حقوق المحتوى (15)
13. قصر الاتجاه على العمودي (16)

---

*أُعِدّ هذا التقرير بقراءة الكود والإعدادات مباشرة. كل بند يحمل مسار الملف
ورقم السطر ليُتحقَّق منه، لا يُصدَّق.*
