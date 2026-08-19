import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ═══════════════════════════════════════════════════════════════════
///  المصدر الوحيد لتواريخ الحمل — يمنع اختلاف الأسبوع بين الشاشات
///
///  الحقول المعتمدة في Firestore (users/{uid}):
///   • pregnancyStartDate : Timestamp — أول يوم من آخر دورة (LMP)
///   • dueDate            : Timestamp — تاريخ الولادة المتوقّع
///   • dueDateSource      : String    — doctor / ultrasound / lmp / other
///
///  قاعدة الحساب: إن وُجد dueDate فهو المرجع (لأنه غالباً من الطبيبة
///  أو السونار وأدقّ)، وإلا يُحسب من LMP + 280 يوماً.
/// ═══════════════════════════════════════════════════════════════════
class PregnancyDates {
  final DateTime? lmp;
  final DateTime? dueDate;
  final String dueDateSource;

  const PregnancyDates({this.lmp, this.dueDate, this.dueDateSource = ''});

  static const int totalDays = 280; // 40 أسبوعاً

  bool get isActive => dueDate != null || lmp != null;

  /// تاريخ الولادة المتوقّع (محسوب إن لم يكن محفوظاً)
  DateTime? get effectiveDueDate =>
      dueDate ?? (lmp != null ? lmp!.add(const Duration(days: totalDays)) : null);

  /// بداية الحمل الفعلية (LMP) — تُشتقّ من تاريخ الولادة إن لزم
  DateTime? get effectiveStart =>
      lmp ?? (dueDate != null ? dueDate!.subtract(const Duration(days: totalDays)) : null);

  /// عدد الأيام منذ بداية الحمل
  int get daysPregnant {
    final s = effectiveStart;
    if (s == null) return 0;
    return DateTime.now().difference(s).inDays;
  }

  /// الأسبوع الحالي (1..42)
  int get week {
    if (!isActive) return 0;
    final w = (daysPregnant / 7).floor();
    return w.clamp(1, 42);
  }

  /// اليوم داخل الأسبوع (0..6)
  int get dayOfWeek => daysPregnant % 7;

  /// الأيام المتبقّية للولادة (قد تكون سالبة بعد الموعد)
  int get daysLeft {
    final d = effectiveDueDate;
    if (d == null) return 0;
    return d.difference(DateTime.now()).inDays;
  }

  double get progress => (daysPregnant / totalDays).clamp(0.0, 1.0);

  int get trimester => week <= 13 ? 1 : (week <= 27 ? 2 : 3);

  String get sourceLabel => sourceLabelOf(dueDateSource);

  static String sourceLabelOf(String key) {
    switch (key) {
      case 'doctor':
        return 'الطبيبة المتابعة';
      case 'ultrasound':
        return 'السونار / الإيكو';
      case 'lmp':
        return 'حساب آخر دورة';
      case 'other':
        return 'مصدر آخر';
      default:
        return '';
    }
  }

  static const List<MapEntry<String, String>> sources = [
    MapEntry('doctor', 'الطبيبة المتابعة'),
    MapEntry('ultrasound', 'السونار / الإيكو'),
    MapEntry('lmp', 'حساب آخر دورة'),
    MapEntry('other', 'مصدر آخر'),
  ];

  // ── القراءة ──────────────────────────────────────────────────
  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }

  /// يقرأ التواريخ من مستند المستخدمة (يتحمّل الحقول القديمة)
  static PregnancyDates fromUserData(Map<String, dynamic> d) {
    final lmp = _toDate(d['pregnancyStartDate']) ??
        _toDate(d['pregnancyStart']) ??
        _toDate(d['lastPeriodDate']);
    final due = _toDate(d['dueDate']);
    return PregnancyDates(
      lmp: lmp,
      dueDate: due,
      dueDateSource: (d['dueDateSource'] as String?) ?? '',
    );
  }

  static DocumentReference<Map<String, dynamic>>? get _userDoc {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(u.uid);
  }

  static Future<PregnancyDates> load() async {
    final ref = _userDoc;
    if (ref == null) return const PregnancyDates();
    try {
      final snap = await ref.get();
      return fromUserData(snap.data() ?? {});
    } catch (_) {
      return const PregnancyDates();
    }
  }

  // ── الحفظ ────────────────────────────────────────────────────
  /// يحفظ تاريخ الولادة المتوقّع ومصدره، ويُحدّث LMP ليبقى الجميع متّسقاً.
  /// يُزيل الحقول القديمة المتعارضة (pregnancyWeek، lastPeriodDate النصّي).
  static Future<void> saveDueDate(DateTime due, String source) async {
    final ref = _userDoc;
    if (ref == null) return;
    final lmp = due.subtract(const Duration(days: totalDays));
    await ref.set({
      'dueDate': Timestamp.fromDate(due),
      'dueDateSource': source,
      'pregnancyStartDate': Timestamp.fromDate(lmp),
      'pregnancyWeek': FieldValue.delete(),
      'lastPeriodDate': FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  /// يحفظ تاريخ آخر دورة ويحسب منه تاريخ الولادة
  static Future<void> saveLmp(DateTime lmp) async {
    final ref = _userDoc;
    if (ref == null) return;
    final due = lmp.add(const Duration(days: totalDays));
    await ref.set({
      'pregnancyStartDate': Timestamp.fromDate(lmp),
      'dueDate': Timestamp.fromDate(due),
      'dueDateSource': 'lmp',
      'pregnancyWeek': FieldValue.delete(),
      'lastPeriodDate': FieldValue.delete(),
    }, SetOptions(merge: true));
  }
}
