import 'package:flutter/material.dart';
import '../../models/smart_article.dart';
import '../../services/smart_articles_service.dart';
import 'article_detail_screen.dart';

class ArticlesListScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  const ArticlesListScreen({Key? key, required this.categoryId, required this.categoryName}) : super(key: key);
  @override
  State<ArticlesListScreen> createState() => _ArticlesListScreenState();
}

class _ArticlesListScreenState extends State<ArticlesListScreen> {
  final _service = SmartArticlesService();
  final _controller = ScrollController();
  List<SmartArticle> _all = [];
  List<SmartArticle> _shown = [];
  int _page = 0;
  static const _pageSize = 20;
  bool _loading = true;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _load();
    _controller.addListener(_onScroll);
  }

  Future<void> _load() async {
    final list = await _service.byCategory(widget.categoryId);
    if (!mounted) return;
    setState(() {
      _all = list;
      _shown = list.take(_pageSize).toList();
      _loading = false;
    });
  }

  void _onScroll() {
    if (_loadingMore || _shown.length >= _all.length) return;
    if (_controller.position.pixels > _controller.position.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  void _loadMore() {
    setState(() {
      _loadingMore = true;
      _page++;
      _shown = _all.take((_page + 1) * _pageSize).toList();
      _loadingMore = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.categoryName),
          backgroundColor: const Color(0xFFE91E63),
          foregroundColor: Colors.white,
        ),
        body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE91E63)))
          : ListView.builder(
              controller: _controller,
              padding: const EdgeInsets.all(12),
              itemCount: _shown.length + 1,
              itemBuilder: (context, i) {
                if (i == _shown.length) {
                  if (_shown.length >= _all.length) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: Text('عرضتِ كل المقالات ✓', style: TextStyle(color: Colors.grey))),
                    );
                  }
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final a = _shown[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ArticleDetailScreen(article: a),
                    )),
                    child: Row(children: [
                      Container(
                        width: 100, height: 120,
                        color: a.themeColor.withOpacity(0.15),
                        child: Image.asset(a.imagePath, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(a.iconEmoji, style: const TextStyle(fontSize: 40)),
                          )),
                      ),
                      Expanded(child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          if (a.badge != null) Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: a.themeColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(a.badge!, style: TextStyle(fontSize: 10, color: a.themeColor, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 6),
                          Text(a.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(a.summary, maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          const SizedBox(height: 6),
                          Row(children: [
                            Icon(Icons.schedule, size: 12, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(a.readTime, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            const SizedBox(width: 12),
                            Icon(Icons.visibility, size: 12, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text('${a.originalViews}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          ]),
                        ]),
                      )),
                    ]),
                  ),
                );
              },
            ),
      ),
    );
  }
}
