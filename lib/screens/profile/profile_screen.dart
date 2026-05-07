import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../services/admin_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _admin = AdminService();
  bool _adminLoaded = false;

  @override
  void initState() {
    super.initState();
    _initAdmin();
  }

  Future<void> _initAdmin() async {
    await _admin.initialize();
    if (mounted) setState(() => _adminLoaded = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF00897B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    child: Icon(Icons.person, size: 50),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'فاطمة محمد',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'fatima@example.com',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            // ─── Admin Panel Button (only for staff) ───
            if (_adminLoaded && _admin.isAdmin) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => context.push('/admin'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AdminService.roleColor(_admin.currentRole),
                        AdminService.roleColor(_admin.currentRole).withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AdminService.roleColor(_admin.currentRole).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46, height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          AdminService.roleIcon(_admin.currentRole),
                          color: Colors.white, size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'لوحة التحكم',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'الدور: ${AdminService.roleNameAr(_admin.currentRole)}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.7), size: 18),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 30),
            const Text(
              'الإعدادات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            _buildSettingItem(
              icon: Icons.notifications,
              title: 'الإشعارات',
              onTap: () {},
            ),
            _buildSettingItem(
              icon: Icons.language,
              title: 'اللغة',
              onTap: () {},
            ),
            _buildSettingItem(
              icon: Icons.privacy_tip,
              title: 'الخصوصية',
              onTap: () {},
            ),
            _buildSettingItem(
              icon: Icons.security,
              title: 'الأمان',
              onTap: () {},
            ),
            const SizedBox(height: 30),
            const Text(
              'حول التطبيق',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            _buildSettingItem(
              icon: Icons.info,
              title: 'عن نبضة',
              onTap: () {},
            ),
            _buildSettingItem(
              icon: Icons.description,
              title: 'شروط الاستخدام',
              onTap: () {},
            ),
            _buildSettingItem(
              icon: Icons.policy,
              title: 'سياسة الخصوصية',
              onTap: () {},
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                context.read<AuthBloc>().add(const AuthLogoutRequested());
                context.go('/login');
              },
              icon: const Icon(Icons.logout),
              label: const Text('تسجيل الخروج'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'الإصدار 1.0.0',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF00897B)),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
