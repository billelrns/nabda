import 'package:cloud_firestore/cloud_firestore.dart';

enum MeasurementType { bloodPressure, bloodSugar, weight, temperature, heartRate }

class HealthMeasurementModel {
  final String id;
  final String userId;
  final MeasurementType type;
  // ضغط الدم
  final int? systolic;   // الضغط الانقباضي (مثل 120)
  final int? diastolic;  // الضغط الانبساطي (مثل 80)
  // سكر الدم (mg/dL)
  final double? bloodSugar;
  final String? sugarContext; // fasting, after_meal, before_sleep, random
  // وزن (kg)
  final double? weight;
  // حرارة (°C)
  final double? temperature;
  // نبض (bpm)
  final int? heartRate;
  final String? notes;
  final DateTime measuredAt;

  HealthMeasurementModel({
    required this.id,
    required this.userId,
    required this.type,
    this.systolic,
    this.diastolic,
    this.bloodSugar,
    this.sugarContext,
    this.weight,
    this.temperature,
    this.heartRate,
    this.notes,
    required this.measuredAt,
  });

  // تقييم الضغط
  String get bloodPressureStatus {
    if (systolic == null || diastolic == null) return 'unknown';
    if (systolic! < 120 && diastolic! < 80) return 'normal';
    if (systolic! < 130 && diastolic! < 80) return 'elevated';
    if (systolic! < 140 || diastolic! < 90) return 'high_stage1';
    return 'high_stage2';
  }

  // تقييم السكر
  String get bloodSugarStatus {
    if (bloodSugar == null) return 'unknown';
    if (sugarContext == 'fasting') {
      if (bloodSugar! < 100) return 'normal';
      if (bloodSugar! < 126) return 'prediabetes';
      return 'high';
    }
    if (bloodSugar! < 140) return 'normal';
    if (bloodSugar! < 200) return 'elevated';
    return 'high';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'type': type.name,
    'systolic': systolic,
    'diastolic': diastolic,
    'bloodSugar': bloodSugar,
    'sugarContext': sugarContext,
    'weight': weight,
    'temperature': temperature,
    'heartRate': heartRate,
    'notes': notes,
    'measuredAt': measuredAt,
  };

  factory HealthMeasurementModel.fromJson(Map<String, dynamic> json) {
    MeasurementType type;
    try {
      type = MeasurementType.values.byName(json['type'] ?? 'bloodPressure');
    } catch (_) {
      type = MeasurementType.bloodPressure;
    }
    return HealthMeasurementModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: type,
      systolic: json['systolic'],
      diastolic: json['diastolic'],
      bloodSugar: json['bloodSugar']?.toDouble(),
      sugarContext: json['sugarContext'],
      weight: json['weight']?.toDouble(),
      temperature: json['temperature']?.toDouble(),
      heartRate: json['heartRate'],
      notes: json['notes'],
      measuredAt: json['measuredAt'] is Timestamp
          ? (json['measuredAt'] as Timestamp).toDate()
          : DateTime.parse(json['measuredAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
