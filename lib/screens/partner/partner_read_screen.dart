import 'package:flutter/material.dart';

import '../../services/partner_service.dart';
import '../articles/articles_hub_screen.dart';
import '../articles/smart_articles_list_screen.dart';
import '../fiqh/womens_fiqh_screen.dart';
import 'father_daily_tips.dart';

/// ═══════════════════════════════════════════════════════════════════
///  تبويب «اقرأ» للأب — بوّابة المحتوى
///
///  يُعيد استعمال شاشات المحتوى نفسها التي تراها الزوجة، فيرث تلقائياً
///  فلترة `kHideMedicalFeatures` (إخفاء التصنيفات الطبّية في نسخة
///  الحساب الشخصي على Google Play) دون أي كود إضافي.
/// ═══════════════════════════════════════════════════════════════════
/// قسم «اقرأ وتعلّم» — كان تبويباً مستقلاً، وصار مدمجاً داخل «رحلتنا».
/// يُستعمل كقطعة قابلة للتضمين في أي صفحة.
class PartnerLearnSection extends StatelessWidget {
  final String? coupleId;

  /// `true` لإظهار بطاقة نصيحة اليوم (تُخفى إن كانت معروضة فوقها)
  final bool showTip;

  const PartnerLearnSection({
    super.key,
    this.coupleId,
    this.showTip = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = PartnerReadScreen(coupleId: coupleId);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (showTip) ...[s.tipOfDay(), const SizedBox(height: 20)],
      const Text('اقرأ وتعلّم',
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: PartnerReadScreen._ink)),
      const SizedBox(height: 12),
      ...s.contentCards(context),
      if (coupleId != null) ...[
        const SizedBox(height: 20),
        const Text('إنجازات زوجتك',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: PartnerReadScreen._ink)),
        const SizedBox(height: 12),
        s.badges(coupleId!),
      ],
    ]);
  }
}

class PartnerReadScreen extends StatelessWidget {
  final String? coupleId;
  const PartnerReadScreen({super.key, this.coupleId});

  static const _blue = Color(0xFF2E6B8F);
  static const _deepBlue = Color(0xFF1E4A66);
  static const _teal = Color(0xFF00897B);
  static const _amber = Color(0xFFD98324);
  static const _pink = Color(0xFFE0195B);
  static const _ink = Color(0xFF1F1A20);
  static const _ink3 = Color(0xFF9B8F95);
  static const _bg = Color(0xFFF7FAFC);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          foregroundColor: _ink,
          title: const Text('اقرأ وتعلّم',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            tipOfDay(),
            const SizedBox(height: 20),
            const Text('المحتوى',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800, color: _ink)),
            const SizedBox(height: 12),
            ...contentCards(context),
            const SizedBox(height: 20),
            if (coupleId != null) ...[
              const Text('إنجازات زوجتك',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800, color: _ink)),
              const SizedBox(height: 12),
              badges(coupleId!),
            ],
          ],
        ),
      ),
    );
  }

  /// بطاقات المحتوى الثلاث — تُستعمل هنا وفي «رحلتنا»
  List<Widget> contentCards(BuildContext context) => [
        _card(
          context,
          '📚',
          'مكتبة نبضة',
          'كل المقالات وآخر الأخبار في مكان واحد',
          _blue,
          () => const ArticlesHubScreen(),
        ),
        _card(
          context,
          '🧠',
          'الموسوعة الذكية',
          'أكثر من 100 مقال تفاعلي عن الحمل والطفل',
          _teal,
          () => const SmartArticlesListScreen(),
        ),
        _card(
          context,
          '📗',
          'فقه المرأة',
          'أحكام تخصّ زوجتك — تفهمها فتُحسن معاملتها',
          _amber,
          () => const WomensFiqhScreen(),
        ),
      ];

  // ── نصيحة اليوم ──────────────────────────────────────────────
  Widget tipOfDay() => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [_blue, _deepBlue],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.wb_sunny_outlined,
                size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text('نصيحة اليوم',
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.9))),
          ]),
          const SizedBox(height: 12),
          Text(
            FatherDailyTips.today(),
            style: const TextStyle(
                fontSize: 15,
                height: 1.8,
                fontWeight: FontWeight.w600,
                color: Colors.white),
          ),
        ]),
      );

  Widget _card(BuildContext context, String emoji, String title, String sub,
          Color c, Widget Function() builder) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => builder())),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE6EDF2)),
            ),
            child: Row(children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: c.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(15),
                ),
                child:
                    Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: _ink)),
                      const SizedBox(height: 3),
                      Text(sub,
                          style: const TextStyle(
                              fontSize: 11.5, color: _ink3, height: 1.4)),
                    ]),
              ),
              const Icon(Icons.arrow_back_ios, size: 14, color: _ink3),
            ]),
          ),
        ),
      );

  // ── شارات الزوجة وإنجازاتها ──────────────────────────────────
  Widget badges(String coupleId) => StreamBuilder<SharedProfile?>(
        stream: PartnerService.watchProfile(coupleId),
        builder: (context, snap) {
          final p = snap.data;
          if (p == null || (p.badges.isEmpty && p.points == 0)) {
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE6EDF2)),
              ),
              child: const Row(children: [
                Icon(Icons.emoji_events_outlined, color: _ink3, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ستظهر هنا شارات زوجتك ونقاطها فور أن تبدأ بجمعها.',
                    style: TextStyle(fontSize: 12.5, color: _ink3, height: 1.6),
                  ),
                ),
              ]),
            );
          }

          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _pink.withOpacity(0.20)),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Text('🏆', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        p.name.trim().isEmpty ? 'زوجتك' : p.name.trim(),
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: _ink),
                      ),
                    ),
                    if (p.points > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _pink.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('${p.points} نقطة',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: _pink)),
                      ),
                  ]),
                  if (p.badges.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: p.badges
                          .map((b) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: _amber.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                      color: _amber.withOpacity(0.28)),
                                ),
                                child: Text('🏅 $b',
                                    style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: _ink)),
                              ))
                          .toList(),
                    ),
                  ],
                  if (p.postsCount > 0) ...[
                    const SizedBox(height: 12),
                    Text('شاركت ${p.postsCount} منشوراً في مجتمع نبضة',
                        style: const TextStyle(fontSize: 11.5, color: _ink3)),
                  ],
                ]),
          );
        },
      );
}
