import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, kDebugMode, defaultTargetPlatform, TargetPlatform;

// ═══════════════════════════════════════════════════════════════════
//  خدمة AdMob — إعلانات جوجل
//
//  ⚠️ للتفعيل:
//  ① أضيفي الحزمة في pubspec.yaml:
//        google_mobile_ads: ^5.2.0
//     ثم:  flutter pub get
//
//  ② android/app/src/main/AndroidManifest.xml داخل <application>:
//     <meta-data
//        android:name="com.google.android.gms.ads.APPLICATION_ID"
//        android:value="ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY"/>
//
//  ③ ضعي معرّفاتك أدناه في androidBannerId / iosBannerId
//  ④ اجعلي enabled = true
//  ⑤ أزيلي التعليق عن الأسطر المعلّمة بـ  // ADMOB:
//
//  قبل التفعيل التطبيق يعمل طبيعياً ويعرض إعلاناتك الخاصة فقط.
// ═══════════════════════════════════════════════════════════════════

// ADMOB: import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  /// مفتاح التشغيل الوحيد — اجعليه true بعد إتمام خطوات الإعداد أعلاه
  static const bool enabled = false;

  /// معرّفات وحدات الإعلان (بانر)
  /// معرّفات الاختبار الرسمية من جوجل — استبدليها بمعرّفاتك
  static const String _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerIos = 'ca-app-pub-3940256099942544/2934735716';

  static const String androidBannerId = 'ca-app-pub-XXXXXXXXXXXXXXXX/AAAAAAAAAA';
  static const String iosBannerId = 'ca-app-pub-XXXXXXXXXXXXXXXX/BBBBBBBBBB';

  static String get bannerUnitId {
    if (kDebugMode) {
      return _isIos ? _testBannerIos : _testBannerAndroid;
    }
    return _isIos ? iosBannerId : androidBannerId;
  }

  static bool get _isIos => defaultTargetPlatform == TargetPlatform.iOS;

  static bool _initialized = false;

  /// تُستدعى مرّة واحدة في main() قبل runApp
  static Future<void> init() async {
    if (!enabled || kIsWeb || _initialized) return;
    _initialized = true;
    // ADMOB: await MobileAds.instance.initialize();
  }
}

/// بانر AdMob — يعرض [fallback] إن لم يُحمَّل الإعلان أو كان AdMob معطّلاً
class AdMobBanner extends StatefulWidget {
  final Widget fallback;
  const AdMobBanner({Key? key, required this.fallback}) : super(key: key);

  @override
  State<AdMobBanner> createState() => _AdMobBannerState();
}

class _AdMobBannerState extends State<AdMobBanner> {
  // ADMOB: BannerAd? _banner;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    if (!AdMobService.enabled) return;
    // ADMOB:
    // _banner = BannerAd(
    //   adUnitId: AdMobService.bannerUnitId,
    //   size: AdSize.mediumRectangle,
    //   request: const AdRequest(),
    //   listener: BannerAdListener(
    //     onAdLoaded: (_) { if (mounted) setState(() => _loaded = true); },
    //     onAdFailedToLoad: (ad, err) { ad.dispose(); },
    //   ),
    // )..load();
  }

  @override
  void dispose() {
    // ADMOB: _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return widget.fallback;
    // ADMOB:
    // return SizedBox(
    //   width: _banner!.size.width.toDouble(),
    //   height: _banner!.size.height.toDouble(),
    //   child: AdWidget(ad: _banner!),
    // );
    return widget.fallback;
  }
}
