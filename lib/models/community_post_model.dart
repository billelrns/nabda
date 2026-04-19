import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityPostModel {
  final String id;
  final String userId;
  final String title;
  final String content;
  final String author;
  final String category; // pregnancy, cycle, baby, general
  final int likes;
  final List<String> likedBy;
  final List<Map<String, dynamic>> comments;
  final bool isAnonymous;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CommunityPostModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.author,
    this.category = 'general',
    this.likes = 0,
    this.likedBy = const [],
    this.comments = const [],
    this.isAnonymous = false,
    required this.createdAt,
    this.updatedAt,
  });

  CommunityPostModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    String? author,
    String? category,
    int? likes,
    List<String>? likedBy,
    List<Map<String, dynamic>>? comments,
    bool? isAnonymous,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CommunityPostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      author: author ?? this.author,
      category: category ?? this.category,
      likes: likes ?? this.likes,
      likedBy: likedBy ?? this.likedBy,
      comments: comments ?? this.comments,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'content': content,
      'author': author,
      'category': category,
      'likes': likes,
      'likedBy': likedBy,
      'comments': comments,
      'isAnonymous': isAnonymous,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory CommunityPostModel.fromJson(Map<String, dynamic> json) {
    return CommunityPostModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      author: json['author'] ?? '',
      category: json['category'] ?? 'general',
      likes: json['likes'] ?? 0,
      likedBy: List<String>.from(json['likedBy'] ?? []),
      comments: List<Map<String, dynamic>>.from(json['comments'] ?? []),
      isAnonymous: json['isAnonymous'] ?? false,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }
}






