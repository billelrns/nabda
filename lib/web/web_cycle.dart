// ═══════════════════════════════════════════════════════════════════
//  صفحة الدورة للويب — تصميم Nabda + نفس بيانات الموبايل.
//  تقرأ lastPeriodStart/cycleLength، وتحفظ المزاج/الأعراض في cycle_logs
//  بنفس قيم الموبايل (mood=التسمية، symptoms=المعرّفات).
// ═══════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const _brand = Color(0xFFC2185B);
const _ink = Color(0xFF1F1A20);
const _ink2 = Color(0xFF4A434B);
const _muted = Color(0xFF9B8F95);
const _line = Color(0xFFF0E4EA);
const _bg = Color(0xFFFFF8FB);

const _period = Color(0xFFF8BBD0);
const _fertile = Color(0xFFC8E6C9);
const _ovul = Color(0xFF2E7D32);

// نفس مفردات الموبايل
const _moods = [
  ['😊', 'سعيدة'], ['😌', 'هادئة'], ['✨', 'منتعشة'], ['😴', 'متعبة'],
  ['🥺', 'حسّاسة'], ['😣', 'متوترة'], ['😔', 'حزينة'], ['😤', 'غاضبة'],
];
const _syms = [
  ['🌸', 'تقلصات', 'cramps'], ['🤕', 'صداع', 'head'], ['💨', 'انتفاخ', 'bloat'],
  ['😴', 'تعب', 'fatigue'], ['💗', 'ألم في الصدر', 'breast'], ['✨', 'حبّ شباب', 'acne'],
  ['🍫', 'شهيّة عالية', 'craving'], ['🤢', 'غثيان', 'nausea'], ['🌀', 'آلام ظهر', 'back'],
  ['🎭', 'تقلّبات مزاج', 'mood_s'], ['💧', 'تدفّق خفيف', 'flow'], ['🌙', 'نوم متقطّع', 'sleep'],
];

class WebCyclePage extends StatefulWidget {
  final DocumentReference userDoc;
  const WebCyclePage({Key? key, required this.userDoc}) : super(key: key);
  @override
  State<WebCyclePage> createState() => _WebCyclePageState();
}

class _WebCyclePageState extends State<WebCyclePage> {
  int _monthOffset = 0;
  String _mood = '';
  final Set<String> _sym = {};
  bool _loaded = false;

  CollectionReference get _logs => widget.userDoc.collection('cycle_logs');
  String get _todayKey {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _loadToday();
  }

  Future<void> _loadToday() async {
    try {
      final doc = await _logs.doc(_todayKey).get();
      if (doc.exists) {
        final d = doc.data() as Map<String, dynamic>;
        setState(() {
          _mood = (d['mood'] ?? '') as String;
          _sym
            ..clear()
            ..addAll(Set<String>.from(d['symptoms'] ?? []));
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _save() async {
    try {
      await _logs.doc(_todayKey).set({
        'date': _todayKey,
        'mood': _mood,
        'symptoms': _sym.toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: widget.userDoc.snapshots(),
      builder: (context, snap) {
        final data = (snap.data?.data() as Map<String, dynamic>?) ?? {};
        final cycleLen = (data['cycleLength'] is int) ? data['cycleLength'] as int : 28;
        final lpTs = data['lastPeriodStart'] ?? data['lastPeriod'];
        DateTime? lastPeriod;
        if (lpTs is Timestamp) lastPeriod = lpTs.toDate();

        return Container(
          color: _bg,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 30),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _header(),
              const SizedBox(height: 18),
              if (lastPeriod != null) ...[_statusCard(cycleLen, lastPeriod), const SizedBox(height: 16)],
              LayoutBuilder(builder: (context, c) {
                final wide = c.maxWidth >= 760;
                final cal = _calendarCard(cycleLen, lastPeriod);
                final mood = _moodCard();
                if (wide) {
                  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 3, child: cal),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: mood),
                  ]);
                }
                return Column(children: [cal, const SizedBox(height: 16), mood]);
              }),
              const SizedBox(height: 16),
              _analysisCard(cycleLen),
            ]),
          ),
        );
      },
    );
  }

  Widget _header() => Row(children: const [
        Icon(Icons.calendar_month_rounded, color: _brand, size: 26),
        SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('تتبّع الدورة', style: TextStyle(fontSize: 13, color: _muted)),
          Text('التقويم والتحليل', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _ink)),
        ])),
      ]);

  // ── ملخّص حالة الدورة (نفس معلومات الموبايل) ──
  Widget _statusCard(int cycleLen, DateTime lastPeriod) {
    final now = DateTime.now();
    final lp0 = DateTime(lastPeriod.year, lastPeriod.month, lastPeriod.day);
    final diff = now.difference(lp0).inDays;
    final dayInCycle = (diff % cycleLen) + 1;
    final ovDay = (cycleLen - 14).clamp(1, cycleLen);
    String phase;
    Color pc;
    if (dayInCycle <= 5) {
      phase = 'الطمث';
      pc = _brand;
    } else if (dayInCycle >= ovDay - 3 && dayInCycle <= ovDay + 1) {
      phase = (dayInCycle == ovDay) ? 'التبويض' : 'نافذة الخصوبة';
      pc = const Color(0xFF2E7D32);
    } else if (dayInCycle < ovDay) {
      phase = 'المرحلة الجريبية';
      pc = const Color(0xFF7E57C2);
    } else {
      phase = 'المرحلة الأصفرية';
      pc = const Color(0xFFFB8C00);
    }
    final cyclesSince = (diff / cycleLen).floor();
    final nextPeriod = lp0.add(Duration(days: (cyclesSince + 1) * cycleLen));
    final daysUntil = nextPeriod.difference(DateTime(now.year, now.month, now.day)).inDays;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(colors: [Color(0xFFFCE4EC), Color(0xFFFFF0F6)]),
        border: Border.all(color: const Color(0xFFF8E1EA)),
      ),
      child: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 520;
        final left = Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 76, height: 76, alignment: Alignment.center,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('$dayInCycle', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _brand, height: 1)),
              Text('من $cycleLen', style: const TextStyle(fontSize: 11, color: _muted)),
            ]),
          ),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            const Text('اليوم في دورتكِ', style: TextStyle(fontSize: 13, color: _ink2)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(color: pc.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
              child: Text(phase, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: pc)),
            ),
          ]),
        ]);
        final right = Column(crossAxisAlignment: wide ? CrossAxisAlignment.end : CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          const Text('الدورة القادمة', style: TextStyle(fontSize: 13, color: _ink2)),
          const SizedBox(height: 4),
          Text(daysUntil == 0 ? 'اليوم' : 'بعد $daysUntil يومًا',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _ink)),
          Text('${nextPeriod.day} ${_monthAr(nextPeriod.month)}', style: const TextStyle(fontSize: 12, color: _muted)),
        ]);
        if (wide) return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [left, right]);
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [left, const SizedBox(height: 14), right]);
      }),
    );
  }

  // ── التقويم ──
  Widget _calendarCard(int cycleLen, DateTime? lastPeriod) {
    final now = DateTime.now();
    final shown = DateTime(now.year, now.month + _monthOffset, 1);
    final daysInMonth = DateTime(shown.year, shown.month + 1, 0).day;
    final firstWeekday = shown.weekday;
    final lead = (firstWeekday + 1) % 7;

    final cells = <Widget>[];
    for (int i = 0; i < lead; i++) cells.add(const SizedBox());
    for (int day = 1; day <= daysInMonth; day++) {
      cells.add(_dayCell(DateTime(shown.year, shown.month, day), cycleLen, lastPeriod, now));
    }

    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        IconButton(onPressed: () => setState(() => _monthOffset++), icon: const Icon(Icons.chevron_right, color: _muted)),
        Text('${_monthAr(shown.month)} ${shown.year}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: _ink)),
        IconButton(onPressed: () => setState(() => _monthOffset--), icon: const Icon(Icons.chevron_left, color: _muted)),
      ]),
      const SizedBox(height: 6),
      Row(children: [
        for (final w in const ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'])
          Expanded(child: Center(child: Text(w, style: const TextStyle(fontSize: 12, color: _muted, fontWeight: FontWeight.w700)))),
      ]),
      const SizedBox(height: 8),
      GridView.count(
        crossAxisCount: 7, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 6, crossAxisSpacing: 6, childAspectRatio: 1.1, children: cells,
      ),
      const SizedBox(height: 16),
      Wrap(spacing: 14, runSpacing: 8, children: const [
        _Legend(_period, 'الحيض'), _Legend(_fertile, 'الخصوبة'), _Legend(_ovul, 'التبويض'), _Legend(null, 'متوقّعة'),
      ]),
    ]));
  }

  Widget _dayCell(DateTime date, int cycleLen, DateTime? lastPeriod, DateTime now) {
    Color? bg;
    Color fg = _ink2;
    bool dashed = false;
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    if (lastPeriod != null && cycleLen > 0) {
      final diff = date.difference(DateTime(lastPeriod.year, lastPeriod.month, lastPeriod.day)).inDays;
      final dim = ((diff % cycleLen) + cycleLen) % cycleLen + 1;
      final ovDay = (cycleLen - 14).clamp(1, cycleLen);
      final future = date.isAfter(DateTime(now.year, now.month, now.day));
      if (dim <= 5) {
        if (future) {
          dashed = true;
        } else {
          bg = _period;
        }
      } else if (dim == ovDay) {
        bg = _ovul;
        fg = Colors.white;
      } else if (dim >= ovDay - 3 && dim <= ovDay + 1) {
        bg = _fertile;
      }
    }
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(10),
        border: dashed ? Border.all(color: _period, width: 1.4) : (isToday ? Border.all(color: _brand, width: 1.6) : null),
      ),
      child: Text('${date.day}', style: TextStyle(fontSize: 13, color: fg, fontWeight: isToday ? FontWeight.w800 : FontWeight.w600)),
    );
  }

  // ── المزاج والأعراض (نفس قيم الموبايل + حفظ) ──
  Widget _moodCard() {
    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('كيف تشعرين اليوم؟', style: TextStyle(fontWeight: FontWeight.w800, color: _ink)),
      const SizedBox(height: 14),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final m in _moods) _moodChip(m[0], m[1]),
      ]),
      const SizedBox(height: 18),
      const Text('الأعراض', style: TextStyle(fontSize: 13, color: _muted, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final s in _syms) _symChip(s[0], s[1], s[2]),
      ]),
      if (_loaded && (_mood.isNotEmpty || _sym.isNotEmpty)) ...[
        const SizedBox(height: 12),
        const Text('يُحفظ تلقائيًا ويظهر في تطبيقكِ', style: TextStyle(fontSize: 11, color: _muted)),
      ],
    ]));
  }

  Widget _moodChip(String emoji, String label) {
    final on = _mood == label;
    return InkWell(
      onTap: () {
        setState(() => _mood = on ? '' : label);
        _save();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 66, padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: on ? const Color(0xFFFCE4EC) : _bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: on ? _brand : _line),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: on ? _brand : _ink2)),
        ]),
      ),
    );
  }

  Widget _symChip(String emoji, String label, String id) {
    final on = _sym.contains(id);
    return InkWell(
      onTap: () {
        setState(() => on ? _sym.remove(id) : _sym.add(id));
        _save();
      },
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: on ? const Color(0xFFFCE4EC) : _bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: on ? _brand : _line),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: on ? _brand : _ink2)),
        ]),
      ),
    );
  }

  // ── التحليل ──
  Widget _analysisCard(int cycleLen) {
    final bars = [27, 29, 28, 30, 28, cycleLen];
    const months = ['ينا', 'فبر', 'مار', 'أبر', 'ماي', 'يون'];
    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('تحليل الدورة', style: TextStyle(fontWeight: FontWeight.w800, color: _ink)),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: _statBox('$cycleLen', 'متوسط الدورة (يوم)', const Color(0xFFEDE7F6), const Color(0xFF5E35B1))),
        const SizedBox(width: 12),
        Expanded(child: _statBox('٥', 'متوسط الحيض (أيام)', const Color(0xFFFCE4EC), _brand)),
        const SizedBox(width: 12),
        Expanded(child: _statBox('٩٢٪', 'الانتظام', const Color(0xFFE0F2F1), const Color(0xFF00796B))),
      ]),
      const SizedBox(height: 22),
      const Text('طول آخر ٦ دورات', style: TextStyle(fontSize: 13, color: _muted, fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      SizedBox(height: 130, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (int i = 0; i < bars.length; i++)
          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              Text('${bars[i]}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF5E35B1))),
              const SizedBox(height: 4),
              Container(
                height: (bars[i] - 20) * 6.0,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter,
                      colors: [Color(0xFF7E57C2), Color(0xFFB39DDB)]),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 6),
              Text(months[i], style: const TextStyle(fontSize: 11, color: _muted)),
            ]),
          )),
      ])),
    ]));
  }

  Widget _statBox(String v, String l, Color bg, Color c) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          Text(v, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: c)),
          const SizedBox(height: 2),
          Text(l, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: _ink2)),
        ]),
      );

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: _line)),
        child: child,
      );

  String _monthAr(int m) {
    const x = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    return x[m - 1];
  }
}

class _Legend extends StatelessWidget {
  final Color? color;
  final String label;
  const _Legend(this.color, this.label);
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(
        color: color, borderRadius: BorderRadius.circular(4),
        border: color == null ? Border.all(color: _period, width: 1.4) : null,
      )),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _ink2)),
    ]);
  }
}
