import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/smart_article.dart';

class SmartArticlesService {
  static final SmartArticlesService _instance = SmartArticlesService._internal();
  factory SmartArticlesService() => _instance;
  SmartArticlesService._internal();

  List<SmartArticle>? _cache;
  bool _loading = false;

  /// تحميل جميع المقالات (مرة واحدة، ثم مخزّنة)
  Future<List<SmartArticle>> loadAll() async {
    if (_cache != null) return _cache!;
    if (_loading) {
      // انتظار جولة التحميل الجارية
      while (_loading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _cache ?? [];
    }
    _loading = true;
    try {
      final jsonStr = await rootBundle.loadString('assets/data/smart_2500_articles.json');
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final list = (data['articles'] as List)
          .map((a) => SmartArticle.fromJson(a as Map<String, dynamic>))
          .toList();
      _cache = list;
      return list;
    } finally {
      _loading = false;
    }
  }

  /// مقالات حسب التصنيف
  Future<List<SmartArticle>> byCategory(String categoryId) async {
    final all = await loadAll();
    return all.where((a) => a.categoryId == categoryId).toList();
  }

  /// أعلى المقالات مشاهدة (top N)
  Future<List<SmartArticle>> topViewed({int limit = 10}) async {
    final all = await loadAll();
    final sorted = [...all]..sort((a, b) => b.originalViews.compareTo(a.originalViews));
    return sorted.take(limit).toList();
  }

  /// بحث في العناوين والملخصات
  Future<List<SmartArticle>> search(String query) async {
    final all = await loadAll();
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    return all.where((a) =>
      a.title.toLowerCase().contains(q) ||
      a.summary.toLowerCase().contains(q) ||
      a.categoryName.toLowerCase().contains(q)
    ).toList();
  }

  /// مقالات مقترحة (متعلقة) — بناءً على categoryId
  Future<List<SmartArticle>> relatedTo(SmartArticle article, {int limit = 6}) async {
    final all = await loadAll();
    final same = all.where((a) => a.categoryId == article.categoryId && a.id != article.id).toList();
    same.shuffle();
    return same.take(limit).toList();
  }

  /// إحصائيات
  Future<Map<String, int>> categoryStats() async {
    final all = await loadAll();
    final stats = <String, int>{};
    for (final a in all) {
      stats[a.categoryId] = (stats[a.categoryId] ?? 0) + 1;
    }
    return stats;
  }
}
