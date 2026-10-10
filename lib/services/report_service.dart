import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportService {
  static final List<String> defaultReasons = [
    'محتوى مسيء',
    'معلومات طبية خاطئة',
    'إعلان أو احتيال',
    'انتحال شخصية',
    'أخرى',
  ];

  static Future<void> showReportDialog({
    required BuildContext context,
    required String targetType, // 'community_post', 'ai_response', 'comment', 'direct_chat'
    required String targetId,
    required String targetUserId,
    String? contentSnippet,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب تسجيل الدخول أولاً للإبلاغ')),
      );
      return;
    }

    String selectedReason = defaultReasons.first;
    final noteController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.report_problem_outlined, color: Colors.amber),
                SizedBox(width: 8),
                Text('إبلاغ عن محتوى', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('اختاري سبب الإبلاغ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  ...defaultReasons.map((r) => RadioListTile<String>(
                    title: Text(r, style: const TextStyle(fontSize: 13)),
                    value: r,
                    groupValue: selectedReason,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      if (val != null) setDlgState(() => selectedReason = val);
                    },
                  )),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'ملاحظة إضافية (اختياري)...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(10),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00897B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('إرسال البلاغ', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      try {
        final payload = <String, dynamic>{
          'reporterUid': user.uid,
          'targetType': targetType,
          'targetId': targetId,
          'targetUserId': targetUserId,
          'reason': selectedReason,
          'note': noteController.text.trim(),
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        };
        if (contentSnippet != null && contentSnippet.isNotEmpty) {
          payload['content'] = contentSnippet;
        }
        await FirebaseFirestore.instance.collection('reports').add(payload);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم استلام بلاغك، سيراجعه الفريق خلال 24 ساعة.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تعذر إرسال البلاغ: $e')),
          );
        }
      }
    }
  }

  static Future<void> blockUser(BuildContext context, String targetUserId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || targetUserId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حظر هذه المستخدمة'),
          content: const Text('هل أنتِ متأكدة من حظر هذه المستخدمة؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حظر', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('blocked')
            .doc(targetUserId)
            .set({'blockedAt': FieldValue.serverTimestamp()});

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حظر المستخدمة بنجاح')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تعذر الحظر: $e')),
          );
        }
      }
    }
  }
}
