// ═══════════════════════════════════════════════════════════════════
//  فتح الشاشة المناسبة عند الضغط على إشعار
//
//  • إشعارات المنتجات المحلية (AppNotifs) تحمل payload = "product:<id>".
//  • إشعارات المقالات المحلية تحمل payload = "article:<id>".
//  • إشعارات FCM (الأدمن/الزوجين) تحمل data.linkType/linkId أو data.productId.
//
//  يعمل في الحالات الثلاث: التطبيق مفتوح، في الخلفية، أو مُغلق تماماً.
//  في الحالة الأخيرة ننتظر حتى يجهز Navigator ويُسجَّل الدخول ثم نفتح المنتج.
// ═══════════════════════════════════════════════════════════════════
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../config/shop_config.dart' show isShopHidden;
import '../screens/shop/landing_product_screen.dart';
import '../screens/articles/smart_article_detail_screen.dart';
import 'smart_articles_service.dart';
import 'country_currency_service.dart';

/// مفتاح Navigator الرئيسي — مربوط بـ MaterialApp في main.dart
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class NotificationRouter {
  NotificationRouter._();

  static const String _productPrefix = 'product:';
  static const String _articlePrefix = 'article:';

  static String? _pending;
  static Timer? _waiter;
  static String? _lastOpened;
  static DateTime? _lastOpenedAt;

  /// payload لإشعار منتج محلي
  static String productPayload(String productId) => '$_productPrefix$productId';

  /// payload لإشعار مقال محلي
  static String articlePayload(String articleId) => '$_articlePrefix$articleId';

  /// payload من إشعار محلي (flutter_local_notifications)
  static void handlePayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) return;
    if (!payload.startsWith(_productPrefix) && !payload.startsWith(_articlePrefix)) {
      return; // أنواع أخرى: يكفي فتح التطبيق
    }
    _pending = payload.trim();
    _waitAndOpen();
  }

  /// بيانات إشعار FCM
  static void handleData(Map<String, dynamic> data) {
    final type = (data['linkType'] ?? '').toString();
    final id = (data['linkId'] ?? data['productId'] ?? '').toString().trim();
    if (id.isEmpty) return;
    if (type == 'article') {
      handlePayload(articlePayload(id));
    } else if (type.isEmpty || type == 'product') {
      handlePayload(productPayload(id));
    }
  }

  /// ينتظر (حتى 25 ثانية) أن يجهز Navigator وتكون المستخدمة مسجّلة
  static void _waitAndOpen() {
    _waiter?.cancel();
    var ticks = 0;
    _waiter = Timer.periodic(const Duration(milliseconds: 400), (t) {
      ticks++;
      final ready = appNavigatorKey.currentState != null &&
          FirebaseAuth.instance.currentUser != null;
      if (ready || ticks > 62) {
        t.cancel();
        final p = _pending;
        _pending = null;
        if (ready && p != null) {
          // مهلة قصيرة حتى تُبنى الشاشة الرئيسية تحت صفحة المنتج
          Future.delayed(const Duration(milliseconds: 700), () => _open(p));
        }
      }
    });
  }

  static Future<void> _open(String payload) async {
    // نفس الإشعار قد يصل من مسارين (getInitialMessage + onMessageOpenedApp)
    final now = DateTime.now();
    if (_lastOpened == payload &&
        _lastOpenedAt != null &&
        now.difference(_lastOpenedAt!).inSeconds < 5) return;
    _lastOpened = payload;
    _lastOpenedAt = now;

    if (payload.startsWith(_articlePrefix)) {
      await _openArticle(payload.substring(_articlePrefix.length));
      return;
    }
    final id = payload.substring(_productPrefix.length);
    if (id.isEmpty) return;
    try {
      final snap =
          await FirebaseFirestore.instance.collection('products').doc(id).get();
      final data = snap.data();
      if (!snap.exists || data == null) return;
      final raw = <String, dynamic>{...data, 'id': snap.id};
      if (isShopHidden(raw)) return; // منتج مخفي أو غير متوفّر في سوقها
      final product = CountryCurrencyService().localize(raw);
      appNavigatorKey.currentState?.push(MaterialPageRoute(
        builder: (_) => LandingProductScreen(productData: product),
      ));
    } catch (e) {
      debugPrint('NotificationRouter: cannot open product $id: $e');
    }
  }

  static Future<void> _openArticle(String id) async {
    if (id.isEmpty) return;
    try {
      final article = await SmartArticlesService().getById(id);
      if (article == null) return;
      appNavigatorKey.currentState?.push(MaterialPageRoute(
        builder: (_) => SmartArticleDetailScreen(article: article),
      ));
    } catch (e) {
      debugPrint('NotificationRouter: cannot open article $id: $e');
    }
  }
}
