import 'package:flutter/material.dart';
import '../../models/smart_article.dart';
import '../../services/smart_articles_service.dart';
import 'article_detail_screen.dart';

class ArticlesSearchScreen extends StatefulWidget {
  const ArticlesSearchScreen({Key? key}) : super(key: key);
  @override
  State<ArticlesSearchScreen> createState() => _ArticlesSearchScreenState();
}

class _ArticlesSearchScreenState extends State<ArticlesSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final SmartArticlesService _service = SmartArticlesService();
  List<SmartArticle> _results = [];
  bool _searching = false;
  String _lastQuery = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    final query = q.trim();
    if (query.length < 2) {
      if (mounted) {
        setState(() {
          _results = [];
          _searching = false;
          _lastQuery = query;
        });
      }
      return;
    }
    setState(() {
      _searching = true;
      _lastQuery = query;
    });

    final r = await _service.search(query);
    if (!mounted) return;
    setState(() {
      _results = r.take(50).toList();
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFE91E63),
          foregroundColor: Colors.white,
          title: TextField(
            controller: _controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.white,
            decoration: const InputDecoration(
              hintText: 'ابحثي في 2,500 مقال...',
              hintStyle: TextStyle(color: Colors.white70),
              border: InputBorder.none,
            ),
            onChanged: _search,
          ),
          actions: [
            if (_controller.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  _search('');
                },
              ),
          ],
        ),
        body: _searching
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFE91E63)))
            : _controller.text.trim().length < 2
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text(
                          'ابدئي بكتابة كلمة للبحث في الموسوعة',
                          style: TextStyle(color: Colors.grey, fontSize: 15),
                        ),
                      ],
                    ),
                  )
                : _results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              'لا توجد مقالات مطابقة لـ "$_lastQuery"',
                              style: const TextStyle(color: Colors.grey, fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final a = _results[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: a.themeColor.withOpacity(0.15),
                              child: Text(a.iconEmoji, style: const TextStyle(fontSize: 20)),
                            ),
                            title: Text(
                              a.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Row(
                              children: [
                                Text(
                                  a.categoryName,
                                  style: TextStyle(color: a.themeColor, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 12),
                                Icon(Icons.schedule, size: 12, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text(
                                  a.readTime,
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: a)),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
