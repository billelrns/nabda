import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// بيانات الولايات والبلديات الجزائرية (تقسيم 2025: 69 ولاية، 1541 بلدية).
/// المصدر: assets/data/algeria_cities.json. تُحمَّل مرّة واحدة وتُخزَّن في الذاكرة.
class AlgeriaLocations {
  static bool _loaded = false;
  static final Map<int, List<String>> _communesByWilaya = {};

  /// يحمّل البيانات من الأصل مرّة واحدة فقط.
  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final raw = await rootBundle.loadString('assets/data/algeria_cities.json');
      final data = json.decode(raw) as Map<String, dynamic>;
      for (final c in (data['communes'] as List)) {
        final wid = (c['wilaya_id'] as num).toInt();
        final name = c['commune_name_arabic'] as String? ?? '';
        if (name.isEmpty) continue;
        (_communesByWilaya[wid] ??= <String>[]).add(name);
      }
      _loaded = true;
    } catch (_) {
      // في حال فشل التحميل تبقى القوائم فارغة (الحقول تتعامل مع ذلك برسالة "جارٍ التحميل").
    }
  }

  static bool get isLoaded => _loaded;

  /// بلديات ولاية معيّنة حسب رقمها الرسمي (1..69).
  static List<String> communesFor(int wilayaId) =>
      _communesByWilaya[wilayaId] ?? const <String>[];
}
