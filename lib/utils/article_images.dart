import 'package:flutter/material.dart';
import 'article_image_map.g.dart';

/// ═══════════════════════════════════════════════════════════════════
///  محلّل صور المقالات v2 — يستبدل روابط Unsplash بصور نبضة المحلية.
///  • كلمات مفتاحية مخصصة حسب القسم (baby/pregnancy/cycle) لتفادي
///    التصادم (مشي الطفل ≠ مشي الحامل).
///  • عند غياب التطابق: توزيع ثابت متنوع من حوض صور القسم (بحسب
///    hash العنوان) — فلا تتكرر صورة واحدة في كل المقالات.
/// ═══════════════════════════════════════════════════════════════════
class ArticleImages {
  static const _b = 'assets/images/articles';

  // ── كلمات قسم الطفل (أولوية عند section=baby) ──
  static const List<MapEntry<String, String>> _babyKw = [
    MapEntry('تطعيم', '$_b/cat_vaccination.png'),
    MapEntry('لقاح', '$_b/cat_vaccination.png'),
    MapEntry('حمى', '$_b/cat_vaccination.png'),
    MapEntry('حرارة', '$_b/cat_vaccination.png'),
    MapEntry('مرض', '$_b/cat_vaccination.png'),
    MapEntry('تسنين', '$_b/cat_teething.png'),
    MapEntry('استحمام', '$_b/cat_baby_bath.png'),
    MapEntry('حمام', '$_b/cat_baby_bath.png'),
    MapEntry('نظافة', '$_b/cat_baby_bath.png'),
    MapEntry('مغص', '$_b/cat_colic.png'),
    MapEntry('بكاء', '$_b/cat_colic.png'),
    MapEntry('نوم', '$_b/cat_baby_sleep.png'),
    MapEntry('رضاعة طبيعية', '$_b/cat_breastfeeding.png'),
    MapEntry('رضاعة صناعية', '$_b/cat_bottle_feeding.png'),
    MapEntry('حليب', '$_b/cat_bottle_feeding.png'),
    MapEntry('رضاعة', '$_b/cat_breastfeeding.png'),
    MapEntry('فطام', '$_b/cat_weaning.png'),
    MapEntry('طعام', '$_b/cat_first_foods.png'),
    MapEntry('تغذية', '$_b/cat_first_foods.png'),
    MapEntry('أكل', '$_b/cat_first_foods.png'),
    MapEntry('مشي', '$_b/cat_toddler.png'),
    MapEntry('خطوات', '$_b/cat_toddler.png'),
    MapEntry('حركة', '$_b/cat_growth_6_12.png'),
    MapEntry('زحف', '$_b/cat_growth_6_12.png'),
    MapEntry('جلوس', '$_b/cat_growth_6_12.png'),
    MapEntry('لعب', '$_b/cat_growth_6_12.png'),
    MapEntry('كلام', '$_b/cat_reading.png'),
    MapEntry('لغة', '$_b/cat_reading.png'),
    MapEntry('قراءة', '$_b/cat_reading.png'),
    MapEntry('قصص', '$_b/cat_reading.png'),
    MapEntry('ذكاء', '$_b/cat_reading.png'),
    MapEntry('أمان', '$_b/cat_home_safety.png'),
    MapEntry('تأمين', '$_b/cat_home_safety.png'),
    MapEntry('سلامة', '$_b/cat_home_safety.png'),
    MapEntry('نمو', '$_b/cat_growth_chart.png'),
    MapEntry('وزن', '$_b/cat_growth_chart.png'),
    MapEntry('طول', '$_b/cat_growth_chart.png'),
    MapEntry('تطور', '$_b/cat_growth_0_6.png'),
    MapEntry('حديث الولادة', '$_b/cat_newborn.png'),
    MapEntry('مولود', '$_b/cat_newborn.png'),
    MapEntry('حفاض', '$_b/cat_newborn.png'),
    MapEntry('سفر', '$_b/cat_travel.png'),
    MapEntry('أسماء', '$_b/cat_baby_names.png'),
  ];

  // ── كلمات قسم الحمل ──
  static const List<MapEntry<String, String>> _pregKw = [
    MapEntry('غثيان', '$_b/cat_nausea.png'),
    MapEntry('وحام', '$_b/cat_nausea.png'),
    MapEntry('حقيبة', '$_b/cat_birth_prep.png'),
    MapEntry('قيصري', '$_b/cat_delivery_recovery.png'),
    MapEntry('مخاض', '$_b/cat_birth_prep.png'),
    MapEntry('ولادة', '$_b/cat_birth_prep.png'),
    MapEntry('سونار', '$_b/cat_prenatal_checkup.png'),
    MapEntry('فحوص', '$_b/cat_prenatal_checkup.png'),
    MapEntry('فحص', '$_b/cat_prenatal_checkup.png'),
    MapEntry('تحاليل', '$_b/cat_prenatal_checkup.png'),
    MapEntry('طبيب', '$_b/cat_prenatal_checkup.png'),
    MapEntry('دور الأب', '$_b/cat_husband_support.png'),
    MapEntry('الأب', '$_b/cat_husband_support.png'),
    MapEntry('زوج', '$_b/cat_husband_support.png'),
    MapEntry('التواصل مع الجنين', '$_b/cat_spiritual.png'),
    MapEntry('دعاء', '$_b/cat_spiritual.png'),
    MapEntry('قرآن', '$_b/cat_spiritual.png'),
    MapEntry('أذكار', '$_b/cat_spiritual.png'),
    MapEntry('بشرة', '$_b/cat_skincare.png'),
    MapEntry('كلف', '$_b/cat_skincare.png'),
    MapEntry('تشقق', '$_b/cat_skincare.png'),
    MapEntry('أزياء', '$_b/cat_fashion.png'),
    MapEntry('ملابس', '$_b/cat_fashion.png'),
    MapEntry('نوم', '$_b/cat_sleep_pregnancy.png'),
    MapEntry('أرق', '$_b/cat_sleep_pregnancy.png'),
    MapEntry('يوغا', '$_b/cat_exercise.png'),
    MapEntry('تمارين', '$_b/cat_exercise.png'),
    MapEntry('كيغل', '$_b/cat_exercise.png'),
    MapEntry('رياضة', '$_b/cat_exercise.png'),
    MapEntry('مشي', '$_b/cat_walking.png'),
    MapEntry('تغذية', '$_b/cat_nutrition.png'),
    MapEntry('غذاء', '$_b/cat_nutrition.png'),
    MapEntry('فيتامين', '$_b/cat_nutrition.png'),
    MapEntry('حديد', '$_b/cat_nutrition.png'),
    MapEntry('طعام', '$_b/cat_meal_prep.png'),
    MapEntry('وصفات', '$_b/cat_meal_prep.png'),
    MapEntry('رضاعة', '$_b/cat_breastfeeding.png'),
    MapEntry('اكتئاب', '$_b/cat_postpartum_support.png'),
    MapEntry('نفاس', '$_b/cat_postpartum_support.png'),
    MapEntry('ما بعد الولادة', '$_b/cat_postpartum_support.png'),
    MapEntry('تعافي', '$_b/cat_postpartum_fitness.png'),
    MapEntry('نفسية', '$_b/cat_mental_health.png'),
    MapEntry('توتر', '$_b/cat_mental_health.png'),
    MapEntry('أسماء', '$_b/cat_baby_names.png'),
    MapEntry('غرفة المولود', '$_b/cat_newborn.png'),
    MapEntry('مولود', '$_b/cat_newborn.png'),
  ];

  // ── كلمات قسم الدورة/صحة المرأة ──
  static const List<MapEntry<String, String>> _cycleKw = [
    MapEntry('دورة', '$_b/cat_cycle.png'),
    MapEntry('حيض', '$_b/cat_cycle.png'),
    MapEntry('طمث', '$_b/cat_cycle.png'),
    MapEntry('ألم', '$_b/cat_cycle.png'),
    MapEntry('خصوبة', '$_b/cat_fertility.png'),
    MapEntry('تبويض', '$_b/cat_fertility.png'),
    MapEntry('إنجاب', '$_b/cat_fertility.png'),
    MapEntry('تكيس', '$_b/cat_women_health.png'),
    MapEntry('هرمون', '$_b/cat_women_health.png'),
    MapEntry('انتباذ', '$_b/cat_women_health.png'),
    MapEntry('نفسية', '$_b/cat_mental_health.png'),
    MapEntry('مزاج', '$_b/cat_mental_health.png'),
    MapEntry('تغذية', '$_b/cat_nutrition.png'),
    MapEntry('تمارين', '$_b/cat_exercise.png'),
  ];

  // ── حوض التنويع لكل قسم (عند غياب أي تطابق) ──
  static const Map<String, List<String>> _pools = {
    'baby': [
      '$_b/cat_newborn.png', '$_b/cat_growth_0_6.png',
      '$_b/cat_growth_6_12.png', '$_b/cat_toddler.png',
      '$_b/cat_reading.png', '$_b/cat_baby_sleep.png',
      '$_b/cat_baby_bath.png', '$_b/cat_growth_chart.png',
      '$_b/cat_family.png',
    ],
    'pregnancy': [
      '$_b/cat_prenatal_checkup.png', '$_b/cat_walking.png',
      '$_b/cat_spiritual.png', '$_b/cat_husband_support.png',
      '$_b/cat_nutrition.png', '$_b/cat_sleep_pregnancy.png',
      '$_b/cat_fashion.png', '$_b/cat_exercise.png',
    ],
    'cycle': [
      '$_b/cat_cycle.png', '$_b/cat_women_health.png',
      '$_b/cat_mental_health.png', '$_b/cat_fertility.png',
      '$_b/cat_nutrition.png',
    ],
    'home': [
      '$_b/cat_family.png', '$_b/cat_community.png',
      '$_b/cat_mental_health.png', '$_b/cat_meal_prep.png',
      '$_b/cat_walking.png', '$_b/cat_spiritual.png',
      '$_b/cat_newborn.png', '$_b/cat_prenatal_checkup.png',
    ],
  };

  static List<MapEntry<String, String>> _kwFor(String section) {
    switch (section) {
      case 'baby':
        return [..._babyKw, ..._pregKw, ..._cycleKw];
      case 'cycle':
      case 'fertility':
        // في قسم الدورة فقط: «حمل» تعني التخطيط للحمل → صورة الخصوبة
        return [
          const MapEntry('حمل', '$_b/cat_fertility.png'),
          ..._cycleKw, ..._pregKw, ..._babyKw,
        ];
      case 'pregnancy':
      case 'home':
      default:
        return [..._pregKw, ..._babyKw, ..._cycleKw];
    }
  }

  /// يعيد مسار الصورة المناسبة — صورة فريدة أولاً، ثم تطابق حسب القسم
  static String resolve(String title, {String section = ''}) {
    // ① صورة Hook فريدة مولّدة بالذكاء الاصطناعي (أولوية قصوى)
    final exact = kArticleImageMap[title.trim()];
    if (exact != null) return exact;

    // ② تطابق كلمة مفتاحية حسب القسم
    for (final e in _kwFor(section)) {
      if (title.contains(e.key)) return e.value;
    }
    final pool = _pools[section] ?? _pools['home']!;
    // توزيع ثابت: نفس العنوان يعطي نفس الصورة دائماً، وعناوين مختلفة تتنوع
    final idx = title.codeUnits.fold<int>(0, (a, c) => (a + c) % 100000);
    return pool[idx % pool.length];
  }
}

/// ويدجت صورة المقال: محلية أولاً، وعند فقدان الملف تعود للرابط القديم
class ArticleImage extends StatelessWidget {
  final String title;
  final String section;
  final String? networkUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const ArticleImage({
    Key? key,
    required this.title,
    this.section = '',
    this.networkUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final asset = ArticleImages.resolve(title, section: section);
    return Image.asset(
      asset,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) {
        if (networkUrl != null && networkUrl!.isNotEmpty) {
          return Image.network(
            networkUrl!,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, __, ___) => _placeholder(),
          );
        }
        return _placeholder();
      },
    );
  }

  Widget _placeholder() => Container(
        width: width,
        height: height,
        color: const Color(0xFFFCE4EC),
        child: const Center(
            child: Icon(Icons.favorite, color: Color(0xFFE0195B), size: 32)),
      );
}
