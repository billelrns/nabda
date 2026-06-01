import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/medication_model.dart';
import '../models/health_measurement_model.dart';

class HealthTrackingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ─── helper يضمن uid غير null ───
  CollectionReference _medsCol(String uid) =>
      _db.collection('users').doc(uid).collection('medications');

  // ─── الأدوية ──────────────────────────────────────────

  Future<void> addMedication(MedicationModel med) async {
    final uid = _uid;
    if (uid == null) throw Exception('يجب تسجيل الدخول أولاً');
    final data = med.toJson();
    // تحويل DateTime إلى Timestamp لضمان التوافق مع web
    data['startDate'] = Timestamp.fromDate(med.startDate);
    data['createdAt'] = Timestamp.fromDate(med.createdAt);
    if (med.endDate != null) data['endDate'] = Timestamp.fromDate(med.endDate!);
    await _medsCol(uid).doc(med.id).set(data);
  }

  Future<void> updateMedication(MedicationModel med) async {
    final uid = _uid;
    if (uid == null) return;
    await _medsCol(uid).doc(med.id).update(med.toJson());
  }

  Future<void> deleteMedication(String medId) async {
    final uid = _uid;
    if (uid == null) return;
    await _medsCol(uid).doc(medId).delete();
  }

  Stream<List<MedicationModel>> getUserMedications() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);
    return _medsCol(uid).snapshots().map((snap) {
      final list = snap.docs
          .map((d) => MedicationModel.fromJson(d.data() as Map<String, dynamic>))
          .where((m) => m.isActive)
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<List<MedicationModel>> getUserMedicationsFuture() async {
    final uid = _uid;
    if (uid == null) return [];
    try {
      final snap = await _medsCol(uid).get();
      final list = snap.docs
          .map((d) => MedicationModel.fromJson(d.data() as Map<String, dynamic>))
          .where((m) => m.isActive)
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      return [];
    }
  }

  Future<void> logMedication(String medId, MedicationLog log) async {
    final uid = _uid;
    if (uid == null) return;
    final med = await _medsCol(uid).doc(medId).get();
    if (!med.exists) return;
    final data = med.data() as Map<String, dynamic>;
    final logs = (data['logs'] as List<dynamic>? ?? [])
        .map((l) => MedicationLog.fromJson(l as Map<String, dynamic>))
        .toList();
    logs.add(log);
    await _medsCol(uid).doc(medId).update({
      'logs': logs.map((l) => l.toJson()).toList(),
    });
  }

  // ─── القياسات الصحية ──────────────────────────────────

  Future<void> addMeasurement(HealthMeasurementModel m) async {
    if (_uid == null) throw Exception('يجب تسجيل الدخول أولاً');
    await _db.collection('health_measurements').doc(m.id).set(m.toJson());
  }

  Future<void> deleteMeasurement(String id) async {
    await _db.collection('health_measurements').doc(id).delete();
  }

  Stream<List<HealthMeasurementModel>> getMeasurements(MeasurementType type) {
    if (_uid == null) return Stream.value([]);
    return _db
        .collection('health_measurements')
        .where('userId', isEqualTo: _uid)
        .where('type', isEqualTo: type.name)
        .orderBy('measuredAt', descending: true)
        .limit(30)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => HealthMeasurementModel.fromJson(d.data()))
            .toList());
  }

  Future<List<HealthMeasurementModel>> getRecentMeasurements({int days = 7}) async {
    if (_uid == null) return [];
    final since = DateTime.now().subtract(Duration(days: days));
    final snap = await _db
        .collection('health_measurements')
        .where('userId', isEqualTo: _uid)
        .where('measuredAt', isGreaterThan: Timestamp.fromDate(since))
        .orderBy('measuredAt', descending: true)
        .get();
    return snap.docs
        .map((d) => HealthMeasurementModel.fromJson(d.data()))
        .toList();
  }

  // ─── تقرير صحي للطبيب ────────────────────────────────

  Future<Map<String, dynamic>> generateHealthReport() async {
    if (_uid == null) return {};
    final meds = await _db
        .collection('medications')
        .where('userId', isEqualTo: _uid)
        .where('isActive', isEqualTo: true)
        .get();
    final measurements = await getRecentMeasurements(days: 30);

    final bpReadings = measurements
        .where((m) => m.type == MeasurementType.bloodPressure)
        .take(10)
        .toList();
    final sugarReadings = measurements
        .where((m) => m.type == MeasurementType.bloodSugar)
        .take(10)
        .toList();
    final weightReadings = measurements
        .where((m) => m.type == MeasurementType.weight)
        .take(5)
        .toList();

    return {
      'generatedAt': DateTime.now().toIso8601String(),
      'medications': meds.docs.map((d) {
        final data = d.data();
        return '${data['name']} ${data['dose']} - ${data['frequency']}';
      }).toList(),
      'bloodPressure': bpReadings.map((m) =>
          '${m.measuredAt.day}/${m.measuredAt.month}: ${m.systolic}/${m.diastolic} mmHg'
      ).toList(),
      'bloodSugar': sugarReadings.map((m) =>
          '${m.measuredAt.day}/${m.measuredAt.month}: ${m.bloodSugar} mg/dL (${m.sugarContext ?? ''})'
      ).toList(),
      'weight': weightReadings.map((m) =>
          '${m.measuredAt.day}/${m.measuredAt.month}: ${m.weight} kg'
      ).toList(),
    };
  }
}
