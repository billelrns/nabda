import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../services/admin_service.dart';
import '../onboarding_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _admin = AdminService();
  bool _adminLoaded = false;
  String? _photoUrl;
  String _displayName = '';
  String _email = '';
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _initAdmin();
    _loadUserData();
  }

  Future<void> _initAdmin() async {
    await _admin.initialize();
    if (mounted) setState(() => _adminLoaded = true);
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data() ?? {};
    if (mounted) {
      setState(() {
        _photoUrl = data['photoUrl'] as String?;
        _displayName = data['name'] as String? ?? user.displayName ?? '';
        _email = user.email ?? '';
      });
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              const Text('تغيير الصورة الشخصية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: const Color(0xFF00897B).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.camera_alt, color: Color(0xFF00897B)),
                ),
                title: const Text('التقاط صورة بالكاميرا'),
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
              ListTile(
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: const Color(0xFFFF4F93).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.photo_library, color: Color(0xFFFF4F93)),
                ),
                title: const Text('اختيار من المعرض'),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
              if (_photoUrl != null)
                ListTile(
                  leading: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  title: const Text('إزالة الصورة'),
                  onTap: () => Navigator.pop(ctx, 'remove'),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    if (source == 'remove') {
      await _removePhoto();
      return;
    }

    final imgSource = source == 'camera' ? ImageSource.camera : ImageSource.gallery;
    final picked = await picker.pickImage(source: imgSource, maxWidth: 512, maxHeight: 512, imageQuality: 80);
    if (picked == null) return;

    setState(() => _uploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final bytes = await picked.readAsBytes();

      String url;
      try {
        final ref = FirebaseStorage.instance.ref().child('profile_photos/${user.uid}.jpg');
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
        url = await ref.getDownloadURL();
      } catch (_) {
        // Fallback: base64 in Firestore
        final base64Str = base64Encode(bytes);
        url = 'data:image/jpeg;base64,$base64Str';
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {'photoUrl': url},
        SetOptions(merge: true),
      );

      if (mounted) setState(() {
        _photoUrl = url;
        _uploading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل رفع الصورة: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _removePhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseStorage.instance.ref().child('profile_photos/${user.uid}.jpg').delete();
    } catch (_) {}
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      {'photoUrl': FieldValue.delete()},
      SetOptions(merge: true),
    );
    if (mounted) setState(() => _photoUrl = null);
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFFF4F93).withOpacity(0.08),
                    const Color(0xFF00897B).withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  // ── Profile Photo with upload ──
                  GestureDetector(
                    onTap: _pickAndUploadPhoto,
                    child: Stack(
                      children: [
                        Container(
                          width: 110, height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFF4F93), Color(0xFF9B6FE1)],
                            ),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFFFF4F93).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
                            ],
                          ),
                          padding: const EdgeInsets.all(3),
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            padding: const EdgeInsets.all(3),
                            child: _uploading
                                ? const CircleAvatar(
                                    radius: 48,
                                    backgroundColor: Color(0xFFF5F5F5),
                                    child: SizedBox(width: 30, height: 30, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00897B))),
                                  )
                                : _photoUrl != null
                                    ? CircleAvatar(
                                        radius: 48,
                                        backgroundImage: _photoUrl!.startsWith('data:')
                                            ? MemoryImage(base64Decode(_photoUrl!.split(',').last))
                                            : NetworkImage(_photoUrl!) as ImageProvider,
                                        backgroundColor: const Color(0xFFF5F5F5),
                                      )
                                    : const CircleAvatar(
                                        radius: 48,
                                        backgroundColor: Color(0xFFF5F5F5),
                                        child: Icon(Icons.person, size: 50, color: Color(0xFF00897B)),
                                      ),
                          ),
                        ),
                        // Camera badge
                        Positioned(
                          bottom: 2, right: 2,
                          child: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(colors: [Color(0xFF00897B), Color(0xFF15B8A6)]),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(color: const Color(0xFF00897B).withOpacity(0.4), blurRadius: 6),
                              ],
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _displayName.isNotEmpty ? _displayName : 'مستخدمة نبضة',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B1320),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _email,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
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
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TermsOfServicePage()),
              ),
            ),
            _buildSettingItem(
              icon: Icons.policy,
              title: 'سياسة الخصوصية',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () async {
                final nav = GoRouter.of(context);
                final bloc = context.read<AuthBloc>();
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('onboarding_done');
                await prefs.remove('life_stage');
                await prefs.remove('user_name');
                await prefs.remove('pregnancy_start');
                bloc.add(const AuthLogoutRequested());
                nav.go('/onboarding');
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
