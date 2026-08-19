import 'package:cloud_firestore/cloud_firestore.dart';

class CohortService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// اشتقاق مفتاح الفوج تلقائياً بناءً على حالة المستخدمة
  String? deriveCohortKey({
    required String status,
    DateTime? pregnancyStartDate,
    DateTime? babyBirthDate,
    DateTime? dueDate,
  }) {
    // ① طفل مولود → نادي شهر الميلاد
    if (babyBirthDate != null && (status == 'baby' || status == 'mother')) {
      final monthStr = babyBirthDate.month.toString().padLeft(2, '0');
      return 'born_${babyBirthDate.year}_$monthStr';
    }
    // ② حامل → نادي شهر الولادة المتوقّع
    //    نعتمد تاريخ الولادة المحفوظ إن وُجد (أدقّ)، وإلا LMP + 280 يوماً.
    //    لا نشترط status لأن بعض الحسابات القديمة لا تحمل lifeStage.
    final edd = dueDate ??
        (pregnancyStartDate != null
            ? pregnancyStartDate.add(const Duration(days: 280))
            : null);
    if (edd != null) {
      final monthStr = edd.month.toString().padLeft(2, '0');
      return 'due_${edd.year}_$monthStr';
    }
    if (babyBirthDate != null) {
      final monthStr = babyBirthDate.month.toString().padLeft(2, '0');
      return 'born_${babyBirthDate.year}_$monthStr';
    }
    return null;
  }

  /// اسم النادي بالعربية من مفتاحه — مثال: «مواليد جانفي 2027»
  static const List<String> monthsAr = [
    '', 'جانفي', 'فيفري', 'مارس', 'أفريل', 'ماي', 'جوان',
    'جويلية', 'أوت', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
  ];

  static String labelForKey(String key) {
    final p = key.split('_');
    if (p.length < 3) return 'نادي الولادة';
    final year = p[1];
    final m = int.tryParse(p[2]) ?? 0;
    final month = (m >= 1 && m <= 12) ? monthsAr[m] : '';
    return p[0] == 'born'
        ? 'مواليد $month $year'
        : 'مواليد $month $year';
  }

  /// قائمة أندية متاحة للتصفّح حول شهر معيّن (±[span] شهراً)
  static List<String> nearbyKeys(String centerKey, {int span = 6}) {
    final p = centerKey.split('_');
    if (p.length < 3) return const [];
    final prefix = p[0];
    final year = int.tryParse(p[1]) ?? DateTime.now().year;
    final month = int.tryParse(p[2]) ?? DateTime.now().month;
    final center = DateTime(year, month);
    final out = <String>[];
    for (var i = -span; i <= span; i++) {
      final d = DateTime(center.year, center.month + i);
      out.add('${prefix}_${d.year}_${d.month.toString().padLeft(2, '0')}');
    }
    return out;
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
