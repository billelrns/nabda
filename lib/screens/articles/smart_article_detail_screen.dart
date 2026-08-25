import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/smart_interactive_articles_data.dart';
import '../qadaa/qadaa_screen.dart';
import '../fiqh/womens_fiqh_screen.dart';
import '../pregnancy/pregnancy_weeks_screen.dart';
import '../fertility/fertility_screen.dart';
import '../../main.dart';

/// شاشة عرض المقال التفاعلي الذكي
class SmartArticleDetailScreen extends StatefulWidget {
  final SmartArticle article;

  const SmartArticleDetailScreen({Key? key, required this.article})
      : super(key: key);

  @override
  State<SmartArticleDetailScreen> createState() =>
      _SmartArticleDetailScreenState();
}

class _SmartArticleDetailScreenState extends State<SmartArticleDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  double _readingProgress = 0.0;
  bool _isBookmarked = false;
  final Set<int> _expandedFaqs = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    if (maxScroll > 0) {
      setState(() {
        _readingProgress = (currentScroll / maxScroll).clamp(0.0, 1.0);
      });
    }
  }

  void _shareArticle() {
    final text = '''
📖 مقال طبي متميز من تطبيق نبضة:
${widget.article.title}

${widget.article.summary}

✨ اقرأي المزيد وتتبعي صحتكِ في تطبيق نبضة!
''';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('تم نسخ المقال للمشاركة بنجاح ✨'),
          ],
        ),
        backgroundColor: widget.article.themeColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _triggerToolAction(ArticleToolType? toolType) {
    if (toolType == null) return;
    switch (toolType) {
      case ArticleToolType.dueDateCalculator:
      case ArticleToolType.pregnancyWeeks:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PregnancyWeeksScreen()),
        );
        break;
      case ArticleToolType.ovulationCalculator:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const FertilityScreen(userData: {}),
          ),
        );
        break;
      case ArticleToolType.qadaaTracker:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QadaaScreen()),
        );
        break;
      case ArticleToolType.womensFiqh:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WomensFiqhScreen()),
        );
        break;
      case ArticleToolType.aiAssistant:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AIChatPage()),
        );
        break;
      case ArticleToolType.babyTracker:
      case ArticleToolType.waterTracker:
        Navigator.maybePop(context);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final art = widget.article;
    final themeColor = art.themeColor;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFC),
        body: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                // ── Hero Header ──
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  backgroundColor: themeColor,
                  leading: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.25),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.25),
                        ),
                        child: Icon(
                          _isBookmarked
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _isBookmarked = !_isBookmarked;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _isBookmarked
                                  ? 'تم حفظ المقال في المفضلة 🤍'
                                  : 'تمت الإزالة من المفضلة',
                            ),
                            duration: const Duration(seconds: 1),
                            backgroundColor: themeColor,
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.25),
                        ),
                        child: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
                      ),
                      onPressed: _shareArticle,
                    ),
                    const SizedBox(width: 8),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [
                            themeColor,
                            themeColor.withOpacity(0.8),
                            const Color(0xFF1B1320),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 70, 20, 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  art.categoryName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  art.badge,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text(
                                art.iconEmoji,
                                style: const TextStyle(fontSize: 26),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  art.readTime,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Article Body Content ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          art.title,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1B1320),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Author & Credibility Row
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: themeColor.withOpacity(0.12),
                              ),
                              child: Center(
                                child: Icon(Icons.verified_user_rounded,
                                    color: themeColor, size: 18),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    art.author,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2D2D3A),
                                    ),
                                  ),
                                  const Text(
                                    'محتوى طبي مُراجع ومتوافق مع المعايير الصحية العالمية',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: Color(0xFF8E8295),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Executive Summary Hook Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: themeColor.withOpacity(0.25), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: themeColor.withOpacity(0.06),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('💡', style: TextStyle(fontSize: 22)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  art.summary,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF333333),
                                    height: 1.6,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Interactive In-Article Action Tool Card
                        if (art.toolType != null && art.toolTitle != null) ...[
                          _buildInteractiveToolBanner(art, themeColor),
                          const SizedBox(height: 24),
                        ],

                        // Main Sections
                        ...art.sections.map((sec) => _buildSectionWidget(sec, themeColor)),

                        // FAQ Section if present
                        if (art.faqs.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildFAQSection(art.faqs, themeColor),
                        ],

                        const SizedBox(height: 30),

                        // Disclaimer Footer
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F7),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.black12, width: 0.8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.grey, size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'المعلومات الواردة في هذا المقال للتثقيف والإرشاد العام فقط ولا تغني عن الاستشارة الطبية المباشرة من الطبيبة المختصة.',
                                  style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Related Articles Suggestions
                        _buildRelatedArticles(art),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Top Reading Progress Indicator
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: SizedBox(
                  height: 3.5,
                  child: LinearProgressIndicator(
                    value: _readingProgress,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      themeColor == Colors.white ? const Color(0xFFE91E63) : themeColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionWidget(ArticleSection sec, Color themeColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sec.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B1320),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            sec.content,
            style: const TextStyle(
              fontSize: 14.5,
              color: Color(0xFF4A3F4F),
              height: 1.65,
            ),
          ),
          if (sec.bulletPoints.isNotEmpty) ...[
            const SizedBox(height: 10),
            Column(
              children: sec.bulletPoints.map((bp) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: themeColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          bp,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF2D2D3A),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
          if (sec.calloutTip != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9E6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFD54F), width: 1),
              ),
              child: Text(
                sec.calloutTip!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF795548),
                  height: 1.5,
                ),
              ),
            ),
          ],
          if (sec.calloutWarning != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEF5350), width: 1),
              ),
              child: Text(
                sec.calloutWarning!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFC62828),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInteractiveToolBanner(SmartArticle art, Color themeColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [themeColor.withOpacity(0.12), themeColor.withOpacity(0.04)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeColor.withOpacity(0.3), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: themeColor,
            ),
            child: const Center(
              child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  art.toolTitle ?? 'أداة نبضة الذكية',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B1320),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  art.toolSubtitle ?? 'جربي الأداة التفاعلية الآن',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF6B6470),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _triggerToolAction(art.toolType),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('افتحي الأداة', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection(List<ArticleFAQ> faqs, Color themeColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.06), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('❓', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Text(
                'أسئلة شائعة وإجابات طبية سريعة',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B1320),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(faqs.length, (i) {
            final faq = faqs[i];
            final isExp = _expandedFaqs.contains(i);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F8FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text(
                  faq.question,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D2D3A),
                  ),
                ),
                subtitle: isExp
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 4),
                        child: Text(
                          faq.answer,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF555555),
                            height: 1.5,
                          ),
                        ),
                      )
                    : null,
                trailing: Icon(
                  isExp ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: themeColor,
                ),
                onTap: () {
                  setState(() {
                    if (isExp) {
                      _expandedFaqs.remove(i);
                    } else {
                      _expandedFaqs.add(i);
                    }
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRelatedArticles(SmartArticle currentArt) {
    final related = SmartArticlesDatabase.articles
        .where((a) => a.id != currentArt.id)
        .take(3)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'مقالات مقترحة لكِ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1B1320),
          ),
        ),
        const SizedBox(height: 12),
        ...related.map((a) {
          return InkWell(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => SmartArticleDetailScreen(article: a),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  Text(a.iconEmoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.title,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B1320),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          a.readTime,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_back_ios, size: 14, color: Colors.grey),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
