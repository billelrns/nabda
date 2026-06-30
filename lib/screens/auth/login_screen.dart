import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _obscurePassword = true;

  late AnimationController _bgController;
  late AnimationController _formController;
  late Animation<double> _logoScale;
  late Animation<Offset> _titleSlide;
  late Animation<double> _formFade;
  late Animation<Offset> _emailSlide;
  late Animation<Offset> _passSlide;
  late Animation<double> _buttonScale;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _checkOnboarding();

    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();

    _formController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _formController, curve: const Interval(0.0, 0.3, curve: Curves.elasticOut)),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _formController, curve: const Interval(0.15, 0.4, curve: Curves.easeOutCubic)),
    );
    _formFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _formController, curve: const Interval(0.25, 0.5, curve: Curves.easeIn)),
    );
    _emailSlide = Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _formController, curve: const Interval(0.35, 0.6, curve: Curves.easeOutCubic)),
    );
    _passSlide = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _formController, curve: const Interval(0.45, 0.7, curve: Curves.easeOutCubic)),
    );
    _buttonScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _formController, curve: const Interval(0.6, 0.85, curve: Curves.elasticOut)),
    );

    _formController.forward();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool('onboarding_done') ?? false;
    if (!done && mounted) context.go('/onboarding');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _bgController.dispose();
    _formController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) async {
            if (state is AuthAuthenticated) {
              try {
                final prefs = await SharedPreferences.getInstance();
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final data = <String, dynamic>{
                    'lifeStage': prefs.getString('life_stage') ?? 'cycle',
                    'onboardingDone': true,
                    'updatedAt': FieldValue.serverTimestamp(),
                  };
                  final name = prefs.getString('user_name');
                  if (name != null && name.isNotEmpty) data['displayName'] = name;
                  final pregStart = prefs.getString('pregnancy_start');
                  if (pregStart != null) data['pregnancyStartDate'] = Timestamp.fromDate(DateTime.parse(pregStart));
                  await FirebaseFirestore.instance.collection('users').doc(user.uid).set(data, SetOptions(merge: true));
                }
              } catch (_) {}
              if (!context.mounted) return;
              context.go('/home');
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red.shade400,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
          },
          child: Stack(
            children: [
              // Animated background
              AnimatedBuilder(
                animation: _bgController,
                builder: (context, _) => CustomPaint(
                  painter: _AuthBgPainter(_bgController.value),
                  size: Size.infinite,
                ),
              ),
              // Content
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const SizedBox(height: 60),
                      // Animated logo
                      ScaleTransition(
                        scale: _logoScale,
                        child: Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE91E63), Color(0xFFFF6090)],
                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFFE91E63).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
                            ],
                          ),
                          child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 50),
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Title
                      SlideTransition(
                        position: _titleSlide,
                        child: Column(
                          children: [
                            const Text('مرحباً بعودتك', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2D2D3A))),
                            const SizedBox(height: 8),
                            Text('سجلي الدخول لمتابعة صحتك', style: TextStyle(fontSize: 15, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Form card
                      FadeTransition(
                        opacity: _formFade,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 30, offset: const Offset(0, 10)),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Identifier field (phone or email)
                              SlideTransition(
                                position: _emailSlide,
                                child: _buildTextField(
                                  controller: _emailController,
                                  label: 'رقم الهاتف أو البريد الإلكتروني',
                                  hint: '0555… أو example@gmail.com',
                                  icon: Icons.alternate_email_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                              ),
                              const SizedBox(height: 18),
                              // Password field
                              SlideTransition(
                                position: _passSlide,
                                child: _buildTextField(
                                  controller: _passwordController,
                                  label: 'كلمة المرور',
                                  hint: '••••••••',
                                  icon: Icons.lock_rounded,
                                  isPassword: true,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: () => _showForgotPassword(),
                                  child: Text('هل نسيتِ كلمة المرور؟', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Login button
                              ScaleTransition(
                                scale: _buttonScale,
                                child: BlocBuilder<AuthBloc, AuthState>(
                                  builder: (context, state) {
                                    final isLoading = state is AuthLoading;
                                    return SizedBox(
                                      width: double.infinity,
                                      height: 56,
                                      child: ElevatedButton(
                                        onPressed: isLoading ? null : () {
                                          context.read<AuthBloc>().add(AuthLoginRequested(
                                            email: _emailController.text,
                                            password: _passwordController.text,
                                          ));
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFE91E63),
                                          foregroundColor: Colors.white,
                                          elevation: 8,
                                          shadowColor: const Color(0xFFE91E63).withOpacity(0.4),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                        ),
                                        child: isLoading
                                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)))
                                          : const Text('تسجيل الدخول', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Divider
                      FadeTransition(
                        opacity: _formFade,
                        child: Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey.shade300)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text('أو', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                            ),
                            Expanded(child: Divider(color: Colors.grey.shade300)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Register link
                      FadeTransition(
                        opacity: _formFade,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('ليس لديك حساب؟ ', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                            GestureDetector(
                              onTap: () => context.go('/register'),
                              child: const Text('إنشاء حساب', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE91E63), fontSize: 14)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword ? _obscurePassword : false,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: Colors.grey.shade500),
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE91E63).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFE91E63), size: 20),
          ),
          suffixIcon: isPassword ? IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.grey.shade400),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  void _showForgotPassword() {
    final resetController = TextEditingController();
    final authService = AuthService();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('استعادة كلمة المرور', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('أدخلي رقم هاتفك أو بريدك الإلكتروني', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
            const SizedBox(height: 24),
            TextField(
              controller: resetController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'الهاتف أو البريد',
                hintText: '0555… أو example@gmail.com',
                prefixIcon: const Icon(Icons.alternate_email_rounded, color: Color(0xFFE91E63)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE91E63), width: 2)),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF25D366).withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('للحسابات بالهاتف: نرسل طلبك للدعم عبر واتساب وستصلك كلمة مرور مؤقتة.', style: TextStyle(color: Colors.grey.shade700, fontSize: 12))),
              ]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final identifier = resetController.text.trim();
                  if (identifier.isEmpty) {
                    if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('أدخلي رقم هاتفك')));
                    return;
                  }
                  try {
                    // قراءة رقم دعم واتساب من Firestore، أو استعمال افتراضي
                    String supportNumber = '213555000000';
                    try {
                      final doc = await FirebaseFirestore.instance
                          .collection('app_config').doc('contact').get();
                      final n = (doc.data()?['whatsappNumber'] as String?)?.trim();
                      if (n != null && n.isNotEmpty) supportNumber = n;
                    } catch (_) {}
                    // تسجيل الطلب
                    try {
                      await FirebaseFirestore.instance
                          .collection('password_reset_requests').add({
                        'identifier': identifier,
                        'method': 'whatsapp',
                        'status': 'pending',
                        'requestedAt': FieldValue.serverTimestamp(),
                      });
                    } catch (_) {}
                    final msg = Uri.encodeComponent('السلام عليكم،\nأرغب في إعادة تعيين كلمة المرور لحسابي في تطبيق نبضة.\nرقمي/بريدي: $identifier\nشكراً.');
                    final url = 'https://wa.me/$supportNumber?text=$msg';
                    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    if (!ok && ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('تعذّر فتح واتساب')));
                    if (ok && ctx.mounted) Navigator.pop(ctx);
                  } catch (e) {
                    if (ctx.mounted) {
                      final err = e.toString().replaceFirst('Exception: ', '');
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(err)));
                    }
                  }
                },
                icon: const Icon(Icons.chat_rounded, color: Colors.white),
                label: const Text('أرسل الطلب عبر واتساب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity, height: 48,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final identifier = resetController.text.trim();
                  if (identifier.isEmpty || !AuthService.isEmail(identifier)) {
                    if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('هذا الخيار للبريد فقط')));
                    return;
                  }
                  try {
                    await authService.resetPassword(identifier);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('تم إرسال رابط الاستعادة إلى بريدك'), backgroundColor: const Color(0xFF00897B), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      );
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      final err = e.toString().replaceFirst('Exception: ', '');
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(err)));
                    }
                  }
                },
                icon: const Icon(Icons.mail_outline_rounded, color: Color(0xFFE91E63)),
                label: const Text('أرسل رابط للبريد', style: TextStyle(color: Color(0xFFE91E63), fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFE91E63)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Animated background painter
class _AuthBgPainter extends CustomPainter {
  final double animValue;
  _AuthBgPainter(this.animValue);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Main background gradient
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..shader = const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFFFFF0F3), Color(0xFFFFF5F7), Colors.white],
        stops: [0.0, 0.4, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Floating circles
    final circles = [
      _Circle(0.1, 0.15, 80, const Color(0xFFE91E63), 0.06),
      _Circle(0.85, 0.1, 60, const Color(0xFF00897B), 0.05),
      _Circle(0.7, 0.85, 100, const Color(0xFFE91E63), 0.04),
      _Circle(0.15, 0.75, 50, const Color(0xFFFF6090), 0.07),
      _Circle(0.5, 0.05, 40, const Color(0xFF00897B), 0.05),
    ];

    for (final c in circles) {
      final dx = w * c.x + sin(animValue * 2 * pi + c.phase) * 20;
      final dy = h * c.y + cos(animValue * 2 * pi + c.phase) * 15;
      canvas.drawCircle(Offset(dx, dy), c.radius, Paint()..color = c.color.withOpacity(c.opacity));
    }

    // Decorative wave at bottom
    final wavePaint = Paint()..color = const Color(0xFFE91E63).withOpacity(0.03);
    final wavePath = Path();
    wavePath.moveTo(0, h * 0.85);
    for (double x = 0; x <= w; x += 1) {
      final y = h * 0.85 + sin((x / w * 4 * pi) + animValue * 2 * pi) * 15;
      wavePath.lineTo(x, y);
    }
    wavePath.lineTo(w, h);
    wavePath.lineTo(0, h);
    wavePath.close();
    canvas.drawPath(wavePath, wavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _Circle {
  final double x, y, radius, opacity, phase;
  final Color color;
  const _Circle(this.x, this.y, this.radius, this.color, this.opacity, {this.phase = 0});
}
