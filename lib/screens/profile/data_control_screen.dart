import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/auth_service.dart';

class DataControlScreen extends StatefulWidget {
  const DataControlScreen({Key? key}) : super(key: key);

  @override
  State<DataControlScreen> createState() => _DataControlScreenState();
}

class _DataControlScreenState extends State<DataControlScreen> {
  bool _exporting = false;

  Future<void> _exportData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب تسجيل الدخول أولاً لتصدير البيانات')),
      );
      return;
    }

    setState(() => _exporting = true);

    try {
      final uid = user.uid;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};

      // Convert timestamp fields safely
      final cleanUserData = _sanitizeData(userData);

      // Collect data from key subcollections
      final subcollections = [
        'babies',
        'baby_logs',
        'cycle_logs',
        'weight_tracker',
        'vaccines',
        'favorites',
        'medications',
      ];

      final Map<String, dynamic> subcollectionsData = {};
      for (final sub in subcollections) {
        try {
          final snap = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection(sub)
              .get();
          subcollectionsData[sub] = snap.docs.map((d) => _sanitizeData(d.data())).toList();
        } catch (_) {}
      }

      final exportPayload = {
        'appName': 'نبضة - Nabda',
        'exportedAt': DateTime.now().toIso8601String(),
        'userId': uid,
        'profile': cleanUserData,
        'activity': subcollectionsData,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportPayload);

      await Share.share(
        jsonString,
        subject: 'نسخة احتياطية من بياناتي في تطبيق نبضة',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء تصدير البيانات: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Map<String, dynamic> _sanitizeData(Map<String, dynamic> input) {
    final Map<String, dynamic> result = {};
    input.forEach((key, value) {
      if (value is Timestamp) {
        result[key] = value.toDate().toIso8601String();
      } else if (value is Map<String, dynamic>) {
        result[key] = _sanitizeData(value);
      } else if (value is List) {
        result[key] = value.map((v) {
          if (v is Timestamp) return v.toDate().toIso8601String();
          if (v is Map<String, dynamic>) return _sanitizeData(v);
          return v;
        }).toList();
      } else {
        result[key] = value;
      }
    });
    return result;
  }

  Future<void> _clearAIChat() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مسح محادثات الذكاء الاصطناعي'),
        content: const Text('هل ترغبين في مسح سجل محادثاتكِ السابقة مع المساعد الذكي؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('مسح', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final docs = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('chat_history')
            .get();
        for (final doc in docs.docs) {
          await doc.reference.delete();
        }
      } catch (_) {}
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم مسح سجل محادثات المساعد الذكي بنجاح')),
      );
    }
  }

  Future<void> _clearSearchHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مسح سجل البحث'),
        content: const Text('هل ترغبين في مسح كلمات البحث السابقة المحفوظة على هذا الجهاز؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('مسح', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
    await prefs.remove('article_search_history');
    await prefs.remove('baby_name_searches');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم مسح سجل البحث المحفوظ')),
      );
    }
  }

  Future<void> _showDeleteAccountDialog() async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ حذف الحساب نهائياً'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text(
              'هذا الإجراء سيحذف كل بياناتك (الحمل، الدورة، الأطفال، الطلبات) '
              'ولا يمكن استرجاعها. اكتبي «حذف» للتأكيد.',
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                labelText: 'اكتبي «حذف» للتأكيد',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور الحالية',
                border: OutlineInputBorder(),
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (confirmController.text.trim() != 'حذف') {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('يجب كتابة كلمة «حذف» بالضبط')),
                );
                return;
              }
              if (passwordController.text.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('أدخلي كلمة المرور')),
                );
                return;
              }
              try {
                await AuthService().deleteAccount(recentPassword: passwordController.text);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  GoRouter.of(context).go('/onboarding');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حذف حسابك بنجاح')),
                  );
                }
              } catch (e) {
                final msg = e.toString().replaceFirst('Exception: ', '');
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(msg), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('حذف نهائياً', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8FB),
        appBar: AppBar(
          title: const Text('التحكم في بياناتي', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF00897B),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00897B).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security, color: Color(0xFF00897B), size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'نحن نحترم خصوصيتكِ ونمنحكِ التحكم الكامل في حفظ، تصدير، أو حذف بياناتكِ المسجلة لدينا في أي وقت.',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _card(
              title: 'تصدير نسخة من بياناتي',
              subtitle: 'حمّلي نسخة كاملة من سجلاتكِ ومعلوماتكِ بصيغة JSON',
              icon: Icons.file_download_outlined,
              color: Colors.blue.shade700,
              trailing: _exporting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : null,
              onTap: _exporting ? () {} : _exportData,
            ),
            const SizedBox(height: 12),

            _card(
              title: 'مسح سجل محادثات الذكاء الاصطناعي',
              subtitle: 'حذف الأسئلة والإجابات المخزنة من محادثات المساعد',
              icon: Icons.chat_bubble_outline,
              color: Colors.orange.shade700,
              onTap: _clearAIChat,
            ),
            const SizedBox(height: 12),

            _card(
              title: 'مسح سجل البحث المحلي',
              subtitle: 'حذف الكلمات والموضوعات التي تم البحث عنها على هذا الجهاز',
              icon: Icons.search_off_outlined,
              color: Colors.purple.shade700,
              onTap: _clearSearchHistory,
            ),
            const SizedBox(height: 28),

            const Divider(),
            const SizedBox(height: 12),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Text(
                'منطقة الخطر',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 13),
              ),
            ),

            Card(
              elevation: 0,
              color: Colors.red.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.red.shade200),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: Colors.red.shade100,
                  child: Icon(Icons.delete_forever, color: Colors.red.shade700),
                ),
                title: Text(
                  'حذف حسابي وبياناتي نهائياً',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900),
                ),
                subtitle: Text(
                  'حذف الحساب بشكل نهائي ولا يمكن استرجاعه بعد ذلك',
                  style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                ),
                onTap: _showDeleteAccountDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
