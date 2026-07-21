import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/nabda_animated_logo.dart';

/// ═══════════════════════════════════════════════════════════════════
///  شاشات التعريف (أول تشغيل) — تصميم 2026
///  3 شرائح بصور حقيقية متحركة (Ken Burns) + الشعار النابض:
///  ترحيب → رحلة الأمومة → الخصوصية. تنتهي بـ «ابدئي رحلتك».
/// ═══════════════════════════════════════════════════════════════════
class IntroScreen extends StatefulWidget {
  final VoidCallback? onDone;
  const IntroScreen({Key? key, this.onDone}) : super(key: key);

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

// ── لوحة الألوان ──
const _bg = Color(0xFFFFF8FB);
const _rose = Color(0xFFE0195B);
const _pink = Color(0xFFF0347C);
const _blush = Color(0xFFFAD7E5);
const _peach = Color(0xFFF8B8A5);
const _lav = Color(0xFFCBB8FF);
const _green = Color(0xFF8BCF7B);
const _ink = Color(0xFF1F1A20);
const _muted = Color(0xFF4A434B);

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin {
  final _pc = PageController();
  int _i = 0;

  late final AnimationController _btnC;

  @override
  void initState() {
    super.initState();
    _btnC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('intro_seen', true);
    if (!mounted) return;
    widget.onDone?.call();
  }

  void _next() {
    if (_i < 2) {
      _pc.nextPage(
          duration: const Duration(milliseconds: 380), curve: Curves.easeOut);
    } else {
      _finish();
    }
  }

  @override
  void dispose() {
    _pc.dispose();
    _btnC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(
          children: [
            const Positioned(
                top: -90, right: -70, child: _Blob(size: 240, color: _blush)),
            const Positioned(
                bottom: 120,
                left: -80,
                child: _Blob(size: 220, color: Color(0xFFE0F2F1))),
            SafeArea(
              child: Column(
                children: [
                  // تخطّي
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12, top: 6),
                      child: _i < 2
                          ? TextButton(
                              onPressed: _finish,
                              child: Text('تخطّي',
                                  style: GoogleFonts.almarai(
                                      color: _muted,
                                      fontWeight: FontWeight.w700)),
                            )
                          : const SizedBox(height: 48),
                    ),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pc,
                      onPageChanged: (v) => setState(() => _i = v),
                      children: [
                        _WelcomeSlide(active: _i == 0),
                        _JourneySlide(active: _i == 1),
                        _PrivacySlide(active: _i == 2),
                      ],
                    ),
                  ),
                  // مؤشر الصفحات
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (k) => AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        width: k == _i ? 26 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          gradient: k == _i
                              ? const LinearGradient(colors: [_pink, _rose])
                              : null,
                          color: k == _i ? null : _blush,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // زر المتابعة
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                    child: AnimatedBuilder(
                      animation: _btnC,
                      builder: (context, child) {
                        final pulse =
                            _i == 2 ? 1.0 + 0.02 * _btnC.value : 1.0;
                        return Transform.scale(scale: pulse, child: child);
                      },
                      child: GestureDetector(
                        onTap: _next,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient:
                                const LinearGradient(colors: [_pink, _rose]),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: _rose.withValues(alpha: 0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_i == 2) ...[
                                  const Icon(Icons.favorite,
                                      color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  _i < 2 ? 'التالي' : 'ابدئي رحلتك',
                                  style: GoogleFonts.almarai(
                                    color: Colors.white,
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─── فقاعة خلفية ناعمة ───
class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.55),
            color.withValues(alpha: 0.0)
          ],
        ),
      ),
    );
  }
}

/// ─── صورة متحركة بأسلوب Ken Burns (زوم وانزياح بطيء مستمر) ───
class _KenBurnsImage extends StatefulWidget {
  final String asset;
  final Alignment focal; // اتجاه الانزياح البطيء
  const _KenBurnsImage({required this.asset, this.focal = Alignment.topCenter});

  @override
  State<_KenBurnsImage> createState() => _KenBurnsImageState();
}

class _KenBurnsImageState extends State<_KenBurnsImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(_c.value);
          return Transform.scale(
            scale: 1.06 + 0.10 * t,
            alignment: widget.focal,
            child: child,
          );
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              widget.asset,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_blush, Color(0xFFE0F2F1)],
                  ),
                ),
                child: const Center(
                    child: Icon(Icons.favorite, size: 64, color: _rose)),
              ),
            ),
            // تدرّج سفلي ناعم يدمج الصورة مع الخلفية
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.62, 1.0],
                    colors: [
                      Colors.transparent,
                      _bg.withValues(alpha: 0.85),
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

/// ─── دخول متدرّج ───
class _StaggerIn extends StatefulWidget {
  final Widget child;
  final bool active;
  final int delayMs;
  const _StaggerIn(
      {required this.child, required this.active, this.delayMs = 0});

  @override
  State<_StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<_StaggerIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 520));
    _maybeStart();
  }

  @override
  void didUpdateWidget(_StaggerIn old) {
    super.didUpdateWidget(old);
    _maybeStart();
  }

  void _maybeStart() {
    if (widget.active && !_started) {
      _started = true;
      Future.delayed(Duration(milliseconds: widget.delayMs), () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final v = Curves.easeOutCubic.transform(_c.value);
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 26 * (1 - v)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// ══ الشريحة 1: الترحيب — صورة أم حامل + شارة القلبين النابضين ══
class _WelcomeSlide extends StatelessWidget {
  final bool active;
  const _WelcomeSlide({required this.active});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Expanded(
            flex: 12,
            child: _StaggerIn(
              active: active,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Positioned.fill(
                    child: _KenBurnsImage(
                      asset: 'assets/images/intro/intro_welcome.png',
                      focal: Alignment.topCenter,
                    ),
                  ),
                  // شارة القلبين النابضين
                  Positioned(
                    bottom: -26,
                    right: 0,
                    left: 0,
                    child: Center(
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _rose.withValues(alpha: 0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(
                            child: NabdaBeatingHearts(size: 52)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 38),
          Expanded(
            flex: 7,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _StaggerIn(
                  active: active,
                  delayMs: 200,
                  child: Text(
                    'مرحباً بكِ في عالم نبضة',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.almarai(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: _ink),
                  ),
                ),
                const SizedBox(height: 6),
                _StaggerIn(
                  active: active,
                  delayMs: 320,
                  child: Text(
                    'كل نبضة حبٍّ، تهمّنا',
                    style: GoogleFonts.almarai(fontSize: 14, color: _rose),
                  ),
                ),
                const SizedBox(height: 12),
                _StaggerIn(
                  active: active,
                  delayMs: 450,
                  child: Text(
                    'دليلكِ الشخصي لصحة المرأة والأمومة — من الدورة والخصوبة إلى الحمل ورعاية طفلكِ، في مكان واحد أنيق وآمن.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.almarai(
                        fontSize: 14, color: _muted, height: 1.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ══ الشريحة 2: رحلة الأمومة — صورة أم ورضيعها + مراحل ══
class _JourneySlide extends StatelessWidget {
  final bool active;
  const _JourneySlide({required this.active});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Expanded(
            flex: 12,
            child: _StaggerIn(
              active: active,
              child: const _KenBurnsImage(
                asset: 'assets/images/intro/intro_journey.png',
                focal: Alignment.center,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            flex: 7,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _StaggerIn(
                  active: active,
                  delayMs: 150,
                  child: Text(
                    'دليلكِ في كل مرحلة',
                    style: GoogleFonts.almarai(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: _ink),
                  ),
                ),
                const SizedBox(height: 6),
                _StaggerIn(
                  active: active,
                  delayMs: 260,
                  child: Text(
                    'مهما كانت رحلتكِ، نبضة معكِ خطوة بخطوة',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.almarai(fontSize: 13.5, color: _muted),
                  ),
                ),
                const SizedBox(height: 14),
                _StaggerIn(
                  active: active,
                  delayMs: 380,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: const [
                      _StagePill(emoji: '🌙', text: 'تتبّع الدورة', color: _lav),
                      _StagePill(emoji: '🌱', text: 'الخصوبة', color: _green),
                      _StagePill(emoji: '🤰', text: 'متابعة الحمل', color: _rose),
                      _StagePill(emoji: '👶', text: 'رعاية المولود', color: _peach),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StagePill extends StatelessWidget {
  final String emoji;
  final String text;
  final Color color;
  const _StagePill(
      {required this.emoji, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(text,
              style: GoogleFonts.almarai(
                  fontSize: 13, fontWeight: FontWeight.w800, color: _ink)),
        ],
      ),
    );
  }
}

/// ══ الشريحة 3: الخصوصية — صورة اطمئنان + ضمانات ══
class _PrivacySlide extends StatelessWidget {
  final bool active;
  const _PrivacySlide({required this.active});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Expanded(
            flex: 12,
            child: _StaggerIn(
              active: active,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Positioned.fill(
                    child: _KenBurnsImage(
                      asset: 'assets/images/intro/intro_privacy.png',
                      focal: Alignment.center,
                    ),
                  ),
                  Positioned(
                    bottom: -22,
                    right: 0,
                    left: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: _rose.withValues(alpha: 0.2),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shield_rounded,
                                color: _rose, size: 18),
                            const SizedBox(width: 6),
                            Text('خصوصيتكِ محمية وآمنة',
                                style: GoogleFonts.almarai(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: _ink)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 34),
          Expanded(
            flex: 7,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _StaggerIn(
                  active: active,
                  delayMs: 200,
                  child: Text(
                    'أمانكِ أساس خدمتنا — بياناتكِ محفوظة وتحت تحكّمكِ الكامل.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.almarai(
                        fontSize: 14, color: _muted, height: 1.7),
                  ),
                ),
                const SizedBox(height: 12),
                _StaggerIn(
                    active: active,
                    delayMs: 320,
                    child: const _PrivacyRow(
                        icon: Icons.verified_user_rounded,
                        text: 'تحكّم كامل ببياناتكِ')),
                _StaggerIn(
                    active: active,
                    delayMs: 430,
                    child: const _PrivacyRow(
                        icon: Icons.visibility_off_rounded,
                        text: 'لا مشاركة مع أطراف ثالثة')),
                _StaggerIn(
                    active: active,
                    delayMs: 540,
                    child: const _PrivacyRow(
                        icon: Icons.lock_outline_rounded,
                        text: 'حماية وتشفير للبيانات')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _PrivacyRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _rose.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: _rose, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: GoogleFonts.almarai(
                    fontSize: 14, fontWeight: FontWeight.w700, color: _ink)),
          ),
          const Icon(Icons.check_circle, color: _green, size: 18),
        ],
      ),
    );
  }
}
