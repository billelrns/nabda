import 'dart:convert';

/// نموذج بيانات أيام القضاء لكل سنة هجرية/ميلادية
class QadaaYearData {
  final int year; // السنة الميلادية (مثلاً 2026)
  final int hijriYear; // السنة الهجرية (مثلاً 1447)
  final List<int> missedDays; // أرقام أيام رمضان التي أفطرت فيها (1..30)
  final List<int> completedDays; // أرقام الأيام التي تم قضاؤها بالفعل
  final DateTime updatedAt;

  QadaaYearData({
    required this.year,
    required this.hijriYear,
    required this.missedDays,
    required this.completedDays,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  int get totalMissed => missedDays.length;
  int get totalCompleted => completedDays.where((d) => missedDays.contains(d)).length;
  int get remainingDays => totalMissed - totalCompleted;
  bool get isAllCompleted => totalMissed > 0 && remainingDays == 0;
  double get progressPercent => totalMissed == 0 ? 0.0 : (totalCompleted / totalMissed).clamp(0.0, 1.0);

  String get titleAr => 'رمضان ($hijriYear - $year)';

  QadaaYearData copyWith({
    int? year,
    int? hijriYear,
    List<int>? missedDays,
    List<int>? completedDays,
    DateTime? updatedAt,
  }) {
    return QadaaYearData(
      year: year ?? this.year,
      hijriYear: hijriYear ?? this.hijriYear,
      missedDays: missedDays ?? List<int>.from(this.missedDays),
      completedDays: completedDays ?? List<int>.from(this.completedDays),
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'year': year,
      'hijriYear': hijriYear,
      'missedDays': missedDays,
      'completedDays': completedDays,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory QadaaYearData.fromMap(Map<String, dynamic> map) {
    return QadaaYearData(
      year: (map['year'] as num?)?.toInt() ?? 2026,
      hijriYear: (map['hijriYear'] as num?)?.toInt() ?? 1447,
      missedDays: (map['missedDays'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
      completedDays: (map['completedDays'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory QadaaYearData.fromJson(String source) =>
      QadaaYearData.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

/// معلومات توقيت شهر رمضان لكل سنة
class RamadanYearInfo {
  final int year;
  final int hijriYear;
  final String titleAr;
  final int startWeekday; // 1 = Monday, 6 = Saturday, 7 = Sunday
  final int totalRamadanDays; // 29 أو 30

  const RamadanYearInfo({
    required this.year,
    required this.hijriYear,
    required this.titleAr,
    required this.startWeekday,
    this.totalRamadanDays = 30,
  });

  /// إزاحة اليوم في الأسبوع بالترتيب العربي (السبت = 0 ... الجمعة = 6)
  int get arabicWeekdayOffset {
    // startWeekday: 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat, 7=Sun
    // Arabic order: السبت(0), الأحد(1), الاثنين(2), الثلاثاء(3), الأربعاء(4), الخميس(5), الجمعة(6)
    switch (startWeekday) {
      case 6: // Sat
        return 0;
      case 7: // Sun
        return 1;
      case 1: // Mon
        return 2;
      case 2: // Tue
        return 3;
      case 3: // Wed (مثل رمضان 1447 / 2026)
        return 4;
      case 4: // Thu
        return 5;
      case 5: // Fri
        return 6;
      default:
        return 0;
    }
  }
}
