# خطة تنفيذ إصلاحات الامتثال — Antigravity Brief

> **موجّه إلى:** Antigravity / Cursor / أي AI coding agent
> **المشروع:** `C:\nabda_app` — Flutter app (نبضة — صحة المرأة العربية)
> **الهدف:** إصلاح 9 مخالفات لسياسات Google Play و Apple App Store قبل النشر
> **المدة المتوقّعة:** 90-120 دقيقة عمل مركّز
> **المخرجات:** 9 commits منفصلة، كل commit يعالج مشكلة واحدة

---

## 📐 قواعد التنفيذ

**قبل البدء:**
1. اقرأ `STORE_COMPLIANCE_AUDIT.md` في الجذر لفهم السياق
2. اقرأ `brand.md` للنبرة العربية المعتمدة
3. اقرأ `NABDA_PROJECT_HISTORY.md` لفهم بنية المشروع

**أثناء التنفيذ:**
- **لا تعدّل ملف `admin_panel_screen.dart` عبر أدوات Edit العادية** — الملف كبير (5617 سطر) وقابل للاقتطاع. استعمل Python scripts (اقرأ للملف كاملاً في /tmp، عدّل، ثم انسخ).
- **العربية RTL:** كل نصّ جديد بالعربية الفصحى + نبرة مؤنّثة (`اشربي`، `طبيبتك`) حسب `brand.md`
- **بعد كل تعديل:** شغّل `flutter analyze` — يجب صفر errors (warnings/infos مقبولة)
- **بعد كل مرحلة:** commit منفصل برسالة عربية واضحة (نموذج في نهاية كل مرحلة)

**اختبار محلي مطلوب بعد كل مرحلة:**
```cmd
flutter analyze
flutter build apk --debug
```

---

## المرحلة 1 — «حذف الحساب» داخل التطبيق (أولوية قصوى)

### المشكلة
Google Play يفرض منذ مايو 2024 أن كل تطبيق يسمح بإنشاء حسابات يوفّر خاصية حذف الحساب داخل التطبيق. حالياً `deleteAccount()` غير موجودة.

### الملفات المتأثّرة
- `lib/services/auth_service.dart` (إضافة دالة)
- `lib/screens/profile/profile_screen.dart` (إضافة زر)
- `firestore.rules` (السماح للمستخدمة بحذف وثيقتها + subcollections)

### التنفيذ المطلوب

**1.1 في `lib/services/auth_service.dart`** — أضف قبل السطر الأخير `}`:

```dart
  /// حذف الحساب نهائياً: يمسح كل بيانات المستخدمة من Firestore + Auth
  /// يتطلّب إعادة مصادقة حديثة (Firebase security requirement).
  ///
  /// [recentPassword] كلمة المرور الحالية لإعادة المصادقة (للحسابات ببريد)
  /// [socialProvider] موفّر الدخول الاجتماعي إن وُجد (google/facebook/apple)
  ///
  /// يرجع true عند النجاح، ويرمي Exception عند الفشل.
  Future<bool> deleteAccount({String? recentPassword, String? socialProvider}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('يجب تسجيل الدخول أولاً');
    final uid = user.uid;

    try {
      // 1. إعادة مصادقة (Firebase يشترطها لعمليات حسّاسة)
      if (recentPassword != null && user.email != null) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: recentPassword,
        );
        await user.reauthenticateWithCredential(credential);
      } else if (socialProvider != null) {
        AuthProvider? provider;
        if (socialProvider == 'google') provider = GoogleAuthProvider();
        else if (socialProvider == 'facebook') provider = FacebookAuthProvider();
        else if (socialProvider == 'apple') {
          provider = OAuthProvider('apple.com')..addScope('email');
        }
        if (provider != null) {
          if (kIsWeb) {
            await user.reauthenticateWithPopup(provider);
          } else {
            await user.reauthenticateWithProvider(provider);
          }
        }
      }

      // 2. حذف subcollections (babies, baby_logs, cycle_logs, vaccines...)
      final subcollections = ['babies', 'baby_logs', 'cycle_logs', 'weight_tracker',
                              'vaccines', 'logs', 'orders', 'medications', 'blocked'];
      for (final sub in subcollections) {
        try {
          final docs = await _firestore.collection('users').doc(uid).collection(sub).get();
          for (final doc in docs.docs) {
            await doc.reference.delete();
          }
        } catch (_) {} // تخطّي subcollection إن لم توجد
      }

      // 3. حذف وثيقة المستخدمة الرئيسية
      await _firestore.collection('users').doc(uid).delete();

      // 4. حذف من users_directory (نسخة للأدمن)
      try {
        await _firestore.collection('users_directory').doc(uid).delete();
      } catch (_) {}

      // 5. أخيراً — حذف حساب Firebase Auth
      await user.delete();

      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception('لأمان حسابك، سجّلي الخروج ثم الدخول من جديد قبل الحذف');
      }
      throw Exception(_emailErrorAr(e.code));
    } catch (e) {
      throw Exception('فشل حذف الحساب: $e');
    }
  }
```

**1.2 في `lib/screens/profile/profile_screen.dart`** — أضف قبل نهاية الشاشة (في القسم السفلي أو ListTile قائم بذاته):

```dart
// ── حذف الحساب ──
Card(
  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  color: Colors.red.shade50,
  child: ListTile(
    leading: Icon(Icons.delete_forever, color: Colors.red.shade700),
    title: Text('حذف حسابي نهائياً', 
      style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold)),
    subtitle: Text('لا يمكن التراجع عن هذا الإجراء',
      style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
    onTap: () => _showDeleteAccountDialog(context),
  ),
),
```

وأضف الدالة داخل الـState:

```dart
Future<void> _showDeleteAccountDialog(BuildContext context) async {
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('⚠️ حذف الحساب نهائياً'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text(
            'هذا الإجراء سيحذف كل بياناتك (الحمل، الدورة، الأطفال، الطلبات) '
            'ولا يمكن استرجاعها. اكتبي «حذف» للتأكيد.',
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: confirmController,
            decoration: const InputDecoration(
              labelText: 'اكتبي «حذف» للتأكيد',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'كلمة المرور الحالية',
              border: OutlineInputBorder(),
            ),
          ),
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            if (confirmController.text.trim() != 'حذف') {
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('يجب كتابة كلمة «حذف» بالضبط')),
              );
              return;
            }
            if (passwordController.text.isEmpty) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('أدخلي كلمة المرور')),
              );
              return;
            }
            try {
              await AuthService().deleteAccount(recentPassword: passwordController.text);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                context.go('/login');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف حسابك بنجاح')),
                );
              }
            } catch (e) {
              final msg = e.toString().replaceFirst('Exception: ', '');
              if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text(msg), backgroundColor: Colors.red),
              );
            }
          },
          child: const Text('حذف نهائياً', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}
```

**1.3 في `firestore.rules`** — تحقّق أن قاعدة المستخدمة تسمح بالحذف من صاحبة الحساب:

```
match /users/{userId} {
  // ... القواعد الموجودة
  allow delete: if isAuthenticated() && isOwner(userId);  // ← تأكّد من وجود هذا
}
```

### معايير القبول
- ✅ `flutter analyze` = صفر errors
- ✅ زر «حذف حسابي نهائياً» يظهر في ProfileScreen
- ✅ الضغط عليه يفتح dialog يطلب كلمة «حذف» + كلمة المرور
- ✅ عند التأكيد: يمسح الوثيقة من Firestore + يمسح Auth account + يوجّه لـ /login

### Commit message
```
feat(gdpr): إضافة خاصية حذف الحساب داخل التطبيق (Google Play Requirement)

- AuthService.deleteAccount() يمسح subcollections + وثيقة المستخدمة + Auth
- زر حذف في ProfileScreen مع dialog تأكيد مزدوج (كلمة + كلمة مرور)
- تحديث firestore.rules للسماح للمستخدمة بحذف وثيقتها

Refs: Play Store Account Deletion Requirement (May 2024)
```

---

## المرحلة 2 — إبلاغ عن المنشورات

### المشكلة
`post_detail_screen.dart` يعرض منشورات المجتمع بدون خاصية إبلاغ عن منشور معيّن. Apple ترفض هذا 100%.

### الملفات المتأثّرة
- `lib/screens/community/post_detail_screen.dart`
- `firestore.rules` (إضافة قاعدة لمجموعة `post_reports`)

### التنفيذ المطلوب

**2.1 في `lib/screens/community/post_detail_screen.dart`** — أضف PopupMenuButton في AppBar (بجانب زر الرجوع):

```dart
actions: [
  PopupMenuButton<String>(
    icon: const Icon(Icons.more_vert),
    onSelected: (value) async {
      if (value == 'report') await _reportPost();
      else if (value == 'block_user') await _blockUser();
    },
    itemBuilder: (ctx) => [
      const PopupMenuItem(
        value: 'report',
        child: Row(children: [
          Icon(Icons.flag, color: Colors.orange),
          SizedBox(width: 8),
          Text('إبلاغ عن المنشور'),
        ]),
      ),
      const PopupMenuItem(
        value: 'block_user',
        child: Row(children: [
          Icon(Icons.block, color: Colors.red),
          SizedBox(width: 8),
          Text('حظر صاحبة المنشور'),
        ]),
      ),
    ],
  ),
],
```

وأضف داخل الـState:

```dart
Future<void> _reportPost() async {
  final reason = await showDialog<String>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: const Text('لماذا تُبلغين عن هذا المنشور؟'),
      children: [
        _reasonOption(ctx, 'محتوى مسيء أو غير لائق'),
        _reasonOption(ctx, 'معلومات طبية خاطئة أو خطيرة'),
        _reasonOption(ctx, 'إعلان أو سبام'),
        _reasonOption(ctx, 'محتوى مكرّر'),
        _reasonOption(ctx, 'انتهاك خصوصية شخص'),
        _reasonOption(ctx, 'سبب آخر'),
      ],
    ),
  );
  if (reason == null) return;
  
  try {
    await FirebaseFirestore.instance.collection('post_reports').add({
      'postId': widget.postId,
      'reportedBy': FirebaseAuth.instance.currentUser?.uid,
      'reason': reason,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('شكراً لكِ، تمّ استلام بلاغك وسنراجعه قريباً')),
    );
  } catch (e) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('خطأ: $e')),
    );
  }
}

Widget _reasonOption(BuildContext ctx, String text) => SimpleDialogOption(
  onPressed: () => Navigator.pop(ctx, text),
  child: Text(text),
);

Future<void> _blockUser() async {
  // نفس منطق user_profile_screen.dart الموجود
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;
  await FirebaseFirestore.instance.collection('users').doc(uid)
      .collection('blocked').doc(widget.authorId).set({
    'blockedAt': FieldValue.serverTimestamp(),
  });
  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('تمّ حظر هذه العضوة')),
  );
}
```

**2.2 في `firestore.rules`** — أضف بعد آخر match:

```
// ─── تقارير المنشورات ────────────────────────────────────
match /post_reports/{reportId} {
  allow create: if isAuthenticated() 
    && request.resource.data.reportedBy == request.auth.uid;
  allow read, update, delete: if isOwnerOrSupervisor();
}
```

### معايير القبول
- ✅ PopupMenu في AppBar لكل صفحة منشور
- ✅ خيارَي «إبلاغ» و «حظر صاحبة المنشور»
- ✅ 6 أسباب للإبلاغ عبر SimpleDialog
- ✅ التقرير يُحفظ في `post_reports` بـ postId + reason + status
- ✅ رسالة شكر بعد الإبلاغ

### Commit message
```
feat(moderation): إبلاغ عن منشور وحظر صاحبته (UGC Compliance)

- PopupMenu في AppBar بخياري إبلاغ وحظر
- 6 أسباب مفصّلة للإبلاغ (مسيء، طبي خاطئ، سبام، مكرّر، خصوصية، آخر)
- تخزين في post_reports مع قواعد Firestore محكمة

Refs: Apple UGC Guideline 1.2, Google Play UGC Policy
```

---

## المرحلة 3 — Info.plist Usage Descriptions (iOS)

### المشكلة
`ios/Runner/Info.plist` خالٍ من كل usage descriptions. التطبيق سيقع crash على iOS 14+.

### الملفات المتأثّرة
- `ios/Runner/Info.plist`

### التنفيذ المطلوب

قبل `</dict>` الأخيرة في `Info.plist`، أضف:

```xml
	<key>NSCameraUsageDescription</key>
	<string>يحتاج نبضة الوصول للكاميرا لالتقاط صور طفلك وحملك وحفظها في يومياتك الخاصّة.</string>
	
	<key>NSPhotoLibraryUsageDescription</key>
	<string>يحتاج نبضة الوصول لصورك لاختيار صورة بروفايل ومشاركة صور طفلك في يوميات الحمل.</string>
	
	<key>NSPhotoLibraryAddUsageDescription</key>
	<string>لحفظ صور تقدّم حملك ومشاركة الإنجازات على مكتبتك.</string>
	
	<key>NSLocationWhenInUseUsageDescription</key>
	<string>يستعمل نبضة موقعك (فقط عند طلبك) للبحث عن أقرب طبيبة نساء أو مستشفى ولادة.</string>
	
	<key>NSUserNotificationUsageDescription</key>
	<string>لتذكيرك بمواعيد أدويتك وفحوصاتك ونصائح الحمل الأسبوعية.</string>
	
	<key>NSAppTransportSecurity</key>
	<dict>
		<key>NSAllowsArbitraryLoads</key>
		<false/>
		<key>NSExceptionDomains</key>
		<dict>
			<key>images.unsplash.com</key>
			<dict>
				<key>NSIncludesSubdomains</key>
				<true/>
				<key>NSExceptionAllowsInsecureHTTPLoads</key>
				<false/>
			</dict>
		</dict>
	</dict>
	
	<key>ITSAppUsesNonExemptEncryption</key>
	<false/>
```

### معايير القبول
- ✅ 5 usage descriptions باللغة العربية
- ✅ NSAppTransportSecurity محدّد
- ✅ ITSAppUsesNonExemptEncryption=false (لا يستعمل تشفير خاص)

### Commit message
```
fix(ios): إضافة Usage Descriptions المطلوبة لسياسات Apple

- كاميرا، صور، موقع، إشعارات
- ATS محكم مع استثناء Unsplash للصور
- ITSAppUsesNonExemptEncryption=false (يتجنّب أسئلة التصدير في App Store Connect)
```

---

## المرحلة 4 — توحيد اسم التطبيق

### الملفات المتأثّرة
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`
- `pubspec.yaml`

### التنفيذ

**4.1** في `AndroidManifest.xml` سطر 14، غيّر:
```xml
android:label="nabda"
```
إلى:
```xml
android:label="نبضة"
```

**4.2** في `Info.plist`، تأكّد:
```xml
<key>CFBundleDisplayName</key>
<string>نبضة</string>
<key>CFBundleName</key>
<string>Nabda</string>
```

**4.3** في `pubspec.yaml`، حدّث الوصف:
```yaml
description: "نبضة — تطبيق صحة المرأة العربية: متابعة الحمل والدورة ورعاية الطفل"
```

### Commit message
```
chore: توحيد اسم التطبيق إلى «نبضة» عبر Android و iOS + وصف عربي
```

---

## المرحلة 5 — نقل مفتاح Gemini API إلى Firebase Remote Config

### المشكلة
مفتاح Gemini مطبوع نصّاً في `lib/main.dart:8835`. أي شخص يفكّ APK يستنزف الحساب.

### الملفات المتأثّرة
- `lib/main.dart` (السطر ~8835 — بحث `_apiKey`)
- `pubspec.yaml` (إضافة firebase_remote_config)
- Firebase Console (خارج الكود)

### التنفيذ

**5.1** في `pubspec.yaml`:
```yaml
firebase_remote_config: ^5.1.3
```
ثم `flutter pub get`.

**5.2** في `lib/main.dart` (`main()` قبل runApp):
```dart
await FirebaseRemoteConfig.instance.setConfigSettings(RemoteConfigSettings(
  fetchTimeout: const Duration(seconds: 10),
  minimumFetchInterval: const Duration(hours: 1),
));
await FirebaseRemoteConfig.instance.setDefaults({
  'gemini_api_key': '', // فارغ افتراضاً — يجب جلبه من Firebase
});
FirebaseRemoteConfig.instance.fetchAndActivate(); // غير حاجب
```

**5.3** استبدال المفتاح المطبوع:
```dart
// كان: final String _apiKey = 'AIzaSyB09gZH8igVPtC0yfPA5Twfp3KU0dC-kTI';
// صار:
String get _apiKey => FirebaseRemoteConfig.instance.getString('gemini_api_key');
```

**5.4** خطوات في Firebase Console (يدوية — لا تتم عبر Antigravity):
- افتح Firebase Console → Remote Config
- Add parameter: `gemini_api_key` = المفتاح الحقيقي
- Publish

**5.5** تنظيف Git — احذف المفتاح من التاريخ:
```
تنبيه: المفتاح مسرّب في git history بالفعل. يجب:
1. تعطيل المفتاح القديم في Google AI Studio
2. توليد مفتاح جديد
3. وضع الجديد في Firebase Remote Config
```

### معايير القبول
- ✅ لا يوجد نصّ `AIzaSy` في `lib/main.dart`
- ✅ Remote Config يجلب المفتاح عند بدء التطبيق
- ✅ إن فشل الجلب، مساعد AI يعرض «الخدمة غير متوفّرة مؤقّتاً»

### Commit message
```
security: نقل مفتاح Gemini API إلى Firebase Remote Config

- إزالة المفتاح المطبوع في main.dart (كان تسريباً أمنياً)
- Remote Config يجلب المفتاح ديناميكياً مع timeout 10 ثوان
- fallback رسالة «الخدمة غير متوفّرة» عند غياب المفتاح

⚠️ يجب: (1) تعطيل المفتاح القديم في aistudio.google.com
        (2) توليد مفتاح جديد ووضعه في Firebase Console → Remote Config
```

---

## المرحلة 6 — تحذير AI + Modal الموافقة

### الملفات المتأثّرة
- `lib/screens/ai_chat/ai_chat_screen.dart` (أو نظيرها)

### التنفيذ

**6.1** بانر ثابت أعلى المحادثة:

```dart
Container(
  padding: const EdgeInsets.all(12),
  color: Colors.orange.shade50,
  child: Row(children: [
    const Icon(Icons.info_outline, color: Colors.orange, size: 20),
    const SizedBox(width: 8),
    Expanded(child: Text(
      '⚠️ هذه إجابات ذكاء اصطناعي إرشادية فقط. للحالات الطبية، استشيري طبيبتك.',
      style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
    )),
  ]),
),
```

**6.2** Modal موافقة أوّل مرّة:

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) => _showFirstTimeConsent());
}

Future<void> _showFirstTimeConsent() async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool('ai_consent_given') == true) return;
  
  if (!mounted) return;
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('مساعد نبضة الذكي'),
      content: const SingleChildScrollView(
        child: Text(
          'هذا مساعد ذكي مُدعوم بـ Google Gemini.\n\n'
          '• أسئلتك تُرسَل لخوادم Google لمعالجتها.\n'
          '• لا تُخزَّن أسئلتك عندنا بشكل دائم.\n'
          '• الإجابات إرشادية وليست تشخيصاً طبياً.\n'
          '• للحالات الطارئة، توجّهي فوراً للطبيب.\n\n'
          'هل توافقين على استخدام المساعد؟',
          textAlign: TextAlign.right,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            Navigator.pop(context); // ارجعي للشاشة السابقة
          },
          child: const Text('رفض'),
        ),
        ElevatedButton(
          onPressed: () async {
            await prefs.setBool('ai_consent_given', true);
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('أوافق'),
        ),
      ],
    ),
  );
}
```

**6.3** زر flag على كل إجابة:

```dart
// بجانب كل رسالة من AI:
IconButton(
  icon: Icon(Icons.flag_outlined, size: 16, color: Colors.grey),
  tooltip: 'الإبلاغ عن هذه الإجابة',
  onPressed: () async {
    await FirebaseFirestore.instance.collection('ai_flagged_responses').add({
      'response': message.text,
      'reportedBy': FirebaseAuth.instance.currentUser?.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('شكراً، سنراجع الإجابة')),
    );
  },
),
```

### Commit message
```
feat(ai): تحذير + موافقة + إبلاغ عن إجابات المساعد الذكي

- بانر تحذير دائم أعلى المحادثة
- Modal موافقة أوّل استعمال مع خيار الرفض
- زر flag على كل إجابة → حفظ في ai_flagged_responses

Refs: Apple 5.1.1(iv) + Google Play Generative AI Policy 2024
```

---

## المرحلة 7 — SHA-1/SHA-256 في Firebase

### التنفيذ (نصف يدوي)

**7.1** استخراج SHA-1/SHA-256 debug:
```cmd
cd C:\nabda_app\android
gradlew signingReport
```

**7.2** استخراج SHA للـ Release keystore (بعد إنشائها):
```cmd
keytool -list -v -keystore C:\nabda_app\android\nabda-release-key.jks -alias nabda
```

**7.3** خطوات في Firebase Console:
- Firebase Console → Project Settings → Your apps → Android app
- SHA certificate fingerprints → Add fingerprint
- ألصقي SHA-1 (كل من debug و release)
- ألصقي SHA-256 (كل من debug و release)

**7.4** أعيدي تنزيل `google-services.json` وضعيها في `android/app/`

### Commit message
```
chore(firebase): تحديث google-services.json بعد إضافة SHA fingerprints

- SHA-1/SHA-256 لكل من debug و release
- ضروري لعمل Google Sign-In على APK المُوقّع
```

---

## المرحلة 8 — صفحة web لحذف الحساب

### الملفات المتأثّرة
- `web/delete-account.html` (ملف جديد)
- `firebase.json` (إن كان الاستضافة على Firebase Hosting)

### التنفيذ

**8.1** أنشئ `web/delete-account.html`:

```html
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <title>حذف حساب نبضة</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body { font-family: 'Arial', sans-serif; background: #FFF8FB; padding: 20px; max-width: 600px; margin: 40px auto; }
    h1 { color: #E91E63; }
    .card { background: white; padding: 30px; border-radius: 16px; box-shadow: 0 4px 20px rgba(0,0,0,0.05); }
    input, textarea { width: 100%; padding: 12px; margin: 8px 0; border: 1px solid #ddd; border-radius: 8px; }
    button { background: #E91E63; color: white; padding: 14px 24px; border: none; border-radius: 8px; cursor: pointer; font-size: 16px; }
    .warning { background: #FFE8EC; padding: 16px; border-radius: 8px; margin: 16px 0; color: #C62828; }
  </style>
</head>
<body>
  <div class="card">
    <h1>حذف حساب نبضة</h1>
    <p>لحذف حسابك وبياناتك بالكامل من تطبيق نبضة، املئي النموذج التالي:</p>
    
    <div class="warning">
      ⚠️ الحذف نهائي ولا يمكن التراجع عنه. ستُحذف كل بياناتك (الحمل، الدورة، الأطفال، الطلبات).
    </div>
    
    <form action="mailto:matbakhwalid@gmail.com?subject=طلب%20حذف%20حساب%20نبضة" method="post" enctype="text/plain">
      <label>البريد الإلكتروني المسجَّل به حسابك:</label>
      <input type="email" name="email" required>
      
      <label>سبب الحذف (اختياري):</label>
      <textarea name="reason" rows="3"></textarea>
      
      <label>
        <input type="checkbox" required>
        أفهم أن الحذف نهائي ولا يمكن استرجاع بياناتي
      </label>
      
      <br><br>
      <button type="submit">أرسلي طلب الحذف</button>
    </form>
    
    <p style="margin-top: 24px; color: #666; font-size: 14px;">
      ما يتمّ حذفه: بياناتك الشخصية، الصحّية، صور طفلك، سجلّاتك.<br>
      ما يبقى: سجلّات معاملات المتجر (5 سنوات لأسباب قانونية).<br>
      مدة الحذف: خلال 30 يوماً من الطلب.
    </p>
  </div>
</body>
</html>
```

**8.2** انشرها عبر:
```cmd
firebase deploy --only hosting
```

الرابط الناتج: `https://nabda.online/delete-account.html`

### Commit message
```
feat(web): صفحة delete-account.html لطلبات حذف الحساب من خارج التطبيق

مطلوبة لسياسة Google Play Account Deletion (للمستخدمات اللواتي حذفن التطبيق)
```

---

## المرحلة 9 — تحديث pubspec + gitignore + رقم WhatsApp

### 9.1 في `pubspec.yaml`
```yaml
description: "نبضة — تطبيق صحة المرأة العربية: متابعة الحمل والدورة ورعاية الطفل"
version: 1.0.0+1
```

### 9.2 في `.gitignore`
تحقّق من وجود:
```
android/nabda-release-key.jks
android/key.properties
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
```

### 9.3 في Firebase Console (يدوي)
- Firestore → `app_config/contact` → whatsappNumber → غيّر من `213555000000` إلى رقمك الحقيقي (بصيغة دولية بلا +)

### Commit message
```
chore: تحديث pubspec.yaml + .gitignore + إعداد رقم WhatsApp الحقيقي
```

---

## 📊 قائمة تحقّق نهائية للمُنفّذ

قبل تسليم العمل، تأكّد:

- [ ] المرحلة 1: زر حذف الحساب يعمل — اختبر: أنشئ حساب اختبار، احذفه، تأكّد أنّ الوثيقة اختفت من Firestore
- [ ] المرحلة 2: زر إبلاغ يظهر ويحفظ في `post_reports`
- [ ] المرحلة 3: `Info.plist` يحوي 5+ usage descriptions
- [ ] المرحلة 4: اسم التطبيق «نبضة» موحّد
- [ ] المرحلة 5: `grep -rn "AIzaSy" lib/main.dart` = فارغ
- [ ] المرحلة 6: عند فتح AI أوّل مرّة، Modal الموافقة يظهر
- [ ] المرحلة 7: `google-services.json` يحوي SHA fingerprints
- [ ] المرحلة 8: `nabda.online/delete-account.html` يفتح ويرسل بريد
- [ ] المرحلة 9: pubspec.yaml محدّث + gitignore صحيح + WhatsApp حقيقي

**بعد كل الإصلاحات:**
```cmd
flutter clean
flutter pub get
flutter analyze
flutter build appbundle --release
```

يجب أن ينتج ملف `build\app\outputs\bundle\release\app-release.aab` بلا أخطاء.

---

## 🎁 مكافأة اختيارية

بعد إتمام الـ9 مراحل، إن بقي وقت:

**م10 — Firebase Crashlytics:**
```yaml
firebase_crashlytics: ^4.1.0
```
```dart
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
```

**م11 — App Icon adaptive:**
اقرأ `scripts/generate_launcher_icons.md` — استعمل flutter_launcher_icons.

---

## 📞 إذا حصلت صعوبة

- خطأ Edit tool يقتطع الملف الكبير → استعمل Python + read all → modify → cp
- خطأ Firestore rule → افتح Firebase Console → Rules → Simulator لاختبار
- خطأ SHA-1 → تأكّد من keystore الصحيح (debug vs release)

---

*هذا الملف self-contained. لا يحتاج سياقاً إضافياً. يمكن نسخه لـ Antigravity كاملاً كـ initial prompt.*
