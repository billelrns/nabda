import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/health_measurement_model.dart';
import '../../services/health_tracking_service.dart';
import 'dart:math' as math;

const Color _teal = Color(0xFF00897B);
const Color _bg = Color(0xFFF5F5F8);

class HealthMeasurementsScreen extends StatefulWidget {
  const HealthMeasurementsScreen({Key? key}) : super(key: key);

  @override
  State<HealthMeasurementsScreen> createState() => _HealthMeasurementsScreenState();
}

class _HealthMeasurementsScreenState extends State<HealthMeasurementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabC;
  final _service = HealthTrackingService();

  @override
  void initState() {
    super.initState();
    _tabC = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: const Text('📊 القياسات الصحية',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: _teal,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            controller: _tabC,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: '🩸 ضغط الدم'),
              Tab(text: '🍬 سكر الدم'),
            ],
          ),
        ),
        body: TabBarView(controller: _tabC, children: [
          _MeasurementTab(
            type: MeasurementType.bloodPressure,
            service: _service,
            color: const Color(0xFFEF5350),
            onAdd: () => _showAddSheet(MeasurementType.bloodPressure),
          ),
          _MeasurementTab(
            type: MeasurementType.bloodSugar,
            service: _service,
            color: const Color(0xFFFFA726),
            onAdd: () => _showAddSheet(MeasurementType.bloodSugar),
          ),
        ]),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddSheet(
              _tabC.index == 0 ? MeasurementType.bloodPressure : MeasurementType.bloodSugar),
          backgroundColor: _teal,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('إضافة قياس', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  void _showAddSheet(MeasurementType type) {
    final isBP = type == MeasurementType.bloodPressure;
    final c1 = TextEditingController();
    final c2 = TextEditingController();
    final notesC = TextEditingController();
    String sugarContext = 'fasting';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setBS) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: const BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            Text(isBP ? '🩸 تسجيل ضغط الدم' : '🍬 تسجيل سكر الدم',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            if (isBP) ...[
              Row(children: [
                Expanded(child: TextField(
                  controller: c1, keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'الانقباضي (مثال: 120)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                )),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('/', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                Expanded(child: TextField(
                  controller: c2, keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'الانبساطي (مثال: 80)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                )),
              ]),
              const SizedBox(height: 8),
              const Text('القراءة الطبيعية: أقل من 120/80 mmHg',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
            ] else ...[
              TextField(
                controller: c1, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'مستوى السكر (mg/dL)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 12),
              const Align(alignment: Alignment.centerRight,
                  child: Text('وقت القياس', style: TextStyle(fontWeight: FontWeight.w600))),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                for (final entry in {'fasting': 'صائمة', 'after_meal': 'بعد الأكل',
                    'before_sleep': 'قبل النوم', 'random': 'عشوائي'}.entries)
                  ChoiceChip(
                    label: Text(entry.value, style: const TextStyle(fontSize: 12)),
                    selected: sugarContext == entry.key,
                    selectedColor: _teal,
                    onSelected: (_) => setBS(() => sugarContext = entry.key),
                    labelStyle: TextStyle(color: sugarContext == entry.key ? Colors.white : Colors.black),
                  ),
              ]),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: notesC,
              decoration: InputDecoration(labelText: 'ملاحظات (اختياري)',
                  prefixIcon: const Icon(Icons.notes, color: _teal),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () async {
                final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                HealthMeasurementModel m;
                if (isBP) {
                  if (c1.text.isEmpty || c2.text.isEmpty) return;
                  m = HealthMeasurementModel(
                    id: '${uid}_bp_${DateTime.now().millisecondsSinceEpoch}',
                    userId: uid, type: MeasurementType.bloodPressure,
                    systolic: int.tryParse(c1.text), diastolic: int.tryParse(c2.text),
                    notes: notesC.text.isNotEmpty ? notesC.text : null,
                    measuredAt: DateTime.now(),
                  );
                } else {
                  if (c1.text.isEmpty) return;
                  m = HealthMeasurementModel(
                    id: '${uid}_bs_${DateTime.now().millisecondsSinceEpoch}',
                    userId: uid, type: MeasurementType.bloodSugar,
                    bloodSugar: double.tryParse(c1.text), sugarContext: sugarContext,
                    notes: notesC.text.isNotEmpty ? notesC.text : null,
                    measuredAt: DateTime.now(),
                  );
                }
                await _service.addMeasurement(m);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('حفظ القياس', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            )),
          ]),
        ),
      )),
    );
  }
}

class _MeasurementTab extends StatelessWidget {
  final MeasurementType type;
  final HealthTrackingService service;
  final Color color;
  final VoidCallback onAdd;

  const _MeasurementTab({required this.type, required this.service,
      required this.color, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<HealthMeasurementModel>>(
      stream: service.getMeasurements(type),
      builder: (context, snap) {
        final readings = snap.data ?? [];
        if (readings.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(type == MeasurementType.bloodPressure ? '🩸' : '🍬',
                style: const TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            const Text('لا توجد قياسات بعد',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D2D3A))),
            const SizedBox(height: 8),
            const Text('سجّلي قياساتك لمتابعة صحتك',
                style: TextStyle(color: Color(0xFF6B7280))),
          ]));
        }
        return ListView(padding: const EdgeInsets.all(16), children: [
          // أحدث قياس
          _LatestReadingCard(reading: readings.first, color: color),
          const SizedBox(height: 16),
          // تاريخ القياسات
          const Text('آخر القياسات',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D2D3A))),
          const SizedBox(height: 8),
          ...readings.map((r) => _ReadingTile(reading: r, color: color,
              onDelete: () => service.deleteMeasurement(r.id))),
        ]);
      },
    );
  }
}

class _LatestReadingCard extends StatelessWidget {
  final HealthMeasurementModel reading;
  final Color color;

  const _LatestReadingCard({required this.reading, required this.color});

  String get _statusText {
    if (reading.type == MeasurementType.bloodPressure) {
      switch (reading.bloodPressureStatus) {
        case 'normal': return '✅ طبيعي';
        case 'elevated': return '⚠️ مرتفع قليلاً';
        case 'high_stage1': return '🔴 ضغط مرتفع - المرحلة 1';
        case 'high_stage2': return '🔴 ضغط مرتفع - المرحلة 2';
        default: return '';
      }
    } else {
      switch (reading.bloodSugarStatus) {
        case 'normal': return '✅ طبيعي';
        case 'prediabetes': return '⚠️ ما قبل السكري';
        case 'elevated': return '🔴 مرتفع';
        case 'high': return '🔴 مرتفع جداً';
        default: return '';
      }
    }
  }

  String get _valueText {
    if (reading.type == MeasurementType.bloodPressure) {
      return '${reading.systolic}/${reading.diastolic}';
    }
    return '${reading.bloodSugar}';
  }

  String get _unitText {
    return reading.type == MeasurementType.bloodPressure ? 'mmHg' : 'mg/dL';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('آخر قياس', style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(_valueText, style: const TextStyle(color: Colors.white,
              fontSize: 48, fontWeight: FontWeight.bold)),
          Padding(padding: const EdgeInsets.only(bottom: 8, right: 6),
              child: Text(_unitText, style: const TextStyle(color: Colors.white70, fontSize: 16))),
        ]),
        Text(_statusText, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('${reading.measuredAt.day}/${reading.measuredAt.month}/${reading.measuredAt.year} '
            '${reading.measuredAt.hour}:${reading.measuredAt.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ]),
    );
  }
}

class _ReadingTile extends StatelessWidget {
  final HealthMeasurementModel reading;
  final Color color;
  final VoidCallback onDelete;

  const _ReadingTile({required this.reading, required this.color, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isBP = reading.type == MeasurementType.bloodPressure;
    final value = isBP
        ? '${reading.systolic}/${reading.diastolic} mmHg'
        : '${reading.bloodSugar} mg/dL';
    final status = isBP ? reading.bloodPressureStatus : reading.bloodSugarStatus;
    final statusColor = status == 'normal' ? Colors.green : status.contains('high') ? Colors.red : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Row(children: [
        Container(width: 4, height: 40, decoration: BoxDecoration(
            color: statusColor, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2D2D3A))),
          if (!isBP && reading.sugarContext != null)
            Text({'fasting': 'صائمة', 'after_meal': 'بعد الأكل',
                'before_sleep': 'قبل النوم', 'random': 'عشوائي'}[reading.sugarContext] ?? '',
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
          if (reading.notes != null)
            Text(reading.notes!, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
        ])),
        Text('${reading.measuredAt.day}/${reading.measuredAt.month}',
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
        IconButton(icon: Icon(Icons.delete_outline, color: Colors.red.shade300, size: 20),
            onPressed: onDelete),
      ]),
    );
  }
}
