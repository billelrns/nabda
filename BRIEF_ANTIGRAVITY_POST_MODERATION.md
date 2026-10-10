# أمر تنفيذ لـAntigravity — حذف المنشورات والإشراف على المجتمع

25 سبتمبر 2026 · مجلّد العمل: **`C:\nabda_app` حصرًا**

---

## السياق — عطلان مستقلّان اكتُشفا معًا

بلال لا يستطيع حذف منشوراته التجريبية في مجتمع الحوامل. الفحص كشف سببين
منفصلين، كلاهما يحتاج إصلاحًا:

1. **لا يوجد مسار حذف أصلًا** في الشاشتين اللتين تُستعملان فعليًا
   (`community_screen.dart` و`post_detail_screen.dart`).
2. **شرط الملكية يعتمد على uid** كُتبت به منشورات بحساب قديم مُنشأ في مايو،
   ثم أُعيد إنشاء الحساب في سبتمبر بـuid مختلف. وهذا نفس السبب الذي عطّل
   لوحة التحكّم (وثيقة `staff` كانت بمعرّف الحساب القديم).

---

## الحالة الراهنة — ما وجدتُه بالفحص

| الموضع | القائمة | الحذف |
|---|---|---|
| `community_screen.dart` (المسار `/community` المسجَّل في `routes.dart:139`) | **لا قائمة إطلاقًا** | ❌ |
| `post_detail_screen.dart:315-361` | حفظ · تنبيهات · إخفاء · إبلاغ · حظر | ❌ |
| `main.dart:8942-9019` (تدفّق قديم) | حذف للكاتبة فقط · إبلاغ/حظر للباقين | جزئي |
| `my_posts_screen.dart:126` | حذف | ✅ للكاتبة فقط |
| `admin_panel_screen.dart:6246` | **عبر البلاغات فقط** | جزئي |

قواعد Firestore سليمة ولا تحتاج تعديلًا — `firestore.rules:170`:

```
allow delete: if isAuthenticated() &&
  (isOwner(resource.data.userId) || isOwnerOrSupervisor());
```

**الصلاحية موجودة في الخادم؛ الناقص هو الزرّ في الواجهة.** وهذا مهمّ:
الإصلاح كلّه في طبقة العرض، بلا أي مساس بالأمان أو بالبيانات.

---

## المهمة 1 — دالّة حذف موحّدة

`lib/services/community_moderation.dart` (ملف جديد):

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'admin_service.dart';

class CommunityModeration {
  /// هل تملك المستخدمة الحالية صلاحية حذف هذا المنشور؟
  /// الكاتبة نفسها، أو المالك/المشرف.
  static bool canDelete(String postAuthorUid) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    if (uid == postAuthorUid) return true;
    return AdminService().hasPermission(Permission.manageUsers);
  }

  /// يحذف المنشور وتعليقاته. يُرجع رسالة خطأ أو null عند النجاح.
  static Future<String?> deletePost(String postId) async {
    try {
      final db = FirebaseFirestore.instance;
      final ref = db.collection('community_posts').doc(postId);

      // التعليقات مجموعة فرعية — احذفها أولًا وإلا بقيت يتيمة في Firestore
      while (true) {
        final snap = await ref.collection('comments').limit(400).get();
        if (snap.docs.isEmpty) break;
        final batch = db.batch();
        for (final d in snap.docs) { batch.delete(d.reference); }
        await batch.commit();
        if (snap.docs.length < 400) break;
      }

      await ref.delete();
      return null;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return 'لا تملكين صلاحية حذف هذا المنشور';
      }
      return 'تعذّر الحذف — تحقّقي من الاتصال';
    } catch (_) {
      return 'تعذّر الحذف — حاولي مجدّدًا';
    }
  }
}
```

⚠️ **لا تبتلع الخطأ هنا.** هذه رابع مرّة في هذا المشروع يخفي فيها
`catch (_) {}` عطلًا حقيقيًا (المساعد الذكي، لوحة التحكّم، وغيرهما).
إن فشل الحذف، **يجب أن ترى المستخدمة رسالة** — لا أن يبدو الزرّ ميّتًا.
ولهذا تُرجع الدالّة `String?` بدل `bool`.

> **تحقّق أولًا من اسم مجموعة التعليقات الفرعية** — اقرأ
> `post_detail_screen.dart` و`firestore_service.dart` وتأكّد أنها
> `comments`. إن كانت التعليقات مصفوفةً داخل الوثيقة لا مجموعةً فرعية،
> احذف حلقة التنظيف كلّها.

---

## المهمة 2 — قائمة في بطاقة المنشور داخل `community_screen.dart`

هذه الشاشة **بلا قائمة إطلاقًا**، وهي الشاشة المسجَّلة في `routes.dart`.
أضف `PopupMenuButton` في رأس البطاقة (في `_buildPostCard`، قرب السطر 415
حيث يُحسب `isLiked`)، بنفس شكل `main.dart:8942`:

- **إن كانت `CommunityModeration.canDelete(post.userId)`** → خيار
  «حذف المنشور» بالأحمر
- **دائمًا** (لغير الكاتبة) → «إبلاغ عن المنشور» · «حظر هذه المستخدمة»

فإن كانت المستخدمة مشرفةً على منشور غيرها، ظهرت **الثلاثة**: حذف وإبلاغ وحظر.

بعد الحذف: `ScaffoldMessenger` برسالة «تم حذف المنشور»، أو برسالة الخطأ
المُعادة إن فشل.

---

## المهمة 3 — الحذف في شاشة التفاصيل

`post_detail_screen.dart` — أضف عنصرًا سادسًا إلى `itemBuilder`
(السطر 315) **في أعلى القائمة**:

```dart
if (_cachedPost != null && CommunityModeration.canDelete(_cachedPost!.userId))
  const PopupMenuItem(
    value: 'delete',
    child: Row(children: [
      Icon(Icons.delete_outline, size: 20, color: Colors.red),
      SizedBox(width: 10),
      Text('حذف المنشور', style: TextStyle(color: Colors.red)),
    ]),
  ),
```

وفي `onSelected` حالة `'delete'`: حوار تأكيد → `deletePost` → عند النجاح
`Navigator.pop(context)` لأن الشاشة تعرض منشورًا لم يعد موجودًا.

⚠️ `itemBuilder` هنا يُرجع `List<PopupMenuEntry<String>>` ثابتة؛ حوّلها إلى
بناء بـcollection-if كما أعلاه — لن يقبل `const` على القائمة كلّها بعدها.

---

## المهمة 4 — وحدة «إدارة المنشورات» في لوحة التحكّم

مسار الحذف الوحيد اليوم عبر البلاغات (`admin_panel_screen.dart:6246`):
**المنشور المسيء الذي لم يبلّغ عنه أحد لا يمكن حذفه من داخل التطبيق.**

هذا شرط في سياسة Google Play للمحتوى الذي ينشئه المستخدمون، لا تحسينًا
اختياريًا.

أضف بطاقة وحدة جديدة في شبكة «الوحدات الإدارية» بعد «إدارة المقالات»:

> **إدارة المنشورات** — «عرض وحذف منشورات المجتمع» · أيقونة `forum`

شاشتها:

- `StreamBuilder` على `community_posts` مرتَّبة `createdAt` تنازليًا،
  **بـ`limit(50)` وزرّ «تحميل المزيد»** — لا تجلب المجموعة كاملة
- كل عنصر: صورة الكاتبة · اسمها · أول 120 حرفًا من النص · التاريخ ·
  عدد الإعجابات والتعليقات
- **بحث نصّي** في محتوى المنشور (تصفية محلّية على المُحمَّل يكفي)
- زرّ حذف أحمر لكل عنصر → نفس `CommunityModeration.deletePost`
- **تحديد متعدّد** لحذف دفعة واحدة — بلال يحتاجها الآن لتنظيف
  المنشورات التجريبية، وستنفع لاحقًا عند موجة سبام

الصلاحية: `Permission.manageUsers` (المالك والمشرف يملكانها؛ الموظف لا).

---

## المهمة 5 — السبب الجذري: وثائق مربوطة بـuid قديم

`admin_service.dart:198-211` يُنشئ وثيقة الموظف بـuid مأخوذ من البحث
بالبريد في `users`. هذا صحيح **ما دامت وثيقة `users` نفسها بالـuid
الحقيقي** — لكن حادثة اليوم أثبتت أن الانحراف يقع فعلًا.

أضف **فحص اتساق** في وحدة إدارة الموظفين باللوحة: لكل وثيقة في `staff`،
تحقّق أن `email` فيها يطابق `email` في `users/{doc.id}`. إن اختلفا أو
غابت وثيقة المستخدم، اعرض شارة حمراء **«معرّف غير مطابق»** مع زرّ حذف.

> بلال هو الموظف الوحيد اليوم، فالعطل كلّفه ساعة. مع خمسة مشرفين سيكلّف
> أكثر بكثير، ولن يكون سببه ظاهرًا.

---

## التحقّق

1. افتح منشورًا كتبته → **ظهر «حذف المنشور»** → احذفه → اختفى من القائمة
2. افتح منشور مستخدمة أخرى وأنت مالك → **ظهرت الثلاثة**: حذف · إبلاغ · حظر
3. سجّل الخروج وادخل بحساب عادي → افتح منشور غيرك → **لا خيار حذف**
4. من اللوحة: **إدارة المنشورات** → حدّد ثلاثة → حذف → اختفت من المجتمع
5. اقطع الإنترنت واضغط حذف → **رسالة خطأ واضحة**، لا زرّ صامت
6. في Firestore، تحقّق أن **مجموعة `comments` الفرعية اختفت** مع المنشور —
   هذه أكثر خطوة تُنسى، وتترك بيانات يتيمة تتراكم بصمت
7. `flutter analyze`

---

## ما لا يتغيّر

- **قواعد Firestore** — تسمح بالحذف أصلًا؛ لا تعدّلها
- **شكل بطاقة المنشور** — القائمة تُضاف في الرأس فقط
- **البيانات القائمة** — لا ترحيل ولا تعديل حقول
