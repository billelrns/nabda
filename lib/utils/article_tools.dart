import 'package:flutter/material.dart';
import '../screens/pregnancy/pregnancy_weeks_screen.dart';
import '../screens/pregnancy/pregnancy_calendar_screen.dart';
import '../screens/fertility/fertility_screen.dart';
import '../screens/trackers/health_trackers_screen.dart';

/// ═══════════════════════════════════════════════════════════════════
///  الخريطة المعتمدة الوحيدة: toolType -> باني الشاشة.
///  ما ليس هنا = لا زرّ (إخفاء البطاقة بأمان تام).
/// ═══════════════════════════════════════════════════════════════════
final Map<String, WidgetBuilder> kArticleTools = {
  // مفاتيح مقالات smart_2500_articles.json
  'pregnancy_tracker'  : (_) => const PregnancyWeeksScreen(),
  'pregnancy_wheel'    : (_) => const PregnancyCalendarScreen(),
  'ovulation_calc'     : (_) => const FertilityScreen(userData: {}),
  'health_tracker'     : (_) => const HealthTrackersScreen(),
  'period_tracker'     : (_) => const FertilityScreen(userData: {}),
  'baby_tracker'       : (_) => const HealthTrackersScreen(),

  // مفاتيح بديلة متوافقة مع enum ArticleToolType
  'dueDateCalculator'  : (_) => const PregnancyCalendarScreen(),
  'ovulationCalculator': (_) => const FertilityScreen(userData: {}),
  'pregnancyWeeks'     : (_) => const PregnancyWeeksScreen(),
  'babyTracker'        : (_) => const HealthTrackersScreen(),
  'waterTracker'       : (_) => const HealthTrackersScreen(),
};

/// التحقق من وجود أداة فعالة للمقال
bool hasArticleTool(Object? t) {
  if (t == null) return false;
  if (t is String) return kArticleTools.containsKey(t);
  final str = t.toString().split('.').last;
  return kArticleTools.containsKey(str);
}

/// الحصول على باني الشاشة إن وُجد
WidgetBuilder? getArticleToolBuilder(Object? t) {
  if (t == null) return null;
  if (t is String) return kArticleTools[t];
  final str = t.toString().split('.').last;
  return kArticleTools[str];
}
