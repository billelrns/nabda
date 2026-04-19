import 'package:cloud_firestore/cloud_firestore.dart';

class CycleModel {
  final String id;
  final String userId;
  final DateTime startDate;
  final DateTime? endDate;
  final int cycleLength;
  final List<String> symptoms;
  final String mood;
  final String flow; // light, normal, heavy
  final String? notes;
  final DateTime createdAt;

  CycleModel({
    required this.id,
    required this.userId,
    required this.startDate,
    this.endDate,
    this.cycleLength = 28,
    this.symptoms = const [],
    this.mood = 'normal',
    this.flow = 'normal',
    this.notes,
    required this.createdAt,
  });

  CycleModel copyWith({
    String? id,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int? cycleLength,
    List<String>? symptoms,
    String? mood,
    String? flow,
    String? notes,
    DateTime? createdAt,
  }) {
    return CycleModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      cycleLength: cycleLength ?? this.cycleLength,
      symptoms: symptoms ?? this.symptoms,
      mood: mood ?? this.mood,
      flow: flow ?? this.flow,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'startDate': startDate,
      'endDate': endDate,
      'cycleLength': cycleLength,
      'symptoms': symptoms,
      'mood': mood,
      'flow': flow,
      'notes': notes,
      'createdAt': createdAt,
    };
  }

  factory CycleModel.fromJson(Map<String, dynamic> json) {
    return CycleModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      startDate: json['startDate'] is Timestamp
          ? (json['startDate'] as Timestamp).toDate()
          : DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: json['endDate'] is Timestamp
          ? (json['endDate'] as Timestamp).toDate()
          : json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      cycleLength: json['cycleLength'] ?? 28,
      symptoms: List<String>.from(json['symptoms'] ?? []),
      mood: json['mood'] ?? 'normal',
      flow: json['flow'] ?? 'normal',
      notes: json['notes'],
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}






