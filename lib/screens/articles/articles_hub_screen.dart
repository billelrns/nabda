import 'package:flutter/material.dart';
import '../../models/smart_article.dart';
import '../../services/smart_articles_service.dart';
import 'articles_list_screen.dart';
import 'article_detail_screen.dart';
import 'articles_search_screen.dart';

class ArticlesHubScreen extends StatefulWidget {
  const ArticlesHubScreen({Key? key}) : super(key: key);
  @override
  State<ArticlesHubScreen> createState() => _ArticlesHubScreenState();
}

class _ArticlesHubScreenState extends State<ArticlesHubScreen> {
  final _service = SmartArticlesService();
  Map<String, int>? _stats;
  List<SmartArticle>? _featured;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await _service.categoryStats();
    final featured = await _service.topViewed(limit: 10);
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _featured = featured;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('موسوعة نبضة', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFFE91E63),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const ArticlesSearchScreen(),
              )),
            ),
          ],
        ),
        body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE91E63)))
          : ListView(children: [
              _buildHero(),
              const SizedBox(height: 16),
              _buildCategoriesGrid(),
              const SizedBox(height: 24),
              _buildFeaturedSection(),
              const SizedBox(height: 32),
            ]),
      ),
    );
  }

  Widget _buildHero() {
    final total = _stats?.values.fold(0, (a, b) => a + b) ?? 2500;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFFAB47BC)],
        ),
      ),
      child: Column(children: [
        const Icon(Icons.auto_stories, size: 40, color: Colors.white),
        const SizedBox(height: 12),
        Text('$total مقال طبي موثّق',
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('كل ما تحتاجينه لصحتك ورعاية طفلك',
          style: TextStyle(color: Colors.white70, fontSize: 14)),
      ]),
    );
  }

  Widget _buildCategoriesGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.3,
        children: categoryNames.entries.map((entry) {
          final categoryId = entry.key;
          final name = entry.value;
          final count = _stats?[categoryId] ?? 0;
          final emoji = categoryEmojis[categoryId] ?? '📖';
          final color = Color(categoryColors[categoryId] ?? 0xFFE91E63);
          return InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ArticlesListScreen(categoryId: categoryId, categoryName: name),
            )),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(colors: [color.withOpacity(0.85), color]),
                boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 30)),
                  const SizedBox(height: 6),
                  Text(name, textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('$count مقال',
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeaturedSection() {
    if (_featured == null || _featured!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🔥 الأكثر قراءة',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._featured!.take(5).map((a) => _articleTile(a)).toList(),
      ]),
    );
  }

  Widget _articleTile(SmartArticle a) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: a.themeColor.withOpacity(0.15),
        child: Text(a.iconEmoji, style: const TextStyle(fontSize: 22)),
      ),
      title: Text(a.title, maxLines: 2, overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      subtitle: Row(children: [
        const Icon(Icons.visibility, size: 12, color: Colors.grey),
        const SizedBox(width: 4),
        Text('${a.originalViews}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(width: 12),
        const Icon(Icons.schedule, size: 12, color: Colors.grey),
        const SizedBox(width: 4),
        Text(a.readTime, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ]),
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => ArticleDetailScreen(article: a),
      )),
    ),
  );
}
