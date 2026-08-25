# خطة Antigravity — استكمال ميزات حساب المستخدمة (نموذج «الملكة»)

> **موجّه إلى:** Antigravity / أي AI coding agent
> **المشروع:** `C:\nabda_app` — Flutter app (نبضة)
> **الهدف:** إضافة 13 ميزة مفقودة في صفحة «حسابي» بنبضة، مقتبسة من تطبيق «الملكة» المنافس
> **المدة المتوقّعة:** 4-6 ساعات عمل مركّز
> **المخرجات:** 10 commits منفصلة

---

## 📸 التحليل المرجعي — ما وجدناه في الملكة (Malika)

بناءً على 5 لقطات مرفقة من تطبيق الملكة:

### 1) شاشة «الدعم الفني» (Technical Support Form)
نموذج تواصل احترافي فيه:
- الاسم * (Name)
- البريد الإلكتروني * (Email)
- الغرض من التواصل * (Dropdown: الدعم الفني، اقتراح، شكوى، آخر)
- المشكلة التي تواجهك (Dropdown: خيارات مسبقة)
- عنوان الرسالة *
- اكتبي رسالتك *
- رفع صورة (اختياري، dashed border «إضغطي هنا لرفع صورة»)
- زر إرسال (turquoise/teal)

### 2) قائمة إجراءات المنشور (Post Actions Bottom Sheet)
تظهر عند فتح منشور:
- 📑 احفظ المنشور — «تستطيع الوصول اليه بسهوله من قائمة المحفوظات»
- ⚠️ الإبلاغ عن منشور (موجود جزئياً في نبضة)
- 🚫 اخفاء المنشور (مفقود في نبضة)
- 🔔 تفعيل التنبيهات — «حتى تصلك تنبيهات خاصة بالمنشور» (Toggle)

### 3) صفحة «حسابي» الرئيسية
قسمَان:
**القسم الأوّل (متعلّق بالنشاط الاجتماعي):**
- 🔄 متابعاتي (Following)
- ⚠️ محظوراتي (Blocked users)
- 🔖 المفضلة (Favorites / Saved posts)
- 📝 منشوراتي (My posts)

**القسم الثاني (أخرى):**
- 🛟 الدعم الفني (Support form)
- ⚙️ الإعدادات (Settings)
- ⭐ قيم البرنامج (Rate on Play Store)
- ✈️ انشر البرنامج (Share app link)
- 💖 عن التطبيق (About)

**زر كبير في الأسفل:**
- 🔒 التحكم في بياناتي (Data control - export/delete)

### 4) صفحة تفاصيل الحساب
- Avatar + username
- **هدف الاستخدام** (3 أزرار: متابعة الدورة / متابعة الحمل / البحث عن حمل) — يمكن تغييره لاحقاً
- **بيانات خاصة بالحمل** (Group): الموعد المتوقّع، التنبيهات، بيانات الطفل
- **بانر الاشتراك الذهبي** (Gold subscription)
- **أنشطتي** (My activities): استشاراتي، متابعيني، متابعاتي

---

## 📋 ما هو موجود مسبقاً في نبضة (لا تكرّر عمله)

✅ **حذف الحساب** — موجود (زر أحمر في ProfilePage)
✅ **حظر مستخدمة** — الوظيفة موجودة (`users/{uid}/blocked` subcollection) لكن **لا شاشة تعرضها**
✅ **إبلاغ عن منشور** — موجود (post_reports collection)
✅ **مجتمع + إنشاء منشورات** — موجود
✅ **إشعارات مجدولة** — موجودة (أدوية، ماء، إلخ)

---

## 🎯 المهام المطلوب تنفيذها (13 ميزة)

## المرحلة 1 — «المفضلة» (حفظ المقالات والمنشورات)

### الملفات الجديدة
- `lib/screens/profile/favorites_screen.dart` — شاشة قائمة المفضّلة

### الملفات المعدَّلة
- `lib/main.dart` — إضافة عنصر «المفضلة» في ProfilePage
- `lib/screens/community/post_detail_screen.dart` — زر «حفظ في المفضلة»
- `firestore.rules` — قواعد `users/{uid}/favorites`

### التنفيذ

**1.1 قواعد Firestore** (أضيفي في `firestore.rules` داخل `match /users/{userId}`):
```
match /favorites/{favId} {
  allow read, write: if isAuthenticated() && isOwner(userId);
}
```

**1.2 دالة الحفظ** في `post_detail_screen.dart`:
```dart
Future<void> _toggleFavorite() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;
  final ref = FirebaseFirestore.instance
      .collection('users').doc(uid)
      .collection('favorites').doc(widget.postId);
  final doc = await ref.get();
  if (doc.exists) {
    await ref.delete();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('أُزيل من المفضلة')),
    );
  } else {
    await ref.set({
      'type': 'post',
      'postId': widget.postId,
      'title': post.title ?? '',
      'preview': (post.content ?? '').substring(0, 100),
      'thumbnail': post.imageUrl,
      'authorName': post.authorName,
      'savedAt': FieldValue.serverTimestamp(),
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✓ حُفظ في المفضلة — يمكنكِ الوصول إليه من قائمة المحفوظات')),
    );
  }
  if (mounted) setState(() {});
}
```

**1.3 زر الحفظ** في PopupMenu بـpost_detail (بعد «إبلاغ»):
```dart
PopupMenuItem(
  value: 'favorite',
  child: Row(children: [
    Icon(Icons.bookmark_border, color: Color(0xFFE91E63)),
    SizedBox(width: 8),
    Text('حفظ في المفضلة'),
  ]),
),
```

**1.4 شاشة FavoritesScreen كاملة:**
```dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المفضلة', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF00897B),
          foregroundColor: Colors.white,
        ),
        body: uid == null
          ? const Center(child: Text('سجّلي الدخول أوّلاً'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users').doc(uid)
                  .collection('favorites')
                  .orderBy('savedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_border, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('لا توجد عناصر محفوظة', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('احفظي المقالات والمنشورات المهمّة لتصلي إليها بسهولة', 
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                    ],
                  ));
                }
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: d['thumbnail'] != null && d['thumbnail'].toString().isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(d['thumbnail'], width: 50, height: 50, fit: BoxFit.cover),
                          )
                        : Icon(Icons.bookmark, color: const Color(0xFFE91E63), size: 32),
                      title: Text(d['title'] ?? 'بدون عنوان', 
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(d['preview'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => docs[i].reference.delete(),
                      ),
                      onTap: () {
                        // TODO: انتقل لتفاصيل المنشور
                      },
                    );
                  },
                );
              },
            ),
      ),
    );
  }
}
```

### Commit
```
feat(profile): إضافة نظام المفضلة (حفظ المقالات والمنشورات)
```

---

## المرحلة 2 — «المحظورات» (شاشة عرض المستخدمات المحظورات)

### الملفات الجديدة
- `lib/screens/profile/blocked_users_screen.dart`

### التنفيذ

```dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المحظورات', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF00897B),
          foregroundColor: Colors.white,
        ),
        body: uid == null
          ? const Center(child: Text('سجّلي الدخول أوّلاً'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users').doc(uid)
                  .collection('blocked')
                  .orderBy('blockedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.block, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('لا يوجد مستخدمات محظورات', 
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                    ],
                  ));
                }
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final blockedUid = docs[i].id;
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users_directory').doc(blockedUid).get(),
                      builder: (context, snap) {
                        final data = snap.data?.data() as Map<String, dynamic>?;
                        final name = data?['displayName'] ?? data?['name'] ?? 'مستخدمة';
                        final avatar = data?['avatar'] as String?;
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.red.shade100,
                              backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                              child: avatar == null 
                                ? Text(name[0], style: const TextStyle(color: Colors.red))
                                : null,
                            ),
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: const Text('محظورة'),
                            trailing: TextButton.icon(
                              icon: const Icon(Icons.lock_open, color: Color(0xFF00897B)),
                              label: const Text('إلغاء الحظر', 
                                style: TextStyle(color: Color(0xFF00897B))),
                              onPressed: () => docs[i].reference.delete(),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
      ),
    );
  }
}
```

### Commit
```
feat(profile): شاشة عرض المستخدمات المحظورات مع إمكانية إلغاء الحظر
```

---

## المرحلة 3 — «متابعاتي» و «متابعيني» (Followers/Following)

### الملفات الجديدة
- `lib/screens/profile/follows_screen.dart` (شاشتان في ملف واحد)

### قواعد Firestore
```
match /users/{userId}/followers/{fUid} {
  allow read: if isAuthenticated();
  allow write: if isAuthenticated() && request.auth.uid == fUid;
}
match /users/{userId}/following/{fUid} {
  allow read: if isAuthenticated();
  allow write: if isAuthenticated() && isOwner(userId);
}
```

### التنفيذ
```dart
class FollowsScreen extends StatelessWidget {
  final String type; // 'followers' or 'following'
  final String title;
  const FollowsScreen({Key? key, required this.type, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF00897B),
          foregroundColor: Colors.white,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users').doc(uid)
              .collection(type)
              .snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Center(child: Text(
                type == 'followers' ? 'لا يوجد متابعات بعد' : 'لم تتابعي أحداً بعد',
                style: TextStyle(color: Colors.grey.shade600),
              ));
            }
            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, i) {
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users_directory').doc(docs[i].id).get(),
                  builder: (context, snap) {
                    final data = snap.data?.data() as Map<String, dynamic>?;
                    final name = data?['displayName'] ?? 'مستخدمة';
                    return ListTile(
                      leading: CircleAvatar(child: Text(name[0])),
                      title: Text(name),
                      // TODO: زر متابعة/إلغاء متابعة
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
```

### Commit
```
feat(profile): شاشات متابعاتي ومتابعيني
```

---

## المرحلة 4 — «منشوراتي» (My Posts)

### التنفيذ (شاشة جديدة)
```dart
class MyPostsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('منشوراتي')),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('community_posts')
              .where('userId', isEqualTo: uid)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(child: Text('لم تنشري بعد. شاركي في المجتمع!'));
            }
            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final d = docs[i].data() as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(d['title'] ?? 'بدون عنوان'),
                    subtitle: Text(d['content'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'delete') {
                          await docs[i].reference.delete();
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'delete', child: Text('حذف المنشور', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
```

---

## المرحلة 5 — «الدعم الفني» (Full Contact Form)

### الملف الجديد
- `lib/screens/profile/support_screen.dart`

### التنفيذ الكامل
```dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class SupportScreen extends StatefulWidget {
  const SupportScreen({Key? key}) : super(key: key);
  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  final _titleC = TextEditingController();
  final _msgC = TextEditingController();
  String? _purpose = 'الدعم الفني';
  String? _problem;
  File? _screenshot;
  bool _sending = false;

  final _purposes = ['الدعم الفني', 'اقتراح', 'شكوى', 'استفسار', 'آخر'];
  final _problems = [
    'مشكلة في تسجيل الدخول',
    'مشكلة في المحتوى',
    'مشكلة في الإشعارات',
    'مشكلة في الدفع',
    'مشكلة تقنية',
    'أخرى',
  ];

  @override
  void initState() {
    super.initState();
    // ملء تلقائي
    final user = FirebaseAuth.instance.currentUser;
    _emailC.text = user?.email ?? '';
    FirebaseFirestore.instance.collection('users').doc(user?.uid).get().then((doc) {
      if (doc.exists && mounted) {
        _nameC.text = (doc.data()?['displayName'] as String?) ?? '';
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (img != null) setState(() => _screenshot = File(img.path));
  }

  Future<void> _submit() async {
    if (_nameC.text.trim().isEmpty || _emailC.text.trim().isEmpty || 
        _titleC.text.trim().isEmpty || _msgC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء الحقول المطلوبة')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      String? imageUrl;
      if (_screenshot != null) {
        final ref = FirebaseStorage.instance.ref('support/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(_screenshot!);
        imageUrl = await ref.getDownloadURL();
      }
      await FirebaseFirestore.instance.collection('support_requests').add({
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'name': _nameC.text.trim(),
        'email': _emailC.text.trim(),
        'purpose': _purpose,
        'problem': _problem,
        'title': _titleC.text.trim(),
        'message': _msgC.text.trim(),
        'screenshot': imageUrl,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ تم إرسال طلبك، سنتواصل معكِ قريباً'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e')),
      );
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الدعم الفني', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF00897B),
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Illustration
            SizedBox(
              height: 180,
              child: Image.asset('assets/images/support_illustration.png',
                errorBuilder: (_, __, ___) => const Icon(Icons.contact_support, size: 100, color: Color(0xFF00897B))),
            ),
            const SizedBox(height: 16),
            _field(_nameC, 'الإسم *'),
            const SizedBox(height: 12),
            _field(_emailC, 'البريد الإلكتروني *', TextInputType.emailAddress),
            const SizedBox(height: 12),
            _dropdown('الغرض من التواصل *', _purpose, _purposes, (v) => setState(() => _purpose = v)),
            const SizedBox(height: 12),
            _dropdown('المشكلة التي تواجهك', _problem, _problems, (v) => setState(() => _problem = v)),
            const SizedBox(height: 12),
            _field(_titleC, 'عنوان الرسالة *'),
            const SizedBox(height: 12),
            _field(_msgC, 'اكتبي رسالتك *', TextInputType.multiline, 5),
            const SizedBox(height: 20),
            const Text('إرفعي الصورة هنا (اختياري)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00897B), width: 1.5, style: BorderStyle.solid),
                  color: const Color(0xFFE0F7F4),
                ),
                child: _screenshot != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_screenshot!, fit: BoxFit.cover))
                  : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add_photo_alternate, size: 40, color: const Color(0xFF00897B)),
                      const SizedBox(height: 8),
                      const Text('إضغطي هنا لرفع صورة', style: TextStyle(color: Color(0xFF00897B))),
                    ]),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _sending ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF26C6DA),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _sending
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('إرسال', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, [TextInputType? type, int lines = 1]) {
    return TextField(
      controller: c,
      keyboardType: type,
      maxLines: lines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _dropdown(String label, String? value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
      onChanged: onChanged,
    );
  }
}
```

### قواعد Firestore
```
match /support_requests/{reqId} {
  allow create: if isAuthenticated();
  allow read, update, delete: if isOwnerOrSupervisor();
}
```

### Commit
```
feat(profile): نموذج الدعم الفني الكامل مع رفع صور
```

---

## المرحلة 6 — «قيّم البرنامج» + «انشر البرنامج»

### إضافة في `pubspec.yaml`
```yaml
in_app_review: ^2.0.9
```

### التنفيذ في ProfilePage
```dart
_menuItem('قيّم البرنامج', Icons.star, Colors.amber, () async {
  final review = InAppReview.instance;
  if (await review.isAvailable()) {
    review.requestReview();
  } else {
    // Fallback: افتحي رابط Play Store
    launchUrl(Uri.parse('https://play.google.com/store/apps/details?id=com.nabda.app'));
  }
}),

_menuItem('انشر البرنامج', Icons.share, Colors.blue, () async {
  await Share.share(
    'تطبيق نبضة — رفيقتك في رحلة الأمومة 💖\n\n'
    'حمّليه من Play Store:\n'
    'https://play.google.com/store/apps/details?id=com.nabda.app',
    subject: 'نبضة — صحة المرأة العربية',
  );
}),
```

### Commit
```
feat(profile): زرّا التقييم على Play Store ومشاركة التطبيق
```

---

## المرحلة 7 — «عن التطبيق» (About Screen)

### التنفيذ (شاشة بسيطة)
```dart
class AboutScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('عن التطبيق')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Image.asset('assets/images/logo_nabda_foreground.png', width: 120, height: 120),
            const SizedBox(height: 16),
            const Text('نبضة', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFE91E63))),
            const SizedBox(height: 8),
            const Text('صحة المرأة العربية', style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 24),
            const Text('الإصدار 1.0.0'),
            const SizedBox(height: 32),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'نبضة رفيقتك في رحلة الأمومة، من التخطيط للحمل حتى تربية طفلك، '
                'بمحتوى عربي أصيل ولمسة إسلامية دافئة.\n\n'
                'أكثر من 300 مقال بمراجع طبية موثّقة، متابعة حمل أسبوعية، '
                'دورة شهرية، رعاية طفل، مجتمع أمّهات، ومساعد ذكي بالذكاء الاصطناعي.',
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.6, fontSize: 14),
              ),
            ),
            const SizedBox(height: 32),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('تواصلي معنا'),
              subtitle: const Text('matbakhwalid@gmail.com'),
              onTap: () => launchUrl(Uri.parse('mailto:matbakhwalid@gmail.com')),
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('الموقع'),
              subtitle: const Text('nabda.online'),
              onTap: () => launchUrl(Uri.parse('https://nabda.online')),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('سياسة الخصوصية'),
              onTap: () => launchUrl(Uri.parse('https://nabda.online/privacy')),
            ),
            ListTile(
              leading: const Icon(Icons.article),
              title: const Text('الشروط والأحكام'),
              onTap: () => launchUrl(Uri.parse('https://nabda.online/terms')),
            ),
          ]),
        ),
      ),
    );
  }
}
```

### Commit
```
feat(profile): صفحة «عن التطبيق» مع الروابط الرسمية
```

---

## المرحلة 8 — «التحكم في بياناتي» (Data Control)

### التنفيذ (شاشة شاملة)
```dart
class DataControlScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('التحكم في بياناتي')),
        body: ListView(children: [
          _card('تصدير بياناتي', 'حمّلي نسخة من كل بياناتك بصيغة JSON',
            Icons.download, Colors.blue, _exportData),
          _card('مسح سجلّ المحادثات مع AI', 'حذف تاريخ محادثاتك مع المساعد الذكي',
            Icons.chat_bubble, Colors.orange, _clearAIChat),
          _card('مسح سجلّ البحث', 'حذف كلمات البحث السابقة',
            Icons.search_off, Colors.purple, _clearSearch),
          const Divider(height: 40),
          _card('حذف حسابي نهائياً', 'حذف الحساب مع كل البيانات',
            Icons.delete_forever, Colors.red, _deleteAccount),
        ]),
      ),
    );
  }
  // ... implementation
}
```

### Commit
```
feat(profile): شاشة التحكم في البيانات (تصدير/مسح/حذف)
```

---

## المرحلة 9 — إجراءات المنشور (اخفاء + تفعيل التنبيهات)

### في `post_detail_screen.dart` PopupMenu
```dart
PopupMenuItem(
  value: 'hide',
  child: Row(children: [
    Icon(Icons.visibility_off, color: Colors.grey),
    SizedBox(width: 8),
    Text('اخفاء المنشور'),
  ]),
),
PopupMenuItem(
  value: 'notifications',
  child: Row(children: [
    Icon(Icons.notifications_active, color: Color(0xFFE91E63)),
    SizedBox(width: 8),
    Text('تفعيل التنبيهات على هذا المنشور'),
  ]),
),
```

### دوال الإجراءات
```dart
Future<void> _hidePost() async {
  await FirebaseFirestore.instance
    .collection('users').doc(uid)
    .collection('hidden_posts').doc(widget.postId).set({
      'hiddenAt': FieldValue.serverTimestamp(),
    });
  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('أُخفي المنشور — لن يظهر لكِ مجدّداً')),
  );
}

Future<void> _togglePostNotifications() async {
  final ref = FirebaseFirestore.instance
    .collection('users').doc(uid)
    .collection('post_notifications').doc(widget.postId);
  final doc = await ref.get();
  if (doc.exists) {
    await ref.delete();
  } else {
    await ref.set({'enabledAt': FieldValue.serverTimestamp()});
  }
}
```

### Commit
```
feat(community): اخفاء المنشور + تفعيل التنبيهات لمنشور معيّن
```

---

## المرحلة 10 — تحديث ProfilePage في main.dart

### الوضع الحالي
`ProfilePage` في `main.dart:7577` فيه: تعديل الاسم، اللغة، الإشعارات، الخصوصية، المساعدة، تسجيل الخروج، حذف الحساب.

### التحديث المطلوب

استبدل قسم `_menuItem` بالبنية الجديدة (قسمَان):

```dart
// ═══ القسم 1: النشاط الاجتماعي ═══
_sectionHeader('نشاطي'),
_menuItem('متابعاتي', Icons.people, Colors.blue, 
  () => Navigator.push(context, MaterialPageRoute(builder: (_) => 
    const FollowsScreen(type: 'following', title: 'متابعاتي')))),
_menuItem('المحظورات', Icons.block, Colors.red, 
  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockedUsersScreen()))),
_menuItem('المفضلة', Icons.bookmark, Color(0xFFE91E63), 
  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()))),
_menuItem('منشوراتي', Icons.article, Color(0xFF00897B), 
  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyPostsScreen()))),

const SizedBox(height: 24),
// ═══ القسم 2: أخرى ═══
_sectionHeader('أخرى'),
_menuItem('الدعم الفني', Icons.support_agent, Color(0xFF26C6DA), 
  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen()))),
_menuItem('الإعدادات', Icons.settings, Colors.grey, 
  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
_menuItem('قيّم البرنامج', Icons.star, Colors.amber, _rateApp),
_menuItem('انشر البرنامج', Icons.share, Colors.blue, _shareApp),
_menuItem('عن التطبيق', Icons.info, Colors.purple, 
  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()))),

const SizedBox(height: 24),
// ═══ زر التحكم في البيانات ═══
Container(
  margin: EdgeInsets.symmetric(horizontal: 16),
  child: OutlinedButton.icon(
    icon: Icon(Icons.security, color: Color(0xFF00897B)),
    label: Text('التحكم في بياناتي', 
      style: TextStyle(color: Color(0xFF00897B), fontWeight: FontWeight.bold, fontSize: 16)),
    style: OutlinedButton.styleFrom(
      side: BorderSide(color: Color(0xFF00897B), width: 1.5),
      padding: EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DataControlScreen())),
  ),
),

const SizedBox(height: 12),
// زر تسجيل الخروج (موجود)
// زر حذف الحساب (موجود)
```

### Helper widget
```dart
Widget _sectionHeader(String title) => Padding(
  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
);
```

### Commit
```
feat(profile): إعادة هيكلة صفحة الحساب بقسمَين + 8 عناصر جديدة
```

---

## 📊 قائمة تحقّق نهائية

- [ ] المفضلة تعمل (حفظ + عرض)
- [ ] المحظورات تُعرَض مع إمكانية إلغاء الحظر
- [ ] المتابعات والمتابعين شاشتان تعملان
- [ ] منشوراتي تعرض منشورات المستخدمة
- [ ] الدعم الفني يرسل ويحفظ في Firestore
- [ ] قيّم البرنامج يفتح InAppReview أو Play Store
- [ ] انشر البرنامج يفتح Share sheet
- [ ] عن التطبيق يعرض المعلومات والروابط
- [ ] التحكم في البيانات (تصدير، مسح، حذف)
- [ ] اخفاء المنشور + تنبيهات المنشور
- [ ] ProfilePage جديدة بقسمَين
- [ ] `flutter analyze` = 0 errors
- [ ] `flutter build apk --release` ينجح

---

## ⚠️ ملاحظات مهمّة للمُنفّذ

1. **لا تحذف** الميزات الموجودة (حذف الحساب، تسجيل الخروج، إعادة تعيين البيانات)
2. **رابط Play Store** (`com.nabda.app`) استعمليه في `_rateApp` و`_shareApp` — بعد النشر الفعلي سنحدّثه
3. **رفع الصور** في «الدعم الفني» يحتاج قاعدة Firebase Storage للسماح بالكتابة للمصادَق
4. **`admin_panel_screen.dart` خطر الاقتطاع** — إذا احتجت تعديله، استعمل Python + read all → modify → cp
5. بعد كل مرحلة: `flutter analyze` + commit منفصل برسالة عربية

---

## 🎨 التصميم

استعمل نفس ألوان نبضة (`#E91E63` وردي، `#00897B` تيل، `#FFF8FB` كريمي) وخط Almarai. حاول أن تظهر البطاقات والأزرار بشكل مطابق للـ Home Page الحالي (rounded corners 20-24px، shadow خفيف).

---

*هذا الملف self-contained — يمكن نسخه كاملاً لـ Antigravity كـ initial prompt.*
