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
  });

  factory SmartArticle.fromJson(Map<String, dynamic> json) {
    final hex = (json['themeColorHex'] as String? ?? '#00897B').replaceAll('#', '');
    return SmartArticle(
      id: json['id'] ?? '',
      originalId: json['originalId']?.toString() ?? '',
      rank: json['rank'] ?? 0,
      categoryId: json['categoryId'] ?? '',
      categoryName: json['categoryName'] ?? '',
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
  'baby_care': 'رعاية وتطور الرضيع',
};

/// خريطة categoryId → emoji مميز
const Map<String, String> categoryEmojis = {
  'pregnancy': '🤰',
  'beauty': '💄',
  'marriage': '💕',
  'fertility': '🌸',
  'womens_health': '💗',
  'baby_care': '👶',
};

/// خريطة categoryId → لون ثيم — ألوان نبضة الرسمية بعد التنظيف
/// (متطابقة مع القيم في smart_2500_articles.json بعد تشغيل المرحلة 0)
const Map<String, int> categoryColors = {
  'pregnancy': 0xFFE91E63,       // Nabda pink (وردي أساسي)
  'beauty': 0xFFFF6090,          // Nabda soft pink (وردي ناعم)
  'marriage': 0xFFEC407A,        // rose (روز أنثوي)
  'fertility': 0xFF7E57C2,       // Nabda lavender (لافندر)
  'womens_health': 0xFF00897B,   // Nabda teal (تركوازي نبضة الرسمي)
  'baby_care': 0xFF29B6F6,       // light blue (أزرق لطيف للرضع)
};

/// ألوان نبضة الرسمية للمرجع
const int kNabdaPink = 0xFFE91E63;        // اللون الأساسي
const int kNabdaTeal = 0xFF00897B;         // اللون الثانوي
const int kNabdaCream = 0xFFFFF8FB;        // خلفية دافئة
const int kNabdaSoftPink = 0xFFFF6090;     // وردي ناعم
const int kNabdaLavender = 0xFF7E57C2;     // بنفسجي أنثوي
