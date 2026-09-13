import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../community/post_detail_screen.dart';
import '../articles/article_detail_screen.dart';
import '../articles/smart_article_detail_screen.dart';
import '../../services/smart_articles_service.dart';
import '../../services/favorites_service.dart';
import '../../models/smart_article.dart';
import '../../data/smart_interactive_articles_data.dart' as interactive_data;

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoritesService _favoritesService = FavoritesService();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _favoritesService.changeNotifier.addListener(_onFavoritesChanged);
  }

  @override
  void dispose() {
    _favoritesService.changeNotifier.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (mounted) {
      _loadFavorites(silent: true);
    }
  }

  Future<void> _loadFavorites({bool silent = false}) async {
    if (!silent) {
      setState(() => _loading = true);
    }
    final list = await _favoritesService.getAllFavorites();
    if (mounted) {
      setState(() {
        _items = list;
        _loading = false;
      });
    }
  }

  Future<void> _openArticle(Map<String, dynamic> d) async {
    final articleId = (d['articleId'] ?? d['id'] ?? '').toString();
    final title = (d['title'] ?? '').toString();
    final preview = (d['preview'] ?? '').toString();
    final thumbnail = d['thumbnail'] as String?;
    final category = (d['category'] ?? 'موسوعة نبضة').toString();
    final categoryId = (d['categoryId'] ?? 'general').toString();
    final author = (d['author'] ?? 'فريق نبضة الطبي').toString();
    final readTime = (d['readTime'] ?? '5 دقائق').toString();
    final hexStr = (d['themeColorHex'] as String? ?? '#00897B').replaceAll('#', '');
    final themeColor = Color(int.parse('FF$hexStr', radix: 16));

    // إظهار مؤشر تحميل خفيف
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF00897B)),
      ),
    );

    SmartArticle? art;
    interactive_data.SmartArticle? interactiveArt;

    try {
      // 1. محاولة جلب المقال من موسوعة نبضة بمهلة قصيرة لتجنب التجميد
      if (articleId.isNotEmpty) {
        art = await SmartArticlesService()
            .getById(articleId)
            .timeout(const Duration(milliseconds: 1200), onTimeout: () => null);
      }
      if (art == null && title.isNotEmpty) {
        art = await SmartArticlesService()
            .getByTitle(title)
            .timeout(const Duration(milliseconds: 1200), onTimeout: () => null);
      }

      // 2. محاولة جلب المقال التفاعلي
      if (art == null) {
        try {
          interactiveArt = interactive_data.SmartArticlesDatabase.articles
              .firstWhere((a) => a.id == articleId || a.title == title);
        } catch (_) {}
      }
    } catch (_) {}

    if (!mounted) return;
    Navigator.pop(context); // إغلاق مؤشر التحميل

    if (art != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: art!)),
      );
    } else if (interactiveArt != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SmartArticleDetailScreen(article: interactiveArt!)),
      );
    } else {
      // 3. بناء فوري للمقال من البيانات المحفوظة محلياً لضمان الفتح الفوري
      final fallbackArt = SmartArticle(
        id: articleId.isNotEmpty ? articleId : 'saved_${title.hashCode}',
        originalId: articleId,
        rank: 1,
        categoryId: categoryId,
        categoryName: category,
        title: title.isNotEmpty ? title : 'مقال طبي محفوظ',
        readTime: readTime,
        author: author,
        summary: preview,
        iconEmoji: '📖',
        themeColor: themeColor,
        sections: [
          ArticleSection(
            title: 'محتوى المقال',
            content: preview.isNotEmpty
                ? preview
                : 'محتوى المقال متاح في موسوعة نبضة الطبية الشاملة.',
          ),
        ],
        faqs: const [],
        originalViews: 1,
        imagePath: thumbnail ?? 'assets/images/logo_nabda.png',
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: fallbackArt)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8FB),
        appBar: AppBar(
          title: const Text('المفضلة', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF00897B),
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'تحديث',
              onPressed: () => _loadFavorites(),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF00897B)))
            : Column(
                children: [
                  if (uid == null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: const Color(0xFFE0F2F1),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 18, color: Color(0xFF00897B)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'مقالاتكِ محفوظة على هذا الهاتف محلياً ✓',
                              style: TextStyle(fontSize: 12, color: Colors.teal.shade900, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: _items.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            itemCount: _items.length,
                            itemBuilder: (context, i) {
                              final d = _items[i];
                              final isArticle = (d['type'] as String?) == 'article' || d['type'] == null;
                              final id = (d['articleId'] ?? d['id'] ?? d['postId'] ?? '').toString();
                              final postId = (d['postId'] ?? id).toString();
                              final title = (d['title'] as String?) ?? 'بدون عنوان';
                              final preview = (d['preview'] as String?) ?? '';
                              final thumbnail = d['thumbnail'] as String?;
                              final authorName = (d['authorName'] ?? d['author'] as String?) ?? '';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                elevation: 1,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    if (isArticle) {
                                      _openArticle(d);
                                    } else if (postId.isNotEmpty) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => PostDetailScreen(postId: postId)),
                                      );
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: thumbnail != null && thumbnail.isNotEmpty
                                              ? (thumbnail.startsWith('http')
                                                  ? Image.network(
                                                      thumbnail,
                                                      width: 60,
                                                      height: 60,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, __, ___) => _fallbackThumb(isArticle),
                                                    )
                                                  : Image.asset(
                                                      thumbnail,
                                                      width: 60,
                                                      height: 60,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, __, ___) => _fallbackThumb(isArticle),
                                                    ))
                                              : _fallbackThumb(isArticle),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                title,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (preview.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  preview,
                                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                              if (isArticle) ...[
                                                const SizedBox(height: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF00897B).withOpacity(0.10),
                                                    borderRadius: BorderRadius.circular(999),
                                                  ),
                                                  child: const Text(
                                                    '📖 مقال محفوظ',
                                                    style: TextStyle(
                                                        fontSize: 10.5,
                                                        color: Color(0xFF00897B),
                                                        fontWeight: FontWeight.w700),
                                                  ),
                                                ),
                                              ] else if (authorName.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  authorName,
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Color(0xFF00897B),
                                                      fontWeight: FontWeight.w600),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                                          tooltip: 'إزالة من المفضلة',
                                          onPressed: () async {
                                            await _favoritesService.removeFavorite(id);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('تمت إزالة المقال من المفضلة'),
                                                  duration: Duration(seconds: 2),
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'لا توجد عناصر محفوظة',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'احفظي مقالات موسوعة نبضة (6,982 مقالاً) بالضغط على زر 🔖 لتصلي إليها بسهولة في أي وقت حتى بدون إنترنت.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackThumb(bool isArticle) {
    return Container(
      width: 60,
      height: 60,
      color: isArticle ? const Color(0xFFE0F2F1) : const Color(0xFFFFF0F5),
      child: Icon(
        isArticle ? Icons.menu_book_rounded : Icons.bookmark,
        color: isArticle ? const Color(0xFF00897B) : const Color(0xFFE91E63),
        size: 28,
      ),
    );
  }
}
