import 'package:flutter/material.dart';

class SmartArticle {
  final String id;
  final String originalId;
  final int rank;
  final String categoryId;
  final String categoryName;
  final String title;
  final String? originalTitle;
  final String readTime;
  final String author;
  final String? badge;
  final String summary;
  final String iconEmoji;
  final Color themeColor;
  final List<ArticleSection> sections;
  final List<ArticleFaq> faqs;
  final String? toolType;
  final String? toolTitle;
  final String? toolSubtitle;
  final String? sourceUrl;
  final int originalViews;
  final String imagePath;
  final String? photoTag;
  final String? subcategoryId;
  final String? subcategoryName;
  final String? specialty;
  final String? subcategoryEmoji;
  final List<String> tags;

  const SmartArticle({
    required this.id,
    required this.originalId,
    required this.rank,
    required this.categoryId,
    required this.categoryName,
    required this.title,
    this.originalTitle,
    required this.readTime,
    required this.author,
    this.badge,
    required this.summary,
    required this.iconEmoji,
    required this.themeColor,
    required this.sections,
    required this.faqs,
    this.toolType,
    this.toolTitle,
    this.toolSubtitle,
    this.sourceUrl,
    required this.originalViews,
    required this.imagePath,
    this.photoTag,
    this.subcategoryId,
    this.subcategoryName,
    this.specialty,
    this.subcategoryEmoji,
    this.tags = const [],
  });

  factory SmartArticle.fromJson(Map<String, dynamic> json) {
    final hex = (json['themeColorHex'] as String? ?? '#00897B').replaceAll('#', '');
    final catId = json['categoryId'] ?? '';
    final subId = json['subcategoryId'];
    final subName = json['subcategoryName'] ?? (subId != null ? subcategoryNames[subId] : null);
    final subEmoji = json['subcategoryEmoji'] ?? (subId != null ? subcategoryEmojis[subId] : null);

    return SmartArticle(
      id: json['id'] ?? '',
      originalId: json['originalId']?.toString() ?? '',
      rank: json['rank'] ?? 0,
      categoryId: catId,
      categoryName: json['categoryName'] ?? (categoryNames[catId] ?? ''),
      title: json['title'] ?? '',
      originalTitle: json['originalTitle'],
      readTime: json['readTime'] ?? '5 دقائق',
      author: json['author'] ?? 'فريق نبضة',
      badge: json['badge'],
      summary: json['summary'] ?? '',
      iconEmoji: json['iconEmoji'] ?? '📖',
      themeColor: Color(int.parse('FF$hex', radix: 16)),
      sections: (json['sections'] as List? ?? [])
          .map((s) => ArticleSection.fromJson(s as Map<String, dynamic>))
          .toList(),
      faqs: (json['faqs'] as List? ?? [])
          .map((f) => ArticleFaq.fromJson(f as Map<String, dynamic>))
          .toList(),
      toolType: json['toolType'],
      toolTitle: json['toolTitle'],
      toolSubtitle: json['toolSubtitle'],
      sourceUrl: json['sourceUrl'],
      originalViews: json['originalViews'] ?? 0,
      imagePath: json['imagePath'] ?? 'assets/images/logo_nabda.png',
      photoTag: json['photoTag'],
      subcategoryId: subId,
      subcategoryName: subName,
      specialty: json['specialty'],
      subcategoryEmoji: subEmoji,
      tags: (json['tags'] as List? ?? []).map((t) => t.toString()).toList(),
    );
  }
}

class ArticleSection {
  final String title;
  final String content;
  const ArticleSection({required this.title, required this.content});
  factory ArticleSection.fromJson(Map<String, dynamic> j) =>
      ArticleSection(title: j['title'] ?? '', content: j['content'] ?? '');
}

class ArticleFaq {
  final String question;
  final String answer;
  const ArticleFaq({required this.question, required this.answer});
  factory ArticleFaq.fromJson(Map<String, dynamic> j) =>
      ArticleFaq(question: j['question'] ?? '', answer: j['answer'] ?? '');
}

/// خريطة categoryId → categoryName (للتوحيد)
const Map<String, String> categoryNames = {
  'pregnancy': 'الحمل والولادة',
  'beauty': 'جمالي وعنايتي',
  'marriage': 'العلاقة الزوجية والسكينة',
  'fertility': 'التبويض والتخطيط للحمل',
  'womens_health': 'صحة المرأة والرشاقة',
  'health': 'صحة المرأة والرشاقة',
  'baby_care': 'رعاية وتطور الرضيع',
  'baby': 'رعاية وتطور الرضيع',
};

/// خريطة categoryId → emoji مميز
const Map<String, String> categoryEmojis = {
  'pregnancy': '🤰',
  'beauty': '💄',
  'marriage': '💕',
  'fertility': '🌸',
  'womens_health': '💗',
  'health': '💗',
  'baby_care': '👶',
  'baby': '👶',
};

/// خريطة categoryId → لون ثيم — ألوان نبضة الرسمية بعد التنظيف
const Map<String, int> categoryColors = {
  'pregnancy': 0xFFE91E63,       // Nabda pink (وردي أساسي)
  'beauty': 0xFFFF6090,          // Nabda soft pink (وردي ناعم)
  'marriage': 0xFFEC407A,        // rose (روز أنثوي)
  'fertility': 0xFF7E57C2,       // Nabda lavender (لافندر)
  'womens_health': 0xFF00897B,   // Nabda teal (تركوازي نبضة الرسمي)
  'health': 0xFF00897B,          // Nabda teal (تركوازي نبضة الرسمي)
  'baby_care': 0xFF29B6F6,       // light blue (أزرق لطيف للرضع)
  'baby': 0xFF29B6F6,            // light blue (أزرق لطيف للرضع)
};

/// خريطة التصنيفات الفرعية لكل قسم رئيسي
const Map<String, List<String>> subcategoriesByCategory = {
  'pregnancy': [
    'preg_nutrition_vitamins',
    'preg_labor_delivery',
    'preg_health_tests',
    'preg_symptoms_weeks',
    'preg_postpartum',
  ],
  'baby': [
    'baby_development_growth',
    'baby_breastfeeding_food',
    'baby_sleep_routine',
    'baby_health_care',
    'baby_safety_gear',
  ],
  'baby_care': [
    'baby_development_growth',
    'baby_breastfeeding_food',
    'baby_sleep_routine',
    'baby_health_care',
    'baby_safety_gear',
  ],
  'fertility': [
    'fert_ovulation_cycle',
    'fert_boost_tips',
    'fert_pcos_hormones',
    'fert_ivf_medical',
  ],
  'health': [
    'health_nutrition_fitness',
    'health_diseases_prevention',
    'health_mental_wellness',
    'health_hormones_lifestyle',
    'health_period_cycle',
  ],
  'womens_health': [
    'health_nutrition_fitness',
    'health_diseases_prevention',
    'health_mental_wellness',
    'health_hormones_lifestyle',
    'health_period_cycle',
  ],
  'beauty': [
    'beauty_skincare',
    'beauty_haircare',
    'beauty_body_perfume',
    'beauty_natural_recipes',
    'beauty_pregnancy_safe',
  ],
  'marriage': [
    'marr_communication',
    'marr_conflicts_solutions',
    'marr_parenting_partnership',
    'marr_intimacy',
  ],
};

/// أسماء التصنيفات الفرعية
const Map<String, String> subcategoryNames = {
  // Pregnancy
  'preg_nutrition_vitamins': 'تغذية وفيتامينات الحامل',
  'preg_labor_delivery': 'المخاض والولادة والتحضير',
  'preg_health_tests': 'فحوصات وسونار ومتاعب الحمل',
  'preg_symptoms_weeks': 'أعراض الحمل وتطور الجنين',
  'preg_postpartum': 'ما بعد الولادة والنفاس',

  // Baby
  'baby_development_growth': 'مراحل النمو والتطور',
  'baby_breastfeeding_food': 'الرضاعة والتغذية والفطام',
  'baby_sleep_routine': 'نوم الرضيع والروتين والبكاء',
  'baby_health_care': 'صحة الرضيع والتطعيمات',
  'baby_safety_gear': 'سلامة الطفل ومستلزماته',

  // Fertility
  'fert_ovulation_cycle': 'حساب التبويض وعلامات الخصوبة',
  'fert_boost_tips': 'تعزيز الخصوبة وفرص الحمل',
  'fert_pcos_hormones': 'تكيس المبايض واضطراب الهرمونات',
  'fert_ivf_medical': 'الفحوصات والحقن المجهري',

  // Health
  'health_nutrition_fitness': 'الرشاقة وإنقاص الوزن والطبخ',
  'health_diseases_prevention': 'الأمراض النسائية والوقاية',
  'health_mental_wellness': 'الصحة النفسية والاسترخاء',
  'health_hormones_lifestyle': 'الهرمونات ونمط الحياة',
  'health_period_cycle': 'الدورة الشهرية وأعراضها',

  // Beauty
  'beauty_skincare': 'العناية بالبشرة والوجه والنضارة',
  'beauty_haircare': 'العناية بالشعر ومنع التساقط',
  'beauty_body_perfume': 'العناية بالجسم والتعطير',
  'beauty_natural_recipes': 'الوصفات والخلطات الطبيعية',
  'beauty_pregnancy_safe': 'الجمال الآمن للحوامل والأمهات',

  // Marriage
  'marr_communication': 'التفاهم والحوار ولغات الحب',
  'marr_conflicts_solutions': 'إدارة الخلافات والضغوط',
  'marr_parenting_partnership': 'الشراكة الوالدية وبناء الأسرة',
  'marr_intimacy': 'العلاقة الحميمة والانسجام',
};

/// إيموجي التصنيفات الفرعية
const Map<String, String> subcategoryEmojis = {
  'preg_nutrition_vitamins': '🥗',
  'preg_labor_delivery': '🏥',
  'preg_health_tests': '🔬',
  'preg_symptoms_weeks': '🤰',
  'preg_postpartum': '🌸',

  'baby_development_growth': '🧸',
  'baby_breastfeeding_food': '🍼',
  'baby_sleep_routine': '😴',
  'baby_health_care': '👶',
  'baby_safety_gear': '🛡️',

  'fert_ovulation_cycle': '🗓️',
  'fert_boost_tips': '🌸',
  'fert_pcos_hormones': '🩺',
  'fert_ivf_medical': '🔬',

  'health_nutrition_fitness': '🥗',
  'health_diseases_prevention': '🩺',
  'health_mental_wellness': '🕊️',
  'health_hormones_lifestyle': '💗',
  'health_period_cycle': '🩸',

  'beauty_skincare': '💄',
  'beauty_haircare': '💇‍♀️',
  'beauty_body_perfume': '✨',
  'beauty_natural_recipes': '🌿',
  'beauty_pregnancy_safe': '🤰',

  'marr_communication': '💍',
  'marr_conflicts_solutions': '🕊️',
  'marr_parenting_partnership': '👨‍👩‍👧',
  'marr_intimacy': '💕',
};

/// ألوان نبضة الرسمية للمرجع
const int kNabdaPink = 0xFFE91E63;        // اللون الأساسي
const int kNabdaTeal = 0xFF00897B;         // اللون الثانوي
const int kNabdaCream = 0xFFFFF8FB;        // خلفية دافئة
const int kNabdaSoftPink = 0xFFFF6090;     // وردي ناعم
const int kNabdaLavender = 0xFF7E57C2;     // بنفسجي أنثوي

