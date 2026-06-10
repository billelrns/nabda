import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationModel {
  final String id;
  final String userId;
  final String name;
  final String type; // pill, syrup, injection, vitamin, supplement
  final String dose;
  final String frequency; // daily, twice_daily, three_times, weekly, as_needed
  final List<String> times; // ['08:00', '20:00']
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;
  final bool isActive;
  final List<MedicationLog> logs;
  final DateTime createdAt;
  // حقول المريض
  final String patientType; // 'self' or 'baby'
  final String? patientId;   // baby doc id if patientType == 'baby'
  final String patientName;  // اسم المريض للعرض
  final String reminderTime; // HH:mm e.g. '08:00'

  MedicationModel({
    required this.id,
    required this.userId,
    required this.name,
    this.type = 'pill',
    required this.dose,
    this.frequency = 'daily',
    this.times = const ['08:00'],
    required this.startDate,
    this.endDate,
    this.notes,
    this.isActive = true,
    this.logs = const [],
    required this.createdAt,
    this.patientType = 'self',
    this.patientId,
    this.patientName = 'الأم',
    this.reminderTime = '08:00',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'name': name,
    'type': type,
    'dose': dose,
    'frequency': frequency,
    'times': times,
    'startDate': startDate,
    'endDate': endDate,
    'notes': notes,
    'isActive': isActive,
    'logs': logs.map((l) => l.toJson()).toList(),
    'createdAt': createdAt,
    'patientType': patientType,
    'patientId': patientId,
    'patientName': patientName,
    'reminderTime': reminderTime,
  };

  factory MedicationModel.fromJson(Map<String, dynamic> json) => MedicationModel(
    id: json['id'] ?? '',
    userId: json['userId'] ?? '',
    name: json['name'] ?? '',
    type: json['type'] ?? 'pill',
    dose: json['dose'] ?? '',
    frequency: json['frequency'] ?? 'daily',
    times: List<String>.from(json['times'] ?? ['08:00']),
    startDate: json['startDate'] is Timestamp
        ? (json['startDate'] as Timestamp).toDate()
        : DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
    endDate: json['endDate'] is Timestamp
        ? (json['endDate'] as Timestamp).toDate()
        : json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
    notes: json['notes'],
    isActive: json['isActive'] ?? true,
    logs: (json['logs'] as List<dynamic>? ?? [])
        .map((l) => MedicationLog.fromJson(l as Map<String, dynamic>))
        .toList(),
    createdAt: json['createdAt'] is Timestamp
        ? (json['createdAt'] as Timestamp).toDate()
        : DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    patientType: json['patientType'] ?? 'self',
    patientId: json['patientId'],
    patientName: json['patientName'] ?? 'الأم',
    reminderTime: json['reminderTime'] ?? '08:00',
  );
}

class MedicationLog {
  final DateTime takenAt;
  final bool taken;
  final String? note;

  MedicationLog({required this.takenAt, required this.taken, this.note});

  Map<String, dynamic> toJson() => {
    'takenAt': takenAt.toIso8601String(),
    'taken': taken,
    'note': note,
  };

  factory MedicationLog.fromJson(Map<String, dynamic> json) => MedicationLog(
    takenAt: DateTime.parse(json['takenAt'] ?? DateTime.now().toIso8601String()),
    taken: json['taken'] ?? false,
    note: json['note'],
  );
}
