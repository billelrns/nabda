// ═══════════════════════════════════════════════════════════════════
//  صفحة رعاية الطفل للويب — تصميم Nabda + نفس بيانات الموبايل.
//  تقرأ من مجموعة `babies` الفرعية (name, birthDate, weight, height).
// ═══════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const _brand = Color(0xFFC2185B);
const _teal = Color(0xFF00897B);
const _teal2 = Color(0xFF26A69A);
const _ink = Color(0xFF1F1A20);
const _ink2 = Color(0xFF4A434B);
const _muted = Color(0xFF9B8F95);
const _line = Color(0xFFF0E4EA);
const _bg = Color(0xFFFFF8FB);

class _Vax {
  final String age, vaccine;
  const _Vax(this.age, this.vaccine);
}

const _schedule = <_Vax>[
  _Vax('عند الولادة', 'BCG (السل) + التهاب الكبد B'),
  _Vax('شهر', 'التهاب الكبد B (الجرعة 2)'),
  _Vax('شهران', 'الخماسي + شلل الأطفال + الرئوي (الجرعة 1)'),
  _Vax('4 أشهر', 'الخماسي + شلل الأطفال + الرئوي (الجرعة 2)'),
  _Vax('6 أشهر', 'الخماسي + شلل الأطفال + الرئوي (الجرعة 3)'),
  _Vax('9 أشهر', 'الحصبة + الحمى الصفراء'),
  _Vax('12 شهرًا', 'الحصبة والنكاف والحصبة الألمانية (MMR)'),
  _Vax('18 شهرًا', 'الجرعات المنشّطة (Booster)'),
];

class WebBabyPage extends StatefulWidget {
  final DocumentReference userDoc;
  const WebBabyPage({Key? key, required this.userDoc}) : super(key: key);
  @override
  State<WebBabyPage> createState() => _WebBabyPageState();
}

class _WebBabyPageState extends State<WebBabyPage> {
  final Set<int> _done = {};
  String? _selectedId;

  CollectionReference get _babies => widget.userDoc.collection('babies');

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _babies.snapshots(),
      builder: (context, babiesSnap) {
        final docs = babiesSnap.hasData
            ? (List<QueryDocumentSnapshot>.from(babiesSnap.data!.docs)
              ..sort((a, b) {
                final ad = (a.data() as Map)['createdAt'];
                final bd = (b.data() as Map)['createdAt'];
                if (ad == null) return 1;
                if (bd == null) return -1;
                return (ad as Timestamp).compareTo(bd as Timestamp);
              }))
            : <QueryDocumentSnapshot>[];

        return StreamBuilder<DocumentSnapshot>(
          stream: widget.userDoc.snapshots(),
          builder: (context, userSnap) {
            final ud = (userSnap.data?.data() as Map<String, dynamic>?) ?? {};
            _selectedId ??= ud['selectedBabyId'] as String?;

            if (docs.isEmpty) return _scroll([_header(), const SizedBox(height: 18), _noBaby()]);

            final baby = docs.firstWhere((d) => d.id == _selectedId, orElse: () => docs.first);
            final b = baby.data() as Map<String, dynamic>;
            final name = (b['name'] ?? '') as String;
            final birth = (b['birthDate'] is Timestamp) ? (b['birthDate'] as Timestamp).toDate() : null;
            final weight = (b['weight'] is num) ? (b['weight'] as num).toDouble() : 0.0;
            final height = (b['height'] is num) ? (b['height'] as num).toDouble() : 0.0;

            return _scroll([
              _header(),
              if (docs.length > 1) ...[const SizedBox(height: 14), _babySelector(docs)],
              const SizedBox(height: 18),
              LayoutBuilder(builder: (context, c) {
                final wide = c.maxWidth >= 700;
                final hero = _babyCard(name, birth, weight, height);
                final vax = _nextVaxCard(birth);
                if (wide) {
                  return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Expanded(child: hero),
                    const SizedBox(width: 16),
                    Expanded(child: vax),
                  ]);
                }
                return Column(children: [hero, const SizedBox(height: 16), vax]);
              }),
              const SizedBox(height: 18),
              _milestones(birth),
              const SizedBox(height: 18),
              _scheduleCard(birth),
            ]);
          },
        );
      },
    );
  }

  Widget _scroll(List<Widget> children) => Container(
        color: _bg,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 30),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        ),
      );

  Widget _header() => Row(children: const [
        Icon(Icons.child_care_rounded, color: _teal, size: 26),
        SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('رعاية الطفل', style: TextStyle(fontSize: 13, color: _muted)),
          Text('نموّ طفلكِ وصحّته', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _ink)),
        ])),
      ]);

  Widget _babySelector(List<QueryDocumentSnapshot> docs) {
    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (final d in docs)
        InkWell(
          onTap: () => setState(() => _selectedId = d.id),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _selectedId == d.id || (_selectedId == null && d == docs.first) ? const Color(0xFFE0F2F1) : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _selectedId == d.id ? _teal : _line),
            ),
            child: Text('👶 ${((d.data() as Map)['name'] ?? 'طفل')}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _ink)),
          ),
        ),
    ]);
  }

  Widget _babyCard(String name, DateTime? birth, double weight, double height) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(colors: [_teal, _teal2]),
        boxShadow: [BoxShadow(color: _teal.withOpacity(0.22), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Container(width: 64, height: 64, alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: const Text('👶', style: TextStyle(fontSize: 34))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(name.isEmpty ? 'طفلكِ' : name, style: const TextStyle(fontSize: 14, color: Colors.white)),
            const SizedBox(height: 2),
            Text(_ageText(birth), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
          ])),
        ]),
        const SizedBox(height: 18),
        Row(children: [
          _BabyStat('الوزن', weight > 0 ? '${_fmt(weight)} كغ' : '— كغ'),
          const SizedBox(width: 28),
          _BabyStat('الطول', height > 0 ? '${_fmt(height)} سم' : '— سم'),
        ]),
        if (weight == 0 && height == 0) ...[
          const SizedBox(height: 6),
          const Text('سجّلي قياسات طفلكِ من التطبيق لمتابعتها هنا', style: TextStyle(fontSize: 11, color: Colors.white70)),
        ],
      ]),
    );
  }

  Widget _nextVaxCard(DateTime? birth) {
    final next = _nextVax();
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: _line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        const Text('التطعيم القادم', style: TextStyle(fontSize: 13, color: _muted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(next?.age ?? 'مكتملة 🎉', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _teal)),
        const SizedBox(height: 6),
        Text(next?.vaccine ?? 'كل التطعيمات في جدولكِ مكتملة', style: const TextStyle(fontSize: 13, color: _ink2, height: 1.5)),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(12)),
          child: Text('💉 ${_done.length} من ${_schedule.length} مراحل مكتملة',
              style: const TextStyle(fontSize: 14, color: _teal, fontWeight: FontWeight.w800)),
        ),
      ]),
    );
  }

  Widget _milestones(DateTime? birth) {
    final days = birth == null ? 0 : DateTime.now().difference(birth).inDays;
    final items = _milestonesFor(days);
    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('مراحل النمو هذا الشهر', style: TextStyle(fontWeight: FontWeight.w800, color: _ink)),
      const SizedBox(height: 14),
      for (final m in items) Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
        Container(width: 32, height: 32, alignment: Alignment.center,
          decoration: BoxDecoration(color: (m.$1) ? const Color(0xFF43A047) : _line, shape: BoxShape.circle),
          child: Icon((m.$1) ? Icons.check : Icons.circle_outlined, size: 16, color: (m.$1) ? Colors.white : _muted)),
        const SizedBox(width: 12),
        Expanded(child: Text(m.$2, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: (m.$1) ? _ink : _muted))),
      ])),
    ]));
  }

  Widget _scheduleCard(DateTime? birth) {
    final months = _ageMonths(birth);
    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('جدول التطعيمات 💉', style: TextStyle(fontWeight: FontWeight.w800, color: _ink)),
        Text('${_done.length}/${_schedule.length}', style: const TextStyle(fontWeight: FontWeight.w800, color: _teal)),
      ]),
      const SizedBox(height: 12),
      for (int i = 0; i < _schedule.length; i++) _vaxRow(i, months),
      const SizedBox(height: 8),
      const Center(child: Text('اضغطي على أي مرحلة لتسجيلها كمكتملة', style: TextStyle(fontSize: 12, color: _muted))),
    ]));
  }

  Widget _vaxRow(int i, int babyMonths) {
    final v = _schedule[i];
    final done = _done.contains(i);
    final due = babyMonths >= _stageMonth(i);
    final status = done ? 'مكتمل' : (due ? 'مستحق' : 'قادم');
    final statusColor = done ? const Color(0xFF43A047) : (due ? const Color(0xFFFB8C00) : _muted);
    return InkWell(
      onTap: () => setState(() => done ? _done.remove(i) : _done.add(i)),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        child: Row(children: [
          Container(width: 38, height: 38, alignment: Alignment.center,
            decoration: BoxDecoration(color: done ? const Color(0xFF43A047) : const Color(0xFFE0F2F1), shape: BoxShape.circle),
            child: Icon(done ? Icons.check : Icons.vaccines_outlined, size: 18, color: done ? Colors.white : _teal)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(v.age, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _ink)),
            const SizedBox(height: 2),
            Text(v.vaccine, style: const TextStyle(fontSize: 12.5, color: _ink2, height: 1.4)),
          ])),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
            child: Text(status, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: statusColor)),
          ),
        ]),
      ),
    );
  }

  Widget _noBaby() => _card(child: Column(children: const [
        Text('👶', style: TextStyle(fontSize: 44)),
        SizedBox(height: 10),
        Text('لم تُضِفي طفلًا بعد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _ink)),
        SizedBox(height: 6),
        Text('أضيفي طفلكِ من التطبيق لمتابعة نموّه وتطعيماته هنا.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: _ink2)),
      ]));

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: _line)),
        child: child,
      );

  // ── حسابات (نفس منطق الموبايل) ──
  int _ageMonths(DateTime? birth) => birth == null ? 0 : (DateTime.now().difference(birth).inDays / 30.44).floor();
  int _stageMonth(int i) => const [0, 1, 2, 4, 6, 9, 12, 18][i];

  _Vax? _nextVax() {
    for (int i = 0; i < _schedule.length; i++) {
      if (!_done.contains(i)) return _schedule[i];
    }
    return null;
  }

  String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  List<(bool, String)> _milestonesFor(int days) {
    if (days < 30) {
      return [(true, 'يتعرّف على صوت أمه'), (true, 'يحرّك أطرافه'), (false, 'الابتسامة الأولى'), (false, 'يثبّت رأسه قليلًا')];
    }
    if (days < 90) {
      return [(true, 'يبتسم اجتماعيًا'), (true, 'يناغي ويصدر أصواتًا'), (false, 'يتابع الأشياء بعينيه'), (false, 'يثبّت رأسه')];
    }
    if (days < 180) {
      return [(true, 'يتقلّب من بطنه إلى ظهره'), (true, 'يضحك ويصدر أصواتًا'), (false, 'يجلس بمساعدة'), (false, 'يمسك الأشياء')];
    }
    if (days < 270) {
      return [(true, 'يجلس دون مساعدة'), (true, 'يبدأ الطعام الصلب'), (false, 'يزحف'), (false, 'ينطق مقاطع (با، ما)')];
    }
    if (days < 365) {
      return [(true, 'يزحف بثبات'), (true, 'يقف بمساعدة'), (false, 'يمشي ممسكًا بالأثاث'), (false, 'يقول كلمة واضحة')];
    }
    return [(true, 'يمشي بمفرده'), (true, 'يقول عدة كلمات'), (false, 'يصعد الدرج بمساعدة'), (false, 'يستخدم الملعقة')];
  }

  String _ageText(DateTime? birth) {
    if (birth == null) return 'حديث الولادة';
    final days = DateTime.now().difference(birth).inDays;
    if (days < 30) return '$days يومًا';
    final months = (days / 30.44).floor();
    if (months < 24) {
      final remDays = days - (months * 30.44).round();
      return remDays > 0 ? '$months أشهر و $remDays يومًا' : '$months أشهر';
    }
    final years = months ~/ 12;
    final rem = months % 12;
    return rem > 0 ? '$years سنة و $rem أشهر' : '$years سنة';
  }
}

class _BabyStat extends StatelessWidget {
  final String label, value;
  const _BabyStat(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
    ]);
  }
}
