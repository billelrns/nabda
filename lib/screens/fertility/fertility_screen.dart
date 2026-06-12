import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/news_section.dart';
import '../../widgets/conditional_content.dart';

/// رحلة الخصوبة — تصميم فاخر (glassmorphism) للنساء اللواتي يحاولن الحمل.
/// محتوى إرشادي فقط ولا يغني عن استشارة الطبيب.
class FertilityScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const FertilityScreen({Key? key, required this.userData}) : super(key: key);
  @override
  State<FertilityScreen> createState() => _FertilityScreenState();
}

// ===== لوحة الألوان الفاخرة =====
const _bg = Color(0xFFFCF7F7);
const _rose = Color(0xFFF64D8A);
const _blush = Color(0xFFFAD7E5);
const _peach = Color(0xFFF8B8A5);
const _lav = Color(0xFFCBB8FF);
const _green = Color(0xFF8BCF7B);
const _ink = Color(0xFF3A2A2A);
const _muted = Color(0xFF9A8A8A);

class _FertilityScreenState extends State<FertilityScreen> {
  Map<String, dynamic> get d => widget.userData;
  DocumentReference get _userDoc =>
      FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid ?? 'anonymous');

  int get _cycleLen => (d['cycleLength'] as num?)?.toInt() ?? 28;
  int get _luteal => (d['lutealPhase'] as num?)?.toInt() ?? 14;
  bool get _remindersOn => d['fertilityReminders'] != false;

  DateTime? get _lastPeriod {
    final ts = d['lastPeriodStart'];
    return ts is Timestamp ? ts.toDate() : null;
  }

  static const _arMonths = ['', 'جانفي', 'فيفري', 'مارس', 'أفريل', 'ماي', 'جوان', 'جويلية', 'أوت', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
  String _moShort(int m) => _arMonths[m].length > 4 ? _arMonths[m].substring(0, 4) : _arMonths[m];

  DateTime _currentCycleStart(DateTime lp) {
    final now = DateTime.now();
    var s = lp;
    int g = 0;
    while (s.add(Duration(days: _cycleLen)).isBefore(now) && g < 24) { s = s.add(Duration(days: _cycleLen)); g++; }
    return s;
  }

  Future<void> _setLastPeriod() async {
    final date = await showDatePicker(
      context: context, initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 120)), lastDate: DateTime.now(),
      helpText: 'اختاري تاريخ أول يوم لآخر دورة',
      builder: (c, child) => Localizations.override(context: c, locale: const Locale('en'), child: child!),
    );
    if (date != null) {
      await _userDoc.set({'lastPeriodStart': Timestamp.fromDate(date)}, SetOptions(merge: true));
      if (mounted) setState(() => d['lastPeriodStart'] = Timestamp.fromDate(date));
    }
  }

  Future<void> _toggleReminders(bool v) async {
    await _userDoc.set({'fertilityReminders': v}, SetOptions(merge: true));
    if (mounted) setState(() => d['fertilityReminders'] = v);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(v ? 'سيتم تذكيرك بأيام الخصوبة (تُفعّل عند فتح التطبيق التالي) 🌸' : 'أوقفنا تذكير الخصوبة'),
      backgroundColor: _rose));
  }

  Future<void> _exitTrying() async => _userDoc.set({'goal': null}, SetOptions(merge: true));

  Future<void> _confirmPregnancy() async {
    final ok = await showDialog<bool>(context: context, builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('تأكيد الحمل 💗'),
        content: const Text('مبروك! هل أكّد الطبيب أو اختبار الحمل أنكِ حامل؟ سننقلكِ إلى متابعة الحمل (سنعتمد تاريخ آخر دورة كبداية، يمكن تعديله لاحقاً).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ليس بعد')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: _rose, foregroundColor: Colors.white), child: const Text('نعم، أنا حامل')),
        ],
      ),
    ));
    if (ok == true) {
      final lp = _lastPeriod ?? DateTime.now();
      await _userDoc.set({'pregnancyStartDate': Timestamp.fromDate(lp), 'goal': null, 'postTermAck': null}, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lp = _lastPeriod;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        color: _bg,
        child: Column(children: [
          // ── ترويسة فاخرة بتدرّج ناعم ──
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 14, bottom: 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_rose, Color(0xFFF884AE)]),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              boxShadow: [BoxShadow(color: Color(0x33F64D8A), blurRadius: 18, offset: Offset(0, 8))],
            ),
            child: Column(children: const [
              Text('🌱  محاولة الحمل', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
              SizedBox(height: 4),
              Text('متابعة خطواتك نحو حلم الأمومة بكل حب', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
            ]),
          ),
          Expanded(child: lp == null ? _setup() : _dashboard(lp)),
        ]),
      ),
    );
  }

  Widget _setup() {
    return Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle,
        gradient: LinearGradient(colors: [_blush, _peach.withOpacity(0.5)])),
        child: const Icon(Icons.spa, size: 58, color: _rose)),
      const SizedBox(height: 22),
      const Text('لنبدأ رحلتك نحو الحمل', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _ink), textAlign: TextAlign.center),
      const SizedBox(height: 10),
      const Text('أدخلي تاريخ أول يوم لآخر دورة شهرية لنحسب لكِ أيام الخصوبة والإباضة المتوقّعة.',
        style: TextStyle(fontSize: 14, color: _muted, height: 1.7), textAlign: TextAlign.center),
      const SizedBox(height: 26),
      _gradientButton('تحديد تاريخ آخر دورة', Icons.event, _setLastPeriod),
      const SizedBox(height: 10),
      TextButton(onPressed: _exitTrying, child: const Text('الخروج من وضع المحاولة', style: TextStyle(color: _muted))),
    ])));
  }

  Widget _dashboard(DateTime lp) {
    final now = DateTime.now();
    final cs = _currentCycleStart(lp);
    final cycleDay = now.difference(cs).inDays + 1;
    final ovDayNum = _cycleLen - _luteal;
    DateTime ov = cs.add(Duration(days: ovDayNum - 1));
    if (ov.add(const Duration(days: 1)).isBefore(now)) ov = ov.add(Duration(days: _cycleLen));
    final fStart = ov.subtract(const Duration(days: 5));
    final fEnd = ov.add(const Duration(days: 1));
    final today0 = DateTime(now.year, now.month, now.day);
    final inFertile = !today0.isBefore(DateTime(fStart.year, fStart.month, fStart.day)) && !today0.isAfter(DateTime(fEnd.year, fEnd.month, fEnd.day));
    final daysToOv = DateTime(ov.year, ov.month, ov.day).difference(today0).inDays;
    String f(DateTime x) => '${x.day}/${x.month}';

    return ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 28), children: [
      _heroCard(inFertile, cycleDay, fStart, fEnd, ov, daysToOv, f),
      const SizedBox(height: 16),
      _timeline(ov, fStart, fEnd),
      const SizedBox(height: 8),
      _dots(),
      const SizedBox(height: 18),
      // إعلان ضمن الصفحة
      NabdaAd(slot: 0, groupId: 'fertilitypage', place: 'fertility', color: _rose),
      const SizedBox(height: 6),
      _reminderCard(),
      const SizedBox(height: 14),
      _knowledgeCard('🌱', 'تحسين الخصوبة', 'تغذية، حمض الفوليك، الوزن ونمط الحياة', _green, () => _openArticle('تحسين الخصوبة', _improveText)),
      const SizedBox(height: 10),
      _knowledgeCard('🩺', 'متى أراجع أخصائي الخصوبة؟', 'علامات تستدعي زيارة الطبيب والفحوصات', _lav, () => _openArticle('متى تراجعين الأخصائي', _whenSpecialistText)),
      const SizedBox(height: 10),
      _knowledgeCard('📋', 'استبيان الخصوبة', 'أجيبي على أسئلة قصيرة لتوجيه مخصّص', _peach, _openQuestionnaire),
      const SizedBox(height: 22),
      const ConditionalContentSection(),
      const SizedBox(height: 14),
      _sectionTitle('📚 مقالات مفيدة'),
      const SizedBox(height: 10),
      ..._useful.map((a) => _articleCard(a, _blush)),
      const SizedBox(height: 14),
      _sectionTitle('✨ قصص ملهمة'),
      const SizedBox(height: 10),
      ..._stories.map((a) => _articleCard(a, _peach.withOpacity(0.45))),
      const SizedBox(height: 16),
      // إعلان ثانٍ
      NabdaAd(slot: 1, groupId: 'fertilitypage', place: 'fertility', color: _rose),
      const SizedBox(height: 14),
      _ctaPregnant(),
      const SizedBox(height: 12),
      Center(child: TextButton.icon(onPressed: _setLastPeriod, icon: const Icon(Icons.edit_calendar, size: 16, color: _rose), label: const Text('تعديل تاريخ آخر دورة', style: TextStyle(color: _rose)))),
      Center(child: TextButton(onPressed: _exitTrying, child: const Text('الخروج من وضع المحاولة', style: TextStyle(color: _muted)))),
      const SizedBox(height: 8),
      _disclaimer(),
      const SizedBox(height: 20),
    ]);
  }

  // ── بطاقة الهيرو ──
  Widget _heroCard(bool inF, int cd, DateTime fs, DateTime fe, DateTime ov, int dto, String Function(DateTime) f) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft,
          colors: inF ? [_blush, const Color(0xFFFDEEF4)] : [const Color(0xFFF3EEF2), Colors.white]),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: _rose.withOpacity(0.10), blurRadius: 20, offset: const Offset(0, 10))],
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
      ),
      child: Stack(children: [
        Positioned(left: -6, bottom: -6, child: Icon(Icons.pregnant_woman, size: 92, color: _rose.withOpacity(0.10))),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(inF ? Icons.favorite : Icons.favorite_border, color: _rose, size: 24),
            const SizedBox(width: 8),
            Expanded(child: Text(inF ? '🌸 أنتِ ضمن نافذة الخصوبة ❤️' : 'خارج نافذة الخصوبة حالياً',
              style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: _ink))),
          ]),
          const SizedBox(height: 14),
          _kv('يومكِ في الدورة', '$cd', Icons.calendar_today_rounded),
          _kv('نافذة الخصوبة', '${f(fs)} — ${f(fe)}', Icons.adjust_rounded),
          _kv('الإباضة المتوقّعة', '${f(ov)}  ${dto == 0 ? "(اليوم 💗)" : dto > 0 ? "(بعد $dto أيام)" : ""}', Icons.brightness_7_rounded),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(color: _rose.withOpacity(0.10), borderRadius: BorderRadius.circular(14)),
            child: const Text('أفضل أيام المحاولة هي اليومان قبل الإباضة ويومها 💞',
              style: TextStyle(fontSize: 12.5, color: _rose, fontWeight: FontWeight.w700)),
          ),
        ]),
      ]),
    );
  }

  Widget _kv(String k, String v, IconData ic) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
    Icon(ic, size: 16, color: _rose.withOpacity(0.7)),
    const SizedBox(width: 8),
    Text('$k:  ', style: const TextStyle(fontSize: 13, color: _muted)),
    Expanded(child: Text(v, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: _ink))),
  ]));

  // ── الخط الزمني للأيام ──
  Widget _timeline(DateTime ov, DateTime fs, DateTime fe) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final ov0 = DateTime(ov.year, ov.month, ov.day);
    return SizedBox(height: 92, child: ListView.builder(
      scrollDirection: Axis.horizontal, itemCount: 12,
      itemBuilder: (_, i) {
        final day = today.add(Duration(days: i));
        final off = day.difference(ov0).inDays;
        String label; Color bg; Color fg; Gradient? grad; bool glow = false;
        if (off == 0) { label = 'إباضة'; grad = const LinearGradient(colors: [_rose, _peach]); bg = _rose; fg = Colors.white; glow = true; }
        else if (off == -1 || off == 1) { label = 'مرتفع'; bg = _peach.withOpacity(0.30); fg = const Color(0xFFC2533A); }
        else if (off >= -5 && off <= 1) { label = 'خصوبة'; bg = _blush; fg = _rose; }
        else { label = 'منخفض'; bg = Colors.white; fg = _muted; }
        final isToday = i == 0;
        return Container(
          width: 60, margin: const EdgeInsets.only(left: 9),
          decoration: BoxDecoration(
            gradient: grad, color: grad == null ? bg : null,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isToday ? _green : Colors.white.withOpacity(0.7), width: isToday ? 2 : 1),
            boxShadow: glow ? [BoxShadow(color: _rose.withOpacity(0.45), blurRadius: 14, offset: const Offset(0, 5))] : null,
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('${day.day}', style: TextStyle(fontWeight: FontWeight.w900, color: fg, fontSize: 18)),
            Text(_moShort(day.month), style: TextStyle(fontSize: 9, color: fg.withOpacity(0.8))),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 9.5, color: fg, fontWeight: FontWeight.w700)),
          ]),
        );
      },
    ));
  }

  Widget _dots() => Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) => Container(
    width: i == 0 ? 16 : 6, height: 6, margin: const EdgeInsets.symmetric(horizontal: 3),
    decoration: BoxDecoration(color: i == 0 ? _rose : _blush, borderRadius: BorderRadius.circular(3)))));

  Widget _reminderCard() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white), boxShadow: [BoxShadow(color: _rose.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 5))]),
    child: Row(children: [
      Container(width: 42, height: 42, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [_rose, _peach])),
        child: const Icon(Icons.notifications_active, color: Colors.white, size: 22)),
      const SizedBox(width: 12),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('تذكير التوقيت', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: _ink)),
        SizedBox(height: 2),
        Text('إشعارات بأيام الخصوبة العالية ويوم الإباضة', style: TextStyle(fontSize: 11.5, color: _muted)),
      ])),
      Switch(value: _remindersOn, activeColor: _rose, onChanged: _toggleReminders),
    ]),
  );

  Widget _knowledgeCard(String emoji, String title, String sub, Color c, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(children: [
        Container(width: 46, height: 46, decoration: BoxDecoration(shape: BoxShape.circle, color: c.withOpacity(0.18)),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(height: 3),
          Text(sub, style: const TextStyle(fontSize: 12, color: _muted)),
        ])),
        const Icon(Icons.arrow_back_ios, size: 14, color: Color(0xFFC9BCBC)),
      ]),
    ),
  );

  Widget _sectionTitle(String t) => Padding(padding: const EdgeInsets.only(right: 4),
    child: Text(t, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: _ink)));

  Widget _articleCard(Map<String, dynamic> a, Color tint) => GestureDetector(
    onTap: () => _openArticle(a['title'] as String, a['body'] as String),
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(children: [
        Container(width: 54, height: 54, decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(colors: [tint, Colors.white])),
          child: Center(child: Text(a['icon'] as String, style: const TextStyle(fontSize: 26)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(a['title'] as String, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: _ink), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Text(a['sub'] as String, style: const TextStyle(fontSize: 11.5, color: _muted), maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        const Icon(Icons.arrow_back_ios, size: 14, color: Color(0xFFC9BCBC)),
      ]),
    ),
  );

  Widget _gradientButton(String text, IconData ic, VoidCallback onTap) => SizedBox(width: double.infinity, height: 54,
    child: ElevatedButton.icon(onPressed: onTap, icon: Icon(ic),
      label: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(backgroundColor: _rose, foregroundColor: Colors.white, elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)))));

  Widget _ctaPregnant() => GestureDetector(
    onTap: _confirmPregnancy,
    child: Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_rose, _peach]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _rose.withOpacity(0.4), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: const Center(child: Text('🎉  هل حصل الحمل؟ أكّدي حملكِ 💗',
        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900))),
    ),
  );

  Widget _disclaimer() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFFFE082))),
    child: const Row(children: [
      Icon(Icons.info_outline, color: Color(0xFFF57F17), size: 18),
      SizedBox(width: 8),
      Expanded(child: Text('هذه الحسابات والمحتوى إرشادية لمساعدتك على التنظيم، ولا تغني عن استشارة الطبيب أو أخصائي الخصوبة.',
        style: TextStyle(fontSize: 11.5, color: Color(0xFF8D6E00), height: 1.5))),
    ]),
  );

  void _openArticle(String title, String body) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _FertArticlePage(title: title, body: body)));
  }

  void _openQuestionnaire() {
    // قراءة القيم المحفوظة من إعداد الخصوبة (onboarding) إن وُجدت
    final fp = d['fertilityProfile'] as Map?;
    int months = (fp?['tryMonths'] as num?)?.toInt() ?? 6;
    String age = fp?['age'] as String? ?? '25-34';
    String regular = fp?['regular'] as String? ?? 'yes';
    String condition = fp?['condition'] as String? ?? 'none';
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => Directionality(textDirection: TextDirection.rtl,
        child: Padding(padding: EdgeInsets.only(left: 20, right: 20, top: 18, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Center(child: Text('استبيان الخصوبة', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: _ink))),
            const SizedBox(height: 16),
            const Text('منذ متى تحاولين الحمل؟', style: TextStyle(fontWeight: FontWeight.w700)),
            DropdownButton<int>(isExpanded: true, value: months, items: const [
              DropdownMenuItem(value: 3, child: Text('أقل من 6 أشهر')),
              DropdownMenuItem(value: 6, child: Text('6 إلى 12 شهراً')),
              DropdownMenuItem(value: 12, child: Text('أكثر من سنة')),
              DropdownMenuItem(value: 24, child: Text('أكثر من سنتين')),
            ], onChanged: (v) => setS(() => months = v ?? 6)),
            const SizedBox(height: 8),
            const Text('عمرك', style: TextStyle(fontWeight: FontWeight.w700)),
            DropdownButton<String>(isExpanded: true, value: age, items: const [
              DropdownMenuItem(value: '18-24', child: Text('18 - 24')),
              DropdownMenuItem(value: '25-34', child: Text('25 - 34')),
              DropdownMenuItem(value: '35-39', child: Text('35 - 39')),
              DropdownMenuItem(value: '40+', child: Text('40 فأكثر')),
            ], onChanged: (v) => setS(() => age = v ?? '25-34')),
            const SizedBox(height: 8),
            const Text('هل دورتك منتظمة؟', style: TextStyle(fontWeight: FontWeight.w700)),
            DropdownButton<String>(isExpanded: true, value: regular, items: const [
              DropdownMenuItem(value: 'yes', child: Text('نعم، منتظمة')),
              DropdownMenuItem(value: 'no', child: Text('لا، غير منتظمة')),
            ], onChanged: (v) => setS(() => regular = v ?? 'yes')),
            const SizedBox(height: 8),
            const Text('هل لديك حالة معروفة؟', style: TextStyle(fontWeight: FontWeight.w700)),
            DropdownButton<String>(isExpanded: true, value: condition, items: const [
              DropdownMenuItem(value: 'none', child: Text('لا شيء')),
              DropdownMenuItem(value: 'pcos', child: Text('تكيّس المبايض (PCOS)')),
              DropdownMenuItem(value: 'thyroid', child: Text('الغدة الدرقية')),
              DropdownMenuItem(value: 'other', child: Text('أخرى')),
            ], onChanged: (v) => setS(() => condition = v ?? 'none')),
            const SizedBox(height: 18),
            _gradientButton('احصلي على التوجيه', Icons.auto_awesome, () {
              final profile = {'tryMonths': months, 'age': age, 'regular': regular, 'condition': condition};
              _userDoc.set({'fertilityProfile': profile}, SetOptions(merge: true));
              d['fertilityProfile'] = profile;
              Navigator.pop(ctx);
              _openArticle('توجيهك المخصّص', _guidance(months, age, regular, condition));
            }),
            const SizedBox(height: 8),
          ])),
        ),
      )),
    );
  }

  String _guidance(int months, String age, String regular, String condition) {
    final b = StringBuffer();
    final older = age == '35-39' || age == '40+';
    final longTrying = months >= 12 || (older && months >= 6);
    if (longTrying) {
      b.writeln('🔴 يُنصح بزيارة أخصائي/ة الخصوبة قريباً.');
      b.writeln(older ? 'بعد سن 35 يُنصح بالتقييم إذا لم يحدث حمل خلال 6 أشهر من المحاولة المنتظمة.' : 'إذا مرّت سنة كاملة من المحاولة المنتظمة دون حمل، فالتقييم الطبي خطوة مهمة.');
    } else {
      b.writeln('🟢 المدة ما زالت ضمن الطبيعي. معظم الأزواج يحملون خلال السنة الأولى.');
      b.writeln('استمري بالمحاولة في أيام الخصوبة، وراجعي الطبيب إن طالت المدة.');
    }
    b.writeln('');
    if (regular == 'no') b.writeln('• دورتك غير منتظمة: قد يدل على مشكلة في الإباضة، وهي من أكثر أسباب التأخر وأكثرها قابلية للعلاج. يُنصح بفحص الهرمونات.');
    if (condition == 'pcos') b.writeln('• تكيّس المبايض من أشيع أسباب ضعف الإباضة. غالباً يساعد إنقاص الوزن البسيط وأدوية تنشيط الإباضة (بإشراف طبي).');
    else if (condition == 'thyroid') b.writeln('• اختلال الغدة الدرقية يؤثر على الخصوبة والحمل — تأكدي من ضبطها مع طبيبك.');
    b.writeln('');
    b.writeln('خطوات مفيدة الآن:');
    b.writeln('• حمض الفوليك يومياً (400-800 ميكروغرام) قبل الحمل.');
    b.writeln('• المحاولة كل يومين خلال نافذة الخصوبة.');
    b.writeln('• نمط حياة صحي: وزن متوازن، نوم كافٍ، تقليل التوتر، الإقلاع عن التدخين.');
    b.writeln('• تحضير الزوج مهم: قد يُطلب تحليل السائل المنوي ضمن التقييم.');
    return b.toString().trim();
  }

  // ===== المحتوى =====
  static const List<Map<String, dynamic>> _useful = [
    {'icon': '🥗', 'title': 'أطعمة تعزّز الخصوبة', 'sub': 'تغذية ذكية ترفع فرص الحمل', 'body': 'تلعب التغذية دوراً مهماً في تحسين الخصوبة لدى الزوجين. أكثري من الخضار الورقية والفواكه الملوّنة والحبوب الكاملة والبقوليات، فهي غنية بمضادات الأكسدة وحمض الفوليك.\n\nأضيفي مصادر الأوميغا 3 مثل السلمون والسردين وبذور الكتان والجوز، والبروتين الصحي والبيض ومنتجات الألبان كاملة الدسم باعتدال.\n\nقلّلي السكريات والأطعمة المصنّعة والدهون المتحولة، وحافظي على ترطيب جيد. التوازن لا الحرمان هو المفتاح.'},
    {'icon': '💊', 'title': 'حمض الفوليك قبل الحمل', 'sub': 'لماذا يبدأ قبل الحمل بشهر', 'body': 'يُنصح كل امرأة تخطّط للحمل بتناول 400 إلى 800 ميكروغرام من حمض الفوليك يومياً، بدءاً من شهر على الأقل قبل الحمل.\n\nيقي حمض الفوليك من تشوّهات الأنبوب العصبي لدى الجنين التي تتكوّن في الأسابيع الأولى جداً — غالباً قبل أن تعرف المرأة أنها حامل.\n\nيمكن الحصول عليه من المكمّلات ومن الأطعمة كالخضار الورقية والبقوليات والحمضيات. استشيري طبيبك للجرعة المناسبة لك.'},
    {'icon': '📅', 'title': 'كيف تحسبين أيام التبويض؟', 'sub': 'نافذة الخصوبة بالتفصيل', 'body': 'الإباضة تحدث عادةً قبل الدورة التالية بحوالي 14 يوماً. نافذة الخصوبة هي الأيام الخمسة السابقة للإباضة ويوم الإباضة نفسه، لأن الحيوانات المنوية قد تعيش حتى 5 أيام.\n\nعلامات اقتراب الإباضة: زيادة المخاط الشفاف المطّاطي (يشبه بياض البيض)، ارتفاع طفيف في حرارة الجسم بعد الإباضة، وأحياناً ألم خفيف في أحد الجانبين.\n\nالتطبيق يحسب لكِ هذه النافذة تلقائياً من بيانات دورتك، ويمكن دعمها باختبارات الإباضة المنزلية.'},
    {'icon': '🧘', 'title': 'التوتر والخصوبة', 'sub': 'الراحة النفسية جزء من الرحلة', 'body': 'التوتر المزمن قد يؤثر على انتظام الإباضة والهرمونات. الرحلة نحو الحمل قد تكون مرهقة عاطفياً، وهذا طبيعي تماماً.\n\nجرّبي تقنيات الاسترخاء: التنفّس العميق، المشي، الصلاة والذكر، النوم الكافي، والحديث مع شريكك أو مع نساء يمررن بالتجربة نفسها.\n\nلا تجعلي المحاولة مصدر ضغط يومي؛ الاستمتاع بالعلاقة وتخفيف القلق يساعدان جسمك وعقلك معاً.'},
    {'icon': '⚖️', 'title': 'الوزن الصحي وخصوبتك', 'sub': 'توازن بسيط بفرق كبير', 'body': 'الوزن الزائد أو النقص الشديد يؤثران على الإباضة وانتظام الدورة. الدهون الزائدة قد ترفع هرمونات تعيق الإباضة، والنحافة الشديدة قد توقفها.\n\nالخبر الجيد: حتى إنقاص 5 إلى 10% من الوزن الزائد قد يعيد انتظام الإباضة ويرفع فرص الحمل بشكل ملحوظ.\n\nاستهدفي تغييرات تدريجية ومستدامة عبر التغذية المتوازنة والنشاط المعتدل، لا الحميات القاسية.'},
  ];

  static const List<Map<String, dynamic>> _stories = [
    {'icon': '🌟', 'title': 'حملت بعد 6 سنوات من المحاولة', 'sub': 'لا تفقدي الأمل', 'body': 'بعد ست سنوات من المحاولة وعدّة محاولات علاجية، رُزقت سارة بطفلها الأول. تقول إن أصعب ما واجهته كان الضغط النفسي ونظرات المحيطين.\n\nالتزمت بمتابعة منتظمة مع أخصائية خصوبة، وضبطت نمط حياتها وغذاءها، وتعلّمت أن تحسب أيام خصوبتها بدقّة.\n\nرسالتها: «كل رحلة مختلفة، ولا يعني تأخّر الحمل أنه لن يحدث. ثقي بجسدك، واطلبي المساعدة الطبية مبكراً، ولا تيأسي.» (كل حالة تختلف، واستشيري طبيبك دائماً.)'},
    {'icon': '💪', 'title': 'تغلّبت على تكيّس المبايض', 'sub': 'قصة أمل حقيقية', 'body': 'شُخّصت ليلى بتكيّس المبايض وعانت من دورات غير منتظمة سنوات. شعرت أن الحمل حلم بعيد.\n\nبمساعدة طبيبها، بدأت برنامجاً لإنقاص الوزن بشكل بسيط، مع أدوية لتنظيم الإباضة ومتابعة دقيقة لأيام الخصوبة.\n\nخلال أقل من سنة، تحقق الحلم. تكيّس المبايض من أكثر أسباب تأخر الحمل شيوعاً، وهو من أكثرها استجابةً للعلاج. الخطوة الأهم: لا تتأخري في استشارة المختص.'},
    {'icon': '👶', 'title': 'أمومة بعد رحلة علاج طويلة', 'sub': 'الصبر يثمر', 'body': 'بعد محاولات وعلاجات متعددة، استقبلت نور طفلتها. تقول إن الدعم من زوجها وعائلتها كان سندها الأكبر.\n\nتعلّمت أن تعتني بصحتها النفسية بقدر اهتمامها بالجانب الطبي، وأن تحتفل بكل خطوة صغيرة في الطريق.\n\nنصيحتها للأخريات: «اطلبي الدعم، ثقّفي نفسك، وكوني لطيفة مع نفسك. رحلتك لا تقاس برحلة غيرك.» (المعلومات للتشجيع فقط ولا تغني عن الطبيب.)'},
  ];

  static const String _improveText =
      'تحسين فرص الحمل يبدأ بخطوات بسيطة ومثبتة:\n\n'
      '• حمض الفوليك: ابدئي بـ 400-800 ميكروغرام يومياً قبل الحمل بشهر على الأقل، فهو يقي من تشوهات الأنبوب العصبي.\n\n'
      '• الوزن المتوازن: حتى إنقاص 5-10% من الوزن الزائد قد يعيد انتظام الإباضة.\n\n'
      '• التغذية: أكثري من الخضار والفواكه والحبوب الكاملة والبروتين الصحي والأوميغا 3، وقلّلي السكريات والأطعمة المصنّعة.\n\n'
      '• نمط الحياة: نوم كافٍ، نشاط معتدل، تقليل الكافيين، والإقلاع التام عن التدخين والكحول.\n\n'
      '• التوقيت: المحاولة كل يوم أو يومين خلال نافذة الخصوبة ترفع الفرص.\n\n'
      '• صحة الزوج: التغذية الجيدة وتجنّب الحرارة والتدخين تحسّن جودة الحيوانات المنوية.';

  static const String _whenSpecialistText =
      'متى يُنصح بزيارة أخصائي/ة الخصوبة؟\n\n'
      '• إذا مرّت سنة من المحاولة المنتظمة دون حمل (وأنتِ أقل من 35 عاماً).\n'
      '• إذا مرّت 6 أشهر وأنتِ 35 عاماً فأكثر.\n'
      '• إذا كانت دورتك غير منتظمة أو غائبة أو مؤلمة جداً.\n'
      '• إذا كان لديك تكيّس مبايض، بطانة مهاجرة، التهابات حوض، أو جراحات سابقة.\n'
      '• إذا سبق لكِ إجهاضان أو أكثر.\n\n'
      'ما قد يطلبه الطبيب:\n'
      '• فحوصات هرمونية (تقييم الإباضة ومخزون المبيض AMH).\n'
      '• تصوير للرحم والأنابيب وأحياناً سونار.\n'
      '• تحليل السائل المنوي للزوج (عامل مهم في نحو نصف الحالات).\n\n'
      'الخيارات العلاجية متعددة (تنشيط الإباضة، التلقيح، الحقن المجهري)، وكثير من الحالات قابلة للعلاج. لا تتأخري في طلب التقييم — الوقت عامل مؤثر خاصة بعد 35.';
}

// ===== صفحة قراءة المقال (مع إعلانات داخلها) =====
class _FertArticlePage extends StatelessWidget {
  final String title, body;
  const _FertArticlePage({required this.title, required this.body});
  @override
  Widget build(BuildContext context) {
    final paras = body.split('\n\n').where((p) => p.trim().isNotEmpty).toList();
    final widgets = <Widget>[];
    for (int i = 0; i < paras.length; i++) {
      widgets.add(Padding(padding: const EdgeInsets.only(bottom: 16),
        child: Text(paras[i].trim(), style: const TextStyle(fontSize: 16, height: 1.9, color: Color(0xFF3A343B)))));
      if (i == 0) widgets.add(const Padding(padding: EdgeInsets.only(bottom: 12),
        child: NabdaAd(slot: 0, groupId: 'fertarticle', place: 'fertility', color: _rose)));
      if (i == (paras.length ~/ 2) && paras.length > 2) widgets.add(const Padding(padding: EdgeInsets.only(bottom: 12),
        child: NabdaAd(slot: 1, groupId: 'fertarticle', place: 'fertility', color: _rose)));
    }
    widgets.add(const Padding(padding: EdgeInsets.only(top: 4),
      child: NabdaAd(slot: 2, groupId: 'fertarticle', place: 'fertility', color: _rose)));
    widgets.add(const SizedBox(height: 16));
    widgets.add(Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFFFE082))),
      child: const Row(children: [
        Icon(Icons.info_outline, color: Color(0xFFF57F17), size: 18), SizedBox(width: 8),
        Expanded(child: Text('محتوى إرشادي لا يغني عن استشارة الطبيب أو أخصائي الخصوبة.',
          style: TextStyle(fontSize: 11.5, color: Color(0xFF8D6E00), height: 1.5))),
      ]),
    ));
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(backgroundColor: _rose, foregroundColor: Colors.white, title: const Text('رحلة الخصوبة', style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _ink, height: 1.5)),
        const SizedBox(height: 16),
        ...widgets,
        const SizedBox(height: 24),
      ]),
    ));
  }
}
