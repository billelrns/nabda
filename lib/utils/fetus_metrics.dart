import '../models/pregnancy_week_articles.dart';
import 'fetus_size.dart';

/// ═══════════════════════════════════════════════════════════════════
///  المصدر الطبي الموحّد لمقاييس ونمو الجنين (طول، وزن، فاكهة، إيموجي)
///  يقرأ حصرياً من pregnancyWeekArticles بدون أي معادلات أو استيفاء رياضي.
/// ═══════════════════════════════════════════════════════════════════
class FetusMetrics {
  final String length;  // مثال: '3.1 سم'
  final String weight;  // مثال: '4 غرام'
  final String fruit;   // مثال: 'فراولة'
  final String emoji;   // مثال: '🍓'
  final String summary; // مثال: 'حبة فراولة'

  const FetusMetrics({
    required this.length,
    required this.weight,
    required this.fruit,
    required this.emoji,
    this.summary = '',
  });

  /// يقرأ من pregnancyWeekArticles.
  /// عند غياب الأسبوع يعود بأقرب أسبوع متاح — وممنوع أي استيفاء أو حساب بمعادلة.
  static FetusMetrics forWeek(int week) {
    if (pregnancyWeekArticles.isEmpty) {
      return const FetusMetrics(
        length: '--',
        weight: '--',
        fruit: 'بذرة',
        emoji: '🌱',
        summary: 'بذرة',
      );
    }

    // 1. محاولة مطابقة الأسبوع بدقة
    PregnancyWeekArticle? exact;
    for (final a in pregnancyWeekArticles) {
      if (a.week == week) {
        exact = a;
        break;
      }
    }

    if (exact != null) {
      return _fromArticle(exact);
    }

    // 2. عند غياب الأسبوع: البحث عن أقرب أسبوع متوفر بدون أي استيفاء رياضي
    PregnancyWeekArticle closest = pregnancyWeekArticles.first;
    int minDiff = (closest.week - week).abs();
    for (final a in pregnancyWeekArticles) {
      final diff = (a.week - week).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = a;
      }
    }

    return _fromArticle(closest);
  }

  static FetusMetrics _fromArticle(PregnancyWeekArticle a) {
    final fEmoji = FetusSize.emoji(a.week);
    final fName = FetusSize.name(a.week);
    return FetusMetrics(
      length: a.babyLength,
      weight: a.babyWeight,
      fruit: fName,
      emoji: fEmoji,
      summary: a.babySizeAr,
    );
  }
}
