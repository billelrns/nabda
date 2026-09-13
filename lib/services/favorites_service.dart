import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// خدمة إدارة المفضلة والمحفوظات لنبضة (موسوعة 6,982 مقالاً، مقالات تفاعلية، ومنشورات).
/// بنية هجينة موثوقة (Offline-First Dual Storage):
/// 1. حفظ فوري محلي في SharedPreferences يعمل دائماً بدون إنترنت وبدون الحاجة لتسجيل الدخول (Guest Support).
/// 2. مزامنة سحابية متوازية مع Firestore (users/{uid}/favorites/{id}) عند توفر حساب مسجّل.
/// 3. إشعار تفاعلي فوري لجميع الشاشات عبر ValueNotifier و Stream.
class FavoritesService {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  static const String _prefsKey = 'nabda_local_favorites_v2';
  static const String _idsKey = 'nabda_local_fav_ids_v2';

  final Set<String> _cachedIds = {};
  final List<Map<String, dynamic>> _cachedList = [];
  bool _initialized = false;

  /// مشعر تفاعلي لتحديث واجهات التطبيق فوراً عند الحفظ أو الحذف
  final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);

  /// تهيئة الكاش المحلي عند بدء تشغيل التطبيق
  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final idsList = prefs.getStringList(_idsKey) ?? [];
      _cachedIds.clear();
      _cachedIds.addAll(idsList);

      final rawJsonList = prefs.getStringList(_prefsKey) ?? [];
      _cachedList.clear();
      for (final raw in rawJsonList) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          _cachedList.add(map);
        } catch (_) {}
      }
      _initialized = true;
      changeNotifier.value++;
    } catch (e) {
      debugPrint('FavoritesService.init error: $e');
    }
  }

  /// فحص فوري سريع (0ms) هل العنصر محفوظ في المفضلة
  bool isBookmarked(String id) {
    if (!_initialized) {
      // إطلاق التهيئة بالخلفية إن لم تكن مكتملة بعد
      init();
    }
    return _cachedIds.contains(id.trim());
  }

  /// فحص غير متزامن يضمن قراءة التخزين المحلي والتحقق
  Future<bool> checkIsBookmarked(String id) async {
    if (!_initialized) {
      await init();
    }
    final cleanId = id.trim();
    if (_cachedIds.contains(cleanId)) return true;

    // فحص اختياري من Firestore إن كان المستخدم مسجلاً
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('favorites')
            .doc(cleanId)
            .get();
        if (doc.exists) {
          _cachedIds.add(cleanId);
          changeNotifier.value++;
          return true;
        }
      } catch (_) {}
    }

    return false;
  }

  /// تبديل حالة حفظ مقال (حفظ أو إزالة)
  /// يعيد true إذا أصبح محفوظاً، أو false إذا أزيل.
  Future<bool> toggleArticle({
    required String articleId,
    required String title,
    required String summary,
    required String category,
    required String categoryId,
    required String imagePath,
    String? author,
    String? readTime,
    String? themeColorHex,
  }) async {
    if (!_initialized) await init();
    final cleanId = articleId.trim();
    final wasBookmarked = _cachedIds.contains(cleanId);
    final nowBookmarked = !wasBookmarked;

    final itemMap = {
      'type': 'article',
      'articleId': cleanId,
      'title': title,
      'preview': summary,
      'thumbnail': imagePath,
      'category': category,
      'categoryId': categoryId,
      'author': author ?? 'فريق نبضة الطبي',
      'readTime': readTime ?? '5 دقائق',
      'themeColorHex': themeColorHex ?? '#00897B',
      'savedAtMillis': DateTime.now().millisecondsSinceEpoch,
    };

    // 1. التحديث المحلي الفوري (مضمون 100% بدون إنترنت وبدون حساب)
    if (nowBookmarked) {
      _cachedIds.add(cleanId);
      _cachedList.removeWhere((item) => (item['articleId'] ?? item['id']) == cleanId);
      _cachedList.insert(0, itemMap);
    } else {
      _cachedIds.remove(cleanId);
      _cachedList.removeWhere((item) => (item['articleId'] ?? item['id']) == cleanId);
    }

    await _persistLocal();
    changeNotifier.value++;

    // 2. المزامنة المتوازية مع Firestore إن وجد حساب
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _syncToFirestore(uid, cleanId, nowBookmarked, itemMap);
    }

    return nowBookmarked;
  }

  /// إزالة عنصر من المفضلة
  Future<void> removeFavorite(String id) async {
    if (!_initialized) await init();
    final cleanId = id.trim();
    _cachedIds.remove(cleanId);
    _cachedList.removeWhere((item) =>
        (item['articleId'] ?? item['id'] ?? item['postId']) == cleanId);

    await _persistLocal();
    changeNotifier.value++;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('favorites')
            .doc(cleanId)
            .delete();
      } catch (_) {}
    }
  }

  /// حفظ الحالة في SharedPreferences
  Future<void> _persistLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_idsKey, _cachedIds.toList());
      final rawList = _cachedList.map((m) => jsonEncode(m)).toList();
      await prefs.setStringList(_prefsKey, rawList);
    } catch (e) {
      debugPrint('Error persisting local favorites: $e');
    }
  }

  /// مزامنة في الخلفية مع Firestore دون تعطيل واجهة المستخدم
  void _syncToFirestore(String uid, String articleId, bool isSaved, Map<String, dynamic> itemMap) {
    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(articleId);

    if (isSaved) {
      favRef.set({
        ...itemMap,
        'savedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).catchError((e) {
        debugPrint('Cloud favorites sync set error (saved locally): $e');
      });
    } else {
      favRef.delete().catchError((e) {
        debugPrint('Cloud favorites sync delete error: $e');
      });
    }
  }

  /// جلب القائمة الكاملة الموحدة (محلي + سحابي مدمج)
  Future<List<Map<String, dynamic>>> getAllFavorites() async {
    if (!_initialized) await init();

    final result = List<Map<String, dynamic>>.from(_cachedList);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      try {
        final query = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('favorites')
            .get();

        bool hasNewCloudItems = false;
        for (final doc in query.docs) {
          final data = doc.data();
          final id = (data['articleId'] ?? data['postId'] ?? doc.id).toString();
          if (!_cachedIds.contains(id)) {
            _cachedIds.add(id);
            final unified = {
              ...data,
              'id': id,
              'articleId': data['articleId'] ?? id,
              'title': data['title'] ?? 'بدون عنوان',
              'preview': data['preview'] ?? '',
              'thumbnail': data['thumbnail'],
              'savedAtMillis': (data['savedAt'] is Timestamp)
                  ? (data['savedAt'] as Timestamp).millisecondsSinceEpoch
                  : DateTime.now().millisecondsSinceEpoch,
            };
            result.add(unified);
            _cachedList.add(unified);
            hasNewCloudItems = true;
          }
        }

        if (hasNewCloudItems) {
          await _persistLocal();
          changeNotifier.value++;
        }
      } catch (e) {
        debugPrint('Error fetching cloud favorites, using local: $e');
      }
    }

    // ترتيب تنازلي حسب وقت الحفظ
    result.sort((a, b) {
      final aTime = (a['savedAtMillis'] as num?)?.toInt() ?? 0;
      final bTime = (b['savedAtMillis'] as num?)?.toInt() ?? 0;
      return bTime.compareTo(aTime);
    });

    return result;
  }
}
