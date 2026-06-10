import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const _cPeriod = Color(0xFFFF5A8A);
const _cFertile = Color(0xFF66BB6A);
const _cOv = Color(0xFFFFC107);
const _cPre = Color(0xFF5B9BE8);
const _cNormal = Color(0xFFD9CEDB);
const _ink = Color(0xFF1B1320);
const _ink3 = Color(0xFF8E8295);

const _arMonths = ['', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];

Color _phaseColor(int pos, int cl, int pl, int lut) {
  final ov = cl - lut;
  if (pos < pl) return _cPeriod;
  if (pos == ov) return _cOv;
  if (pos >= ov - 5 && pos <= ov + 1) return _cFertile;
  if (pos >= cl - 5) return _cPre;
  return _cNormal;
}

({String name, String emoji}) _phaseInfo(int pos, int cl, int pl, int lut) {
  final ov = cl - lut;
  if (pos < pl) return (name: 'الحيض', emoji: '🩸');
  if (pos == ov) return (name: 'الإباضة', emoji: '🥚');
  if (pos >= ov - 5 && pos <= ov + 1) return (name: 'الخصوبة', emoji: '🌱');
  if (pos >= cl - 5) return (name: 'ما قبل الدورة', emoji: '🌙');
  return (name: 'مرحلة عادية', emoji: '🤍');
}

/// عجلة الدورة: حلقة نقاط ملوّنة حسب الطور، متحركة وتفاعلية.
/// مستقلّة بذاتها — تُدرَج بسطر واحد أعلى تبويب الدورة.
class CyclePhaseWheel extends StatefulWidget {
  const CyclePhaseWheel({Key? key}) : super(key: key);
  @override
  State<CyclePhaseWheel> createState() => _CyclePhaseWheelState();
}

class _CyclePhaseWheelState extends State<CyclePhaseWheel> with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _pulse;
  int? _selected; // اليوم المضغوط (pos)، null = اليوم الحالي

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 950))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entrance.dispose();
    _pulse.dispose();
    super.dispose();
  }

  DateTime _curStart(DateTime lp, int cl) {
    final t = DateTime.now();
    final today = DateTime(t.year, t.month, t.day);
    var s = DateTime(lp.year, lp.month, lp.day);
    int g = 0;
    while (s.add(Duration(days: cl)).isBefore(today) && g < 60) { s = s.add(Duration(days: cl)); g++; }
    return s;
  }

  void _onTapUp(TapUpDetails d, double side, int cl) {
    final c = Offset(side / 2, side / 2);
    final v = d.localPosition - c;
    final R = side / 2 - 20;
    if ((v.distance - R).abs() > 30) { setState(() => _selected = null); return; }
    double rel = atan2(v.dy, v.dx) + pi / 2;
    if (rel < 0) rel += 2 * pi;
    final idx = (rel / (2 * pi / cl)).round() % cl;
    setState(() => _selected = idx);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final d = snap.data!.data() as Map<String, dynamic>? ?? {};
        final ts = d['lastPeriodStart'];
        if (ts is! Timestamp) return const SizedBox.shrink();
        final lp = ts.toDate();
        final cl = (d['cycleLength'] as num?)?.toInt() ?? 28;
        final lut = (d['lutealPhase'] as num?)?.toInt() ?? 14;
        final pl = ((d['cycleProfile'] as Map?)?['periodLength'] as num?)?.toInt() ?? 5;
        final curStart = _curStart(lp, cl);
        final today = DateTime.now();
        final today0 = DateTime(today.year, today.month, today.day);
        int curPos = today0.difference(curStart).inDays;
        if (curPos < 0) curPos = 0;
        if (curPos >= cl) curPos = curPos % cl;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
            child: LayoutBuilder(builder: (context, cons) {
              final side = min(cons.maxWidth, 330.0);
              final shownPos = _selected ?? curPos;
              final info = _phaseInfo(shownPos, cl, pl, lut);
              final shownDate = curStart.add(Duration(days: shownPos));
              return Center(child: SizedBox(
                width: side, height: side,
                child: GestureDetector(
                  onTapUp: (e) => _onTapUp(e, side, cl),
                  child: Stack(alignment: Alignment.center, children: [
                    AnimatedBuilder(
                      animation: Listenable.merge([_entrance, _pulse]),
                      builder: (_, __) => CustomPaint(size: Size.square(side),
                        painter: _WheelPainter(cl: cl, pl: pl, lut: lut, curPos: curPos,
                          selected: _selected, entrance: _entrance.value, pulse: _pulse.value)),
                    ),
                    IgnorePointer(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('${shownDate.day} ${_arMonths[shownDate.month]}',
                        style: const TextStyle(fontSize: 13, color: _ink3, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(info.emoji, style: const TextStyle(fontSize: 30)),
                      const SizedBox(height: 4),
                      Text(info.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: _ink)),
                      const SizedBox(height: 4),
                      Text('اليوم ${shownPos + 1} من ${cl}',
                        style: const TextStyle(fontSize: 12.5, color: _ink3, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(_selected == null ? 'اضغطي على أي يوم 👆' : 'اليوم الحالي: ${curPos + 1}',
                        style: const TextStyle(fontSize: 10.5, color: _ink3)),
                    ])),
                  ]),
                ),
              ));
            }),
          ),
        );
      },
    );
  }
}

class _WheelPainter extends CustomPainter {
  final int cl, pl, lut, curPos;
  final int? selected;
  final double entrance, pulse;
  _WheelPainter({required this.cl, required this.pl, required this.lut, required this.curPos,
    required this.selected, required this.entrance, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final R = size.width / 2 - 20;
    final baseDot = (2 * pi * R / cl) * 0.32; // مسافة بين النقاط
    final dotR = baseDot.clamp(4.0, 9.0);
    for (int i = 0; i < cl; i++) {
      // ظهور متدرّج
      final t = (entrance * 1.5 - i / cl * 0.5).clamp(0.0, 1.0);
      final appear = Curves.easeOut.transform(t);
      if (appear <= 0) continue;
      final ang = -pi / 2 + 2 * pi * i / cl;
      final p = Offset(center.dx + R * cos(ang), center.dy + R * sin(ang));
      final color = _phaseColor(i, cl, pl, lut);
      double r = dotR * appear;
      bool glow = false;
      if (i == curPos) { r *= (1 + 0.30 * pulse); glow = true; }
      if (i == selected) { r = dotR * 1.6 * appear; glow = true; }
      if (glow) {
        canvas.drawCircle(p, r + 5, Paint()..color = color.withValues(alpha: 0.30)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      }
      canvas.drawCircle(p, r, Paint()..color = color);
      if (i == selected) {
        canvas.drawCircle(p, r + 3, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2);
      }
      if (i == curPos) {
        canvas.drawCircle(p, r * 0.45, Paint()..color = Colors.white);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WheelPainter old) =>
      old.entrance != entrance || old.pulse != pulse || old.selected != selected ||
      old.curPos != curPos || old.cl != cl;
}
