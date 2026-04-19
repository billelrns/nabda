import 'package:cloud_firestore/cloud_firestore.dart';

class PregnancyModel {
  final String id;
  final String userId;
  final DateTime dueDate;
  final int currentWeek;
  final List<Map<String, dynamic>> appointments;
  final List<Map<String, dynamic>> kickCounts;
  final String? babyName;
  final String? babyGender;
  final DateTime createdAt;

  PregnancyModel({
    required this.id,
    required this.userId,
    required this.dueDate,
    this.currentWeek = 0,
    this.appointments = const [],
    this.kickCounts = const [],
    this.babyName,
    this.babyGender,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'dueDate': dueDate,
      'currentWeek': currentWeek,
      'appointments': appointments,
      'kickCounts': kickCounts,
      'babyName': babyName,
      'babyGender': babyGender,
      'createdAt': createdAt,
    };
  }

  factory PregnancyModel.fromJson(Map<String, dynamic> json) {
    return PregnancyModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      dueDate: json['dueDate'] is Timestamp
          ? (json['dueDate'] as Timestamp).toDate()
          : DateTime.parse(json['dueDate'] ?? DateTime.now().toIso8601String()),
      currentWeek: json['currentWeek'] ?? 0,
      appointments: List<Map<String, dynamic>>.from(json['appointments'] ?? []),
      kickCounts: List<Map<String, dynamic>>.from(json['kickCounts'] ?? []),
      babyName: json['babyName'],
      babyGender: json['babyGender'],
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}






