import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/medication_model.dart';
import '../../services/health_tracking_service.dart';
import '../../main.dart' as app;
import 'dart:async';

const Color _teal = Color(0xFF00897B);
const Color _pink = Color(0xFFE91E63);
const Color _bg = Color(0xFFF5F5F8);

// ─── نموذج بسيط للمريض ───
class _Patient {
  final String id;
  final String name;
  final String type; // 'self' or 'baby'
  _Patient({required this.id, required this.name, required this.type});
}

class MedicationTrackerScreen extends StatefulWidget {
  const MedicationTrackerScreen({Key? key}) : super(key: key);

  @override
  State<MedicationTrackerScreen> createState() => _MedicationTrackerScreenState();
}

class _MedicationTrackerScreenState extends State<MedicationTrackerScreen> {
  final _service = HealthTrackingService();
  List<_Patient> _patients = [];
  Timer? _notifTimer;
  late Future<List<MedicationModel>> _medsFuture;

  static const _typeIcons = {
    'pill': '💊', 'syrup': '🧴', 'injection': '💉',
    'vitamin': '🌟', 'supplement': '🌿',
  };
  static const _typeNames = {
    'pill': 'حبة', 'syrup': 'شراب', 'injection': 'حقنة',
    'vitamin': 'فيتامين', 'supplement': 'مكمل غذائي',
  };
  static const _freqNames = {
    'daily': 'يومياً', 'twice_daily': 'مرتين يومياً',
    'three_times': 'ثلاث مرات', 'weekly': 'أسبوعياً',
    'as_needed': 'عند الحاجة',
  };

  @override
  void initState() {
    super.initState();
    _medsFuture = _service.getUserMedicationsFuture();
    _loadPatients();
    _startReminderChecker();
    _rescheduleAll();
  }

  // الأوقات الفعلية للدواء: نعتمد times إن كانت متعددة، وإلا reminderTime (يدعم الأدوية القديمة)
  static List<String> _effTimes(MedicationModel m) {
    final raw = m.times.length > 1 ? m.times : [m.reminderTime];
    return raw.where((t) => t.contains(':')).toList();
  }

  static List<List<int>> _parseTimes(MedicationModel m) {
    final out = <List<int>>[];
    for (final t in _effTimes(m)) {
      final p = t.split(':');
      if (p.length != 2) continue;
      final h = int.tryParse(p[0]);
      final mi = int.tryParse(p[1]);
      if (h != null && mi != null) out.add([h, mi]);
    }
    return out.isEmpty ? [[8, 0]] : out;
  }

  // ✅ إعادة جدولة إشعارات كل الأدوية المحفوظة (تشمل الأدوية القديمة ومتعددة الأوقات)
  Future<void> _rescheduleAll() async {
    try {
      final meds = await _service.getUserMedicationsFuture();
      for (final m in meds) {
        await app.NotifService.scheduleMedTimes(
          medId: m.id,
          medName: m.name,
          patientName: m.patientName,
          times: _parseTimes(m),
        );
      }
    } catch (_) {}
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _medsFuture = _service.getUserMedicationsFuture();
    });
  }

  @override
  void dispose() {
    _notifTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    // انتظر حتى يكون المستخدم مسجل دخوله
    final user = await FirebaseAuth.instance.authStateChanges()
        .firstWhere((u) => u != null);
    final uid = user!.uid;

    final list = <_Patient>[
      _Patient(id: 'self', name: 'الأم', type: 'self'),
    ];
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users').doc(uid).collection('babies').get();
      for (final doc in snap.docs) {
        final data = doc.data();
        final name = data['name'] as String? ?? 'طفل';
        if (name.isNotEmpty) {
          list.add(_Patient(id: doc.id, name: name, type: 'baby'));
        }
      }
    } catch (e) {
      debugPrint('خطأ في تحميل الأطفال: $e');
    }
    if (mounted) setState(() => _patients = list);
  }

  // ─── فحص التذكيرات كل دقيقة ───
  void _startReminderChecker() {
    _notifTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final now = TimeOfDay.now();
      final nowStr = '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}';
      final snap = await FirebaseFirestore.instance
          .collection('users').doc(uid as String).collection('medications')
          .get();
      for (final doc in snap.docs) {
        final data = doc.data();
        final timesList = (data['times'] as List?)?.map((e) => e.toString()).toList() ?? [];
        final eff = timesList.length > 1 ? timesList : [data['reminderTime']?.toString() ?? ''];
        if ((data['isActive'] ?? true) && eff.contains(nowStr)) {
          if (mounted) {
            _showReminderBanner(data['name'] ?? 'دواء', data['patientName'] ?? 'الأم');
          }
        }
      }
    });
  }

  void _showReminderBanner(String medName, String patientName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 8),
        backgroundColor: _teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(children: [
          const Text('⏰', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('تذكير: $medName', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
            Text('لـ $patientName', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ])),
        ]),
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
          title: const Text('💊 الأدوية والفيتامينات',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: _teal,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddMedicationSheet(context),
          backgroundColor: _teal,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('إضافة دواء', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: RefreshIndicator(
          onRefresh: () async => _refresh(),
          color: _teal,
          child: FutureBuilder<List<MedicationModel>>(
            future: _medsFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: _teal));
              }
              final meds = snap.data ?? [];
              if (meds.isEmpty) return _buildEmptyState();
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: meds.length,
                itemBuilder: (_, i) => _MedicationCard(
                  med: meds[i],
                  typeIcon: _typeIcons[meds[i].type] ?? '💊',
                  typeName: _typeNames[meds[i].type] ?? '',
                  freqName: _freqNames[meds[i].frequency] ?? '',
                  onTaken: () async {
                    await _markTaken(meds[i]);
                    _refresh();
                  },
                  onDelete: () async {
                    await _confirmDelete(meds[i]);
                    _refresh();
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('💊', style: TextStyle(fontSize: 64)),
      const SizedBox(height: 16),
      const Text('لا توجد أدوية مضافة بعد',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D2D3A))),
      const SizedBox(height: 8),
      const Text('أضيفي أدويتك لتتبعي مواعيدها بسهولة',
          style: TextStyle(color: Color(0xFF6B7280))),
      const SizedBox(height: 24),
      ElevatedButton.icon(
        onPressed: () => _showAddMedicationSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('إضافة دواء'),
        style: ElevatedButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
      ),
    ]),
  );

  Future<void> _markTaken(MedicationModel med) async {
    await _service.logMedication(med.id, MedicationLog(takenAt: DateTime.now(), taken: true));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تسجيل أخذ ${med.name} ✓'), backgroundColor: _teal,
            behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _confirmDelete(MedicationModel med) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('حذف الدواء'),
          content: Text('هل تريدين حذف "${med.name}"؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('حذف', style: TextStyle(color: Colors.white))),
          ],
        )),
    );
    if (ok == true) {
      await _service.deleteMedication(med.id);
      await app.NotifService.cancelMedReminder(med.id);
    }
  }

  void _showAddMedicationSheet(BuildContext context) {
    final nameC = TextEditingController();
    final doseC = TextEditingController();
    final notesC = TextEditingController();
    String selectedType = 'pill';
    String selectedFreq = 'daily';
    _Patient? selectedPatient = _patients.isNotEmpty ? _patients.first : null;
    final List<TimeOfDay> reminderTimes = [const TimeOfDay(hour: 8, minute: 0)];

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
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const Text('إضافة دواء / فيتامين',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2D2D3A))),
            const SizedBox(height: 20),

            // ─── لمن هذا الدواء؟ ───
            const Align(alignment: Alignment.centerRight,
                child: Text('لمن هذا الدواء؟', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2D2D3A)))),
            const SizedBox(height: 8),
            if (_patients.isEmpty)
              const Text('جاري التحميل...', style: TextStyle(color: Colors.grey))
            else
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<_Patient>(
                    value: selectedPatient,
                    isExpanded: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    borderRadius: BorderRadius.circular(12),
                    items: _patients.map((p) => DropdownMenuItem(
                      value: p,
                      child: Row(children: [
                        Text(p.type == 'self' ? '👩' : '👶', style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Text(p.name, style: const TextStyle(fontSize: 15)),
                      ]),
                    )).toList(),
                    onChanged: (v) => setBS(() => selectedPatient = v),
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // ─── نوع الدواء ───
            const Align(alignment: Alignment.centerRight,
                child: Text('النوع', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2D2D3A)))),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: _typeIcons.keys.map((type) => ChoiceChip(
              label: Text('${_typeIcons[type]} ${_typeNames[type]}'),
              selected: selectedType == type,
              selectedColor: _teal,
              onSelected: (_) => setBS(() => selectedType = type),
              labelStyle: TextStyle(color: selectedType == type ? Colors.white : Colors.black),
            )).toList()),
            const SizedBox(height: 16),

            _field(nameC, 'اسم الدواء *', Icons.medication_outlined),
            _field(doseC, 'الجرعة (مثال: حبة واحدة / 5ml)', Icons.scale_outlined),

            // ─── التكرار ───
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedFreq,
              decoration: InputDecoration(labelText: 'التكرار',
                  prefixIcon: const Icon(Icons.schedule, color: _teal),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
              items: _freqNames.entries.map((e) =>
                  DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: (v) => setBS(() => selectedFreq = v!),
            ),
            const SizedBox(height: 12),

            // ─── أوقات التذكير (متعددة) ───
            Row(children: [
              const Align(alignment: Alignment.centerRight,
                  child: Text('أوقات التذكير', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2D2D3A)))),
              const Spacer(),
              if (reminderTimes.length < 10)
                TextButton.icon(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: ctx,
                      initialTime: const TimeOfDay(hour: 8, minute: 0),
                      helpText: 'أضيفي وقتاً',
                    );
                    if (picked != null) setBS(() {
                      if (!reminderTimes.any((t) => t.hour == picked.hour && t.minute == picked.minute)) {
                        reminderTimes.add(picked);
                        reminderTimes.sort((a, b) =>
                            (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
                      }
                    });
                  },
                  icon: const Icon(Icons.add_alarm, color: _teal, size: 20),
                  label: const Text('إضافة وقت', style: TextStyle(color: _teal)),
                ),
            ]),
            const SizedBox(height: 4),
            Column(children: List.generate(reminderTimes.length, (i) {
              final t = reminderTimes[i];
              final label = '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.alarm, color: _teal),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: ctx, initialTime: t, helpText: 'تعديل الوقت');
                      if (picked != null) setBS(() {
                        reminderTimes[i] = picked;
                        reminderTimes.sort((a, b) =>
                            (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
                      });
                    },
                    child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  const Spacer(),
                  if (reminderTimes.length > 1)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red, size: 20),
                      onPressed: () => setBS(() => reminderTimes.removeAt(i)),
                    ),
                ]),
              );
            })),
            const SizedBox(height: 12),

            _field(notesC, 'ملاحظات (اختياري)', Icons.notes_outlined),
            const SizedBox(height: 16),

            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () async {
                if (nameC.text.trim().isEmpty || doseC.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('الرجاء إدخال اسم الدواء والجرعة')));
                  return;
                }
                final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                final patient = selectedPatient ?? _Patient(id: 'self', name: 'الأم', type: 'self');
                reminderTimes.sort((a, b) =>
                    (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
                final timesStr = reminderTimes
                    .map((t) => '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}')
                    .toList();
                final remStr = timesStr.join(' • ');
                final med = MedicationModel(
                  id: '${uid}_med_${DateTime.now().millisecondsSinceEpoch}',
                  userId: uid,
                  name: nameC.text.trim(),
                  type: selectedType,
                  dose: doseC.text.trim(),
                  frequency: selectedFreq,
                  times: timesStr,
                  startDate: DateTime.now(),
                  notes: notesC.text.isNotEmpty ? notesC.text.trim() : null,
                  createdAt: DateTime.now(),
                  patientType: patient.type,
                  patientId: patient.type == 'baby' ? patient.id : null,
                  patientName: patient.name,
                  reminderTime: timesStr.first,
                );
                try {
                  await _service.addMedication(med);
                  // ✅ جدولة إشعار منفصل لكل وقت
                  await app.NotifService.scheduleMedTimes(
                    medId: med.id,
                    medName: med.name,
                    patientName: patient.name,
                    times: reminderTimes.map((t) => [t.hour, t.minute]).toList(),
                  );
                  // إشعار تأكيد فوري للمستخدم
                  await app.NotifService.showInstant(
                    '✅ تم ضبط تذكير الدواء',
                    'سيصلك إشعار يومي لـ ${med.name} في: $remStr',
                  );
                  _refresh();
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم إضافة ${med.name} لـ ${patient.name} ✓'),
                        backgroundColor: _teal,
                        behavior: SnackBarBehavior.floating,
                      ));
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('حفظ الدواء', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            )),
          ])),
        ),
      )),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: c,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: _teal),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
    ),
  );
}

// ─── كارد الدواء ───
class _MedicationCard extends StatelessWidget {
  final MedicationModel med;
  final String typeIcon, typeName, freqName;
  final VoidCallback onTaken, onDelete;

  const _MedicationCard({required this.med, required this.typeIcon, required this.typeName,
      required this.freqName, required this.onTaken, required this.onDelete});

  bool get _takenToday {
    final today = DateTime.now();
    return med.logs.any((l) => l.taken &&
        l.takenAt.year == today.year &&
        l.takenAt.month == today.month &&
        l.takenAt.day == today.day);
  }

  @override
  Widget build(BuildContext context) {
    final taken = _takenToday;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: taken ? Border.all(color: _teal.withOpacity(0.4), width: 1.5) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 48, height: 48,
            decoration: BoxDecoration(color: _teal.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(typeIcon, style: const TextStyle(fontSize: 24)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D2D3A))),
            const SizedBox(height: 2),
            Text('$typeName • ${med.dose}', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
          ])),
          if (taken)
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: _teal.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: const Text('✓ تم اليوم', style: TextStyle(color: _teal, fontSize: 12, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 10),
        // ─── معلومات المريض والتذكير ───
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Text(med.patientType == 'self' ? '👩' : '👶', style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(med.patientName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const Spacer(),
            const Icon(Icons.alarm, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(med.times.length > 1 ? med.times.join(' • ') : med.reminderTime,
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(width: 8),
            const Icon(Icons.refresh, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(freqName, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ]),
        ),
        if (med.notes != null && med.notes!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('📝 ${med.notes}', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
        ],
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
            label: const Text('حذف', style: TextStyle(color: Colors.red, fontSize: 13)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          )),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton.icon(
            onPressed: taken ? null : onTaken,
            icon: Icon(taken ? Icons.check_circle : Icons.medication, size: 16),
            label: Text(taken ? 'تم اليوم' : 'سجّلي الأخذ', style: const TextStyle(fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: taken ? Colors.grey.shade300 : _teal,
              foregroundColor: taken ? Colors.grey : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          )),
        ]),
      ]),
    );
  }
}
