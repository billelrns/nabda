import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  /// يُستدعى بعد انتهاء حركة الشعار؛ الأب (RootGate) يقرّر الوجهة التالية.
  final VoidCallback? onDone;
  const SplashScreen({Key? key, this.onDone}) : super(key: key);
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  static const _rose = Color(0xFFF64D8A);
  static const _bg = Color(0xFFFCF7F7);

  late final AnimationController _c;     // entrance
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final AnimationController _pulseC; // heartbeat
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.elasticOut));
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeIn));
    _pulseC = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _pulseC, curve: Curves.easeInOut));
    _c.forward();
    _runTimer();
  }

  Future<void> _runTimer() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;
    widget.onDone?.call();
  }

  @override
  void dispose() {
    _c.dispose();
    _pulseC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: ScaleTransition(
                  scale: _pulse,
                  child: Image.asset(
                    'assets/images/logo_nabda.png',
                    width: 220,
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
            const SizedBox(height: 40),
            FadeTransition(
              opacity: _fade,
              child: const SizedBox(
                width: 26, height: 26,
                child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(_rose)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
