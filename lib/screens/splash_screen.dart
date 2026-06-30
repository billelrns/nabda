import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════
///  شاشة البداية (موبايل) — صورة "نبضة" تنبض بإيقاع قلب حقيقي
///  مطابقة لنبضة الويب: نبضة قويّة → ارتداد → نبضة أخفّ → راحة قصيرة
/// ═══════════════════════════════════════════════════════════════════
class SplashScreen extends StatefulWidget {
  final VoidCallback? onDone;
  const SplashScreen({Key? key, this.onDone}) : super(key: key);
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  static const _bg = Color(0xFFFFF8FB);    // مطابق لخلفية الويب
  static const _rose = Color(0xFFE91E63);  // وردي العلامة (fallback)

  late final AnimationController _entranceC;
  late final Animation<double> _entranceScale;
  late final Animation<double> _entranceFade;

  late final AnimationController _heartC;
  late final Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();
    // حركة الدخول (مرّة واحدة)
    _entranceC = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _entranceScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _entranceC, curve: Curves.easeOutBack),
    );
    _entranceFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceC, curve: Curves.easeIn),
    );

    // إيقاع قلب حقيقي (متكرّر): نبضة قويّة → ارتداد → نبضة أخفّ → راحة
    _heartC = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.94, end: 1.10).chain(CurveTween(curve: Curves.easeOut)),
        weight: 14,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.10, end: 0.96).chain(CurveTween(curve: Curves.easeIn)),
        weight: 14,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.96, end: 1.06).chain(CurveTween(curve: Curves.easeOut)),
        weight: 14,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.06, end: 0.94).chain(CurveTween(curve: Curves.easeIn)),
        weight: 28,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(0.94), weight: 30),
    ]).animate(_heartC);

    _entranceC.forward();
    _runTimer();
  }

  Future<void> _runTimer() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;
    widget.onDone?.call();
  }

  @override
  void dispose() {
    _entranceC.dispose();
    _heartC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: FadeTransition(
          opacity: _entranceFade,
          child: ScaleTransition(
            scale: _entranceScale,
            child: ScaleTransition(
              scale: _heartScale,
              child: Image.asset(
                'assets/images/nabda_heart.png',
                width: 240,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  width: 150, height: 150,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                  child: const Center(child: Icon(Icons.favorite, size: 70, color: _rose)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
