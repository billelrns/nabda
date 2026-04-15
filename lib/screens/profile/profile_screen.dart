import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

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
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
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
                style: TextStyle(color: Colors.grey[600]),
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
            bottom: BorderSide(color: Colors.grey[200]\!),
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
