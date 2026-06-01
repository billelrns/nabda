import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

// ─── Theme ───
const Color _bg = Color(0xFFFFF5F7);
const Color _card = Colors.white;
const Color _teal = Color(0xFF00897B);
const Color _pink = Color(0xFFE91E63);
const Color _text1 = Color(0xFF2D2D3A);
const Color _text2 = Color(0xFF6B7280);
const Color _indigo = Color(0xFF5C6BC0);

DocumentReference get _userDoc {
  final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
  return FirebaseFirestore.instance.collection('users').doc(uid);
}

// ═══════════════════════════════════════════════
//  WEIGHT TRACKER SCREEN (Comprehensive)
// ═══════════════════════════════════════════════
class WeightTrackerScreen extends StatefulWidget {
  const WeightTrackerScreen({Key? key}) : super(key: key);
  @override
  State<WeightTrackerScreen> createState() => _WeightTrackerScreenState();
}

class _WeightTrackerScreenState extends State<WeightTrackerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // User profile data
  double _prePregnancyWeight = 0;
  double _height = 0; // cm
  int _currentWeek = 0;
  bool _isTwins = false;
  bool _profileLoaded = false;
  bool _needsSetup = false;

  // Weight entries
  List<_WeightEntry> _entries = [];
  bool _loadingEntries = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfile();
    _loadEntries();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final doc = await _userDoc.get();
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final wt = data['weight_tracker_profile'] as Map<String, dynamic>?;
      if (wt != null) {
        setState(() {
          _prePregnancyWeight = (wt['pre_weight'] as num?)?.toDouble() ?? 0;
          _height = (wt['height'] as num?)?.toDouble() ?? 0;
          _currentWeek = (wt['current_week'] as num?)?.toInt() ?? 0;
          _isTwins = wt['is_twins'] ?? false;
          _profileLoaded = true;
          _needsSetup = _prePregnancyWeight <= 0 || _height <= 0;
        });
      } else {
        // Try to get from onboarding data
        final pw = (data['prePregnancyWeight'] as num?)?.toDouble() ?? 0;
        final h = (data['height'] as num?)?.toDouble() ?? 0;
        final week = (data['pregnancyWeek'] as num?)?.toInt() ?? 0;
        setState(() {
          _prePregnancyWeight = pw;
          _height = h;
          _currentWeek = week;
          _profileLoaded = true;
          _needsSetup = pw <= 0 || h <= 0;
        });
      }
    } catch (_) {
      setState(() { _profileLoaded = true; _needsSetup = true; });
    }
  }

  Future<void> _loadEntries() async {
    try {
      final snap = await _userDoc.collection('weight_tracker')
          .orderBy('date', descending: false).get();
      setState(() {
        _entries = snap.docs.map((d) {
          final data = d.data();
          final ts = data['date'] as Timestamp?;
          return _WeightEntry(
            id: d.id,
            weight: (data['weight'] as num?)?.toDouble() ?? 0,
            date: ts?.toDate() ?? DateTime.now(),
            week: (data['week'] as num?)?.toInt() ?? 0,
          );
        }).toList();
        _loadingEntries = false;
      });
    } catch (_) {
      setState(() { _loadingEntries = false; });
    }
  }

  double get _bmi {
    if (_height <= 0 || _prePregnancyWeight <= 0) return 0;
    final hm = _height / 100;
    return _prePregnancyWeight / (hm * hm);
  }

  String get _bmiCategory {
    final b = _bmi;
    if (b <= 0) return '';
    if (b < 18.5) return 'نقص الوزن';
    if (b < 25) return 'وزن طبيعي';
    if (b < 30) return 'زيادة الوزن';
    return 'سمنة';
  }

  Color get _bmiColor {
    final b = _bmi;
    if (b < 18.5) return Colors.orange;
    if (b < 25) return _teal;
    if (b < 30) return Colors.orange;
    return Colors.red;
  }

  // Recommended total gain based on BMI (IOM guidelines)
  (double, double) get _recommendedTotalGain {
    final b = _bmi;
    if (_isTwins) {
      if (b < 18.5) return (22.7, 28.1);
      if (b < 25) return (16.8, 24.5);
      if (b < 30) return (14.1, 22.7);
      return (11.3, 19.1);
    }
    if (b < 18.5) return (12.5, 18.0);
    if (b < 25) return (11.5, 16.0);
    if (b < 30) return (7.0, 11.5);
    return (5.0, 9.0);
  }

  // Recommended weight for a given week
  (double, double) _recommendedWeightAtWeek(int week) {
    final (minGain, maxGain) = _recommendedTotalGain;
    // Linear interpolation over 40 weeks
    final minW = _prePregnancyWeight + (minGain * week / 40);
    final maxW = _prePregnancyWeight + (maxGain * week / 40);
    return (minW, maxW);
  }

  double? get _currentWeight => _entries.isNotEmpty ? _entries.last.weight : null;

  double get _totalGain {
    if (_currentWeight == null) return 0;
    return _currentWeight! - _prePregnancyWeight;
  }

  String get _weightStatus {
    if (_currentWeight == null || _currentWeek <= 0) return '';
    final (minW, maxW) = _recommendedWeightAtWeek(_currentWeek);
    if (_currentWeight! < minW) return 'أقل من المتوقع';
    if (_currentWeight! > maxW) return 'أعلى من المتوقع';
    return 'ضمن النطاق الطبيعي';
  }

  Color get _statusColor {
    final s = _weightStatus;
    if (s == 'ضمن النطاق الطبيعي') return _teal;
    if (s == 'أقل من المتوقع') return Colors.orange;
    if (s == 'أعلى من المتوقع') return Colors.red;
    return _text2;
  }

  Future<void> _saveProfile(double preWeight, double height, int week, bool twins) async {
    await _userDoc.set({
      'weight_tracker_profile': {
        'pre_weight': preWeight,
        'height': height,
        'current_week': week,
        'is_twins': twins,
      },
    }, SetOptions(merge: true));
    setState(() {
      _prePregnancyWeight = preWeight;
      _height = height;
      _currentWeek = week;
      _isTwins = twins;
      _needsSetup = false;
    });
  }

  Future<void> _addWeight(double weight) async {
    await _userDoc.collection('weight_tracker').add({
      'weight': weight,
      'date': FieldValue.serverTimestamp(),
      'week': _currentWeek,
    });
    await _loadEntries();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم تسجيل الوزن بنجاح'),
          backgroundColor: _teal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _deleteEntry(String id) async {
    await _userDoc.collection('weight_tracker').doc(id).delete();
    await _loadEntries();
  }

  void _showAddWeightDialog() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('تسجيل وزن جديد', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _text1)),
              const SizedBox(height: 8),
              Text('الأسبوع $_currentWeek من الحمل', style: TextStyle(fontSize: 14, color: _text2)),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _text1),
                decoration: InputDecoration(
                  hintText: '00.0',
                  hintStyle: TextStyle(fontSize: 32, color: Colors.grey[300]),
                  suffixText: 'كغ',
                  suffixStyle: const TextStyle(fontSize: 18, color: _text2),
                  filled: true,
                  fillColor: _bg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                ),
              ),
              const SizedBox(height: 8),
              if (_currentWeight != null)
                Text('آخر وزن مسجل: ${_currentWeight!.toStringAsFixed(1)} كغ', style: TextStyle(fontSize: 13, color: _text2)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    final w = double.tryParse(controller.text);
                    if (w != null && w >= 30 && w <= 200) {
                      Navigator.pop(ctx);
                      _addWeight(w);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('تسجيل الوزن', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSetupDialog() {
    final preWeightCtrl = TextEditingController(text: _prePregnancyWeight > 0 ? _prePregnancyWeight.toString() : '');
    final heightCtrl = TextEditingController(text: _height > 0 ? _height.toString() : '');
    final weekCtrl = TextEditingController(text: _currentWeek > 0 ? _currentWeek.toString() : '');
    bool twins = _isTwins;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) => Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 20),
                  const Text('إعداد تتبع الوزن', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _text1)),
                  const SizedBox(height: 8),
                  Text('نحتاج بعض المعلومات لحساب النطاق المثالي', style: TextStyle(fontSize: 13, color: _text2)),
                  const SizedBox(height: 24),
                  _setupField('الوزن قبل الحمل (كغ)', preWeightCtrl, 'مثال: 60'),
                  const SizedBox(height: 14),
                  _setupField('الطول (سم)', heightCtrl, 'مثال: 165'),
                  const SizedBox(height: 14),
                  _setupField('أسبوع الحمل الحالي', weekCtrl, 'مثال: 14'),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Expanded(child: Text('حمل توأم؟', style: TextStyle(fontSize: 15, color: _text1))),
                        Switch(value: twins, onChanged: (v) => setBS(() => twins = v), activeColor: _pink),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        final pw = double.tryParse(preWeightCtrl.text) ?? 0;
                        final h = double.tryParse(heightCtrl.text) ?? 0;
                        final w = int.tryParse(weekCtrl.text) ?? 0;
                        if (pw > 20 && h > 100 && w >= 0 && w <= 42) {
                          Navigator.pop(ctx);
                          _saveProfile(pw, h, w, twins);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('حفظ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _setupField(String label, TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true, fillColor: _bg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: const Text('تتبع الوزن', style: TextStyle(fontWeight: FontWeight.bold, color: _text1, fontSize: 20)),
          backgroundColor: _card,
          foregroundColor: _teal,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, size: 22),
              onPressed: _showSetupDialog,
              tooltip: 'الإعدادات',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: _teal,
            unselectedLabelColor: _text2,
            indicatorColor: _teal,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: const [
              Tab(text: 'نظرة عامة'),
              Tab(text: 'السجل'),
              Tab(text: 'نصائح صحية'),
            ],
          ),
        ),
        floatingActionButton: (!_needsSetup && _profileLoaded)
          ? FloatingActionButton.extended(
              onPressed: _showAddWeightDialog,
              backgroundColor: _pink,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('تسجيل الوزن', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        body: !_profileLoaded
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : _needsSetup
            ? _buildSetupPrompt()
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildRecordsTab(),
                  _buildHealthTipsTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildSetupPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                color: _pink.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.monitor_weight_outlined, size: 56, color: _pink),
            ),
            const SizedBox(height: 28),
            const Text('تتبع وزنك أثناء الحمل', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _text1)),
            const SizedBox(height: 12),
            Text(
              'تابعي زيادة وزنك لضمان صحتك وصحة جنينك.\nنحتاج بعض المعلومات للبدء.',
              style: TextStyle(fontSize: 14, color: _text2, height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _showSetupDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('ابدئي الآن', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  TAB 1: OVERVIEW
  // ═══════════════════════════════════════════════
  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        // Weight Chart
        _buildWeightChart(),
        const SizedBox(height: 16),
        // Stats Row
        _buildStatsRow(),
        const SizedBox(height: 16),
        // Status Card
        _buildStatusCard(),
        const SizedBox(height: 16),
        // BMI Card
        _buildBMICard(),
        const SizedBox(height: 16),
        // Recommended Range Table
        _buildRecommendedRangeCard(),
      ],
    );
  }

  Widget _buildWeightChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('مخطط الوزن', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _text1)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _teal.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('الأسبوع $_currentWeek', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _teal)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: CustomPaint(
              size: const Size(double.infinity, 220),
              painter: _WeightChartPainter(
                entries: _entries,
                preWeight: _prePregnancyWeight,
                recommendedGain: _recommendedTotalGain,
                currentWeek: _currentWeek,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(Colors.red, 'وزنك'),
              const SizedBox(width: 20),
              _legendDot(_teal.withOpacity(0.3), 'النطاق المتوقع'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: _text2)),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Row(
        children: [
          _statItem('البداية', '${_prePregnancyWeight.toStringAsFixed(1)} كغ', _indigo),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          _statItem('الحالي', _currentWeight != null ? '${_currentWeight!.toStringAsFixed(1)} كغ' : '---', _teal),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          _statItem('الزيادة', _currentWeight != null ? '${_totalGain >= 0 ? "+" : ""}${_totalGain.toStringAsFixed(1)} كغ' : '---',
            _totalGain > 0 ? Colors.orange : _teal),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: _text2)),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final (minW, maxW) = _recommendedWeightAtWeek(_currentWeek);
    final status = _weightStatus;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _statusColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                status == 'ضمن النطاق الطبيعي' ? Icons.check_circle : Icons.info_outline,
                color: _statusColor, size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _currentWeight != null
                    ? 'وزنك الحالي ${_currentWeight!.toStringAsFixed(1)} كغ — $status'
                    : 'لم يتم تسجيل أي وزن بعد',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('النطاق المتوقع لهذا الأسبوع', style: TextStyle(fontSize: 13, color: _text2)),
                Text('${minW.toStringAsFixed(1)} - ${maxW.toStringAsFixed(1)} كغ',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _teal)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBMICard() {
    if (_bmi <= 0) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('مؤشر كتلة الجسم قبل الحمل', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _text1)),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: _bmiColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(_bmi.toStringAsFixed(1), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _bmiColor)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_bmiCategory, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _bmiColor)),
                    const SizedBox(height: 4),
                    Text('الزيادة المثالية: ${_recommendedTotalGain.$1.toStringAsFixed(1)} - ${_recommendedTotalGain.$2.toStringAsFixed(1)} كغ',
                      style: TextStyle(fontSize: 12, color: _text2)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // BMI bar visualization
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(flex: 185, child: Container(color: Colors.blue[200])),
                  Expanded(flex: 65, child: Container(color: Colors.green[300])),
                  Expanded(flex: 50, child: Container(color: Colors.orange[300])),
                  Expanded(flex: 100, child: Container(color: Colors.red[300])),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('نقص', style: TextStyle(fontSize: 10, color: Colors.blue[400])),
              Text('طبيعي', style: TextStyle(fontSize: 10, color: Colors.green[600])),
              Text('زيادة', style: TextStyle(fontSize: 10, color: Colors.orange[600])),
              Text('سمنة', style: TextStyle(fontSize: 10, color: Colors.red[400])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedRangeCard() {
    final (minGain, maxGain) = _recommendedTotalGain;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('جدول الوزن المتوقع', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _text1)),
          const SizedBox(height: 6),
          Text('حسب فئة BMI الخاصة بك', style: TextStyle(fontSize: 12, color: _text2)),
          const SizedBox(height: 14),
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: _teal.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('الثلث', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _teal))),
                Expanded(flex: 3, child: Text('نطاق الوزن', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _teal), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('الزيادة', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _teal), textAlign: TextAlign.center)),
              ],
            ),
          ),
          _rangeRow('الأول (1-12)', _recommendedWeightAtWeek(12), (minGain * 12 / 40, maxGain * 12 / 40)),
          _rangeRow('الثاني (13-26)', _recommendedWeightAtWeek(26), (minGain * 26 / 40, maxGain * 26 / 40)),
          _rangeRow('الثالث (27-40)', _recommendedWeightAtWeek(40), (minGain, maxGain)),
        ],
      ),
    );
  }

  Widget _rangeRow(String trimester, (double, double) range, (double, double) gain) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[100]!))),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(trimester, style: const TextStyle(fontSize: 12, color: _text1))),
          Expanded(flex: 3, child: Text('${range.$1.toStringAsFixed(1)} - ${range.$2.toStringAsFixed(1)} كغ',
            style: const TextStyle(fontSize: 12, color: _text1), textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text('${gain.$1.toStringAsFixed(1)} - ${gain.$2.toStringAsFixed(1)} كغ',
            style: TextStyle(fontSize: 12, color: _teal), textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  TAB 2: RECORDS
  // ═══════════════════════════════════════════════
  Widget _buildRecordsTab() {
    if (_loadingEntries) {
      return const Center(child: CircularProgressIndicator(color: _teal));
    }
    if (_entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('لا توجد تسجيلات بعد', style: TextStyle(fontSize: 16, color: _text2)),
            const SizedBox(height: 8),
            Text('اضغطي "تسجيل الوزن" للبدء', style: TextStyle(fontSize: 13, color: _text2)),
          ],
        ),
      );
    }

    // Monthly variation chart data
    final monthlyData = <int, double>{};
    for (final e in _entries) {
      final key = e.date.month;
      if (!monthlyData.containsKey(key)) {
        monthlyData[key] = e.weight;
      } else {
        monthlyData[key] = e.weight; // last in month
      }
    }

    final reversed = _entries.reversed.toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        // Monthly bar chart
        if (_entries.length >= 2) ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('تغيرات الوزن الشهرية', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _text1)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 160,
                  child: CustomPaint(
                    size: const Size(double.infinity, 160),
                    painter: _MonthlyBarPainter(entries: _entries, preWeight: _prePregnancyWeight),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        // History header
        Row(
          children: [
            const Text('السجل', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _text1)),
            const Spacer(),
            Text('${_entries.length} تسجيل', style: TextStyle(fontSize: 13, color: _text2)),
          ],
        ),
        const SizedBox(height: 10),
        // History table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: _indigo.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
          child: const Row(
            children: [
              Expanded(flex: 2, child: Text('الوزن', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _indigo))),
              Expanded(flex: 2, child: Text('التاريخ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _indigo), textAlign: TextAlign.center)),
              Expanded(flex: 1, child: Text('الأسبوع', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _indigo), textAlign: TextAlign.center)),
              Expanded(flex: 2, child: Text('التغيير', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _indigo), textAlign: TextAlign.center)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        ...List.generate(reversed.length, (i) {
          final e = reversed[i];
          double? diff;
          if (i < reversed.length - 1) {
            diff = e.weight - reversed[i + 1].weight;
          }
          return Dismissible(
            key: Key(e.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20),
              decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.delete, color: Colors.red[400]),
            ),
            onDismissed: (_) => _deleteEntry(e.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _card,
                border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
              ),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text('${e.weight.toStringAsFixed(1)} كغ',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _text1))),
                  Expanded(flex: 2, child: Text('${e.date.day}/${e.date.month}/${e.date.year}',
                    style: TextStyle(fontSize: 13, color: _text2), textAlign: TextAlign.center)),
                  Expanded(flex: 1, child: Text('${e.week}',
                    style: TextStyle(fontSize: 13, color: _text2), textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: diff != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: diff > 0 ? Colors.orange.withOpacity(0.1) : diff < 0 ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${diff > 0 ? "+" : ""}${diff.toStringAsFixed(1)} كغ',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                            color: diff > 0 ? Colors.orange : diff < 0 ? Colors.blue : _text2),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : const SizedBox(),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  //  TAB 3: HEALTH TIPS
  // ═══════════════════════════════════════════════
  Widget _buildHealthTipsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        _tipCard(
          number: 1,
          title: 'لماذا تتبع الوزن مهم؟',
          icon: Icons.monitor_weight_outlined,
          content: 'تتبع الوزن أثناء الحمل يساعدك على:',
          points: [
            'دعم النمو الصحي لطفلك',
            'اكتشاف مشاكل مثل سكري الحمل مبكرًا',
            'توجيه التغذية المناسبة لك',
            'تقليل مضاعفات الولادة',
            'تسريع التعافي بعد الولادة',
          ],
        ),
        const SizedBox(height: 14),
        _tipCard(
          number: 2,
          title: 'الزيادة المثالية حسب BMI',
          icon: Icons.calculate_outlined,
          content: 'حسب إرشادات IOM الطبية:',
          tableData: [
            ['فئة BMI', 'النطاق', 'الزيادة المثالية'],
            ['نقص الوزن', 'أقل من 18.5', '12.5 - 18 كغ'],
            ['وزن طبيعي', '18.5 - 24.9', '11.5 - 16 كغ'],
            ['زيادة الوزن', '25 - 29.9', '7 - 11.5 كغ'],
            ['سمنة', '30 فما فوق', '5 - 9 كغ'],
          ],
        ),
        const SizedBox(height: 14),
        _tipCard(
          number: 3,
          title: 'توزيع الزيادة على الأثلاث',
          icon: Icons.timeline,
          content: 'الزيادة ليست خطية — تختلف حسب المرحلة:',
          tableData: [
            ['الثلث', 'الزيادة المتوقعة'],
            ['الأول (1-12)', '0.5 - 2 كغ (بسبب الغثيان)'],
            ['الثاني (13-26)', '~0.5 كغ/أسبوع (نمو سريع)'],
            ['الثالث (27-40)', '0.5 - 1 كغ/أسبوع'],
          ],
        ),
        const SizedBox(height: 14),
        _tipCard(
          number: 4,
          title: 'ماذا لو زاد وزنك كثيرًا؟',
          icon: Icons.trending_up,
          content: '',
          points: [
            'سجّلي ما تأكلين وتشربين يوميًا',
            'تناولي أطعمة غنية بالعناصر (خضروات، بروتين)',
            'مارسي رياضة خفيفة كالمشي والسباحة',
            'استشيري طبيبتك أو أخصائية تغذية',
          ],
        ),
        const SizedBox(height: 14),
        _tipCard(
          number: 5,
          title: 'ماذا لو كانت الزيادة قليلة؟',
          icon: Icons.trending_down,
          content: '',
          points: [
            'تناولي وجبات صغيرة ومتكررة',
            'اختاري وجبات خفيفة عالية السعرات (مكسرات، أفوكادو)',
            'حافظي على شرب الماء',
            'راقبي حركات الجنين ومستوى طاقتك',
            'استشيري طبيبتك إذا استمرت الزيادة ضعيفة',
          ],
        ),
        const SizedBox(height: 14),
        _tipCard(
          number: 6,
          title: 'أين يذهب الوزن الزائد؟',
          icon: Icons.child_care,
          content: 'ليس كل الوزن الزائد دهون — بل يدعم نمو طفلك:',
          points: [
            'الطفل: 3 - 4 كغ',
            'المشيمة: ~0.7 كغ',
            'السائل الأمنيوسي: ~1 كغ',
            'زيادة حجم الدم: ~1.5 - 1.8 كغ',
            'الثديان: ~0.5 - 1.4 كغ',
            'احتباس السوائل: ~1 - 1.4 كغ',
            'مخزون الدهون: ~2.7 - 3.6 كغ',
            'الرحم: ~1 كغ',
          ],
        ),
        const SizedBox(height: 14),
        _tipCard(
          number: 7,
          title: 'عوامل تؤثر على زيادة الوزن',
          icon: Icons.restaurant_menu,
          content: '',
          iconPoints: [
            (Icons.restaurant, 'التغذية: تناولي مزيجًا متوازنًا من البروتين والكربوهيدرات والدهون الصحية'),
            (Icons.fitness_center, 'النشاط البدني: يوغا الحمل والمشي والسباحة تساعد في إدارة الوزن'),
            (Icons.psychology, 'الوراثة: جسمك قد يخزن الطاقة بشكل مختلف — تابعي الاتجاه وليس الأرقام فقط'),
            (Icons.nightlight_round, 'النوم والتوتر: قلة النوم والتوتر يزيدان هرمونات الجوع'),
            (Icons.medical_services, 'الحالات الصحية: السكري ومشاكل الغدة قد تغير نمط الزيادة'),
          ],
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _tipCard({
    required int number,
    required String title,
    required IconData icon,
    String content = '',
    List<String>? points,
    List<List<String>>? tableData,
    List<(IconData, String)>? iconPoints,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('نصيحة $number', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _teal)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(icon, color: _indigo, size: 22),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _indigo))),
            ],
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(content, style: TextStyle(fontSize: 13, color: _text2, height: 1.5)),
          ],
          if (points != null) ...[
            const SizedBox(height: 10),
            ...points.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6, height: 6,
                    margin: const EdgeInsets.only(top: 6, left: 8),
                    decoration: BoxDecoration(color: _teal, shape: BoxShape.circle),
                  ),
                  Expanded(child: Text(p, style: const TextStyle(fontSize: 13, color: _text1, height: 1.5))),
                ],
              ),
            )),
          ],
          if (tableData != null) ...[
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[200]!)),
              child: Column(
                children: List.generate(tableData.length, (i) {
                  final row = tableData[i];
                  final isHeader = i == 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isHeader ? _indigo.withOpacity(0.08) : (i.isEven ? Colors.grey[50] : Colors.white),
                      borderRadius: i == 0
                        ? const BorderRadius.vertical(top: Radius.circular(9))
                        : i == tableData.length - 1
                          ? const BorderRadius.vertical(bottom: Radius.circular(9))
                          : null,
                    ),
                    child: Row(
                      children: row.map((c) => Expanded(
                        child: Text(c,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                            color: isHeader ? _indigo : _text1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )).toList(),
                    ),
                  );
                }),
              ),
            ),
          ],
          if (iconPoints != null) ...[
            const SizedBox(height: 10),
            ...iconPoints.map((ip) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: _indigo.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(ip.$1, color: _indigo, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(ip.$2, style: const TextStyle(fontSize: 13, color: _text1, height: 1.5))),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }
}

// ─── Weight Entry Model ───
class _WeightEntry {
  final String id;
  final double weight;
  final DateTime date;
  final int week;
  const _WeightEntry({required this.id, required this.weight, required this.date, required this.week});
}

// ═══════════════════════════════════════════════
//  WEIGHT CHART PAINTER
// ═══════════════════════════════════════════════
class _WeightChartPainter extends CustomPainter {
  final List<_WeightEntry> entries;
  final double preWeight;
  final (double, double) recommendedGain;
  final int currentWeek;

  _WeightChartPainter({
    required this.entries,
    required this.preWeight,
    required this.recommendedGain,
    required this.currentWeek,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (preWeight <= 0) return;

    final padding = const EdgeInsets.only(left: 40, right: 16, top: 10, bottom: 30);
    final chartW = size.width - padding.left - padding.right;
    final chartH = size.height - padding.top - padding.bottom;

    final totalWeeks = 40.0;
    final (minGain, maxGain) = recommendedGain;
    final minY = preWeight - 2;
    final maxY = preWeight + maxGain + 4;
    final yRange = maxY - minY;

    double toX(double week) => padding.left + (week / totalWeeks) * chartW;
    double toY(double weight) => padding.top + chartH - ((weight - minY) / yRange) * chartH;

    // Grid lines
    final gridPaint = Paint()..color = Colors.grey[200]!..strokeWidth = 0.5;
    final labelStyle = TextStyle(fontSize: 10, color: Colors.grey[400]);

    // Y axis labels
    final yStep = ((yRange) / 5).ceilToDouble();
    for (double y = minY; y <= maxY; y += yStep) {
      final py = toY(y);
      canvas.drawLine(Offset(padding.left, py), Offset(size.width - padding.right, py), gridPaint);
      final tp = TextPainter(text: TextSpan(text: '${y.toInt()}', style: labelStyle), textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(padding.left - tp.width - 6, py - tp.height / 2));
    }

    // X axis labels (trimesters)
    final trimesters = [
      (0, '0'), (13, '1T'), (26, '2T'), (40, '3T'),
    ];
    for (final (w, label) in trimesters) {
      final px = toX(w.toDouble());
      canvas.drawLine(Offset(px, padding.top), Offset(px, size.height - padding.bottom), gridPaint);
      final tp = TextPainter(text: TextSpan(text: label, style: TextStyle(fontSize: 11, color: Colors.red[400])), textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(px - tp.width / 2, size.height - padding.bottom + 8));
    }

    // Recommended range (shaded area)
    final rangePath = Path();
    for (int w = 0; w <= 40; w++) {
      final minW = preWeight + (minGain * w / 40);
      final x = toX(w.toDouble());
      final y = toY(minW);
      if (w == 0) rangePath.moveTo(x, y); else rangePath.lineTo(x, y);
    }
    for (int w = 40; w >= 0; w--) {
      final maxW = preWeight + (maxGain * w / 40);
      rangePath.lineTo(toX(w.toDouble()), toY(maxW));
    }
    rangePath.close();
    canvas.drawPath(rangePath, Paint()..color = const Color(0xFFE91E63).withOpacity(0.1));

    // Actual weight line
    if (entries.isNotEmpty) {
      final linePaint = Paint()
        ..color = Colors.red
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final dotPaint = Paint()..color = Colors.red;

      final allPoints = <Offset>[Offset(toX(0), toY(preWeight))];
      for (final e in entries) {
        allPoints.add(Offset(toX(e.week.toDouble()), toY(e.weight)));
      }

      final path = Path();
      path.moveTo(allPoints[0].dx, allPoints[0].dy);
      for (int i = 1; i < allPoints.length; i++) {
        path.lineTo(allPoints[i].dx, allPoints[i].dy);
      }
      canvas.drawPath(path, linePaint);

      // Dots
      for (final p in allPoints) {
        canvas.drawCircle(p, 5, dotPaint);
        canvas.drawCircle(p, 3, Paint()..color = Colors.white);
      }
    } else {
      // Draw starting point only
      final startPoint = Offset(toX(0), toY(preWeight));
      canvas.drawCircle(startPoint, 5, Paint()..color = Colors.red);
      canvas.drawCircle(startPoint, 3, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════
//  MONTHLY BAR CHART PAINTER
// ═══════════════════════════════════════════════
class _MonthlyBarPainter extends CustomPainter {
  final List<_WeightEntry> entries;
  final double preWeight;

  _MonthlyBarPainter({required this.entries, required this.preWeight});

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    final months = <int, double>{};
    for (final e in entries) {
      months[e.date.month] = e.weight - preWeight;
    }

    if (months.isEmpty) return;

    final monthNames = ['', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];

    final padding = const EdgeInsets.only(left: 30, right: 10, top: 20, bottom: 24);
    final chartH = size.height - padding.top - padding.bottom;
    final chartW = size.width - padding.left - padding.right;

    final sortedMonths = months.keys.toList()..sort();
    if (sortedMonths.isEmpty) return;

    final maxVal = months.values.reduce(max).abs();
    final barWidth = (chartW / max(sortedMonths.length, 1)) * 0.6;
    final gap = (chartW / max(sortedMonths.length, 1));

    for (int i = 0; i < sortedMonths.length; i++) {
      final m = sortedMonths[i];
      final val = months[m]!;
      final barH = maxVal > 0 ? (val.abs() / (maxVal + 2)) * chartH : 0.0;
      final x = padding.left + i * gap + (gap - barWidth) / 2;
      final y = padding.top + chartH - barH;

      final barPaint = Paint()..color = const Color(0xFFAB47BC).withOpacity(0.7);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x, y, barWidth, barH),
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
        ),
        barPaint,
      );

      // Value label
      final valTp = TextPainter(
        text: TextSpan(text: val.toStringAsFixed(1), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _text1)),
        textDirection: TextDirection.ltr,
      );
      valTp.layout();
      valTp.paint(canvas, Offset(x + barWidth / 2 - valTp.width / 2, y - valTp.height - 4));

      // Month label
      final mName = m <= 12 ? monthNames[m] : '$m';
      final short = mName.length > 4 ? mName.substring(0, 3) : mName;
      final mTp = TextPainter(
        text: TextSpan(text: short, style: TextStyle(fontSize: 10, color: _text2)),
        textDirection: TextDirection.rtl,
      );
      mTp.layout();
      mTp.paint(canvas, Offset(x + barWidth / 2 - mTp.width / 2, size.height - padding.bottom + 4));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
