// ═══════════════════════════════════════════════════════════════════
//  NABDA ADMIN WEB — نقطة دخول لوحة التحكم على الويب (admin.nabda.online)
//  تُعيد استخدام نفس كود الأدمن (AdminPanelScreen + AdminService) وقاعدة
//  Firebase نفسها. تتحكّم في كل نسخ التطبيق (Firebase = مصدر الحقيقة).
//  لا تُعرَض أي شاشة إدارة قبل تسجيل دخول طاقم نشط (isActive).
// ═══════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'config/theme.dart';
import 'services/admin_service.dart';
import 'screens/admin/admin_panel_screen.dart';

// ─── ألوان لوحة الأدمن (متوافقة مع AdminPanelScreen) ───
const Color _purple = Color(0xFF7E57C2);
const Color _bg = Color(0xFFF5F5F8);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // إصلاح خطأ Firestore الداخلي (ca9) على الويب: تعطيل التخزين المحلي.
  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
  } catch (_) {}

  runApp(const NabdaAdminWebApp());
}

class NabdaAdminWebApp extends StatelessWidget {
  const NabdaAdminWebApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'لوحة تحكم نبضة',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar', 'SA')],
      locale: const Locale('ar', 'SA'),
      // فرض RTL لكامل التطبيق (الأدمن عربي بالكامل).
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const _StaffGate(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  حارس الطاقم: يقرّر بين شاشة الدخول / لوحة الأدمن / رفض الوصول
// ═══════════════════════════════════════════════════════════════════
class _StaffGate extends StatelessWidget {
  const _StaffGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const _LoadingScaffold();
        }
        // غير مسجّل دخول → شاشة دخول الطاقم.
        if (!authSnap.hasData) {
          return const _StaffLoginScreen();
        }
        // مسجّل دخول → حدّد الدور قبل عرض أي شاشة إدارة.
        return FutureBuilder<bool>(
          future: _resolveStaffRole(),
          builder: (context, roleSnap) {
            if (roleSnap.connectionState != ConnectionState.done) {
              return const _LoadingScaffold();
            }
            if (roleSnap.data == true) {
              return const AdminPanelScreen();
            }
            // مسجّل دخول لكن ليس طاقمًا نشطًا → رفض الوصول.
            return const _AccessDeniedScreen();
          },
        );
      },
    );
  }

  /// يُهيّئ AdminService (يقرأ staff/{uid}.isActive) ويعيد ما إذا كان طاقمًا.
  Future<bool> _resolveStaffRole() async {
    await AdminService().initialize();
    return AdminService().isAdmin;
  }
}

// ═══════════════════════════════════════════════════════════════════
//  شاشة دخول الطاقم
// ═══════════════════════════════════════════════════════════════════
class _StaffLoginScreen extends StatefulWidget {
  const _StaffLoginScreen({Key? key}) : super(key: key);
  @override
  State<_StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends State<_StaffLoginScreen> {
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailC.dispose();
    _passC.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailC.text.trim();
    final pass = _passC.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'أدخل البريد وكلمة المرور');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: pass);
      // نجاح: authStateChanges سيُعيد بناء الحارس تلقائيًا.
    } catch (e) {
      final raw = e.toString();
      String msg;
      if (raw.contains('user-not-found')) {
        msg = 'لا يوجد حساب بهذا البريد';
      } else if (raw.contains('wrong-password') ||
          raw.contains('invalid-credential')) {
        msg = 'البريد أو كلمة المرور غير صحيحة';
      } else if (raw.contains('too-many-requests')) {
        msg = 'محاولات كثيرة، حاول لاحقًا';
      } else if (raw.contains('network')) {
        msg = 'تحقّق من اتصال الإنترنت';
      } else {
        msg = 'تعذّر تسجيل الدخول';
      }
      if (mounted) setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 8,
              shadowColor: _purple.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // شعار/أيقونة
                    Container(
                      width: 72,
                      height: 72,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.admin_panel_settings,
                          size: 40, color: _purple),
                    ),
                    const SizedBox(height: 20),
                    const Text('لوحة تحكم نبضة',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('دخول الطاقم المصرّح له فقط',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade600)),
                    const SizedBox(height: 28),

                    // البريد
                    TextField(
                      controller: _emailC,
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      enabled: !_loading,
                      decoration: InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        prefixIcon: const Icon(Icons.email_rounded,
                            color: _purple),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: _purple, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // كلمة المرور
                    TextField(
                      controller: _passC,
                      obscureText: _obscure,
                      textDirection: TextDirection.ltr,
                      enabled: !_loading,
                      onSubmitted: (_) => _signIn(),
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon:
                            const Icon(Icons.lock_rounded, color: _purple),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: _purple, width: 2)),
                      ),
                    ),

                    // رسالة الخطأ
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(children: [
                          Icon(Icons.error_outline,
                              size: 18, color: Colors.red.shade400),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_error!,
                                style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 13)),
                          ),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // زر الدخول
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _purple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.4, color: Colors.white))
                            : const Text('تسجيل الدخول',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  شاشة رفض الوصول (مسجّل دخول لكن ليس طاقمًا نشطًا)
// ═══════════════════════════════════════════════════════════════════
class _AccessDeniedScreen extends StatelessWidget {
  const _AccessDeniedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_person_rounded,
                    size: 64, color: Colors.red.shade300),
                const SizedBox(height: 20),
                const Text('لا تملك صلاحية الوصول',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('هذا الحساب ليس ضمن الطاقم المصرّح له بإدارة المنصّة.',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                const SizedBox(height: 28),
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('تسجيل الخروج'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _purple,
                      side: const BorderSide(color: _purple),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── شاشة تحميل بسيطة ───
class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _bg,
      body: Center(child: CircularProgressIndicator(color: _purple)),
    );
  }
}
