import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';

import '../services/favorites_service.dart';

class ArticleEngagementBar extends StatefulWidget {
  final String articleId;
  final String articleTitle;
  final String section;
  final Color color;

  const ArticleEngagementBar({
    Key? key,
    required this.articleId,
    required this.articleTitle,
    required this.section,
    required this.color,
  }) : super(key: key);

  @override
  State<ArticleEngagementBar> createState() => _ArticleEngagementBarState();
}

class _ArticleEngagementBarState extends State<ArticleEngagementBar> {
  bool _isLiked = false;
  bool _isSaved = false;
  int _likesCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialStates();
  }

  Future<void> _fetchInitialStates() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    int likes = 0;
    bool liked = false;
    bool saved = FavoritesService().isBookmarked(widget.articleId);

    try {
      final db = FirebaseFirestore.instance;
      final statsDoc = await db
          .collection('article_stats')
          .doc(widget.articleId)
          .get()
          .timeout(const Duration(seconds: 4));
      likes = (statsDoc.data()?['likes'] as num?)?.toInt() ?? 0;

      if (uid != null) {
        final likedDoc = await db
            .collection('users')
            .doc(uid)
            .collection('liked_articles')
            .doc(widget.articleId)
            .get()
            .timeout(const Duration(seconds: 3));
        liked = likedDoc.exists;
      }
    } catch (_) {
      // نتجاهل الخطأ ونعرض القيم الافتراضية
    }

    if (!saved) {
      saved = await FavoritesService().checkIsBookmarked(widget.articleId);
    }

    if (!mounted) return;
    setState(() {
      _likesCount = likes;
      _isLiked = liked;
      _isSaved = saved;
      _loading = false;
    });
  }

  Future<void> _toggleLike() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('سجّلي الدخول لحفظ إعجابك 💗'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final originalLiked = _isLiked;
    final originalCount = _likesCount;

    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });

    final uid = user.uid;
    final likedRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('liked_articles')
        .doc(widget.articleId);
    
    final statsRef = FirebaseFirestore.instance
        .collection('article_stats')
        .doc(widget.articleId);

    try {
      // WriteBatch بدل runTransaction: ذرّي أيضاً ولا يتطلّب قراءة قبل الكتابة،
      // وهذا يتجنّب خطأ Firestore على الويب:
      // INTERNAL ASSERTION FAILED: Unexpected state
      final batch = FirebaseFirestore.instance.batch();
      if (!originalLiked) {
        batch.set(likedRef, {
          'likedAt': FieldValue.serverTimestamp(),
          'title': widget.articleTitle,
          'section': widget.section,
        });
        batch.set(statsRef, {
          'likes': FieldValue.increment(1),
          'title': widget.articleTitle,
          'section': widget.section,
        }, SetOptions(merge: true));
      } else {
        batch.delete(likedRef);
        batch.set(statsRef, {
          'likes': FieldValue.increment(-1),
          'title': widget.articleTitle,
          'section': widget.section,
        }, SetOptions(merge: true));
      }
      await batch.commit();
    } catch (e) {
      // Revert if error
      if (mounted) {
        setState(() {
          _isLiked = originalLiked;
          _likesCount = originalCount;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذّر حفظ الإعجاب، حاولي مجدداً'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      debugPrint('like error: $e');
    }
  }

  Future<void> _toggleSave() async {
    final hex = widget.color.value.toRadixString(16).padLeft(8, '0');
    final colorHex = '#${hex.substring(2)}';

    final newStatus = await FavoritesService().toggleArticle(
      articleId: widget.articleId,
      title: widget.articleTitle,
      summary: 'مقال محفوظ من قسم ${_sectionLabel(widget.section)}',
      category: _sectionLabel(widget.section),
      categoryId: widget.section,
      imagePath: 'assets/images/logo_nabda.png',
      themeColorHex: colorHex,
    );

    if (mounted) {
      setState(() {
        _isSaved = newStatus;
      });
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                newStatus ? Icons.bookmark_added_rounded : Icons.bookmark_remove_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                newStatus
                    ? 'تم حفظ المقال في المفضلة بنجاح 🤍'
                    : 'تمت إزالة المقال من المفضلة',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: newStatus ? const Color(0xFF00897B) : const Color(0xFFE91E63),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  static String _sectionLabel(String s) {
    switch (s) {
      case 'pregnancy':
        return 'الحمل';
      case 'baby':
        return 'الطفل';
      case 'cycle':
        return 'الدورة';
      case 'news':
        return 'الأخبار';
      default:
        return 'نبضة';
    }
  }

  Future<void> _shareArticle() async {
    // عدّاد المشاركة يُكتب فقط للمسجّلات (قواعد Firestore تمنع غير المسجّلة)
    if (FirebaseAuth.instance.currentUser != null) {
      FirebaseFirestore.instance
          .collection('article_stats')
          .doc(widget.articleId)
          .set({
        'shares': FieldValue.increment(1),
        'title': widget.articleTitle,
        'section': widget.section,
      }, SetOptions(merge: true)).catchError((_) {});
    }

    // المشاركة نفسها متاحة للجميع
    await Share.share(
      '${widget.articleTitle}\n\nاقرئي المقال في تطبيق نبضة 💗\nhttps://nabda.online',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: widget.color.withOpacity(0.15), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Likes
            Row(
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : Colors.grey,
                  ),
                  onPressed: _toggleLike,
                ),
                const SizedBox(width: 8),
                Text(
                  _loading ? '...' : '$_likesCount إعجاب',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            // Share and Save
            Row(
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.share, color: Colors.grey),
                  onPressed: _shareArticle,
                ),
                const SizedBox(width: 16),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    _isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: _isSaved ? widget.color : Colors.grey,
                  ),
                  onPressed: _toggleSave,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
