import 'package:flutter/material.dart';
import '../data/smart_interactive_articles_data.dart';
import '../screens/articles/smart_article_detail_screen.dart';

/// كاروسال عرض المقالات التفاعلية الذكية في شاشات التطبيق
class SmartArticlesCarousel extends StatelessWidget {
  final String? categoryFilter;
  final String sectionTitle;
  final String sectionSubtitle;

  const SmartArticlesCarousel({
    Key? key,
    this.categoryFilter,
    this.sectionTitle = 'مقالات حصرية وإرشادية',
    this.sectionSubtitle = 'محتوى طبي وتفاعلي موثق لصحتكِ وجمالكِ',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<SmartArticle> items = SmartArticlesDatabase.articles;
    if (categoryFilter != null && categoryFilter!.isNotEmpty) {
      items = SmartArticlesDatabase.getByCategory(categoryFilter!);
      if (items.isEmpty) {
        items = SmartArticlesDatabase.articles;
      }
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sectionTitle,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B1320),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sectionSubtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B6470),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E63).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'جديد ✨',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE91E63),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final art = items[index];
                return _buildArticleCard(context, art);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(BuildContext context, SmartArticle art) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SmartArticleDetailScreen(article: art),
          ),
        );
      },
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: art.themeColor.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: art.themeColor.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: art.themeColor.withOpacity(0.12),
                  ),
                  child: Center(
                    child: Text(art.iconEmoji, style: const TextStyle(fontSize: 18)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: art.themeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    art.categoryName,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: art.themeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              art.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1B1320),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              art.summary,
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF6B6470),
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  art.readTime,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'اقرأي المقال',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: art.themeColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_back_ios,
                      size: 11,
                      color: art.themeColor,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
