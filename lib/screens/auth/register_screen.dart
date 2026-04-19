import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptTerms = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء حساب جديد'),
        elevation: 0,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.go('/home');
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Icon(
                Icons.favorite,
                size: 60,
                color: Color(0xFFE91E63),
              ),
              const SizedBox(height: 20),
              const Text(
                'انضمي إلينا',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'أنشئي حسابك الآن واستمتعي بخدماتنا',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'الاسم الكامل',
                  hintText: 'فاطمة محمد',
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  hintText: 'example@gmail.com',
                  prefixIcon: const Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'تأكيد كلمة المرور',
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirm = !_obscureConfirm;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              CheckboxListTile(
                value: _acceptTerms,
                onChanged: (value) {
                  setState(() {
                    _acceptTerms = value ?? false;
                  });
                },
                title: const Text('أوافق على الشروط والأحكام'),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 30),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final isLoading = state is AuthLoading;
                  return ElevatedButton(
                    onPressed: (isLoading || !_acceptTerms)
                        ? null
                        : () {
                            context.read<AuthBloc>().add(
                                  AuthRegisterRequested(
                                    name: _nameController.text,
                                    email: _emailController.text,
                                    password: _passwordController.text,
                                    confirmPassword:
                                        _confirmPasswordController.text,
                                  ),
                                );
                          },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text('إنشاء حساب'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('لديك حساب بالفعل؟ '),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text(
                      'تسجيل الدخول',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE91E63),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}






