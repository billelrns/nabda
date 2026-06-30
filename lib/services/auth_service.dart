import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      'termsAccepted': true,
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
    } catch (e) {
      throw Exception('خطأ في الحصول على بيانات المستخدم: $e');
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
