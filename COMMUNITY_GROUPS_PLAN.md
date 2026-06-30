# خطة تنفيذ مجموعات المجتمع (النوادي) والرسائل المباشرة لتطبيق نبضة

تهدف هذه الخطة إلى نقل مجتمع تطبيق وموقع نبضة إلى مستوى جديد من التفاعل والتخصيص، عبر إدخال مفهوم **"نوادي أشهر الولادة" (Birth Cohorts)** والرسائل المباشرة بين الأمهات، لتقديم تجربة شبيهة بالمنصات العالمية مثل BabyCenter ولكن بهوية عربية ورعاية كاملة للخصوصية.

---

## 📋 جدول المحتويات
1. [الفكرة المحورية والمنطق الرياضي للاشتقاق](#1-الفكرة-المحورية-والمنطق-الرياضي-للاشتقاق)
2. [تحديثات بنية قاعدة البيانات (Firestore Schemas)](#2-تحديثات-بنية-قاعدة-البيانات-firestore-schemas)
3. [الخدمات البرمجية المقترحة (Services)](#3-الخدمات-البرمجية-المقترحة-services)
4. [تعديلات واجهة المستخدم (UI changes)](#4-تعديلات-واجهة-المستخدم-ui-changes)
5. [قواعد الحماية والفهارس (Security Rules & Indexes)](#5-قواعد-الحماية-والفهارس-security-rules--indexes)
6. [مراحل التنفيذ الأربعة (Deployment Phases)](#6-مراحل-التنفيذ-الأربعة-deployment-phases)
7. [ملاحظات هامة للبيئة المحلية والمزامنة](#7-ملاحظات-هامة-للبيئة-المحلية-والمزامنة)

---

## 1. الفكرة المحورية والمنطق الرياضي للاشتقاق

لتفادي تفكك المجموعات عند تغير أشهر الحمل (الذي يتغير كل 4 أسابيع)، نعتمد آلية **"أفواج أشهر الولادة"** الثابتة. يتم تصنيف المستخدمة تلقائياً بناءً على حالتها:

### أ. الحوامل (Pregnant Cohort):
* **المعادلة:** يتم احتساب تاريخ الولادة المتوقع (EDD) بإضافة **280 يوماً** إلى تاريخ بداية الحمل (`pregnancyStartDate`).
  $$\text{EDD} = \text{pregnancyStartDate} + 280\text{ days}$$
* **مفتاح الفوج (Cohort Key):** يشتق من سنة وشهر الولادة المتوقعة بالصيغة: `due_YYYY_MM`.
  * *مثال:* بداية الحمل في 20 مارس 2026 $\rightarrow$ تاريخ الولادة المتوقع 25 ديسمبر 2026 $\rightarrow$ الفوج هو `due_2026_12`.

### ب. الأمهات (Mothers Cohort):
* **المعطى:** تاريخ الولادة الفعلي للطفل (`babyBirthDate`).
* **مفتاح الفوج (Cohort Key):** يشتق بالصيغة: `born_YYYY_MM`.
  * *مثال:* ولد الطفل في 14 مايو 2026 $\rightarrow$ الفوج هو `born_2026_05`.

### ج. الانتقال التلقائي (Automatic Migration):
بمجرد قيام المستخدمة بتأكيد حدوث الولادة في التطبيق وتحديث حالتها إلى "أم"، تقوم الخدمة البرمجية تلقائياً بحذفها من مجموعة `due_YYYY_MM` وإضافتها إلى مجموعة `born_YYYY_MM` الجديدة، مع تحديث عداد الأعضاء في كلا المجموعتين بشكل تزامني آمن.

---

## 2. تحديثات بنية قاعدة البيانات (Firestore Schemas)

### 📄 تحديث وثيقة المستخدم (`users/{uid}`)
نضيف حقلاً واحداً لحفظ الفوج الحالي للمستخدمة لتسهيل الاستعلام السريع:
```json
{
  "cohortKey": "due_2027_01", // أو "born_2026_05" أو null
  "hasConfirmedBirth": false
}
```

### 📄 تحديث وثيقة منشورات المجتمع (`community_posts/{postId}`)
لتفادي تكرار كود الإعجابات والتعليقات، نقوم بإعادة استخدام نفس مجموعة المنشورات وإضافة حقل الفوج الاختياري:
```json
{
  "cohortKey": "due_2027_01", // يكون null للمنشورات العامة في المجتمع
  "isPublic": false // true للمجتمع العام، false لمنشورات النادي الخاص
}
```

### 📄 مجموعة عداد الأعضاء (`cohort_members_count/{cohortKey}`)
وثيقة لتخزين الإحصائيات الحيوية لكل نادٍ:
```json
{
  "memberCount": 142,
  "lastUpdated": "Timestamp"
}
```

### 📄 مجموعة الدردشات المباشرة (`direct_chats/{chatId}`)
لإدارة المحادثات الثنائية بين الأمهات:
```json
{
  "participants": ["uid1", "uid2"],
  "lastMessage": "مرحباً بكِ في المجموعة!",
  "lastMessageSenderId": "uid1",
  "lastMessageTime": "Timestamp",
  "unreadCount": {
    "uid1": 0,
    "uid2": 1
  },
  "blockedBy": [] // مصفوفة لحفظ المعرفات في حال قيام طرف بحظر الآخر
}
```

### 📄 الرسائل الفرعية (`direct_chats/{chatId}/messages/{messageId}`)
```json
{
  "senderId": "uid1",
  "text": "مرحباً بكِ في المجموعة!",
  "createdAt": "Timestamp",
  "isRead": false
}
```

---

## 3. الخدمات البرمجية المقترحة (Services)

### 🛠️ [NEW] خدمة الأفواج والنوادي (`lib/services/cohort_service.dart`)
تتعامل مع الحساب الرياضي، الانضمام التلقائي، وتحديث أعداد الأعضاء بـ Firestore:
```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CohortService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. اشتقاق المفتاح تلقائياً
  String? deriveCohortKey({
    required String status,
    DateTime? pregnancyStartDate,
    DateTime? babyBirthDate,
  }) {
    if (status == 'pregnant' && pregnancyStartDate != null) {
      final edd = pregnancyStartDate.add(const Duration(days: 280));
      return 'due_${edd.year}_${edd.month.toString().padLeft(2, '0')}';
    } else if (status == 'mother' && babyBirthDate != null) {
      return 'born_${babyBirthDate.year}_${babyBirthDate.month.toString().padLeft(2, '0')}';
    }
    return null;
  }

  // 2. تحديث الفوج ومزامنة العداد
  Future<void> syncUserCohort(String uid, String? newCohortKey) async {
    final userRef = _db.collection('users').doc(uid);
    
    await _db.runTransaction((transaction) async {
      final userSnap = await transaction.get(userRef);
      if (!userSnap.exists) return;

      final oldCohortKey = userSnap.data()?['cohortKey'] as String?;
      if (oldCohortKey == newCohortKey) return; // لا تغيير

      // تحديث وثيقة المستخدم
      transaction.update(userRef, {'cohortKey': newCohortKey});

      // إنقاص العداد القديم
      if (oldCohortKey != null) {
        final oldCounterRef = _db.collection('cohort_members_count').doc(oldCohortKey);
        transaction.update(oldCounterRef, {'memberCount': FieldValue.increment(-1)});
      }

      // زيادة العداد الجديد
      if (newCohortKey != null) {
        final newCounterRef = _db.collection('cohort_members_count').doc(newCohortKey);
        transaction.set(newCounterRef, {
          'memberCount': FieldValue.increment(1),
          'lastUpdated': FieldValue.serverTimestamp()
        }, SetOptions(merge: true));
      }
    });
  }
}
```

### 🛠️ [NEW] خدمة الدردشة المباشرة (`lib/services/messaging_service.dart`)
تدير الرسائل المباشرة، الحظر، والإشارات:
```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MessagingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // إنشاء أو جلب معرف المحادثة الثنائية
  Future<String> getOrCreateChat(String currentUid, String recipientUid) async {
    final participants = [currentUid, recipientUid]..sort();
    final chatId = '${participants[0]}_${participants[1]}';

    final chatRef = _db.collection('direct_chats').doc(chatId);
    final snap = await chatRef.get();

    if (!snap.exists) {
      await chatRef.set({
        'participants': participants,
        'lastMessage': '',
        'lastMessageSenderId': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': {currentUid: 0, recipientUid: 0},
        'blockedBy': []
      });
    }
    return chatId;
  }

  // إرسال رسالة مع حارس حظر الدردشة
  Future<void> sendMessage(String chatId, String senderId, String text) async {
    final chatRef = _db.collection('direct_chats').doc(chatId);
    final snap = await chatRef.get();
    if (!snap.exists) return;

    final blockedBy = List<String>.from(snap.data()?['blockedBy'] ?? []);
    if (blockedBy.isNotEmpty) {
      throw Exception('لا يمكن إرسال الرسالة. تم حظر هذه الدردشة.');
    }

    final messageRef = chatRef.collection('messages').doc();
    await _db.runTransaction((transaction) async {
      transaction.set(messageRef, {
        'senderId': senderId,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false
      });

      transaction.update(chatRef, {
        'lastMessage': text,
        'lastMessageSenderId': senderId,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    });
  }
}
```

---

## 4. تعديلات واجهة المستخدم (UI changes)

### 📱 تحديث شاشة المجتمع (`lib/screens/community/community_screen.dart`)
* إضافة تبويب فرعي جديد باسم **«نادي الولادة»** أو **«ناديي»** بجانب التبويب العام.
* في حال لم تكن المستخدمة منضمة لأي فوج (مثل حاملي حالات خاصة لم يحددوا تواريخهم)، يظهر تصميم فارغ يشرح الميزة وزر سريع للانتقال لإعداد الملف الشخصي لتحديد التواريخ.
* المنشورات داخل هذا التبويب تصفى بـ `cohortKey` المأخوذ من ملف المستخدمة الحالي.

### 💬 شاشات الرسائل المباشرة (Direct Messaging Screens)
1. **[NEW] شاشة قائمة المحادثات (`lib/screens/messaging/chat_list_screen.dart`):**
   * تعرض قائمة الدردشات الجارية للمستخدمة مع فرزها تنازلياً حسب وقت آخر رسالة.
   * تُظهر شارات الرسائل غير المقروءة لكل مستخدمة بشكل حيوي.
2. **[NEW] شاشة غرفة المحادثة (`lib/screens/messaging/chat_room_screen.dart`):**
   * واجهة مستخدم نظيفة تشبه واتساب لعرض الرسائل المتبادلة في الوقت الحقيقي.
   * خيار في القائمة العلوية لإجراء **"حظر المستخدم"** أو **"الإبلاغ عن إساءة"** (لإعادة توجيه البيانات لمسار الإشراف العام بالتطبيق).
   * استبدال زر "الرسائل المباشرة قريباً" المعطل في شاشة حسابات المستخدمين برابط مباشر يفتح المحادثة الثنائية فوراً.

---

## 5. قواعد الحماية والفهارس (Security Rules & Indexes)

### 🔒 تحديث `firestore.rules` (تُطبق يدوياً)
لحماية الخصوصية المطلقة للرسائل المباشرة ومنشورات النوادي:

```javascript
// حماية الدردشات الثنائية
match /direct_chats/{chatId} {
  allow read, write: if request.auth != null && request.auth.uid in resource.data.participants;
  allow create: if request.auth != null && request.auth.uid in request.resource.data.participants;

  match /messages/{messageId} {
    allow read, write: if request.auth != null && request.auth.uid in get(/databases/$(database)/documents/direct_chats/$(chatId)).data.participants;
  }
}

// حماية منشورات النوادي الخاصة
match /community_posts/{postId} {
  allow read: if request.auth != null && 
    (resource.data.isPublic == true || resource.data.cohortKey == get(/databases/$(database)/documents/users/$(request.auth.uid)).data.cohortKey);
  
  allow create: if request.auth != null && 
    (request.resource.data.isPublic == true || request.resource.data.cohortKey == get(/databases/$(database)/documents/users/$(request.auth.uid)).data.cohortKey);
}
```

### 🗂️ الفهارس المركبة المطلوبة (Composite Indexes)
لتسريع عرض منشورات النادي فرزاً تنازلياً حسب تاريخ الإنشاء:
1. المجموعة: `community_posts` $\rightarrow$ الحقول: `cohortKey` (صاعد) + `createdAt` (تنازل).

---

## 6. مراحل التنفيذ الأربعة (Deployment Phases)

### 🏁 المرحلة 1: البنية التحتية والربط التلقائي
* إنشاء كود خدمات `CohortService` بالكامل ومطابقة التواريخ.
* تعديل شاشة إعداد الحساب عند تسجيل البيانات لتشغيل المزامنة تلقائياً.
* تحديث وثائق المستخدمين الحاليين عبر تشغيل الخدمة بشكل كسول (Lazy) عند أول دخول لصفحة المجتمع.

### 🏁 المرحلة 2: منشورات النادي والواجهة
* إضافة تبويب "ناديي" بشاشة المجتمع.
* تعديل شاشة إنشاء منشور للسماح بنشر منشور خاص بالنادي (تحديد `cohortKey` وتعيين `isPublic: false`).
* التحقق من تصفية المنشورات وعمل العدادات بشكل صحيح.

### 🏁 المرحلة 3: الرسائل المباشرة (DMs)
* بناء شاشتي `ChatListScreen` و `ChatRoomScreen`.
* استبدال الأزرار المؤقتة المعطلة في الملف الشخصي بمسار فتح المحادثة الفعلي.
* كتابة منطق الحظر والإبلاغ وتجربته.

### 🏁 المرحلة 4: الحماية والتأكيد النهائي
* مراجعة فهارس الاستعلام وتحديث `firestore.rules`.
* إجراء اختبارات مكثفة للأمان والتأكد من عدم قدرة أي مستخدم على قراءة منشورات نادٍ آخر أو رسائل شخصية لآخرين.

---

## 7. ملاحظات هامة للبيئة المحلية والمزامنة

> [!IMPORTANT]
> **نداءات التوجيه (Routes) في `main.dart`:**  
> لتفادي التعارض مع نظام المصادقة المطور محلياً، يجب التعامل مع ملف `main.dart` و `lib/config/routes.dart` بحذر، ويفضل ترميز مسارات شاشات الدردشة الجديدة بوسم `// Local Only` لضمان استقرار العمل البرمجي الجاري.

> [!WARNING]
> **قواعد الحماية (Security Rules):**  
> يجب نشر تحديثات القواعد يدوياً من واجهة Firebase Console أو باستخدام الـ CLI المعتمد بعد تعديل البيئة المحلية، لضمان عدم كسر حماية البيانات الشخصية للمستخدمين الحاليين.
