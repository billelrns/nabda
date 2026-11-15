// ═══════════════════════════════════════════════════════════════════
//  كاروسال أندية الولادة — نفس تصميم الموقع (web/js/pages/community.js)
//  أيقونة ولون لكل شهر (assets/images/clubs/month_MM.webp)، الشهر المعروض في الوسط
//  والأشهر المجاورة يميناً ويساراً، طفو خفيف للأيقونة، سحب للتنقّل.
// ═══════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/cohort_service.dart';

/// لون الخلفية الفاتح + اللون المميّز لكل شهر (مطابق لـ MONTH_THEME في الموقع)
class ClubMonthTheme {
  final Color bg;
  final Color accent;
  const ClubMonthTheme(this.bg, this.accent);

  static const List<ClubMonthTheme> _all = [
    ClubMonthTheme(Color(0xFFFFE4EC), Color(0xFFE2437A)), // جانفي
    ClubMonthTheme(Color(0xFFEFE6FA), Color(0xFF8A55C6)), // فيفري
    ClubMonthTheme(Color(0xFFDFF4F2), Color(0xFF1A958D)), // مارس
    ClubMonthTheme(Color(0xFFFFEBDD), Color(0xFFE8701F)), // أفريل
    ClubMonthTheme(Color(0xFFE3EFFC), Color(0xFF3580CF)), // ماي
    ClubMonthTheme(Color(0xFFFFE6EF), Color(0xFFE04C86)), // جوان
    ClubMonthTheme(Color(0xFFFFF4D4), Color(0xFFC98F00)), // جويلية
    ClubMonthTheme(Color(0xFFE4F4E3), Color(0xFF378F48)), // أوت
    ClubMonthTheme(Color(0xFFF0E6F8), Color(0xFF9554C3)), // سبتمبر
    ClubMonthTheme(Color(0xFFFFE5E8), Color(0xFFE04A66)), // أكتوبر
    ClubMonthTheme(Color(0xFFE2EEFA), Color(0xFF2C78BE)), // نوفمبر
    ClubMonthTheme(Color(0xFFFFF1D8), Color(0xFFBF820C)), // ديسمبر
  ];

  static int monthOf(String key) {
    final p = key.split('_');
    final m = p.length >= 3 ? int.tryParse(p[2]) ?? 1 : 1;
    return m.clamp(1, 12).toInt();
  }

  static ClubMonthTheme of(String key) => _all[monthOf(key) - 1];
  static String icon(String key) => 'assets/images/clubs/month_${monthOf(key).toString().padLeft(2, '0')}.webp';
  static String monthName(String key) => CohortService.monthsAr[monthOf(key)];
  static String year(String key) {
    final p = key.split('_');
    return p.length >= 2 ? p[1] : '';
  }
}

/// أيقونة الشهر — تطفو صعوداً ونزولاً (4 ثوانٍ) مثل الموقع
class ClubMonthIcon extends StatefulWidget {
  final String cohortKey;
  final double size;
  final bool float;
  const ClubMonthIcon({super.key, required this.cohortKey, this.size = 64, this.float = false});

  @override
  State<ClubMonthIcon> createState() => _ClubMonthIconState();
}

class _ClubMonthIconState extends State<ClubMonthIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 2));

  @override
  void initState() {
    super.initState();
    if (widget.float) _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ClubMonthTheme.of(widget.cohortKey);
    final img = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: t.accent.withOpacity(widget.float ? 0.28 : 0.12), blurRadius: widget.float ? 18 : 8, offset: const Offset(0, 6))],
      ),
      child: ClipOval(
        child: Image.asset(
          ClubMonthTheme.icon(widget.cohortKey),
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: t.bg, alignment: Alignment.center, child: Text('🤱', style: TextStyle(fontSize: widget.size * 0.45))),
        ),
      ),
    );
    if (!widget.float || MediaQuery.of(context).disableAnimations) return img;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Transform.translate(offset: Offset(0, -6 * Curves.easeInOut.transform(_c.value)), child: child),
      child: img,
    );
  }
}

/// عدد عضوات النوادي (مخبّأ في الذاكرة لتفادي القراءات المتكرّرة)
class ClubCounts {
  static final Map<String, int> _cache = {};
  static Future<int> of(String key) async {
    if (_cache.containsKey(key)) return _cache[key]!;
    try {
      final d = await FirebaseFirestore.instance.collection('cohort_members_count').doc(key).get();
      final n = ((d.data()?['memberCount'] ?? 0) as num).toInt();
      _cache[key] = n < 0 ? 0 : n;
    } catch (_) {
      _cache[key] = 0;
    }
    return _cache[key]!;
  }
}

/// الكاروسال: [السابق] [شهر-1] [الشهر المعروض] [شهر+1] [التالي] — في RTL السابق على اليمين
class ClubMonthCarousel extends StatelessWidget {
  final String viewKey;
  final String myKey;
  final ValueChanged<String> onSelect;
  final VoidCallback onOpenAll;
  const ClubMonthCarousel({super.key, required this.viewKey, required this.myKey, required this.onSelect, required this.onOpenAll});

  @override
  Widget build(BuildContext context) {
    final keys = CohortService.nearbyKeys(viewKey, span: 1); // [-1, الحالي, +1]
    if (keys.length < 3) return const SizedBox.shrink();
    final visiting = viewKey != myKey;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 6),
        child: Column(children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: (d) {
              final v = d.primaryVelocity ?? 0;
              if (v.abs() < 250) return;
              onSelect(v > 0 ? keys[2] : keys[0]); // السحب يميناً = الشهر التالي في RTL
            },
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              _NavButton(right: true, onTap: () => onSelect(keys[0]), tooltip: 'الشهر السابق'),
              const SizedBox(width: 4),
              _SideCard(cohortKey: keys[0], mine: keys[0] == myKey, onTap: () => onSelect(keys[0])),
              const SizedBox(width: 6),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, a) => FadeTransition(opacity: a, child: ScaleTransition(scale: Tween(begin: 0.96, end: 1.0).animate(a), child: child)),
                  child: _CenterCard(key: ValueKey(viewKey), cohortKey: viewKey, visiting: visiting, myKey: myKey, onBack: () => onSelect(myKey)),
                ),
              ),
              const SizedBox(width: 6),
              _SideCard(cohortKey: keys[2], mine: keys[2] == myKey, onTap: () => onSelect(keys[2])),
              const SizedBox(width: 4),
              _NavButton(right: false, onTap: () => onSelect(keys[2]), tooltip: 'الشهر التالي'),
            ]),
          ),
          const SizedBox(height: 8),
          Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Text(
              visiting ? 'للاطّلاع والتعلّم — النشر يكون في ناديكِ فقط · ' : 'أمهات موعد ولادتهنّ في نفس الشهر يتقاسمن التجربة 💗 · ',
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
            ),
            InkWell(
              onTap: onOpenAll,
              child: const Text('كل الأندية', style: TextStyle(fontSize: 11.5, color: Color(0xFFE91E63), fontWeight: FontWeight.w800)),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final bool right;
  final VoidCallback onTap;
  final String tooltip;
  const _NavButton({required this.right, required this.onTap, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFF43F7E).withOpacity(0.2)),
            boxShadow: [BoxShadow(color: const Color(0xFFF43F7E).withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          // اتجاه صريح: الزر الأيمن يشير لليمين والأيسر لليسار (بلا انعكاس RTL)
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Icon(right ? Icons.chevron_right_rounded : Icons.chevron_left_rounded, size: 20, color: const Color(0xFFF43F7E)),
          ),
        ),
      ),
    );
  }
}

class _SideCard extends StatelessWidget {
  final String cohortKey;
  final bool mine;
  final VoidCallback onTap;
  const _SideCard({required this.cohortKey, required this.mine, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = ClubMonthTheme.of(cohortKey);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 74,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [t.bg, Color.lerp(t.bg, Colors.white, 0.45)!]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: mine ? t.accent : Colors.white, width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ClubMonthIcon(cohortKey: cohortKey, size: 46),
          const SizedBox(height: 4),
          Text(ClubMonthTheme.monthName(cohortKey), maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: t.accent)),
          Text(ClubMonthTheme.year(cohortKey), style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.grey.shade500)),
          if (mine)
            Text('⭐ ناديكِ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: t.accent))
          else
            FutureBuilder<int>(
              future: ClubCounts.of(cohortKey),
              builder: (_, s) => Text(s.hasData ? '${s.data} عضوة' : ' ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey.shade700)),
            ),
        ]),
      ),
    );
  }
}

class _CenterCard extends StatelessWidget {
  final String cohortKey;
  final String myKey;
  final bool visiting;
  final VoidCallback onBack;
  const _CenterCard({super.key, required this.cohortKey, required this.myKey, required this.visiting, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final t = ClubMonthTheme.of(cohortKey);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 14),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.25),
          radius: 0.9,
          colors: [Colors.white, Color.lerp(t.bg, Colors.white, 0.35)!, t.bg],
          stops: const [0, 0.38, 1],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: t.accent.withOpacity(0.22), width: 1.5),
        boxShadow: [BoxShadow(color: t.accent.withOpacity(0.22), blurRadius: 26, offset: const Offset(0, 12))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)]),
          child: Text(visiting ? '👀 تتصفّحين هذا النادي' : '🤱 ناديكِ — انضممتِ تلقائياً',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: t.accent)),
        ),
        const SizedBox(height: 8),
        ClubMonthIcon(cohortKey: cohortKey, size: 92, float: true),
        const SizedBox(height: 4),
        Text(ClubMonthTheme.monthName(cohortKey), style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: t.accent, height: 1.2)),
        Text(CohortService.labelForKey(cohortKey), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF4A4050))),
        const SizedBox(height: 8),
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('cohort_members_count').doc(cohortKey).snapshots(),
          builder: (_, s) {
            final n = ((s.data?.data()?['memberCount'] ?? 0) as num).toInt();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: Color.lerp(t.accent, Colors.white, 0.86), borderRadius: BorderRadius.circular(999)),
              child: Text('${n < 0 ? 0 : n} عضوة', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: t.accent)),
            );
          },
        ),
        if (visiting) ...[
          const SizedBox(height: 10),
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(color: t.accent, borderRadius: BorderRadius.circular(12)),
              child: Text('↩ العودة إلى ناديكِ (${ClubMonthTheme.monthName(myKey)})',
                  style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ]),
    );
  }
}

/// بطاقة نادٍ في منتقي «كل الأندية» (شبكة ملوّنة بالأيقونات)
class ClubPickerTile extends StatelessWidget {
  final String cohortKey;
  final bool mine;
  final bool current;
  final VoidCallback onTap;
  const ClubPickerTile({super.key, required this.cohortKey, required this.mine, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = ClubMonthTheme.of(cohortKey);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
        decoration: BoxDecoration(
          color: t.bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: mine ? t.accent : Colors.transparent, width: 1.5),
          boxShadow: current ? [BoxShadow(color: t.accent.withOpacity(0.3), spreadRadius: 2, blurRadius: 0)] : null,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ClubMonthIcon(cohortKey: cohortKey, size: 54),
          const SizedBox(height: 6),
          Text(CohortService.labelForKey(cohortKey), textAlign: TextAlign.center, maxLines: 2,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: t.accent, height: 1.25)),
          const SizedBox(height: 2),
          if (mine)
            Text('⭐ ناديكِ', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: t.accent))
          else
            FutureBuilder<int>(
              future: ClubCounts.of(cohortKey),
              builder: (_, s) => Text(s.hasData ? '${s.data} عضوة' : ' ', style: TextStyle(fontSize: 10.5, color: Colors.grey.shade700, fontWeight: FontWeight.w700)),
            ),
        ]),
      ),
    );
  }
}
