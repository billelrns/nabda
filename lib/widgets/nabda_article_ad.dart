import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

import 'news_section.dart' show NabdaAd;
import '../services/admob_service.dart';

/// ═══════════════════════════════════════════════════════════════════
///  مساحة إعلانية داخل المقال
///  ① إعلان AdMob (بانر) إن كان مفعّلاً ومتوفراً
///  ② وإلا: إعلان نبضة الخاص (مجموعة ads في Firestore)
///  ③ وإلا: منتج من المتجر مطابق لموضوع المقال
/// ═══════════════════════════════════════════════════════════════════
class NabdaArticleAd extends StatelessWidget {
  /// موضع الإعلان داخل المقال (0،1،2) — يمنع تكرار نفس الإعلان
  final int slot;

  /// معرّف المقال (لمنع تكرار الإعلان داخل نفس المقال)
  final String articleId;

  /// القسم: home / pregnancy / baby / cycle / news
  final String section;

  /// عنوان + نص المقال — تُستعمل لمطابقة المنتج بالموضوع
  final String articleTitle;
  final String articleBody;

  final Color color;

  const NabdaArticleAd({
    Key? key,
    this.slot = 0,
    this.articleId = 'article',
    this.section = 'all',
    this.articleTitle = '',
    this.articleBody = '',
    this.color = const Color(0xFFE91E63),
  }) : super(key: key);

  bool get _admobSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  Widget build(BuildContext context) {
    // NabdaAd يعرض شارته الخاصة («إعلان» / «من متجرنا») ويختفي تماماً
    // إن لم يوجد محتوى — فلا تبقى مساحة فارغة في المقال.
    if (AdMobService.enabled && _admobSupported) {
      return AdMobBanner(fallback: _ownAd());
    }
    return _ownAd();
  }

  Widget _ownAd() => NabdaAd(
        slot: slot,
        groupId: articleId,
        place: section.isEmpty ? 'all' : section,
        color: color,
        contextText: '$articleTitle $articleBody',
      );
}
