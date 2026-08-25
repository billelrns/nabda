import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/womens_fiqh_data.dart';
import '../../config/theme.dart';
import '../qadaa/qadaa_screen.dart';
import '../../widgets/qadaa_quick_card.dart';

const Color _teal = Color(0xFF00897B);
const Color _tealLight = Color(0xFFE0F2F1);

class WomensFiqhScreen extends StatefulWidget {
  final String? initialCategoryId;
  final String? initialQuery;

  const WomensFiqhScreen({
    Key? key,
    this.initialCategoryId,
    this.initialQuery,
  }) : super(key: key);

  @override
  State<WomensFiqhScreen> createState() => _WomensFiqhScreenState();
}

class _WomensFiqhScreenState extends State<WomensFiqhScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _expandedItemIds = {};

  final List<FiqhCategory> _categories = WomensFiqhData.categories;

  @override
  void initState() {
    super.initState();
    int initialIndex = 0;
    if (widget.initialCategoryId != null) {
      final found = _categories.indexWhere((c) => c.id == widget.initialCategoryId);
      if (found != -1) initialIndex = found;
    }
    _tabController = TabController(
      length: _categories.length,
      vsync: this,
      initialIndex: initialIndex,
    );
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchQuery = widget.initialQuery!;
      _searchController.text = widget.initialQuery!;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String key) {
    switch (key) {
      case 'clean_hands':
        return Icons.water_drop_outlined;
      case 'mosque':
        return Icons.mosque_outlined;
      case 'nights_stay':
        return Icons.nights_stay_outlined;
      case 'favorite':
        return Icons.favorite_border_rounded;
      case 'location_city':
        return Icons.card_membership_outlined;
      default:
        return Icons.menu_book_rounded;
    }
  }

  void _copyToClipboard(FiqhItem item) {
    final text = '''
مسألة: ${item.question}

خلاصة الحكم:
${item.summary}

تفصيل المذاهب الأربعة:
• الحنفية: ${item.hanafi}
• المالكية: ${item.maliki}
• الشافعية: ${item.shafii}
• الحنابلة: ${item.hanbali}

الدليل: ${item.dalil}

— فقه المرأة من تطبيق نبضة
''';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ الفتوى إلى الحافظة بنجاح'),
        duration: Duration(seconds: 2),
        backgroundColor: _teal,
      ),
    );
  }

  void _shareRuling(FiqhItem item) {
    final text = '''
🌸 مسألة فقهية: ${item.question}

📌 الحكم المعتمد:
${item.summary}

🕌 المذاهب الأربعة:
- الحنفية: ${item.hanafi}
- المالكية: ${item.maliki}
- الشافعية: ${item.shafii}
- الحنابلة: ${item.hanbali}

📖 الدليل: ${item.dalil}

✨ فقه المرأة - تطبيق نبضة
''';
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSearching = _searchQuery.trim().isNotEmpty;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF9FBFB),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: _teal,
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'فقه المرأة',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined),
              color: _teal,
              tooltip: 'مشاركة',
              onPressed: () {
                Share.share(
                  'موسوعة فقه المرأة المسلمة وفق المذاهب الأربعة (الحنفي، المالكي، الشافعي، الحنبلي) عبر تطبيق نبضة.',
                );
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(isSearching ? 70 : 124),
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F4F4),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? Colors.white12 : const Color(0xFFE0EBEB),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'ابحثي في الأحكام والمسائل الفقهية...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: _teal,
                          size: 22,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),

                // Category Tabs (Hidden during search)
                if (!isSearching)
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: _teal,
                    indicatorWeight: 3,
                    labelColor: _teal,
                    unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 13,
                    ),
                    tabs: _categories.map((cat) {
                      return Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getCategoryIcon(cat.iconKey), size: 18),
                            const SizedBox(width: 6),
                            Text(cat.name),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
        body: Column(
          children: [
            // Trust verification banner matching screenshot
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isDark ? const Color(0xFF1B2E2B) : const Color(0xFFE8F5F3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.verified_rounded,
                    color: Color(0xFF00897B),
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'تمت المراجعة والتحقيق وفق المذاهب السنية الأربعة',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF00695C),
                    ),
                  ),
                ],
              ),
            ),

            // Content List
            Expanded(
              child: isSearching
                  ? _buildSearchResults()
                  : TabBarView(
                      controller: _tabController,
                      children: _categories.map((cat) {
                        return _buildCategoryList(cat.id);
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final results = WomensFiqhData.search(_searchQuery);

    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'لم نجد نتائج مطابقة لـ "$_searchQuery"',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'جربي البحث بكلمات أخرى مثل: حيض، صلاة، وضوء، صيام، عمرة، زوجي',
                style: TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return _buildFiqhCard(item);
      },
    );
  }

  Widget _buildCategoryList(String categoryId) {
    final items = WomensFiqhData.getByCategory(categoryId);
    final isSiyam = categoryId == 'siyam';

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: items.length + (isSiyam ? 1 : 0),
      itemBuilder: (context, index) {
        if (isSiyam && index == 0) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: QadaaQuickCard(
              customTitle: 'أيام القضاء لشهر رمضان',
              customSubtitle: 'احسبي وتابعي أيام القضاء التي عليكِ مع التقويم التفاعلي',
            ),
          );
        }
        final itemIndex = isSiyam ? index - 1 : index;
        final item = items[itemIndex];
        return _buildFiqhCard(item);
      },
    );
  }

  Widget _buildFiqhCard(FiqhItem item) {
    final isExpanded = _expandedItemIds.contains(item.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded
              ? _teal.withOpacity(0.4)
              : (isDark ? Colors.white10 : const Color(0xFFE8EEF0)),
          width: isExpanded ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Question Header
            InkWell(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedItemIds.remove(item.id);
                  } else {
                    _expandedItemIds.add(item.id);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question Icon matching screenshot style
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isExpanded
                            ? _teal
                            : _teal.withOpacity(0.1),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.help_outline_rounded,
                          size: 20,
                          color: isExpanded ? Colors.white : _teal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Question Text
                    Expanded(
                      child: Text(
                        item.question,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                          color: isDark ? Colors.white : const Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Expand / Collapse Arrow
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: isExpanded ? _teal : Colors.grey,
                        size: 26,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Expanded Ruling Content (The 4 Madhhabs & Summary)
            if (isExpanded) ...[
              const Divider(height: 1, thickness: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Highlight Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF19322E)
                            : const Color(0xFFE8F5F3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF80CBC4),
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.auto_awesome_rounded,
                                size: 16,
                                color: Color(0xFF00796B),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'خلاصة الحكم الفقهي المعتمد',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00695C),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.summary,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.white.withOpacity(0.95)
                                  : const Color(0xFF1B4D3E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Detailed 4 Madhhabs
                    const Text(
                      'أقوال المذاهب الأربعة:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00897B),
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildMadhhabRow(
                      madhhab: 'المذهب الحنفي',
                      text: item.hanafi,
                      color: const Color(0xFF1565C0),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _buildMadhhabRow(
                      madhhab: 'المذهب المالكي',
                      text: item.maliki,
                      color: const Color(0xFF2E7D32),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _buildMadhhabRow(
                      madhhab: 'المذهب الشافعي',
                      text: item.shafii,
                      color: const Color(0xFF6A1B9A),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _buildMadhhabRow(
                      madhhab: 'المذهب الحنبلي',
                      text: item.hanbali,
                      color: const Color(0xFFD84315),
                      isDark: isDark,
                    ),

                    // Dalil & Evidence
                    if (item.dalil.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF28241D)
                              : const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFFFE082),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.menu_book_rounded,
                              size: 18,
                              color: Color(0xFFF57F17),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'الدليل: ${item.dalil}',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF5D4037),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Action buttons (Copy & Share)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _copyToClipboard(item),
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text('نسخ الفتوى', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: _teal,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _shareRuling(item),
                          icon: const Icon(Icons.share_rounded, size: 16),
                          label: const Text('مشاركة', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _teal,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMadhhabRow({
    required String madhhab,
    required String text,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262626) : const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          right: BorderSide(color: color, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            madhhab,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: isDark ? Colors.white70 : const Color(0xFF37474F),
            ),
          ),
        ],
      ),
    );
  }
}
