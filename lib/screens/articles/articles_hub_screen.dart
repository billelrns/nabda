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
  List<SmartArticle>? _latest;
  bool _loading = true;

  // The 6 canonical primary categories
  static const List<String> _mainCategoryKeys = [
    'pregnancy',
    'baby',
    'fertility',
    'health',
    'beauty',
    'marriage',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await _service.categoryStats();
    final featured = await _service.topViewed(limit: 8);
    final latest = await _service.latestArticles(limit: 6);
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _featured = featured;
      _latest = latest;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('موسوعة نبضة الطبية', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFFE91E63),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'بحث في 6,982 مقالاً',
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
              const SizedBox(height: 12),
              _buildSectionHeader('الأقسام والتصنيفات الطبية 📚', 'تصفحي مقالات نبضة الموزعة سريرياً حسب مجالكِ'),
              const SizedBox(height: 12),
              _buildCategoriesList(),
              const SizedBox(height: 24),
              _buildFeaturedSection(),
              const SizedBox(height: 24),
              _buildLatestSection(),
              const SizedBox(height: 32),
            ]),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D2D3A))),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildHero() {
    final total = _stats?.values.fold(0, (a, b) => a + b) ?? 6982;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFFAB47BC)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFFE91E63).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(children: [
        const Icon(Icons.auto_stories, size: 44, color: Colors.white),
        const SizedBox(height: 10),
        Text('$total مقال طبي وتفاعلي موثّق',
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('أضخم موسوعة رقمية موثقة لصحة المرأة والأمومة والطفل بـ 28 تصنيفاً تخصصياً',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.4)),
        const SizedBox(height: 14),
        InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => const ArticlesSearchScreen(),
          )),
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search, size: 16, color: Colors.white),
                SizedBox(width: 8),
                Text('ابحثي في كل الموضوعات والأسئلة الشائعة...',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildCategoriesList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _mainCategoryKeys.map((catKey) {
          final name = categoryNames[catKey] ?? catKey;
          final count = _stats?[catKey] ?? 0;
          final emoji = categoryEmojis[catKey] ?? '📖';
          final color = Color(categoryColors[catKey] ?? 0xFFE91E63);
          final subcats = subcategoriesByCategory[catKey] ?? [];

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header of category
                InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ArticlesListScreen(categoryId: catKey, categoryName: name),
                  )),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withOpacity(0.12),
                          ),
                          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text('$count مقالاً متاحاً', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Text('اكتشفي المزيد', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios, size: 10, color: color),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Subcategories Chips horizontal scroll
                if (subcats.isNotEmpty) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(
                      height: 38,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: subcats.length,
                        itemBuilder: (context, idx) {
                          final subId = subcats[idx];
                          final subName = subcategoryNames[subId] ?? subId;
                          final subEmoji = subcategoryEmojis[subId] ?? '📌';
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ActionChip(
                              avatar: Text(subEmoji, style: const TextStyle(fontSize: 13)),
                              label: Text(subName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                              backgroundColor: Colors.grey.shade50,
                              side: BorderSide(color: Colors.grey.shade300, width: 0.8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              onPressed: () => Navigator.push(context, MaterialPageRoute(
                                builder: (_) => ArticlesListScreen(
                                  categoryId: catKey,
                                  categoryName: name,
                                  initialSubcategoryId: subId,
                                ),
                              )),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ],
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('🔥 الأكثر قراءة وتفاعلاً',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text('من بين 6,982 مقالاً', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
        const SizedBox(height: 12),
        ..._featured!.map((a) => _articleTile(a)).toList(),
      ]),
    );
  }

  Widget _buildLatestSection() {
    if (_latest == null || _latest!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('✨ مقالات أُضيفت حديثاً للموسوعة',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text('عناوين حصرية ومشوقة', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
        const SizedBox(height: 12),
        ..._latest!.map((a) => _articleTile(a)).toList(),
      ]),
    );
  }

  Widget _articleTile(SmartArticle a) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: a.themeColor.withOpacity(0.15),
        child: Text(a.iconEmoji, style: const TextStyle(fontSize: 22)),
      ),
      title: Text(a.title, maxLines: 2, overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(children: [
          if (a.subcategoryName != null) ...[
            Flexible(
              child: Text(
                '${a.subcategoryEmoji ?? "📌"} ${a.subcategoryName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: a.themeColor, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 6),
          ],
          const Icon(Icons.visibility, size: 11, color: Colors.grey),
          const SizedBox(width: 3),
          Text('${a.originalViews}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(width: 6),
          const Icon(Icons.schedule, size: 11, color: Colors.grey),
          const SizedBox(width: 3),
          Text(a.readTime, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ]),
      ),
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => ArticleDetailScreen(article: a),
      )),
    ),
  );
}
