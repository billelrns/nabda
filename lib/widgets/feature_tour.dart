import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════
///  محرّك الجولة التعريفية — يعتّم الشاشة ويُضيء العنصر الحقيقي المقصود
///  (زرّ، تبويب…) مع بطاقة شرح وأزرار التالي/السابق/تخطّي.
///
///  لماذا محرّك داخلي لا حزمة (showcaseview / tutorial_coach_mark)؟
///  • تحكّم كامل بالعربية من اليمين لليسار وبهوية نبضة البصرية
///  • لا تبعية جديدة على بناء أندرويد البطيء أصلاً على جهاز التطوير
///
///  يعمل كمسار شفّاف (route) لا كـ OverlayEntry: فزرّ الرجوع في أندرويد
///  يُغلق الجولة طبيعياً بدل أن يُغلق التطبيق من تحتها.
/// ═══════════════════════════════════════════════════════════════════

class TourStep {
  /// العنصر المُضاء. null = بطاقة في منتصف الشاشة (ترحيب/ختام).
  final GlobalKey? target;
  final String emoji;
  final String title;
  final String body;

  /// هامش الإضاءة حول العنصر
  final double padding;

  /// دائرة بدل مستطيل مستدير (للأيقونات الدائرية)
  final bool circle;

  const TourStep({
    this.target,
    required this.emoji,
    required this.title,
    required this.body,
    this.padding = 8,
    this.circle = false,
  });
}

class FeatureTour {
  FeatureTour._();

  static bool _running = false;
  static bool get isRunning => _running;

  /// يعرض الجولة. [onFinish] يُستدعى عند الإنهاء أو التخطّي أو الرجوع،
  /// ويُمرَّر له true إن أكملت المستخدمة كل الخطوات.
  static Future<void> show(
    BuildContext context,
    List<TourStep> steps, {
    void Function(bool completed)? onFinish,
    String nextLabel = 'التالي',
    String prevLabel = 'السابق',
    String skipLabel = 'تخطّي',
    String doneLabel = 'لنبدأ 💗',
  }) async {
    if (_running || steps.isEmpty) return;
    _running = true;
    bool completed = false;
    await Navigator.of(context, rootNavigator: true).push(PageRouteBuilder(
      opaque: false,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => _TourView(
        steps: steps,
        nextLabel: nextLabel,
        prevLabel: prevLabel,
        skipLabel: skipLabel,
        doneLabel: doneLabel,
        onCompleted: () => completed = true,
      ),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    ));
    _running = false;
    onFinish?.call(completed);
  }
}

class _TourView extends StatefulWidget {
  final List<TourStep> steps;
  final String nextLabel, prevLabel, skipLabel, doneLabel;
  final VoidCallback onCompleted;

  const _TourView({
    required this.steps,
    required this.nextLabel,
    required this.prevLabel,
    required this.skipLabel,
    required this.doneLabel,
    required this.onCompleted,
  });

  @override
  State<_TourView> createState() => _TourViewState();
}

class _TourViewState extends State<_TourView> with SingleTickerProviderStateMixin {
  static const _pink = Color(0xFFE0195B);
  static const _pinkSoft = Color(0xFFFF6BA3);
  static const _ink = Color(0xFF1F1A20);
  static const _ink3 = Color(0xFF8E8295);

  /// الخطوات القابلة للعرض فعلاً (تُستبعد التي لم يُرسم عنصرها)
  late final List<TourStep> _steps;
  int _i = 0;

  late final AnimationController _move;
  Rect? _from;
  Rect? _to;

  @override
  void initState() {
    super.initState();
    _steps = widget.steps.where((s) => s.target == null || _rectOf(s) != null).toList();
    _move = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _to = _holeFor(0);
    _from = _to;
  }

  @override
  void dispose() {
    _move.dispose();
    super.dispose();
  }

  Rect? _rectOf(TourStep s) {
    final ctx = s.target?.currentContext;
    if (ctx == null) return null;
    final ro = ctx.findRenderObject();
    if (ro is! RenderBox || !ro.attached || !ro.hasSize) return null;
    final pos = ro.localToGlobal(Offset.zero);
    final r = pos & ro.size;
    // عنصر خارج الشاشة أو بحجم صفري (تبويب مخفي مثلاً) لا يُعرض
    if (r.isEmpty || r.right < 0 || r.bottom < 0) return null;
    return r;
  }

  Rect? _holeFor(int i) {
    if (i < 0 || i >= _steps.length) return null;
    final s = _steps[i];
    final r = s.target == null ? null : _rectOf(s);
    return r?.inflate(s.padding);
  }

  void _goTo(int i) {
    if (i < 0) return;
    if (i >= _steps.length) {
      widget.onCompleted();
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _from = _currentHole;
      _to = _holeFor(i);
      _i = i;
    });
    _move.forward(from: 0);
  }

  Rect? get _currentHole {
    final t = Curves.easeOutCubic.transform(_move.value);
    if (_from == null) return _to;
    if (_to == null) return null;
    return Rect.lerp(_from, _to, t);
  }

  @override
  Widget build(BuildContext context) {
    if (_steps.isEmpty) {
      // لا شيء يُعرض — نُغلق فوراً بعد الإطار
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      return const SizedBox.shrink();
    }

    final size = MediaQuery.of(context).size;
    final pad = MediaQuery.of(context).padding;
    final step = _steps[_i];
    final last = _i == _steps.length - 1;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        type: MaterialType.transparency,
        child: AnimatedBuilder(
          animation: _move,
          builder: (context, _) {
            final hole = _currentHole;
            final circle = step.circle;

            // مكان البطاقة: في الجهة ذات المساحة الأكبر من العنصر
            Widget card = _card(step, last);
            Widget positioned;
            if (_to == null) {
              positioned = Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: card));
            } else {
              final spaceBelow = size.height - _to!.bottom;
              final spaceAbove = _to!.top;
              positioned = spaceBelow >= spaceAbove
                  ? Positioned(
                      top: (_to!.bottom + 18).clamp(pad.top + 12, size.height - 200),
                      left: 18,
                      right: 18,
                      child: card,
                    )
                  : Positioned(
                      bottom: (size.height - _to!.top + 18).clamp(pad.bottom + 12, size.height - 200),
                      left: 18,
                      right: 18,
                      child: card,
                    );
            }

            return Stack(children: [
              // التعتيم مع ثقب الإضاءة — النقر عليه يتقدّم خطوة
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _goTo(_i + 1),
                  child: CustomPaint(
                    painter: _SpotlightPainter(
                      hole: hole,
                      circle: circle,
                      glow: _pinkSoft,
                      pulse: _move.value,
                    ),
                  ),
                ),
              ),
              // ملء الشاشة بقيود ثابتة؛ ومناطقه الفارغة لا تلتقط النقر
              // فيصل إلى طبقة التعتيم تحتها.
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  transitionBuilder: (c, a) => FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                      position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(a),
                      child: c,
                    ),
                  ),
                  child: KeyedSubtree(key: ValueKey(_i), child: Stack(children: [positioned])),
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }

  Widget _card(TourStep s, bool last) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 30, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _pink.withOpacity(0.09),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: Text(s.emoji, style: const TextStyle(fontSize: 21))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(s.title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: _ink)),
          ),
          // مؤشّر التقدّم
          Text('${_i + 1} / ${_steps.length}',
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _ink3)),
        ]),
        const SizedBox(height: 10),
        Text(s.body, style: const TextStyle(fontSize: 13.5, height: 1.8, color: _ink)),
        const SizedBox(height: 12),
        // نقاط التقدّم
        Row(children: [
          for (var k = 0; k < _steps.length; k++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsetsDirectional.only(end: 4),
              width: k == _i ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: k <= _i ? _pink : _pink.withOpacity(0.18),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          if (!last)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(widget.skipLabel, style: const TextStyle(color: _ink3, fontWeight: FontWeight.w700)),
            ),
          const Spacer(),
          if (_i > 0)
            TextButton(
              onPressed: () => _goTo(_i - 1),
              child: Text(widget.prevLabel, style: const TextStyle(color: _pink, fontWeight: FontWeight.w700)),
            ),
          const SizedBox(width: 4),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _pink,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => _goTo(_i + 1),
            child: Text(last ? widget.doneLabel : widget.nextLabel,
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ]),
      ]),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect? hole;
  final bool circle;
  final Color glow;
  final double pulse;

  _SpotlightPainter({required this.hole, required this.circle, required this.glow, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final screen = Offset.zero & size;
    final dim = Paint()..color = const Color(0xFF14070D).withOpacity(0.74);

    if (hole == null) {
      canvas.drawRect(screen, dim);
      return;
    }

    final shape = _shape(hole!);
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(screen)
      ..addPath(shape, Offset.zero);
    canvas.drawPath(path, dim);

    // هالة وردية حول العنصر المُضاء
    final ring = Paint()
      ..color = glow.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(shape, ring);

    final halo = Paint()
      ..color = glow.withOpacity(0.25 * (1 - pulse))
      ..style = PaintingStyle.stroke
      ..strokeWidth = lerpDouble(4, 14, pulse)!;
    canvas.drawPath(_shape(hole!.inflate(4 + 6 * pulse)), halo);
  }

  Path _shape(Rect r) {
    if (circle) {
      final d = r.longestSide;
      return Path()..addOval(Rect.fromCenter(center: r.center, width: d, height: d));
    }
    return Path()..addRRect(RRect.fromRectAndRadius(r, const Radius.circular(18)));
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter old) =>
      old.hole != hole || old.circle != circle || old.pulse != pulse;
}
