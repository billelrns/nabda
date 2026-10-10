import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// بيانات مناطق/محافظات الدول العربية المحمّلة من assets/data/regions.json
class CountryRegions {
  static bool _loaded = false;
  static final Map<String, List<String>> _regionsByCountry = {};

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final raw = await rootBundle.loadString('assets/data/regions.json');
      final data = json.decode(raw) as Map<String, dynamic>;
      data.forEach((countryCode, list) {
        if (list is List) {
          _regionsByCountry[countryCode] = list.map((e) => e.toString()).toList();
        }
      });
      _loaded = true;
    } catch (_) {
      // في حال تعذر القراءة تبقى فارغة
    }
  }

  static bool get isLoaded => _loaded;

  /// قائمة المناطق لدولة معيّنة برمزها (SA, EG, AE...) أو null إذا لم تكن متوفرة
  static List<String>? regionsFor(String countryCode) => _regionsByCountry[countryCode];

  /// هل تتوفر قائمة مناطق مسجلة لهذه الدولة؟
  static bool hasRegions(String countryCode) {
    final list = _regionsByCountry[countryCode];
    return list != null && list.isNotEmpty;
  }
}
