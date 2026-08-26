import 'package:flutter/material.dart';
import '../../data/smart_interactive_articles_data.dart';
import 'smart_article_detail_screen.dart';

/// شاشة تصفح وبحث كافة المقالات التفاعلية الذكية (100+ مقال)
class SmartArticlesListScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialTitle;

  const SmartArticlesListScreen({
    super.key,
    this.initialCategory,
    this.initialTitle,
  });

  @override
  State<SmartArticlesListScreen> createState() =>
      _SmartArticlesListScreenState();
}

class _SmartArticlesListScreenState extends State<SmartArticlesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<SmartArticle> _allArticles = [];
  List<SmartArticle> _filteredArticles = [];
  bool _isLoading = true;
  String _selectedCategory = 'all';

  final List<Map<String, String>> _categories = const [
    {'id': 'all', 'label': '🌟 الكل', 'name': 'جميع المقالات'},
    {'id': 'pregnancy', 'label': '🤰 الحمل والولادة', 'name': 'الحمل والولادة'},
    {'id': 'fertility', 'label': '🩸 الخصوبة والتبويض', 'name': 'الخصوبة والتبويض'},
    {'id': 'baby', 'label': '👶 رعاية الرضيع', 'name': 'رعاية الرضيع والطفل'},
    {'id': 'beauty', 'label': '💄 الجمال والعناية', 'name': 'الجمال والعناية'},
    {'id': 'health', 'label': '🥗 الصحة والرشاقة', 'name': 'الصحة والرشاقة'},
    {'id': 'marriage', 'label': '💍 الحياة الزوجية', 'name': 'الحياة الزوجية والنفسية'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null && widget.initialCategory!.isNotEmpty) {
      _selectedCategory = widget.initialCategory!;
    }
    _loadArticles();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadArticles() async {
    setState(() => _isLoading = true);
    final list = await SmartArticlesDatabase.getAll100Articles();
    if (mounted) {
      setState(() {
        _allArticles = list;
        _isLoading = false;
        _applyFilters();
      });
    }
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredArticles = _allArticles.where((art) {
        final matchesCat =
            _selectedCategory == 'all' || art.categoryId == _selectedCategory;
        if (!matchesCat) return false;
        if (query.isEmpty) return true;

        final inTitle = art.title.toLowerCase().contains(query);
        final inSummary = art.summary.toLowerCase().contains(query);
        final inCat = art.categoryName.toLowerCase().contains(query);
        return inTitle || inSummary || inCat;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE91E63);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFBF8FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1B1320), size: 20),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Text(
            widget.initialTitle ?? 'الموسوعة التفاعلية الذكية',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1B1320),
            ),
          ),
          centerTitle: true,
          actions: [
            Container(
              margin: const EdgeInsets.only(left: 14),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_stories, color: primaryColor, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${_filteredArticles.length} مقال',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // ─── شريط البحث ───
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EEF3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ابحثي في 100+ مقال طبي وتفاعلي...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF8A8290)),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF8A8290), size: 22),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, color: Color(0xFF8A8290), size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _applyFilters();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  ),
                ),
              ),
            ),

            // ─── تصنيفات التصفية الأفقية ───
            Container(
              color: Colors.white,
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final cat = _categories[idx];
                  final isSelected = _selectedCategory == cat['id'];
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCategory = cat['id']!;
                        _applyFilters();
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor : const Color(0xFFF3EEF3),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        cat['label']!,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFF5A5260),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1, color: Color(0xFFECE5EB)),

            // ─── قائمة المقالات ───
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    )
                  : _filteredArticles.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_off_rounded, size: 64, color: Color(0xFFC0B5C4)),
                              const SizedBox(height: 12),
                              const Text(
                                'لم نجد مقالات مطابقة لبحثكِ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2C2230),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'جربي كلمات بحث مختلفة أو اختاري قسماً آخر',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF7A7080),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _selectedCategory = 'all');
                                  _applyFilters();
                                },
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text('عرض جميع المقالات'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: primaryColor,
                          onRefresh: _loadArticles,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                            itemCount: _filteredArticles.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final article = _filteredArticles[index];
                              return _buildArticleItem(article);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleItem(SmartArticle article) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0E8EE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SmartArticleDetailScreen(article: article),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Header: Category + Badge + Read time ───
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: article.themeColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Text(article.iconEmoji, style: const TextStyle(fontSize: 16)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          article.categoryName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: article.themeColor,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            article.badge,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFE65100),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          article.readTime,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8A8290),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ─── العنوان ───
                Text(
                  article.title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1B1320),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 8),

                // ─── الملخص ───
                Text(
                  article.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF5A5260),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),

                // ─── Footer: Tool indicator + Arrow ───
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (article.toolTitle != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: article.themeColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: article.themeColor.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.touch_app_outlined, size: 14, color: article.themeColor),
                            const SizedBox(width: 5),
                            Text(
                              article.toolTitle!,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: article.themeColor,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const SizedBox(),
                    Row(
                      children: [
                        Text(
                          'اقرأي المزيد',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: article.themeColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: article.themeColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
