// ═══════════════════════════════════════════════════════════════════
//  صفحة الحمل للويب — مطابقة لتصميم Nabda (الحمل). تُستعمَل على الويب فقط.
//  تُعيد استخدام صور الجنين (assets/images/fetus) وبيانات الأسابيع.
// ═══════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/dynamic_content_service.dart';
import '../utils/article_images.dart';

const _pink = Color(0xFFE91E63);
const _pink2 = Color(0xFFFF5252);
const _brand = Color(0xFFC2185B);
const _ink = Color(0xFF1F1A20);
const _ink2 = Color(0xFF4A434B);
const _muted = Color(0xFF9B8F95);
const _line = Color(0xFFF0E4EA);
const _bg = Color(0xFFFFF8FB);

class WebPregnancyPage extends StatelessWidget {
  final DocumentReference userDoc;
  final void Function(int) onTab;
  final VoidCallback onProfile;
  final void Function(Map<String, String>) onOpenArticle;
  final Widget articlesSection; // قسم المقالات الحقيقي من التطبيق

  const WebPregnancyPage({
    Key? key,
    required this.userDoc,
    required this.onTab,
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
        final pregTs = data['pregnancyStartDate'] ?? data['pregnancyStart'];
        DateTime? start;
        if (pregTs is Timestamp) start = pregTs.toDate();

        return Container(
          color: _bg,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 30),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _topBar(context, name),
              const SizedBox(height: 18),
              if (start == null)
                _noPreg(context)
              else
                _content(context, start),
            ]),
          ),
        );
      },
    );
  }

  Widget _topBar(BuildContext context, String name) {
    return Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text('مرحبا ${name.isEmpty ? 'بكِ' : name}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(width: 8),
          const Text('👋', style: TextStyle(fontSize: 20)),
        ]),
        const SizedBox(height: 2),
        const Text('نتمنى لكِ يومًا جميلًا', style: TextStyle(fontSize: 14, color: _muted)),
      ])),
      InkWell(
        onTap: onProfile,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [_pink, _pink2]),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [BoxShadow(color: _pink.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: const Center(child: Text('👩🏻', style: TextStyle(fontSize: 22))),
        ),
      ),
    ]);
  }

  Widget _content(BuildContext context, DateTime start) {
    final days = DateTime.now().difference(start).inDays;
    final week = (days / 7).floor().clamp(1, 42);
    final d = _dataFor(week);
    final daysLeft = (280 - days).clamp(0, 280);
    final progress = (week / 40 * 100).clamp(0, 100).round();
    final month = (week / 4.345).ceil().clamp(1, 10);
    final end = start.add(const Duration(days: 280));

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _hero(week, month, daysLeft, progress, d, start, end),
      const SizedBox(height: 18),
      _statsRow(d),
      const SizedBox(height: 18),
      _midRow(context, d),
      const SizedBox(height: 18),
      _bottomRow(context, week, d),
      const SizedBox(height: 18),
      articlesSection,
    ]);
  }

  // ── Hero ──
  Widget _hero(int week, int month, int daysLeft, int progress, _Wk d, DateTime start, DateTime end) {
    final textBlock = Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text('الأسبوع $week من الحمل',
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white)),
      const SizedBox(height: 8),
      Text('الشهر ${_ord(month)}  •  بقي $daysLeft يوم على موعد الولادة',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
      const SizedBox(height: 20),
      // شريط التقدّم
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
          child: Text('$progress%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _brand)),
        ),
        const SizedBox(width: 12),
        Expanded(child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress / 100, minHeight: 12,
            backgroundColor: Colors.white.withOpacity(0.35),
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
        )),
      ]),
      const SizedBox(height: 14),
      Text('من ${_dateAr(start)} إلى ${_dateAr(end)}',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.9))),
    ]);

    final fetus = Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
      Container(
        width: 200, height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.18),
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
        ),
        child: ClipOval(child: Image.asset(_fetusAsset(week), fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Center(child: Text(d.emoji, style: const TextStyle(fontSize: 80))))),
      ),
      Positioned(
        bottom: 6, right: -8,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10)]),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(d.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text('بحجم\n${d.fruit}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _ink, height: 1.2)),
          ]),
        ),
      ),
    ]);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(colors: [Color(0xFFEC4F8E), Color(0xFFE91E63)],
            begin: Alignment.centerRight, end: Alignment.centerLeft),
        boxShadow: [BoxShadow(color: _pink.withOpacity(0.25), blurRadius: 26, offset: const Offset(0, 12))],
      ),
      child: LayoutBuilder(builder: (context, c) {
        if (c.maxWidth < 640) {
          return Column(children: [fetus, const SizedBox(height: 20), textBlock]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(child: textBlock),
          const SizedBox(width: 24),
          fetus,
        ]);
      }),
    );
  }

  // ── بطاقات الحجم/الوزن/الطول ──
  Widget _statsRow(_Wk d) {
    final cards = [
      _statCard('🥝', 'حجم الجنين', d.fruit, 'بحجم ثمرة ${d.fruit}', const Color(0xFFE0F2F1), const Color(0xFF00897B)),
      _statCard('⚖️', 'الوزن', d.weight, 'تقديري لهذا الأسبوع', const Color(0xFFEDE7F6), const Color(0xFF7E57C2)),
      _statCard('📏', 'الطول', d.length, 'من الرأس إلى المقعدة', const Color(0xFFE3F2FD), const Color(0xFF42A5F5)),
    ];
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < 640) return Column(children: [for (final x in cards) Padding(padding: const EdgeInsets.only(bottom: 12), child: x)]);
      return Row(children: [
        for (int i = 0; i < cards.length; i++) ...[if (i > 0) const SizedBox(width: 16), Expanded(child: cards[i])],
      ]);
    });
  }

  Widget _statCard(String emoji, String label, String value, String sub, Color tint, Color accent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: tint.withOpacity(0.45), borderRadius: BorderRadius.circular(20), border: Border.all(color: _line)),
      child: Row(children: [
        Container(width: 56, height: 56, alignment: Alignment.center,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: Text(emoji, style: const TextStyle(fontSize: 28))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: accent)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 12, color: _muted)),
        ])),
      ]),
    );
  }

  // ── تطوّر الجنين + مقالات ──
  Widget _midRow(BuildContext context, _Wk d) {
    final dev = _card(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
        Text('تطوّر الجنين هذا الأسبوع 💓', style: TextStyle(fontWeight: FontWeight.w800, color: _ink)),
      ]),
      const SizedBox(height: 14),
      for (final t in d.dev) Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [
        Container(width: 22, height: 22, alignment: Alignment.center,
          decoration: const BoxDecoration(color: Color(0xFF43A047), shape: BoxShape.circle),
          child: const Icon(Icons.check, size: 14, color: Colors.white)),
        const SizedBox(width: 10),
        Expanded(child: Text(t, style: const TextStyle(fontSize: 14, color: _ink2, fontWeight: FontWeight.w600))),
      ])),
      const SizedBox(height: 4),
      InkWell(onTap: () => onTab(2), child: const Center(child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Text('عرض المزيد', style: TextStyle(fontSize: 13, color: _brand, fontWeight: FontWeight.w800))))),
    ]));

    return dev;
  }

  Widget _articlesCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: DynamicContentService.getArticles(section: 'pregnancy'),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
            Text('مقالات مفيدة لكِ', style: TextStyle(fontWeight: FontWeight.w800, color: _ink)),
            Text('عرض الكل', style: TextStyle(fontSize: 11, color: _brand, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 12),
          if (docs.isEmpty)
            _articleEmpty()
          else
            for (final dd in docs.take(3)) _articleItem(DynamicContentService.docToArticle(dd)),
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
            child: ArticleImage(
              title: (a['title'] ?? '').toString(),
              section: 'pregnancy',
              networkUrl: img,
              height: 130,
              fit: BoxFit.cover,
            ),
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
          const SizedBox(height: 6),
          const Text('اقرأ المزيد ←', style: TextStyle(fontSize: 12, color: _brand, fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }

  Widget _imgFallback() => Container(
        height: 130, alignment: Alignment.center,
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFCE4EC), Color(0xFFE3F2FD)])),
        child: const Text('📰', style: TextStyle(fontSize: 36)),
      );

  Widget _articleEmpty() => Container(
        height: 120, alignment: Alignment.center,
        decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(14)),
        child: const Text('ستظهر المقالات هنا فور إضافتها', style: TextStyle(fontSize: 13, color: _muted)),
      );

  // ── التذكيرات + الجدول الزمني + الحجم ──
  Widget _bottomRow(BuildContext context, int week, _Wk d) {
    final reminders = _card(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('تذكيرات هذا الأسبوع 🔔', style: TextStyle(fontWeight: FontWeight.w800, color: _ink)),
      const SizedBox(height: 14),
      _remRow('📅', 'موعد الطبيب بعد ٣ أيام'),
      _remRow('💧', 'شرب ١ لتر من الماء يوميًا'),
      _remRow('💊', 'تناول حمض الفوليك يوميًا'),
      _remRow('🚶🏻‍♀️', 'ممارسة المشي ٣٠ دقيقة'),
    ]));

    final timeline = _card(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('الجدول الزمني للحمل 📅', style: TextStyle(fontWeight: FontWeight.w800, color: _ink)),
      const SizedBox(height: 18),
      _timeline(week),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12)),
        child: Text('💗 أنتِ في الأسبوع $week — استمتعي بكل لحظة',
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _brand)),
      ),
    ]));

    final size = _card(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        const Text('حجم الجنين', style: TextStyle(fontWeight: FontWeight.w800, color: _brand)),
        const SizedBox(width: 6),
        Text(d.emoji, style: const TextStyle(fontSize: 18)),
      ]),
      const SizedBox(height: 12),
      Center(child: Container(width: 96, height: 96, alignment: Alignment.center,
        decoration: const BoxDecoration(color: Color(0xFFF1F8E9), shape: BoxShape.circle),
        child: Text(d.emoji, style: const TextStyle(fontSize: 46)))),
      const SizedBox(height: 10),
      Center(child: Text('بحجم ثمرة ${d.fruit}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _ink2))),
      const SizedBox(height: 14),
      _kv('📏', 'الطول', d.length),
      const SizedBox(height: 8),
      _kv('⚖️', 'الوزن', d.weight),
    ]));

    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < 760) {
        return Column(children: [reminders, const SizedBox(height: 16), timeline, const SizedBox(height: 16), size]);
      }
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: reminders),
        const SizedBox(width: 16),
        Expanded(flex: 2, child: timeline),
        const SizedBox(width: 16),
        Expanded(child: size),
      ]);
    });
  }

  Widget _remRow(String emoji, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 18)),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 13.5, color: _ink2, fontWeight: FontWeight.w600))),
    ]),
  );

  Widget _kv(String emoji, String k, String v) => Row(children: [
    Text(emoji, style: const TextStyle(fontSize: 16)),
    const SizedBox(width: 8),
    Text(k, style: const TextStyle(fontSize: 13, color: _muted)),
    const Spacer(),
    Text(v, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _ink)),
  ]);

  Widget _timeline(int week) {
    const milestones = [4, 12, 20, 30, 40];
    // أقرب معلم للأسبوع الحالي
    int activeIdx = 0;
    for (int i = 0; i < milestones.length; i++) {
      if (week >= milestones[i]) activeIdx = i;
    }
    return Row(children: [
      for (int i = 0; i < milestones.length; i++) ...[
        if (i > 0) Expanded(child: Container(height: 3, color: i <= activeIdx ? const Color(0xFF43A047) : _line)),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 16, height: 16,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: i <= activeIdx ? const Color(0xFF43A047) : _line)),
          const SizedBox(height: 6),
          Text('الأسبوع ${milestones[i]}',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
              color: i == activeIdx ? const Color(0xFF2E7D32) : _muted)),
        ]),
      ],
    ]);
  }

  Widget _noPreg(BuildContext context) => _card(child: Column(children: [
    const Text('🤰', style: TextStyle(fontSize: 44)),
    const SizedBox(height: 10),
    const Text('لم تُسجَّل بيانات الحمل بعد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _ink)),
    const SizedBox(height: 6),
    const Text('أدخلي تاريخ بداية الحمل من التطبيق لمتابعة رحلتكِ أسبوعًا بأسبوع.',
        textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: _ink2)),
  ]));

  // ── أدوات ──
  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _line)),
    child: child,
  );

  static const _jpg = {4, 5, 8, 11, 14, 17, 20, 23, 26, 28, 35, 38};
  String _fetusAsset(int w) {
    final ww = w.clamp(4, 41);
    return 'assets/images/fetus/week_$ww.${_jpg.contains(ww) ? 'jpg' : 'png'}';
  }

  String _ord(int n) {
    const o = ['', 'الأول', 'الثاني', 'الثالث', 'الرابع', 'الخامس', 'السادس', 'السابع', 'الثامن', 'التاسع', 'العاشر'];
    return (n >= 1 && n < o.length) ? o[n] : '$n';
  }

  String _dateAr(DateTime d) {
    const m = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  _Wk _dataFor(int week) {
    // أقرب أسبوع ≤ المطلوب
    int key = _wk.keys.first;
    for (final k in _wk.keys) {
      if (k <= week) key = k;
    }
    return _wk[key]!;
  }
}

class _Wk {
  final String emoji, fruit, length, weight;
  final List<String> dev;
  const _Wk(this.emoji, this.fruit, this.length, this.weight, this.dev);
}

// جدول الأسابيع (مأخوذ من بيانات التطبيق)
const Map<int, _Wk> _wk = {
  4: _Wk('🌰', 'بذرة خشخاش', '0.1 سم', 'أقل من 1 غ', ['بداية تشكل الأنبوب العصبي', 'القلب يبدأ بالتكون', 'تبدأ المشيمة بالتطور']),
  5: _Wk('🫘', 'حبة سمسم', '0.2 سم', 'أقل من 1 غ', ['القلب يبدأ بالنبض', 'تتشكل براعم الأطراف', 'يبدأ الدماغ بالنمو السريع']),
  6: _Wk('🫐', 'حبة عدس', '0.6 سم', 'أقل من 1 غ', ['الأنف والفم يبدآن بالتشكل', 'الأمعاء تتطور', 'بداية تشكل اليدين والقدمين']),
  7: _Wk('🫒', 'حبة توت', '1.3 سم', '1 غ', ['الدماغ ينمو بسرعة', 'تتشكل الأصابع', 'الكبد ينتج خلايا الدم']),
  8: _Wk('🍇', 'حبة فاصوليا', '1.6 سم', '1 غ', ['أصابع اليدين والقدمين تتشكل', 'الأذنان تبدآن بالتكون', 'الجنين يبدأ بالتحرك']),
  9: _Wk('🍒', 'حبة كرز', '2.3 سم', '2 غ', ['العضلات تبدأ بالعمل', 'الأعضاء التناسلية تتشكل', 'الوجه يصبح أكثر وضوحًا']),
  10: _Wk('🍓', 'فراولة', '3.1 سم', '4 غ', ['الأظافر تبدأ بالنمو', 'العظام تبدأ بالتصلب', 'الكلى تنتج البول']),
  11: _Wk('🍋', 'تين', '4.1 سم', '7 غ', ['الرأس يشكل نصف الطول', 'براعم الأسنان تتشكل', 'الحبل السري يعمل بكفاءة']),
  12: _Wk('🍑', 'ليمون', '5.4 سم', '14 غ', ['الأعضاء كلها تشكلت', 'الجنين يتثاءب ويمص إبهامه', 'نهاية المرحلة الحرجة']),
  13: _Wk('🥝', 'كيوي', '7.4 سم', '23 غ', ['بصمات الأصابع تتشكل', 'الحبال الصوتية تتطور', 'المبايض أو الخصيتين تتطور']),
  14: _Wk('🍊', 'برتقالة صغيرة', '8.7 سم', '43 غ', ['الجنين يستطيع العبوس والتحديق', 'الغدة الدرقية تعمل', 'الزغب يظهر']),
  15: _Wk('🍎', 'تفاحة', '10.1 سم', '70 غ', ['الجلد رقيق وشفاف', 'يستطيع تحريك كل المفاصل', 'يتنفس السائل السلوي']),
  16: _Wk('🥑', 'أفوكادو', '11.6 سم', '100 غ', ['العينان حساستان للضوء', 'الجهاز العصبي يتطور', 'العظام أصبحت أقوى']),
  18: _Wk('🫑', 'فلفل حلو', '14.2 سم', '190 غ', ['الأذنان تستطيعان السمع', 'الجنين يتقلب ويتحرك بنشاط', 'المايلين يغلف الأعصاب']),
  20: _Wk('🍌', 'موزة', '16.4 سم', '300 غ', ['منتصف الحمل!', 'الجلد يتغطى بمادة شمعية واقية', 'ينام ويستيقظ بانتظام']),
  22: _Wk('🥕', 'جزرة كبيرة', '27.8 سم', '430 غ', ['حاسة اللمس تتطور', 'الشفاه والحواجب واضحة', 'العينان تكوّنتا']),
  24: _Wk('🌽', 'ذرة', '30 سم', '600 غ', ['الرئتان تنتجان السيرفاكتانت', 'يستجيب للأصوات', 'دورة نوم منتظمة']),
  26: _Wk('🥬', 'خس', '35.6 سم', '760 غ', ['العينان تفتحان لأول مرة', 'الرئتان تتطوران بسرعة', 'الدماغ ينمو بشكل مكثف']),
  28: _Wk('🍆', 'باذنجان', '37.6 سم', '1 كغ', ['يحلم أثناء النوم', 'يميّز بين الأصوات', 'الدهون تتراكم تحت الجلد']),
  30: _Wk('🥥', 'جوز هند', '39.9 سم', '1.3 كغ', ['نخاع العظام ينتج خلايا الدم', 'الشعر الحقيقي ينمو', 'يتنفس السائل للتدريب']),
  32: _Wk('🍊', 'برتقالة كبيرة', '42.4 سم', '1.7 كغ', ['العظام تصلبت عدا الجمجمة', 'أظافر القدم مكتملة', 'الجلد أقل شفافية']),
  34: _Wk('🍈', 'شمام', '45 سم', '2.1 كغ', ['الرئتان شبه مكتملتين', 'الجهاز المناعي يتطور', 'يستدير برأسه للأسفل']),
  36: _Wk('🥬', 'ملفوف', '47.4 سم', '2.6 كغ', ['يكتسب وزنًا سريعًا', 'الكلى والكبد يعملان بكفاءة', 'الزغب يختفي تدريجيًا']),
  38: _Wk('🍉', 'بطيخة صغيرة', '49.8 سم', '3 كغ', ['الأعضاء مكتملة وجاهزة', 'الدماغ والرئتان يكتملان', 'الجنين مكتمل النمو']),
  40: _Wk('🎃', 'يقطينة', '51.2 سم', '3.4 كغ', ['الجنين مكتمل 100%', 'مستعد للقاء العالم', 'الولادة قد تحدث أي لحظة']),
};
