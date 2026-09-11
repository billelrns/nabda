import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/smart_article.dart';
import '../../services/smart_articles_service.dart';

class ArticleDetailScreen extends StatefulWidget {
  final SmartArticle article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final SmartArticlesService _service = SmartArticlesService();
  double _readingProgress = 0.0;
  bool _isBookmarked = false;
  bool _isBookmarkLoading = false;
  List<SmartArticle> _relatedArticles = [];
  bool _loadingRelated = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadRelated();
    _checkBookmarkStatus();
  }

  Future<void> _checkBookmarkStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('favorites')
          .doc(widget.article.id)
          .get();
      if (mounted) {
        setState(() {
          _isBookmarked = doc.exists;
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleBookmark() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('سجّلي الدخول أولاً لحفظ المقال في المفضلة 🔖'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final original = _isBookmarked;
    setState(() {
      _isBookmarked = !original;
      _isBookmarkLoading = true;
    });

    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(widget.article.id);

    try {
      if (!original) {
        await favRef.set({
          'type': 'article',
          'articleId': widget.article.id,
          'title': widget.article.title,
          'preview': widget.article.summary,
          'thumbnail': widget.article.imagePath,
          'category': widget.article.categoryName,
          'categoryId': widget.article.categoryId,
          'savedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await favRef.delete();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              !original
                  ? 'تم حفظ المقال في المفضلة 🤍'
                  : 'تمت الإزالة من المفضلة',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: widget.article.themeColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBookmarked = original;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر تحديث المفضلة، تحققي من الاتصال بالإنترنت'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBookmarkLoading = false;
        });
      }
    }
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

  Future<void> _loadRelated() async {
    final related = await _service.relatedTo(widget.article, limit: 6);
    if (!mounted) return;
    setState(() {
      _relatedArticles = related;
      _loadingRelated = false;
    });
  }

  String get _articleWebUrl => 'https://nabda.online/articles.html?id=${widget.article.id}';

  Future<void> _shareNative() async {
    final text = '${widget.article.title}\n\nاقرئي المقال كاملاً في موسوعة نبضة:\n$_articleWebUrl';
    await Share.share(text, subject: widget.article.title);
  }

  void _copyLink() {
    Clipboard.setData(ClipboardData(text: _articleWebUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('تم نسخ رابط المقال بنجاح 📋'),
          ],
        ),
        backgroundColor: widget.article.themeColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _shareWhatsApp() async {
    final text = Uri.encodeComponent('${widget.article.title}\n\n$_articleWebUrl');
    final uri = Uri.parse('https://api.whatsapp.com/send?text=$text');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await _shareNative();
    }
  }

  Future<void> _shareTwitter() async {
    final text = Uri.encodeComponent(widget.article.title);
    final url = Uri.encodeComponent(_articleWebUrl);
    final uri = Uri.parse('https://twitter.com/intent/tweet?text=$text&url=$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await _shareNative();
    }
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final themeColor = article.themeColor;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFBF9FA),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              expandedHeight: 260.0,
              pinned: true,
              backgroundColor: themeColor,
              foregroundColor: Colors.white,
              title: innerBoxIsScrolled
                  ? Text(
                      article.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    )
                  : null,
              actions: [
                IconButton(
                  icon: _isBookmarkLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(
                          _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          color: _isBookmarked ? const Color(0xFFFF4081) : Colors.white,
                        ),
                  tooltip: 'حفظ المقال',
                  onPressed: _isBookmarkLoading ? null : _toggleBookmark,
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: 'مشاركة',
                  onPressed: _shareNative,
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      article.imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [themeColor, themeColor.withValues(alpha: 0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Text(article.iconEmoji, style: const TextStyle(fontSize: 72)),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.75),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.85),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (article.badge != null && article.badge!.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: themeColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                article.badge!,
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          Text(
                            article.categoryName,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  value: _readingProgress,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 4,
                ),
              ),
            ),
          ],
          body: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            children: [
              // عنوان المقال
              Text(
                article.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1.4,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 12),

              // شريط الكاتب والإحصائيات
              _buildAuthorBar(themeColor),
              const SizedBox(height: 16),

              // أزرار المشاركة الاجتماعية السريعة
              _buildShareRow(themeColor),
              const SizedBox(height: 20),

              // أقسام المقال
              ...article.sections.map((section) => _buildSectionWidget(section, themeColor)),

              // بطاقة الأداة التفاعلية إن وجدت
              if (article.toolTitle != null && article.toolTitle!.isNotEmpty)
                _buildToolCard(themeColor),

              // الأسئلة الشائعة
              if (article.faqs.isNotEmpty) _buildFaqsSection(themeColor),

              // المراجع المعتمدة
              _buildReferencesSection(themeColor),
              const SizedBox(height: 32),

              // مقالات ذات صلة
              _buildRelatedSection(themeColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthorBar(Color themeColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: themeColor.withValues(alpha: 0.15),
            radius: 20,
            child: Text(widget.article.iconEmoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.article.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2C2C2C)),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified, size: 14, color: Color(0xFF00897B)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(widget.article.readTime, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    const SizedBox(width: 12),
                    Icon(Icons.visibility, size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text('${widget.article.originalViews} قراءة',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareRow(Color themeColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _shareIconButton(
          icon: Icons.link,
          label: 'نسخ الرابط',
          color: const Color(0xFF5E35B1),
          onTap: _copyLink,
        ),
        _shareIconButton(
          icon: Icons.chat_bubble_outline,
          label: 'واتساب',
          color: const Color(0xFF25D366),
          onTap: _shareWhatsApp,
        ),
        _shareIconButton(
          icon: Icons.share,
          label: 'مشاركة',
          color: themeColor,
          onTap: _shareNative,
        ),
        _shareIconButton(
          icon: Icons.open_in_browser,
          label: 'إكس',
          color: const Color(0xFF1DA1F2),
          onTap: _shareTwitter,
        ),
      ],
    );
  }

  Widget _shareIconButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionWidget(ArticleSection section, Color themeColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  section.title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1F1A20)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            section.content,
            style: const TextStyle(fontSize: 15, height: 1.7, color: Color(0xFF333333)),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(Color themeColor) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [themeColor.withValues(alpha: 0.12), themeColor.withValues(alpha: 0.05)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calculate_outlined, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.article.toolTitle ?? 'أداة تفاعلية',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1F1A20)),
                    ),
                    if (widget.article.toolSubtitle != null && widget.article.toolSubtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.article.toolSubtitle!,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('الأداة: ${widget.article.toolTitle ?? ""} متاحة داخل تبويب الأدوات بالصفحة الرئيسية'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('افتحي الأداة الآن', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqsSection(Color themeColor) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, color: themeColor, size: 22),
              const SizedBox(width: 8),
              const Text(
                'الأسئلة الشائعة والإجابات المعتمدة',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1F1A20)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...widget.article.faqs.map(
            (faq) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              elevation: 0,
              child: ExpansionTile(
                iconColor: themeColor,
                collapsedIconColor: Colors.grey,
                title: Text(
                  faq.question,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2C2C2C)),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Text(
                      faq.answer,
                      style: const TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF4A4A4A)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferencesSection(Color themeColor) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            const Icon(Icons.menu_book_outlined, size: 18, color: Color(0xFF00897B)),
            const SizedBox(width: 8),
            const Text(
              'المراجع والمصادر الطبية المعتمدة',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF00897B)),
            ),
          ],
        ),
        children: const [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text(
              'تم إعداد هذا المحتوى وتدقيقه وفقاً لأحدث البروتوكولات الإكلينيكية الصادرة عن:\n'
              '• الكلية الأمريكية لأطباء النساء والتوليد (ACOG Guidelines)\n'
              '• المعهد الوطني للصحة والرعاية المتميزة (NICE UK)\n'
              '• منظمة الصحة العالمية (WHO — Maternal & Child Health)\n'
              '• قاعدة بيانات المكتبة الوطنية الأمريكية للطب (PubMed / NIH)\n'
              '• الجمعية الملكية لأطباء النساء والتوليد (RCOG)',
              style: TextStyle(fontSize: 12, height: 1.7, color: Color(0xFF6E6E6E)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedSection(Color themeColor) {
    if (_loadingRelated) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_relatedArticles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'مقالات ذات صلة تهمكِ',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F1A20)),
        ),
        const SizedBox(height: 12),
        ..._relatedArticles.map(
          (rel) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: rel.themeColor.withValues(alpha: 0.15),
                child: Text(rel.iconEmoji, style: const TextStyle(fontSize: 20)),
              ),
              title: Text(
                rel.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              subtitle: Text(
                '⏱️ ${rel.readTime} · 👁️ ${rel.originalViews}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: rel)),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
