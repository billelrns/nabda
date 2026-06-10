import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        // أرسل بريد التحقق فور إنشاء الحساب
        await user.sendEmailVerification();

        final userModel = UserModel(
          id: user.uid,
          name: name,
          email: email,
          language: 'ar',
          mode: 'cycle',
          createdAt: DateTime.now(),
        );

        await _firestore.collection('users').doc(user.uid).set(
              userModel.toJson(),
            );

        return userModel;
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw Exception('هذا البريد الإلكتروني مستخدم بالفعل');
        case 'weak-password':
          throw Exception('كلمة المرور ضعيفة جداً');
        case 'invalid-email':
          throw Exception('صيغة البريد الإلكتروني غير صحيحة');
        default:
          throw Exception('حدث خطأ في إنشاء الحساب، يرجى المحاولة لاحقاً');
      }
    }
    return null;
  }

  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          return UserModel.fromJson(userDoc.data() as Map<String, dynamic>);
        }
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
        case 'invalid-email':
          throw Exception('البريد الإلكتروني أو كلمة المرور غير صحيحة');
        case 'user-disabled':
          throw Exception('هذا الحساب موقوف، يرجى التواصل مع الدعم');
        case 'too-many-requests':
          throw Exception('محاولات كثيرة، يرجى الانتظار قليلاً ثم المحاولة مجدداً');
        default:
          throw Exception('حدث خطأ، يرجى المحاولة لاحقاً');
      }
    }
    return null;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<UserModel?> getCurrentUser(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return UserModel.fromJson(userDoc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      throw Exception('خطأ في الحصول على بيانات المستخدم: $e');
    }
    return null;
  }

  Future<void> updateUserProfile({
    String? name,
    String? avatar,
    String? language,
    String? mode,
  }) async {
    // استخدم uid المستخدم الحالي فقط — لا نقبل uid من الخارج
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('يجب تسجيل الدخول أولاً');

    try {
      final updateData = <String, dynamic>{
        if (name != null) 'name': name,
        if (avatar != null) 'avatar': avatar,
        if (language != null) 'language': language,
        if (mode != null) 'mode': mode,
        'updatedAt': DateTime.now(),
      };

      await _firestore.collection('users').doc(uid).update(updateData);
    } catch (e) {
      throw Exception('خطأ في تحديث البيانات، يرجى المحاولة لاحقاً');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('خطأ في إعادة تعيين كلمة المرور: $e');
    }
  }
}






