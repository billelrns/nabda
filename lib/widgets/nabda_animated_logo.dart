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

/// اتجاه تركيب الشعار.
enum NabdaLogoOrientation {
  /// الكلمة على اليسار والقلبان على اليمين (الشكل الرسمي — لافتات، هيدر الموقع).
  horizontal,

  /// القلبان فوق والكلمة تحت (للشاشات الضيقة وأيقونة البداية).
  vertical,
}

/// الشعار الكامل: القلبان النابضان + كلمة «نبضة» ونقاطها قلوب تقفز.
class NabdaAnimatedLogo extends StatelessWidget {
  /// ارتفاع كتلة القلبين (وهو ارتفاع الشعار كاملاً في الوضع الأفقي).
  final double size;
  final bool showWordmark;
  final NabdaLogoOrientation orientation;

  const NabdaAnimatedLogo({
    super.key,
    this.size = 200,
    this.showWordmark = true,
    this.orientation = NabdaLogoOrientation.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    if (!showWordmark) return NabdaBeatingHearts(size: size);

    if (orientation == NabdaLogoOrientation.vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NabdaBeatingHearts(size: size),
          SizedBox(height: size * 0.02),
          NabdaWordmarkVector(width: size * 0.95),
        ],
      );
    }

    // ── الوضع الأفقي: الكلمة يساراً، القلبان يميناً ──
    // Directionality.ltr إجباري: التطبيق RTL، وبدونها ينقلب الترتيب.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          NabdaWordmarkVector(width: size * kNabdaWordRatio),
          SizedBox(width: size * kNabdaGapRatio),
          NabdaBeatingHearts(size: size),
        ],
      ),
    );
  }
}

/// نِسَب التركيب الأفقي المعتمدة:
/// ارتفاع الكلمة = 72% من ارتفاع القلب · الفجوة = 13% منه.
const double kNabdaWordRatio = 1.609; // عرض الكلمة ÷ ارتفاع القلب
const double kNabdaGapRatio = 0.130; // الفجوة ÷ ارتفاع القلب

/// شعار أفقي مضغوط للأشرطة العلوية (هيدر التطبيق).
///
/// `height` هو ارتفاع القلب — والعرض الكلي ≈ height × 2.35.
/// مثال: `NabdaLogoBar(height: 38)` → 89×38 تقريباً.
class NabdaLogoBar extends StatelessWidget {
  final double height;
  const NabdaLogoBar({super.key, this.height = 38});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          NabdaWordmarkVector(width: height * kNabdaWordRatio),
          SizedBox(width: height * kNabdaGapRatio),
          NabdaBeatingHearts(size: height),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────
///  القلبان النابضان: قلب الأم (كبير) وقلب الطفل (صغير بالداخل)
/// ─────────────────────────────────────────────────────────────────
class NabdaBeatingHearts extends StatefulWidget {
  final double size;
  const NabdaBeatingHearts({super.key, this.size = 200});

  @override
  State<NabdaBeatingHearts> createState() => _NabdaBeatingHeartsState();
}

class _NabdaBeatingHeartsState extends State<NabdaBeatingHearts>
    with TickerProviderStateMixin {
  // قلب الأم: 40 نبضة/دقيقة — نبضة واحدة عريضة ناعمة
  late final AnimationController _motherC;

  // قلب الطفل: 140 نبضة/دقيقة — لَب-دَب سريع (نبض الجنين الحقيقي)
  late final AnimationController _babyC;

  // انجراف الطفل داخل التجويف
  late final AnimationController _driftC;

  @override
  void initState() {
    super.initState();
    _motherC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), // 40 ن/د
    )..repeat();
    _babyC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 429), // 140 ن/د
    )..repeat();
    _driftC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();
  }

  @override
  void dispose() {
    _motherC.dispose();
    _babyC.dispose();
    _driftC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    // نِسب مقاسة من الشعار الأصلي — نفس أرقام فيديو الشعار الرسمي
    const imgAspect = 1252 / 1153; // نسبة صورة القلب الكبير
    final imgH = s / imgAspect;
    final topOff = (s - imgH) / 2;
    final babyW = 0.45 * s;
    final babyH = babyW * 690 / 813; // نسبة صورة القلب الصغير
    final babyCx = 0.527 * s;
    final babyCy = topOff + 0.570 * imgH;

    return SizedBox(
      width: s,
      height: s,
      child: AnimatedBuilder(
        animation: Listenable.merge([_motherC, _babyC, _driftC]),
        builder: (context, _) {
          final ms = _softBeat(_motherC.value, 0.040);
          final bs = _sharpBeat(_babyC.value, 0.115);
          final u = _driftC.value;
          final dx = 0.013 * s * math.sin(u * 2 * math.pi);
          final dy = 0.017 * s * math.sin(u * 4 * math.pi + 0.7);
          final rot = 0.0628 * math.sin(u * 2 * math.pi + 1.1); // ±3.6°

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // ── قلب الأم ──
              Positioned.fill(
                child: Transform.scale(
                  scale: ms,
                  child: Image.asset(
                    'assets/images/heart_big.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (_, __, ___) => CustomPaint(
                      painter: _HeartsPainter(
                        motherScale: 1, babyScale: 1, babySway: 0),
                    ),
                  ),
                ),
              ),
              // ── قلب الطفل يطفو داخل التجويف ──
              Positioned(
                left: (s / 2) + (babyCx - s / 2) * ms - babyW / 2 + dx,
                top: (s / 2) + (babyCy - s / 2) * ms - babyH / 2 + dy,
                width: babyW,
                height: babyH,
                child: Transform.rotate(
                  angle: rot,
                  child: Transform.scale(
                    scale: bs,
                    child: Image.asset(
                      'assets/images/heart_small.png',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// نبضة جاوسية دورية — ناعمة رياضياً بلا أي انكسار، وتُغلق دورتها تماماً.
double _g(double p, double c, double w) {
  var d = (p - c).abs();
  if (d > 0.5) d = 1.0 - d;
  return math.exp(-math.pow(d / w, 2).toDouble());
}

/// نبضة الأم: تمدّد واحد عريض ثم راحة طويلة.
double _softBeat(double p, double amp) =>
    1.0 +
    amp *
        (1.00 * _g(p, 0.13, 0.105) -
            0.12 * _g(p, 0.32, 0.120) +
            0.30 * _g(p, 0.46, 0.130));

/// نبضة الطفل: لَب — ارتداد — دَب — استقرار.
double _sharpBeat(double p, double amp) =>
    1.0 +
    amp *
        (1.00 * _g(p, 0.085, 0.048) -
            0.26 * _g(p, 0.185, 0.055) +
            0.50 * _g(p, 0.310, 0.062) -
            0.11 * _g(p, 0.430, 0.075));

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
  const NabdaWordmark({super.key, this.width = 160});

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

/// ─────────────────────────────────────────────────────────────────
///  كلمة «نبضة» كمسار فيكتور — نقاط الحروف الخمس صارت قلوباً تقفز
///
///  الكلمة مستخرجة مباشرة من خط Almarai ExtraBold كمسار Bézier، فشكلها
///  ثابت تماماً ولا يتغيّر مهما اختلف الجهاز أو توفّر الخط. النقاط
///  (ن · ب · ض · ة×2) حُذفت من المسار ووُضع مكانها قلوب صغيرة تقفز
///  وتتزحلق على الحرف ثم ترجع إلى موضع النقطة بالضبط.
/// ─────────────────────────────────────────────────────────────────

/// صندوق عرض مسار الكلمة (وحدات الخط).
const double _kWordVBW = 2143.0;
const double _kWordVBH = 883.0;

/// مسار جسم الكلمة بلا نقاط.
const String _kWordPathD =
    'M446 193L446 537Q446 543 450 547Q454 551 462 551L496 551L496 680L417 680'
    'Q366 680 324 640Q275 689 206 689L205 689L203 689Q103 689 46 606Q0 541 0 451'
    'Q0 341 70 269Q133 204 227 204Q278 204 328 225L369 193ZM291 344Q267 338 246 338'
    'Q202 338 177 368Q152 398 152 451Q152 501 179.5 533Q207 565 251 565Q268 565 291 560Z'
    'M823 343Q950 207 1123 207Q1247 207 1330 281Q1407 350 1407 456L1407 512'
    'Q1407 524 1408 551L1439 551L1439 680L1420 680L1382 634L1380 634Q1342 680 1283 680'
    'L489 680L489 551L669 551L669 220L823 220ZM1253 473Q1252 408 1201 370Q1159 339 1104 339'
    'Q984 339 884 457Q878 467 863 488Q835 529 822 551L1238 551Q1253 551 1253 537Z'
    'M1766 220L1766 542Q1766 546 1767 551L1816 551L1816 680L1785 680L1741 634L1739 634'
    'Q1701 680 1641 680L1432 680L1432 551L1592 551Q1601 551 1606 545Q1612 540 1612 531'
    'L1612 220ZM2143 220L2143 556Q2143 600 2114 635Q2076 680 2018 680L1809 680L1809 551'
    'L1974 551Q1980 551 1984 548Q1989 544 1989 537L1989 220Z';

/// مواضع النقاط الخمس (مرتّبة من اليمين لليسار: ن · ب · ض · ة · ة).
/// `dy` هو اتجاه القفزة: سالب = القلب يقفز لأعلى، موجب = لأسفل (نقطة الباء).
const List<List<double>> _kDots = [
  //  cx,      cy,   slideX, hopDir
  [2065.0, 78.0, -46.0, -1.0], // نقطة النون (فوق)
  [1688.0, 804.5, 52.0, 1.0], // نقطة الباء (تحت)
  [1058.0, 78.0, -46.0, -1.0], // نقطة الضاد (فوق)
  [368.0, 78.0, -46.0, -1.0], // نقطة التاء المربوطة اليمنى
  [188.5, 78.0, -46.0, -1.0], // نقطة التاء المربوطة اليسرى
];

/// قطر القلب الذي يحلّ محلّ النقطة (النقطة نفسها 156 وحدة).
const double _kDotHeart = 195.0;

Path? _wordPathCache;

/// محلّل مبسّط لمسار SVG — يدعم M · L · Q · C · Z بإحداثيات مطلقة.
Path _parseSvgPath(String d) {
  final path = Path();
  final cmdRe = RegExp(r'([MLQCZ])([^MLQCZ]*)');
  final numRe = RegExp(r'-?\d*\.?\d+');
  for (final m in cmdRe.allMatches(d)) {
    final cmd = m.group(1)!;
    final n = numRe
        .allMatches(m.group(2)!)
        .map((e) => double.parse(e.group(0)!))
        .toList();
    switch (cmd) {
      case 'M':
        for (int i = 0; i + 1 < n.length; i += 2) {
          if (i == 0) {
            path.moveTo(n[0], n[1]);
          } else {
            path.lineTo(n[i], n[i + 1]);
          }
        }
        break;
      case 'L':
        for (int i = 0; i + 1 < n.length; i += 2) {
          path.lineTo(n[i], n[i + 1]);
        }
        break;
      case 'Q':
        for (int i = 0; i + 3 < n.length; i += 4) {
          path.quadraticBezierTo(n[i], n[i + 1], n[i + 2], n[i + 3]);
        }
        break;
      case 'C':
        for (int i = 0; i + 5 < n.length; i += 6) {
          path.cubicTo(n[i], n[i + 1], n[i + 2], n[i + 3], n[i + 4], n[i + 5]);
        }
        break;
      case 'Z':
        path.close();
        break;
    }
  }
  return path;
}

/// الكلمة كاملة مع قلوبها المتحرّكة.
class NabdaWordmarkVector extends StatefulWidget {
  final double width;
  const NabdaWordmarkVector({super.key, this.width = 300});

  @override
  State<NabdaWordmarkVector> createState() => _NabdaWordmarkVectorState();
}

class _NabdaWordmarkVectorState extends State<NabdaWordmarkVector>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width;
    // مساحة إضافية أعلى وأسفل حتى لا تُقصّ القلوب أثناء القفز
    final pad = w * 0.075;
    return SizedBox(
      width: w,
      height: w * (_kWordVBH / _kWordVBW) + pad * 2,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          painter: _WordVectorPainter(t: _c.value, pad: pad),
        ),
      ),
    );
  }
}

class _WordVectorPainter extends CustomPainter {
  final double t; // 0..1
  final double pad;
  _WordVectorPainter({required this.t, required this.pad});

  @override
  void paint(Canvas canvas, Size size) {
    _wordPathCache ??= _parseSvgPath(_kWordPathD);
    final s = size.width / _kWordVBW;

    canvas.save();
    canvas.translate(0, pad);
    canvas.scale(s);

    final wordRect = Rect.fromLTWH(0, 0, _kWordVBW, _kWordVBH);

    // ظل ناعم تحت الكلمة
    canvas.drawPath(
      _wordPathCache!.shift(const Offset(0, 14)),
      Paint()
        ..color = _kDeepPink.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );

    // جسم الكلمة بتدرّج وردي
    canvas.drawPath(
      _wordPathCache!,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_kPink, Color(0xFFC2185B)],
        ).createShader(wordRect),
    );

    // ── القلوب الخمس مكان النقاط ──
    for (int i = 0; i < _kDots.length; i++) {
      final d = _kDots[i];
      final cx = d[0], cy = d[1], slideX = d[2], hopDir = d[3];

      // كل قلب يبدأ في طور مختلف حتى يلعبوا كأطفال لا كآلة واحدة
      final p = (t - i * 0.2) % 1.0;

      double slide = 0, lift = 0, sqx = 1, sqy = 1, rot = 0;

      if (p >= 0.50 && p < 0.55) {
        // انحناءة استعداد للقفز
        final u = (p - 0.50) / 0.05;
        lift = 6 * u * hopDir * -1;
        sqx = 1 + 0.14 * u;
        sqy = 1 - 0.14 * u;
      } else if (p >= 0.55 && p < 0.66) {
        // الإقلاع + بداية الانزلاق
        final u = Curves.easeOut.transform((p - 0.55) / 0.11);
        lift = 96 * u * hopDir;
        slide = slideX * u;
        sqx = 1.14 - 0.24 * u;
        sqy = 0.86 + 0.26 * u;
        rot = -0.16 * u;
      } else if (p >= 0.66 && p < 0.78) {
        // التزحلق على الحرف في الهواء
        final u = (p - 0.66) / 0.12;
        lift = 96 * hopDir;
        slide = slideX;
        sqx = 0.90 + 0.04 * u;
        sqy = 1.12 - 0.06 * u;
        rot = -0.16 + 0.28 * u;
      } else if (p >= 0.78 && p < 0.90) {
        // الرجوع والهبوط
        final u = Curves.easeIn.transform((p - 0.78) / 0.12);
        lift = 96 * (1 - u) * hopDir + 8 * u * hopDir * -1;
        slide = slideX * (1 - u);
        sqx = 0.94 + 0.24 * u;
        sqy = 1.06 - 0.24 * u;
        rot = 0.12 * (1 - u);
      } else if (p >= 0.90 && p < 1.0) {
        // ارتداد لطيف بعد الهبوط
        final u = Curves.easeOut.transform((p - 0.90) / 0.10);
        lift = 8 * (1 - u) * hopDir * -1;
        sqx = 1.18 - 0.18 * u;
        sqy = 0.82 + 0.18 * u;
      } else {
        // راحة مع رفرفة خفيفة حتى لا تبدو جامدة
        final idle = math.sin(p / 0.50 * math.pi * 2);
        lift = 7 * idle * hopDir;
        rot = 0.05 * idle;
      }

      canvas.save();
      canvas.translate(cx + slide, cy + lift);
      canvas.rotate(rot);
      canvas.scale(sqx, sqy);
      _drawGlossyHeart(
        canvas,
        Rect.fromCenter(
          center: Offset.zero,
          width: _kDotHeart,
          height: _kDotHeart,
        ),
      );
      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_WordVectorPainter old) => old.t != t;
}

/// يرسم قلباً زجاجياً لامعاً داخل المستطيل المعطى (نفس هوية الشعار).
void _drawGlossyHeart(Canvas canvas, Rect rect) {
  final path = _HeartsPainter._heartPath(rect);
  final w = rect.width, h = rect.height;

  canvas.drawPath(
    path.shift(Offset(0, h * 0.06)),
    Paint()
      ..color = const Color(0xFF9E0B3F).withValues(alpha: 0.20)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.08),
  );

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
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(rect.center.dx, rect.top + h * 0.86),
      width: w * 0.62,
      height: h * 0.26,
    ),
    Paint()
      ..color = const Color(0xFFFF6FA8).withValues(alpha: 0.50)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.12),
  );
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(rect.left + w * 0.29, rect.top + h * 0.24),
      width: w * 0.34,
      height: h * 0.20,
    ),
    Paint()
      ..color = Colors.white.withValues(alpha: 0.60)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.055),
  );
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(rect.left + w * 0.235, rect.top + h * 0.205),
      width: w * 0.11,
      height: h * 0.07,
    ),
    Paint()..color = Colors.white.withValues(alpha: 0.95),
  );
  canvas.restore();

  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03
      ..color = Colors.white.withValues(alpha: 0.48),
  );
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
