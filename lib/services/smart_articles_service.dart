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

  /// مقالات حسب التصنيف الرئيسي
  Future<List<SmartArticle>> byCategory(String categoryId) async {
    final all = await loadAll();
    return all.where((a) => a.categoryId == categoryId).toList();
  }

  /// مقالات حسب التصنيف الفرعي
  Future<List<SmartArticle>> bySubcategory(String subcategoryId) async {
    final all = await loadAll();
    return all.where((a) => a.subcategoryId == subcategoryId).toList();
  }

  /// مقالات حسب التصنيف الرئيسي والتصنيف الفرعي اختياريًا
  Future<List<SmartArticle>> byCategoryAndSubcategory(
    String categoryId, {
    String? subcategoryId,
  }) async {
    final list = await byCategory(categoryId);
    if (subcategoryId == null || subcategoryId.isEmpty || subcategoryId == 'all') {
      return list;
    }
    return list.where((a) => a.subcategoryId == subcategoryId).toList();
  }

  /// أحدث المقالات (latest)
  Future<List<SmartArticle>> latestArticles({String? categoryId, int limit = 10}) async {
    final all = await loadAll();
    var filtered = categoryId != null ? all.where((a) => a.categoryId == categoryId).toList() : all;
    // Latest articles have highest rank or id
    final sorted = [...filtered]..sort((a, b) => b.rank.compareTo(a.rank));
    return sorted.take(limit).toList();
  }

  /// أعلى المقالات مشاهدة (top N)
  Future<List<SmartArticle>> topViewed({String? categoryId, int limit = 10}) async {
    final all = await loadAll();
    var filtered = categoryId != null ? all.where((a) => a.categoryId == categoryId).toList() : all;
    final sorted = [...filtered]..sort((a, b) => b.originalViews.compareTo(a.originalViews));
    return sorted.take(limit).toList();
  }

  /// بحث في العناوين والملخصات والتصنيفات الفرعية والوسوم
  Future<List<SmartArticle>> search(String query) async {
    final all = await loadAll();
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    return all.where((a) =>
      a.title.toLowerCase().contains(q) ||
      a.summary.toLowerCase().contains(q) ||
      a.categoryName.toLowerCase().contains(q) ||
      (a.subcategoryName != null && a.subcategoryName!.toLowerCase().contains(q)) ||
      (a.specialty != null && a.specialty!.toLowerCase().contains(q)) ||
      a.tags.any((t) => t.toLowerCase().contains(q))
    ).toList();
  }

  /// مقالات مقترحة (متعلقة) — بناءً على categoryId و subcategoryId
  Future<List<SmartArticle>> relatedTo(SmartArticle article, {int limit = 6}) async {
    final all = await loadAll();
    // Prefer same subcategory first, then same category
    final sameSub = article.subcategoryId != null
        ? all.where((a) => a.subcategoryId == article.subcategoryId && a.id != article.id).toList()
        : <SmartArticle>[];
    if (sameSub.length >= limit) {
      sameSub.shuffle();
      return sameSub.take(limit).toList();
    }
    final sameCat = all.where((a) => a.categoryId == article.categoryId && a.id != article.id).toList();
    sameCat.shuffle();
    return sameCat.take(limit).toList();
  }

  /// إحصائيات الأقسام الرئيسية
  Future<Map<String, int>> categoryStats() async {
    final all = await loadAll();
    final stats = <String, int>{};
    for (final a in all) {
      stats[a.categoryId] = (stats[a.categoryId] ?? 0) + 1;
    }
    return stats;
  }

  /// إحصائيات التصنيفات الفرعية لقسم معين
  Future<Map<String, int>> subcategoryStats(String categoryId) async {
    final all = await loadAll();
    final stats = <String, int>{};
    for (final a in all) {
      if (a.categoryId == categoryId && a.subcategoryId != null) {
        stats[a.subcategoryId!] = (stats[a.subcategoryId!] ?? 0) + 1;
      }
    }
    return stats;
  }

  /// جلب مقال بواسطة المعرف (ID)
  Future<SmartArticle?> getById(String id) async {
    final all = await loadAll();
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  /// جلب مقال بواسطة العنوان
  Future<SmartArticle?> getByTitle(String title) async {
    final all = await loadAll();
    final clean = title.trim().toLowerCase();
    try {
      return all.firstWhere((a) => a.title.trim().toLowerCase() == clean);
    } catch (_) {
      try {
        return all.firstWhere((a) => a.title.trim().toLowerCase().contains(clean) || clean.contains(a.title.trim().toLowerCase()));
      } catch (_) {
        return null;
      }
    }
  }
}
