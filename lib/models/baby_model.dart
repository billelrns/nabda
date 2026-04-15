import 'package:cloud_firestore/cloud_firestore.dart';

class BabyModel {
  final String id;
  final String userId;
  final String name;
  final DateTime birthDate;
  final String gender;
  final double weight;
  final double height;
  final List<Map<String, dynamic>> milestones;
  final List<Map<String, dynamic>> vaccinations;
  final DateTime createdAt;

  BabyModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.birthDate,
    required this.gender,
    this.weight = 0,
    this.height = 0,
    this.milestones = const [],
    this.vaccinations = const [],
    required this.createdAt,
  });

  int get ageInMonths {
    final now = DateTime.now();
    final difference = now.difference(birthDate);
    return (difference.inDays / 30.44).round();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'birthDate': birthDate,
      'gender': gender,
      'weight': weight,
      'height': height,
      'milestones': milestones,
      'vaccinations': vaccinations,
      'createdAt': createdAt,
    };
  }

  factory BabyModel.fromJson(Map<String, dynamic> json) {
    return BabyModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      birthDate: json['birthDate'] is Timestamp
          ? (json['birthDate'] as Timestamp).toDate()
          : DateTime.parse(json['birthDate'] ?? DateTime.now().toIso8601String()),
      gender: json['gender'] ?? 'unknown',
      weight: (json['weight'] ?? 0).toDouble(),
      height: (json['height'] ?? 0).toDouble(),
      milestones: List<Map<String, dynamic>>.from(json['milestones'] ?? []),
      vaccinations: List<Map<String, dynamic>>.from(json['vaccinations'] ?? []),
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
