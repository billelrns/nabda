import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../community/post_detail_screen.dart';
import '../articles/article_detail_screen.dart';
import '../articles/smart_article_detail_screen.dart';
import '../../services/smart_articles_service.dart';
import '../../models/smart_article.dart';
import '../../data/smart_interactive_articles_data.dart' as interactive_data;

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

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
        ),
        body: uid == null
            ? const Center(child: Text('سجّلي الدخول أولاً للوصول إلى مفضلتكِ'))
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('favorites')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF00897B)));
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
                            const SizedBox(height: 12),
                            Text(
                              'تعذر تحميل المحفوظات، يرجى المحاولة لاحقاً',
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final docs = (snapshot.data?.docs ?? []).toList();
                  docs.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;
                    final aTime = aData['savedAt'];
                    final bTime = bData['savedAt'];
                    if (aTime is Timestamp && bTime is Timestamp) {
                      return bTime.compareTo(aTime);
                    }
                    if (aTime is Timestamp) return -1;
                    if (bTime is Timestamp) return 1;
                    return 0;
                  });

                  if (docs.isEmpty) {
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
                              'احفظي المقالات والمنشورات المهمة لتصلي إليها بسهولة في أي وقت.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 14, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final d = docs[i].data() as Map<String, dynamic>;
                      final isArticle = (d['type'] as String?) == 'article';
                      final postId = d['postId'] as String? ?? docs[i].id;
                      final title = d['title'] as String? ?? 'بدون عنوان';
                      final preview = d['preview'] as String? ?? '';
                      final thumbnail = d['thumbnail'] as String?;
                      final authorName = d['authorName'] as String? ?? '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            if (isArticle) {
                              final articleId = d['articleId'] as String? ?? docs[i].id;

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
                                if (articleId.isNotEmpty) {
                                  art = await SmartArticlesService().getById(articleId);
                                }
                                if (art == null && title.isNotEmpty) {
                                  art = await SmartArticlesService().getByTitle(title);
                                }
                                if (art == null) {
                                  try {
                                    interactiveArt = interactive_data.SmartArticlesDatabase.articles
                                        .firstWhere((a) => a.id == articleId || a.title == title);
                                  } catch (_) {}
                                }
                              } catch (_) {}

                              if (context.mounted) {
                                Navigator.pop(context); // إغلاق مؤشر التحميل
                                if (art != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ArticleDetailScreen(article: art!),
                                    ),
                                  );
                                } else if (interactiveArt != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SmartArticleDetailScreen(article: interactiveArt!),
                                    ),
                                  );
                                } else {
                                  final fallbackArt = SmartArticle(
                                    id: articleId,
                                    originalId: articleId,
                                    rank: 1,
                                    categoryId: d['categoryId'] as String? ?? 'general',
                                    categoryName: d['category'] as String? ?? 'موسوعة نبضة',
                                    title: title,
                                    readTime: '5 دقائق',
                                    author: d['author'] as String? ?? 'فريق نبضة الطبي',
                                    summary: preview,
                                    iconEmoji: '📖',
                                    themeColor: const Color(0xFF00897B),
                                    sections: [
                                      ArticleSection(
                                        title: 'محتوى المقال',
                                        content: preview.isNotEmpty ? preview : title,
                                      ),
                                    ],
                                    faqs: const [],
                                    originalViews: 1,
                                    imagePath: thumbnail ?? 'assets/images/logo_nabda.png',
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ArticleDetailScreen(article: fallbackArt),
                                    ),
                                  );
                                }
                              }
                            } else if (postId.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PostDetailScreen(postId: postId),
                                ),
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
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF00897B)
                                                .withOpacity(0.10),
                                            borderRadius:
                                                BorderRadius.circular(999),
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
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF00897B), fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                                  tooltip: 'إزالة من المفضلة',
                                  onPressed: () => docs[i].reference.delete(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
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
