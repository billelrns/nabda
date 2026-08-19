import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';

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
    
    // Fetch stats
    try {
      final statsDoc = await FirebaseFirestore.instance
          .collection('article_stats')
          .doc(widget.articleId)
          .get();
      if (statsDoc.exists && mounted) {
        setState(() {
          _likesCount = statsDoc.data()?['likes'] as int? ?? 0;
        });
      }
    } catch (_) {}

    if (uid != null) {
      try {
        final likedDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('liked_articles')
            .doc(widget.articleId)
            .get();
        final savedDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('saved_articles')
            .doc(widget.articleId)
            .get();
        
        if (mounted) {
          setState(() {
            _isLiked = likedDoc.exists;
            _isSaved = savedDoc.exists;
            _loading = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
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
      if (!originalLiked) {
        // Like the article
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          transaction.set(likedRef, {
            'likedAt': FieldValue.serverTimestamp(),
            'title': widget.articleTitle,
            'section': widget.section,
          });
          transaction.set(statsRef, {
            'likes': FieldValue.increment(1),
            'title': widget.articleTitle,
            'section': widget.section,
          }, SetOptions(merge: true));
        });
      } else {
        // Unlike the article
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          transaction.delete(likedRef);
          transaction.set(statsRef, {
            'likes': FieldValue.increment(-1),
            'title': widget.articleTitle,
            'section': widget.section,
          }, SetOptions(merge: true));
        });
      }
    } catch (e) {
      // Revert if error
      if (mounted) {
        setState(() {
          _isLiked = originalLiked;
          _likesCount = originalCount;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    }
  }

  Future<void> _toggleSave() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('سجّلي الدخول لحفظ المقال 🔖'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final originalSaved = _isSaved;
    setState(() {
      _isSaved = !_isSaved;
    });

    final uid = user.uid;
    final savedRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('saved_articles')
        .doc(widget.articleId);

    try {
      if (!originalSaved) {
        await savedRef.set({
          'savedAt': FieldValue.serverTimestamp(),
          'title': widget.articleTitle,
          'section': widget.section,
        });
      } else {
        await savedRef.delete();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaved = originalSaved;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
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
