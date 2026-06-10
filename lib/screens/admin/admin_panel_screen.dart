import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/admin_service.dart';
import '../../services/notification_service.dart';
import '../../services/dynamic_content_service.dart';
import '../../services/community_engagement_service.dart';

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

            // Dynamic Content (new articles & products)
            if (_admin.hasPermission(Permission.addArticles) || _admin.hasPermission(Permission.addProducts))
              _ModuleCard(
                title: 'المحتوى الجديد',
                subtitle: 'إضافة مقالات ومنتجات جديدة (Firestore)',
                emoji: '🆕',
                color: const Color(0xFF00897B),
                onTap: () => _push(_DynamicContentScreen()),
              ),

            // Ads (owner/admin only)
            if (_admin.hasPermission(Permission.manageCoupons))
              _ModuleCard(
                title: 'إدارة الإعلانات',
                subtitle: 'إعلانات داخل المقالات — إضافة، رفع صورة، تفعيل، حذف',
                emoji: '\u{1F4E2}',
                color: const Color(0xFFAB47BC),
                onTap: () => _push(_AdsManagementScreen()),
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

            // Community Engagement - TODO: implement screen
            // if (_admin.hasPermission(Permission.viewDashboard))
            //   _ModuleCard(title: 'تنشيط المجتمع', ...),

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
class _ProductsManagementScreen extends StatefulWidget {
  @override
  State<_ProductsManagementScreen> createState() => _ProductsManagementScreenState();
}

class _ProductsManagementScreenState extends State<_ProductsManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabC;
  String _searchQuery = '';
  String _carouselSearchQuery = '';
  String _shopCategoryFilter = 'الكل';
  String _carouselSectionFilter = 'الكل';

  static const _sectionLabels = {'home': 'الرئيسية', 'cycle': 'الدورة', 'pregnancy': 'الحمل', 'baby': 'الطفل', 'news': 'الأخبار'};

  static const _staticCarouselProducts = <String, List<Map<String, String>>>{
    'pregnancy': [
      {'name': 'وسادة الحمل المريحة', 'image': 'https://images.unsplash.com/photo-1584839404210-0a5d92ea4861?w=300&q=80', 'price': '3500 د.ج', 'category': 'راحة الحامل'},
      {'name': 'كريم علامات التمدد', 'image': 'https://images.unsplash.com/photo-1556228578-8c89e6adf883?w=300&q=80', 'price': '1800 د.ج', 'category': 'العناية بالبشرة'},
      {'name': 'حمض الفوليك 400mcg', 'image': 'https://images.unsplash.com/photo-1550572017-edd951b55104?w=300&q=80', 'price': '950 د.ج', 'category': 'مكملات غذائية'},
      {'name': 'حزام دعم البطن', 'image': 'https://images.unsplash.com/photo-1584839404210-0a5d92ea4861?w=300&q=80', 'price': '2200 د.ج', 'category': 'راحة الحامل'},
      {'name': 'زيت اللوز للتدليك', 'image': 'https://images.unsplash.com/photo-1608571423902-eed4a5ad8108?w=300&q=80', 'price': '1200 د.ج', 'category': 'العناية بالبشرة'},
      {'name': 'فيتامينات ما قبل الولادة', 'image': 'https://images.unsplash.com/photo-1471864190281-a93a3070b6de?w=300&q=80', 'price': '2800 د.ج', 'category': 'مكملات غذائية'},
    ],
    'cycle': [
      {'name': 'قربة ماء ساخن', 'image': 'https://images.unsplash.com/photo-1515377905703-c4788e51af15?w=300&q=80', 'price': '800 د.ج', 'category': 'تخفيف الألم'},
      {'name': 'شاي البابونج العضوي', 'image': 'https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=300&q=80', 'price': '650 د.ج', 'category': 'مشروبات صحية'},
      {'name': 'مكمل المغنيسيوم', 'image': 'https://images.unsplash.com/photo-1550572017-edd951b55104?w=300&q=80', 'price': '1500 د.ج', 'category': 'مكملات غذائية'},
      {'name': 'فوط صحية قطنية', 'image': 'https://images.unsplash.com/photo-1583947215259-38e31be8751f?w=300&q=80', 'price': '450 د.ج', 'category': 'نظافة شخصية'},
    ],
    'baby': [
      {'name': 'كريم حماية الحفاض', 'image': 'https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?w=300&q=80', 'price': '750 د.ج', 'category': 'العناية بالطفل'},
      {'name': 'زيت تدليك الأطفال', 'image': 'https://images.unsplash.com/photo-1608571423902-eed4a5ad8108?w=300&q=80', 'price': '900 د.ج', 'category': 'العناية بالطفل'},
      {'name': 'ميزان حرارة رقمي', 'image': 'https://images.unsplash.com/photo-1584308666544-27e30e01c6c6?w=300&q=80', 'price': '1200 د.ج', 'category': 'صحة الطفل'},
      {'name': 'رضاعة مضادة للمغص', 'image': 'https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?w=300&q=80', 'price': '1800 د.ج', 'category': 'تغذية الطفل'},
    ],
    'home': [
      {'name': 'فيتامين D3 للنساء', 'image': 'https://images.unsplash.com/photo-1550572017-edd951b55104?w=300&q=80', 'price': '1400 د.ج', 'category': 'مكملات غذائية'},
      {'name': 'كريم ترطيب طبيعي', 'image': 'https://images.unsplash.com/photo-1556228578-8c89e6adf883?w=300&q=80', 'price': '1600 د.ج', 'category': 'العناية بالبشرة'},
      {'name': 'شاي أعشاب مهدئ', 'image': 'https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=300&q=80', 'price': '700 د.ج', 'category': 'مشروبات صحية'},
    ],
  };

  @override
  void initState() { super.initState(); _tabC = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tabC.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('إدارة المنتجات', style: TextStyle(fontWeight: FontWeight.bold, color: _text1, fontSize: 18)),
        backgroundColor: _card, foregroundColor: _teal, elevation: 0, surfaceTintColor: Colors.transparent,
        actions: [
          if (AdminService().hasPermission(Permission.addProducts))
            IconButton(icon: const Icon(Icons.add_circle_outline, size: 26), onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => _AddProductScreen()));
            }),
        ],
        bottom: TabBar(
          controller: _tabC, labelColor: _teal, unselectedLabelColor: _text2, indicatorColor: _teal,
          indicatorWeight: 3,
          tabs: const [Tab(text: 'منتجات المتجر'), Tab(text: 'منتجات الكاروسال')],
        ),
      ),
      body: TabBarView(controller: _tabC, children: [_buildShopTab(), _buildCarouselTab()]),
    ));
  }

  // ═══════════════════════════════════════════════════════════════
  // ██  TAB 1: SHOP PRODUCTS (Firestore 'products')
  // ═══════════════════════════════════════════════════════════════
  Widget _buildShopTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snap) {
        var docs = snap.data?.docs ?? [];
        // Extract categories for filter chips
        final allCats = <String>{'الكل'};
        for (final doc in docs) {
          final cat = ((doc.data() as Map<String, dynamic>)['category'] ?? '').toString();
          if (cat.isNotEmpty) allCats.add(cat);
        }

        // Apply filters
        if (_searchQuery.isNotEmpty) {
          docs = docs.where((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return (d['name'] ?? '').toString().toLowerCase().contains(_searchQuery) ||
                   (d['category'] ?? '').toString().toLowerCase().contains(_searchQuery);
          }).toList();
        }
        if (_shopCategoryFilter != 'الكل') {
          docs = docs.where((doc) => ((doc.data() as Map<String, dynamic>)['category'] ?? '') == _shopCategoryFilter).toList();
        }

        return Column(children: [
          // Search bar
          Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 6), child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'بحث بالاسم أو التصنيف...', prefixIcon: const Icon(Icons.search, color: _teal),
              filled: true, fillColor: _card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16)),
          )),
          // Category filter chips
          if (allCats.length > 2)
            SizedBox(height: 40, child: ListView(
              scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
              children: allCats.map((cat) => Padding(
                padding: const EdgeInsets.only(left: 6),
                child: ChoiceChip(
                  label: Text(cat, style: TextStyle(fontSize: 11, color: _shopCategoryFilter == cat ? Colors.white : _text2)),
                  selected: _shopCategoryFilter == cat,
                  selectedColor: _teal,
                  backgroundColor: _card,
                  onSelected: (_) => setState(() => _shopCategoryFilter = cat),
                  visualDensity: VisualDensity.compact,
                ),
              )).toList(),
            )),
          // Stats bar
          Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 4), child: Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: _teal.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('${docs.length} منتج', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _teal))),
            const Spacer(),
            TextButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _AddProductScreen())),
              icon: const Icon(Icons.add, size: 16), label: const Text('إضافة منتج', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: _teal, visualDensity: VisualDensity.compact)),
          ])),
          // Products grid
          Expanded(child: docs.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.shopping_bag_outlined, size: 60, color: _teal.withOpacity(0.3)),
                const SizedBox(height: 12),
                Text('لا توجد منتجات', style: TextStyle(color: _text2)),
              ]))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16), itemCount: docs.length,
                itemBuilder: (_, i) => _shopProductCard(docs[i]),
              ),
          ),
        ]);
      },
    );
  }

  Widget _shopProductCard(QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final imageUrl = d['imageUrl'] as String? ?? '';
    final imageUrls = d['imageUrls'] as List<dynamic>? ?? [];
    final mainImg = imageUrls.isNotEmpty ? imageUrls.first.toString() : imageUrl;
    final hasImg = mainImg.isNotEmpty;
    final hasOldPrice = (d['oldPrice'] ?? '').toString().isNotEmpty;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _AddProductScreen(docId: doc.id, existingData: d))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Row(children: [
          // Product image (larger)
          ClipRRect(
            borderRadius: const BorderRadius.only(topRight: Radius.circular(16), bottomRight: Radius.circular(16)),
            child: hasImg
              ? Image.network(mainImg, width: 100, height: 100, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _imgPlaceholder(d['emoji']))
              : _imgPlaceholder(d['emoji']),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: _text1, fontSize: 14),
                maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                Text(d['price'] ?? '', style: const TextStyle(fontSize: 15, color: _teal, fontWeight: FontWeight.bold)),
                if (hasOldPrice) ...[
                  const SizedBox(width: 6),
                  Text(d['oldPrice'], style: TextStyle(fontSize: 11, color: _text2, decoration: TextDecoration.lineThrough)),
                ],
              ]),
              const SizedBox(height: 6),
              if (d['category'] != null) Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: _teal.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                child: Text(d['category'], style: const TextStyle(fontSize: 10, color: _teal, fontWeight: FontWeight.w600)),
              ),
              if (imageUrls.length > 1) Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${imageUrls.length} صور', style: TextStyle(fontSize: 10, color: _text2)),
              ),
            ],
          ))),
          // Actions column
          Padding(padding: const EdgeInsets.only(left: 6), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            _actionBtn(Icons.edit_outlined, _teal,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => _AddProductScreen(docId: doc.id, existingData: d)))),
            const SizedBox(height: 4),
            _actionBtn(Icons.content_copy_outlined, Colors.blue, () => _copyShopToCarousel(d)),
            const SizedBox(height: 4),
            if (AdminService().hasPermission(Permission.deleteProducts))
              _actionBtn(Icons.delete_outline, Colors.red.shade400, () => _confirmDeleteShop(doc, d['name'] ?? '')),
          ])),
          const SizedBox(width: 6),
        ]),
      ),
    );
  }

  Widget _imgPlaceholder(String? emoji) => Container(width: 100, height: 100,
    color: _teal.withOpacity(0.08),
    child: Center(child: Text(emoji ?? '🛍️', style: const TextStyle(fontSize: 32))));

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) => InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(8),
    child: Container(padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, size: 18, color: color)));

  Future<void> _confirmDeleteShop(QueryDocumentSnapshot doc, String name) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => Directionality(
      textDirection: TextDirection.rtl, child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [Icon(Icons.warning_amber, color: Colors.red.shade400), const SizedBox(width: 8), const Text('حذف المنتج')]),
        content: Text('هل تريد حذف "$name"؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('حذف', style: TextStyle(color: Colors.white))),
        ],
      ),
    ));
    if (ok == true) { doc.reference.delete(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حذف المنتج ✓'), backgroundColor: Color(0xFF00897B))); }
  }

  // Copy a shop product to carousel (dynamic_products)
  void _copyShopToCarousel(Map<String, dynamic> d) {
    final nameC = TextEditingController(text: d['name'] ?? '');
    final priceC = TextEditingController(text: d['price'] ?? '');
    final imageC = TextEditingController(text: d['imageUrl'] ?? '');
    final categoryC = TextEditingController(text: d['category'] ?? '');
    final linkC = TextEditingController();
    String section = 'home';
    _showProductFormSheet(
      title: 'نسخ إلى الكاروسال', icon: Icons.copy, color: Colors.blue, btnText: 'نسخ إلى الكاروسال', btnIcon: Icons.arrow_back,
      nameC: nameC, priceC: priceC, imageC: imageC, categoryC: categoryC, linkC: linkC,
      section: section, onSectionChanged: (v) => section = v,
      onSave: () async {
        await DynamicContentService.addProduct(name: nameC.text.trim(), image: imageC.text.trim(),
          price: priceC.text.trim(), category: categoryC.text.trim(), section: section, link: linkC.text.trim());
        return 'تم النسخ إلى الكاروسال ✓';
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ██  TAB 2: CAROUSEL PRODUCTS (dynamic_products + hardcoded)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildCarouselTab() {
    return Column(children: [
      // Search
      Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 6), child: TextField(
        onChanged: (v) => setState(() => _carouselSearchQuery = v.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'بحث بالاسم أو التصنيف...', prefixIcon: const Icon(Icons.search, color: _teal),
          filled: true, fillColor: _card,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16)),
      )),
      // Section filter chips
      SizedBox(height: 40, child: ListView(
        scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
        children: ['الكل', ..._sectionLabels.values].map((label) => Padding(
          padding: const EdgeInsets.only(left: 6),
          child: ChoiceChip(
            label: Text(label, style: TextStyle(fontSize: 11, color: _carouselSectionFilter == label ? Colors.white : _text2)),
            selected: _carouselSectionFilter == label,
            selectedColor: _teal, backgroundColor: _card,
            onSelected: (_) => setState(() => _carouselSectionFilter = label),
            visualDensity: VisualDensity.compact),
        )).toList(),
      )),
      // Products list
      Expanded(child: StreamBuilder<QuerySnapshot>(
        stream: DynamicContentService.productsRef.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snap) {
          final dynamicDocs = snap.data?.docs ?? [];
          final List<_CarouselProductItem> allItems = [];

          for (final doc in dynamicDocs) {
            final d = doc.data() as Map<String, dynamic>;
            allItems.add(_CarouselProductItem(name: d['name'] ?? '', image: d['image'] ?? '', price: d['price'] ?? '',
              category: d['category'] ?? '', section: d['section'] ?? '', sectionLabel: _sectionLabels[d['section']] ?? d['section'] ?? '',
              isDynamic: true, docId: doc.id, link: d['link'] ?? ''));
          }
          for (final entry in _staticCarouselProducts.entries) {
            for (final p in entry.value) {
              allItems.add(_CarouselProductItem(name: p['name']!, image: p['image']!, price: p['price']!,
                category: p['category']!, section: entry.key, sectionLabel: _sectionLabels[entry.key] ?? entry.key,
                isDynamic: false, docId: null, link: ''));
            }
          }

          // Apply filters
          var filtered = allItems.toList();
          if (_carouselSearchQuery.isNotEmpty) {
            filtered = filtered.where((e) =>
              e.name.toLowerCase().contains(_carouselSearchQuery) ||
              e.category.toLowerCase().contains(_carouselSearchQuery) ||
              e.price.toLowerCase().contains(_carouselSearchQuery)).toList();
          }
          if (_carouselSectionFilter != 'الكل') {
            filtered = filtered.where((e) => e.sectionLabel == _carouselSectionFilter).toList();
          }

          if (filtered.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.search_off, size: 50, color: _teal.withOpacity(0.3)),
              const SizedBox(height: 10),
              Text('لا توجد نتائج', style: TextStyle(color: _text2)),
            ]));
          }

          // Stats
          final dynCount = filtered.where((e) => e.isDynamic).length;
          final staticCount = filtered.length - dynCount;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            itemCount: filtered.length + 1,
            itemBuilder: (_, i) {
              if (i == 0) {
                return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
                  _statChip('${filtered.length} منتج', _teal),
                  const SizedBox(width: 6),
                  if (dynCount > 0) _statChip('$dynCount ديناميكي', Colors.blue),
                  if (dynCount > 0) const SizedBox(width: 6),
                  _statChip('$staticCount مدمج', Colors.orange),
                ]));
              }
              final item = filtered[i - 1];
              return _carouselProductCard(item);
            },
          );
        },
      )),
    ]);
  }

  Widget _statChip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
    child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)));

  Widget _carouselProductCard(_CarouselProductItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(16),
        border: item.isDynamic ? Border.all(color: Colors.blue.withOpacity(0.2)) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(children: [
        // Image
        ClipRRect(
          borderRadius: const BorderRadius.only(topRight: Radius.circular(16), bottomRight: Radius.circular(16)),
          child: Image.network(item.image, width: 90, height: 90, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(width: 90, height: 90, color: _teal.withOpacity(0.08),
              child: const Icon(Icons.shopping_bag, color: _teal, size: 30))),
        ),
        const SizedBox(width: 10),
        // Details
        Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, color: _text1, fontSize: 13),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text(item.price, style: const TextStyle(fontSize: 14, color: _teal, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                child: Text(item.category, style: TextStyle(fontSize: 9, color: _text2))),
              const SizedBox(width: 4),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: _teal.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                child: Text(item.sectionLabel, style: const TextStyle(fontSize: 9, color: _teal))),
              const SizedBox(width: 4),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: item.isDynamic ? Colors.blue.withOpacity(0.08) : Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6)),
                child: Text(item.isDynamic ? 'ديناميكي' : 'مدمج',
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: item.isDynamic ? Colors.blue : Colors.orange))),
            ]),
          ],
        ))),
        // Actions
        Padding(padding: const EdgeInsets.only(left: 6), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          _actionBtn(item.isDynamic ? Icons.edit_outlined : Icons.copy_outlined, _teal,
            item.isDynamic ? () => _editCarouselProduct(item) : () => _convertToDynamic(item)),
          const SizedBox(height: 4),
          _actionBtn(Icons.store_outlined, Colors.purple, () => _copyCarouselToShop(item)),
          const SizedBox(height: 4),
          if (item.isDynamic)
            _actionBtn(Icons.delete_outline, Colors.red.shade400, () => _confirmDeleteCarousel(item)),
        ])),
        const SizedBox(width: 6),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ██  SHARED ACTIONS
  // ═══════════════════════════════════════════════════════════════

  void _editCarouselProduct(_CarouselProductItem item) {
    final nameC = TextEditingController(text: item.name);
    final priceC = TextEditingController(text: item.price);
    final imageC = TextEditingController(text: item.image);
    final categoryC = TextEditingController(text: item.category);
    final linkC = TextEditingController(text: item.link);
    String section = item.section;
    _showProductFormSheet(
      title: 'تعديل المنتج', icon: Icons.edit, color: _teal, btnText: 'حفظ التعديلات', btnIcon: Icons.save,
      nameC: nameC, priceC: priceC, imageC: imageC, categoryC: categoryC, linkC: linkC,
      section: section, onSectionChanged: (v) => section = v,
      onSave: () async {
        await DynamicContentService.productsRef.doc(item.docId).update({
          'name': nameC.text.trim(), 'price': priceC.text.trim(), 'image': imageC.text.trim(),
          'category': categoryC.text.trim(), 'section': section, 'link': linkC.text.trim()});
        return 'تم تعديل المنتج ✓';
      },
    );
  }

  void _convertToDynamic(_CarouselProductItem item) {
    final nameC = TextEditingController(text: item.name);
    final priceC = TextEditingController(text: item.price);
    final imageC = TextEditingController(text: item.image);
    final categoryC = TextEditingController(text: item.category);
    final linkC = TextEditingController();
    String section = item.section;
    _showProductFormSheet(
      title: 'نسخ كمنتج ديناميكي', icon: Icons.copy, color: Colors.orange.shade700,
      btnText: 'نسخ كديناميكي', btnIcon: Icons.copy,
      nameC: nameC, priceC: priceC, imageC: imageC, categoryC: categoryC, linkC: linkC,
      section: section, onSectionChanged: (v) => section = v,
      hint: 'هذا المنتج مدمج. يمكنك إنشاء نسخة ديناميكية قابلة للتعديل.',
      onSave: () async {
        await DynamicContentService.addProduct(name: nameC.text.trim(), image: imageC.text.trim(),
          price: priceC.text.trim(), category: categoryC.text.trim(), section: section, link: linkC.text.trim());
        return 'تم إنشاء نسخة ديناميكية ✓';
      },
    );
  }

  void _copyCarouselToShop(_CarouselProductItem item) {
    final nameC = TextEditingController(text: item.name);
    final priceC = TextEditingController(text: item.price);
    final imageC = TextEditingController(text: item.image);
    final categoryC = TextEditingController(text: item.category);
    final linkC = TextEditingController();
    String section = item.section;
    _showProductFormSheet(
      title: 'نسخ إلى المتجر', icon: Icons.store, color: Colors.purple, btnText: 'إضافة للمتجر', btnIcon: Icons.store,
      nameC: nameC, priceC: priceC, imageC: imageC, categoryC: categoryC, linkC: linkC,
      section: section, onSectionChanged: (v) => section = v,
      onSave: () async {
        await FirebaseFirestore.instance.collection('products').add({
          'name': nameC.text.trim(), 'price': priceC.text.trim(), 'imageUrl': imageC.text.trim(),
          'category': categoryC.text.trim(), 'emoji': '🛍️', 'rating': 4.5,
          'createdAt': FieldValue.serverTimestamp(), 'createdBy': FirebaseAuth.instance.currentUser?.uid});
        return 'تم إضافة المنتج للمتجر ✓';
      },
    );
  }

  Future<void> _confirmDeleteCarousel(_CarouselProductItem item) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => Directionality(
      textDirection: TextDirection.rtl, child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [Icon(Icons.warning_amber, color: Colors.red.shade400), const SizedBox(width: 8), const Text('حذف المنتج')]),
        content: Text('هل تريد حذف "${item.name}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('حذف', style: TextStyle(color: Colors.white))),
        ],
      ),
    ));
    if (ok == true && item.docId != null) {
      await DynamicContentService.deleteProduct(item.docId!);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف المنتج ✓'), backgroundColor: Color(0xFF00897B)));
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ██  SHARED PRODUCT FORM BOTTOM SHEET
  // ═══════════════════════════════════════════════════════════════
  void _showProductFormSheet({
    required String title, required IconData icon, required Color color,
    required String btnText, required IconData btnIcon,
    required TextEditingController nameC, required TextEditingController priceC,
    required TextEditingController imageC, required TextEditingController categoryC,
    required TextEditingController linkC,
    required String section, required ValueChanged<String> onSectionChanged,
    required Future<String> Function() onSave, String? hint,
  }) {
    String currentSection = section;
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setBS) => Container(
        decoration: const BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 22), const SizedBox(width: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: color)),
          ]),
          if (hint != null) ...[
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
              child: Text(hint, style: TextStyle(fontSize: 12, color: color), textAlign: TextAlign.center)),
          ],
          // Image preview
          if (imageC.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(borderRadius: BorderRadius.circular(12),
              child: Image.network(imageC.text, height: 100, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink())),
          ],
          const SizedBox(height: 16),
          _formField(nameC, 'اسم المنتج', Icons.shopping_bag_outlined),
          _formField(priceC, 'السعر', Icons.attach_money),
          _formField(imageC, 'رابط الصورة', Icons.image_outlined),
          _formField(categoryC, 'التصنيف', Icons.category_outlined),
          _formField(linkC, 'رابط الشراء (اختياري)', Icons.link),
          const SizedBox(height: 6),
          Directionality(textDirection: TextDirection.rtl, child: DropdownButtonFormField<String>(
            value: currentSection,
            decoration: InputDecoration(labelText: 'القسم', prefixIcon: const Icon(Icons.dashboard_outlined, color: _teal),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
            items: _sectionLabels.entries.map((e) =>
              DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            onChanged: (v) { setBS(() => currentSection = v!); onSectionChanged(v!); },
          )),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(foregroundColor: _text2, padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('إلغاء'))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton.icon(
              onPressed: () async {
                if (nameC.text.trim().isEmpty) return;
                final msg = await onSave();
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(msg), backgroundColor: const Color(0xFF00897B)));
              },
              icon: Icon(btnIcon, size: 18), label: Text(btnText),
              style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            )),
          ]),
        ])),
      )),
    );
  }

  Widget _formField(TextEditingController c, String label, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(controller: c, decoration: InputDecoration(
      labelText: label, prefixIcon: Icon(icon, color: _teal, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
  );
}

// ── Helper class for carousel product items ──
class _CarouselProductItem {
  final String name, image, price, category, section, sectionLabel, link;
  final bool isDynamic;
  final String? docId;

  _CarouselProductItem({
    required this.name, required this.image, required this.price,
    required this.category, required this.section, required this.sectionLabel,
    required this.isDynamic, required this.docId, required this.link,
  });
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
class _ArticlesManagementScreen extends StatefulWidget {
  @override
  State<_ArticlesManagementScreen> createState() => _ArticlesManagementScreenState();
}

class _ArticlesManagementScreenState extends State<_ArticlesManagementScreen> {
  String _filterType = 'all';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  static const _typeColors = {'pregnancy': Color(0xFF9C27B0), 'cycle': Color(0xFFE91E63), 'baby': Color(0xFF2196F3), 'home': Color(0xFFFF9800), 'news': Color(0xFFFF5722)};
  static const _typeNames = {'pregnancy': 'الحمل', 'cycle': 'الدورة', 'baby': 'الطفل', 'home': 'الرئيسية', 'news': 'أخبار'};

  // ═══ ALL hardcoded articles from the app ═══
  static final _hardcodedArticles = <Map<String, dynamic>>[
    // ── News articles (30) ──
    {'title': 'أم رباعية التوائم تنجب 5 توائم دفعة واحدة', 'category': 'أرقام قياسية', 'type': 'news', 'imageUrl': 'https://images.unsplash.com/photo-1555252333-9f8e92e65df9?w=400&q=80'},
    {'title': 'أصغر توائم رباعية خدّج في التاريخ ينجون', 'category': 'معجزة طبية', 'type': 'news', 'imageUrl': 'https://images.unsplash.com/photo-1504151932400-72d4384f04b3?w=400&q=80'},
    {'title': 'امرأة ألمانية تنجب طفلها العاشر في سن 66 عاماً', 'category': 'حول العالم', 'type': 'news', 'imageUrl': 'https://images.unsplash.com/photo-1492725764893-90b379c2b6e7?w=400&q=80'},
    {'title': 'طفل ينمو خارج الرحم وينجو بأعجوبة', 'category': 'معجزة طبية', 'type': 'news', 'imageUrl': 'https://images.unsplash.com/photo-1519689680058-324335c77eba?w=400&q=80'},
    {'title': 'تسعة توائم من مالي يحتفلون بعيد ميلادهم الأول', 'category': 'أرقام قياسية', 'type': 'news', 'imageUrl': 'https://images.unsplash.com/photo-1544126592-807ade215a0b?w=400&q=80'},
    {'title': 'أم تلد في مطعم بعد أن أعادها المستشفى للمنزل', 'category': 'قصص مدهشة', 'type': 'news', 'imageUrl': 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=400&q=80'},
    {'title': 'أول طفل في بريطانيا من رحم مزروع بعد عقد من الانتظار', 'category': 'معجزة طبية', 'type': 'news', 'imageUrl': 'https://images.unsplash.com/photo-1531983412531-1f49a365ffed?w=400&q=80'},
    {'title': 'توأمان يولدان في سنتين مختلفتين بفارق 15 دقيقة', 'category': 'قصص مدهشة', 'type': 'news', 'imageUrl': 'https://images.unsplash.com/photo-1578922746465-3a80a228f223?w=400&q=80'},
    {'title': 'سيدة أفريقية تنجب 10 توائم في ولادة واحدة', 'category': 'أرقام قياسية', 'type': 'news', 'imageUrl': 'https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9?w=400&q=80'},
    {'title': 'طفل يولد بسنّين كاملتين يثير دهشة الأطباء', 'category': 'حالات نادرة', 'type': 'news', 'imageUrl': 'https://images.unsplash.com/photo-1519340241574-2cec6aef0c01?w=400&q=80'},
    {'title': 'أم تكتشف حملها قبل الولادة بساعات فقط', 'category': 'قصص مدهشة', 'type': 'news', 'imageUrl': 'https://images.unsplash.com/photo-1457342813143-a1ae27a5e890?w=400&q=80'},
    {'title': 'توأمان متطابقان يولدان بلونَي بشرة مختلفين تماماً', 'category': 'حالات نادرة', 'type': 'news', 'imageUrl': 'https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?w=400&q=80'},
    {'title': 'أصغر طفل خديج في العالم يحتفل بعيده الخامس', 'category': 'معجزة طبية', 'type': 'news', 'imageUrl': 'https://images.unsplash.com/photo-1566004100631-35d015d6a491?w=400&q=80'},
    {'title': 'امرأة تنجب طفلاً أثناء غيبوبة استمرت 3 أشهر', 'category': 'حالات نادرة', 'type': 'news', 'imageUrl': 'https://images.unsplash.com/photo-1584820927498-cfe5211fd8bf?w=400&q=80'},
    {'title': 'دراسة: أطفال يتعرفون على أصوات أمهاتهم من الرحم', 'category': 'اكتشافات علمية', 'type': 'news', 'imageUrl': 'https://images.unsplash.com/photo-1491013516836-7db643ee125a?w=400&q=80'},
    {'title': 'طفلة تولد بخصلة شعر بيضاء وراثية نادرة', 'category': 'حالات نادرة', 'type': 'news', 'imageUrl': 'https://images.unsplash.com/photo-1519689373023-dd07c7988603?w=400&q=80'},
    {'title': 'دراسة: الرضاعة الطبيعية تحمي من 800 ألف وفاة سنوياً', 'category': 'اكتشافات علمية', 'type': 'news', 'imageUrl': 'https://images.unsplash.com/photo-1609220136736-443140cffec6?w=400&q=80'},
    {'title': 'أب يحضر ولادة ابنته عبر الفيديو من الفضاء', 'category': 'قصص مدهشة', 'type': 'news', 'imageUrl': 'https://images.unsplash.com/photo-1522771930-78848d9293e8?w=400&q=80'},
    {'title': 'اكتشاف أن حليب الأم يتغير تركيبه حسب جنس المولود', 'category': 'اكتشافات علمية', 'type': 'news', 'imageUrl': 'https://images.unsplash.com/photo-1555252333-9f8e92e65df9?w=400&q=80'},
    {'title': 'مستشفى يعزف الموسيقى للأجنة ويحسن نموهم', 'category': 'اكتشافات علمية', 'type': 'news', 'imageUrl': 'https://images.unsplash.com/photo-1485546246426-74dc88dec4d9?w=400&q=80'},
    {'title': 'أم تنجب طفلتها في سيارة إسعاف على الطريق السريع', 'category': 'قصص مدهشة', 'type': 'news', 'imageUrl': 'https://images.unsplash.com/photo-1490818387583-1baba5e638af?w=400&q=80'},
    {'title': 'تقنية جديدة تتيح للأجنة التنفس خارج الرحم', 'category': 'اكتشافات علمية', 'type': 'news', 'imageUrl': 'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=400&q=80'},
    {'title': 'ممرضة تكتشف أنها أنجبت التوأم الذي تعتني به في الحضانة', 'category': 'قصص مدهشة', 'type': 'news', 'imageUrl': 'https://images.unsplash.com/photo-1578307985320-34b61a66c195?w=400&q=80'},
    {'title': 'دراسة: الأطفال الذين يسمعون لغتين يتطور دماغهم أسرع', 'category': 'اكتشافات علمية', 'type': 'news', 'imageUrl': 'https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9?w=400&q=80'},
    {'title': 'توأمان ملتصقان يُفصلان بنجاح بعد عملية 36 ساعة', 'category': 'معجزة طبية', 'type': 'news', 'imageUrl': 'https://images.unsplash.com/photo-1519689680058-324335c77eba?w=400&q=80'},
    {'title': 'أصغر أم تتبرع بحليبها لإنقاذ مائة طفل خديج', 'category': 'قصص مدهشة', 'type': 'news', 'imageUrl': 'https://images.unsplash.com/photo-1544126592-807ade215a0b?w=400&q=80'},
    {'title': 'طفل يولد في طائرة على ارتفاع 10 آلاف متر', 'category': 'حول العالم', 'type': 'news', 'imageUrl': 'https://images.unsplash.com/photo-1436491865332-7a61a109db05?w=400&q=80'},
    {'title': 'علماء يطورون حفاضاً ذكياً ينبه الوالدين صحياً', 'category': 'اكتشافات علمية', 'type': 'news', 'imageUrl': 'https://images.unsplash.com/photo-1587616211892-f743fcca64f9?w=400&q=80'},
    {'title': 'سيدة مصرية تنجب بعد 25 سنة من العقم', 'category': 'معجزة طبية', 'type': 'news', 'imageUrl': 'https://images.unsplash.com/photo-1492725764893-90b379c2b6e7?w=400&q=80'},
    {'title': 'مولود يبتسم ابتسامة عريضة لحظة ولادته', 'category': 'قصص مدهشة', 'type': 'news', 'imageUrl': 'https://images.unsplash.com/photo-1519340241574-2cec6aef0c01?w=400&q=80'},
    {'title': 'مدينة يابانية تقدم مكافأة مليون ين لكل مولود جديد', 'category': 'حول العالم', 'type': 'news', 'imageUrl': 'https://images.unsplash.com/photo-1480796927426-f609979314bd?w=400&q=80'},
    // ── Cycle hardcoded (10) ──
    {'title': 'أطعمة تخفف آلام الدورة', 'category': 'تغذية أثناء الدورة', 'type': 'cycle', 'imageUrl': ''},
    {'title': 'مشروبات دافئة لتقليل التقلصات', 'category': 'تغذية أثناء الدورة', 'type': 'cycle', 'imageUrl': ''},
    {'title': 'فيتامينات ضرورية لصحة الدورة', 'category': 'تغذية أثناء الدورة', 'type': 'cycle', 'imageUrl': ''},
    {'title': 'تمارين لتخفيف آلام الدورة', 'category': 'رياضة وحركة', 'type': 'cycle', 'imageUrl': ''},
    {'title': 'يوغا لأيام الدورة', 'category': 'رياضة وحركة', 'type': 'cycle', 'imageUrl': ''},
    {'title': 'التعامل مع تقلبات المزاج', 'category': 'صحة نفسية', 'type': 'cycle', 'imageUrl': ''},
    {'title': 'نصائح للنوم الجيد أثناء الدورة', 'category': 'صحة نفسية', 'type': 'cycle', 'imageUrl': ''},
    {'title': 'متى تستشيرين الطبيبة؟', 'category': 'صحة نفسية', 'type': 'cycle', 'imageUrl': ''},
    {'title': 'تتبع الدورة: لماذا هو مهم؟', 'category': 'نصائح عامة', 'type': 'cycle', 'imageUrl': ''},
    {'title': 'خرافات شائعة عن الدورة الشهرية', 'category': 'نصائح عامة', 'type': 'cycle', 'imageUrl': ''},
    {'title': 'منتجات صحية بديلة', 'category': 'نصائح عامة', 'type': 'cycle', 'imageUrl': ''},
    // ── Baby hardcoded (10) ──
    {'title': 'الرضاعة الطبيعية: أساس صحة طفلك', 'category': 'تغذية الطفل', 'type': 'baby', 'imageUrl': ''},
    {'title': 'متى وكيف تبدئين بالأطعمة الصلبة', 'category': 'تغذية الطفل', 'type': 'baby', 'imageUrl': ''},
    {'title': 'أطعمة يجب تجنبها في السنة الأولى', 'category': 'تغذية الطفل', 'type': 'baby', 'imageUrl': ''},
    {'title': 'تنظيم نوم الرضيع: دليل شامل', 'category': 'نوم الطفل', 'type': 'baby', 'imageUrl': ''},
    {'title': 'بيئة النوم الآمنة للرضيع', 'category': 'نوم الطفل', 'type': 'baby', 'imageUrl': ''},
    {'title': 'مراحل نمو الطفل في السنة الأولى', 'category': 'النمو والتطور', 'type': 'baby', 'imageUrl': ''},
    {'title': 'تحفيز ذكاء طفلك باللعب', 'category': 'النمو والتطور', 'type': 'baby', 'imageUrl': ''},
    {'title': 'الحمى عند الرضع: متى تقلقين', 'category': 'صحة الطفل العامة', 'type': 'baby', 'imageUrl': ''},
    {'title': 'العناية ببشرة الطفل الحساسة', 'category': 'صحة الطفل العامة', 'type': 'baby', 'imageUrl': ''},
    // ── Home hardcoded (14) ──
    {'title': 'فحوصات طبية لا غنى عنها لكل امرأة بعد سن الثلاثين', 'category': 'صحة المرأة', 'type': 'home', 'imageUrl': ''},
    {'title': 'اضطرابات الغدة الدرقية: العدو الخفي لصحة المرأة', 'category': 'صحة المرأة', 'type': 'home', 'imageUrl': ''},
    {'title': 'فقر الدم عند النساء: الأسباب والعلاج الفعال', 'category': 'صحة المرأة', 'type': 'home', 'imageUrl': ''},
    {'title': '10 أطعمة خارقة لبشرة نضرة وشعر قوي', 'category': 'تغذية وجمال', 'type': 'home', 'imageUrl': ''},
    {'title': 'روتين العناية بالبشرة المثالي: صباحاً ومساءً', 'category': 'تغذية وجمال', 'type': 'home', 'imageUrl': ''},
    {'title': 'أسرار الشعر الصحي: من الجذور إلى الأطراف', 'category': 'تغذية وجمال', 'type': 'home', 'imageUrl': ''},
    {'title': 'إدارة التوتر والقلق: تقنيات فعالة للحياة اليومية', 'category': 'صحة نفسية', 'type': 'home', 'imageUrl': ''},
    {'title': 'النوم الصحي: مفتاح الصحة النفسية والجسدية', 'category': 'صحة نفسية', 'type': 'home', 'imageUrl': ''},
    {'title': 'التربية الإيجابية: كيف تربين طفلاً واثقاً وسعيداً', 'category': 'أمومة وطفولة', 'type': 'home', 'imageUrl': ''},
    {'title': 'تعزيز المناعة الطبيعية عند الأطفال', 'category': 'أمومة وطفولة', 'type': 'home', 'imageUrl': ''},
    {'title': 'تمارين منزلية فعالة في 15 دقيقة يومياً', 'category': 'رياضة ولياقة', 'type': 'home', 'imageUrl': ''},
    {'title': 'المشي: الرياضة المثالية للمرأة العصرية', 'category': 'رياضة ولياقة', 'type': 'home', 'imageUrl': ''},
    {'title': 'وجبات فطور صحية وسريعة للمرأة العاملة', 'category': 'وصفات صحية', 'type': 'home', 'imageUrl': ''},
    {'title': 'مشروبات ديتوكس طبيعية لتنقية الجسم', 'category': 'وصفات صحية', 'type': 'home', 'imageUrl': ''},
    {'title': 'التوازن بين العمل والحياة الأسرية: دليل عملي', 'category': 'علاقات أسرية', 'type': 'home', 'imageUrl': ''},
    {'title': 'التواصل الفعال مع الشريك: أساس العلاقة الصحية', 'category': 'علاقات أسرية', 'type': 'home', 'imageUrl': ''},
    {'title': 'الصداع النصفي عند النساء: فهم وعلاج', 'category': 'نصائح طبية', 'type': 'home', 'imageUrl': ''},
    {'title': 'التهابات المسالك البولية: وقاية وعلاج', 'category': 'نصائح طبية', 'type': 'home', 'imageUrl': ''},
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(centerTitle: true, title: const Text('\u{1F4DD} إدارة المقالات', style: TextStyle(fontWeight: FontWeight.bold, color: _text1)),
        backgroundColor: _card, foregroundColor: _teal, elevation: 0, surfaceTintColor: Colors.transparent,
        actions: [
          if (AdminService().hasPermission(Permission.addArticles))
            IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => _AddArticleScreen()));
            }),
        ],
      ),
      body: Column(children: [
        // Search bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          color: _card,
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _searchQuery = v.trim()),
            decoration: InputDecoration(
              hintText: 'البحث عن مقال...',
              hintStyle: TextStyle(color: _text2, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: _teal),
              suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); }) : null,
              filled: true, fillColor: _bg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ),
        // Type filter chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: _card,
          child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
            _filterChip('all', 'الكل', _teal),
            const SizedBox(width: 8),
            _filterChip('pregnancy', 'الحمل', const Color(0xFF9C27B0)),
            const SizedBox(width: 8),
            _filterChip('cycle', 'الدورة', const Color(0xFFE91E63)),
            const SizedBox(width: 8),
            _filterChip('baby', 'الطفل', const Color(0xFF2196F3)),
            const SizedBox(width: 8),
            _filterChip('home', 'الرئيسية', const Color(0xFFFF9800)),
            const SizedBox(width: 8),
            _filterChip('news', 'أخبار', const Color(0xFFFF5722)),
          ])),
        ),
        // Seed button
        if (AdminService().hasPermission(Permission.addArticles))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: SizedBox(width: double.infinity, child: OutlinedButton.icon(
              onPressed: () => _seedArticles(context),
              icon: const Icon(Icons.cloud_upload_outlined, size: 18),
              label: const Text('رفع المقالات الافتراضية', style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(foregroundColor: _teal, side: BorderSide(color: _teal.withOpacity(0.3))),
            )),
          ),
        // Articles list — combines Firestore + hardcoded + overrides
        Expanded(child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('articles').orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snap) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('article_overrides').snapshots(),
              builder: (context, overrideSnap) {
                // Build unified list
                final allItems = <Map<String, dynamic>>[];

                // Track titles already added (to avoid duplicates)
                final addedTitles = <String>{};

                // 1. Firestore articles
                if (snap.hasData) {
                  for (final doc in snap.data!.docs) {
                    final d = doc.data() as Map<String, dynamic>;
                    allItems.add({...d, '_docId': doc.id, '_source': 'firestore'});
                    addedTitles.add((d['title'] ?? '').toString());
                  }
                }

                // 2. Article overrides (admin edits of hardcoded articles)
                if (overrideSnap.hasData) {
                  for (final doc in overrideSnap.data!.docs) {
                    final d = doc.data() as Map<String, dynamic>;
                    if (d['deleted'] == true) continue;
                    addedTitles.add((d['title'] ?? d['originalTitle'] ?? '').toString());
                    addedTitles.add((d['originalTitle'] ?? '').toString());
                    final existsInArticles = allItems.any((a) => a['title'] == d['title'] || a['_docId'] == doc.id);
                    if (!existsInArticles) {
                      allItems.add({...d, '_docId': doc.id, '_source': 'override', 'type': d['section'] ?? d['type'] ?? 'news'});
                    }
                  }
                }

                // 3. Hardcoded articles (not yet in Firestore or overrides)
                for (final hc in _hardcodedArticles) {
                  final title = hc['title'] as String;
                  if (!addedTitles.contains(title)) {
                    allItems.add({...hc, '_docId': 'hc_${title.hashCode}', '_source': 'hardcoded'});
                  }
                }

                // Apply filters
                var filtered = allItems;
                if (_filterType != 'all') {
                  filtered = filtered.where((d) => (d['type'] ?? d['section'] ?? 'pregnancy') == _filterType).toList();
                }
                if (_searchQuery.isNotEmpty) {
                  filtered = filtered.where((d) {
                    final title = (d['title'] ?? '').toString().toLowerCase();
                    final body = (d['body'] ?? d['content'] ?? '').toString().toLowerCase();
                    final category = (d['category'] ?? '').toString().toLowerCase();
                    final q = _searchQuery.toLowerCase();
                    return title.contains(q) || body.contains(q) || category.contains(q);
                  }).toList();
                }

                if (filtered.isEmpty) {
                  return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text('\u{1F4DD}', style: TextStyle(fontSize: 60)),
                    const SizedBox(height: 16),
                    Text(_searchQuery.isNotEmpty ? 'لا توجد نتائج لـ "$_searchQuery"' : 'لا توجد مقالات',
                      style: TextStyle(fontSize: 14, color: _text2)),
                    const SizedBox(height: 16),
                    if (AdminService().hasPermission(Permission.addArticles))
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _AddArticleScreen())),
                        icon: const Icon(Icons.add), label: const Text('إضافة مقال'),
                        style: ElevatedButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.white),
                      ),
                  ]));
                }

                return Column(children: [
                  // Count indicator
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(children: [
                      Text('${filtered.length} مقال', style: TextStyle(fontSize: 12, color: _text2, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      if (_searchQuery.isNotEmpty) Text('نتائج البحث', style: TextStyle(fontSize: 12, color: _teal)),
                    ]),
                  ),
                  Expanded(child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final d = filtered[i];
                      final imgUrl = (d['imageUrl'] ?? d['image'] ?? '').toString();
                      final hasImage = imgUrl.isNotEmpty;
                      final type = d['type'] ?? d['section'] ?? 'pregnancy';
                      final typeColor = _typeColors[type] ?? _teal;
                      final source = d['_source'] as String;
                      final isHardcoded = source == 'hardcoded';
                      final isOverride = source == 'override';
                      return GestureDetector(
                        onTap: () {
                          if (isHardcoded || isOverride) {
                            // Edit hardcoded/override articles via _AddArticleScreen with override support
                            Navigator.push(context, MaterialPageRoute(builder: (_) => _AddArticleScreen(
                              docId: isOverride ? d['_docId'] : null,
                              existingData: {...d, 'content': d['content'] ?? d['body'] ?? '', 'type': type},
                            )));
                            return;
                          }
                          Navigator.push(context, MaterialPageRoute(builder: (_) => _AddArticleScreen(docId: d['_docId'], existingData: d)));
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14),
                            border: isOverride ? Border.all(color: Colors.orange.withOpacity(0.3), width: 1)
                              : isHardcoded ? Border.all(color: typeColor.withOpacity(0.2), width: 1) : null),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(children: [
                              Container(width: 50, height: 50, margin: const EdgeInsets.only(left: 12),
                                decoration: BoxDecoration(
                                  color: hasImage ? null : typeColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  image: hasImage ? DecorationImage(image: NetworkImage(imgUrl), fit: BoxFit.cover) : null,
                                ),
                                child: hasImage ? null : Center(child: Icon(Icons.article, color: typeColor))),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(d['title'] ?? d['originalTitle'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: _text1), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Row(children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                    child: Text(_typeNames[type] ?? type, style: TextStyle(fontSize: 11, color: typeColor, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(child: Text(d['category'] ?? '', style: TextStyle(fontSize: 12, color: _text2), overflow: TextOverflow.ellipsis)),
                                  if (isOverride) ...[
                                    const SizedBox(width: 6),
                                    Icon(Icons.edit_note, size: 14, color: Colors.orange.shade400),
                                  ],
                                  if (isHardcoded) ...[
                                    const SizedBox(width: 6),
                                    Icon(Icons.code, size: 14, color: typeColor.withOpacity(0.5)),
                                  ],
                                ]),
                              ])),
                              IconButton(icon: const Icon(Icons.edit_outlined, color: _teal, size: 20),
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => _AddArticleScreen(
                                    docId: (source == 'firestore') ? d['_docId'] : (isOverride ? d['_docId'] : null),
                                    existingData: {...d, 'content': d['content'] ?? d['body'] ?? '', 'type': type},
                                  )));
                                }),
                              if (AdminService().hasPermission(Permission.deleteArticles) && source == 'firestore')
                                IconButton(icon: Icon(Icons.delete_outline, color: Colors.red.shade300, size: 20),
                                  onPressed: () => FirebaseFirestore.instance.collection('articles').doc(d['_docId']).delete()),
                            ]),
                          ),
                        ),
                      );
                    },
                  )),
                ]);
              },
            );
          },
        )),
      ]),
    ));
  }

  Widget _filterChip(String type, String label, Color color) {
    final selected = _filterType == type;
    return GestureDetector(
      onTap: () => setState(() => _filterType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.bold,
          color: selected ? Colors.white : color,
        )),
      ),
    );
  }

  Future<void> _seedArticles(BuildContext context) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('رفع المقالات الافتراضية'),
        content: const Text('سيتم رفع مقالات الدورة الشهرية والطفل إلى قاعدة البيانات. هل تريد المتابعة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('رفع'),
            style: ElevatedButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.white)),
        ],
      ),
    ));
    if (confirm != true || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('جاري رفع المقالات...'), backgroundColor: _teal, duration: Duration(seconds: 10)));

    final batch = FirebaseFirestore.instance.batch();
    final col = FirebaseFirestore.instance.collection('articles');
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final now = FieldValue.serverTimestamp();

    // Cycle articles
    final cycleArticles = [
      {'section': 'تغذية أثناء الدورة', 'articles': [
        {'title': 'أطعمة تخفف آلام الدورة', 'body': 'تناولي الأطعمة الغنية بالحديد مثل السبانخ والعدس لتعويض الدم المفقود. الموز غني بالبوتاسيوم الذي يقلل التشنجات. الشوكولاتة الداكنة (70%+) تحسّن المزاج وتخفف الألم بفضل المغنيسيوم. الزنجبيل الطازج مضاد طبيعي للالتهابات ويقلل الغثيان. تجنبي الكافيين الزائد والأطعمة المالحة التي تزيد الانتفاخ.'},
        {'title': 'مشروبات دافئة لتقليل التقلصات', 'body': 'شاي البابونج يهدئ الأعصاب ويرخي عضلات الرحم. مغلي القرفة ينشط الدورة الدموية ويخفف الألم. شاي النعناع يقلل الانتفاخ والغازات. الحليب الدافئ بالكركم مضاد قوي للالتهابات. الماء الدافئ بالليمون والعسل يرطب الجسم ويقلل التعب.'},
        {'title': 'فيتامينات ضرورية لصحة الدورة', 'body': 'فيتامين B6 يقلل أعراض متلازمة ما قبل الدورة بنسبة 70%. المغنيسيوم يخفف التشنجات وتقلبات المزاج. أوميغا 3 من الأسماك الدهنية تقلل الالتهابات. الحديد ضروري لتعويض النقص خلال النزيف. فيتامين D يحسّن المزاج ويقوي العظام.'},
      ]},
      {'section': 'رياضة وحركة', 'articles': [
        {'title': 'تمارين لتخفيف آلام الدورة', 'body': 'المشي الخفيف 20-30 دقيقة يحسّن الدورة الدموية ويقلل التشنجات. وضعية الطفل في اليوغا ترخي عضلات الحوض. تمرين الفراشة يفتح منطقة الحوض ويخفف الضغط. السباحة تقلل الالتهابات وترفع المزاج.'},
        {'title': 'يوغا لأيام الدورة', 'body': 'وضعية القطة والبقرة تحرك العمود الفقري وتخفف آلام الظهر. وضعية الحمامة تفتح الوركين وتقلل التوتر. وضعية الجسر ترفع الحوض وتنشط الدورة الدموية. التنفس العميق يهدئ الجهاز العصبي.'},
      ]},
      {'section': 'صحة نفسية', 'articles': [
        {'title': 'التعامل مع تقلبات المزاج', 'body': 'تقلبات المزاج قبل وأثناء الدورة طبيعية تماماً وسببها هرمونات الإستروجين والبروجستيرون. لا تلومي نفسك على مشاعرك. جربي الكتابة اليومية لتفريغ مشاعرك. تحدثي مع صديقة أو شخص تثقين به.'},
        {'title': 'نصائح للنوم الجيد أثناء الدورة', 'body': 'ضعي وسادة بين ركبتيك عند النوم على الجنب لتقليل ألم الظهر. استخدمي كمادة دافئة على البطن قبل النوم. تجنبي الشاشات ساعة قبل النوم. اشربي شاي البابونج الدافئ.'},
        {'title': 'متى تستشيرين الطبيبة؟', 'body': 'استشيري الطبيبة إذا: الألم شديد لدرجة عدم القدرة على ممارسة أنشطتك اليومية. النزيف غزير جداً. الدورة غير منتظمة. وجود إفرازات غير طبيعية. استمرار الألم بعد انتهاء الدورة.'},
      ]},
      {'section': 'نصائح عامة', 'articles': [
        {'title': 'تتبع الدورة: لماذا هو مهم؟', 'body': 'تتبع الدورة يساعدك على معرفة موعد الدورة القادمة والاستعداد لها. يمكنك التعرف على فترة الخصوبة إذا كنتِ تخططين للحمل. يساعد الطبيبة في تشخيص أي مشاكل صحية.'},
        {'title': 'خرافات شائعة عن الدورة الشهرية', 'body': 'خرافة: لا يمكنك ممارسة الرياضة أثناء الدورة. الحقيقة: الرياضة الخفيفة تخفف الألم. خرافة: لا يمكنك الاستحمام. الحقيقة: الاستحمام بماء دافئ يرخي العضلات.'},
        {'title': 'منتجات صحية بديلة', 'body': 'كأس الحيض: صديق للبيئة، يمكن استخدامه 12 ساعة متواصلة، يدوم سنوات. الملابس الداخلية الماصة: مريحة للنوم والأيام الخفيفة. الفوط القطنية العضوية: خالية من المواد الكيميائية.'},
      ]},
    ];

    for (final section in cycleArticles) {
      for (final a in (section['articles'] as List<Map<String, String>>)) {
        final ref = col.doc();
        batch.set(ref, {
          'title': a['title'], 'content': a['body'], 'category': section['section'],
          'type': 'cycle', 'imageUrl': '', 'contentImages': [],
          'createdAt': now, 'updatedAt': now, 'createdBy': uid,
        });
      }
    }

    // Baby articles
    final babyArticles = [
      {'section': 'تغذية الطفل', 'articles': [
        {'title': 'الرضاعة الطبيعية: أساس صحة طفلك', 'body': 'تُعد الرضاعة الطبيعية الغذاء الأمثل للرضيع في الأشهر الستة الأولى من حياته. يحتوي حليب الأم على جميع العناصر الغذائية والأجسام المضادة التي يحتاجها الطفل لبناء جهاز مناعي قوي.'},
        {'title': 'متى وكيف تبدئين بالأطعمة الصلبة', 'body': 'يمكن البدء بإدخال الأطعمة التكميلية عند بلوغ الطفل ستة أشهر، مع الاستمرار بالرضاعة الطبيعية. ابدئي بالأطعمة المهروسة الناعمة مثل الأرز المسلوق والخضروات المهروسة والفواكه.'},
        {'title': 'أطعمة يجب تجنبها في السنة الأولى', 'body': 'هناك أطعمة يجب تجنب تقديمها للطفل قبل إتمام عامه الأول لأسباب صحية وأمان. من أهمها: العسل الطبيعي الذي قد يسبب التسمم، وحليب البقر الكامل كبديل للرضاعة.'},
      ]},
      {'section': 'نوم الطفل', 'articles': [
        {'title': 'تنظيم نوم الرضيع: دليل شامل', 'body': 'ينام المولود الجديد ما بين 16 إلى 17 ساعة يومياً، لكن بفترات متقطعة. مع نموه، تتوحد فترات النوم تدريجياً. ضعي روتيناً ثابتاً قبل النوم يتضمن حماماً دافئاً وقراءة قصة قصيرة.'},
        {'title': 'بيئة النوم الآمنة للرضيع', 'body': 'سلامة بيئة نوم الرضيع أمر بالغ الأهمية للوقاية من متلازمة الموت المفاجئ. ضعي طفلك دائماً على ظهره للنوم، على سطح مستوٍ وثابت. أبعدي الوسائد والألعاب من سرير الطفل.'},
      ]},
      {'section': 'النمو والتطور', 'articles': [
        {'title': 'مراحل نمو الطفل في السنة الأولى', 'body': 'تمر السنة الأولى بتطورات مذهلة. في الشهر الثالث يبدأ الطفل بالابتسام والتتبع بالعينين. في الشهر السادس يجلس بمساعدة. بين الشهر السابع والتاسع يزحف ويبدأ بفهم الكلمات.'},
        {'title': 'تحفيز ذكاء طفلك باللعب', 'body': 'اللعب هو الطريقة الرئيسية التي يتعلم بها الطفل ويطور مهاراته. في الأشهر الأولى، يستفيد الطفل من الألعاب الحسية كالخشخاشات والألعاب الملونة ذات الأصوات المختلفة.'},
      ]},
      {'section': 'صحة الطفل العامة', 'articles': [
        {'title': 'الحمى عند الرضع: متى تقلقين', 'body': 'الحمى هي استجابة طبيعية من جسم الطفل لمكافحة العدوى. تُعتبر درجة الحرارة أعلى من 38 درجة مئوية حمى عند الرضيع. استشيري الطبيب فوراً إذا كان عمر الطفل أقل من ثلاثة أشهر.'},
        {'title': 'العناية ببشرة الطفل الحساسة', 'body': 'بشرة الرضيع رقيقة وحساسة وتحتاج عناية خاصة. استخدمي منتجات خالية من العطور والمواد الكيميائية القاسية المخصصة للأطفال. حممي طفلك مرتين إلى ثلاث مرات أسبوعياً.'},
      ]},
    ];

    for (final section in babyArticles) {
      for (final a in (section['articles'] as List<Map<String, String>>)) {
        final ref = col.doc();
        batch.set(ref, {
          'title': a['title'], 'content': a['body'], 'category': section['section'],
          'type': 'baby', 'imageUrl': '', 'contentImages': [],
          'createdAt': now, 'updatedAt': now, 'createdBy': uid,
        });
      }
    }

    // Home articles (news/general)
    final homeArticles = [
      {'section': 'صحة المرأة', 'articles': [
        {'title': 'فحوصات طبية لا غنى عنها لكل امرأة بعد سن الثلاثين', 'body': 'مع تقدم العمر، تصبح الفحوصات الدورية ضرورة وليست خياراً. بعد سن الثلاثين، يُنصح بإجراء فحص شامل للدم مرة سنوياً يشمل تحليل وظائف الغدة الدرقية، مستوى السكر في الدم، والدهون والكوليسترول. هذه الفحوصات البسيطة قد تكشف مشاكل صحية مبكراً قبل تفاقمها.\n\nفحص عنق الرحم (مسحة باب) يُوصى به كل ثلاث سنوات للنساء بين 21 و65 عاماً. هذا الفحص السريع وغير المؤلم يمكنه اكتشاف تغيرات خلوية مبكرة قبل أن تتحول إلى مشكلة صحية كبيرة. كما يُنصح بفحص الماموغرام للثدي بدءاً من سن الأربعين.\n\nفحص كثافة العظام مهم خاصة للنساء اللواتي لديهن تاريخ عائلي لهشاشة العظام. فيتامين D والكالسيوم ضروريان لصحة العظام. اطلبي من طبيبتك فحص مستوى فيتامين D في دمك، فنقصه شائع جداً ويؤثر على المزاج والمناعة والعظام.\n\nلا تنسي فحص ضغط الدم بانتظام، خاصة إذا كنتِ تستخدمين موانع حمل هرمونية. ارتفاع الضغط الصامت يمكن أن يسبب مضاعفات خطيرة على القلب والكلى دون أعراض واضحة.'},
        {'title': 'اضطرابات الغدة الدرقية: العدو الخفي لصحة المرأة', 'body': 'تصاب النساء باضطرابات الغدة الدرقية بمعدل خمس إلى ثماني مرات أكثر من الرجال. الغدة الدرقية هي غدة صغيرة على شكل فراشة في مقدمة الرقبة، لكنها تتحكم في عمليات حيوية كثيرة: الأيض، الطاقة، درجة الحرارة، الوزن، والمزاج.\n\nقصور الغدة الدرقية (خمول الغدة) يسبب: زيادة الوزن غير المبررة، التعب المزمن، الاكتئاب، جفاف الجلد، تساقط الشعر، عدم انتظام الدورة الشهرية، والشعور بالبرد المستمر. كثير من النساء يعانين من هذه الأعراض لسنوات دون تشخيص.\n\nفرط نشاط الغدة الدرقية يسبب العكس: فقدان الوزن السريع، تسارع نبضات القلب، القلق والتوتر المفرط، التعرق الزائد، والأرق. كلا الحالتين يمكن علاجهما بفعالية بالأدوية تحت إشراف طبي.\n\nإذا كنتِ تعانين من أي من هذه الأعراض، اطلبي من طبيبتك فحص TSH البسيط. التشخيص المبكر والعلاج المناسب يمكن أن يغير حياتك بالكامل ويعيد لكِ طاقتك وحيويتك.'},
        {'title': 'فقر الدم عند النساء: الأسباب والعلاج الفعال', 'body': 'فقر الدم من أكثر المشاكل الصحية شيوعاً بين النساء في سن الإنجاب. نزيف الدورة الشهرية الغزير هو السبب الأول، يليه سوء التغذية ونقص امتصاص الحديد. الأعراض تشمل التعب الشديد، شحوب البشرة، ضيق التنفس عند المجهود البسيط، والدوخة.\n\nعلاج فقر الدم يبدأ بتحديد السبب. إذا كان نقص الحديد، فالعلاج يشمل مكملات الحديد مع فيتامين C لتحسين الامتصاص. تناولي مكملات الحديد على معدة فارغة مع عصير برتقال، وتجنبي تناولها مع الشاي أو القهوة أو الحليب لأنها تقلل الامتصاص.\n\nالأطعمة الغنية بالحديد تشمل اللحوم الحمراء والكبد والسبانخ والعدس والفاصوليا والتمر. الحديد من مصادر حيوانية (حديد الهيم) يُمتص أفضل من الحديد النباتي. الطبخ في أواني حديد يزيد محتوى الحديد في الطعام.\n\nراجعي طبيبتك إذا استمر التعب رغم تناول مكملات الحديد لمدة شهرين، فقد يكون السبب نقص فيتامين B12 أو حمض الفوليك أو مشكلة في الامتصاص تحتاج فحوصات إضافية.'},
      ]},
      {'section': 'تغذية وجمال', 'articles': [
        {'title': '10 أطعمة خارقة لبشرة نضرة وشعر قوي', 'body': 'ما تأكلينه ينعكس مباشرة على بشرتك وشعرك. الأفوكادو غني بالدهون الصحية وفيتامين E الذي يحمي البشرة من التلف ويمنحها مرونة ونعومة. تناولي نصف حبة أفوكادو يومياً أو استخدميها كماسك طبيعي للوجه.\n\nالسلمون والأسماك الدهنية مصدر ممتاز لأوميغا 3 التي تقلل التهابات البشرة وتمنح الشعر لمعاناً طبيعياً. البيض يحتوي على البيوتين الضروري لنمو الشعر والأظافر. التوت بأنواعه مليء بمضادات الأكسدة التي تحارب شيخوخة البشرة.\n\nالبطاطا الحلوة غنية بالبيتا كاروتين الذي يتحول لفيتامين A ويجدد خلايا البشرة. الجوز واللوز يحتويان على فيتامين E والزنك الضروريين لصحة الجلد. البروكلي يحتوي على فيتامين C الذي يحفز إنتاج الكولاجين.\n\nالشاي الأخضر مضاد قوي للأكسدة ويحمي البشرة من أضرار أشعة الشمس. بذور الشيا والكتان غنية بأوميغا 3 والألياف. والماء أهم عنصر على الإطلاق — اشربي 8 أكواب يومياً للحفاظ على ترطيب بشرتك من الداخل.'},
        {'title': 'روتين العناية بالبشرة المثالي: صباحاً ومساءً', 'body': 'العناية بالبشرة لا تحتاج منتجات باهظة، بل روتين ثابت ومنتجات مناسبة لنوع بشرتك. الروتين الصباحي المثالي يبدأ بغسول لطيف يناسب بشرتك (رغوي للبشرة الدهنية، كريمي للجافة).\n\nبعد الغسول، ضعي تونر مرطب لموازنة حموضة البشرة. ثم سيروم فيتامين C الذي يفتح البشرة ويحميها من التلوث وأشعة الشمس. بعده مرطب خفيف يناسب نوع بشرتك. وأخيراً واقي الشمس SPF 30 على الأقل — وهو أهم خطوة في الروتين كله.\n\nالروتين المسائي يبدأ بمزيل مكياج (زيتي أو ماء ميسيلار) ثم غسول. استخدمي سيروم ريتينول مرتين أسبوعياً لتجديد الخلايا ومحاربة التجاعيد (ابدئي بتركيز منخفض). ثم كريم عيون وأخيراً مرطب ليلي أغنى من مرطب النهار.\n\nمرة أسبوعياً، قومي بتقشير لطيف وماسك ترطيب عميق. تجنبي لمس وجهك بيديك المتسختين، وغيري غطاء الوسادة أسبوعياً. النتائج تحتاج صبراً — التزمي بروتينك شهراً على الأقل لتري الفرق.'},
        {'title': 'أسرار الشعر الصحي: من الجذور إلى الأطراف', 'body': 'شعرك يعكس صحتك الداخلية. تساقط الشعر المفرط قد يكون علامة على نقص الحديد أو مشاكل الغدة الدرقية أو التوتر الشديد. قبل شراء منتجات باهظة، تأكدي من أن تغذيتك متوازنة وأن مستويات الحديد وفيتامين D طبيعية.\n\nالبروتين أساس صحة الشعر — تناولي البيض والدجاج والسمك والبقوليات يومياً. البيوتين (فيتامين B7) ضروري لنمو الشعر ويوجد في البيض والمكسرات والبطاطا الحلوة. الزنك يمنع تساقط الشعر ويوجد في اللحوم والحبوب الكاملة.\n\nلا تغسلي شعرك يومياً — مرتان إلى ثلاث مرات أسبوعياً تكفي. استخدمي ماء فاتر وليس ساخن، والماء البارد في الشطف الأخير لإغلاق طبقات الشعر ومنحه لمعاناً. جففي شعرك بمنشفة من المايكروفايبر بلطف دون فرك.\n\nقللي استخدام مجفف الشعر والمكواة قدر الإمكان. استخدمي واقي حراري دائماً. قصي أطراف شعرك كل 6-8 أسابيع لمنع التقصف. زيت جوز الهند أو الأرغان كماسك أسبوعي يصنع فرقاً كبيراً في نعومة وقوة الشعر.'},
      ]},
      {'section': 'صحة نفسية', 'articles': [
        {'title': 'إدارة التوتر والقلق: تقنيات فعالة للحياة اليومية', 'body': 'التوتر المزمن ليس مجرد إحساس مزعج — إنه يؤثر على كل جهاز في جسمك: يضعف المناعة، يرفع ضغط الدم، يسبب مشاكل هضمية، ويؤثر على الهرمونات والدورة الشهرية. تعلم إدارة التوتر مهارة حياتية ضرورية.\n\nتقنية التنفس المربع: استنشقي لمدة 4 ثوانٍ، احبسي النفس 4 ثوانٍ، ازفري 4 ثوانٍ، انتظري 4 ثوانٍ. كرري هذه الدورة 4 مرات. هذه التقنية البسيطة تنشط الجهاز العصبي السمبثاوي وتهدئ جسمك في دقيقتين فقط.\n\nالتأمل الذهني (Mindfulness) لا يحتاج وقتاً طويلاً — 5 دقائق صباحاً تكفي. اجلسي بهدوء، أغمضي عينيك، وركزي على تنفسك. عندما تشرد أفكارك (وستشرد)، أعيدي تركيزك بلطف دون حكم على نفسك. التطبيقات المجانية مثل Insight Timer يمكن أن تساعدك.\n\nالحركة الجسدية أقوى مضاد طبيعي للتوتر. لا تحتاجين صالة رياضية — المشي 20 دقيقة في الهواء الطلق، اليوغا، أو حتى الرقص في غرفتك يفرز الإندورفين ويحسن المزاج فوراً. اجعلي الحركة عادة يومية وليست خياراً.'},
        {'title': 'النوم الصحي: مفتاح الصحة النفسية والجسدية', 'body': 'النوم ليس رفاهية — إنه حاجة بيولوجية أساسية. خلال النوم يقوم جسمك بإصلاح الأنسجة، تقوية المناعة، تثبيت الذكريات، وتنظيم الهرمونات. قلة النوم المزمنة ترتبط بزيادة الوزن، ضعف المناعة، الاكتئاب، ومشاكل القلب.\n\nالنوم المثالي للبالغين 7-9 ساعات. لكن الجودة أهم من الكمية. للحصول على نوم عميق: ثبتي موعد النوم والاستيقاظ حتى في الإجازات. تجنبي الكافيين بعد الساعة 2 ظهراً. تجنبي الشاشات ساعة قبل النوم (الضوء الأزرق يثبط هرمون الميلاتونين).\n\nاجعلي غرفة نومك مظلمة وباردة (18-20 درجة) وهادئة. استثمري في مرتبة ووسادة مريحة. إذا لم تستطيعي النوم خلال 20 دقيقة، انهضي واقرئي كتاباً (ورقي وليس إلكتروني) حتى تشعري بالنعاس.\n\nالقيلولة المثالية لا تتجاوز 20-30 دقيقة وتكون قبل الساعة 3 عصراً. القيلولة الطويلة أو المتأخرة تؤثر على نوم الليل. إذا كنتِ تعانين من أرق مزمن رغم اتباع هذه النصائح، استشيري طبيبتك فقد يكون السبب قلق أو اكتئاب يحتاج علاج.'},
      ]},
      {'section': 'أمومة وطفولة', 'articles': [
        {'title': 'التربية الإيجابية: كيف تربين طفلاً واثقاً وسعيداً', 'body': 'التربية الإيجابية لا تعني الإفراط في التدليل أو غياب الحدود — بل تعني بناء علاقة محترمة مع طفلك قائمة على الحب والتفهم مع وضع قواعد واضحة ومتسقة. الأبحاث تؤكد أن الأطفال الذين يُربَّون بأسلوب إيجابي أكثر ثقة واستقلالية وأقل عرضة للمشاكل السلوكية.\n\nبدلاً من العقاب، استخدمي العواقب المنطقية. إذا رمى الطفل طعامه، ارفعي الطبق بهدوء وقولي "يبدو أنك لست جائعاً". هذا يعلمه المسؤولية دون إذلال. بدلاً من "لا تركض!" قولي "امشِ بهدوء" — الدماغ يستجيب للتوجيهات الإيجابية أفضل من النفي.\n\nامنحي طفلك خيارات محدودة: "هل تريد ارتداء القميص الأحمر أم الأزرق؟" هذا يمنحه إحساساً بالسيطرة ويقلل صراعات السلطة. اعترفي بمشاعره حتى لو لم تقبلي سلوكه: "أفهم أنك غاضب لأن أخاك أخذ لعبتك، لكن الضرب ممنوع".\n\nوأهم شيء: اعتني بنفسك أولاً. الأم المرهقة والمتوترة لا يمكنها تقديم أفضل تربية. خذي وقتاً لنفسك دون الشعور بالذنب. اطلبي المساعدة عندما تحتاجينها. أنتِ لستِ مضطرة لأن تكوني أماً مثالية — يكفي أن تكوني أماً حاضرة ومحبة.'},
        {'title': 'تعزيز المناعة الطبيعية عند الأطفال', 'body': 'جهاز المناعة عند الأطفال يتطور تدريجياً خلال السنوات الأولى. بدلاً من محاولة حماية طفلك من كل جرثومة، ساعديه على بناء جهاز مناعي قوي. الرضاعة الطبيعية في الأشهر الستة الأولى تمنح الطفل أجساماً مضادة قوية من الأم.\n\nالتغذية السليمة أساس المناعة القوية. الفواكه والخضروات الملونة غنية بمضادات الأكسدة وفيتامين C. الزبادي والأطعمة المخمرة تحتوي على بكتيريا نافعة تقوي صحة الأمعاء (التي تحتوي على 70% من جهاز المناعة). العسل بعد عمر السنة مضاد طبيعي للبكتيريا.\n\nالنوم الكافي ضروري — الأطفال يحتاجون 10-14 ساعة حسب العمر. خلال النوم ينتج الجسم بروتينات تحارب العدوى. اللعب في الهواء الطلق يعرض الطفل لأشعة الشمس (فيتامين D) وتنوع بيئي يقوي المناعة.\n\nالنظافة مهمة لكن المبالغة فيها ضارة. اغسلي يدي طفلك بالماء والصابون العادي — المطهرات المضادة للبكتيريا قد تقتل البكتيريا النافعة أيضاً. دعي طفلك يلعب في التراب أحياناً — التعرض المبكر للجراثيم يقوي الجهاز المناعي على المدى البعيد.'},
      ]},
      {'section': 'رياضة ولياقة', 'articles': [
        {'title': 'تمارين منزلية فعالة في 15 دقيقة يومياً', 'body': 'لا تحتاجين صالة رياضية أو معدات لتحافظي على لياقتك. 15 دقيقة من التمارين المكثفة يومياً يمكن أن تحدث فرقاً كبيراً في صحتك ومزاجك. المفتاح هو الانتظام وليس المدة.\n\nابدئي بالإحماء: 2 دقيقة مشي في المكان مع رفع الركبتين. ثم 3 دقائق سكوات (القرفصاء): قفي بعرض الكتفين، انزلي كأنك تجلسين على كرسي، 15 تكرار × 3 مجموعات. هذا التمرين يقوي الساقين والمؤخرة ويحرق سعرات حرارية كثيرة.\n\nتمرين البلانك: ابقي في وضع الضغط مع الاستناد على الساعدين. ابدئي بـ 20 ثانية وزيدي تدريجياً. هذا التمرين يقوي عضلات البطن والظهر والأكتاف. تمرين الضغط المعدل (على الركبتين): 10 تكرارات × 3 مجموعات.\n\nاختمي بتمارين تمدد: مددي كل مجموعة عضلية 20-30 ثانية. التمدد يقلل الإصابات ويحسن المرونة ويهدئ الجهاز العصبي. إذا شعرتِ بعدم الرغبة في التمرين، قولي لنفسك "سأبدأ بدقيقتين فقط" — غالباً ما ستستمرين بعد البداية.'},
        {'title': 'المشي: الرياضة المثالية للمرأة العصرية', 'body': 'المشي هو الرياضة الأكثر أماناً وفعالية للنساء من جميع الأعمار. لا يحتاج معدات خاصة أو خبرة سابقة أو مستوى لياقة عالٍ. الأبحاث تؤكد أن 30 دقيقة مشي يومياً تقلل خطر أمراض القلب بنسبة 30-40%.\n\nفوائد المشي تتجاوز اللياقة البدنية: يخفض التوتر والقلق، يحسن المزاج بفضل إفراز الإندورفين، يحسن نوعية النوم، ويقوي العظام ويقلل خطر هشاشة العظام. المشي في الطبيعة (الحدائق أو الشاطئ) يضاعف الفوائد النفسية.\n\nلجعل المشي أكثر فعالية: ارتدي حذاءً مريحاً وداعماً. امشي بخطوات سريعة بحيث يمكنك التحدث لكن بصعوبة. حركي ذراعيك بنشاط. حافظي على استقامة الظهر والرأس مرفوع.\n\nلزيادة الحرق: أضيفي فترات مشي سريع (دقيقة سريعة ثم دقيقة معتدلة). امشي على منحدرات أو درج. احملي أوزاناً خفيفة. المشي 10,000 خطوة يومياً هدف ممتاز — ابدئي بما تستطيعين وزيدي تدريجياً 500 خطوة أسبوعياً.'},
      ]},
      {'section': 'وصفات صحية', 'articles': [
        {'title': 'وجبات فطور صحية وسريعة للمرأة العاملة', 'body': 'الفطور أهم وجبة في اليوم — يمنحك الطاقة ويمنع الإفراط في الأكل لاحقاً. لكن ضيق الوقت صباحاً يجعل كثيرات يتخطين هذه الوجبة. إليك وجبات تُحضَّر في 5 دقائق أو أقل.\n\nأوفرنايت أوتس (شوفان الليل): في الليلة السابقة، اخلطي نصف كوب شوفان مع كوب حليب (أو لبن زبادي) وملعقة عسل وملعقة بذور شيا. ضعيها في الثلاجة. في الصباح أضيفي فواكه طازجة ومكسرات. وجبة متكاملة بدون طبخ.\n\nسموذي أخضر: اخلطي في الخلاط: حفنة سبانخ + موزة مجمدة + ملعقة زبدة فول سوداني + كوب حليب لوز + ملعقة عسل. غني بالحديد والبروتين والألياف. يمكنك تحضير مكونات عدة أكواب مسبقاً في أكياس تجميد.\n\nتوست الأفوكادو: محمصي شريحة خبز أسمر، اهرسي نصف حبة أفوكادو فوقها، أضيفي رشة ملح وفلفل وليمون. يمكنك إضافة بيضة مسلوقة أو شرائح طماطم. بيض مخفوق مع خضار: اخفقي بيضتين مع حفنة سبانخ وطماطم مقطعة في المقلاة — جاهز في 3 دقائق.'},
        {'title': 'مشروبات ديتوكس طبيعية لتنقية الجسم', 'body': 'الجسم لديه آلية طبيعية للتخلص من السموم عبر الكبد والكلى. لكن بعض المشروبات يمكن أن تدعم هذه العملية وتحسن الهضم والبشرة والطاقة. الأهم هو الماء — اشربي 8-10 أكواب يومياً.\n\nماء الليمون الدافئ صباحاً: اعصري نصف ليمونة في كوب ماء دافئ واشربيه على الريق. ينشط الجهاز الهضمي، يعزز المناعة بفيتامين C، ويساعد على ترطيب الجسم بعد ساعات النوم الطويلة.\n\nمشروب الزنجبيل والكركم: ابشري قطعة زنجبيل طازج وملعقة كركم في كوب ماء ساخن. أضيفي عسل وليمون. مضاد قوي للالتهابات ويحسن الهضم ويقوي المناعة. يمكنك تحضيره بارداً في الصيف.\n\nماء الخيار والنعناع: قطعي خيارة وحفنة نعناع في إبريق ماء واتركيها في الثلاجة ليلة كاملة. مشروب منعش خالي من السعرات يرطب البشرة ويقلل الانتفاخ. الشاي الأخضر بارداً مع شرائح ليمون وزنجبيل — غني بمضادات الأكسدة ويعزز الأيض.'},
      ]},
      {'section': 'علاقات أسرية', 'articles': [
        {'title': 'التوازن بين العمل والحياة الأسرية: دليل عملي', 'body': 'التوازن المثالي بين العمل والحياة الأسرية هو خرافة — ما يمكنك تحقيقه هو تكامل مرن يتغير حسب مرحلة حياتك واحتياجات عائلتك. الخطوة الأولى هي التخلي عن الشعور بالذنب المستمر والاعتراف بأنك تبذلين أفضل ما لديك.\n\nضعي حدوداً واضحة: حددي ساعات عمل ثابتة والتزمي بها قدر الإمكان. عندما تكونين مع أطفالك، ضعي الهاتف جانباً وكوني حاضرة فعلاً. الجودة أهم من الكمية — 30 دقيقة من اللعب المركز مع طفلك أفضل من ساعات وأنتِ مشغولة بالهاتف.\n\nرتبي أولوياتك: ليس كل شيء مهم بنفس القدر. استخدمي قاعدة "الثلاثة" — كل يوم، حددي ثلاث مهام فقط يجب إنجازها. الباقي يمكن تأجيله. تعلمي قول "لا" دون الشعور بالذنب — قبول كل طلب يعني التضحية بشيء آخر.\n\nاطلبي المساعدة واقبليها: تقاسمي المهام المنزلية مع شريكك. لا يجب أن تفعلي كل شيء بنفسك. إذا كان متاحاً، استعيني بمساعدة في التنظيف أو الطبخ. هذا ليس ضعفاً — بل ذكاء وإدارة لمواردك.'},
        {'title': 'التواصل الفعال مع الشريك: أساس العلاقة الصحية', 'body': 'أغلب مشاكل العلاقات الزوجية سببها ليس عدم الحب بل سوء التواصل. تعلم مهارات التواصل الفعال يمكن أن يحوّل علاقتك بالكامل. القاعدة الأولى: استمعي لتفهمي وليس لتردي.\n\nعندما تريدين التعبير عن مشاعرك، استخدمي صيغة "أنا" بدلاً من "أنت": قولي "أشعر بالإهمال عندما لا تسألني عن يومي" بدلاً من "أنت لا تهتم بي". الصيغة الأولى تعبر عن مشاعرك دون اتهام، والثانية تضع الشريك في موقف دفاعي.\n\nاختاري الوقت المناسب للمحادثات المهمة: ليس عندما يكون أحدكما جائعاً أو متعباً أو مشغولاً. اتفقا على "موعد حوار" أسبوعي تناقشان فيه أي مشاكل بهدوء. حافظا على اللطف حتى أثناء الخلاف — الإهانات والصراخ لا تحل أي مشكلة.\n\nلا تتوقعي أن شريكك يقرأ أفكارك — عبّري عن احتياجاتك بوضوح ولطف. قدّري الأشياء الصغيرة التي يفعلها وعبّري عن امتنانك. الشكر والتقدير وقود العلاقة الصحية. وتذكري أن كل علاقة تحتاج جهداً مستمراً من الطرفين.'},
      ]},
      {'section': 'نصائح طبية', 'articles': [
        {'title': 'الصداع النصفي عند النساء: فهم وعلاج', 'body': 'الصداع النصفي (الشقيقة) يصيب النساء ثلاث مرات أكثر من الرجال بسبب التقلبات الهرمونية. كثير من النساء يعانين من نوبات شقيقة قبل أو أثناء الدورة الشهرية. الألم يكون عادة في جانب واحد من الرأس، نابض، ويصاحبه غثيان وحساسية للضوء والصوت.\n\nالمحفزات الشائعة تشمل: التوتر، قلة النوم أو كثرته، تخطي الوجبات، الكافيين الزائد أو انسحابه المفاجئ، الجبن القديم والشوكولاتة والنبيذ الأحمر. احتفظي بدفتر لتتبع المحفزات ونمط النوبات.\n\nالعلاج الفوري: عند الإحساس بقدوم النوبة، تناولي مسكن الألم فوراً (لا تنتظري حتى يشتد). استلقي في غرفة مظلمة وهادئة. كمادة باردة على الجبهة أو خلف الرقبة قد تساعد. الكافيين بكمية قليلة (كوب قهوة) في بداية النوبة قد يساعد في تخفيفها.\n\nإذا كانت النوبات تتكرر أكثر من 4 مرات شهرياً أو تؤثر على حياتك اليومية، استشيري طبيبة الأعصاب. هناك أدوية وقائية فعالة يمكنها تقليل عدد النوبات وشدتها بشكل كبير. العلاجات الجديدة مثل أدوية Anti-CGRP حققت نتائج ممتازة.'},
        {'title': 'التهابات المسالك البولية: وقاية وعلاج', 'body': 'التهاب المسالك البولية من أكثر الالتهابات شيوعاً عند النساء — نصف النساء تقريباً يصبن بها مرة واحدة على الأقل في حياتهن. الأعراض تشمل حرقة عند التبول، الحاجة المتكررة للتبول، ألم أسفل البطن، وأحياناً بول غائم أو دموي.\n\nالوقاية خير من العلاج: اشربي ماء كافٍ (8 أكواب يومياً) لطرد البكتيريا. تبولي فور الشعور بالحاجة ولا تحبسي البول. تبولي بعد العلاقة الزوجية فوراً. امسحي من الأمام للخلف بعد استخدام الحمام. ارتدي ملابس داخلية قطنية وتجنبي الملابس الضيقة.\n\nعصير التوت البري (Cranberry) قد يساعد في الوقاية لأنه يمنع البكتيريا من الالتصاق بجدار المثانة — لكنه ليس بديلاً عن المضاد الحيوي عند حدوث الالتهاب. البروبيوتيك (الزبادي والمخللات) يدعم البكتيريا النافعة ويقلل خطر العدوى.\n\nراجعي الطبيبة فوراً إذا ظهرت أعراض التهاب مع حمى أو ألم في الظهر أو الجانبين — قد يكون الالتهاب وصل للكلى ويحتاج علاجاً عاجلاً. لا تتناولي مضاداً حيوياً بدون وصفة طبية — الاستخدام العشوائي يسبب مقاومة البكتيريا.'},
      ]},
    ];

    for (final section in homeArticles) {
      for (final a in (section['articles'] as List<Map<String, String>>)) {
        final ref = col.doc();
        batch.set(ref, {
          'title': a['title'], 'content': a['body'], 'category': section['section'],
          'type': 'home', 'imageUrl': '', 'contentImages': [],
          'createdAt': now, 'updatedAt': now, 'createdBy': uid,
        });
      }
    }

    try {
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم رفع جميع المقالات بنجاح ✓'), backgroundColor: Color(0xFF00897B)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الرفع: $e'), backgroundColor: Colors.red));
      }
    }
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
  String _articleType = 'pregnancy'; // pregnancy, cycle, baby, home, news
  final _typeLabels = {'pregnancy': 'الحمل', 'cycle': 'الدورة الشهرية', 'baby': 'الطفل', 'home': 'الرئيسية', 'news': 'أخبار'};
  final _catsByType = <String, List<String>>{
    'pregnancy': ['تغذية', 'رياضة', 'صحة نفسية', 'نوم', 'جمال', 'نصائح عامة', 'صحة الجنين', 'ما بعد الولادة'],
    'cycle': ['تغذية أثناء الدورة', 'رياضة وحركة', 'صحة نفسية', 'نصائح عامة'],
    'baby': ['تغذية الطفل', 'نوم الطفل', 'النمو والتطور', 'صحة الطفل العامة'],
    'home': ['صحة المرأة', 'تغذية وجمال', 'صحة نفسية', 'أمومة وطفولة', 'رياضة ولياقة', 'وصفات صحية', 'علاقات أسرية', 'نصائح طبية'],
    'news': ['أرقام قياسية', 'معجزة طبية', 'حول العالم', 'قصص مدهشة', 'حالات نادرة', 'اكتشافات علمية'],
  };
  List<String> get _cats => _catsByType[_articleType] ?? _catsByType['pregnancy']!;
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
      _articleType = d['type'] ?? 'pregnancy';
      if (!_typeLabels.containsKey(_articleType)) _articleType = 'pregnancy';
      _category = d['category'] ?? _cats.first;
      if (!_cats.contains(_category)) _category = _cats.first;
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
        'type': _articleType,
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
        DropdownButtonFormField<String>(value: _articleType,
          decoration: InputDecoration(labelText: '\u0646\u0648\u0639 \u0627\u0644\u0645\u0642\u0627\u0644', prefixIcon: const Icon(Icons.category, color: _teal), filled: true, fillColor: _card,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
          items: _typeLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
          onChanged: (v) => setState(() {
            _articleType = v!;
            _category = _cats.first;
          })),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          key: ValueKey(_articleType), // rebuild when type changes
          value: _category,
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
class _UsersManagementScreen extends StatefulWidget {
  @override
  State<_UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<_UsersManagementScreen> {
  String _searchQuery = '';
  String _roleFilter = 'all'; // all, admin, supervisor, employee, user

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(centerTitle: true, title: const Text('👥 إدارة المستخدمات', style: TextStyle(fontWeight: FontWeight.bold, color: _text1)),
        backgroundColor: _card, foregroundColor: _teal, elevation: 0, surfaceTintColor: Colors.transparent),
      body: Column(children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'بحث بالاسم أو الإيميل...',
              prefixIcon: const Icon(Icons.search, color: _teal),
              filled: true, fillColor: _card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
          ),
        ),
        // Role filter chips
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _filterChip('الكل', 'all'),
              _filterChip('أدمن', 'owner'),
              _filterChip('مشرفة', 'supervisor'),
              _filterChip('موظفة', 'employee'),
              _filterChip('مستخدمة', 'user'),
            ],
          ),
        ),
        // Users list
        Expanded(child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snap) {
            if (!snap.hasData || snap.data!.docs.isEmpty) {
              return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('👥', style: TextStyle(fontSize: 60)),
                const SizedBox(height: 16),
                Text('لا توجد مستخدمات بعد', style: TextStyle(fontSize: 16, color: _text2)),
              ]));
            }
            var docs = snap.data!.docs;
            // Filter by search
            if (_searchQuery.isNotEmpty) {
              docs = docs.where((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final name = (d['name'] ?? '').toString().toLowerCase();
                final email = (d['email'] ?? '').toString().toLowerCase();
                return name.contains(_searchQuery) || email.contains(_searchQuery);
              }).toList();
            }
            // Filter by role
            if (_roleFilter != 'all') {
              docs = docs.where((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final role = d['role'] ?? 'user';
                return role == _roleFilter;
              }).toList();
            }
            if (docs.isEmpty) {
              return Center(child: Text('لا توجد نتائج', style: TextStyle(color: _text2)));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (_, i) {
                final doc = docs[i];
                final d = doc.data() as Map<String, dynamic>;
                final isBanned = d['isBanned'] == true;
                final role = d['role'] ?? 'user';
                final postsCount = d['postsCount'] ?? 0;
                final likesReceived = d['likesReceived'] ?? 0;
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => _UserProfileAdminScreen(userId: doc.id, userData: d),
                  )),
                  child: Container(
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
                        backgroundImage: (d['photoUrl'] != null && (d['photoUrl'] as String).isNotEmpty)
                            ? NetworkImage(d['photoUrl']) : null,
                        child: (d['photoUrl'] == null || (d['photoUrl'] as String).isEmpty)
                            ? Text((d['name'] ?? '?')[0].toUpperCase(), style: TextStyle(color: _teal, fontWeight: FontWeight.bold))
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Flexible(child: Text(d['name'] ?? 'بدون اسم', style: const TextStyle(fontWeight: FontWeight.bold, color: _text1),
                              maxLines: 1, overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 6),
                          _roleBadge(role),
                          if (isBanned) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                              child: const Text('محظورة', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ]),
                        const SizedBox(height: 2),
                        Text(d['email'] ?? '', style: TextStyle(fontSize: 11, color: _text2)),
                        const SizedBox(height: 4),
                        Row(children: [
                          Icon(Icons.article_outlined, size: 12, color: _text2),
                          const SizedBox(width: 3),
                          Text('$postsCount', style: TextStyle(fontSize: 11, color: _text2)),
                          const SizedBox(width: 10),
                          Icon(Icons.favorite_outline, size: 12, color: _text2),
                          const SizedBox(width: 3),
                          Text('$likesReceived', style: TextStyle(fontSize: 11, color: _text2)),
                          const SizedBox(width: 10),
                          Icon(Icons.access_time, size: 12, color: _text2),
                          const SizedBox(width: 3),
                          Text(_formatDate(d['createdAt']), style: TextStyle(fontSize: 11, color: _text2)),
                        ]),
                      ])),
                      const Icon(Icons.chevron_left, color: Colors.grey, size: 20),
                    ]),
                  ),
                );
              },
            );
          },
        )),
      ]),
    ));
  }

  Widget _filterChip(String label, String value) {
    final selected = _roleFilter == value;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : _text1)),
        selected: selected,
        selectedColor: _teal,
        backgroundColor: _card,
        onSelected: (_) => setState(() => _roleFilter = value),
      ),
    );
  }

  Widget _roleBadge(String role) {
    Color color;
    String label;
    switch (role) {
      case 'owner': color = Colors.deepPurple; label = 'أدمن'; break;
      case 'supervisor': color = Colors.blue; label = 'مشرفة'; break;
      case 'employee': color = Colors.orange; label = 'موظفة'; break;
      default: return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  String _formatDate(dynamic ts) {
    if (ts == null) return '';
    if (ts is Timestamp) {
      final d = ts.toDate();
      return '${d.year}/${d.month}/${d.day}';
    }
    return '';
  }
}

// ─── Admin User Profile Screen ───
class _UserProfileAdminScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;
  const _UserProfileAdminScreen({required this.userId, required this.userData});
  @override
  State<_UserProfileAdminScreen> createState() => _UserProfileAdminScreenState();
}

class _UserProfileAdminScreenState extends State<_UserProfileAdminScreen> {
  late Map<String, dynamic> _data;

  @override
  void initState() {
    super.initState();
    _data = Map.from(widget.userData);
  }

  String get _roleName {
    switch (_data['role'] ?? 'user') {
      case 'owner': return 'أدمن (مالك)';
      case 'supervisor': return 'مشرفة';
      case 'employee': return 'موظفة';
      default: return 'مستخدمة عادية';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBanned = _data['isBanned'] == true;
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        centerTitle: true,
        title: Text(_data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: _text1)),
        backgroundColor: _card, foregroundColor: _teal, elevation: 0, surfaceTintColor: Colors.transparent,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
        builder: (context, snap) {
          if (snap.hasData && snap.data!.exists) {
            _data = snap.data!.data() as Map<String, dynamic>;
          }
          return ListView(padding: const EdgeInsets.all(16), children: [
            // Profile header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: _teal.withOpacity(0.1),
                  backgroundImage: (_data['photoUrl'] != null && (_data['photoUrl'] as String).isNotEmpty)
                      ? NetworkImage(_data['photoUrl']) : null,
                  child: (_data['photoUrl'] == null || (_data['photoUrl'] as String).isEmpty)
                      ? Text((_data['name'] ?? '?')[0].toUpperCase(), style: TextStyle(fontSize: 28, color: _teal, fontWeight: FontWeight.bold))
                      : null,
                ),
                const SizedBox(height: 12),
                Text(_data['name'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _text1)),
                const SizedBox(height: 4),
                Text(_data['email'] ?? '', style: TextStyle(fontSize: 13, color: _text2)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isBanned ? Colors.red.withOpacity(0.1) : _teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(isBanned ? 'محظورة' : _roleName,
                    style: TextStyle(color: isBanned ? Colors.red : _teal, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ]),
            ),
            const SizedBox(height: 16),

            // Stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('النشاط', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _text1)),
                const SizedBox(height: 12),
                _statRow(Icons.article_outlined, 'المنشورات', '${_data['postsCount'] ?? 0}'),
                _statRow(Icons.favorite_outline, 'إعجابات مستلمة', '${_data['likesReceived'] ?? 0}'),
                _statRow(Icons.comment_outlined, 'التعليقات', '${_data['commentsCount'] ?? 0}'),
                _statRow(Icons.calendar_today, 'تاريخ الانضمام', _formatDate(_data['createdAt'])),
                _statRow(Icons.login, 'آخر دخول', _formatDate(_data['lastLoginAt'])),
                if (_data['cycleLength'] != null)
                  _statRow(Icons.loop, 'طول الدورة', '${_data['cycleLength']} يوم'),
                if (_data['pregnancyStartDate'] != null)
                  _statRow(Icons.pregnant_woman, 'بداية الحمل', _formatDate(_data['pregnancyStartDate'])),
                if (_data['babyName'] != null && (_data['babyName'] as String).isNotEmpty)
                  _statRow(Icons.child_care, 'اسم الطفل', _data['babyName']),
              ]),
            ),
            const SizedBox(height: 16),

            // User's posts
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('آخر المنشورات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _text1)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('community_posts')
                        .where('userId', isEqualTo: widget.userId)
                        .orderBy('createdAt', descending: true)
                        .limit(5)
                        .snapshots(),
                    builder: (ctx, postSnap) {
                      if (!postSnap.hasData || postSnap.data!.docs.isEmpty) {
                        return Center(child: Text('لا توجد منشورات', style: TextStyle(color: _text2)));
                      }
                      return ListView.builder(
                        itemCount: postSnap.data!.docs.length,
                        itemBuilder: (_, j) {
                          final p = postSnap.data!.docs[j].data() as Map<String, dynamic>;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(10)),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(p['content'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13, color: _text1)),
                              const SizedBox(height: 4),
                              Row(children: [
                                Icon(Icons.favorite, size: 12, color: Colors.pink.shade200),
                                const SizedBox(width: 3),
                                Text('${(p['likes'] as List?)?.length ?? 0}', style: TextStyle(fontSize: 11, color: _text2)),
                                const SizedBox(width: 10),
                                Text(_formatDate(p['createdAt']), style: TextStyle(fontSize: 11, color: _text2)),
                              ]),
                            ]),
                          );
                        },
                      );
                    },
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('إجراءات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _text1)),
                const SizedBox(height: 12),

                // Role change
                if (AdminService().hasPermission(Permission.manageStaff))
                  _actionButton(
                    icon: Icons.admin_panel_settings,
                    label: 'تغيير الدور',
                    color: Colors.deepPurple,
                    onTap: () => _showRoleDialog(),
                  ),
                const SizedBox(height: 8),

                // Ban/Unban
                if (AdminService().hasPermission(Permission.banUsers))
                  _actionButton(
                    icon: isBanned ? Icons.lock_open : Icons.block,
                    label: isBanned ? 'إلغاء الحظر' : 'حظر المستخدمة',
                    color: isBanned ? Colors.green : Colors.red,
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(isBanned ? 'إلغاء الحظر' : 'حظر المستخدمة'),
                          content: Text(isBanned ? 'هل تريد إلغاء حظر هذه المستخدمة؟' : 'هل أنت متأكد من حظر هذه المستخدمة؟'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(backgroundColor: isBanned ? Colors.green : Colors.red),
                              child: Text(isBanned ? 'إلغاء الحظر' : 'حظر', style: const TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({'isBanned': !isBanned});
                      }
                    },
                  ),
              ]),
            ),
            const SizedBox(height: 40),
          ]);
        },
      ),
    ));
  }

  Widget _statRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, size: 18, color: _teal),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 13, color: _text2)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _text1)),
      ]),
    );
  }

  Widget _actionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const Spacer(),
          Icon(Icons.chevron_left, color: color, size: 20),
        ]),
      ),
    );
  }

  void _showRoleDialog() {
    final currentRole = _data['role'] ?? 'user';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تغيير الدور'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('الدور الحالي: $_roleName', style: TextStyle(color: _text2, fontSize: 13)),
          const SizedBox(height: 16),
          _roleOption(ctx, 'مستخدمة عادية', 'user', currentRole),
          _roleOption(ctx, 'موظفة', 'employee', currentRole),
          _roleOption(ctx, 'مشرفة', 'supervisor', currentRole),
          _roleOption(ctx, 'أدمن (مالك)', 'owner', currentRole),
        ]),
      ),
    );
  }

  Widget _roleOption(BuildContext ctx, String label, String role, String current) {
    final selected = current == role;
    return ListTile(
      dense: true,
      leading: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
          color: selected ? _teal : Colors.grey),
      title: Text(label, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      onTap: () async {
        Navigator.pop(ctx);
        await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({'role': role});
        // Also update staff collection if promoting
        if (role != 'user') {
          await FirebaseFirestore.instance.collection('staff').doc(widget.userId).set({
            'email': _data['email'] ?? '',
            'name': _data['name'] ?? '',
            'role': role,
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
            'createdBy': FirebaseAuth.instance.currentUser?.uid ?? '',
          }, SetOptions(merge: true));
        } else {
          // Demoting: remove from staff
          await FirebaseFirestore.instance.collection('staff').doc(widget.userId).delete();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم تغيير الدور إلى: $label ✓'), backgroundColor: _teal));
        }
      },
    );
  }

  String _formatDate(dynamic ts) {
    if (ts == null) return '—';
    if (ts is Timestamp) {
      final d = ts.toDate();
      return '${d.year}/${d.month}/${d.day}';
    }
    return '—';
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
        // ─── التحكم بالإشعارات التلقائية المجدولة ───
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('الإشعارات التلقائية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _text1)),
            const SizedBox(height: 4),
            const Text('تشغيل/إيقاف الإشعارات المجدولة لكل المستخدمات', style: TextStyle(fontSize: 12, color: _text2)),
            const SizedBox(height: 6),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('app_config').doc('notifications').snapshots(),
              builder: (_, snap) {
                final data = snap.data?.data() as Map<String, dynamic>? ?? {};
                bool isOn(String k) => data[k] != false;
                void setFlag(String k, bool v) {
                  FirebaseFirestore.instance.collection('app_config').doc('notifications')
                      .set({k: v}, SetOptions(merge: true));
                }
                Widget tog(String key, String label, String emoji) => SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      activeColor: _teal,
                      title: Text('$emoji  $label', style: const TextStyle(fontSize: 14, color: _text1)),
                      value: isOn(key),
                      onChanged: (v) => setFlag(key, v),
                    );
                return Column(children: [
                  tog('water', 'تذكير شرب الماء', '\u{1f4a7}'),
                  tog('tips', 'نصائح يومية', '\u{1f4a1}'),
                  tog('pregnancy', 'متابعة الحمل والدورة', '\u{1f930}'),
                  tog('products', 'عروض ومنتجات المتجر', '\u{1f6cd}'),
                ]);
              },
            ),
          ]),
        ),
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

// ─────────────────────────────────────────────
// Dynamic Content Management (Firestore articles & products)
// ─────────────────────────────────────────────

class _DynamicContentScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المحتوى الجديد'),
          backgroundColor: const Color(0xFF00897B),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.article), text: 'مقالات'),
              Tab(icon: Icon(Icons.shopping_bag), text: 'منتجات'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _DynamicArticlesTab(),
            _DynamicProductsTab(),
          ],
        ),
      ),
    );
  }
}

class _DynamicArticlesTab extends StatelessWidget {
  static const _sections = ['home', 'cycle', 'pregnancy', 'baby', 'news'];
  static const _sectionLabels = {
    'home': 'الرئيسية',
    'cycle': 'الدورة',
    'pregnancy': 'الحمل',
    'baby': 'الطفل',
    'news': 'الأخبار',
  };

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: DynamicContentService.articlesRef
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        return Scaffold(
          body: docs.isEmpty
              ? const Center(child: Text('لا توجد مقالات جديدة بعد', style: TextStyle(fontSize: 16, color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    final section = _sectionLabels[d['section']] ?? d['section'] ?? '';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            d['image'] ?? '',
                            width: 56, height: 56, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 56, height: 56, color: Colors.grey[200],
                              child: const Icon(Icons.image, color: Colors.grey),
                            ),
                          ),
                        ),
                        title: Text(d['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('$section • ${d['category'] ?? ''}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('حذف المقال'),
                                content: const Text('هل أنت متأكد من حذف هذا المقال؟'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    child: const Text('حذف', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await DynamicContentService.deleteArticle(docs[i].id);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF00897B),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('إضافة مقال', style: TextStyle(color: Colors.white)),
            onPressed: () => _showAddArticleSheet(context),
          ),
        );
      },
    );
  }

  void _showAddArticleSheet(BuildContext context) {
    final titleC = TextEditingController();
    final contentC = TextEditingController();
    final imageC = TextEditingController();
    final categoryC = TextEditingController();
    String selectedSection = 'home';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('إضافة مقال جديد', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(controller: titleC, decoration: InputDecoration(
                  labelText: 'عنوان المقال *', filled: true, fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                const SizedBox(height: 12),
                TextField(controller: contentC, maxLines: 4, decoration: InputDecoration(
                  labelText: 'محتوى المقال *', filled: true, fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                const SizedBox(height: 12),
                TextField(controller: imageC, decoration: InputDecoration(
                  labelText: 'رابط الصورة *', filled: true, fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                const SizedBox(height: 12),
                TextField(controller: categoryC, decoration: InputDecoration(
                  labelText: 'التصنيف *', filled: true, fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedSection,
                  decoration: InputDecoration(
                    labelText: 'القسم', filled: true, fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                  items: _sections.map((s) => DropdownMenuItem(value: s, child: Text(_sectionLabels[s] ?? s))).toList(),
                  onChanged: (v) => setState(() => selectedSection = v ?? 'home'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (titleC.text.trim().isEmpty || contentC.text.trim().isEmpty ||
                        imageC.text.trim().isEmpty || categoryC.text.trim().isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('يرجى ملء جميع الحقول المطلوبة')));
                      return;
                    }
                    await DynamicContentService.addArticle(
                      title: titleC.text.trim(),
                      content: contentC.text.trim(),
                      image: imageC.text.trim(),
                      category: categoryC.text.trim(),
                      section: selectedSection,
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم إضافة المقال بنجاح ✓'), backgroundColor: Color(0xFF00897B)));
                  },
                  child: const Text('إضافة المقال', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DynamicProductsTab extends StatelessWidget {
  static const _sections = ['home', 'cycle', 'pregnancy', 'baby', 'news'];
  static const _sectionLabels = {
    'home': 'الرئيسية',
    'cycle': 'الدورة',
    'pregnancy': 'الحمل',
    'baby': 'الطفل',
    'news': 'الأخبار',
  };

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: DynamicContentService.productsRef
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        return Scaffold(
          body: docs.isEmpty
              ? const Center(child: Text('لا توجد منتجات جديدة بعد', style: TextStyle(fontSize: 16, color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    final section = _sectionLabels[d['section']] ?? d['section'] ?? '';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            d['image'] ?? '',
                            width: 56, height: 56, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 56, height: 56, color: Colors.grey[200],
                              child: const Icon(Icons.shopping_bag, color: Colors.grey),
                            ),
                          ),
                        ),
                        title: Text(d['name'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('$section • ${d['category'] ?? ''} • ${d['price'] ?? ''}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('حذف المنتج'),
                                content: const Text('هل أنت متأكد من حذف هذا المنتج؟'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    child: const Text('حذف', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await DynamicContentService.deleteProduct(docs[i].id);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF00897B),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('إضافة منتج', style: TextStyle(color: Colors.white)),
            onPressed: () => _showAddProductSheet(context),
          ),
        );
      },
    );
  }

  void _showAddProductSheet(BuildContext context) {
    final nameC = TextEditingController();
    final imageC = TextEditingController();
    final priceC = TextEditingController();
    final categoryC = TextEditingController();
    final linkC = TextEditingController();
    String selectedSection = 'home';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('إضافة منتج جديد', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(controller: nameC, decoration: InputDecoration(
                  labelText: 'اسم المنتج *', filled: true, fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                const SizedBox(height: 12),
                TextField(controller: imageC, decoration: InputDecoration(
                  labelText: 'رابط الصورة *', filled: true, fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                const SizedBox(height: 12),
                TextField(controller: priceC, decoration: InputDecoration(
                  labelText: 'السعر *', filled: true, fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                const SizedBox(height: 12),
                TextField(controller: categoryC, decoration: InputDecoration(
                  labelText: 'التصنيف *', filled: true, fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                const SizedBox(height: 12),
                TextField(controller: linkC, decoration: InputDecoration(
                  labelText: 'رابط الشراء (اختياري)', filled: true, fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedSection,
                  decoration: InputDecoration(
                    labelText: 'القسم', filled: true, fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                  items: _sections.map((s) => DropdownMenuItem(value: s, child: Text(_sectionLabels[s] ?? s))).toList(),
                  onChanged: (v) => setState(() => selectedSection = v ?? 'home'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (nameC.text.trim().isEmpty || imageC.text.trim().isEmpty ||
                        priceC.text.trim().isEmpty || categoryC.text.trim().isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('يرجى ملء جميع الحقول المطلوبة')));
                      return;
                    }
                    await DynamicContentService.addProduct(
                      name: nameC.text.trim(),
                      image: imageC.text.trim(),
                      price: priceC.text.trim(),
                      category: categoryC.text.trim(),
                      section: selectedSection,
                      link: linkC.text.trim(),
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم إضافة المنتج بنجاح ✓'), backgroundColor: Color(0xFF00897B)));
                  },
                  child: const Text('إضافة المنتج', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// ─── Ads Management (owner/supervisor) ───
class _AdsManagementScreen extends StatefulWidget {
  @override
  State<_AdsManagementScreen> createState() => _AdsManagementScreenState();
}

class _AdsManagementScreenState extends State<_AdsManagementScreen> {
  final _titleC = TextEditingController();
  final _linkC = TextEditingController();
  final _imageC = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  Uint8List? _bytes;
  XFile? _file;
  bool _saving = false;
  final _priorityC = TextEditingController(text: '1');
  String _target = '';
  DateTime? _start;
  DateTime? _end;

  void _snack(String m, {Color c = const Color(0xFF00897B)}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: c));
  }

  Future<void> _pick() async {
    try {
      final f = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
      if (f != null) {
        final b = await f.readAsBytes();
        setState(() { _file = f; _bytes = b; _imageC.clear(); });
      }
    } catch (e) { _snack('تعذّر اختيار الصورة', c: Colors.red); }
  }

  Future<void> _add() async {
    final hasImg = _bytes != null || _imageC.text.trim().isNotEmpty;
    if (!hasImg) { _snack('أضف صورة للإعلان (رفع أو رابط)', c: Colors.orange); return; }
    setState(() => _saving = true);
    try {
      String image = _imageC.text.trim();
      if (_file != null && _bytes != null) {
        final ts = DateTime.now().millisecondsSinceEpoch;
        final ref = FirebaseStorage.instance.ref().child('ads/ad_$ts.jpg');
        await ref.putData(_bytes!, SettableMetadata(contentType: 'image/jpeg'));
        image = await ref.getDownloadURL();
      }
      final data = <String, dynamic>{
        'title': _titleC.text.trim(),
        'link': _linkC.text.trim(),
        'image': image,
        'active': true,
        'priority': int.tryParse(_priorityC.text.trim()) ?? 1,
        'target': _target,
        'impressions': 0,
        'clicks': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseAuth.instance.currentUser?.uid,
      };
      if (_start != null) data['startAt'] = Timestamp.fromDate(_start!);
      if (_end != null) data['endAt'] = Timestamp.fromDate(_end!);
      await FirebaseFirestore.instance.collection('ads').add(data);
      _titleC.clear(); _linkC.clear(); _imageC.clear(); _priorityC.text = '1';
      setState(() { _file = null; _bytes = null; _target = ''; _start = null; _end = null; });
      _snack('تمت إضافة الإعلان ✓');
    } catch (e) {
      _snack('خطأ: $e', c: Colors.red);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF00897B);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7FB),
        appBar: AppBar(title: const Text('\u{1F4E2} إدارة الإعلانات', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: const Color(0xFFAB47BC), foregroundColor: Colors.white),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('إضافة إعلان جديد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(controller: _titleC, decoration: const InputDecoration(labelText: 'عنوان الإعلان', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: _linkC, decoration: const InputDecoration(labelText: 'رابط الوجهة (URL)', hintText: 'https://...', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                Row(children: [
                  SizedBox(width: 110, child: TextField(controller: _priorityC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الأولوية', border: OutlineInputBorder()))),
                  const SizedBox(width: 10),
                  Expanded(child: DropdownButtonFormField<String>(
                    value: _target,
                    decoration: const InputDecoration(labelText: 'الاستهداف', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('كل الأماكن')),
                      DropdownMenuItem(value: 'news', child: Text('المقالات/الأخبار')),
                      DropdownMenuItem(value: 'pregnancy', child: Text('الحمل')),
                      DropdownMenuItem(value: 'cycle', child: Text('الدورة')),
                      DropdownMenuItem(value: 'baby', child: Text('الطفل')),
                      DropdownMenuItem(value: 'home', child: Text('الرئيسية')),
                      DropdownMenuItem(value: 'fertility', child: Text('رحلة الخصوبة')),
                    ],
                    onChanged: (v) => setState(() => _target = v ?? ''),
                  )),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.event, size: 18), label: Text(_start == null ? 'يبدأ: غير محدد' : 'يبدأ: ' + _start!.toString().substring(0,10)), onPressed: () async { final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime(2030)); if (d != null) setState(() => _start = d); })),
                  const SizedBox(width: 10),
                  Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.event_busy, size: 18), label: Text(_end == null ? 'ينتهي: غير محدد' : 'ينتهي: ' + _end!.toString().substring(0,10)), onPressed: () async { final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime(2030)); if (d != null) setState(() => _end = DateTime(d.year, d.month, d.day, 23, 59)); })),
                ]),
                const SizedBox(height: 12),
                const Text('صورة الإعلان', style: TextStyle(fontWeight: FontWeight.bold)),
                const Text('المقاس الأفضل: 1200×628 بكسل (أفقي، نسبة 1.91:1). أقل قبول 800×420.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                if (_bytes != null)
                  ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(_bytes!, height: 150, width: double.infinity, fit: BoxFit.cover))
                else if (_imageC.text.trim().isNotEmpty)
                  ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(_imageC.text.trim(), height: 150, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 150, color: teal.withOpacity(0.08), child: const Center(child: Icon(Icons.image, color: teal))))),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: OutlinedButton.icon(onPressed: _pick, icon: const Icon(Icons.upload), label: const Text('رفع صورة من الجهاز'))),
                ]),
                const SizedBox(height: 8),
                TextField(controller: _imageC, decoration: const InputDecoration(labelText: 'أو الصق رابط صورة', hintText: 'https://...', border: OutlineInputBorder()), onChanged: (_) => setState(() { _file = null; _bytes = null; })),
                const SizedBox(height: 14),
                SizedBox(width: double.infinity, child: ElevatedButton(
                  onPressed: _saving ? null : _add,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFAB47BC), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: _saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('➕ إضافة الإعلان', style: TextStyle(fontWeight: FontWeight.bold)),
                )),
              ]),
            ),
            const SizedBox(height: 20),
            const Text('الإعلانات الحالية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('ads').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snap) {
                if (snap.hasError) return Padding(padding: const EdgeInsets.all(12), child: Text('خطأ: ${snap.error}', style: const TextStyle(color: Colors.red)));
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('لا توجد إعلانات بعد — سيظهر منتج من المتجر تلقائياً.', style: TextStyle(color: Colors.grey)));
                return Column(children: docs.map((d) {
                  final a = d.data() as Map<String, dynamic>;
                  final on = a['active'] != false;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                    child: Row(children: [
                      ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network((a['image'] ?? '') as String, width: 84, height: 60, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 84, height: 60, color: teal.withOpacity(0.08), child: const Icon(Icons.image, color: teal)))),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text((a['title'] ?? 'إعلان') as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('👁 ' + '${a['impressions'] ?? 0}' + ' · 🖱 ' + '${a['clicks'] ?? 0}' + ' · أولوية ' + '${a['priority'] ?? 1}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ])),
                      Switch(value: on, activeColor: teal, onChanged: (v) => FirebaseFirestore.instance.collection('ads').doc(d.id).update({'active': v})),
                      IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () async {
                        final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('حذف الإعلان؟'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف', style: TextStyle(color: Colors.red)))]));
                        if (ok == true) FirebaseFirestore.instance.collection('ads').doc(d.id).delete();
                      }),
                    ]),
                  );
                }).toList());
              },
            ),
          ],
        ),
      ),
    );
  }
}
