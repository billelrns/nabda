import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/nabda_animated_logo.dart';

/// ═══════════════════════════════════════════════════════════════════
///  شاشة البداية — الهوية الحركية لنبضة (2026)
///  قلب الأم ينبض (~60) وقلب الطفل بداخله ينبض أسرع (~140 مثل الجنين)،
///  قلوب صغيرة تلعب فوق كلمة «نبضة»، وقلوب شفافة تطفو في الخلفية.
/// ═══════════════════════════════════════════════════════════════════
class SplashScreen extends StatefulWidget {
  final VoidCallback? onDone;
  const SplashScreen({Key? key, this.onDone}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const _sub = Color(0xFF4A434B);

  late final AnimationController _entranceC;
  late final Animation<double> _entranceScale;
  late final Animation<double> _entranceFade;
  late final Animation<double> _taglineFade;
  late final Animation<Offset> _taglineSlide;

  late final AnimationController _floatC;

  @override
  void initState() {
    super.initState();

    _entranceC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _entranceScale = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceC,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _entranceFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceC,
        curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
      ),
    );
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceC,
        curve: const Interval(0.55, 1.0, curve: Curves.easeIn),
      ),
    );
    _taglineSlide =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entranceC,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
      ),
    );

    _floatC = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();

    _entranceC.forward();
    _runTimer();
  }

  Future<void> _runTimer() async {
    await Future.delayed(const Duration(milliseconds: 3200));
    if (!mounted) return;
    widget.onDone?.call();
  }

  @override
  void dispose() {
    _entranceC.dispose();
    _floatC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFEFF5), Color(0xFFFFF8FB), Color(0xFFFDEFF4)],
          ),
        ),
        child: Stack(
          children: [
            // قلوب شفافة تطفو للأعلى في الخلفية
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _floatC,
                builder: (context, _) => CustomPaint(
                  painter: _FloatingHeartsPainter(progress: _floatC.value),
                ),
              ),
            ),
            // المحتوى
            Center(
              child: FadeTransition(
                opacity: _entranceFade,
                child: ScaleTransition(
                  scale: _entranceScale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const NabdaAnimatedLogo(size: 220),
                      const SizedBox(height: 18),
                      FadeTransition(
                        opacity: _taglineFade,
                        child: SlideTransition(
                          position: _taglineSlide,
                          child: Text(
                            'رفيقتك في رحلة الأمومة',
                            style: GoogleFonts.almarai(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _sub,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// قلوب وردية شفافة تطفو ببطء نحو الأعلى — لمسة حية للخلفية.
class _FloatingHeartsPainter extends CustomPainter {
  final double progress; // 0..1 يتكرر

  _FloatingHeartsPainter({required this.progress});

  // بيانات ثابتة لكل قلب: (x نسبي، طور، حجم نسبي، شفافية)
  static const _hearts = [
    [0.12, 0.00, 0.045, 0.10],
    [0.85, 0.25, 0.060, 0.08],
    [0.28, 0.50, 0.035, 0.12],
    [0.68, 0.72, 0.050, 0.09],
    [0.45, 0.38, 0.028, 0.11],
    [0.92, 0.60, 0.038, 0.07],
    [0.05, 0.82, 0.055, 0.08],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final h in _hearts) {
      final t = (progress + h[1]) % 1.0;
      final x = h[0] * size.width +
          math.sin(t * math.pi * 3) * size.width * 0.03; // تمايل خفيف
      final y = size.height * (1.15 - t * 1.3); // من الأسفل للأعلى
      final s = h[2] * size.width;
      // تلاشي عند الأطراف
      final edgeFade =
          (t < 0.15 ? t / 0.15 : (t > 0.85 ? (1 - t) / 0.15 : 1.0));
      final rect = Rect.fromCenter(center: Offset(x, y), width: s, height: s);
      canvas.drawPath(
        _heartPath(rect),
        Paint()
          ..color = const Color(0xFFE0195B)
              .withValues(alpha: h[3] * edgeFade),
      );
    }
  }

  static Path _heartPath(Rect r) {
    final w = r.width, h = r.height;
    final x = r.left, y = r.top;
    final path = Path();
    path.moveTo(x + 0.50 * w, y + 0.32 * h);
    path.cubicTo(x + 0.36 * w, y + 0.06 * h, x + 0.04 * w, y + 0.12 * h,
        x + 0.04 * w, y + 0.38 * h);
    path.cubicTo(x + 0.04 * w, y + 0.60 * h, x + 0.28 * w, y + 0.74 * h,
        x + 0.50 * w, y + 0.92 * h);
    path.cubicTo(x + 0.72 * w, y + 0.74 * h, x + 0.96 * w, y + 0.60 * h,
        x + 0.96 * w, y + 0.38 * h);
    path.cubicTo(x + 0.96 * w, y + 0.12 * h, x + 0.64 * w, y + 0.06 * h,
        x + 0.50 * w, y + 0.32 * h);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_FloatingHeartsPainter old) => old.progress != progress;
}
