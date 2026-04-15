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
      if (user \!= null) {
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
      throw Exception('خطأ في التسجيل: ${e.message}');
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
      if (user \!= null) {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          return UserModel.fromJson(userDoc.data() as Map<String, dynamic>);
        }
      }
    } on FirebaseAuthException catch (e) {
      throw Exception('خطأ في تسجيل الدخول: ${e.message}');
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
    required String uid,
    String? name,
    String? avatar,
    String? language,
    String? mode,
  }) async {
    try {
      final updateData = <String, dynamic>{
        if (name \!= null) 'name': name,
        if (avatar \!= null) 'avatar': avatar,
        if (language \!= null) 'language': language,
        if (mode \!= null) 'mode': mode,
        'updatedAt': DateTime.now(),
      };

      await _firestore.collection('users').doc(uid).update(updateData);
    } catch (e) {
      throw Exception('خطأ في تحديث البيانات: $e');
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
