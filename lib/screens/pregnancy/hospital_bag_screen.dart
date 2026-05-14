import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const Color _bg = Color(0xFFFFF5F7);
const Color _card = Colors.white;
const Color _teal = Color(0xFF00897B);
const Color _pink = Color(0xFFE91E63);
const Color _text1 = Color(0xFF2D2D3A);
const Color _text2 = Color(0xFF6B7280);

DocumentReference get _userDoc {
  final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
  return FirebaseFirestore.instance.collection('users').doc(uid);
}

class HospitalBagScreen extends StatefulWidget {
  const HospitalBagScreen({Key? key}) : super(key: key);
  @override
  State<HospitalBagScreen> createState() => _HospitalBagScreenState();
}

class _HospitalBagScreenState extends State<HospitalBagScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, bool> _checkedItems = {};
  bool _loaded = false;

  final _categories = <_BagCategory>[
    _BagCategory('للأم', Icons.woman, Color(0xFFE91E63), [
      'قميص نوم مريح (2-3)',
      'روب حمام',
      'ملابس داخلية قطنية (5+)',
      'حمالة صدر للرضاعة (2)',
      'فوط صحية كبيرة بعد الولادة',
      'شبشب مريح',
      'جوارب دافئة',
      'ملابس للخروج من المستشفى',
      'أدوات النظافة (فرشاة أسنان، معجون، شامبو)',
      'مرطب شفاه',
      'ربطات شعر',
      'مناشف صغيرة',
      'وسادة مريحة (اختياري)',
      'نظارات (إن كنت تستخدمين عدسات)',
      'كريم مرطب',
      'مناديل مبللة',
    ]),
    _BagCategory('للطفل', Icons.child_care, Color(0xFF5C6BC0), [
      'ملابس داخلية (بودي) (4-5)',
      'أفرهول / سالوبيت (3-4)',
      'قبعة صغيرة (2)',
      'جوارب صغيرة (3 أزواج)',
      'بطانية ناعمة للف الطفل',
      'حفاضات لحديثي الولادة (عبوة)',
      'مناديل مبللة للأطفال',
      'كريم حفاضات',
      'مناشف قطنية صغيرة',
      'ملابس الخروج من المستشفى',
      'كرسي سيارة للطفل',
      'لهاية (اختياري)',
      'قنينة رضاعة (احتياطي)',
    ]),
    _BagCategory('للأب / المرافق', Icons.man, Color(0xFF00897B), [
      'ملابس مريحة للتبديل',
      'أغراض النظافة الشخصية',
      'شاحن هاتف + سلك طويل',
      'وجبات خفيفة ومشروبات',
      'كاميرا أو هاتف بشحن كامل',
      'نقود نثرية',
      'كتاب أو ترفيه للانتظار',
      'وسادة صغيرة (للانتظار الطويل)',
    ]),
    _BagCategory('أوراق مهمة', Icons.folder, Color(0xFFFF7043), [
      'بطاقة الهوية / جواز السفر',
      'بطاقة التأمين الصحي',
      'دفتر متابعة الحمل',
      'نتائج التحاليل والفحوصات',
      'صور السونار',
      'خطة الولادة (إن وجدت)',
      'أرقام الطوارئ المهمة',
      'عقد الزواج (بعض المستشفيات تطلبه)',
    ]),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadChecked();
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<void> _loadChecked() async {
    try {
      final doc = await _userDoc.get();
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final bag = data['hospital_bag'] as Map<String, dynamic>? ?? {};
      setState(() {
        _checkedItems = bag.map((k, v) => MapEntry(k, v as bool));
        _loaded = true;
      });
    } catch (_) {
      setState(() { _loaded = true; });
    }
  }

  Future<void> _toggleItem(String item) async {
    final newVal = !(_checkedItems[item] ?? false);
    setState(() { _checkedItems[item] = newVal; });
    await _userDoc.set({
      'hospital_bag': {item: newVal},
    }, SetOptions(merge: true));
  }

  int get _totalItems => _categories.fold(0, (s, c) => s + c.items.length);
  int get _checkedCount => _checkedItems.values.where((v) => v).length;
  double get _progress => _totalItems > 0 ? _checkedCount / _totalItems : 0;

  int _categoryChecked(int catIndex) {
    final cat = _categories[catIndex];
    return cat.items.where((i) => _checkedItems[i] == true).length;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: const Text('حقيبة الولادة', style: TextStyle(fontWeight: FontWeight.bold, color: _text1, fontSize: 20)),
          backgroundColor: _card, foregroundColor: _teal, elevation: 0, surfaceTintColor: Colors.transparent, centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: _teal,
            unselectedLabelColor: _text2,
            indicatorColor: _teal,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: _categories.map((c) => Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(c.icon, size: 18),
                const SizedBox(width: 6),
                Text(c.title),
              ]),
            )).toList(),
          ),
        ),
        body: !_loaded
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : Column(
              children: [
                // Progress header
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_teal, _teal.withOpacity(0.8)]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.card_travel, color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('تقدم التحضير', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                Text('$_checkedCount من $_totalItems عنصر', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                              ],
                            ),
                          ),
                          Text('${(_progress * 100).toInt()}%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: _progress, minHeight: 8,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: List.generate(_categories.length, (i) => _buildCategoryList(i)),
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildCategoryList(int catIndex) {
    final cat = _categories[catIndex];
    final checked = _categoryChecked(catIndex);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      children: [
        // Category progress
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: cat.color.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Icon(cat.icon, color: cat.color, size: 20),
              const SizedBox(width: 8),
              Text('${cat.title}: $checked/${cat.items.length}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cat.color)),
              const Spacer(),
              if (checked == cat.items.length)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: _teal, borderRadius: BorderRadius.circular(6)),
                  child: const Text('مكتمل!', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
        // Items
        ...cat.items.map((item) {
          final isChecked = _checkedItems[item] == true;
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(14),
              border: isChecked ? Border.all(color: _teal.withOpacity(0.3)) : null,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              leading: GestureDetector(
                onTap: () => _toggleItem(item),
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: isChecked ? _teal : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isChecked ? _teal : Colors.grey[300]!, width: 2),
                  ),
                  child: isChecked ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                ),
              ),
              title: Text(item, style: TextStyle(
                fontSize: 14, color: isChecked ? _text2 : _text1,
                decoration: isChecked ? TextDecoration.lineThrough : null,
              )),
              onTap: () => _toggleItem(item),
            ),
          );
        }),
      ],
    );
  }
}

class _BagCategory {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;
  const _BagCategory(this.title, this.icon, this.color, this.items);
}
