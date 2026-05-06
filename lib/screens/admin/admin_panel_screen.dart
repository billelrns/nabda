import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/admin_service.dart';
import '../../services/notification_service.dart';

// ─── Theme ───
const Color _bg = Color(0xFFF5F5F8);
const Color _card = Colors.white;
const Color _teal = Color(0xFF00897B);
const Color _pink = Color(0xFFE91E63);
const Color _text1 = Color(0xFF2D2D3A);
const Color _text2 = Color(0xFF6B7280);
const Color _purple = Color(0xFF7E57C2);

// ═══════════════════════════════════════════════
//  ADMIN PANEL MAIN SCREEN
// ═══════════════════════════════════════════════
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);
  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _admin = AdminService();

  @override
  Widget build(BuildContext context) {
    final role = _admin.currentRole;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          centerTitle: true,
          title: const Text('لوحة التحكم', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
          backgroundColor: _purple,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            Container(
              margin: const EdgeInsets.only(left: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(AdminService.roleIcon(role), size: 16, color: Colors.white),
                const SizedBox(width: 4),
                Text(AdminService.roleNameAr(role), style: const TextStyle(color: Colors.white, fontSize: 12)),
              ]),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Stats cards row (owner & supervisor)
            if (_admin.hasPermission(Permission.viewDashboard)) ...[
              _buildStatsRow(),
              const SizedBox(height: 20),
            ],

            // Admin modules grid
            const Text('الوحدات الإدارية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _text1)),
            const SizedBox(height: 12),

            // Dashboard
            if (_admin.hasPermission(Permission.viewDashboard))
              _ModuleCard(
                title: 'لوحة الإحصائيات',
                subtitle: 'مستخدمات، طلبات، إيرادات',
                emoji: '📊',
                color: const Color(0xFF5C6BC0),
                onTap: () => _push(_DashboardScreen()),
              ),

            // Orders
            if (_admin.hasPermission(Permission.manageOrders))
              _ModuleCard(
                title: 'إدارة الطلبات',
                subtitle: 'عرض وتحديث حالة الطلبات',
                emoji: '📦',
                color: const Color(0xFFFF7043),
                onTap: () => _push(_OrdersManagementScreen()),
              ),

            // Products
            if (_admin.hasPermission(Permission.addProducts) || _admin.hasPermission(Permission.manageProducts))
              _ModuleCard(
                title: 'إدارة المنتجات',
                subtitle: _admin.hasPermission(Permission.deleteProducts) ? 'إضافة، تعديل، حذف' : 'إضافة وتعديل فقط',
                emoji: '🛍️',
                color: const Color(0xFF26A69A),
                onTap: () => _push(_ProductsManagementScreen()),
              ),

            // Articles
            if (_admin.hasPermission(Permission.addArticles) || _admin.hasPermission(Permission.manageArticles))
              _ModuleCard(
                title: 'إدارة المقالات',
                subtitle: _admin.hasPermission(Permission.deleteArticles) ? 'نشر، تعديل، حذف' : 'إضافة وتعديل فقط',
                emoji: '📝',
                color: const Color(0xFF42A5F5),
                onTap: () => _push(_ArticlesManagementScreen()),
              ),

            // Users
            if (_admin.hasPermission(Permission.viewUsers))
              _ModuleCard(
                title: 'إدارة المستخدمات',
                subtitle: _admin.hasPermission(Permission.banUsers) ? 'عرض، حظر، إشعارات' : 'عرض فقط',
                emoji: '👥',
                color: const Color(0xFFEF5350),
                onTap: () => _push(_UsersManagementScreen()),
              ),

            // Coupons
            if (_admin.hasPermission(Permission.manageCoupons))
              _ModuleCard(
                title: 'الكوبونات والعروض',
                subtitle: 'خصومات وعروض موسمية',
                emoji: '🎟️',
                color: const Color(0xFFFF9800),
                onTap: () => _push(_CouponsManagementScreen()),
              ),

            // Staff (Owner only)
            if (_admin.hasPermission(Permission.manageStaff))
              _ModuleCard(
                title: 'إدارة الموظفين',
                subtitle: 'إضافة موظفين وتحديد الصلاحيات',
                emoji: '👔',
                color: _purple,
                onTap: () => _push(_StaffManagementScreen()),
              ),

            // Delivery Pricing
            if (_admin.hasPermission(Permission.manageProducts))
              _ModuleCard(
                title: 'أسعار التوصيل',
                subtitle: 'تحديد أسعار التوصيل لكل منطقة',
                emoji: '🚚',
                color: const Color(0xFF66BB6A),
                onTap: () => _push(_DeliveryPricingScreen()),
              ),

            // Notifications
            if (_admin.hasPermission(Permission.sendNotifications))
              _ModuleCard(
                title: 'الإشعارات الجماعية',
                subtitle: 'إرسال رسائل لكل المستخدمات',
                emoji: '🔔',
                color: const Color(0xFF8D6E63),
                onTap: () => _push(_NotificationsScreen()),
              ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _push(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  Widget _buildStatsRow() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, usersSnap) {
        final userCount = usersSnap.data?.docs.length ?? 0;
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('orders').snapshots(),
          builder: (context, ordersSnap) {
            final orderCount = ordersSnap.data?.docs.length ?? 0;
            return Row(
              children: [
                _StatCard(label: 'المستخدمات', value: '$userCount', icon: Icons.people, color: const Color(0xFF42A5F5)),
                const SizedBox(width: 10),
                _StatCard(label: 'الطلبات', value: '$orderCount', icon: Icons.shopping_bag, color: const Color(0xFFFF7043)),
                const SizedBox(width: 10),
                _StatCard(label: 'المنتجات', value: '300+', icon: Icons.inventory, color: const Color(0xFF26A69A)),
              ],
            );
          },
        );
      },
    );
  }
}

// ─── Stat Card ───
class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: _text2)),
          ],
        ),
      ),
    );
  }
}

// ─── Module Card ───
class _ModuleCard extends StatelessWidget {
  final String title, subtitle, emoji;
  final Color color;
  final VoidCallback onTap;
  const _ModuleCard({required this.title, required this.subtitle, required this.emoji, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))]),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _text1)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 12, color: _text2)),
            ])),
            Icon(Icons.arrow_back_ios, size: 16, color: _text2),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  1. DASHBOARD - STATISTICS
// ═══════════════════════════════════════════════
class _DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(centerTitle: true, title: const Text('📊 لوحة الإحصائيات', style: TextStyle(fontWeight: FontWeight.bold, color: _text1)),
        backgroundColor: _card, foregroundColor: _teal, elevation: 0, surfaceTintColor: Colors.transparent),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Users count
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (_, snap) {
            final count = snap.data?.docs.length ?? 0;
            return _DashCard(title: 'إجمالي المستخدمات', value: '$count', icon: Icons.people, color: const Color(0xFF42A5F5));
          },
        ),
        const SizedBox(height: 10),
        // Orders count
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('orders').snapshots(),
          builder: (_, snap) {
            final count = snap.data?.docs.length ?? 0;
            final pending = snap.data?.docs.where((d) => (d.data() as Map)['status'] == 'pending').length ?? 0;
            return _DashCard(title: 'الطلبات', value: '$count', subtitle: '$pending طلب في الانتظار', icon: Icons.shopping_bag, color: const Color(0xFFFF7043));
          },
        ),
        const SizedBox(height: 10),
        // Staff count
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('staff').snapshots(),
          builder: (_, snap) {
            final count = snap.data?.docs.length ?? 0;
            return _DashCard(title: 'فريق العمل', value: '$count', icon: Icons.badge, color: _purple);
          },
        ),
        const SizedBox(height: 10),
        // Articles
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('articles').snapshots(),
          builder: (_, snap) {
            final count = snap.data?.docs.length ?? 0;
            return _DashCard(title: 'المقالات المنشورة', value: '$count', icon: Icons.article, color: const Color(0xFF26A69A));
          },
        ),
        const SizedBox(height: 20),
        // Recent orders
        const Text('آخر الطلبات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _text1)),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).limit(10).snapshots(),
          builder: (_, snap) {
            if (!snap.hasData || snap.data!.docs.isEmpty) {
              return Center(child: Padding(padding: const EdgeInsets.all(30), child: Text('لا توجد طلبات بعد', style: TextStyle(color: _text2))));
            }
            return Column(children: snap.data!.docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  _statusBadge(d['status'] ?? 'pending'),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(d['productName'] ?? 'طلب', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _text1)),
                    Text(d['customerName'] ?? '', style: TextStyle(fontSize: 11, color: _text2)),
                  ])),
                  Text(d['total'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, color: _teal, fontSize: 13)),
                ]),
              );
            }).toList());
          },
        ),
      ]),
    ));
  }
}

class _DashCard extends StatelessWidget {
  final String title, value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  const _DashCard({required this.title, required this.value, this.subtitle, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
      child: Row(children: [
        Container(width: 50, height: 50, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: color, size: 26)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 13, color: _text2)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
          if (subtitle != null) Text(subtitle!, style: TextStyle(fontSize: 11, color: _text2)),
        ])),
      ]),
    );
  }
}

Widget _statusBadge(String status) {
  Color c; String t;
  switch (status) {
    case 'pending': c = Colors.orange; t = 'جديد'; break;
    case 'processing': c = Colors.blue; t = 'قيد التجهيز'; break;
    case 'shipped': c = Colors.purple; t = 'تم الشحن'; break;
    case 'delivered': c = Colors.green; t = 'مكتمل'; break;
    case 'cancelled': c = Colors.red; t = 'ملغي'; break;
    default: c = Colors.grey; t = status;
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
    child: Text(t, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: c)),
  );
}

// ═══════════════════════════════════════════════
//  2. ORDERS MANAGEMENT
// ═══════════════════════════════════════════════
class _OrdersManagementScreen extends StatelessWidget {
  final _statuses = const ['pending', 'processing', 'shipped', 'delivered', 'cancelled'];
  final _statusAr = const {'pending': 'جديد', 'processing': 'قيد التجهيز', 'shipped': 'تم الشحن', 'delivered': 'مكتمل', 'cancelled': 'ملغي'};

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(centerTitle: true, title: const Text('📦 إدارة الطلبات', style: TextStyle(fontWeight: FontWeight.bold, color: _text1)),
        backgroundColor: _card, foregroundColor: _teal, elevation: 0, surfaceTintColor: Colors.transparent),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('📦', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 16),
              Text('لا توجد طلبات بعد', style: TextStyle(fontSize: 16, color: _text2)),
            ]));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snap.data!.docs.length,
            itemBuilder: (_, i) {
              final doc = snap.data!.docs[i];
              final d = doc.data() as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    _statusBadge(d['status'] ?? 'pending'),
                    const Spacer(),
                    Text('#${doc.id.substring(0, 8)}', style: TextStyle(fontSize: 11, color: _text2)),
                  ]),
                  const SizedBox(height: 10),
                  Text(d['productName'] ?? 'منتج', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _text1)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.person, size: 14, color: _text2), const SizedBox(width: 4),
                    Text(d['customerName'] ?? '', style: TextStyle(fontSize: 12, color: _text2)),
                    const SizedBox(width: 16),
                    Icon(Icons.phone, size: 14, color: _text2), const SizedBox(width: 4),
                    Text(d['phone'] ?? '', style: TextStyle(fontSize: 12, color: _text2)),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Text(d['total'] ?? '', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _teal)),
                    const Spacer(),
                    // Status changer
                    PopupMenuButton<String>(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: _teal.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('تغيير الحالة', style: TextStyle(fontSize: 12, color: _teal, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down, size: 16, color: _teal),
                        ]),
                      ),
                      onSelected: (status) async {
                        await doc.reference.update({'status': status});
                        // Send notification to customer
                        final userId = d['userId'] as String?;
                        if (userId != null) {
                          await NotificationService().createOrderNotification(
                            userId: userId,
                            orderId: doc.id,
                            newStatus: status,
                            productName: d['productName'] ?? 'طلبك',
                          );
                        }
                      },
                      itemBuilder: (_) => _statuses.map((s) => PopupMenuItem(
                        value: s,
                        child: Text(_statusAr[s] ?? s),
                      )).toList(),
                    ),
                  ]),
                ]),
              );
            },
          );
        },
      ),
    ));
  }
}

// ═══════════════════════════════════════════════
//  3. PRODUCTS MANAGEMENT
// ═══════════════════════════════════════════════
class _ProductsManagementScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(centerTitle: true, title: const Text('🛍️ إدارة المنتجات', style: TextStyle(fontWeight: FontWeight.bold, color: _text1)),
        backgroundColor: _card, foregroundColor: _teal, elevation: 0, surfaceTintColor: Colors.transparent,
        actions: [
          if (AdminService().hasPermission(Permission.addProducts))
            IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => _AddProductScreen()));
            }),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('🛍️', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 16),
              Text('لا توجد منتجات في قاعدة البيانات', style: TextStyle(fontSize: 14, color: _text2)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _AddProductScreen())),
                icon: const Icon(Icons.add), label: const Text('إضافة منتج'),
                style: ElevatedButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.white),
              ),
            ]));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snap.data!.docs.length,
            itemBuilder: (_, i) {
              final doc = snap.data!.docs[i];
              final d = doc.data() as Map<String, dynamic>;
              final hasImage = d['imageUrl'] != null && (d['imageUrl'] as String).isNotEmpty;
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _AddProductScreen(docId: doc.id, existingData: d))),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    if (hasImage)
                      ClipRRect(borderRadius: BorderRadius.circular(12),
                        child: Image.network(d['imageUrl'], width: 50, height: 50, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(width: 50, height: 50, color: _teal.withOpacity(0.1),
                            child: Center(child: Text(d['emoji'] ?? '🛍️', style: const TextStyle(fontSize: 24))))))
                    else
                      Container(width: 50, height: 50, decoration: BoxDecoration(color: _teal.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: Center(child: Text(d['emoji'] ?? '🛍️', style: const TextStyle(fontSize: 24)))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(d['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: _text1), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(d['price'] ?? '', style: TextStyle(fontSize: 12, color: _teal, fontWeight: FontWeight.bold)),
                    ])),
                    IconButton(icon: const Icon(Icons.edit_outlined, color: _teal, size: 20),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _AddProductScreen(docId: doc.id, existingData: d)))),
                    if (AdminService().hasPermission(Permission.deleteProducts))
                      IconButton(icon: Icon(Icons.delete_outline, color: Colors.red.shade300, size: 20), onPressed: () => doc.reference.delete()),
                  ]),
                ),
              );
            },
          );
        },
      ),
    ));
  }
}

// ─── Add / Edit Product Screen (with images) ───
class _AddProductScreen extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? existingData;
  const _AddProductScreen({this.docId, this.existingData});
  @override
  State<_AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<_AddProductScreen> {
  final _nameC = TextEditingController();
  final _priceC = TextEditingController();
  final _oldPriceC = TextEditingController();
  final _descC = TextEditingController();
  final _emojiC = TextEditingController(text: '🛍️');
  String _category = 'ملابس الحمل';
  bool get _isEditing => widget.docId != null;

  // Multiple product images (gallery)
  final List<_ArticleImage> _productImages = [];

  // Description images
  final List<_ArticleImage> _descImages = [];

  bool _isSaving = false;
  final _picker = ImagePicker();

  final _categories = ['ملابس الحمل', 'لوازم الرضيع', 'ملابس المولود', 'الرضاعة والتغذية', 'الحفاضات والنظافة',
    'عناية بالحامل', 'فيتامينات ومكملات', 'حقيبة الولادة', 'ألعاب وتحفيز', 'راحة الأم',
    'كتب وأدلة', 'أجهزة طبية', 'تذكارات وهدايا', 'سفر وتنقل', 'ديكور غرفة الطفل'];

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      final d = widget.existingData!;
      _nameC.text = d['name'] ?? '';
      _priceC.text = d['price'] ?? '';
      _oldPriceC.text = d['oldPrice'] ?? '';
      _descC.text = d['description'] ?? '';
      _emojiC.text = d['emoji'] ?? '🛍️';
      _category = d['category'] ?? 'ملابس الحمل';
      if (!_categories.contains(_category)) _category = 'ملابس الحمل';
      // Load product images (support both old single imageUrl and new imageUrls list)
      final imageUrls = d['imageUrls'] as List<dynamic>? ?? [];
      if (imageUrls.isNotEmpty) {
        for (final url in imageUrls) {
          final s = url.toString();
          if (s.isNotEmpty) _productImages.add(_ArticleImage(url: s));
        }
      } else {
        // Backward compat: old single imageUrl
        final oldUrl = d['imageUrl'] as String?;
        if (oldUrl != null && oldUrl.isNotEmpty) _productImages.add(_ArticleImage(url: oldUrl));
      }
      // Load description images
      final descImgs = d['descImages'] as List<dynamic>? ?? [];
      for (final img in descImgs) _descImages.add(_ArticleImage(url: img.toString()));
    }
  }

  Future<XFile?> _pickImage() async {
    try {
      return await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
    } catch (e) { return null; }
  }

  Future<Uint8List?> _readFileBytes(XFile file) async {
    try { return await file.readAsBytes(); } catch (e) { return null; }
  }

  Future<String?> _uploadImage(XFile file, String path) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      final bytes = await file.readAsBytes();
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في رفع الصورة: $e'), backgroundColor: Colors.red, duration: const Duration(seconds: 5)));
      }
      return null;
    }
  }

  Future<void> _addProductImage() async {
    final f = await _pickImage();
    if (f != null) {
      final b = await _readFileBytes(f);
      if (b != null) setState(() => _productImages.add(_ArticleImage(file: f, bytes: b)));
    }
  }

  Future<void> _addDescImage() async {
    final f = await _pickImage();
    if (f != null) {
      final b = await _readFileBytes(f);
      if (b != null) setState(() => _descImages.add(_ArticleImage(file: f, bytes: b)));
    }
  }

  Future<void> _save() async {
    if (_nameC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إدخال اسم المنتج'), backgroundColor: Colors.orange));
      return;
    }
    if (_priceC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إدخال السعر'), backgroundColor: Colors.orange));
      return;
    }
    setState(() => _isSaving = true);
    debugPrint('=== SAVE PRODUCT START ===');
    try {
      final ts = DateTime.now().millisecondsSinceEpoch;

      // Upload product images
      final List<String> productImageUrls = [];
      for (int i = 0; i < _productImages.length; i++) {
        final img = _productImages[i];
        if (img.url != null) {
          productImageUrls.add(img.url!);
        } else if (img.file != null) {
          final url = await _uploadImage(img.file!, 'products/product_${ts}_$i.jpg');
          if (url != null) productImageUrls.add(url);
        }
      }

      // Upload description images
      final List<String> descImageUrls = [];
      for (int i = 0; i < _descImages.length; i++) {
        final img = _descImages[i];
        if (img.url != null) descImageUrls.add(img.url!);
        else if (img.file != null) {
          final url = await _uploadImage(img.file!, 'products/desc_${ts}_$i.jpg');
          if (url != null) descImageUrls.add(url);
        }
      }

      final data = <String, dynamic>{
        'name': _nameC.text.trim(), 'price': _priceC.text.trim(), 'oldPrice': _oldPriceC.text.trim(),
        'description': _descC.text.trim(), 'emoji': _emojiC.text, 'category': _category,
        'imageUrl': productImageUrls.isNotEmpty ? productImageUrls.first : '', // backward compat
        'imageUrls': productImageUrls, // new: all product images
        'descImages': descImageUrls,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (_isEditing) {
        await FirebaseFirestore.instance.collection('products').doc(widget.docId).update(data);
        debugPrint('Product updated: ${widget.docId}');
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        data['createdBy'] = FirebaseAuth.instance.currentUser?.uid;
        data['rating'] = 4.5;
        final docRef = await FirebaseFirestore.instance.collection('products').add(data);
        debugPrint('Product created: ${docRef.id}');
      }
      debugPrint('=== SAVE PRODUCT SUCCESS ===');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'تم حفظ التعديلات ✓' : 'تم حفظ المنتج بنجاح ✓'),
            backgroundColor: const Color(0xFF00897B), duration: const Duration(seconds: 2)));
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Save product error: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildImgPreview(Uint8List? bytes, String? url, {double height = 140, double? width}) {
    if (bytes != null && bytes.isNotEmpty) {
      return Image.memory(bytes, height: height, width: width ?? double.infinity, fit: BoxFit.cover);
    } else if (url != null && url.isNotEmpty) {
      return Image.network(url, height: height, width: width ?? double.infinity, fit: BoxFit.cover,
        errorBuilder: (_, error, ___) {
          debugPrint('Product image error: $error');
          return Container(height: height, width: width, decoration: BoxDecoration(
            color: _teal.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
            child: const Center(child: Icon(Icons.cloud_off, color: _teal, size: 24)));
        });
    }
    return const SizedBox.shrink();
  }

  @override
  void dispose() { _nameC.dispose(); _priceC.dispose(); _oldPriceC.dispose(); _descC.dispose(); _emojiC.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(centerTitle: true,
        title: Text(_isEditing ? 'تعديل المنتج' : 'إضافة منتج جديد', style: const TextStyle(fontWeight: FontWeight.bold, color: _text1)),
        backgroundColor: _card, foregroundColor: _teal, elevation: 0, surfaceTintColor: Colors.transparent),
      body: _isSaving
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const CircularProgressIndicator(color: _teal), const SizedBox(height: 16),
            Text('جاري ${_isEditing ? "حفظ التعديلات" : "حفظ المنتج"}...', style: TextStyle(color: _text2)),
            const SizedBox(height: 8),
            Text('يتم رفع الصور...', style: TextStyle(fontSize: 12, color: _text2)),
          ]))
        : SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [

        // ─── Product Images (Gallery) ───
        Container(
          width: double.infinity, padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.photo_camera, color: _teal, size: 20), const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('صور المنتج', style: TextStyle(fontWeight: FontWeight.bold, color: _text1)),
                Text('الصورة الأولى هي الصورة الرئيسية', style: TextStyle(fontSize: 10, color: _text2)),
              ])),
              TextButton.icon(
                onPressed: _addProductImage,
                icon: const Icon(Icons.add_photo_alternate, size: 18),
                label: Text('إضافة (${_productImages.length})', style: const TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: _teal)),
            ]),
            const SizedBox(height: 10),
            if (_productImages.isEmpty)
              InkWell(
                onTap: _addProductImage,
                borderRadius: BorderRadius.circular(12),
                child: Container(height: 120, width: double.infinity,
                  decoration: BoxDecoration(color: _teal.withOpacity(0.05), borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _teal.withOpacity(0.3))),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add_photo_alternate, size: 40, color: _teal.withOpacity(0.6)),
                    const SizedBox(height: 8),
                    Text('اضغط لاختيار صور المنتج', style: TextStyle(color: _teal.withOpacity(0.8), fontSize: 13)),
                    Text('يمكنك إضافة عدة صور', style: TextStyle(color: _text2, fontSize: 11)),
                  ])),
              )
            else
              SizedBox(
                height: 140,
                child: ReorderableListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _productImages.length,
                  onReorder: (oldIdx, newIdx) {
                    setState(() {
                      if (newIdx > oldIdx) newIdx--;
                      final item = _productImages.removeAt(oldIdx);
                      _productImages.insert(newIdx, item);
                    });
                  },
                  itemBuilder: (_, i) {
                    final img = _productImages[i];
                    return Container(
                      key: ValueKey('pimg_$i'),
                      width: 130, margin: const EdgeInsets.only(left: 8),
                      child: Stack(children: [
                        ClipRRect(borderRadius: BorderRadius.circular(12),
                          child: _buildImgPreview(img.bytes, img.url, height: 130, width: 130)),
                        // Remove button
                        Positioned(top: 4, left: 4, child: InkWell(
                          onTap: () => setState(() => _productImages.removeAt(i)),
                          child: Container(padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.white, size: 14)))),
                        // Badge (main / number)
                        Positioned(bottom: 4, right: 4, child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: i == 0 ? _teal : Colors.black54,
                            borderRadius: BorderRadius.circular(8)),
                          child: Text(i == 0 ? 'رئيسية' : '${i + 1}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        )),
                      ]),
                    );
                  },
                ),
              ),
          ]),
        ),
        const SizedBox(height: 14),

        _field(_nameC, 'اسم المنتج', Icons.shopping_bag),
        _field(_priceC, 'السعر (مثال: 2500)', Icons.attach_money, type: TextInputType.text),
        _field(_oldPriceC, 'السعر القديم (اختياري)', Icons.money_off, type: TextInputType.text),
        _field(_emojiC, 'الإيموجي', Icons.emoji_emotions),
        _field(_descC, 'وصف المنتج', Icons.description, maxLines: 4),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _category,
          decoration: InputDecoration(labelText: 'القسم', filled: true, fillColor: _card,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14)))).toList(),
          onChanged: (v) => setState(() => _category = v!),
        ),
        const SizedBox(height: 14),

        // ─── Description Images ───
        Container(
          width: double.infinity, padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.photo_library, color: _pink, size: 20), const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('صور الوصف', style: TextStyle(fontWeight: FontWeight.bold, color: _text1)),
                Text('صور تظهر في وصف المنتج التفصيلي', style: TextStyle(fontSize: 10, color: _text2)),
              ])),
              TextButton.icon(
                onPressed: _addDescImage,
                icon: const Icon(Icons.add_photo_alternate, size: 18),
                label: Text('إضافة (${_descImages.length})', style: const TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: _pink)),
            ]),
            if (_descImages.isEmpty)
              Padding(padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(child: Column(children: [
                  Icon(Icons.photo_library_outlined, size: 32, color: _text2.withOpacity(0.3)),
                  const SizedBox(height: 6),
                  Text('لا توجد صور وصف. اضغط "إضافة" لإدراج صور.', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: _text2)),
                ]))),
            ..._descImages.asMap().entries.map((e) => Padding(padding: const EdgeInsets.only(top: 10), child: Stack(children: [
              ClipRRect(borderRadius: BorderRadius.circular(10), child: _buildImgPreview(e.value.bytes, e.value.url, height: 100)),
              Positioned(top: 4, left: 4, child: InkWell(onTap: () => setState(() => _descImages.removeAt(e.key)),
                child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 14)))),
              Positioned(bottom: 4, right: 4, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                child: Text('${e.key + 1}', style: const TextStyle(color: Colors.white, fontSize: 11)),
              )),
            ]))),
          ]),
        ),
        const SizedBox(height: 20),

        SizedBox(width: double.infinity, height: 52, child: ElevatedButton.icon(
          onPressed: _save, icon: Icon(_isEditing ? Icons.save : Icons.add),
          label: Text(_isEditing ? 'حفظ التعديلات' : 'حفظ المنتج', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        )),
      ])),
    ));
  }

  Widget _field(TextEditingController c, String label, IconData icon, {TextInputType? type, int maxLines = 1}) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: TextField(
      controller: c, keyboardType: type, maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icon, color: _teal),
        filled: true, fillColor: _card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _teal, width: 1.5)),
      ),
    ));
  }
}

// ═══════════════════════════════════════════════
//  4. ARTICLES MANAGEMENT
// ═══════════════════════════════════════════════
class _ArticlesManagementScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(centerTitle: true, title: const Text('📝 إدارة المقالات', style: TextStyle(fontWeight: FontWeight.bold, color: _text1)),
        backgroundColor: _card, foregroundColor: _teal, elevation: 0, surfaceTintColor: Colors.transparent,
        actions: [
          if (AdminService().hasPermission(Permission.addArticles))
            IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => _AddArticleScreen()));
            }),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('articles').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('📝', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 16),
              Text('لا توجد مقالات في قاعدة البيانات', style: TextStyle(fontSize: 14, color: _text2)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _AddArticleScreen())),
                icon: const Icon(Icons.add), label: const Text('إضافة مقال'),
                style: ElevatedButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.white),
              ),
            ]));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snap.data!.docs.length,
            itemBuilder: (_, i) {
              final doc = snap.data!.docs[i];
              final d = doc.data() as Map<String, dynamic>;
              final hasImage = d['imageUrl'] != null && (d['imageUrl'] as String).isNotEmpty;
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _AddArticleScreen(docId: doc.id, existingData: d))),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (hasImage)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                        child: Image.network(d['imageUrl'], height: 140, width: double.infinity, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(height: 80, color: const Color(0xFF42A5F5).withOpacity(0.1),
                            child: const Center(child: Icon(Icons.broken_image, color: Color(0xFF42A5F5))))),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        if (!hasImage)
                          Container(width: 50, height: 50, margin: const EdgeInsets.only(left: 12),
                            decoration: BoxDecoration(color: const Color(0xFF42A5F5).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                            child: const Center(child: Icon(Icons.article, color: Color(0xFF42A5F5)))),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(d['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: _text1), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(d['category'] ?? '', style: TextStyle(fontSize: 12, color: _text2)),
                        ])),
                        IconButton(icon: const Icon(Icons.edit_outlined, color: _teal, size: 20),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _AddArticleScreen(docId: doc.id, existingData: d)))),
                        if (AdminService().hasPermission(Permission.deleteArticles))
                          IconButton(icon: Icon(Icons.delete_outline, color: Colors.red.shade300, size: 20), onPressed: () => doc.reference.delete()),
                      ]),
                    ),
                  ]),
                ),
              );
            },
          );
        },
      ),
    ));
  }
}

// ─── Add / Edit Article Screen (with image upload) ───
class _AddArticleScreen extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? existingData;
  const _AddArticleScreen({this.docId, this.existingData});
  @override
  State<_AddArticleScreen> createState() => _AddArticleScreenState();
}

class _AddArticleScreenState extends State<_AddArticleScreen> {
  final _titleC = TextEditingController();
  final _contentC = TextEditingController();
  String _category = 'تغذية';
  final _cats = ['تغذية', 'رياضة', 'صحة نفسية', 'نوم', 'جمال', 'نصائح عامة', 'صحة الجنين', 'ما بعد الولادة'];
  bool get _isEditing => widget.docId != null;

  // Header image — cache bytes in memory for reliable web preview
  String? _headerImageUrl; // existing URL from Firestore
  XFile? _headerImageFile; // newly picked file
  Uint8List? _headerImageBytes; // cached bytes for preview

  // Content images
  final List<_ArticleImage> _contentImages = [];

  bool _isSaving = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      final d = widget.existingData!;
      _titleC.text = d['title'] ?? '';
      _contentC.text = d['content'] ?? '';
      _headerImageUrl = d['imageUrl'] as String?;
      if (_headerImageUrl != null && _headerImageUrl!.isEmpty) _headerImageUrl = null;
      _category = d['category'] ?? 'تغذية';
      if (!_cats.contains(_category)) _category = 'تغذية';
      final images = d['contentImages'] as List<dynamic>? ?? [];
      for (final img in images) {
        _contentImages.add(_ArticleImage(url: img.toString()));
      }
    }
  }

  // ─── Pick image from gallery ───
  Future<XFile?> _pickImage() async {
    try {
      return await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في اختيار الصورة: $e'), backgroundColor: Colors.red));
      }
      return null;
    }
  }

  // ─── Read file bytes (cached for preview) ───
  Future<Uint8List?> _readFileBytes(XFile file) async {
    try {
      return await file.readAsBytes();
    } catch (e) {
      debugPrint('Read bytes error: $e');
      return null;
    }
  }

  // ─── Upload image to Firebase Storage ───
  Future<String?> _uploadImage(XFile file, String path) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      final bytes = await file.readAsBytes();
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final task = await ref.putData(bytes, metadata);
      debugPrint('Upload complete: ${task.state}, bytes: ${bytes.length}');
      final url = await ref.getDownloadURL();
      debugPrint('Download URL: $url');
      return url;
    } catch (e) {
      debugPrint('Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في رفع الصورة: $e'), backgroundColor: Colors.red, duration: const Duration(seconds: 5)));
      }
      return null;
    }
  }

  // ─── Pick header image ───
  Future<void> _pickHeaderImage() async {
    final file = await _pickImage();
    if (file != null) {
      final bytes = await _readFileBytes(file);
      if (bytes != null) {
        setState(() {
          _headerImageFile = file;
          _headerImageBytes = bytes;
          _headerImageUrl = null;
        });
      }
    }
  }

  // ─── Add content image ───
  Future<void> _addContentImage() async {
    final file = await _pickImage();
    if (file != null) {
      final bytes = await _readFileBytes(file);
      if (bytes != null) {
        setState(() => _contentImages.add(_ArticleImage(file: file, bytes: bytes)));
      }
    }
  }

  // ─── Remove content image ───
  void _removeContentImage(int index) {
    setState(() => _contentImages.removeAt(index));
  }

  // ─── Remove header image ───
  void _removeHeaderImage() {
    setState(() {
      _headerImageFile = null;
      _headerImageBytes = null;
      _headerImageUrl = null;
    });
  }

  // ─── Save article ───
  Future<void> _save() async {
    if (_titleC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال عنوان المقال'), backgroundColor: Colors.orange));
      return;
    }
    if (_contentC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال محتوى المقال'), backgroundColor: Colors.orange));
      return;
    }
    setState(() => _isSaving = true);
    debugPrint('=== SAVE ARTICLE START ===');

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Upload header image if new file selected
      String? headerUrl = _headerImageUrl;
      if (_headerImageFile != null) {
        debugPrint('Uploading header image...');
        headerUrl = await _uploadImage(_headerImageFile!, 'articles/headers/header_$timestamp.jpg');
        debugPrint('Header upload result: $headerUrl');
        if (headerUrl == null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل رفع صورة العنوان — سيُحفظ المقال بدون صورة'), backgroundColor: Colors.orange, duration: Duration(seconds: 3)));
        }
      }

      // Upload content images (only new files)
      final List<String> contentImageUrls = [];
      for (int i = 0; i < _contentImages.length; i++) {
        final img = _contentImages[i];
        if (img.url != null) {
          contentImageUrls.add(img.url!);
        } else if (img.file != null) {
          debugPrint('Uploading content image $i...');
          final url = await _uploadImage(img.file!, 'articles/content/content_${timestamp}_$i.jpg');
          if (url != null) contentImageUrls.add(url);
        }
      }

      debugPrint('Saving to Firestore...');
      final data = <String, dynamic>{
        'title': _titleC.text.trim(),
        'content': _contentC.text.trim(),
        'category': _category,
        'imageUrl': headerUrl ?? '',
        'contentImages': contentImageUrls,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid,
      };

      if (_isEditing) {
        await FirebaseFirestore.instance.collection('articles').doc(widget.docId).update(data);
        debugPrint('Article updated: ${widget.docId}');
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        data['createdBy'] = FirebaseAuth.instance.currentUser?.uid;
        final docRef = await FirebaseFirestore.instance.collection('articles').add(data);
        debugPrint('Article created: ${docRef.id}');
      }

      debugPrint('=== SAVE ARTICLE SUCCESS ===');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'تم حفظ التعديلات ✓' : 'تم نشر المقال بنجاح ✓'),
            backgroundColor: const Color(0xFF00897B), duration: const Duration(seconds: 2)));
        Navigator.pop(context);
      }
    } catch (e, stack) {
      debugPrint('=== SAVE ARTICLE ERROR ===');
      debugPrint('Error: $e');
      debugPrint('Stack: $stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الحفظ: $e'), backgroundColor: Colors.red, duration: const Duration(seconds: 5)));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() { _titleC.dispose(); _contentC.dispose(); super.dispose(); }

  Widget _buildImagePreview(Uint8List? bytes, String? url, {double height = 140}) {
    if (bytes != null && bytes.isNotEmpty) {
      return Image.memory(bytes, height: height, width: double.infinity, fit: BoxFit.cover);
    }
    if (url != null && url.isNotEmpty) {
      return Image.network(url, height: height, width: double.infinity, fit: BoxFit.cover,
        errorBuilder: (_, error, ___) {
          debugPrint('Image load error: $error');
          return Container(height: height, decoration: BoxDecoration(
            color: _teal.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.cloud_off, color: _teal.withOpacity(0.5), size: 32),
              const SizedBox(height: 6),
              Text('\u0627\u0644\u0635\u0648\u0631\u0629 \u063a\u064a\u0631 \u0645\u062a\u0627\u062d\u0629', style: TextStyle(fontSize: 11, color: _text2)),
            ]));
        });
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final hasHeader = _headerImageBytes != null || (_headerImageUrl != null && _headerImageUrl!.isNotEmpty);
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(centerTitle: true,
        title: Text(_isEditing ? '\u062a\u0639\u062f\u064a\u0644 \u0627\u0644\u0645\u0642\u0627\u0644' : '\u0625\u0636\u0627\u0641\u0629 \u0645\u0642\u0627\u0644', style: const TextStyle(fontWeight: FontWeight.bold, color: _text1)),
        backgroundColor: _card, foregroundColor: _teal, elevation: 0, surfaceTintColor: Colors.transparent),
      body: _isSaving
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const CircularProgressIndicator(color: _teal),
            const SizedBox(height: 16),
            Text('\u062c\u0627\u0631\u064a ${_isEditing ? "\u062d\u0641\u0638 \u0627\u0644\u062a\u0639\u062f\u064a\u0644\u0627\u062a" : "\u0646\u0634\u0631 \u0627\u0644\u0645\u0642\u0627\u0644"}...', style: TextStyle(color: _text2)),
            const SizedBox(height: 8),
            Text('\u064a\u062a\u0645 \u0631\u0641\u0639 \u0627\u0644\u0635\u0648\u0631...', style: TextStyle(fontSize: 12, color: _text2)),
          ]))
        : SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        TextField(controller: _titleC, decoration: InputDecoration(labelText: '\u0639\u0646\u0648\u0627\u0646 \u0627\u0644\u0645\u0642\u0627\u0644', prefixIcon: const Icon(Icons.title, color: _teal),
          filled: true, fillColor: _card, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
        const SizedBox(height: 14),
        Container(
          width: double.infinity, padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.image, color: _teal, size: 20), const SizedBox(width: 8),
              const Expanded(child: Text('\u0635\u0648\u0631\u0629 \u0627\u0644\u0639\u0646\u0648\u0627\u0646', style: TextStyle(fontWeight: FontWeight.bold, color: _text1))),
              if (hasHeader) IconButton(icon: Icon(Icons.delete_outline, color: Colors.red.shade300, size: 20), onPressed: _removeHeaderImage),
            ]),
            const SizedBox(height: 8),
            if (hasHeader) ...[
              ClipRRect(borderRadius: BorderRadius.circular(12), child: _buildImagePreview(_headerImageBytes, _headerImageUrl)),
              const SizedBox(height: 8),
              Center(child: TextButton.icon(onPressed: _pickHeaderImage, icon: const Icon(Icons.swap_horiz, size: 18),
                label: const Text('\u062a\u063a\u064a\u064a\u0631 \u0627\u0644\u0635\u0648\u0631\u0629', style: TextStyle(fontSize: 12)), style: TextButton.styleFrom(foregroundColor: _teal))),
            ] else
              InkWell(onTap: _pickHeaderImage, borderRadius: BorderRadius.circular(12),
                child: Container(height: 120, width: double.infinity,
                  decoration: BoxDecoration(color: _teal.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: _teal.withOpacity(0.3))),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add_photo_alternate, size: 40, color: _teal.withOpacity(0.6)), const SizedBox(height: 8),
                    Text('\u0627\u0636\u063a\u0637 \u0644\u0627\u062e\u062a\u064a\u0627\u0631 \u0635\u0648\u0631\u0629', style: TextStyle(color: _teal.withOpacity(0.8), fontSize: 13)),
                  ]))),
          ]),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(value: _category,
          decoration: InputDecoration(labelText: '\u0627\u0644\u0642\u0633\u0645', filled: true, fillColor: _card,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
          items: _cats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setState(() => _category = v!)),
        const SizedBox(height: 14),
        TextField(controller: _contentC, maxLines: 10, decoration: InputDecoration(labelText: '\u0645\u062d\u062a\u0648\u0649 \u0627\u0644\u0645\u0642\u0627\u0644', alignLabelWithHint: true,
          filled: true, fillColor: _card, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
        const SizedBox(height: 16),
        Container(
          width: double.infinity, padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.photo_library, color: _teal, size: 20), const SizedBox(width: 8),
              const Expanded(child: Text('\u0635\u0648\u0631 \u062f\u0627\u062e\u0644 \u0627\u0644\u0645\u0642\u0627\u0644', style: TextStyle(fontWeight: FontWeight.bold, color: _text1))),
              TextButton.icon(onPressed: _addContentImage, icon: const Icon(Icons.add_photo_alternate, size: 18),
                label: const Text('\u0625\u0636\u0627\u0641\u0629 \u0635\u0648\u0631\u0629', style: TextStyle(fontSize: 12)), style: TextButton.styleFrom(foregroundColor: _teal)),
            ]),
            if (_contentImages.isEmpty)
              Padding(padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(child: Column(children: [
                  Icon(Icons.photo_library_outlined, size: 32, color: _text2.withOpacity(0.3)), const SizedBox(height: 6),
                  Text('\u0644\u0627 \u062a\u0648\u062c\u062f \u0635\u0648\u0631', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: _text2)),
                ]))),
            ..._contentImages.asMap().entries.map((entry) {
              final idx = entry.key;
              final img = entry.value;
              return Padding(padding: const EdgeInsets.only(top: 10), child: Stack(children: [
                ClipRRect(borderRadius: BorderRadius.circular(10), child: _buildImagePreview(img.bytes, img.url, height: 100)),
                Positioned(top: 4, left: 4, child: InkWell(onTap: () => _removeContentImage(idx),
                  child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 16)))),
                Positioned(bottom: 4, right: 4, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                  child: Text('${idx + 1}', style: const TextStyle(color: Colors.white, fontSize: 11)))),
              ]));
            }),
          ]),
        ),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 52, child: ElevatedButton.icon(
          onPressed: _save, icon: Icon(_isEditing ? Icons.save : Icons.publish),
          label: Text(_isEditing ? '\u062d\u0641\u0638 \u0627\u0644\u062a\u0639\u062f\u064a\u0644\u0627\u062a' : '\u0646\u0634\u0631 \u0627\u0644\u0645\u0642\u0627\u0644', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        )),
      ])),
    ));
  }
}

class _ArticleImage {
  final String? url;
  final XFile? file;
  final Uint8List? bytes;
  const _ArticleImage({this.url, this.file, this.bytes});
}


// ═══════════════════════════════════════════════
//  5. USERS MANAGEMENT
// ═══════════════════════════════════════════════
class _UsersManagementScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(centerTitle: true, title: const Text('\u{1f465} إدارة المستخدمات', style: TextStyle(fontWeight: FontWeight.bold, color: _text1)),
        backgroundColor: _card, foregroundColor: _teal, elevation: 0, surfaceTintColor: Colors.transparent),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('\u{1f465}', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 16),
              Text('لا توجد مستخدمات بعد', style: TextStyle(fontSize: 16, color: _text2)),
            ]));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snap.data!.docs.length,
            itemBuilder: (_, i) {
              final doc = snap.data!.docs[i];
              final d = doc.data() as Map<String, dynamic>;
              final isBanned = d['isBanned'] == true;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isBanned ? Colors.red.shade50 : _card,
                  borderRadius: BorderRadius.circular(14),
                  border: isBanned ? Border.all(color: Colors.red.shade200) : null,
                ),
                child: Row(children: [
                  CircleAvatar(
                    backgroundColor: _teal.withOpacity(0.1),
                    child: Text((d['name'] ?? '?')[0].toUpperCase(), style: TextStyle(color: _teal, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(d['name'] ?? 'بدون اسم', style: const TextStyle(fontWeight: FontWeight.bold, color: _text1)),
                      if (isBanned) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                          child: const Text('محظورة', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ]),
                    Text(d['email'] ?? '', style: TextStyle(fontSize: 12, color: _text2)),
                  ])),
                  if (AdminService().hasPermission(Permission.banUsers))
                    IconButton(
                      icon: Icon(isBanned ? Icons.lock_open : Icons.block, color: isBanned ? Colors.green : Colors.red.shade300, size: 20),
                      onPressed: () => doc.reference.update({'isBanned': !isBanned}),
                    ),
                ]),
              );
            },
          );
        },
      ),
    ));
  }
}

// ═══════════════════════════════════════════════
//  6. COUPONS MANAGEMENT
// ═══════════════════════════════════════════════
class _CouponsManagementScreen extends StatefulWidget {
  @override
  State<_CouponsManagementScreen> createState() => _CouponsManagementScreenState();
}

class _CouponsManagementScreenState extends State<_CouponsManagementScreen> {
  final _codeC = TextEditingController();
  final _discountC = TextEditingController();
  final _maxUsesC = TextEditingController();
  String _type = 'percentage';

  Future<void> _addCoupon() async {
    if (_codeC.text.trim().isEmpty || _discountC.text.trim().isEmpty) return;
    await FirebaseFirestore.instance.collection('coupons').add({
      'code': _codeC.text.trim().toUpperCase(),
      'discount': double.tryParse(_discountC.text.trim()) ?? 0,
      'type': _type,
      'maxUses': int.tryParse(_maxUsesC.text.trim()) ?? 100,
      'usedCount': 0,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    _codeC.clear(); _discountC.clear(); _maxUsesC.clear();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة الكوبون ✓'), backgroundColor: _teal));
  }

  @override
  void dispose() { _codeC.dispose(); _discountC.dispose(); _maxUsesC.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(centerTitle: true, title: const Text('\u{1f39f}\u{fe0f} الكوبونات والعروض', style: TextStyle(fontWeight: FontWeight.bold, color: _text1)),
        backgroundColor: _card, foregroundColor: _teal, elevation: 0, surfaceTintColor: Colors.transparent),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Add coupon form
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('إضافة كوبون جديد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _text1)),
            const SizedBox(height: 14),
            TextField(controller: _codeC, decoration: InputDecoration(labelText: 'كود الكوبون', prefixIcon: const Icon(Icons.confirmation_number, color: _teal),
              filled: true, fillColor: _bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(controller: _discountC, keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'القيمة', prefixIcon: const Icon(Icons.discount, color: _teal),
                  filled: true, fillColor: _bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
              const SizedBox(width: 10),
              Expanded(child: DropdownButtonFormField<String>(value: _type,
                decoration: InputDecoration(filled: true, fillColor: _bg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                items: const [
                  DropdownMenuItem(value: 'percentage', child: Text('نسبة %')),
                  DropdownMenuItem(value: 'fixed', child: Text('مبلغ ثابت')),
                ],
                onChanged: (v) => setState(() => _type = v!))),
            ]),
            const SizedBox(height: 10),
            TextField(controller: _maxUsesC, keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'الحد الأقصى للاستخدام', prefixIcon: const Icon(Icons.repeat, color: _teal),
                filled: true, fillColor: _bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(
              onPressed: _addCoupon, icon: const Icon(Icons.add), label: const Text('إضافة الكوبون'),
              style: ElevatedButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
          ]),
        ),
        const SizedBox(height: 16),
        const Text('الكوبونات الحالية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _text1)),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('coupons').orderBy('createdAt', descending: true).snapshots(),
          builder: (_, snap) {
            if (!snap.hasData || snap.data!.docs.isEmpty) {
              return Center(child: Padding(padding: const EdgeInsets.all(30),
                child: Text('لا توجد كوبونات بعد', style: TextStyle(color: _text2))));
            }
            return Column(children: snap.data!.docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              final isActive = d['isActive'] == true;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14),
                  border: isActive ? null : Border.all(color: Colors.grey.shade300)),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: _teal.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(d['code'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, color: _teal, fontSize: 14)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(d['type'] == 'percentage' ? '${d['discount']}% خصم' : '${d['discount']} خصم ثابت',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: _text1)),
                    Text('استخدم ${d['usedCount'] ?? 0} / ${d['maxUses'] ?? 100}', style: TextStyle(fontSize: 11, color: _text2)),
                  ])),
                  Switch(value: isActive, activeColor: _teal,
                    onChanged: (v) => doc.reference.update({'isActive': v})),
                  IconButton(icon: Icon(Icons.delete_outline, color: Colors.red.shade300, size: 20),
                    onPressed: () => doc.reference.delete()),
                ]),
              );
            }).toList());
          },
        ),
      ]),
    ));
  }
}

// ═══════════════════════════════════════════════
//  7. STAFF MANAGEMENT (Owner only)
// ═══════════════════════════════════════════════
class _StaffManagementScreen extends StatefulWidget {
  @override
  State<_StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<_StaffManagementScreen> {
  final _emailC = TextEditingController();
  final _nameC = TextEditingController();
  AdminRole _selectedRole = AdminRole.employee;

  Future<void> _addStaff() async {
    if (_emailC.text.trim().isEmpty || _nameC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال الاسم والبريد الإلكتروني'), backgroundColor: Colors.orange));
      return;
    }
    final success = await AdminService().addStaffMember(
      email: _emailC.text.trim(),
      name: _nameC.text.trim(),
      role: _selectedRole,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? 'تم إضافة الموظف ✓' : 'فشل في إضافة الموظف'),
        backgroundColor: success ? _teal : Colors.red));
      if (success) { _emailC.clear(); _nameC.clear(); }
    }
  }

  @override
  void dispose() { _emailC.dispose(); _nameC.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(centerTitle: true, title: const Text('\u{1f454} إدارة الموظفين', style: TextStyle(fontWeight: FontWeight.bold, color: _text1)),
        backgroundColor: _card, foregroundColor: _teal, elevation: 0, surfaceTintColor: Colors.transparent),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Add staff form
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('إضافة موظف جديد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _text1)),
            const SizedBox(height: 14),
            TextField(controller: _nameC, decoration: InputDecoration(labelText: 'اسم الموظف', prefixIcon: const Icon(Icons.person, color: _teal),
              filled: true, fillColor: _bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
            const SizedBox(height: 10),
            TextField(controller: _emailC, keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: const Icon(Icons.email, color: _teal),
              filled: true, fillColor: _bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
            const SizedBox(height: 10),
            DropdownButtonFormField<AdminRole>(
              value: _selectedRole,
              decoration: InputDecoration(labelText: 'الدور', filled: true, fillColor: _bg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
              items: [AdminRole.supervisor, AdminRole.employee].map((r) => DropdownMenuItem(
                value: r, child: Row(children: [
                  Icon(AdminService.roleIcon(r), size: 18, color: AdminService.roleColor(r)),
                  const SizedBox(width: 8),
                  Text(AdminService.roleNameAr(r)),
                ]),
              )).toList(),
              onChanged: (v) => setState(() => _selectedRole = v!),
            ),
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(
              onPressed: _addStaff, icon: const Icon(Icons.person_add), label: const Text('إضافة الموظف'),
              style: ElevatedButton.styleFrom(backgroundColor: _purple, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
          ]),
        ),
        const SizedBox(height: 16),
        const Text('فريق العمل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _text1)),
        const SizedBox(height: 10),
        StreamBuilder<List<StaffMember>>(
          stream: AdminService().staffStream,
          builder: (_, snap) {
            if (!snap.hasData || snap.data!.isEmpty) {
              return Center(child: Padding(padding: const EdgeInsets.all(30),
                child: Text('لا يوجد موظفون بعد', style: TextStyle(color: _text2))));
            }
            return Column(children: snap.data!.map((staff) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: staff.isActive ? _card : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  CircleAvatar(backgroundColor: AdminService.roleColor(staff.role).withOpacity(0.1),
                    child: Icon(AdminService.roleIcon(staff.role), color: AdminService.roleColor(staff.role), size: 20)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(staff.name, style: const TextStyle(fontWeight: FontWeight.bold, color: _text1)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AdminService.roleColor(staff.role).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8)),
                        child: Text(AdminService.roleNameAr(staff.role),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AdminService.roleColor(staff.role))),
                      ),
                    ]),
                    Text(staff.email, style: TextStyle(fontSize: 12, color: _text2)),
                  ])),
                  if (staff.role != AdminRole.owner)
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: _text2, size: 20),
                      onSelected: (action) async {
                        if (action == 'deactivate') {
                          await AdminService().deactivateStaff(staff.uid);
                        } else if (action == 'supervisor') {
                          await AdminService().updateStaffRole(staff.uid, AdminRole.supervisor);
                        } else if (action == 'employee') {
                          await AdminService().updateStaffRole(staff.uid, AdminRole.employee);
                        }
                      },
                      itemBuilder: (_) => [
                        if (staff.role != AdminRole.supervisor)
                          const PopupMenuItem(value: 'supervisor', child: Text('ترقية إلى مشرف')),
                        if (staff.role != AdminRole.employee)
                          const PopupMenuItem(value: 'employee', child: Text('تخفيض إلى موظف')),
                        if (staff.isActive)
                          PopupMenuItem(value: 'deactivate', child: Text('إلغاء التنشيط', style: TextStyle(color: Colors.red.shade400))),
                      ],
                    ),
                ]),
              );
            }).toList());
          },
        ),
      ]),
    ));
  }
}

// ═══════════════════════════════════════════════
//  8. NOTIFICATIONS
// ═══════════════════════════════════════════════
class _NotificationsScreen extends StatefulWidget {
  @override
  State<_NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<_NotificationsScreen> {
  final _titleC = TextEditingController();
  final _bodyC = TextEditingController();
  bool _isSending = false;

  Future<void> _send() async {
    if (_titleC.text.trim().isEmpty || _bodyC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال العنوان والمحتوى'), backgroundColor: Colors.orange));
      return;
    }
    setState(() => _isSending = true);
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': _titleC.text.trim(),
        'body': _bodyC.text.trim(),
        'type': 'broadcast',
        'createdAt': FieldValue.serverTimestamp(),
        'sentBy': FirebaseAuth.instance.currentUser?.uid,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال الإشعار ✓'), backgroundColor: _teal));
        _titleC.clear(); _bodyC.clear();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  void dispose() { _titleC.dispose(); _bodyC.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(centerTitle: true, title: const Text('\u{1f514} الإشعارات الجماعية', style: TextStyle(fontWeight: FontWeight.bold, color: _text1)),
        backgroundColor: _card, foregroundColor: _teal, elevation: 0, surfaceTintColor: Colors.transparent),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('إرسال إشعار جديد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _text1)),
            const SizedBox(height: 14),
            TextField(controller: _titleC, decoration: InputDecoration(labelText: 'عنوان الإشعار',
              prefixIcon: const Icon(Icons.title, color: _teal),
              filled: true, fillColor: _bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
            const SizedBox(height: 10),
            TextField(controller: _bodyC, maxLines: 4, decoration: InputDecoration(labelText: 'محتوى الإشعار', alignLabelWithHint: true,
              filled: true, fillColor: _bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(
              onPressed: _isSending ? null : _send,
              icon: _isSending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send),
              label: Text(_isSending ? 'جاري الإرسال...' : 'إرسال الإشعار'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8D6E63), foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
          ]),
        ),
        const SizedBox(height: 16),
        const Text('الإشعارات السابقة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _text1)),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('notifications').where('type', isEqualTo: 'broadcast').orderBy('createdAt', descending: true).limit(20).snapshots(),
          builder: (_, snap) {
            if (!snap.hasData || snap.data!.docs.isEmpty) {
              return Center(child: Padding(padding: const EdgeInsets.all(30),
                child: Text('لا توجد إشعارات سابقة', style: TextStyle(color: _text2))));
            }
            return Column(children: snap.data!.docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: _text1)),
                  const SizedBox(height: 4),
                  Text(d['body'] ?? '', style: TextStyle(fontSize: 13, color: _text2), maxLines: 3, overflow: TextOverflow.ellipsis),
                ]),
              );
            }).toList());
          },
        ),
      ]),
    ));
  }
}

// ═══════════════════════════════════════════════
//  9. DELIVERY PRICING
// ═══════════════════════════════════════════════
class _CountryDeliveryInfo {
  final String name;
  final String flag;
  final String currency;
  final String code;
  const _CountryDeliveryInfo({required this.name, required this.flag, required this.currency, required this.code});
}

class _DeliveryPricingScreen extends StatelessWidget {
  final _countries = const [
    _CountryDeliveryInfo(name: 'الجزائر', flag: '\u{1f1e9}\u{1f1ff}', currency: 'د.ج', code: 'DZ'),
    _CountryDeliveryInfo(name: 'السعودية', flag: '\u{1f1f8}\u{1f1e6}', currency: 'ر.س', code: 'SA'),
    _CountryDeliveryInfo(name: 'الإمارات', flag: '\u{1f1e6}\u{1f1ea}', currency: 'د.إ', code: 'AE'),
    _CountryDeliveryInfo(name: 'مصر', flag: '\u{1f1ea}\u{1f1ec}', currency: 'ج.م', code: 'EG'),
    _CountryDeliveryInfo(name: 'المغرب', flag: '\u{1f1f2}\u{1f1e6}', currency: 'د.م', code: 'MA'),
    _CountryDeliveryInfo(name: 'تونس', flag: '\u{1f1f9}\u{1f1f3}', currency: 'د.ت', code: 'TN'),
    _CountryDeliveryInfo(name: 'الأردن', flag: '\u{1f1ef}\u{1f1f4}', currency: 'د.أ', code: 'JO'),
    _CountryDeliveryInfo(name: 'الكويت', flag: '\u{1f1f0}\u{1f1fc}', currency: 'د.ك', code: 'KW'),
    _CountryDeliveryInfo(name: 'قطر', flag: '\u{1f1f6}\u{1f1e6}', currency: 'ر.ق', code: 'QA'),
    _CountryDeliveryInfo(name: 'البحرين', flag: '\u{1f1e7}\u{1f1ed}', currency: 'د.ب', code: 'BH'),
    _CountryDeliveryInfo(name: 'عُمان', flag: '\u{1f1f4}\u{1f1f2}', currency: 'ر.ع', code: 'OM'),
    _CountryDeliveryInfo(name: 'العراق', flag: '\u{1f1ee}\u{1f1f6}', currency: 'د.ع', code: 'IQ'),
    _CountryDeliveryInfo(name: 'ليبيا', flag: '\u{1f1f1}\u{1f1fe}', currency: 'د.ل', code: 'LY'),
    _CountryDeliveryInfo(name: 'السودان', flag: '\u{1f1f8}\u{1f1e9}', currency: 'ج.س', code: 'SD'),
    _CountryDeliveryInfo(name: 'فرنسا', flag: '\u{1f1eb}\u{1f1f7}', currency: '\u{20ac}', code: 'FR'),
    _CountryDeliveryInfo(name: 'تركيا', flag: '\u{1f1f9}\u{1f1f7}', currency: '\u{20ba}', code: 'TR'),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(centerTitle: true, title: const Text('\u{1f69a} أسعار التوصيل', style: TextStyle(fontWeight: FontWeight.bold, color: _text1)),
        backgroundColor: _card, foregroundColor: _teal, elevation: 0, surfaceTintColor: Colors.transparent),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('settings').doc('delivery_pricing').snapshots(),
        builder: (context, snap) {
          final data = snap.data?.data() as Map<String, dynamic>? ?? {};
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _countries.length,
            itemBuilder: (_, i) {
              final country = _countries[i];
              final pricing = data[country.code] as Map<String, dynamic>? ?? {};
              final price = pricing['price'] ?? '';
              final enabled = pricing['enabled'] == true;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  Text(country.flag, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(country.name, style: const TextStyle(fontWeight: FontWeight.bold, color: _text1)),
                    Text(price.toString().isNotEmpty ? '$price ${country.currency}' : 'غير محدد',
                      style: TextStyle(fontSize: 12, color: price.toString().isNotEmpty ? _teal : _text2, fontWeight: FontWeight.bold)),
                  ])),
                  Switch(value: enabled, activeColor: _teal, onChanged: (v) {
                    FirebaseFirestore.instance.collection('settings').doc('delivery_pricing').set(
                      {country.code: {'enabled': v, 'price': price, 'currency': country.currency}},
                      SetOptions(merge: true));
                  }),
                  IconButton(icon: const Icon(Icons.edit, color: _teal, size: 20), onPressed: () {
                    final priceC = TextEditingController(text: price.toString());
                    showDialog(context: context, builder: (ctx) => Directionality(
                      textDirection: TextDirection.rtl,
                      child: AlertDialog(
                        title: Text('${country.flag} ${country.name}'),
                        content: TextField(controller: priceC, keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: 'سعر التوصيل (${country.currency})',
                            filled: true, fillColor: _bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                          ElevatedButton(
                            onPressed: () {
                              FirebaseFirestore.instance.collection('settings').doc('delivery_pricing').set(
                                {country.code: {'price': priceC.text.trim(), 'currency': country.currency, 'enabled': true}},
                                SetOptions(merge: true));
                              Navigator.pop(ctx);
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.white),
                            child: const Text('حفظ'),
                          ),
                        ],
                      ),
                    ));
                  }),
                ]),
              );
            },
          );
        },
      ),
    ));
  }
}
