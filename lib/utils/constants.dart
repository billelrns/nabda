import 'package:flutter/material.dart';

class AppConstants {
  // Colors
  static const Color primaryColor = Color(0xFF00897B);
  static const Color accentColor = Color(0xFFE91E63);
  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color errorColor = Color(0xFFE53935);
  static const Color successColor = Color(0xFF43A047);
  static const Color warningColor = Color(0xFFFFA726);

  // Strings - Arabic UI
  static const String appName = 'نبضة';
  static const String appDescription = 'صحتك أولويتنا';

  // URLs
  static const String termsUrl = 'https://example.com/terms';
  static const String privacyUrl = 'https://example.com/privacy';
  static const String supportEmail = 'support@nabda.app';

  // Firebase
  static const String firebaseProjectId = 'nabda-flutter';

  // Cycle constants
  static const int averageCycleLength = 28;
  static const int minCycleLength = 21;
  static const int maxCycleLength = 35;
  static const int averagePeriodDuration = 5;

  // Pregnancy constants
  static const int gestationWeeks = 40;
  static const int weeksTrimester = 13;

  // Baby milestones
  static const List<String> babyMilestones = [
    'الابتسامة',
    'الجلوس',
    'الزحف',
    'الوقوف',
    'المشي',
    'الكلام',
  ];

  // Symptoms list
  static const List<String> commonSymptoms = [
    'صداع',
    'آلام في البطن',
    'آلام في الظهر',
    'إرهاق',
    'قلق',
    'تقلب المزاج',
    'انتفاخ',
    'حب شباب',
    'الرغبة في الحلويات',
    'الأرق',
  ];

  // Vaccination schedule
  static const List<String> vaccinations = [
    'BCG',
    'شلل الأطفال',
    'الخماسي',
    'الالتهاب الكبدي B',
    'الدوران',
    'الحصبة والنكاف والحصبة الألمانية',
    'السعار',
  ];

  // Community categories
  static const List<String> postCategories = [
    'cycle',
    'pregnancy',
    'baby',
    'general',
  ];

  static const Map<String, String> categoryNames = {
    'cycle': 'الدورة الشهرية',
    'pregnancy': 'الحمل',
    'baby': 'الطفل',
    'general': 'عام',
  };
}
