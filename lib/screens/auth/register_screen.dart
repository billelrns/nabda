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
import '../onboarding_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptTerms = false;

  late AnimationController _bgController;
  late AnimationController _formController;
  late Animation<double> _logoScale;
  late Animation<Offset> _titleSlide;
  late Animation<double> _formFade;
  late Animation<Offset> _nameSlide;
  late Animation<Offset> _emailSlide;
  late Animation<Offset> _passSlide;
  late Animation<Offset> _confirmSlide;
  late Animation<double> _buttonScale;

  // Password strength
  int _passwordStrength = 0;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController()..addListener(_calcPasswordStrength);
    _confirmPasswordController = TextEditingController();
    _checkOnboarding();

    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();

    _formController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _formController, curve: const Interval(0.0, 0.25, curve: Curves.elasticOut)),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _formController, curve: const Interval(0.1, 0.35, curve: Curves.easeOutCubic)),
    );
    _formFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _formController, curve: const Interval(0.2, 0.4, curve: Curves.easeIn)),
    );
    _nameSlide = Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _formController, curve: const Interval(0.25, 0.45, curve: Curves.easeOutCubic)),
    );
    _emailSlide = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _formController, curve: const Interval(0.3, 0.5, curve: Curves.easeOutCubic)),
    );
    _passSlide = Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _formController, curve: const Interval(0.35, 0.55, curve: Curves.easeOutCubic)),
    );
    _confirmSlide = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _formController, curve: const Interval(0.4, 0.6, curve: Curves.easeOutCubic)),
    );
    _buttonScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _formController, curve: const Interval(0.6, 0.85, curve: Curves.elasticOut)),
    );

    _formController.forward();
  }

  void _calcPasswordStrength() {
    final p = _passwordController.text;
    int s = 0;
    if (p.length >= 6) s++;
    if (p.length >= 10) s++;
    if (RegExp(r'[A-Z]').hasMatch(p)) s++;
    if (RegExp(r'[0-9]').hasMatch(p)) s++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(p)) s++;
    setState(() => _passwordStrength = s.clamp(0, 5));
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool('onboarding_done') ?? false;
    if (!done && mounted) context.go('/onboarding');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                    'displayName': _nameController.text.trim(),
                    'email': _emailController.text.trim(),
                    'lifeStage': prefs.getString('life_stage') ?? 'cycle',
                    'onboardingDone': true,
                    'createdAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  };
                  final pregStart = prefs.getString('pregnancy_start');
                  if (pregStart != null) data['pregnancyStartDate'] = Timestamp.fromDate(DateTime.parse(pregStart));
                  await FirebaseFirestore.instance.collection('users').doc(user.uid).set(data, SetOptions(merge: true));
                }
              } catch (_) {}
              if (!context.mounted) return;
              context.go('/home');
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red.shade400, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              );
            }
          },
          child: Stack(
            children: [
              // Animated background
              AnimatedBuilder(
                animation: _bgController,
                builder: (context, _) => CustomPaint(
                  painter: _RegisterBgPainter(_bgController.value),
                  size: Size.infinite,
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      // Back button
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => context.go('/login'),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2D2D3A), size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Logo
                      ScaleTransition(
                        scale: _logoScale,
                        child: Container(
                          width: 90, height: 90,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00897B), Color(0xFF4DB6AC)],
                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [BoxShadow(color: const Color(0xFF00897B).withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
                          ),
                          child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 44),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Title
                      SlideTransition(
                        position: _titleSlide,
                        child: Column(
                          children: [
                            const Text('انضمي إلينا', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2D2D3A))),
                            const SizedBox(height: 8),
                            Text('أنشئي حسابك واستمتعي بخدماتنا', style: TextStyle(fontSize: 15, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Form card
                      FadeTransition(
                        opacity: _formFade,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 30, offset: const Offset(0, 10))],
                          ),
                          child: Column(
                            children: [
                              SlideTransition(position: _nameSlide, child: _buildField(_nameController, 'الاسم الكامل', 'فاطمة محمد', Icons.person_rounded)),
                              const SizedBox(height: 16),
                              SlideTransition(position: _emailSlide, child: _buildField(_emailController, 'البريد الإلكتروني', 'example@gmail.com', Icons.email_rounded, keyboardType: TextInputType.emailAddress)),
                              const SizedBox(height: 16),
                              SlideTransition(
                                position: _passSlide,
                                child: Column(
                                  children: [
                                    _buildField(_passwordController, 'كلمة المرور', '••••••••', Icons.lock_rounded, isPassword: true, useObscure1: true),
                                    if (_passwordController.text.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      _buildPasswordStrengthBar(),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              SlideTransition(position: _confirmSlide, child: _buildField(_confirmPasswordController, 'تأكيد كلمة المرور', '••••••••', Icons.lock_outline_rounded, isPassword: true, useObscure1: false)),
                              const SizedBox(height: 16),
                              // Terms
                              _buildTermsRow(),
                              const SizedBox(height: 20),
                              // Register button
                              ScaleTransition(
                                scale: _buttonScale,
                                child: BlocBuilder<AuthBloc, AuthState>(
                                  builder: (context, state) {
                                    final isLoading = state is AuthLoading;
                                    return SizedBox(
                                      width: double.infinity, height: 56,
                                      child: ElevatedButton(
                                        onPressed: (isLoading || !_acceptTerms) ? null : () {
                                          context.read<AuthBloc>().add(AuthRegisterRequested(
                                            name: _nameController.text,
                                            email: _emailController.text,
                                            password: _passwordController.text,
                                            confirmPassword: _confirmPasswordController.text,
                                          ));
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF00897B),
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor: Colors.grey.shade300,
                                          elevation: 8,
                                          shadowColor: const Color(0xFF00897B).withOpacity(0.4),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                        ),
                                        child: isLoading
                                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)))
                                          : const Text('إنشاء حساب', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
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
                      FadeTransition(
                        opacity: _formFade,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('لديك حساب بالفعل؟ ', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                            GestureDetector(
                              onTap: () => context.go('/login'),
                              child: const Text('تسجيل الدخول', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00897B), fontSize: 14)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
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

  Widget _buildField(TextEditingController controller, String label, String hint, IconData icon, {TextInputType? keyboardType, bool isPassword = false, bool useObscure1 = true}) {
    final obscure = isPassword ? (useObscure1 ? _obscurePassword : _obscureConfirm) : false;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
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
              color: const Color(0xFF00897B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF00897B), size: 20),
          ),
          suffixIcon: isPassword ? IconButton(
            icon: Icon((useObscure1 ? _obscurePassword : _obscureConfirm) ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.grey.shade400),
            onPressed: () => setState(() {
              if (useObscure1) _obscurePassword = !_obscurePassword;
              else _obscureConfirm = !_obscureConfirm;
            }),
          ) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthBar() {
    final labels = ['', 'ضعيفة جداً', 'ضعيفة', 'متوسطة', 'جيدة', 'قوية'];
    final colors = [Colors.grey, Colors.red, Colors.orange, Colors.amber, Colors.lightGreen, Colors.green];
    return Row(
      children: [
        ...List.generate(5, (i) => Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(left: i < 4 ? 3 : 0),
            decoration: BoxDecoration(
              color: i < _passwordStrength ? colors[_passwordStrength] : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        )),
        const SizedBox(width: 8),
        Text(_passwordStrength > 0 ? labels[_passwordStrength] : '', style: TextStyle(fontSize: 11, color: colors[_passwordStrength])),
      ],
    );
  }

  Widget _buildTermsRow() {
    return GestureDetector(
      onTap: () => setState(() => _acceptTerms = !_acceptTerms),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: _acceptTerms ? const Color(0xFF00897B) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _acceptTerms ? const Color(0xFF00897B) : Colors.grey.shade400, width: 2),
            ),
            child: _acceptTerms ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              children: [
                Text('أوافق على ', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsOfServicePage())),
                  child: const Text('الشروط', style: TextStyle(fontSize: 13, color: Color(0xFF00897B), fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                ),
                Text(' و', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyPage())),
                  child: const Text('الخصوصية', style: TextStyle(fontSize: 13, color: Color(0xFF00897B), fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterBgPainter extends CustomPainter {
  final double animValue;
  _RegisterBgPainter(this.animValue);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..shader = const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFFE0F2F1), Color(0xFFF5FAFA), Colors.white],
        stops: [0.0, 0.4, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    final circles = [
      _BgCircle(0.15, 0.12, 70, const Color(0xFF00897B), 0.06),
      _BgCircle(0.88, 0.08, 50, const Color(0xFFE91E63), 0.05),
      _BgCircle(0.75, 0.88, 90, const Color(0xFF00897B), 0.04),
      _BgCircle(0.1, 0.8, 45, const Color(0xFF4DB6AC), 0.06),
      _BgCircle(0.5, 0.03, 35, const Color(0xFFE91E63), 0.04),
    ];

    for (final c in circles) {
      final dx = w * c.x + sin(animValue * 2 * pi + c.x * 10) * 18;
      final dy = h * c.y + cos(animValue * 2 * pi + c.y * 10) * 12;
      canvas.drawCircle(Offset(dx, dy), c.radius, Paint()..color = c.color.withOpacity(c.opacity));
    }

    // Wave
    final wavePaint = Paint()..color = const Color(0xFF00897B).withOpacity(0.03);
    final path = Path()..moveTo(0, h * 0.9);
    for (double x = 0; x <= w; x += 1) {
      path.lineTo(x, h * 0.9 + sin((x / w * 4 * pi) + animValue * 2 * pi) * 12);
    }
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();
    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _BgCircle {
  final double x, y, radius, opacity;
  final Color color;
  const _BgCircle(this.x, this.y, this.radius, this.color, this.opacity);
}
