import 'package:flutter/material.dart';

import '../../services/partner_service.dart';

/// ═══════════════════════════════════════════════════════════════════
///  مركز التنبيهات المشترك — يعرض أحداث الطرف الآخر فقط
///  (إضافة للسلّة، تسجيل نشاط الطفل، إتمام طلب، تحديث قائمة…)
///
///  يعمل بلا خادم: Firestore هو القناة. عند إضافة Cloud Functions
///  لاحقاً سيكفي إرسال نسخة push لنفس الأحداث دون تغيير هذه الشاشة.
/// ═══════════════════════════════════════════════════════════════════
class PartnerNotificationsScreen extends StatelessWidget {
  final String coupleId;
  const PartnerNotificationsScreen({super.key, required this.coupleId});

  static const _ink = Color(0xFF1F1A20);
  static const _ink3 = Color(0xFF9B8F95);
  static const _bg = Color(0xFFF7FAFC);

  static (IconData, Color) _style(String type) => switch (type) {
        'cart_add' => (Icons.add_shopping_cart, const Color(0xFFD98324)),
        'order_placed' => (Icons.check_circle, const Color(0xFF00897B)),
        'baby_log' => (Icons.child_care, const Color(0xFF9B6FE1)),
        'list_update' => (Icons.checklist_rtl, const Color(0xFF2E6B8F)),
        _ => (Icons.favorite, const Color(0xFFE0195B)),
      };

  static String _ago(DateTime? t) {
    if (t == null) return '';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'الآن';
    if (d.inMinutes < 60) return 'قبل ${d.inMinutes} دقيقة';
    if (d.inHours < 24) return 'قبل ${d.inHours} ساعة';
    if (d.inDays < 7) return 'قبل ${d.inDays} يوم';
    return '${t.day}/${t.month}';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          foregroundColor: _ink,
          title: const Text('التنبيهات',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        ),
        body: StreamBuilder<List<PartnerNotification>>(
          stream: PartnerService.watchNotifications(coupleId),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2));
            }
            final list = snap.data ?? [];
            if (list.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(mainAxisSize: MainAxisSize.min, children: const [
                    Text('🔔', style: TextStyle(fontSize: 46)),
                    SizedBox(height: 16),
                    Text('لا توجد تنبيهات بعد',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _ink)),
                    SizedBox(height: 8),
                    Text(
                      'سيظهر هنا كل ما يفعله الطرف الآخر:\nإضافة للسلّة، تسجيل نشاط الطفل، إتمام طلب.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: _ink3, height: 1.8),
                    ),
                  ]),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
              itemCount: list.length,
              itemBuilder: (c, i) {
                final n = list[i];
                final (icon, color) = _style(n.type);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE6EDF2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(icon, size: 20, color: color),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n.title,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: _ink)),
                            const SizedBox(height: 4),
                            Text(n.body,
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    color: _ink3,
                                    height: 1.5)),
                            const SizedBox(height: 6),
                            Text(_ago(n.createdAt),
                                style: const TextStyle(
                                    fontSize: 10.5, color: _ink3)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
