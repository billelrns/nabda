import 'package:cloud_firestore/cloud_firestore.dart';

class CohortService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// اشتقاق مفتاح الفوج تلقائياً بناءً على حالة المستخدمة
  String? deriveCohortKey({
    required String status,
    DateTime? pregnancyStartDate,
    DateTime? babyBirthDate,
  }) {
    if (status == 'pregnant' && pregnancyStartDate != null) {
      final edd = pregnancyStartDate.add(const Duration(days: 280));
      final monthStr = edd.month.toString().padLeft(2, '0');
      return 'due_${edd.year}_$monthStr';
    } else if ((status == 'baby' || status == 'mother') && babyBirthDate != null) {
      final monthStr = babyBirthDate.month.toString().padLeft(2, '0');
      return 'born_${babyBirthDate.year}_$monthStr';
    }
    return null;
  }

  /// مزامنة فوج المستخدمة مع تحديث عداد الأعضاء بشكل تزامني آمن
  Future<void> syncUserCohort(String uid, String? newCohortKey) async {
    final userRef = _db.collection('users').doc(uid);

    await _db.runTransaction((transaction) async {
      final userSnap = await transaction.get(userRef);
      if (!userSnap.exists) return;

      final oldCohortKey = userSnap.data()?['cohortKey'] as String?;
      if (oldCohortKey == newCohortKey) return; // لا يوجد تغيير

      // 1. تحديث حقل الفوج في وثيقة المستخدم
      transaction.update(userRef, {
        'cohortKey': newCohortKey,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. إنقاص عداد الأعضاء للفوج القديم إن وجد
      if (oldCohortKey != null && oldCohortKey.isNotEmpty) {
        final oldCounterRef = _db.collection('cohort_members_count').doc(oldCohortKey);
        transaction.set(oldCounterRef, {
          'memberCount': FieldValue.increment(-1),
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // 3. زيادة عداد الأعضاء للفوج الجديد إن وجد
      if (newCohortKey != null && newCohortKey.isNotEmpty) {
        final newCounterRef = _db.collection('cohort_members_count').doc(newCohortKey);
        transaction.set(newCounterRef, {
          'memberCount': FieldValue.increment(1),
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });
  }
}
