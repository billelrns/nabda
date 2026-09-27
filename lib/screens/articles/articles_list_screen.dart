import 'package:flutter/material.dart';
import '../../models/smart_article.dart';
import '../../services/smart_articles_service.dart';
import '../../config/play_compliance.dart';
import 'article_detail_screen.dart';
import 'articles_search_screen.dart';

class ArticlesListScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final String? initialSubcategoryId;

  const ArticlesListScreen({
    Key? key,
    required this.categoryId,
    required this.categoryName,
    this.initialSubcategoryId,
  }) : super(key: key);

  @override
  State<ArticlesListScreen> createState() => _ArticlesListScreenState();
}

class _ArticlesListScreenState extends State<ArticlesListScreen> {
  final _service = SmartArticlesService();
  final _controller = ScrollController();
  List<SmartArticle> _categoryAll = [];
  List<SmartArticle> _filtered = [];
  List<SmartArticle> _shown = [];
  String? _selectedSubcategory;
  int _page = 0;
  static const _pageSize = 20;
  bool _loading = true;
  bool _loadingMore = false;
  Map<String, int> _subCounts = {};

  @override
  void initState() {
    super.initState();
    _selectedSubcategory = widget.initialSubcategoryId;
    _load();
    _controller.addListener(_onScroll);
  }

  Future<void> _load() async {
    final list = await _service.byCategory(widget.categoryId);
    final counts = <String, int>{};
    for (final a in list) {
      if (a.subcategoryId != null) {
        counts[a.subcategoryId!] = (counts[a.subcategoryId!] ?? 0) + 1;
      }
    }
    if (!mounted) return;
    setState(() {
      _categoryAll = list;
      _subCounts = counts;
      _applySubcategoryFilter();
      _loading = false;
    });
  }

  void _applySubcategoryFilter() {
    if (_selectedSubcategory == null || _selectedSubcategory == 'all') {
      _filtered = _categoryAll;
    } else {
      _filtered = _categoryAll.where((a) => a.subcategoryId == _selectedSubcategory).toList();
    }
    _page = 0;
    _shown = _filtered.take(_pageSize).toList();
  }

  void _onScroll() {
    if (_loadingMore || _shown.length >= _filtered.length) return;
    if (_controller.position.pixels > _controller.position.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  void _loadMore() {
    setState(() {
      _loadingMore = true;
      _page++;
      _shown = _filtered.take((_page + 1) * _pageSize).toList();
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
    final catColor = Color(categoryColors[widget.categoryId] ?? 0xFFE91E63);
    final subcatKeys = (subcategoriesByCategory[widget.categoryId] ?? const <String>[])
        .where((s) => !isHiddenSubcategory(s))
        .toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.categoryName, style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: catColor,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'بحث في المقالات',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ArticlesSearchScreen()),
              ),
            ),
          ],
        ),
        body: _loading
            ? Center(child: CircularProgressIndicator(color: catColor))
            : Column(
                children: [
                  // ── Subcategories Filter Chips ──
                  if (subcatKeys.isNotEmpty)
                    Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                      ),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        children: [
                          _buildSubChip(
                            label: 'الكل (${_categoryAll.length})',
                            emoji: '📑',
                            selected: _selectedSubcategory == null || _selectedSubcategory == 'all',
                            onTap: () {
                              setState(() {
                                _selectedSubcategory = 'all';
                                _applySubcategoryFilter();
                              });
                            },
                            color: catColor,
                          ),
                          for (final subId in subcatKeys)
                            _buildSubChip(
                              label: '${subcategoryNames[subId] ?? subId} (${_subCounts[subId] ?? 0})',
                              emoji: subcategoryEmojis[subId] ?? '📌',
                              selected: _selectedSubcategory == subId,
                              onTap: () {
                                setState(() {
                                  _selectedSubcategory = subId;
                                  _applySubcategoryFilter();
                                });
                              },
                              color: catColor,
                            ),
                        ],
                      ),
                    ),

                  // ── Articles List ──
                  Expanded(
                    child: _filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'لا توجد مقالات متوفرة في هذا التصنيف حالياً',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          )
                        : ListView.builder(
                            controller: _controller,
                            padding: const EdgeInsets.all(12),
                            itemCount: _shown.length + 1,
                            itemBuilder: (context, i) {
                              if (i == _shown.length) {
                                if (_shown.length >= _filtered.length) {
                                  return Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Center(
                                      child: Text(
                                        'عرضتِ كل مقالات هذا التصنيف (${_filtered.length}) ✓',
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                    ),
                                  );
                                }
                                return const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }
                              final a = _shown[i];
                              return _buildArticleCard(a, catColor);
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSubChip({
    required String label,
    required String emoji,
    required bool selected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        avatar: Text(emoji, style: const TextStyle(fontSize: 14)),
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: color.withOpacity(0.18),
        checkmarkColor: color,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? color : Colors.grey.shade800,
        ),
        backgroundColor: Colors.grey.shade100,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 1.5 : 0.8,
          ),
        ),
      ),
    );
  }

  Widget _buildArticleCard(SmartArticle a, Color catColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: a)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 105,
              height: 125,
              color: a.themeColor.withOpacity(0.12),
              child: Image.asset(
                a.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(a.iconEmoji, style: const TextStyle(fontSize: 40)),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (a.subcategoryName != null)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: catColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${a.subcategoryEmoji ?? "📌"} ${a.subcategoryName}',
                              style: TextStyle(
                                fontSize: 10,
                                color: catColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (a.badge != null && a.subcategoryName == null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: a.themeColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              a.badge!,
                              style: TextStyle(
                                fontSize: 10,
                                color: a.themeColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      a.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, height: 1.3),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      a.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, height: 1.3),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(a.readTime, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        const SizedBox(width: 14),
                        Icon(Icons.visibility, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text('${a.originalViews}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        const Spacer(),
                        const Icon(Icons.arrow_forward_ios, size: 11, color: Colors.grey),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
