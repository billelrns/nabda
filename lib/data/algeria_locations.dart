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

  /// الولايات الـ69 بصيغة "NN- الاسم". المصدر الوحيد في التطبيق.
  static const List<String> wilayas = [
    '01- أدرار', '02- الشلف', '03- الأغواط', '04- أم البواقي', '05- باتنة',
    '06- بجاية', '07- بسكرة', '08- بشار', '09- البليدة', '10- البويرة',
    '11- تمنراست', '12- تبسة', '13- تلمسان', '14- تيارت', '15- تيزي وزو',
    '16- الجزائر', '17- الجلفة', '18- جيجل', '19- سطيف', '20- سعيدة',
    '21- سكيكدة', '22- سيدي بلعباس', '23- عنابة', '24- قالمة', '25- قسنطينة',
    '26- المدية', '27- مستغانم', '28- المسيلة', '29- معسكر', '30- ورقلة',
    '31- وهران', '32- البيض', '33- إليزي', '34- برج بوعريريج', '35- بومرداس',
    '36- الطارف', '37- تندوف', '38- تسمسيلت', '39- الوادي', '40- خنشلة',
    '41- سوق أهراس', '42- تيبازة', '43- ميلة', '44- عين الدفلى', '45- النعامة',
    '46- عين تموشنت', '47- غرداية', '48- غليزان', '49- تيميمون', '50- برج باجي مختار',
    '51- أولاد جلال', '52- بني عباس', '53- عين صالح', '54- عين قزام', '55- تقرت',
    '56- جانت', '57- المغير', '58- المنيعة',
    '59- آفلو', '60- بريكة', '61- القنطرة', '62- بئر العاتر', '63- العريشة',
    '64- قصر الشلالة', '65- عين وسارة', '66- مسعد', '67- قصر البخاري', '68- بوسعادة',
    '69- الأبيض سيدي الشيخ'
  ];

  /// رقم الولاية من نصّها ("16- الجزائر" → 16)
  static int? idFromLabel(String? label) =>
      label == null ? null : int.tryParse(label.split('-').first.trim());
}
