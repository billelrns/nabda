import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityPostModel {
  final String id;
  final String userId;
  final String title;
  final String content;
  final String author;
  final String category; // pregnancy, cycle, baby, general
  final String? imageUrl;
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
    this.imageUrl,
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
    String? imageUrl,
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
      imageUrl: imageUrl ?? this.imageUrl,
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
      'imageUrl': imageUrl,
      'likes': likes,
      'likedBy': likedBy,
      'comments': comments,
      'isAnonymous': isAnonymous,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory CommunityPostModel.fromJson(Map<String, dynamic> json) {
    // Handle 'likes' field: old posts saved it as array, new ones as int
    int likesCount = 0;
    if (json['likes'] is int) {
      likesCount = json['likes'];
    } else if (json['likes'] is List) {
      likesCount = (json['likes'] as List).length;
    } else if (json['likesCount'] is int) {
      likesCount = json['likesCount'];
    }

    // Handle 'likedBy': old posts used 'likes' array
    List<String> likedByList = [];
    if (json['likedBy'] is List) {
      likedByList = List<String>.from(json['likedBy']);
    } else if (json['likes'] is List) {
      likedByList = List<String>.from(json['likes']);
    }

    // Parse createdAt safely
    DateTime createdAtDate;
    try {
      if (json['createdAt'] is Timestamp) {
        createdAtDate = (json['createdAt'] as Timestamp).toDate();
      } else if (json['createdAt'] is String) {
        createdAtDate = DateTime.parse(json['createdAt']);
      } else {
        createdAtDate = DateTime.now();
      }
    } catch (_) {
      createdAtDate = DateTime.now();
    }

    // Handle category: old posts used 'cat_general' format
    String category = json['category'] ?? 'general';
    if (category.startsWith('cat_')) {
      category = category.substring(4);
    }

    return CommunityPostModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? json['authorId'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? json['text'] ?? '',
      author: json['author'] ?? json['authorName'] ?? '',
      category: category,
      imageUrl: json['imageUrl'] as String?,
      likes: likesCount,
      likedBy: likedByList,
      comments: List<Map<String, dynamic>>.from(json['comments'] ?? []),
      isAnonymous: json['isAnonymous'] ?? false,
      createdAt: createdAtDate,
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }
}
