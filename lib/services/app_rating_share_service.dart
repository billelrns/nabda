import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppRatingShareService {
  static const String playStoreUrl = 'https://play.google.com/store/apps/details?id=com.nabda.app';

  /// يطلب تقييم التطبيق داخل التطبيق أولاً مع الرجوع لصفحة المتجر إذا تعذر
  static Future<void> rateApp() async {
    final review = InAppReview.instance;
    try {
      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        await review.openStoreListing(appStoreId: 'com.nabda.app');
      }
    } catch (_) {
      try {
        final uri = Uri.parse(playStoreUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {}
    }
  }

  /// يفتح نافذة مشاركة التطبيق مع رابط التحميل ورسالة ترحيبية
  static Future<void> shareApp() async {
    const text = 'تطبيق نبضة — رفيقتكِ المتكاملة في رحلة الأمومة وصحة المرأة 💖\n\n'
        'متابعة الحمل أسبوعياً، حساب الدورة الشهرية، رعاية الطفل، مجتمع أمهات ومساعد ذكي.\n\n'
        'حمّليه الآن:\n$playStoreUrl';
    try {
      await Share.share(text, subject: 'تطبيق نبضة — صحة المرأة العربية');
    } catch (_) {}
  }
}
