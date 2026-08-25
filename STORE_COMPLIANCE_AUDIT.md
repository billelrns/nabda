# تدقيق الامتثال — نبضة على Google Play و Apple App Store

> تاريخ التدقيق: 19 أغسطس 2026
> النتيجة الإجمالية: **4 مشاكل حرجة** + **5 عالية الخطورة** + **6 متوسطة** + **4 تحسينات**
> الخطر: **رفض شبه مؤكّد** لو رُفع الآن قبل الإصلاح

---

## 🚨 المستوى 1 — حرج (رفض مؤكّد إذا لم يُصلح)

### ❌ 1. لا توجد خاصية «حذف الحساب» داخل التطبيق

**السياسة:** [Google Play Data safety — Account Deletion Requirements](https://support.google.com/googleplay/android-developer/answer/13327111)
منذ **مايو 2024**، Google تفرض على كل تطبيق يسمح بإنشاء حسابات أن يوفّر خاصية حذف الحساب **داخل التطبيق نفسه** + **رابط ويب** للحذف بدون تنزيل التطبيق.

**الوضع الحالي:** بحثت في كل الكود، **لا توجد أي دالة `deleteAccount()` أو `user.delete()`**. المستخدمة لا تستطيع حذف حسابها.

**الأثر:** رفض مباشر عند الرفع.

**الحلّ:**
- أضيفي زر «حذف حسابي» في `profile_screen.dart` → يستدعي:
  ```dart
  await FirebaseAuth.instance.currentUser?.delete();
  await FirebaseFirestore.instance.collection('users').doc(uid).delete();
  ```
- أنشئي صفحة على nabda.online/delete-account مع نموذج بسيط: البريد + تأكيد → طلب يذهب لبريدك الإداري

---

### ❌ 2. لا يوجد نظام إبلاغ عن المنشورات (Post-level Reporting)

**السياسة:**
- [Google Play — User Generated Content Policy](https://support.google.com/googleplay/android-developer/answer/9878809)
- [Apple App Store Review — 1.2 User-Generated Content](https://developer.apple.com/app-store/review/guidelines/#user-generated-content)

كل تطبيق يعرض محتوى من المستخدمين يجب أن يوفّر:
- ✅ إبلاغ عن مستخدم (موجود في `user_profile_screen.dart:563`)
- ❌ **إبلاغ عن منشور محدّد (مفقود!)**
- ❌ حظر منشور معيّن (مفقود)
- ❌ تعليقات مسيئة → إبلاغ

**الوضع الحالي:** `post_detail_screen.dart` لا يحوي دالة `report` أو زر «إبلاغ».

**الأثر:** رفض من Apple مؤكّد (صارمة جداً في UGC). Google قد يمرّرها بتحذير.

**الحلّ:** أضيفي في `post_detail_screen.dart`:
```dart
// زر إبلاغ في PopupMenuButton لكل منشور
PopupMenuItem(
  child: Text('إبلاغ عن هذا المنشور'),
  onTap: () async {
    await FirebaseFirestore.instance.collection('reports').add({
      'type': 'post',
      'postId': post.id,
      'reportedBy': FirebaseAuth.instance.currentUser!.uid,
      'reason': 'محتوى مسيء',
      'createdAt': FieldValue.serverTimestamp(),
    });
  },
),
```

---

### ❌ 3. iOS Info.plist يفتقر لكل «Usage Descriptions»

**السياسة:** [Apple — Requesting Access to Protected Resources](https://developer.apple.com/documentation/uikit/protecting_the_user_s_privacy)

كل إذن على iOS يحتاج نصّاً يشرح **لماذا** يحتاجه التطبيق. بدون النصّ = رفض فوري + توقّف تنفيذي (app crashes on iOS 14+).

**الوضع الحالي:** `ios/Runner/Info.plist` فيه **صفر usage descriptions** رغم أن التطبيق يستعمل:
- ImagePicker (يحتاج NSPhotoLibraryUsageDescription + NSCameraUsageDescription)
- Geolocator في `doctors_list_screen.dart` (يحتاج NSLocationWhenInUseUsageDescription)
- Notifications (يحتاج NSUserNotificationUsageDescription على iOS 13+)

**الأثر:** التطبيق يُرفض قبل حتى ما يُختبر + سيقع crash على أول محاولة استخدام كاميرا/موقع.

**الحلّ:** أضيفي في `ios/Runner/Info.plist` قبل `</dict>` الأخير:

```xml
<key>NSCameraUsageDescription</key>
<string>يحتاج نبضة الوصول للكاميرا لالتقاط صور طفلك وحملك وحفظها في يومياتك.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>يحتاج نبضة الوصول لصورك لاختيار صورة بروفايل ومشاركة صور طفلك في اليوميات.</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>لحفظ صور تقدّم حملك في مكتبتك.</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>يستعمل نبضة موقعك (فقط عند الطلب) للبحث عن أقرب طبيبة نساء ومستشفى ولادة.</string>

<key>NSUserNotificationUsageDescription</key>
<string>لتذكيرك بأدويتك وفحوصاتك ونصائح الحمل اليومية.</string>

<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
</dict>
```

---

### ❌ 4. اسم التطبيق غير متّسق

**الوضع الحالي:**
- `AndroidManifest.xml:14`: `android:label="nabda"` (حرف صغير)
- `ios/Runner/Info.plist:10`: `CFBundleDisplayName = "Nabda"` (كبير)

**الأثر:** ليس رفضاً مباشراً، لكن Apple تُلاحظ الاختلاف وتطلب توحيداً في مراجعة الجودة.

**الحلّ:** غيّري Android إلى:
```xml
android:label="Nabda"
```
أو الأفضل — استعملي الاسم العربي:
```xml
android:label="نبضة"
```

---

## ⚠️ المستوى 2 — عالي الخطورة (احتمال رفض قوي)

### 5. مفتاح Gemini API مكشوف في الكود

**السياسة:** [Google Play — App Security Requirements](https://support.google.com/googleplay/android-developer/answer/9888379) — يحظر تسريب مفاتيح API التي تسمح باستهلاك موارد مدفوعة.

**الوضع الحالي:**
```dart
// lib/main.dart:8835
final String _apiKey = 'AIzaSyB09gZH8igVPtC0yfPA5Twfp3KU0dC-kTI';
```

المفتاح مطبوع مباشرةً في التطبيق. أي شخص يفكّ تشفير الـAPK يستخرجه ويستنزفك في ساعات.

**الأثر:**
- Google قد تُنبّهك (لن ترفض التطبيق فوراً)
- **الضرر الحقيقي:** فاتورة Gemini API قد تصل لآلاف الدولارات في أسبوع

**الحلّ (اختاري 1):**

**أ. Firebase Remote Config (الأسهل):**
```dart
final apiKey = FirebaseRemoteConfig.instance.getString('gemini_api_key');
```
وضعي المفتاح في Firebase Console → Remote Config.

**ب. Cloud Function وسيطة (الأصحّ):**
اجعلي مفتاح Gemini على Cloud Function، والتطبيق يستدعي الـFunction بدل Gemini مباشرة. Cloud Function تفرض حدود استعمال (rate limiting).

---

### 6. لا يوجد تحذير AI في مساعد الذكاء الاصطناعي

**السياسة:** [Apple — 5.1.1 Data Collection and Storage](https://developer.apple.com/app-store/review/guidelines/#privacy) + [Google Play — Generative AI Policy](https://support.google.com/googleplay/android-developer/answer/13985936)

منذ 2024، كلا المتجرين يفرضان أن **أي تطبيق يقدّم إجابات صحّية بـAI** يجب أن يعرض تحذيراً واضحاً:
- «هذه إجابة من ذكاء اصطناعي، قد تكون غير دقيقة»
- «لا تعتمدي عليها في حالات الطوارئ»
- زر «Flag inappropriate response» واضح

**الوضع الحالي:** لم أجد تحذيراً في `ai_service.dart` أو شاشة المحادثة.

**الحلّ:**
1. في أعلى شاشة المحادثة AI، بانر ثابت:
   > ⚠️ إجابات مساعد نبضة الذكي إرشادية فقط. للحالات الطبية، استشيري طبيبتك.
2. زر Flag على كل إجابة → يحفظ في `ai_flagged_responses` للمراجعة

---

### 7. Data Safety Form — يجب التصريح بجمع البيانات الصحّية

**السياسة:** [Google Play — Data Safety Section](https://support.google.com/googleplay/android-developer/answer/10787469)

**الوضع الحالي:** أنتِ تجمعين بيانات صحّية شديدة الحسّاسية:
- تاريخ الحمل (`pregnancyStartDate`)
- الدورة الشهرية (`lastPeriodStart`, `cycleLength`)
- بيانات الطفل (`babyName`, `babyBirthDate`)
- الأدوية والفحوصات
- الوزن والقياسات

**عند ملء Data Safety Form في Play Console، صرّحي بها كلها كـ:**
- Data type: **Health and fitness**
- Purpose: App functionality + Analytics
- Optional: **Yes** (أعطي المستخدمة خيار عدم إدخالها)
- Shared with third parties: **No**
- Encrypted in transit: **Yes** (Firebase)
- Can request deletion: **Yes** (بعد إصلاح #1)

**الأثر بدون تصريح:** رفض تلقائي من Google.

---

### 8. Google Sign-In: SHA-1 & SHA-256 غير مضافين

**الوضع الحالي:** `auth_service.dart` يدعم `signInWithGoogle()` و`signInWithFacebook()` و`signInWithApple()`.

للعمل على Android، يجب إضافة **SHA-1 و SHA-256 fingerprints** في Firebase Console → Project Settings → Android app → SHA certificate fingerprints.

**تنبيه:** كل مفتاح توقيع له SHA مختلف:
- **Debug** (المفتاح المؤقّت لأثناء التطوير)
- **Release** (المفتاح الذي أنشأتِه لـPlay Store)
- **Play App Signing** (المفتاح الذي يعطيكِ Google بعد الرفع)

**الحصول على SHA:**
```cmd
cd C:\nabda_app\android
gradlew signingReport
```

انسخي SHA-1 و SHA-256 لكل نوع، أضيفيها في Firebase Console.

**الأثر:** بدونها، زرّ Google/Facebook لن يعمل على Play Store version.

---

### 9. صفحة الأطبّاء — لا تفصل «الأطبّاء الشركاء» عن «الأطبّاء العامّون»

**السياسة:** Apple ترفض التطبيقات التي تعرض «قوائم أطبّاء» بلا توضيح إذا كانوا:
- شركاء (advertising)
- أم مفهرسون تلقائياً

**الوضع الحالي:** `doctors_list_screen.dart` يعرض قائمة أطبّاء. لم أرَ تفصيلاً واضحاً.

**الحلّ:** أضيفي على كل بطاقة طبيب علامة واضحة:
- 🏥 «طبيبة شريكة» (إذا كانت شراكة تسويقية)
- 📋 «من قاعدة بياناتنا العامّة» (إذا مسحتِ من المصادر العامّة)

---

## 📋 المستوى 3 — متوسط الخطورة (يجب الإصلاح قبل الإطلاق)

### 10. `community_engagement_service` ينشر تلقائياً باسم «نبضة الرسمي»

**السياسة:** [Google Play — Fake Engagement](https://support.google.com/googleplay/android-developer/answer/9909218) — يحظر «التفاعل الاصطناعي المزيّف».

**الوضع الحالي:** حساب «نبضة الرسمي» ينشر تلقائياً «سؤال اليوم» + «نصائح صحية». **هذا مقبول قانونياً** لأنّه حساب رسمي معلن، وليس يُقلّد مستخدماً حقيقياً.

**التوصية:** أضيفي شارة ✅ «حساب رسمي» ظاهرة بجانب اسم «نبضة الرسمي» في كل منشور (موجود جزئياً)، وأضيفي في `About` الشرح: «هذا حساب رسمي لفريق نبضة يشارك سؤال اليوم والنصائح الصحّيّة».

### 11. الإعلانات — kAdmobReady=false لكن NabdaAds يعمل

`news_section.dart:511` يقول `kAdmobReady=false` (لم تُفعّلي Google AdMob بعد).
لكن `NabdaAds` (إعلاناتك الخاصّة) يعمل ويعرض منتجات من متجرك.

**التوصية:**
- لا تكتبي «إعلان» أو «Ad» على الإعلانات الخاصّة (لأنها منتجاتك، ليست إعلانات مدفوعة من أطراف ثالثة). اكتبي «منتج مقترح» بدلاً.
- عند تفعيل AdMob، اكتبي «إعلان» بوضوح فوق كل بانر (سياسة Google صريحة).

### 12. رقم الدعم الافتراضي `213555000000` وهمي

`auth_service.dart:defaultSupportWhatsApp = '213555000000'` — رقم غير حقيقي.

إذا نُشِر التطبيق ولم تُحدِّثي `app_config/contact.whatsappNumber` في Firestore، المستخدمة ستحاول واتساب رقم مزيّف → تجربة سيئة.

**الحلّ:** بعد إعداد لوحة الأدمن، افتحيها فوراً وحدّثي الرقم لرقم واتساب حقيقي.

### 13. بيانات الأطفال — تحتاج تنبيهاً واضحاً

**السياسة:** [Apple 5.1.4 Kids Category](https://developer.apple.com/app-store/review/guidelines/#kids-category)

التطبيق يجمع بيانات الطفل (اسم، تاريخ ميلاد، لقاحات). هذا مسموح لأنّه بموافقة الأم (وليّة أمر).

**التوصية:** في `privacy_policy.md` (الموجودة عندك)، أضيفي فقرة صريحة:
> «بيانات الطفل المسجّلة (الاسم، تاريخ الميلاد، اللقاحات، النموّ) تُعامَل كبيانات الأم — أنتِ المسؤولة عنها وتستطيعين حذفها في أي وقت.»

### 14. مساعد الذكاء الاصطناعي بلا موافقة صريحة

عند أول مرّة تفتح المستخدمة شاشة AI، يجب أن تظهر modal تُطلب موافقتها:
> «هذا مساعد ذكي مُدعوم بـ Google Gemini. أسئلتك تُرسَل لخوادم Google لمعالجتها. هل توافقين على المتابعة؟»

**الأثر بدون هذا:** Apple ترفض تحت 5.1.1(iv) — Access to personal data without consent.

### 15. تحديث pubspec.yaml للاسم الصحيح

الوضع الحالي:
```yaml
name: nabda_app
description: "A new Flutter project."
```

- الاسم `nabda_app` مقبول (technical).
- الوصف **افتراضي من Flutter** — سيبدو غير احترافي في Play Console.

**الحلّ:**
```yaml
name: nabda_app
description: "نبضة — تطبيق صحة المرأة العربية: متابعة الحمل والدورة ورعاية الطفل"
```

---

## 💡 المستوى 4 — تحسينات (بعد الإطلاق)

### 16. `.gitignore` ينقصه ملفات الأمان
تحقّقي أنّه يستثني:
```
android/nabda-release-key.jks
android/key.properties
android/app/google-services.json
ios/GoogleService-Info.plist
```

### 17. Firebase Crashlytics غير مُفعّل
لتتبّع الأخطاء الحقيقية بعد الإطلاق. أضيفي:
```yaml
firebase_crashlytics: ^4.1.0
```

### 18. لا يوجد نسخة web-signup لحذف الحساب
Play Store يطلب رابط ويب مباشر لحذف الحساب (للمستخدمات اللواتي حذفن التطبيق أصلاً).

### 19. لغات app_localizations
`pubspec.yaml` يُصرّح بدعم ar/en/fr لكن معظم UI بالعربية فقط. عند الرفع، صرّحي بلغات مدعومة فعلياً حتى لا يُعرض التطبيق لأسواق لا يخدمها.

---

## ✅ ما هو نظيف ومطابق للسياسات

- ✅ تنبيه طبي في كل مقال متخصّص («محتوى إرشادي لا يغني عن استشارة الطبيب»)
- ✅ مصادر طبية موثّقة (WHO, ACOG, NHS…) بعد إصلاحاتنا الأخيرة
- ✅ نظام حظر مستخدمين (`user_profile_screen.dart`)
- ✅ Firestore rules محكمة (بيانات صحّية معزولة، الأدمن لا يرى `/users/{uid}`)
- ✅ الدفع بـCOD للمنتجات المادية (لا يحتاج Google Play Billing)
- ✅ لا يوجد ادّعاءات علاجية («يعالج»، «يشفي» غير موجودة)
- ✅ لا محتوى إباحي أو عنيف
- ✅ لا مقامرة، لا كحول، لا مخدّرات
- ✅ لا سرقة حقوق نشر (كلّ المحتوى أصلي أو من مصادر مشروعة)
- ✅ تصنيف عمري صريح (18+ في `PRIVACY_POLICY.md`)
- ✅ Privacy Policy جاهزة (`PRIVACY_POLICY.md`)

---

## 🎯 قائمة الإصلاح المرتّبة (Priority Queue)

### يجب قبل الرفع (أسبوع)

1. **[1 يوم]** إضافة زر «حذف الحساب» في التطبيق + صفحة web
2. **[نصف يوم]** إضافة إبلاغ عن منشور في `post_detail_screen.dart`
3. **[10 دقائق]** إضافة usage descriptions في `Info.plist`
4. **[5 دقائق]** توحيد اسم التطبيق (nabda → Nabda أو نبضة)
5. **[2 ساعات]** نقل مفتاح Gemini إلى Firebase Remote Config
6. **[1 ساعة]** إضافة بانر تحذير AI + زر flag + modal موافقة أول مرة
7. **[30 دقيقة]** حصول على SHA-1/SHA-256 وإضافتها في Firebase

### قبل الرفع مباشرةً (اليوم نفسه)

8. تحديث `pubspec.yaml` بالوصف الصحيح
9. تحديث رقم WhatsApp من Firestore (رقم حقيقي)
10. مراجعة `.gitignore` لملفات الأمان
11. ملء Data Safety Form بدقّة في Play Console

### بعد الرفع (خلال شهر)

12. إضافة Firebase Crashlytics
13. تحسين تسمية الإعلانات
14. مراجعة بيانات الأطفال في Privacy Policy
15. إضافة نسخة ويب لحذف الحساب

---

## 📊 التقييم النهائي

| الفئة | العدد | التأثير |
|---|---|---|
| 🚨 حرج | 4 | رفض مؤكّد |
| ⚠️ عالي | 5 | رفض محتمل |
| 📋 متوسط | 6 | تحذير + مراجعة إضافية |
| 💡 تحسين | 4 | لا يوقف النشر |

**التوصية:** لا ترفعي التطبيق قبل إصلاح المستويَين 1 و2. الإصلاح كلّه يحتاج **3-5 أيام عمل مركّز**.

---

## 🔗 مراجع رسمية

- [Google Play Developer Policy Center](https://play.google.com/about/developer-content-policy/)
- [Apple App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Google Play — Health Apps Policy](https://support.google.com/googleplay/android-developer/answer/9888379)
- [Apple — Health & Medical Apps](https://developer.apple.com/health-fitness/)
- [Google Play — Account Deletion Requirements](https://support.google.com/googleplay/android-developer/answer/13327111)
- [Apple — Sign in with Apple Requirement](https://developer.apple.com/sign-in-with-apple/) (إجباري إن كنتِ تستعملين Google/Facebook Sign-In)

---

*هذا التدقيق شامل لكنّه لا يغني عن مراجعة قانونية مختصّة للمواضيع الحسّاسة. للتطبيقات الصحّية في السوق الأوروبي، استشيري محامياً متخصّصاً في GDPR.*
