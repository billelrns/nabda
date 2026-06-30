// ═══════════════════════════════════════════════════════════════════
//  لوحة الرئيسية للويب — مطابقة لتصميم Nabda.dc.html (مرحلة الحمل)
//  تُستعمَل على الويب فقط (الشاشات الواسعة). تقرأ users/{uid} مباشرةً.
// ═══════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/dynamic_content_service.dart';

// ألوان التصميم
const _pink = Color(0xFFE91E63);
const _pink2 = Color(0xFFFF5252);
const _brand = Color(0xFFC2185B);
const _ink = Color(0xFF1F1A20);
const _ink2 = Color(0xFF4A434B);
const _muted = Color(0xFF9B8F95);
const _line = Color(0xFFF0E4EA);
const _bg = Color(0xFFFFF8FB);
const _lav = Color(0xFFEDE7F6);
const _lavText = Color(0xFF5E35B1);

class WebHomeDashboard extends StatelessWidget {
  final DocumentReference userDoc;
  final void Function(int) onTab; // 0=الرئيسية 1=الدورة 2=الحمل 3=الطفل 4=المتجر
  final VoidCallback onCommunity;
  final VoidCallback onHealth;
  final VoidCallback onProfile;
  final void Function(Map<String, String>) onOpenArticle;
  final Widget articlesSection; // قسم المقالات الحقيقي من التطبيق

  const WebHomeDashboard({
    Key? key,
    required this.userDoc,
    required this.onTab,
    required this.onCommunity,
    required this.onHealth,
    required this.onProfile,
    required this.onOpenArticle,
    required this.articlesSection,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: userDoc.snapshots(),
      builder: (context, snap) {
        final data = (snap.data?.data() as Map<String, dynamic>?) ?? {};
        final name = (data['displayName'] ?? data['name'] ?? '') as String;
        final stage = (data['lifeStage'] ?? '') as String;
        final pregTs = data['pregnancyStartDate'] ?? data['pregnancyStart'];
        DateTime? pregStart;
        if (pregTs is Timestamp) pregStart = pregTs.toDate();

        return LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth >= 880;
          return Container(
            color: _bg,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(wide ? 26 : 16, 22, wide ? 26 : 16, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _topBar(context, name, wide),
                  const SizedBox(height: 20),
                  if (pregStart != null)
                    _pregnantHome(context, name, pregStart, wide)
                  else
                    _genericHome(context, name, stage),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  // ── شريط علوي: تحية + بحث + إشعارات ──
  Widget _topBar(BuildContext context, String name, bool wide) {
    final greeting = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text('صباح الخير، ${name.isEmpty ? 'بكِ' : name}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(width: 8),
          const Text('🌸', style: TextStyle(fontSize: 20)),
        ]),
        const SizedBox(height: 2),
        const Text('جميل أن نراكِ اليوم!', style: TextStyle(fontSize: 14, color: _muted)),
      ],
    );
    if (!wide) return Align(alignment: Alignment.centerRight, child: greeting);
    return Row(children: [
      greeting,
      const Spacer(),
      Container(
        width: 360,
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(999), border: Border.all(color: _line)),
        child: Row(children: const [
          Icon(Icons.search_rounded, size: 20, color: _muted),
          SizedBox(width: 10),
          Text('ابحثي في نبضة...', style: TextStyle(fontSize: 14, color: _muted)),
        ]),
      ),
      const SizedBox(width: 12),
      _circleIcon(Icons.notifications_none_rounded, badge: '٣'),
      const SizedBox(width: 10),
      InkWell(onTap: onProfile, borderRadius: BorderRadius.circular(999), child: _circleIcon(Icons.person_outline_rounded)),
    ]);
  }

  Widget _circleIcon(IconData icon, {String? badge}) {
    return Stack(clipBehavior: Clip.none, children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: _line)),
        child: Icon(icon, size: 20, color: _ink2),
      ),
      if (badge != null)
        Positioned(top: -2, right: -2, child: Container(
          width: 18, height: 18, alignment: Alignment.center,
          decoration: const BoxDecoration(color: _pink, shape: BoxShape.circle),
          child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
        )),
    ]);
  }

  // ── لوحة الحمل ──
  Widget _pregnantHome(BuildContext context, String name, DateTime pregStart, bool wide) {
    final days = DateTime.now().difference(pregStart).inDays;
    final week = (days / 7).floor().clamp(1, 42);
    final daysLeft = (280 - days).clamp(0, 280);
    final fr = _fruitFor(week);
    final tri = week <= 13 ? 'الأول' : (week <= 27 ? 'الثاني' : 'الثالث');

    final main = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _heroCard(context, week, daysLeft, fr, tri),
      const SizedBox(height: 18),
      _quickActions(context, wide),
      const SizedBox(height: 18),
      if (wide) Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 3, child: _tipsCard()),
        const SizedBox(width: 16),
        Expanded(flex: 2, child: _appointmentsCard()),
      ]) else ...[_tipsCard(), const SizedBox(height: 16), _appointmentsCard()],
      const SizedBox(height: 18),
      _bottomBar(context, week),
    ]);

    final side = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _cycleMiniCard(context),
    ]);

    final dash = wide
        ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: main),
            const SizedBox(width: 20),
            SizedBox(width: 360, child: side),
          ])
        : Column(children: [main, const SizedBox(height: 18), side]);

    // قسم المقالات الحقيقي (ثابت + ديناميكي) بعرض كامل أسفل اللوحة
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      dash,
      const SizedBox(height: 22),
      articlesSection,
    ]);
  }

  Widget _heroCard(BuildContext context, int week, int daysLeft, _Fruit fr, String tri) {
    final ring = Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('حجم طفلكِ', style: TextStyle(fontSize: 13, color: _muted)),
      const SizedBox(height: 6),
      Container(
        width: 130, height: 130, alignment: Alignment.center,
        decoration: const BoxDecoration(color: Color(0xFFF8BBD0), shape: BoxShape.circle),
        child: Container(
          width: 108, height: 108, alignment: Alignment.center,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: Text(fr.emoji, style: const TextStyle(fontSize: 52)),
        ),
      ),
      const SizedBox(height: 10),
      Text('${fr.name} صغيرة', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _ink)),
      const SizedBox(height: 12),
      Container(
        margin: const EdgeInsets.only(top: 2),
        padding: const EdgeInsets.only(top: 10),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF6D6E2)))),
        child: Column(children: [
          Text('$daysLeft', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _brand, height: 1)),
          const Text('يوم متبقٍّ للولادة', style: TextStyle(fontSize: 12, color: _muted)),
        ]),
      ),
    ]);

    final info = Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      const Text('أنتِ الآن في', style: TextStyle(fontSize: 15, color: _ink2)),
      Row(mainAxisSize: MainAxisSize.min, children: [
        Text('الأسبوع $week', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: _ink)),
        const SizedBox(width: 8),
        const Text('🌸', style: TextStyle(fontSize: 20)),
      ]),
      Text('الثلث $tri', style: const TextStyle(fontSize: 14, color: _muted)),
      const SizedBox(height: 10),
      Text('طفلكِ ينمو بثبات هذا الأسبوع. تابعي تطوّره أسبوعًا بأسبوع واحرصي على التغذية والراحة.',
          style: const TextStyle(fontSize: 14, color: _ink2, height: 1.7)),
      const SizedBox(height: 16),
      ElevatedButton(
        onPressed: () => onTab(2),
        style: ElevatedButton.styleFrom(
          backgroundColor: _pink, foregroundColor: Colors.white, elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
        child: const Text('عرض التفاصيل', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      ),
    ]);

    return _decor(
      gradient: const LinearGradient(colors: [Color(0xFFFDEFF4), Color(0xFFFCE4EC), Color(0xFFFBD9E6)]),
      border: const Color(0xFFF8E1EA),
      padding: const EdgeInsets.all(26),
      child: LayoutBuilder(builder: (context, c) {
        final showImg = c.maxWidth >= 540;
        if (c.maxWidth < 520) {
          return Column(children: [ring, const SizedBox(height: 18), info]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          SizedBox(width: 160, child: ring),
          const SizedBox(width: 18),
          Expanded(child: info),
          if (showImg) ...[
            const SizedBox(width: 8),
            Image.asset('assets/images/mom.png', height: 250, fit: BoxFit.contain),
          ],
        ]);
      }),
    );
  }

  Widget _quickActions(BuildContext context, bool wide) {
    final items = <List<dynamic>>[
      ['🧠', 'الصحة النفسية', const Color(0xFFEDE7F6), () => onTab(2)],
      ['🥗', 'التغذية', const Color(0xFFFFF3E0), () => onTab(2)],
      ['🧘🏻‍♀️', 'التمارين', const Color(0xFFFCE4EC), () => onTab(2)],
      ['📖', 'المقالات', const Color(0xFFEDE7F6), onHealth],
      ['👥', 'المجتمع', const Color(0xFFFCE4EC), onCommunity],
      ['🛍️', 'المتجر', const Color(0xFFE0F2F1), () => onTab(4)],
      ['🩺', 'الملف الطبي', const Color(0xFFFCE4EC), onHealth],
    ];
    final cols = wide ? 7 : 4;
    return GridView.count(
      crossAxisCount: cols,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.92,
      children: [
        for (final it in items)
          _qaCard(it[0] as String, it[1] as String, it[2] as Color, it[3] as VoidCallback),
      ],
    );
  }

  Widget _qaCard(String emoji, String label, Color bg, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: _line)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 44, height: 44, alignment: Alignment.center,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(13)),
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: _ink)),
        ]),
      ),
    );
  }

  Widget _tipsCard() {
    final tips = [
      ['💧', 'اشربي المزيد من الماء', 'حاولي شرب ٨ أكواب يوميًا للحفاظ على ترطيب جسمكِ.', const Color(0xFFEDE7F6), _lavText],
      ['🥣', 'تناولي البروتين', 'البروتين مهم لنمو طفلكِ، أضيفيه لوجباتكِ اليومية.', const Color(0xFFFCE4EC), _brand],
      ['🚶🏻‍♀️', 'مشي خفيف', '٣٠ دقيقة يوميًا تحسّن مزاجكِ ونومكِ.', const Color(0xFFFFF3E0), const Color(0xFFFB8C00)],
    ];
    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
          Text('نصائح اليوم 🌱', style: TextStyle(fontWeight: FontWeight.w800, color: _ink)),
          Text('عرض الكل', style: TextStyle(fontSize: 12, color: _brand, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 14),
        LayoutBuilder(builder: (context, c) {
          final row = c.maxWidth >= 460;
          final cards = [for (final t in tips) _tipBox(t)];
          if (row) {
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (int i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: cards[i]),
              ],
            ]);
          }
          return Column(children: [
            for (int i = 0; i < cards.length; i++) ...[if (i > 0) const SizedBox(height: 12), cards[i]],
          ]);
        }),
      ]),
    );
  }

  Widget _tipBox(List<dynamic> t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: t[3] as Color, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t[0] as String, style: const TextStyle(fontSize: 26)),
        const SizedBox(height: 8),
        Text(t[1] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: t[4] as Color)),
        const SizedBox(height: 4),
        Text(t[2] as String, style: const TextStyle(fontSize: 12, color: _ink2, height: 1.6)),
      ]),
    );
  }

  Widget _appointmentsCard() {
    Widget row(String emoji, Color bg, String title, String sub, {bool border = false}) => Container(
          padding: EdgeInsets.only(bottom: border ? 14 : 0, top: border ? 0 : 14),
          decoration: border ? const BoxDecoration(border: Border(bottom: BorderSide(color: _line))) : null,
          child: Row(children: [
            Container(width: 44, height: 44, alignment: Alignment.center,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle), child: Text(emoji, style: const TextStyle(fontSize: 22))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _ink)),
              Text(sub, style: const TextStyle(fontSize: 12, color: _muted)),
            ])),
          ]),
        );
    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('المواعيد القادمة 📅', style: TextStyle(fontWeight: FontWeight.w800, color: _ink)),
        const SizedBox(height: 6),
        row('👩🏻‍⚕️', const Color(0xFFFCE4EC), 'فحص دوري', 'د. هبة محمد · ١٢ يونيو · ١٠:٠٠ ص', border: true),
        row('🧪', const Color(0xFFEDE7F6), 'تحليل دم', 'مختبر الحياة · ١٨ يونيو · ٩:٣٠ ص'),
        const SizedBox(height: 14),
        InkWell(onTap: onHealth, child: const Center(
          child: Text('عرض جميع المواعيد ←', style: TextStyle(fontSize: 13, color: _brand, fontWeight: FontWeight.w800)),
        )),
      ]),
    );
  }

  Widget _cycleMiniCard(BuildContext context) {
    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('متابعة الدورة 📅', style: TextStyle(fontWeight: FontWeight.w800, color: _ink)),
        const SizedBox(height: 16),
        Center(child: InkWell(
          onTap: () => onTab(1),
          customBorder: const CircleBorder(),
          child: Container(
            width: 180, height: 180, alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(colors: [
                Color(0xFFE91E63), Color(0xFF7E57C2), Color(0xFF42A5F5), Color(0xFF43A047), Color(0xFFFFA726), Color(0xFFE91E63),
              ]),
            ),
            child: Container(
              width: 140, height: 140, alignment: Alignment.center,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Column(mainAxisSize: MainAxisSize.min, children: const [
                Text('اليوم', style: TextStyle(fontSize: 12, color: _muted)),
                Text('٩', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: _ink, height: 1)),
                Text('من ٢٨', style: TextStyle(fontSize: 12, color: _muted)),
              ]),
            ),
          ),
        )),
        const SizedBox(height: 18),
        ElevatedButton(
          onPressed: () => onTab(1),
          style: ElevatedButton.styleFrom(
            backgroundColor: _bg, foregroundColor: _brand, elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: const BorderSide(color: _line),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
          child: const Text('📅 عرض تقويم الدورة', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        ),
      ]),
    );
  }

  Widget _articleCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: DynamicContentService.getArticles(section: 'home'),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
            Text('مقالات مميزة', style: TextStyle(fontWeight: FontWeight.w800, color: _ink)),
            Text('عرض الكل', style: TextStyle(fontSize: 12, color: _brand, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 12),
          if (docs.isEmpty)
            _articleEmpty()
          else
            for (final d in docs.take(2)) _articleItem(DynamicContentService.docToArticle(d)),
        ]));
      },
    );
  }

  Widget _articleItem(Map<String, String> a) {
    final img = a['image'] ?? '';
    final cat = a['category'] ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: () => onOpenArticle(a),
        borderRadius: BorderRadius.circular(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: img.isEmpty
                ? _imgFallback()
                : Image.network(img, height: 130, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imgFallback()),
          ),
          const SizedBox(height: 8),
          if (cat.isNotEmpty) ...[
            Align(alignment: Alignment.centerRight, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFFCE4EC), borderRadius: BorderRadius.circular(999)),
              child: Text(cat, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _brand)),
            )),
            const SizedBox(height: 6),
          ],
          Text(a['title'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _ink)),
          const SizedBox(height: 4),
          Text(a['content'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: _ink2, height: 1.5)),
        ]),
      ),
    );
  }

  Widget _imgFallback() => Container(
        height: 130, alignment: Alignment.center,
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFCE4EC), Color(0xFFEDE7F6)])),
        child: const Text('📰', style: TextStyle(fontSize: 36)),
      );

  Widget _articleEmpty() => Container(
        height: 120, alignment: Alignment.center,
        decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(14)),
        child: const Text('ستظهر المقالات هنا فور إضافتها', style: TextStyle(fontSize: 13, color: _muted)),
      );

  Widget _bottomBar(BuildContext context, int week) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF8E1EA)),
        gradient: const LinearGradient(colors: [Color(0xFFFCE4EC), Color(0xFFFFF0F6)]),
      ),
      child: LayoutBuilder(builder: (context, c) {
        final btn = ElevatedButton(
          onPressed: () => onTab(2),
          style: ElevatedButton.styleFrom(
            backgroundColor: _pink, foregroundColor: Colors.white, elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
          child: const Text('تسجيل يومياتي +', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        );
        final msg = Text('✨ الأسبوع $week — طفلكِ ينمو بشكل رائع، لا تنسي ترطيب جسمكِ اليوم!',
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _brand));
        if (c.maxWidth < 520) return Column(children: [btn, const SizedBox(height: 10), msg]);
        return Row(children: [btn, const SizedBox(width: 14), Expanded(child: msg)]);
      }),
    );
  }

  // ── مرحلة غير الحمل: تحية + بطاقة تفتح القسم ──
  Widget _genericHome(BuildContext context, String name, String stage) {
    final map = {
      'cycle': ['متابعة الدورة', '📅', 1],
      'planning': ['الخصوبة وأيام التبويض', '💕', 1],
      'baby': ['رعاية طفلكِ', '👶', 3],
    };
    final info = map[stage] ?? ['ابدئي رحلتكِ مع نبضة', '💗', 0];
    return _decor(
      gradient: const LinearGradient(colors: [Color(0xFFFDEFF4), Color(0xFFFCE4EC)]),
      border: const Color(0xFFF8E1EA),
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(info[1] as String, style: const TextStyle(fontSize: 44)),
        const SizedBox(height: 10),
        Text(info[0] as String, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _ink)),
        const SizedBox(height: 8),
        const Text('افتحي قسمكِ لمتابعة كل التفاصيل والنصائح المخصّصة لكِ.',
            style: TextStyle(fontSize: 14, color: _ink2, height: 1.6)),
        const SizedBox(height: 18),
        ElevatedButton(
          onPressed: () => onTab(info[2] as int),
          style: ElevatedButton.styleFrom(
            backgroundColor: _pink, foregroundColor: Colors.white, elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
          child: const Text('افتحي القسم ←', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        ),
      ]),
    );
  }

  // ── أدوات ──
  Widget _card({required Widget child}) => _decor(
        gradient: null, color: Colors.white, border: _line,
        padding: const EdgeInsets.all(20), child: child,
      );

  Widget _decor({Widget? child, Gradient? gradient, Color? color, required Color border, required EdgeInsets padding}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color, gradient: gradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }

  _Fruit _fruitFor(int w) {
    if (w <= 5) return const _Fruit('🌱', 'بذرة');
    if (w <= 7) return const _Fruit('🫐', 'توتة');
    if (w <= 9) return const _Fruit('🍒', 'كرزة');
    if (w <= 11) return const _Fruit('🍓', 'فراولة');
    if (w <= 13) return const _Fruit('🍋', 'ليمونة');
    if (w <= 16) return const _Fruit('🍊', 'برتقالة');
    if (w <= 19) return const _Fruit('🥑', 'أفوكادو');
    if (w <= 22) return const _Fruit('🍌', 'موزة');
    if (w <= 25) return const _Fruit('🌽', 'ذرة');
    if (w <= 28) return const _Fruit('🥦', 'قرنبيط');
    if (w <= 31) return const _Fruit('🥥', 'جوز هند');
    if (w <= 34) return const _Fruit('🍍', 'أناناس');
    if (w <= 37) return const _Fruit('🍈', 'شمّام');
    return const _Fruit('🍉', 'بطيخة');
  }
}

class _Fruit {
  final String emoji;
  final String name;
  const _Fruit(this.emoji, this.name);
}
