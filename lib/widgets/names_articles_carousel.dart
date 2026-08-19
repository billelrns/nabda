import 'package:flutter/material.dart';

import '../data/names_articles_database.dart';
import '../data/baby_names_database.dart';
import '../screens/baby_names/baby_names_screen.dart';
import '../utils/article_images.dart';
import 'package:nabda_app/widgets/nabda_article_ad.dart';
import 'package:nabda_app/widgets/article_engagement_bar.dart';


/// كاروسال أفقي لمقالات «دليل أسماء المواليد» (50+ مقالاً)
/// يظهر في صفحة الحمل لكل الأسابيع، ويفتح شاشة قراءة مريحة.
class NamesArticlesCarousel extends StatelessWidget {
  final int maxItems;
  const NamesArticlesCarousel({Key? key, this.maxItems = 12}) : super(key: key);

  static const _pink = Color(0xFFE0195B);
  static const _teal = Color(0xFF00897B);
  static const _ink = Color(0xFF1F1A20);
  static const _ink2 = Color(0xFF6B6470);

  Color _catColor(String c) {
    switch (c) {
      case 'شرعية':
        return _teal;
      case 'علم النفس':
        return const Color(0xFF7E57C2);
      default:
        return const Color(0xFFF57C00);
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = namesArticlesDatabase;
    if (all.isEmpty) return const SizedBox.shrink();
    // اختيار متنوّع: من كل تصنيف بالتناوب
    final byCat = <String, List<NamesArticle>>{};
    for (final a in all) {
      byCat.putIfAbsent(a.category, () => []).add(a);
    }
    final items = <NamesArticle>[];
    var i = 0;
    while (items.length < maxItems) {
      var added = false;
      for (final list in byCat.values) {
        if (i < list.length) {
          items.add(list[i]);
          added = true;
          if (items.length >= maxItems) break;
        }
      }
      if (!added) break;
      i++;
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                      color: _pink, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 8),
                const Text('📖', style: TextStyle(fontSize: 17)),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text('دليل أسماء المواليد',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _ink)),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const _AllNamesArticlesScreen()),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('عرض الكل',
                          style: TextStyle(
                              color: _teal,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_back_ios, size: 12, color: _teal),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 226,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              itemCount: items.length,
              itemBuilder: (context, k) {
                final a = items[k];
                final c = _catColor(a.category);
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => NameArticleDetailScreen(article: a)),
                  ),
                  child: Container(
                    width: 190,
                    margin: const EdgeInsets.only(left: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: c.withOpacity(0.15)),
                      boxShadow: [
                        BoxShadow(
                            color: c.withOpacity(0.10),
                            blurRadius: 10,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ArticleImage(
                              title: a.title,
                              section: 'pregnancy',
                              height: 110,
                              width: 190,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.92),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(a.category,
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: c)),
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: _ink,
                                        height: 1.4)),
                                const SizedBox(height: 4),
                                Expanded(
                                  child: Text(a.body,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 11.5,
                                          color: _ink2,
                                          height: 1.5)),
                                ),
                                Row(children: [
                                  const Icon(Icons.schedule,
                                      size: 12, color: _ink2),
                                  const SizedBox(width: 4),
                                  Text('${(a.body.length / 900).ceil()} دقائق',
                                      style: const TextStyle(
                                          fontSize: 10.5, color: _ink2)),
                                ]),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          // ── زر واضح: اختيار اسم المولود ──
          const BabyNamesCta(),
        ],
      ),
    );
  }
}

/// بطاقة/زر بارز يفتح مكتبة أسماء المواليد
class BabyNamesCta extends StatelessWidget {
  const BabyNamesCta({Key? key}) : super(key: key);

  static const _pink = Color(0xFFE0195B);
  static const _pinkSoft = Color(0xFFF0347C);

  @override
  Widget build(BuildContext context) {
    final total = babyNamesDatabase.length;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BabyNamesScreen()),
          ),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [_pinkSoft, _pink],
              ),
              boxShadow: [
                BoxShadow(
                  color: _pink.withOpacity(0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text('👶', style: TextStyle(fontSize: 26)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'اختاري اسم مولودكِ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${total > 0 ? '+$total' : 'مئات'} اسم مع المعنى • بحث وتصفية • حفظ المفضّلة',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.92),
                            fontSize: 11.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ابدئي',
                          style: TextStyle(
                            color: _pink,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 3),
                        Icon(Icons.arrow_back_ios, size: 11, color: _pink),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// شاشة قراءة مقال الأسماء
class NameArticleDetailScreen extends StatelessWidget {
  final NamesArticle article;
  const NameArticleDetailScreen({Key? key, required this.article})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final paras = article.body.split('\n\n').where((p) => p.trim().isNotEmpty).toList();
    final midPoint = (paras.length / 2).floor();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8FB),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: const Color(0xFFE0195B),
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(fit: StackFit.expand, children: [
                  ArticleImage(
                      title: article.title,
                      section: 'pregnancy',
                      fit: BoxFit.cover),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.45),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCE4EC),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(article.category,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFC2185B))),
                    ),
                    const SizedBox(height: 12),
                    Text(article.title,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1F1A20),
                            height: 1.4)),
                    const SizedBox(height: 18),
                    for (int i = 0; i < paras.length; i++) ...[
                      Text(paras[i].trim(),
                          style: const TextStyle(
                              fontSize: 15.5,
                              height: 2.0,
                              color: Color(0xFF3A3340))),
                      const SizedBox(height: 16),
                      if (i == 1 && paras.length > 3) ...[
                        NabdaArticleAd(
                          slot: 0,
                          articleId: article.title,
                          section: 'pregnancy',
                          articleTitle: article.title,
                          articleBody: article.body,
                          color: const Color(0xFFE0195B),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (i == midPoint && paras.length > 5 && midPoint > 1) ...[
                        NabdaArticleAd(
                          slot: 1,
                          articleId: article.title,
                          section: 'pregnancy',
                          articleTitle: article.title,
                          articleBody: article.body,
                          color: const Color(0xFFE0195B),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                    const SizedBox(height: 8),
                    ArticleEngagementBar(
                      articleId: article.title,
                      articleTitle: article.title,
                      section: 'pregnancy',
                      color: const Color(0xFFE0195B),
                    ),
                    const SizedBox(height: 16),
                    NabdaArticleAd(
                      slot: 2,
                      articleId: article.title,
                      section: 'pregnancy',
                      articleTitle: article.title,
                      articleBody: article.body,
                      color: const Color(0xFFE0195B),
                    ),
                    const SizedBox(height: 30),
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

/// شاشة كل مقالات الأسماء مع فلترة بالتصنيف
class _AllNamesArticlesScreen extends StatefulWidget {
  const _AllNamesArticlesScreen();
  @override
  State<_AllNamesArticlesScreen> createState() =>
      _AllNamesArticlesScreenState();
}

class _AllNamesArticlesScreenState extends State<_AllNamesArticlesScreen> {
  String _cat = 'الكل';

  @override
  Widget build(BuildContext context) {
    final cats = ['الكل', ...{for (final a in namesArticlesDatabase) a.category}];
    final list = _cat == 'الكل'
        ? namesArticlesDatabase
        : namesArticlesDatabase.where((a) => a.category == _cat).toList();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8FB),
        appBar: AppBar(
          title: const Text('📖 دليل أسماء المواليد',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          backgroundColor: const Color(0xFFE0195B),
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            SizedBox(
              height: 54,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  for (final c in cats)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        label: Text(c),
                        selected: _cat == c,
                        onSelected: (_) => setState(() => _cat = c),
                        selectedColor: const Color(0xFFE0195B),
                        labelStyle: TextStyle(
                          color: _cat == c ? Colors.white : const Color(0xFF6B6470),
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                        backgroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final a = list[i];
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => NameArticleDetailScreen(article: a)),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2)),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Row(children: [
                        ArticleImage(
                            title: a.title,
                            section: 'pregnancy',
                            width: 104,
                            height: 92,
                            fit: BoxFit.cover),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.category,
                                    style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFC2185B))),
                                const SizedBox(height: 4),
                                Text(a.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1F1A20),
                                        height: 1.4)),
                              ],
                            ),
                          ),
                        ),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
