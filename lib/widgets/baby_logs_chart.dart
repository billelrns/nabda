import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ═══════════════════════════════════════════════════════════════════
///  مخطّط نشاط الطفل لآخر 7 أيام — رضاعة • نوم • حفاضات
///  يقرأ من users/{uid}/baby_logs/{yyyy-MM-dd}
///  أو users/{uid}/babies/{babyId}/logs/{yyyy-MM-dd} عند تحديد طفل.
/// ═══════════════════════════════════════════════════════════════════
class BabyLogsChart extends StatefulWidget {
  final String? babyId;
  const BabyLogsChart({Key? key, this.babyId}) : super(key: key);

  @override
  State<BabyLogsChart> createState() => _BabyLogsChartState();
}

class _BabyLogsChartState extends State<BabyLogsChart> {
  static const _pink = Color(0xFFE0195B);
  static const _lav = Color(0xFF9B6FE1);
  static const _teal = Color(0xFF00897B);
  static const _ink = Color(0xFF1F1A20);
  static const _ink3 = Color(0xFF9B8F95);

  static const _metrics = [
    ['feeding', 'الرضاعة', '🍼', 'مرة'],
    ['sleep', 'النوم', '😴', 'ساعة'],
    ['diaper', 'الحفاض', '👶', 'تغيير'],
  ];

  int _selected = 0;
  bool _loading = true;
  List<_DayPoint> _days = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant BabyLogsChart old) {
    super.didUpdateWidget(old);
    if (old.babyId != widget.babyId) _load();
  }

  Color get _color => [_pink, _lav, _teal][_selected];
  String get _key => _metrics[_selected][0];
  String get _unit => _metrics[_selected][3];

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static const _dayNames = ['اثن', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت', 'أحد'];

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final base = FirebaseFirestore.instance.collection('users').doc(uid);
    final col = widget.babyId == null
        ? base.collection('baby_logs')
        : base.collection('babies').doc(widget.babyId).collection('logs');

    final today = DateTime.now();
    final wanted = List.generate(
        7, (i) => DateTime(today.year, today.month, today.day - (6 - i)));

    try {
      final snaps = await Future.wait(
        wanted.map((d) => col.doc(_dateKey(d)).get()),
      ).timeout(const Duration(seconds: 8));

      final pts = <_DayPoint>[];
      for (var i = 0; i < wanted.length; i++) {
        final data = snaps[i].data() ?? {};
        pts.add(_DayPoint(
          date: wanted[i],
          label: _dayNames[wanted[i].weekday - 1],
          feeding: (data['feeding'] as num?)?.toInt() ?? 0,
          sleep: (data['sleep'] as num?)?.toInt() ?? 0,
          diaper: (data['diaper'] as num?)?.toInt() ?? 0,
        ));
      }
      if (!mounted) return;
      setState(() {
        _days = pts;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _valueOf(_DayPoint p) => switch (_key) {
        'feeding' => p.feeding,
        'sleep' => p.sleep,
        _ => p.diaper,
      };

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 190,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final values = _days.map(_valueOf).toList();
    final maxV = values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);
    final total = values.fold<int>(0, (a, b) => a + b);
    final avg = values.isEmpty ? 0.0 : total / values.length;
    final todayV = values.isEmpty ? 0 : values.last;
    final yesterdayV = values.length > 1 ? values[values.length - 2] : 0;
    final diff = todayV - yesterdayV;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── العنوان ──
            Row(children: [
              Container(
                width: 4, height: 18,
                decoration: BoxDecoration(
                    color: _color, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 8),
              const Text('آخر 7 أيام',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800, color: _ink)),
              const Spacer(),
              if (diff != 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (diff > 0 ? _teal : _pink).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(diff > 0 ? Icons.trending_up : Icons.trending_down,
                        size: 13, color: diff > 0 ? _teal : _pink),
                    const SizedBox(width: 4),
                    Text('${diff.abs()} عن أمس',
                        style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: diff > 0 ? _teal : _pink)),
                  ]),
                ),
            ]),
            const SizedBox(height: 12),

            // ── اختيار النشاط ──
            Row(
              children: List.generate(_metrics.length, (i) {
                final on = i == _selected;
                final c = [_pink, _lav, _teal][i];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selected = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(left: i < 2 ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: on ? c.withOpacity(0.12) : const Color(0xFFF7F5F6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: on ? c.withOpacity(0.45) : Colors.transparent),
                      ),
                      child: Column(children: [
                        Text(_metrics[i][2], style: const TextStyle(fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(_metrics[i][1],
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: on ? c : _ink3)),
                      ]),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

            // ── الأعمدة ──
            SizedBox(
              height: 124,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(_days.length, (i) {
                  final v = _valueOf(_days[i]);
                  final h = maxV == 0 ? 0.0 : (v / maxV) * 78.0;
                  final isToday = i == _days.length - 1;
                  return Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(v == 0 ? '' : '$v',
                            style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: isToday ? _color : _ink3)),
                        const SizedBox(height: 3),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          height: h < 4 && v > 0 ? 4 : h,
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: isToday
                                  ? [_color, _color.withOpacity(0.55)]
                                  : [
                                      _color.withOpacity(0.30),
                                      _color.withOpacity(0.16)
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(_days[i].label,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight:
                                    isToday ? FontWeight.w800 : FontWeight.w500,
                                color: isToday ? _ink : _ink3)),
                      ],
                    ),
                  );
                }),
              ),
            ),

            const Divider(height: 22, color: Color(0xFFF0EBEE)),

            // ── ملخّص ──
            Row(children: [
              _stat('اليوم', '$todayV', _unit, _color),
              _divider(),
              _stat('المتوسّط', avg.toStringAsFixed(1), _unit, _ink3),
              _divider(),
              _stat('الإجمالي', '$total', _unit, _ink3),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(
      width: 1, height: 26, color: const Color(0xFFF0EBEE));

  Widget _stat(String label, String value, String unit, Color c) => Expanded(
        child: Column(children: [
          Text(label,
              style: const TextStyle(fontSize: 10.5, color: _ink3)),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(children: [
              TextSpan(
                  text: value,
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w900, color: c)),
              TextSpan(
                  text: ' $unit',
                  style: const TextStyle(fontSize: 10, color: _ink3)),
            ]),
          ),
        ]),
      );
}

class _DayPoint {
  final DateTime date;
  final String label;
  final int feeding;
  final int sleep;
  final int diaper;
  const _DayPoint({
    required this.date,
    required this.label,
    required this.feeding,
    required this.sleep,
    required this.diaper,
  });
}
