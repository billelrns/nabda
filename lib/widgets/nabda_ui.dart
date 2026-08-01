import 'dart:math' as math;

import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════
///  عناصر واجهة نبضة الموحدة (2026)
///  • NabdaPressable: أنيميشن ضغط ناعم لأي عنصر.
///  • GlossyIconBubble: فقاعة أيقونة زجاجية بلمعة اللوغو.
///  • NabdaPulse: نبض خفيف مستمر (للعناصر النشطة).
///  • NabdaBouncyIcon: حركة مرحة للأيقونات (طفو + قفزة عند اللمس).
/// ═══════════════════════════════════════════════════════════════════

/// ألوان العلامة الموحدة (مطابقة للوغو ثلاثي الأبعاد)
const kNabdaPink = Color(0xFFF0347C);
const kNabdaPinkDeep = Color(0xFFE0195B);

/// ─── أنيميشن ضغط: يتقلص العنصر بنعومة عند اللمس ───
class NabdaPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  const NabdaPressable({
    Key? key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.95,
  }) : super(key: key);

  @override
  State<NabdaPressable> createState() => _NabdaPressableState();
}

class _NabdaPressableState extends State<NabdaPressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// ─── فقاعة أيقونة زجاجية: تدرج + لمعة علوية + ظل ملون (لمعان اللوغو) ───
class GlossyIconBubble extends StatelessWidget {
  final List<Color> colors;
  final double size;
  final double radius;
  final Widget child;

  const GlossyIconBubble({
    Key? key,
    required this.colors,
    required this.child,
    this.size = 38,
    this.radius = 12,
  }) : super(key: key);

  /// فقاعة من لون واحد (يُشتق التدرج تلقائياً)
  factory GlossyIconBubble.tinted({
    Key? key,
    required Color base,
    required Widget child,
    double size = 38,
    double radius = 12,
  }) {
    return GlossyIconBubble(
      key: key,
      colors: [base, _darken(base, 0.18)],
      size: size,
      radius: radius,
      child: child,
    );
  }

  static Color _darken(Color c, double amount) =>
      Color.lerp(c, const Color(0xFF3A0A22), amount) ?? c;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // اللمعة الزجاجية العلوية (نفس لمعان اللوغو)
          Positioned(
            top: size * 0.06,
            left: size * 0.10,
            right: size * 0.10,
            height: size * 0.40,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius * 0.8),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.45),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Center(child: child),
        ],
      ),
    );
  }
}

/// ─── نبض خفيف مستمر بإيقاع قلب (للأيقونة النشطة في شريط التنقل) ───
class NabdaPulse extends StatefulWidget {
  final Widget child;
  final double amount;

  const NabdaPulse({Key? key, required this.child, this.amount = 0.10})
      : super(key: key);

  @override
  State<NabdaPulse> createState() => _NabdaPulseState();
}

class _NabdaPulseState extends State<NabdaPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _beat;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    _beat = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.0 + widget.amount)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 14,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0 + widget.amount, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 16,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.0 + widget.amount * 0.6)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0 + widget.amount * 0.6, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 18,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
    ]).animate(_c);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _beat, child: widget.child);
  }
}

/// ─── الجنين الطافي داخل الرحم: خلفية ثابتة + جنين يتحرك بنعومة ───
class WombFloatingFetus extends StatefulWidget {
  final String fetusAsset;
  final double size;

  const WombFloatingFetus({
    Key? key,
    required this.fetusAsset,
    this.size = 145,
  }) : super(key: key);

  @override
  State<WombFloatingFetus> createState() => _WombFloatingFetusState();
}

class _WombFloatingFetusState extends State<WombFloatingFetus>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // خلفية الرحم — ثابتة تماماً
            Image.asset(
              'assets/images/fetus_hd/womb_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [Color(0xFFFFE0EC), Color(0xFFF8BBD0)],
                  ),
                ),
              ),
            ),
            // الجنين — يطفو ويتمايل كأنه في سائل
            AnimatedBuilder(
              animation: _c,
              builder: (context, child) {
                final t = _c.value * 2 * 3.14159265;
                final floatY = _sin(t) * widget.size * 0.030;
                final floatX = _sin(t * 0.5) * widget.size * 0.012;
                final tilt = _sin(t * 0.7) * 0.05;
                final breathe = 1.0 + 0.015 * _sin(t * 1.3);
                return Transform.translate(
                  offset: Offset(floatX, floatY),
                  child: Transform.rotate(
                    angle: tilt,
                    child: Transform.scale(scale: breathe, child: child),
                  ),
                );
              },
              child: Padding(
                padding: EdgeInsets.all(widget.size * 0.10),
                child: Image.asset(
                  widget.fetusAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static double _sin(double x) {
    // تقريب دقيق كافٍ للحركة (بدون استيراد إضافي)
    return math.sin(x);
  }
}

/// ─── أيقونة مرحة: طفو وتمايل خفيف مستمر + قفزة مبهجة عند اللمس ───
/// تُستخدم لاحقاً مع أيقونات 3D (Image.asset) أو أي ويدجت.
class NabdaBouncyIcon extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  /// شدة الطفو المستمر (0 لإيقافه)
  final double idleAmount;

  /// تأخير بدء الطفو — امنحي كل أيقونة قيمة مختلفة لحركة غير متزامنة
  final int idleDelayMs;

  const NabdaBouncyIcon({
    Key? key,
    required this.child,
    this.onTap,
    this.idleAmount = 1.0,
    this.idleDelayMs = 0,
  }) : super(key: key);

  @override
  State<NabdaBouncyIcon> createState() => _NabdaBouncyIconState();
}

class _NabdaBouncyIconState extends State<NabdaBouncyIcon>
    with TickerProviderStateMixin {
  late final AnimationController _idleC;
  late final AnimationController _bounceC;
  late final Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _idleC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    Future.delayed(Duration(milliseconds: widget.idleDelayMs), () {
      if (mounted) _idleC.repeat();
    });

    _bounceC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    // قفزة مرحة: تمدد → سحق → استقرار (squash & stretch)
    _bounce = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.22)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 28,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.22, end: 0.92)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 26,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.92, end: 1.06)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 24,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.06, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 22,
      ),
    ]).animate(_bounceC);
  }

  @override
  void dispose() {
    _idleC.dispose();
    _bounceC.dispose();
    super.dispose();
  }

  void _play() {
    _bounceC.forward(from: 0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _play,
      child: AnimatedBuilder(
        animation: Listenable.merge([_idleC, _bounceC]),
        builder: (context, child) {
          final t = _idleC.value * 2 * math.pi;
          // طفو ناعم للأعلى والأسفل + ميلان لطيف كأنها حية
          final floatY = math.sin(t) * 1.6 * widget.idleAmount;
          final tilt = math.sin(t * 0.5) * 0.035 * widget.idleAmount;
          return Transform.translate(
            offset: Offset(0, floatY),
            child: Transform.rotate(
              angle: tilt,
              child: Transform.scale(
                scale: _bounce.value,
                child: child,
              ),
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
