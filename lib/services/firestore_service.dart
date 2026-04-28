import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cycle_model.dart';
import '../models/pregnancy_model.dart';
import '../models/baby_model.dart';
import '../models/community_post_model.dart';
import '../models/message_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cycle operations
  Future<void> addCycle(CycleModel cycle) async {
    try {
      await _firestore.collection('cycles').doc(cycle.id).set(cycle.toJson());
    } catch (e) {
      throw Exception('خطأ في حفظ دورة: $e');
    }
  }

  Future<void> updateCycle(CycleModel cycle) async {
    try {
      await _firestore
          .collection('cycles')
          .doc(cycle.id)
          .update(cycle.toJson());
    } catch (e) {
      throw Exception('خطأ في تحديث الدورة: $e');
    }
  }

  Future<void> deleteCycle(String cycleId) async {
    try {
      await _firestore.collection('cycles').doc(cycleId).delete();
    } catch (e) {
      throw Exception('خطأ في حذف الدورة: $e');
    }
  }

  Stream<List<CycleModel>> getUserCycles(String userId) {
    return _firestore
        .collection('cycles')
        .where('userId', isEqualTo: userId)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CycleModel.fromJson(doc.data()))
          .toList();
    });
  }

  // Pregnancy operations
  Future<void> addPregnancy(PregnancyModel pregnancy) async {
    try {
      await _firestore
          .collection('pregnancies')
          .doc(pregnancy.id)
          .set(pregnancy.toJson());
    } catch (e) {
      throw Exception('خطأ في حفظ الحمل: $e');
    }
  }

  Future<void> updatePregnancy(PregnancyModel pregnancy) async {
    try {
      await _firestore
          .collection('pregnancies')
          .doc(pregnancy.id)
          .update(pregnancy.toJson());
    } catch (e) {
      throw Exception('خطأ في تحديث الحمل: $e');
    }
  }

  Future<PregnancyModel?> getUserPregnancy(String userId) async {
    try {
      final query = await _firestore
          .collection('pregnancies')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return PregnancyModel.fromJson(query.docs.first.data());
      }
    } catch (e) {
      throw Exception('خطأ في جلب الحمل: $e');
    }
    return null;
  }

  // Baby operations
  Future<void> addBaby(BabyModel baby) async {
    try {
      await _firestore.collection('babies').doc(baby.id).set(baby.toJson());
    } catch (e) {
      throw Exception('خطأ في حفظ البيانات: $e');
    }
  }

  Future<void> updateBaby(BabyModel baby) async {
    try {
      await _firestore
          .collection('babies')
          .doc(baby.id)
          .update(baby.toJson());
    } catch (e) {
      throw Exception('خطأ في تحديث البيانات: $e');
    }
  }

  Stream<List<BabyModel>> getUserBabies(String userId) {
    return _firestore
        .collection('babies')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => BabyModel.fromJson(doc.data())).toList();
    });
  }

  // Community Post operations
  Future<void> addPost(CommunityPostModel post) async {
    try {
      await _firestore.collection('community_posts').doc(post.id).set(post.toJson());
    } catch (e) {
      throw Exception('خطأ في حفظ المنشور: $e');
    }
  }

  Stream<List<CommunityPostModel>> getPosts({String? category}) {
    Query query = _firestore
        .collection('community_posts')
        .orderBy('createdAt', descending: true);

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => CommunityPostModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Stream<CommunityPostModel?> getPost(String postId) {
    return _firestore
        .collection('community_posts')
        .doc(postId)
        .snapshots()
        .map((doc) => doc.exists
            ? CommunityPostModel.fromJson(doc.data() as Map<String, dynamic>)
            : null);
  }

  Future<void> toggleLike(String postId, String userId) async {
    try {
      final postRef = _firestore.collection('community_posts').doc(postId);
      final postDoc = await postRef.get();
      final likedBy = List<String>.from(postDoc.data()?['likedBy'] ?? []);

      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
        await postRef.update({
          'likes': FieldValue.increment(-1),
          'likedBy': likedBy,
        });
      } else {
        likedBy.add(userId);
        await postRef.update({
          'likes': FieldValue.increment(1),
          'likedBy': likedBy,
        });
      }
    } catch (e) {
      throw Exception('خطأ في الإعجاب: $e');
    }
  }

  Future<void> addComment(String postId, Map<String, dynamic> comment) async {
    try {
      await _firestore.collection('community_posts').doc(postId).update({
        'comments': FieldValue.arrayUnion([comment]),
      });
    } catch (e) {
      throw Exception('خطأ في إضافة التعليق: $e');
    }
  }

  // Message operations
  Future<void> addMessage(MessageModel message) async {
    try {
      await _firestore
          .collection('messages')
          .doc(message.id)
          .set(message.toJson());
    } catch (e) {
      throw Exception('خطأ في حفظ الرسالة: $e');
    }
  }

  Stream<List<MessageModel>> getUserMessages(String userId) {
    return _firestore
        .collection('messages')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromJson(doc.data()))
          .toList();
    });
  }
}






