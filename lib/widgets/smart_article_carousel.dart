import 'package:flutter/material.dart';
import '../models/smart_article.dart';
import '../services/smart_articles_service.dart';
import '../screens/articles/article_detail_screen.dart';
import '../screens/articles/articles_list_screen.dart';

class SmartArticleCarousel extends StatefulWidget {
  final String? categoryId; // إن كان null، يعرض top viewed من كل الفئات
  final String title;
  final int maxItems;

  const SmartArticleCarousel({
    super.key,
    this.categoryId,
    required this.title,
    this.maxItems = 8,
  });

  @override
  State<SmartArticleCarousel> createState() => _SmartArticleCarouselState();
}

class _SmartArticleCarouselState extends State<SmartArticleCarousel> {
  List<SmartArticle>? _articles;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = SmartArticlesService();
    List<SmartArticle> list;
    if (widget.categoryId != null) {
      list = await service.byCategory(widget.categoryId!);
      // ترتيب حسب الأكثر مشاهدة داخل الفئة
      list.sort((a, b) => b.originalViews.compareTo(a.originalViews));
    } else {
      list = await service.topViewed(limit: widget.maxItems);
    }
    if (!mounted) return;
    setState(() => _articles = list.take(widget.maxItems).toList());
  }

  @override
  Widget build(BuildContext context) {
    if (_articles == null) {
      return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
    }
    if (_articles!.isEmpty) return const SizedBox.shrink();

    final catName = widget.categoryId != null
        ? (categoryNames[widget.categoryId!] ?? _articles!.first.categoryName)
        : '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (widget.categoryId != null)
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ArticlesListScreen(
                    categoryId: widget.categoryId!,
                    categoryName: catName,
                  ),
                )),
                child: const Text('شاهدي المزيد ←',
                    style: TextStyle(color: Color(0xFFE91E63), fontWeight: FontWeight.bold)),
              ),
          ]),
        ),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _articles!.length,
            itemBuilder: (context, i) {
              final a = _articles![i];
              return Container(
                width: 180,
                margin: const EdgeInsets.only(left: 12),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ArticleDetailScreen(article: a),
                    )),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      SizedBox(
                        height: 120,
                        child: Image.asset(
                          a.imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: a.themeColor.withValues(alpha: 0.15),
                            child: Center(child: Text(a.iconEmoji, style: const TextStyle(fontSize: 40))),
                          ),
                        ),
                      ),
                      Expanded(
                          child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(a.title,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, height: 1.3)),
                          const Spacer(),
                          Row(children: [
                            Icon(Icons.schedule, size: 11, color: Colors.grey.shade600),
                            const SizedBox(width: 3),
                            Text(a.readTime, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                            const SizedBox(width: 8),
                            Icon(Icons.visibility, size: 11, color: Colors.grey.shade600),
                            const SizedBox(width: 3),
                            Text('${a.originalViews}',
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                          ]),
                        ]),
                      )),
                    ]),
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}
