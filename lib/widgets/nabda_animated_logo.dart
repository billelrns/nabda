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
    final w = size.width, h = size.height;

    // ① توهّج خارجي ينبض مع القلب
    final glowStrength = (motherScale - 1.0).clamp(0.0, 0.08) / 0.08;
    canvas.drawPath(
      motherPath,
      Paint()
        ..color = _kPink.withValues(alpha: 0.20 + 0.25 * glowStrength)
        ..maskFilter =
            MaskFilter.blur(BlurStyle.normal, w * (0.05 + 0.04 * glowStrength)),
    );

    // ② ظل تلامسي أسفل القلب يعطي إحساس الارتفاع عن السطح
    canvas.drawPath(
      motherPath.shift(Offset(0, h * 0.045)),
      Paint()
        ..color = const Color(0xFF9E0B3F).withValues(alpha: 0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.06),
    );

    // ③ الجسم الزجاجي: تدرّج قطري من فاتح جداً أعلى اليسار إلى غامق أسفل اليمين
    canvas.drawPath(
      motherPath,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.45, -0.55),
          radius: 1.25,
          colors: const [
            Color(0xFFFF9BC4), // ضوء الحافة العلوية
            _kPink,
            _kDeepPink,
            Color(0xFFA80D48), // عمق الحافة السفلية
          ],
          stops: const [0.0, 0.38, 0.74, 1.0],
        ).createShader(motherRect),
    );

    canvas.save();
    canvas.clipPath(motherPath);

    // ④ ضوء مرتد من الأسفل (بصمة الزجاج الحقيقي)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.86),
        width: w * 0.62,
        height: h * 0.26,
      ),
      Paint()
        ..color = const Color(0xFFFF6FA8).withValues(alpha: 0.55)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.10),
    );

    // ⑤ اللمعة الرئيسية — بقعة بيضاء ناعمة على الفصّ الأيسر
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.29, h * 0.24),
        width: w * 0.36,
        height: h * 0.24,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.62)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.055),
    );

    // ⑥ لمعة ثانوية صغيرة حادّة — تعطي الحسّ الزجاجي المصقول
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.235, h * 0.205),
        width: w * 0.115,
        height: h * 0.075,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.92)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.012),
    );

    // ⑦ لمعة طويلة على الفصّ الأيمن (انعكاس مصدر ضوء ثانٍ)
    canvas.save();
    canvas.translate(w * 0.70, h * 0.30);
    canvas.rotate(-0.5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w * 0.10, height: h * 0.20),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.34)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.035),
    );
    canvas.restore();

    // ⑧ التجويف الداخلي — حفرة زجاجية غائرة تحتضن قلب الطفل
    final cavityRect = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.53),
      width: w * 0.62,
      height: h * 0.62,
    );
    final cavityPath = _heartPath(cavityRect);

    // ظل داخلي علوي يوهم بالغَور
    canvas.drawPath(
      cavityPath.shift(Offset(0, -h * 0.012)),
      Paint()
        ..color = const Color(0xFF8E0A3A).withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.035),
    );

    canvas.drawPath(
      cavityPath,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.2, 0.35),
          radius: 1.0,
          colors: [
            _kLightPink.withValues(alpha: 0.55),
            _kBabyPink.withValues(alpha: 0.92),
          ],
        ).createShader(cavityRect)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.018),
    );

    canvas.restore(); // نهاية القص داخل قلب الأم

    // ⑨ حافة ضوئية رفيعة حول القلب كلّه (حدّ الزجاج)
    canvas.drawPath(
      motherPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.012
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.75),
            Colors.white.withValues(alpha: 0.05),
            const Color(0xFFFF8FBB).withValues(alpha: 0.45),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(motherRect),
    );

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

    // هالة دافئة حول قلب الطفل — كأنه يتوهّج داخل قلب أمّه
    canvas.drawPath(
      babyPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.30 + 0.30 * ((babyScale - 1.0).clamp(0.0, 0.12) / 0.12))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, babyBase * 0.14),
    );

    // جسم زجاجي لؤلؤي
    canvas.drawPath(
      babyPath,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.5),
          radius: 1.2,
          colors: const [
            Color(0xFFFFFFFF),
            Color(0xFFFFE4EF),
            _kBabyPink,
            Color(0xFFF48CB3),
          ],
          stops: const [0.0, 0.30, 0.70, 1.0],
        ).createShader(babyRect),
    );

    canvas.save();
    canvas.clipPath(babyPath);

    // ضوء مرتد أسفل قلب الطفل
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, babyBase * 0.30),
        width: babyBase * 0.60,
        height: babyBase * 0.24,
      ),
      Paint()
        ..color = const Color(0xFFFFB3D0).withValues(alpha: 0.60)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, babyBase * 0.10),
    );

    // لمعة رئيسية
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-babyBase * 0.17, -babyBase * 0.20),
        width: babyBase * 0.34,
        height: babyBase * 0.20,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, babyBase * 0.045),
    );

    // نقطة لمعة حادّة
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-babyBase * 0.21, -babyBase * 0.235),
        width: babyBase * 0.11,
        height: babyBase * 0.07,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.98),
    );
    canvas.restore();

    // حافة ضوئية رفيعة
    canvas.drawPath(
      babyPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = babyBase * 0.022
        ..color = Colors.white.withValues(alpha: 0.55),
    );

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
    final w = size.width, h = size.height;

    // ظل تلامسي
    canvas.drawPath(
      path.shift(Offset(0, h * 0.06)),
      Paint()
        ..color = const Color(0xFF9E0B3F).withValues(alpha: 0.20)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.08),
    );

    // جسم زجاجي بنفس تدرّج القلب الكبير
    canvas.drawPath(
      path,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.45, -0.55),
          radius: 1.25,
          colors: [Color(0xFFFF9BC4), _kPink, _kDeepPink, Color(0xFFA80D48)],
          stops: [0.0, 0.38, 0.74, 1.0],
        ).createShader(rect),
    );

    canvas.save();
    canvas.clipPath(path);

    // ضوء مرتد سفلي
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.86),
        width: w * 0.62,
        height: h * 0.26,
      ),
      Paint()
        ..color = const Color(0xFFFF6FA8).withValues(alpha: 0.50)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.12),
    );

    // قلب طفل صغير بالداخل — نفس هوية اللوغو مصغّرة
    final innerRect = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.55),
      width: w * 0.42,
      height: h * 0.42,
    );
    canvas.drawPath(
      _HeartsPainter._heartPath(innerRect),
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.4),
          colors: [Colors.white, Color(0xFFFFD6E6)],
        ).createShader(innerRect)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.015),
    );

    // لمعة رئيسية
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.29, h * 0.24),
        width: w * 0.34,
        height: h * 0.20,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.60)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.055),
    );

    // نقطة لمعة حادّة
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.235, h * 0.205),
        width: w * 0.11,
        height: h * 0.07,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.95),
    );
    canvas.restore();

    // حافة ضوئية
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.03
        ..color = Colors.white.withValues(alpha: 0.45),
    );
  }

  @override
  bool shouldRepaint(CustomPainter old) => false;
}
