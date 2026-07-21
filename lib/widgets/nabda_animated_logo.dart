import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ═══════════════════════════════════════════════════════════════════
///  شعار «نبضة» المتحرك — الهوية الحركية للتطبيق (2026)
///
///  • قلب الأم الكبير ينبض بإيقاع قلب حقيقي (~60 نبضة/دقيقة).
///  • قلب الطفل الصغير بداخله ينبض أسرع (~140 نبضة/دقيقة — مثل نبض
///    الجنين الحقيقي) ويتمايل بمرح كحركة طفل.
///  • قلوب صغيرة تقفز وتلعب فوق كلمة «نبضة» كأطفال صغار.
/// ═══════════════════════════════════════════════════════════════════

// ── ألوان الشعار ──
const _kDeepPink = Color(0xFFE0195B);
const _kPink = Color(0xFFF0347C);
const _kLightPink = Color(0xFFF8BBD0);
const _kBabyPink = Color(0xFFFFD6E3);
const _kWordPink = Color(0xFFE0195B);

/// الشعار الكامل: القلبان النابضان + كلمة «نبضة» مع قلوب تلعب فوقها.
class NabdaAnimatedLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;

  const NabdaAnimatedLogo({
    Key? key,
    this.size = 200,
    this.showWordmark = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NabdaBeatingHearts(size: size),
        if (showWordmark) ...[
          SizedBox(height: size * 0.02),
          NabdaWordmark(width: size * 0.82),
        ],
      ],
    );
  }
}

/// ─────────────────────────────────────────────────────────────────
///  القلبان النابضان: قلب الأم (كبير) وقلب الطفل (صغير بالداخل)
/// ─────────────────────────────────────────────────────────────────
class NabdaBeatingHearts extends StatefulWidget {
  final double size;
  const NabdaBeatingHearts({Key? key, this.size = 200}) : super(key: key);

  @override
  State<NabdaBeatingHearts> createState() => _NabdaBeatingHeartsState();
}

class _NabdaBeatingHeartsState extends State<NabdaBeatingHearts>
    with TickerProviderStateMixin {
  // قلب الأم: ~60 نبضة/دقيقة (دورة كاملة كل ثانية) بإيقاع "لَب-دَب"
  late final AnimationController _motherC;
  late final Animation<double> _motherBeat;

  // قلب الطفل: ~140 نبضة/دقيقة (أسرع، مثل نبض الجنين)
  late final AnimationController _babyC;
  late final Animation<double> _babyBeat;

  // تمايل الطفل المرح (حركة بطيئة مستقلة عن النبض)
  late final AnimationController _swayC;

  @override
  void initState() {
    super.initState();

    _motherC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    _motherBeat = TweenSequence<double>([
      // لَب: انقباض قوي
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.075)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.075, end: 0.985)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 12,
      ),
      // دَب: نبضة أخف
      TweenSequenceItem(
        tween: Tween(begin: 0.985, end: 1.045)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.045, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      // راحة
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 44),
    ]).animate(_motherC);

    _babyC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 430),
    )..repeat();
    _babyBeat = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.14)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.14, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 30),
    ]).animate(_babyC);

    _swayC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _motherC.dispose();
    _babyC.dispose();
    _swayC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_motherC, _babyC, _swayC]),
        builder: (context, _) {
          final sway = math.sin(_swayC.value * 2 * math.pi);
          return CustomPaint(
            painter: _HeartsPainter(
              motherScale: _motherBeat.value,
              babyScale: _babyBeat.value,
              babySway: sway,
            ),
          );
        },
      ),
    );
  }
}

class _HeartsPainter extends CustomPainter {
  final double motherScale;
  final double babyScale;
  final double babySway; // -1..1

  _HeartsPainter({
    required this.motherScale,
    required this.babyScale,
    required this.babySway,
  });

  /// مسار قلب داخل مستطيل معيّن.
  static Path _heartPath(Rect r) {
    final w = r.width, h = r.height;
    final x = r.left, y = r.top;
    final path = Path();
    path.moveTo(x + 0.50 * w, y + 0.32 * h);
    path.cubicTo(
        x + 0.36 * w, y + 0.06 * h, x + 0.04 * w, y + 0.12 * h, x + 0.04 * w, y + 0.38 * h);
    path.cubicTo(
        x + 0.04 * w, y + 0.60 * h, x + 0.28 * w, y + 0.74 * h, x + 0.50 * w, y + 0.92 * h);
    path.cubicTo(
        x + 0.72 * w, y + 0.74 * h, x + 0.96 * w, y + 0.60 * h, x + 0.96 * w, y + 0.38 * h);
    path.cubicTo(
        x + 0.96 * w, y + 0.12 * h, x + 0.64 * w, y + 0.06 * h, x + 0.50 * w, y + 0.32 * h);
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // ══ قلب الأم ══
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(motherScale);
    canvas.translate(-center.dx, -center.dy);

    final motherRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final motherPath = _heartPath(motherRect);

    // توهج خارجي ينبض مع القلب
    final glowStrength = (motherScale - 1.0).clamp(0.0, 0.08) / 0.08;
    canvas.drawPath(
      motherPath,
      Paint()
        ..color = _kPink.withValues(alpha: 0.18 + 0.22 * glowStrength)
        ..maskFilter =
            MaskFilter.blur(BlurStyle.normal, size.width * (0.04 + 0.03 * glowStrength)),
    );

    // تعبئة متدرجة
    canvas.drawPath(
      motherPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [_kPink, _kDeepPink],
        ).createShader(motherRect),
    );

    // لمعة زجاجية على الفص الأيسر العلوي
    canvas.save();
    canvas.clipPath(motherPath);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.30, size.height * 0.22),
        width: size.width * 0.34,
        height: size.height * 0.18,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.05),
    );

    // تجويف داخلي (عمق) يحتضن قلب الطفل
    final cavityRect = Rect.fromCenter(
      center: Offset(size.width * 0.50, size.height * 0.52),
      width: size.width * 0.60,
      height: size.height * 0.60,
    );
    canvas.drawPath(
      _heartPath(cavityRect),
      Paint()
        ..shader = RadialGradient(
          colors: [
            _kBabyPink.withValues(alpha: 0.85),
            _kLightPink.withValues(alpha: 0.35),
          ],
        ).createShader(cavityRect)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.02),
    );
    canvas.restore(); // نهاية القص داخل قلب الأم
    canvas.restore(); // نهاية تحجيم قلب الأم

    // ══ قلب الطفل ══
    final babyCenter = Offset(
      size.width * (0.50 + 0.015 * babySway), // تمايل أفقي مرح
      size.height * 0.53,
    );
    final babyBase = size.width * 0.34;

    canvas.save();
    canvas.translate(babyCenter.dx, babyCenter.dy);
    canvas.rotate(babySway * 0.09); // ميلان لطيف كحركة طفل
    canvas.scale(babyScale);

    final babyRect = Rect.fromCenter(
      center: Offset.zero,
      width: babyBase,
      height: babyBase,
    );
    final babyPath = _heartPath(babyRect);

    // ظل ناعم تحت قلب الطفل
    canvas.drawPath(
      babyPath.shift(Offset(0, babyBase * 0.04)),
      Paint()
        ..color = _kDeepPink.withValues(alpha: 0.25)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, babyBase * 0.06),
    );

    canvas.drawPath(
      babyPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFFFFEEF4), _kBabyPink, Color(0xFFF9A8C5)],
        ).createShader(babyRect),
    );

    // لمعة صغيرة على قلب الطفل
    canvas.save();
    canvas.clipPath(babyPath);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-babyBase * 0.18, -babyBase * 0.22),
        width: babyBase * 0.34,
        height: babyBase * 0.18,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.75)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, babyBase * 0.05),
    );
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HeartsPainter old) =>
      old.motherScale != motherScale ||
      old.babyScale != babyScale ||
      old.babySway != babySway;
}

/// ─────────────────────────────────────────────────────────────────
///  كلمة «نبضة» مع قلوب صغيرة تقفز وتلعب فوقها كأطفال صغار
/// ─────────────────────────────────────────────────────────────────
class NabdaWordmark extends StatefulWidget {
  final double width;
  const NabdaWordmark({Key? key, this.width = 160}) : super(key: key);

  @override
  State<NabdaWordmark> createState() => _NabdaWordmarkState();
}

class _NabdaWordmarkState extends State<NabdaWordmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _playC;

  @override
  void initState() {
    super.initState();
    _playC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat();
  }

  @override
  void dispose() {
    _playC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width;
    final fontSize = w * 0.42;
    final heartSize = w * 0.115;
    // مواضع القلوب فوق الكلمة (نسب من العرض، من اليمين لليسار مثل العربية)
    const positions = [0.82, 0.55, 0.30, 0.08];
    const phases = [0.0, 0.35, 0.60, 0.15];

    return SizedBox(
      width: w,
      height: fontSize * 1.55 + heartSize * 1.6,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // الكلمة
          Positioned(
            bottom: 0,
            child: Text(
              'نبضة',
              style: GoogleFonts.almarai(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: _kWordPink,
                height: 1.15,
                shadows: [
                  Shadow(
                    color: _kDeepPink.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
          // القلوب اللاعبة
          ...List.generate(positions.length, (i) {
            return Positioned(
              top: heartSize * 0.7,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _playC,
                builder: (context, _) {
                  final t = (_playC.value + phases[i]) % 1.0;
                  // قفزة: |sin| يعطي قفزات متتالية مثل طفل يقفز
                  final jump = math.sin(t * math.pi * 2).abs();
                  final eased = Curves.easeOut.transform(jump);
                  // سحق وتمدد عند الهبوط (squash & stretch)
                  final squash = 1.0 - 0.18 * (1.0 - eased);
                  final stretch = 1.0 + 0.12 * eased;
                  final tilt = math.sin((t + phases[i]) * math.pi * 4) * 0.18;
                  return Align(
                    alignment: Alignment(positions[i] * 2 - 1, -1),
                    child: Transform.translate(
                      offset: Offset(0, -eased * heartSize * 0.55),
                      child: Transform.rotate(
                        angle: tilt,
                        child: Transform.scale(
                          scaleX: squash,
                          scaleY: stretch,
                          child: _MiniHeart(size: heartSize),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// قلب صغير لامع (يُستخدم للقلوب اللاعبة وأي زخرفة أخرى).
class _MiniHeart extends StatelessWidget {
  final double size;
  const _MiniHeart({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _MiniHeartPainter(),
    );
  }
}

class _MiniHeartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = _HeartsPainter._heartPath(rect);
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kPink, _kDeepPink],
        ).createShader(rect),
    );
    // لمعة
    canvas.save();
    canvas.clipPath(path);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.32, size.height * 0.26),
        width: size.width * 0.30,
        height: size.height * 0.16,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.06),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter old) => false;
}
