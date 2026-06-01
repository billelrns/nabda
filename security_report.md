# تقرير الثغرات الأمنية — تطبيق نبضة
**التاريخ:** 2026-05-31  
**المحلل:** Claude (Cowork)  
**المستوى:** حرج ← متوسط ← منخفض

---

## ملخص تنفيذي

تم فحص الكود البرمجي الكامل للتطبيق. وُجدت **9 ثغرات** مصنّفة بين حرجة وعالية ومتوسطة. الأخطر هو تسرّب مفاتيح Firebase في الكود المصدري، وغياب التحقق من الهوية على مستوى الخادم لعمليات الأدمن وتعديل البيانات.

---

## 🔴 حرجة (Critical)

### 1. Firebase API Key مكشوف في الكود المصدري
**الملف:** `lib/firebase_options.dart` — السطور 14، 23، 30

```dart
apiKey: 'AIzaSyDyFmGvaOMAzb2XXOFR_RO_lSn7UYyBd6M',
```

**المشكلة:** مفتاح Firebase الحقيقي موجود مباشرةً في الكود. أي شخص يطّلع على المستودع يمكنه:
- استعمال المفتاح للوصول إلى Firebase Console
- تجاوز القيود إذا كانت Firestore Security Rules ضعيفة
- إجراء عمليات مصادقة على حسابك

**الحل:**
- يجب الاطمئنان أن Firestore Security Rules مشددة (انظر ثغرة #3)
- قيّد المفتاح في Google Cloud Console على التطبيقات المسموح بها فقط
- أضف `firebase_options.dart` إلى `.gitignore` وادعم `google-services.json` من بيئة CI/CD

---

### 2. لوحة الأدمن `/admin` بدون حماية على مستوى الروابط
**الملف:** `lib/config/routes.dart` — السطر 122-124

```dart
GoRoute(
  path: adminPanel,  // '/admin'
  builder: (context, state) => const AdminPanelScreen(),
),
```

**المشكلة:** لا يوجد `redirect` أو `guard` على المسار `/admin`. أي مستخدم مسجّل دخوله يستطيع الانتقال مباشرةً إلى `/admin` عبر Deep Link أو عن طريق كتابة المسار. كل الحماية تعتمد على `AdminService` الذي يُقرأ من Firestore — لكن:
- إذا فشل الاتصال بـ Firestore يعود الدور `AdminRole.user` (بدون صلاحيات) لكن الشاشة تُفتح
- لا يوجد redirect للمستخدم غير المخوّل

**الحل:**
```dart
GoRoute(
  path: adminPanel,
  redirect: (context, state) async {
    final admin = AdminService();
    await admin.initialize();
    if (!admin.isAdmin) return '/home';
    return null;
  },
  builder: (context, state) => const AdminPanelScreen(),
),
```

---

### 3. غياب Firestore Security Rules (عمليات CRUD بدون تحقق خادم)
**الملفات:** `lib/services/firestore_service.dart`، `admin_service.dart`

**المشكلة:** جميع عمليات القراءة والكتابة على Firestore تتم مباشرةً من الـ Client. مثال:

```dart
// deleteCycle — لا يتحقق أن المستخدم الحالي يملك هذه الدورة
Future<void> deleteCycle(String cycleId) async {
  await _firestore.collection('cycles').doc(cycleId).delete();
}
```

مستخدم يعرف `cycleId` لمستخدمة أخرى يستطيع حذف بياناتها. نفس المشكلة مع `pregnancy`، `babies`، `messages`.

**الحل — Firestore Security Rules المقترحة:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // المستخدمون يقرؤون ويعدّلون بياناتهم فقط
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // الدورات
    match /cycles/{cycleId} {
      allow read, write: if request.auth != null 
        && request.auth.uid == resource.data.userId;
      allow create: if request.auth != null 
        && request.auth.uid == request.resource.data.userId;
    }
    
    // الحمل
    match /pregnancies/{pregnancyId} {
      allow read, write: if request.auth != null 
        && request.auth.uid == resource.data.userId;
    }
    
    // الأطفال
    match /babies/{babyId} {
      allow read, write: if request.auth != null 
        && request.auth.uid == resource.data.userId;
    }
    
    // الموظفون — للقراءة من الـ Admin فقط
    match /staff/{staffId} {
      allow read, write: if request.auth != null 
        && get(/databases/$(database)/documents/staff/$(request.auth.uid)).data.isActive == true;
    }
    
    // المنشورات المجتمعية — القراءة للجميع، الكتابة للمالك فقط
    match /community_posts/{postId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null 
        && request.auth.uid == request.resource.data.userId;
      allow update, delete: if request.auth != null 
        && request.auth.uid == resource.data.userId;
    }
  }
}
```

---

## 🟠 عالية (High)

### 4. `updateUserProfile` يقبل أي `uid` دون التحقق
**الملف:** `lib/services/auth_service.dart` — السطر 87

```dart
Future<void> updateUserProfile({
  required String uid,  // ← لا يتحقق أنه uid المستخدم الحالي
  String? name,
  ...
}) async {
  await _firestore.collection('users').doc(uid).update(updateData);
}
```

**المشكلة:** إذا استطاع مستخدم معرفة `uid` مستخدم آخر (وهو ممكن إذا ظهر في منشورات المجتمع)، يمكنه تغيير اسمه أو صورته.

**الحل:**
```dart
Future<void> updateUserProfile({String? name, String? avatar, ...}) async {
  final uid = _auth.currentUser?.uid;
  if (uid == null) throw Exception('يجب تسجيل الدخول أولاً');
  // استخدم uid المستخدم الحالي فقط
  await _firestore.collection('users').doc(uid).update(updateData);
}
```

---

### 5. صلاحيات الأدمن تُتحقق Client-Side فقط
**الملف:** `lib/services/admin_service.dart` — السطر 141

```dart
bool hasPermission(Permission p) {
  return rolePermissions[_currentRole]?.contains(p) ?? false;
}
```

**المشكلة:** إذا تلاعب شخص بقيم الـ `_currentRole` محلياً أو تجاوز الـ UI مباشرةً، تُنفَّذ العمليات على Firestore بدون تحقق من الخادم.

**الحل:** أضف Firestore Security Rules تتحقق من دور الموظف على الخادم (كما في #3)، وأضف Firebase Functions للعمليات الحساسة كـ `banUser`، `addStaff`.

---

### 6. إنشاء UID الموظف بطريقة متوقعة
**الملف:** `lib/services/admin_service.dart` — السطر 200

```dart
uid = email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
// admin@nabda.com → admin_nabda_com
```

**المشكلة:** إذا سجّل شخص بريد إلكتروني يطابق هذا النمط قبل إضافته كموظف، سيحصل تلقائياً على document في مجموعة `staff` بصلاحيات الدور المطلوب.

**الحل:** استخدم UUID عشوائي دائماً، ولا تُضف `staff document` إلا لمستخدم موجود بالفعل في Firebase Auth.

---

## 🟡 متوسطة (Medium)

### 7. لا يوجد Email Verification بعد التسجيل
**الملف:** `lib/services/auth_service.dart` — السطر 13

```dart
final userCredential = await _auth.createUserWithEmailAndPassword(
  email: email, password: password,
);
// ← لا يوجد: await user.sendEmailVerification();
```

**المشكلة:** يمكن لأي شخص إنشاء حساب ببريد وهمي أو بريد شخص آخر دون تأكيد.

**الحل:**
```dart
await user.sendEmailVerification();
// وفي صفحة الدخول:
if (!user.emailVerified) {
  await _auth.signOut();
  throw Exception('يرجى تفعيل بريدك الإلكتروني أولاً');
}
```

---

### 8. كلمة المرور ضعيفة (6 أحرف فقط)
**الملف:** `lib/utils/validators.dart` — السطر 23

```dart
if (value.length < 6) {
  return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
}
```

**المشكلة:** التطبيق يحتوي بيانات صحية حساسة جداً. كلمة مرور من 6 أحرف سهلة القرصنة.

**الحل:** ارفع الحد إلى 8 أحرف على الأقل مع شرط واحد من: رقم أو رمز خاص.

```dart
if (value.length < 8) return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
if (!RegExp(r'[0-9]').hasMatch(value) && !RegExp(r'[!@#$%^&*]').hasMatch(value))
  return 'كلمة المرور يجب أن تحتوي على رقم أو رمز خاص';
```

---

### 9. رسائل الخطأ تكشف تفاصيل داخلية
**الملف:** `lib/services/auth_service.dart` — السطر 65

```dart
throw Exception('خطأ في تسجيل الدخول: ${e.message}');
```

**المشكلة:** `e.message` من Firebase يكشف للمهاجم معلومات كـ "EMAIL_NOT_FOUND" أو "INVALID_PASSWORD" تساعده في تحديد الحسابات الموجودة.

**الحل:**
```dart
on FirebaseAuthException catch (e) {
  switch (e.code) {
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      throw Exception('البريد الإلكتروني أو كلمة المرور غير صحيحة');
    default:
      throw Exception('حدث خطأ، يرجى المحاولة لاحقاً');
  }
}
```

---

## 🟢 ملاحظات إضافية (منخفضة)

| # | الملاحظة | الملف |
|---|----------|-------|
| 10 | نظام الدفع يُرجع `success: true` بدون معالجة حقيقية — خطر إذا ربط به منطق أعمال | `payment_service.dart` |
| 11 | لا يوجد Rate Limiting على طلبات المصادقة أو الذكاء الاصطناعي | Firebase Console |
| 12 | منشورات المجتمع والتعليقات تُحفظ دون تنظيف — قد تكون مشكلة إذا عُرضت في WebView | `firestore_service.dart` |
| 13 | مفتاح Firebase واحد للـ Web وAndroid وiOS — يُفضّل مفاتيح مختلفة | `firebase_options.dart` |

---

## خلاصة الأولويات

| الأولوية | الإجراء |
|----------|---------|
| 🔴 فوري | ضع Firestore Security Rules الآن |
| 🔴 فوري | أضف redirect guard على مسار `/admin` |
| 🟠 هذا الأسبوع | اصلح `updateUserProfile` ليستخدم uid المستخدم الحالي |
| 🟠 هذا الأسبوع | اصلح منطق إنشاء uid الموظف |
| 🟡 قريباً | أضف Email Verification |
| 🟡 قريباً | عزّز متطلبات كلمة المرور |
| 🟡 قريباً | عمّم رسائل الخطأ |

---

*هذا التقرير بناءً على تحليل الكود الستاتيكي. يُنصح بإجراء اختبار اختراق ديناميكي قبل إطلاق التطبيق للعموم.*
