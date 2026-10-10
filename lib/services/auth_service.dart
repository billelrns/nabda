import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';

/// مصادقة نبضة: بريد + كلمة مرور، ودخول اجتماعي (Google / Facebook / Apple)
/// عبر Firebase Auth حصرًا. لا دخول بالهاتف. الويب عبر signInWithPopup،
/// الموبايل عبر signInWithProvider — بلا حزم إضافية.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// هل المُدخَل بريد إلكتروني؟
  static bool isEmail(String input) => input.contains('@');

  // ===========================================================================
  // البريد + كلمة المرور
  // ===========================================================================

  Future<UserModel?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final mail = email.trim().toLowerCase();
      final cred = await _auth.createUserWithEmailAndPassword(
        email: mail,
        password: password,
      );
      final user = cred.user;
      if (user == null) return null;

      try {
        await user.sendEmailVerification();
      } catch (_) {}

      final userModel = UserModel(
        id: user.uid,
        name: name,
        email: mail,
        language: 'ar',
        mode: 'cycle',
        createdAt: DateTime.now(),
      );
      await _firestore.collection('users').doc(user.uid).set({
        ...userModel.toJson(),
        'provider': 'email',
      });
      return userModel;
    } on FirebaseAuthException catch (e) {
      throw Exception(_emailErrorAr(e.code));
    }
  }

  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      final user = cred.user;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          return UserModel.fromJson(doc.data() as Map<String, dynamic>);
        }
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_emailErrorAr(e.code));
    }
    return null;
  }

  /// إعادة تعيين كلمة المرور (للبريد فقط).
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
  }

  // ===========================================================================
  // حذف الحساب (مطلوب لسياسات المتاجر — شاشة التحكّم بالبيانات)
  // ===========================================================================

  /// يحذف بيانات المستخدمة من Firestore ثم يحذف حساب المصادقة.
  /// [recentPassword] كلمة المرور الحالية — يُعاد بها التوثيق قبل الحذف،
  /// لأن Firebase يشترط تسجيل دخول حديثاً للعمليات الحسّاسة.
  Future<void> deleteAccount({String? recentPassword}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;

    final providers = user.providerData.map((p) => p.providerId).toList();
    final isPasswordUser = providers.contains('password');

    // ⓪ إعادة التوثيق (بكلمة المرور أو بالمزوّد الاجتماعي)
    if (isPasswordUser) {
      if (recentPassword != null && recentPassword.isNotEmpty) {
        final email = user.email;
        if (email != null && email.isNotEmpty) {
          try {
            await user.reauthenticateWithCredential(
              EmailAuthProvider.credential(email: email, password: recentPassword),
            );
          } on FirebaseAuthException catch (e) {
            if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
              throw Exception('كلمة المرور غير صحيحة');
            }
            if (e.code == 'requires-recent-login') {
              throw Exception('انتهت صلاحية جلستك — سجّلي الخروج ثم الدخول وأعيدي المحاولة');
            }
            rethrow;
          }
        }
      }
    } else {
      final pid = providers.firstWhere((p) => p != 'password', orElse: () => '');
      try {
        if (pid == 'google.com') {
          await user.reauthenticateWithProvider(GoogleAuthProvider());
        } else if (pid == 'facebook.com') {
          await user.reauthenticateWithProvider(FacebookAuthProvider());
        } else if (pid == 'apple.com') {
          await user.reauthenticateWithProvider(AppleAuthProvider());
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          throw Exception('انتهت صلاحية جلستك — سجّلي الخروج ثم الدخول وأعيدي المحاولة');
        }
        rethrow;
      }
    }

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

    // ③-ب صورة الملف الشخصي في Storage — سياسة الخصوصية وإقرار Data Safety
    // يَعِدان بحذف كل البيانات، والصورة منها. غيابها (object-not-found)
    // طبيعي لمن لم ترفع صورة، فلا يُعدّ فشلاً.
    try {
      await FirebaseStorage.instance.ref('profile_photos/$uid.jpg').delete();
    } catch (_) {}
    try {
      final att = await FirebaseStorage.instance
          .ref('support_attachments/$uid').listAll();
      for (final f in att.items) { await f.delete(); }
    } catch (_) {}

    // ④ الدليل العام ثم الوثيقة الأم
    try { await db.collection('users_directory').doc(uid).delete(); } catch (_) {}
    await db.collection('users').doc(uid).delete();

    // ⑤ أخيراً: حساب المصادقة
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception('انتهت صلاحية جلستك — سجّلي الخروج ثم الدخول وأعيدي المحاولة');
      }
      rethrow;
    }
  }

  // ===========================================================================
  // الدخول الاجتماعي
  // ===========================================================================

  Future<UserCredential> signInWithGoogle() =>
      _social(GoogleAuthProvider(), 'google');

  Future<UserCredential> signInWithFacebook() =>
      _social(FacebookAuthProvider(), 'facebook');

  Future<UserCredential> signInWithApple() {
    final provider = OAuthProvider('apple.com')
      ..addScope('email')
      ..addScope('name');
    return _social(provider, 'apple');
  }

  /// يشغّل تدفّق المزوّد (popup على الويب، native على الموبايل) ثم يضمن وثيقة المستخدمة.
  Future<UserCredential> _social(AuthProvider provider, String name) async {
    final cred = kIsWeb
        ? await _auth.signInWithPopup(provider)
        : await _auth.signInWithProvider(provider);
    final user = cred.user;
    if (user != null) await _ensureUserDoc(user, name);
    return cred;
  }

  /// تُنشئ `users/{uid}` فقط إن لم تكن موجودة (لا تُتلف بيانات دخول سابق).
  /// بلا lifeStage → AuthGate يوجّه المستخدمة الجديدة إلى onboarding.
  Future<void> _ensureUserDoc(User user, String provider) async {
    final ref = _firestore.collection('users').doc(user.uid);
    final snap = await ref.get();
    if (snap.exists) return;
    await ref.set({
      'name': user.displayName ?? '',
      'displayName': user.displayName ?? '',
      'email': user.email ?? '',
      'avatar': user.photoURL ?? '',
      'provider': provider,
      'language': 'ar',
      'mode': 'cycle',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      // الموافقة تُعطى بسطر «بمتابعتك تُوافقين…» تحت أزرار الدخول الاجتماعي
      // في شاشة الدخول؛ نسجّل وقتها ومصدرها بدل قيمة منطقية مجرّدة.
      'termsAccepted': true,
      'termsAcceptedVia': 'social_signin_notice',
      'termsAcceptedAt': FieldValue.serverTimestamp(),
      'cycleLength': 28,
      'lastPeriodStart': null,
      'pregnancyStartDate': null,
      'babyName': '',
      'babyBirthDate': null,
    });
  }

  // ===========================================================================
  // عام
  // ===========================================================================

  Future<void> logout() => _auth.signOut();

  Future<UserModel?> getCurrentUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }
    } catch (_) {
      throw Exception('تعذّر تحميل بياناتك — تحقّقي من الاتصال');
    }
    return null;
  }

  Future<void> updateUserProfile({
    String? uid, // اختياري للتوافق الرجعي — يُتجاهَل ونستعمل currentUser
    String? name,
    String? avatar,
    String? language,
    String? mode,
  }) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) throw Exception('يجب تسجيل الدخول أولاً');
    try {
      final updateData = <String, dynamic>{
        if (name != null) 'name': name,
        if (avatar != null) 'avatar': avatar,
        if (language != null) 'language': language,
        if (mode != null) 'mode': mode,
        'updatedAt': DateTime.now(),
      };
      await _firestore.collection('users').doc(currentUid).update(updateData);
    } catch (e) {
      throw Exception('خطأ في تحديث البيانات، يرجى المحاولة لاحقاً');
    }
  }

  String _emailErrorAr(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'هذا البريد مستخدم بالفعل';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً (6 أحرف على الأقل)';
      case 'invalid-email':
        return 'صيغة البريد غير صحيحة';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'البريد أو كلمة المرور غير صحيحة';
      case 'user-disabled':
        return 'هذا الحساب موقوف، يرجى التواصل مع الدعم';
      case 'too-many-requests':
        return 'محاولات كثيرة، يرجى الانتظار قليلاً ثم المحاولة مجدداً';
      default:
        return 'حدث خطأ، يرجى المحاولة لاحقاً';
    }
  }
}
