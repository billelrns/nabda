import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/qadaa_model.dart';

/// خدمة إدارة وتخزين ومزامنة أيام القضاء لشهر رمضان المبارك
class QadaaService extends ChangeNotifier {
  static final QadaaService instance = QadaaService._internal();
  QadaaService._internal();

  static const String _prefsKey = 'nabda_qadaa_data_v1';
  final Map<int, QadaaYearData> _yearsData = {};
  bool _isInitialized = false;

  /// جدول توقيت شهر رمضان لسنوات متعددة
  static const List<RamadanYearInfo> supportedRamadanYears = [
    RamadanYearInfo(
      year: 2027,
      hijriYear: 1448,
      titleAr: 'رمضان (1448 - 2027)',
      startWeekday: 7, // Sunday
      totalRamadanDays: 30,
    ),
    RamadanYearInfo(
      year: 2026,
      hijriYear: 1447,
      titleAr: 'رمضان (1447 - 2026)',
      startWeekday: 3, // Wednesday (الأربعاء - مطابق للصور)
      totalRamadanDays: 30,
    ),
    RamadanYearInfo(
      year: 2025,
      hijriYear: 1446,
      titleAr: 'رمضان (1446 - 2025)',
      startWeekday: 6, // Saturday (السبت)
      totalRamadanDays: 30,
    ),
    RamadanYearInfo(
      year: 2024,
      hijriYear: 1445,
      titleAr: 'رمضان (1445 - 2024)',
      startWeekday: 1, // Monday (الاثنين)
      totalRamadanDays: 30,
    ),
    RamadanYearInfo(
      year: 2023,
      hijriYear: 1444,
      titleAr: 'رمضان (1444 - 2023)',
      startWeekday: 4, // Thursday (الخميس)
      totalRamadanDays: 29,
    ),
  ];

  static RamadanYearInfo getYearInfo(int year) {
    return supportedRamadanYears.firstWhere(
      (y) => y.year == year,
      orElse: () => RamadanYearInfo(
        year: year,
        hijriYear: year - 579,
        titleAr: 'رمضان (${year - 579} - $year)',
        startWeekday: 3,
        totalRamadanDays: 30,
      ),
    );
  }

  static RamadanYearInfo get defaultYearInfo {
    // السنة الافتراضية الأقرب
    final nowYear = DateTime.now().year;
    return supportedRamadanYears.firstWhere(
      (y) => y.year == nowYear,
      orElse: () => supportedRamadanYears[1], // 2026 - 1447
    );
  }

  bool get isInitialized => _isInitialized;

  /// تهيئة الخدمة وتحميل البيانات من التخزين المحلي والسحابي
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getString(_prefsKey);
      if (localJson != null && localJson.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(localJson);
        _yearsData.clear();
        decoded.forEach((key, value) {
          final year = int.tryParse(key);
          if (year != null && value is Map<String, dynamic>) {
            _yearsData[year] = QadaaYearData.fromMap(value);
          }
        });
      }

      // محاولة المزامنة السحابية الصامتة
      _syncFromFirestore();

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('QadaaService init error: $e');
      _isInitialized = true;
    }
  }

  /// جميع السنوات التي تم تسجيل أيام قضاء فيها
  List<QadaaYearData> get activeYears {
    final list = _yearsData.values.where((y) => y.missedDays.isNotEmpty).toList();
    list.sort((a, b) => b.year.compareTo(a.year)); // الأحدث أولاً
    return list;
  }

  bool get hasAnyDaysTracked => activeYears.isNotEmpty;

  /// إجمالي الأيام المتبقية للقضاء عبر جميع السنوات
  int get totalRemainingDays {
    return activeYears.fold<int>(0, (acc, y) => acc + y.remainingDays);
  }

  /// إجمالي الأيام المفطرة عبر جميع السنوات
  int get totalMissedDays {
    return activeYears.fold<int>(0, (acc, y) => acc + y.totalMissed);
  }

  /// إجمالي الأيام التي تم قضاؤها
  int get totalCompletedDays {
    return activeYears.fold<int>(0, (acc, y) => acc + y.totalCompleted);
  }

  /// الحصول على بيانات سنة معينة
  QadaaYearData? getYearData(int year) => _yearsData[year];

  /// حفظ أو تعديل أيام القضاء المفطرة لسنة معينة
  Future<void> saveMissedDays(int year, List<int> missedDays) async {
    final sortedMissed = List<int>.from(missedDays)..sort();
    final info = getYearInfo(year);
    final existing = _yearsData[year];

    // الإبقاء على الأيام المقضية المتبقية إذا كانت ما تزال ضمن الأيام المفطرة
    final completedDays = existing != null
        ? existing.completedDays.where((d) => sortedMissed.contains(d)).toList()
        : <int>[];

    final updated = QadaaYearData(
      year: year,
      hijriYear: info.hijriYear,
      missedDays: sortedMissed,
      completedDays: completedDays,
      updatedAt: DateTime.now(),
    );

    if (sortedMissed.isEmpty) {
      _yearsData.remove(year);
    } else {
      _yearsData[year] = updated;
    }

    await _saveLocallyAndCloud(year, updated);
    notifyListeners();
  }

  /// تبديل حالة قضاء يوم معين (تم قضاؤه أو لم يُقضَ بعد)
  Future<void> toggleDayCompleted(int year, int dayNumber) async {
    final existing = _yearsData[year];
    if (existing == null) return;

    final completed = List<int>.from(existing.completedDays);
    if (completed.contains(dayNumber)) {
      completed.remove(dayNumber);
    } else {
      completed.add(dayNumber);
    }
    completed.sort();

    final updated = existing.copyWith(
      completedDays: completed,
      updatedAt: DateTime.now(),
    );

    _yearsData[year] = updated;
    await _saveLocallyAndCloud(year, updated);
    notifyListeners();
  }

  /// حذف بيانات سنة معينة
  Future<void> deleteYear(int year) async {
    _yearsData.remove(year);
    await _saveLocallyAndCloud(year, null);
    notifyListeners();
  }

  // ── التخزين والمزامنة ──
  Future<void> _saveLocallyAndCloud(int year, QadaaYearData? data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapToSave = _yearsData.map((k, v) => MapEntry(k.toString(), v.toMap()));
      await prefs.setString(_prefsKey, jsonEncode(mapToSave));

      // مزامنة Firestore
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && uid.isNotEmpty) {
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('qadaa_days')
            .doc(year.toString());

        if (data != null && data.missedDays.isNotEmpty) {
          await docRef.set(data.toMap(), SetOptions(merge: true));
        } else {
          await docRef.delete();
        }
      }
    } catch (e) {
      debugPrint('QadaaService save error: $e');
    }
  }

  Future<void> _syncFromFirestore() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || uid.isEmpty) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('qadaa_days')
          .get();

      if (snapshot.docs.isNotEmpty) {
        bool changed = false;
        for (var doc in snapshot.docs) {
          final year = int.tryParse(doc.id);
          if (year != null) {
            final cloudData = QadaaYearData.fromMap(doc.data());
            final localData = _yearsData[year];
            if (localData == null ||
                cloudData.updatedAt.isAfter(localData.updatedAt)) {
              _yearsData[year] = cloudData;
              changed = true;
            }
          }
        }
        if (changed) {
          final prefs = await SharedPreferences.getInstance();
          final mapToSave =
              _yearsData.map((k, v) => MapEntry(k.toString(), v.toMap()));
          await prefs.setString(_prefsKey, jsonEncode(mapToSave));
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('QadaaService firestore sync error: $e');
    }
  }
}
