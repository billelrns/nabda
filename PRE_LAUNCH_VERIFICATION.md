# تحقّق مستقلّ من تنفيذ إصلاحات ما قبل النشر

19 سبتمبر 2026 · فحص الكود مباشرة، لا الاعتماد على تقرير التنفيذ

---

## النتيجة

**11 مهمّة من 14 منفَّذة بالكامل ومُتحقَّق منها.** مهمّتان ناقصتان، وعنصر
واحد من المهمّة الأولى لم يُنفَّذ ولم يُذكر في تقرير التنفيذ.

التنفيذ جيّد فعلاً — الترتيب الحرج في الحذف المتتالي صحيح، وقصر الاتجاه
على العمودي طُبِّق على iPhone وحده دون المساس بالآيباد، وزرّ الإبلاغ وُصِل
في ثلاثة مواضع لا موضع واحد. هذه تفاصيل لا تُصيبها إلا بقراءة البريف بعناية.

---

## ✅ مُتحقَّق منه في الكود

| # | المهمة | الدليل الذي فحصتُه |
|---|---|---|
| 1 | معرّف الحزمة | `build.gradle.kts:18,33` = `com.nabda.app` · `MainActivity.kt` في `kotlin/com/nabda/app/` · **صفر نتيجة** لـ`com.example` في كل الكود |
| 3 | بنية التوقيع | `signingConfigs` تقرأ `key.properties` · `isMinifyEnabled = false` محفوظ كما طُلب |
| 4 | `USE_EXACT_ALARM` | الصلاحيتان محذوفتان · الأوضاع الثلاثة `inexactAllowWhileIdle` (`main.dart:1186,1333,1346`) |
| 5 | أوصاف iOS | الأربعة موجودة (`Info.plist:56-63`) + `ITSAppUsesNonExemptEncryption` + **iPhone عمودي فقط والآيباد لم يُمسّ** |
| 6 | `PrivacyInfo.xcprivacy` | الملف موجود في `ios/Runner/` |
| 7 | الحذف المتتالي | `firestore.rules:45` و`:106` يسمحان بالحذف · `auth_service.dart:128-158` بالترتيب الصحيح: دفعات ← `users_directory` ← `users` ← `user.delete()` |
| 8 | الإبلاغ | `report_service.dart` + بطاقة المنشور (`main.dart:8827`) + تفاصيل المنشور (`post_detail_screen.dart:299`) + **التعليقات** (`:744`) + شاشة الأدمن (`admin_panel_screen.dart:5964`) |
| 9 | صفحات الويب | `web/privacy.html` و`web/terms.html` موجودتان ومربوطتان في `landing.html` و`articles.html` |
| 10 | صفحة الحذف | `action="https://formspree.io/f/mqaejvyw" method="POST"` · `privacy@nabda.online` |
| 11 | التنظيف | **صفر نتيجة** لـ`apps.apple.com` في `web/*.html` · سجلّات JVM محذوفة |
| 12 | امتثال الذكاء الاصطناعي | موافقة `ai_consent_v1` (`main.dart:9285,9325`) + بانر تحذير (`:9535`) + زر إبلاغ عن الإجابة (`:9654`) |
| 14 | Crashlytics | `pubspec.yaml:36` + الاستيراد في `main.dart:9` |

---

## ❌ ناقص

### 1. `firebase_options.dart` — أُصلح أندرويد فقط

```dart
// السطر 22-28 — أندرويد ✅ صحيح الآن
appId: '1:911912460091:android:aa9f2ec93356eb285b611e',
apiKey: 'AIzaSyC94O8MF5vBzJKpZkvlvg-9pVS2i63a1EA',

// السطر 29-36 — iOS ❌ ما زال على بيانات الويب
appId : '1:911912460091:web:d93a70d03a5a957a5b611e',   // يجب :ios:
apiKey: 'AIzaSyDyFmGvaOMAzb2XXOFR_RO_lSn7UYyBd6M',     // مفتاح الويب
```

تقرير التنفيذ ذكر «تصحيح معرّف تطبيق أندرويد» ولم يذكر iOS إطلاقاً — وهو
وصف دقيق لما حدث فعلاً.

**الإصلاح**: في Firebase Console → إضافة تطبيق iOS بمعرّف `com.nabda.app`،
ثم `flutterfire configure --project=nabda-app-ca864` لإعادة توليد الملف كاملاً.

### 2. `ios/Runner/GoogleService-Info.plist` — غير موجود

كان ضمن المهمة 1 في البريف، ولم يُذكر في تقرير التنفيذ ولا وُجد في المجلّد.
بدونه Firebase على iOS لن يعمل بشكل صحيح (المصادقة والإشعارات خاصة).
يُنزَّل من نفس خطوة إضافة تطبيق iOS أعلاه، ويُضاف إلى هدف Runner في Xcode
(Build Phases → Copy Bundle Resources) — وجوده في المجلّد وحده لا يكفي.

---

## ⚠️ فخّ صامت في إعداد التوقيع

```kotlin
// build.gradle.kts:51-55
signingConfig = if (keystorePropertiesFile.exists()) {
    signingConfigs.getByName("release")
} else {
    signingConfigs.getByName("debug")     // ← هنا الخطر
}
```

الـkeystore لم يُولَّد بعد — الموجود `key.properties.example` فقط. مع هذا
الشرط، أمر `flutter build appbundle --release` **سينجح** ويُخرج حزمة موقَّعة
بمفتاح التصحيح، ويُرفض عند الرفع إلى Play.

الشرط كُتب بنيّة حسنة (ألّا ينكسر البناء على أجهزة لا تملك المفتاح)، لكنه
يحوّل فشلاً صاخباً إلى مخالفة صامتة تُكتشف عند الرفع.

**الأفضل**: اجعل الإصدار يفشل صراحةً:
```kotlin
release {
    if (!keystorePropertiesFile.exists()) {
        throw GradleException("key.properties مفقود — نسخة الإصدار تحتاج مفتاح التوقيع")
    }
    signingConfig = signingConfigs.getByName("release")
    isMinifyEnabled = false
    isShrinkResources = false
}
```

---

## ما يبقى عليك أنت

1. **توليد الـkeystore** ونسخه إلى مكانين خارج المشروع:
   ```
   keytool -genkey -v -keystore C:\keys\nabda-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias nabda
   ```
   ثم `android/key.properties` من القالب الموجود.
2. **إضافة تطبيق iOS في Firebase** → يحلّ البندين الناقصين معاً.
3. **بصمة SHA للإصدار** بعد توليد المفتاح (`gradlew signingReport`)، وبصمة
   **Play App Signing** بعد أول رفع — وإلّا تعطّل الدخول بـGoogle عند
   المستخدمات بينما يعمل عندك.
4. **تأكيد أن `formspree.io/f/mqaejvyw` نموذجك أنت** وأن `privacy@nabda.online`
   صندوق بريد حقيقي — أرسل طلب حذف تجريبياً وتأكّد من وصوله.
5. **بناء إصدار حقيقي** (`flutter build appbundle --release`) — كل ما بُني
   حتى الآن هو `--debug`، فمسار الإصدار لم يُختبر بعد.
6. **`flutter analyze` و`flutter test`** — لم تظهر مخرجاتهما في تقرير التنفيذ.

---

## الاختبار اليدوي — لم يُنفَّذ بعد

الخطوات الخمس في آخر البريف ما زالت مطلوبة، وأهمّها:

> تسجيل حساب جديد ← إدخال بيانات دورة وحمل وطفل ومنشور ← حذف الحساب ←
> **فتح وحدة تحكّم Firestore والتأكّد بالعين أن `/users/{uid}` ومجموعاتها
> الفرعية و`/users_directory/{uid}` اختفت فعلاً.**

وجود الكود الصحيح ليس دليلاً على أن الحذف نجح. القاعدة المنشورة قد ترفض،
أو قد تسبق مهلة الشبكة اكتمال الدفعات. هذه الخطوة تحديداً هي الفرق بين
«أُصلح» و«يعمل».
