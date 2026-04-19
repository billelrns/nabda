import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String userId;
  final String content;
  final String sender; // user or ai
  final DateTime timestamp;
  final bool isAI;
  final String? aiResponse;
  final List<String> tags; // pregnancy, cycle, baby, general

  MessageModel({
    required this.id,
    required this.userId,
    required this.content,
    required this.sender,
    required this.timestamp,
    this.isAI = false,
    this.aiResponse,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'content': content,
      'sender': sender,
      'timestamp': timestamp,
      'isAI': isAI,
      'aiResponse': aiResponse,
      'tags': tags,
    };
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      content: json['content'] ?? '',
      sender: json['sender'] ?? 'user',
      timestamp: json['timestamp'] is Timestamp
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isAI: json['isAI'] ?? false,
      aiResponse: json['aiResponse'],
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}






