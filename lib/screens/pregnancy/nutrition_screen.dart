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

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({Key? key}) : super(key: key);
  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, bool> _vitaminChecks = {};

  final _vitamins = [
    _Vitamin('حمض الفوليك', '400-800 ميكروغرام', 'يحمي من تشوهات الأنبوب العصبي', Icons.medication, Colors.green),
    _Vitamin('حديد', '27 ملغ', 'يمنع فقر الدم ويدعم نقل الأكسجين', Icons.water_drop, Colors.red),
    _Vitamin('كالسيوم', '1000 ملغ', 'يبني عظام وأسنان الجنين', Icons.fitness_center, Colors.blue),
    _Vitamin('فيتامين D', '600 وحدة', 'يساعد امتصاص الكالسيوم', Icons.wb_sunny, Colors.orange),
    _Vitamin('أوميغا 3 (DHA)', '200 ملغ', 'يدعم نمو دماغ وعيني الجنين', Icons.psychology, Colors.purple),
    _Vitamin('فيتامين C', '85 ملغ', 'يعزز المناعة ويساعد امتصاص الحديد', Icons.local_florist, Colors.amber),
    _Vitamin('زنك', '11 ملغ', 'يدعم نمو الخلايا والمناعة', Icons.shield, Colors.teal),
    _Vitamin('يود', '220 ميكروغرام', 'ضروري لنمو الغدة الدرقية', Icons.science, Colors.indigo),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadVitamins();
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<void> _loadVitamins() async {
    try {
      final doc = await _userDoc.get();
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final today = '${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';
      final vits = data['vitamin_tracker_$today'] as Map<String, dynamic>? ?? {};
      setState(() { _vitaminChecks = vits.map((k, v) => MapEntry(k, v as bool)); });
    } catch (_) {}
  }

  Future<void> _toggleVitamin(String name) async {
    final today = '${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';
    final newVal = !(_vitaminChecks[name] ?? false);
    setState(() { _vitaminChecks[name] = newVal; });
    await _userDoc.set({'vitamin_tracker_$today': {name: newVal}}, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: const Text('التغذية والفيتامينات', style: TextStyle(fontWeight: FontWeight.bold, color: _text1, fontSize: 20)),
          backgroundColor: _card, foregroundColor: _teal, elevation: 0, surfaceTintColor: Colors.transparent, centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            labelColor: _teal, unselectedLabelColor: _text2,
            indicatorColor: _teal, indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: const [Tab(text: 'الفيتامينات'), Tab(text: 'مسموح'), Tab(text: 'ممنوع')],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [_buildVitaminsTab(), _buildAllowedTab(), _buildForbiddenTab()],
        ),
      ),
    );
  }

  Widget _buildVitaminsTab() {
    final checked = _vitaminChecks.values.where((v) => v).length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Daily progress
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_teal, _teal.withOpacity(0.8)]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.medication, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('فيتامينات اليوم', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('$checked من ${_vitamins.length} مكتمل', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                  ])),
                  Text('${(checked / _vitamins.length * 100).toInt()}%',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _vitamins.isNotEmpty ? checked / _vitamins.length : 0,
                  minHeight: 8, backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ..._vitamins.map((v) {
          final isChecked = _vitaminChecks[v.name] == true;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: _card, borderRadius: BorderRadius.circular(16),
              border: isChecked ? Border.all(color: _teal.withOpacity(0.3)) : null,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: v.color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(v.icon, color: v.color, size: 22),
              ),
              title: Text(v.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _text1,
                decoration: isChecked ? TextDecoration.lineThrough : null)),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(v.dose, style: TextStyle(fontSize: 12, color: v.color, fontWeight: FontWeight.bold)),
                Text(v.benefit, style: TextStyle(fontSize: 11, color: _text2)),
              ]),
              trailing: GestureDetector(
                onTap: () => _toggleVitamin(v.name),
                child: Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: isChecked ? _teal : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isChecked ? _teal : Colors.grey[300]!, width: 2),
                  ),
                  child: isChecked ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                ),
              ),
              onTap: () => _toggleVitamin(v.name),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAllowedTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _foodCategory('البروتينات', Icons.egg, Colors.orange, [
          _FoodItem('الدجاج المطبوخ جيدًا', 'مصدر ممتاز للبروتين والحديد'),
          _FoodItem('السمك المطبوخ (سلمون، تونا خفيفة)', 'غني بأوميغا 3 لنمو الدماغ'),
          _FoodItem('البيض المطبوخ جيدًا', 'بروتين كامل وكولين للدماغ'),
          _FoodItem('البقوليات (عدس، فول، حمص)', 'حديد وحمض الفوليك وألياف'),
        ]),
        _foodCategory('الخضروات والفواكه', Icons.eco, Colors.green, [
          _FoodItem('السبانخ والبروكلي', 'حمض الفوليك وحديد وكالسيوم'),
          _FoodItem('البطاطا الحلوة', 'فيتامين A لنمو عيني الجنين'),
          _FoodItem('الأفوكادو', 'دهون صحية وحمض الفوليك'),
          _FoodItem('التوت والفراولة', 'مضادات أكسدة وفيتامين C'),
          _FoodItem('الموز', 'بوتاسيوم يخفف التشنجات'),
          _FoodItem('البرتقال والحمضيات', 'فيتامين C يعزز المناعة'),
        ]),
        _foodCategory('الحبوب والنشويات', Icons.breakfast_dining, Colors.amber, [
          _FoodItem('الشوفان', 'ألياف وحديد وطاقة مستدامة'),
          _FoodItem('الأرز البني والخبز الكامل', 'فيتامينات B والألياف'),
          _FoodItem('الكينوا', 'بروتين كامل وحديد'),
        ]),
        _foodCategory('الألبان', Icons.water_drop, Colors.blue, [
          _FoodItem('الحليب المبستر', 'كالسيوم وفيتامين D'),
          _FoodItem('الزبادي', 'بروبيوتيك وكالسيوم'),
          _FoodItem('الجبن المبستر', 'كالسيوم وبروتين'),
        ]),
        _foodCategory('المكسرات والبذور', Icons.grass, Colors.brown, [
          _FoodItem('الجوز', 'أوميغا 3 ودهون صحية'),
          _FoodItem('اللوز', 'كالسيوم وفيتامين E'),
          _FoodItem('بذور الشيا', 'ألياف وأوميغا 3 وكالسيوم'),
        ]),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildForbiddenTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Warning header
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.red[400], size: 28),
              const SizedBox(width: 12),
              Expanded(child: Text('تجنبي هذه الأطعمة أثناء الحمل لحماية صحتك وصحة جنينك',
                style: TextStyle(fontSize: 13, color: Colors.red[700], height: 1.4))),
            ],
          ),
        ),
        _dangerCategory('خطر عالي — تجنبي تمامًا', Colors.red, [
          _FoodItem('الكحول', 'يسبب تشوهات خلقية ومشاكل نمو خطيرة'),
          _FoodItem('اللحوم والأسماك النيئة (سوشي)', 'خطر التسمم بالليستيريا والسالمونيلا'),
          _FoodItem('البيض النيء أو غير المطبوخ', 'خطر السالمونيلا — تجنبي المايونيز المنزلي'),
          _FoodItem('الحليب والأجبان غير المبسترة', 'خطر الليستيريا التي تؤذي الجنين'),
          _FoodItem('سمك القرش والسيف وأبو سيف', 'مستويات عالية من الزئبق تضر بالدماغ'),
          _FoodItem('الكبد بكميات كبيرة', 'فيتامين A الزائد يسبب تشوهات'),
        ]),
        _dangerCategory('تقليل — استهلاك محدود', Colors.orange, [
          _FoodItem('الكافيين (قهوة، شاي، شوكولاتة)', 'حد أقصى 200 ملغ/يوم (كوب واحد قهوة)'),
          _FoodItem('التونا المعلبة', 'مرة واحدة أسبوعيًا بسبب الزئبق'),
          _FoodItem('الأعشاب الطبية', 'بعضها يسبب تقلصات — استشيري طبيبتك'),
          _FoodItem('الملح الزائد', 'يزيد احتباس السوائل وارتفاع الضغط'),
          _FoodItem('السكريات والحلويات', 'تزيد خطر سكري الحمل والوزن الزائد'),
          _FoodItem('الأطعمة المصنعة', 'مواد حافظة وصوديوم عالي'),
        ]),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _foodCategory(String title, IconData icon, Color color, List<_FoodItem> foods) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ]),
          const SizedBox(height: 12),
          ...foods.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 7, left: 8),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _text1)),
                Text(f.benefit, style: TextStyle(fontSize: 12, color: _text2, height: 1.4)),
              ])),
            ]),
          )),
        ],
      ),
    );
  }

  Widget _dangerCategory(String title, Color color, List<_FoodItem> foods) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04), borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.block, color: color, size: 22),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          ]),
          const SizedBox(height: 12),
          ...foods.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.close, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
                Text(f.benefit, style: TextStyle(fontSize: 12, color: _text2, height: 1.4)),
              ])),
            ]),
          )),
        ],
      ),
    );
  }
}

class _Vitamin {
  final String name, dose, benefit;
  final IconData icon;
  final Color color;
  const _Vitamin(this.name, this.dose, this.benefit, this.icon, this.color);
}

class _FoodItem {
  final String name, benefit;
  const _FoodItem(this.name, this.benefit);
}
