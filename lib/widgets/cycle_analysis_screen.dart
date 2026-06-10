import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const _pink = Color(0xFFE53B7E);
const _pinkSoft = Color(0xFFFFF1F6);
const _ink = Color(0xFF1B1320);
const _ink2 = Color(0xFF4A3F4F);
const _ink3 = Color(0xFF8E8295);
const _teal = Color(0xFF15B8A6);

const _symLabels = {
  'bloating': 'انتفاخ', 'headache': 'صداع', 'breast': 'ألم الثدي', 'back': 'ألم الظهر',
  'fatigue': 'إرهاق', 'insomnia': 'أرق', 'nausea': 'غثيان', 'acne': 'حبّ الشباب',
  'cravings': 'اشتهاء طعام', 'moodswing': 'تقلّب مزاج',
};
const _irrLabels = {
  'late': 'تأخّر', 'early': 'تبكير', 'heavy_bleed': 'نزيف غزير',
  'spotting': 'تنقيط', 'pain': 'ألم شديد', 'missed': 'غياب الدورة',
};
const _pregLabels = {'negative': 'سلبي', 'faint': 'خط باهت', 'positive': 'إيجابي'};

/// بطاقة تفتح شاشة التحليل — تُدرَج بسطر واحد في تبويب الدورة.
class CycleAnalysisButton extends StatelessWidget {
  const CycleAnalysisButton({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CycleAnalysisScreen())),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_pink, Color(0xFFF884AE)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Color(0x33E53B7E), blurRadius: 14, offset: Offset(0, 6))]),
          child: Row(children: const [
            Text('📊', style: TextStyle(fontSize: 26)),
            SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('تحليل دورتك', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
              SizedBox(height: 3),
              Text('رؤى وإحصاءات من سجلّاتك', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ])),
            Icon(Icons.arrow_back_ios, color: Colors.white, size: 16),
          ]),
        ),
      ),
    );
  }
}

class CycleAnalysisScreen extends StatelessWidget {
  const CycleAnalysisScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFCF7F7),
        appBar: AppBar(backgroundColor: _pink, foregroundColor: Colors.white,
          title: const Text('تحليل دورتك', style: TextStyle(fontWeight: FontWeight.bold))),
        body: uid == null
            ? const Center(child: Text('سجّلي الدخول أولاً'))
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(uid)
                    .collection('cycle_logs').orderBy('date').snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: _pink));
                  final logs = snap.data!.docs.map((d) => d.data() as Map<String, dynamic>).toList();
                  final s = _analyze(logs);
                  if (s.totalLogs == 0) return _empty();
                  return ListView(padding: const EdgeInsets.all(16), children: [
                    _summary(s),
                    if (s.cycleLengths.isNotEmpty) ...[const SizedBox(height: 14), _history(s)],
                    if (s.bbt.length >= 2) ...[const SizedBox(height: 14), _bbtCard(s)],
                    if (s.symptomCounts.isNotEmpty) ...[const SizedBox(height: 14), _symptomsCard(s)],
                    if (s.irrCounts.isNotEmpty) ...[const SizedBox(height: 14), _irrCard(s)],
                    if (s.pregTests.isNotEmpty) ...[const SizedBox(height: 14), _pregCard(s)],
                    const SizedBox(height: 14),
                    _guidance(s),
                    const SizedBox(height: 14),
                    _disclaimer(),
                    const SizedBox(height: 20),
                  ]);
                },
              ),
      ),
    );
  }

  Widget _empty() => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(
    mainAxisSize: MainAxisSize.min, children: const [
      Text('📋', style: TextStyle(fontSize: 56)),
      SizedBox(height: 16),
      Text('لا توجد بيانات كافية بعد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _ink)),
      SizedBox(height: 8),
      Text('سجّلي حيضكِ وأعراضكِ يوميًا من التقويم، وستظهر هنا تحليلات مفيدة عن نمط دورتك.',
        textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5, color: _ink3, height: 1.7)),
    ])));

  Widget _card(String title, List<Widget> children) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
      boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _ink)),
      const SizedBox(height: 12), ...children,
    ]),
  );

  Widget _summary(_CycleStats s) {
    Widget tile(String emoji, String val, String label) => Container(
      width: 150,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(color: _pinkSoft, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 6),
        Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _pink)),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, color: _ink2)),
      ]),
    );
    return _card('ملخّص دورتك', [
      Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
        tile('🔄', s.avgCycle != null ? '${s.avgCycle!.round()} يوم' : '—', 'متوسط طول الدورة'),
        tile('🩸', s.avgPeriod != null ? '${s.avgPeriod!.round()} أيام' : '—', 'متوسط مدة الحيض'),
        tile('📈', '${s.cyclesCount}', 'دورات مُسجّلة'),
        tile(s.regular ? '✅' : '⚠️', s.cyclesCount < 2 ? '—' : (s.regular ? 'منتظمة' : 'غير منتظمة'), 'انتظام الدورة'),
      ]),
    ]);
  }

  Widget _history(_CycleStats s) {
    const months = ['', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    final rows = <Widget>[];
    final n = s.cycleLengths.length;
    final from = max(0, n - 6);
    for (int i = from; i < n; i++) {
      final start = s.starts[i];
      final len = s.cycleLengths[i];
      final ok = len >= 21 && len <= 35;
      rows.add(Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [
        Text('${start.day} ${months[start.month]}', style: const TextStyle(fontSize: 13, color: _ink2)),
        const Spacer(),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(color: (ok ? _teal : const Color(0xFFFF9800)).withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12)),
          child: Text('$len يوم', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
            color: ok ? _teal : const Color(0xFFE67E00)))),
      ])));
    }
    return _card('📅 سجلّ الدورات الأخيرة', rows);
  }

  Widget _bbtCard(_CycleStats s) {
    final vals = s.bbt.map((e) => e.value).toList();
    return _card('🌡️ منحنى حرارة الجسم (BBT)', [
      SizedBox(height: 90, width: double.infinity, child: CustomPaint(painter: _BbtPainter(vals))),
      const SizedBox(height: 8),
      const Text('ارتفاع مستمر بنحو 0.3°م بعد التبويض يؤكّد حدوثه. سجّلي القياس صباحًا قبل النهوض.',
        style: TextStyle(fontSize: 12, color: _ink3, height: 1.6)),
    ]);
  }

  Widget _bar(String label, int count, int maxC) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 13, color: _ink2))),
      Expanded(child: LayoutBuilder(builder: (c, cons) => Stack(children: [
        Container(height: 14, decoration: BoxDecoration(color: _pinkSoft, borderRadius: BorderRadius.circular(8))),
        Container(height: 14, width: cons.maxWidth * (maxC == 0 ? 0 : count / maxC),
          decoration: BoxDecoration(color: _pink, borderRadius: BorderRadius.circular(8))),
      ]))),
      const SizedBox(width: 8),
      Text('$count', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: _pink)),
    ]),
  );

  Widget _symptomsCard(_CycleStats s) {
    final entries = s.symptomCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(5).toList();
    final maxC = top.isEmpty ? 0 : top.first.value;
    return _card('🩺 أكثر الأعراض تكرارًا', [
      for (final e in top) _bar(_symLabels[e.key] ?? e.key, e.value, maxC),
    ]);
  }

  Widget _irrCard(_CycleStats s) {
    final entries = s.irrCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return _card('⚠️ الاضطرابات المسجّلة', [
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final e in entries)
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFE0B2))),
            child: Text('${_irrLabels[e.key] ?? e.key}: ${e.value}',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFFE67E00)))),
      ]),
    ]);
  }

  Widget _pregCard(_CycleStats s) {
    const months = ['', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    return _card('🤰 اختبارات الحمل', [
      for (final e in s.pregTests.reversed.take(5))
        Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
          Text('${e.key.day} ${months[e.key.month]}', style: const TextStyle(fontSize: 13, color: _ink2)),
          const Spacer(),
          Text(_pregLabels[e.value] ?? e.value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
            color: e.value == 'positive' ? _teal : (e.value == 'faint' ? const Color(0xFFE67E00) : _ink3))),
        ])),
    ]);
  }

  Widget _guidance(_CycleStats s) {
    final tips = <String>[];
    if (s.cyclesCount < 2) {
      tips.add('سجّلي دورتين متتاليتين على الأقل لنمنحكِ تحليلًا أدقّ لانتظام دورتك.');
    } else {
      if (!s.regular) {
        tips.add('دورتك غير منتظمة (تتراوح بين ${s.cycleLengths.reduce(min)} و${s.cycleLengths.reduce(max)} يومًا). قد يرتبط بالتوتر أو الوزن أو خلل هرموني — راجعي الطبيبة إن استمرّ.');
      } else {
        tips.add('دورتك منتظمة نسبيًا 👏 — استمري في التسجيل للحفاظ على دقّة التوقّعات.');
      }
      if (s.avgCycle != null && (s.avgCycle! < 21 || s.avgCycle! > 35)) {
        tips.add('متوسط طول دورتك خارج المعدّل الطبيعي (21-35 يومًا) — يُستحسن تقييم طبّي.');
      }
      if (s.avgPeriod != null && s.avgPeriod! > 7) {
        tips.add('مدّة الحيض لديك أطول من المعتاد (أكثر من 7 أيام) — راجعي الطبيبة لاستبعاد أسباب كالأورام الليفية.');
      }
    }
    if (s.irrCounts['missed'] != null) tips.add('سجّلتِ غيابًا للدورة — إن لم يكن بسبب حمل أو رضاعة، استشيري الطبيبة.');
    if (s.irrCounts['heavy_bleed'] != null) tips.add('سجّلتِ نزيفًا غزيرًا متكرّرًا — راقبيه وراجعي الطبيبة إن أثّر على نشاطك أو سبّب فقر دم.');
    if (s.pregTests.any((e) => e.value == 'positive')) tips.add('🎉 سجّلتِ اختبار حمل إيجابيًا — بارك الله لكِ! أكّديه مع طبيبتك وابدئي متابعة الحمل.');
    tips.add('حافظي على نوم كافٍ وتغذية متوازنة ونشاط معتدل وتقليل التوتر — كلها تدعم انتظام الدورة.');
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [_pinkSoft, Color(0xFFEAF7F5)]),
        borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('💡 توجيهات لكِ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _ink)),
        const SizedBox(height: 10),
        for (final t in tips) Padding(padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(padding: EdgeInsets.only(top: 6), child: Icon(Icons.circle, size: 6, color: _pink)),
            const SizedBox(width: 8),
            Expanded(child: Text(t, style: const TextStyle(fontSize: 13, height: 1.7, color: _ink2))),
          ])),
      ]),
    );
  }

  Widget _disclaimer() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFFFE082))),
    child: const Row(children: [
      Icon(Icons.info_outline, color: Color(0xFFF57F17), size: 18), SizedBox(width: 8),
      Expanded(child: Text('هذه التحليلات إرشادية تساعدك على فهم جسمك، ولا تغني عن استشارة الطبيبة.',
        style: TextStyle(fontSize: 11.5, color: Color(0xFF8D6E00), height: 1.5))),
    ]),
  );
}

class _CycleStats {
  final int totalLogs, cyclesCount;
  final List<int> cycleLengths, periodLengths;
  final double? avgCycle, avgPeriod;
  final bool regular;
  final Map<String, int> symptomCounts, irrCounts;
  final List<MapEntry<DateTime, double>> bbt;
  final List<MapEntry<DateTime, String>> pregTests;
  final List<DateTime> starts;
  _CycleStats({required this.totalLogs, required this.cyclesCount, required this.cycleLengths,
    required this.periodLengths, required this.avgCycle, required this.avgPeriod, required this.regular,
    required this.symptomCounts, required this.irrCounts, required this.bbt, required this.pregTests, required this.starts});
}

_CycleStats _analyze(List<Map<String, dynamic>> logs) {
  DateTime? parse(String? k) {
    if (k == null) return null;
    final p = k.split('-');
    if (p.length != 3) return null;
    try { return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2])); } catch (_) { return null; }
  }
  final dated = <DateTime, Map<String, dynamic>>{};
  for (final l in logs) {
    final d = parse(l['date'] as String?);
    if (d != null) dated[DateTime(d.year, d.month, d.day)] = l;
  }
  final periodSet = dated.entries.where((e) => e.value['isPeriod'] == true).map((e) => e.key).toSet();
  final periodDays = periodSet.toList()..sort();
  final starts = <DateTime>[];
  final runLens = <int>[];
  for (final day in periodDays) {
    if (!periodSet.contains(day.subtract(const Duration(days: 1)))) starts.add(day);
  }
  starts.sort();
  for (final st in starts) {
    int len = 1; var d = st;
    while (periodSet.contains(d.add(const Duration(days: 1)))) { d = d.add(const Duration(days: 1)); len++; }
    runLens.add(len);
  }
  final cycleLengths = <int>[];
  for (int i = 1; i < starts.length; i++) {
    final diff = starts[i].difference(starts[i - 1]).inDays;
    if (diff > 10 && diff < 90) cycleLengths.add(diff); // تجاهل القيم الشاذة
  }
  double? avg(List<int> x) => x.isEmpty ? null : x.reduce((a, b) => a + b) / x.length;
  final sym = <String, int>{}, irr = <String, int>{};
  final bbt = <MapEntry<DateTime, double>>[];
  final preg = <MapEntry<DateTime, String>>[];
  dated.forEach((d, l) {
    for (final x in (l['symptoms'] as List?) ?? []) { final k = x.toString(); sym[k] = (sym[k] ?? 0) + 1; }
    final ir = l['irregularity'];
    if (ir != null && ir != '' && ir != 'none') irr[ir.toString()] = (irr[ir.toString()] ?? 0) + 1;
    final b = l['bbt'];
    if (b is num) bbt.add(MapEntry(d, b.toDouble()));
    final pt = l['pregnancyTest'];
    if (pt != null && pt != '' && pt != 'none') preg.add(MapEntry(d, pt.toString()));
  });
  bbt.sort((a, b) => a.key.compareTo(b.key));
  preg.sort((a, b) => a.key.compareTo(b.key));
  return _CycleStats(totalLogs: dated.length, cyclesCount: cycleLengths.length, cycleLengths: cycleLengths,
    periodLengths: runLens, avgCycle: avg(cycleLengths), avgPeriod: avg(runLens),
    regular: cycleLengths.length >= 2 ? (cycleLengths.reduce(max) - cycleLengths.reduce(min)) <= 5 : true,
    symptomCounts: sym, irrCounts: irr, bbt: bbt, pregTests: preg, starts: starts);
}

class _BbtPainter extends CustomPainter {
  final List<double> values;
  _BbtPainter(this.values);
  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final lo = values.reduce(min), hi = values.reduce(max);
    final range = (hi - lo).abs() < 0.1 ? 0.5 : (hi - lo);
    final dx = size.width / (values.length - 1);
    final pts = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final y = size.height - ((values[i] - lo) / range) * (size.height - 16) - 8;
      pts.add(Offset(i * dx, y));
    }
    final line = Paint()..color = _pink..strokeWidth = 2.5..style = PaintingStyle.stroke..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) path.lineTo(p.dx, p.dy);
    canvas.drawPath(path, line);
    final dot = Paint()..color = _teal;
    for (final p in pts) canvas.drawCircle(p, 3, dot);
  }
  @override
  bool shouldRepaint(covariant _BbtPainter old) => old.values != values;
}
