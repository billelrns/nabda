import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nabda_app/data/specialized_articles.dart';
import 'package:nabda_app/services/specialized_articles_service.dart';
import 'news_section.dart';
import '../utils/article_images.dart';

/// أقسام محتوى متخصّص تظهر حسب ملف المستخدمة وداخل تبويبها الصحيح فقط.
/// [stage] = مرحلة التبويب الذي أُدرج فيه القسم (pregnant/baby/cycle/planning)،
/// فلا يظهر محتوى الحمل في تبويب الطفل مثلاً.
class ConditionalContentSection extends StatelessWidget {
  final String stage;
  final bool horizontal;
  const ConditionalContentSection({super.key, required this.stage, this.horizontal = false});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final d = snap.data!.data() as Map<String, dynamic>? ?? {};
        // اعرض فقط في التبويب المطابق لمرحلة المستخدمة
        if (d['lifeStage'] != stage) return const SizedBox.shrink();
        final topics = _topicsFor(d)
            .where((t) => (specializedArticles[t.key]?.isNotEmpty ?? false))
            .toList();
        if (topics.isEmpty) return const SizedBox.shrink();
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [for (final t in topics) _section(context, t)]),
        );
      },
    );
  }

  String get _place {
    switch (stage) {
      case 'pregnant': return 'pregnancy';
      case 'baby': return 'baby';
      case 'cycle': return 'cycle';
      case 'planning': return 'fertility';
      default: return 'all';
    }
  }

  Widget _section(BuildContext context, _Topic t) {
    return StreamBuilder<QuerySnapshot>(
      stream: SpecializedArticlesService.streamByTopic(t.key),
      builder: (context, snap) {
        if (snap.hasData && snap.data!.docs.isNotEmpty) {
          final docs = snap.data!.docs.toList()
            ..sort((a, b) {
              final ao = (a.data() as Map)['order'] as int? ?? 0;
              final bo = (b.data() as Map)['order'] as int? ?? 0;
              return ao.compareTo(bo);
            });
          return _buildSection(context, t, docs: docs);
        }
        final arts = specializedArticles[t.key] ?? [];
        return _buildSection(context, t, hardcoded: arts);
      },
    );
  }

  // ignore: unused_element
  Widget _ph(_Topic t) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [t.color.withValues(alpha: 0.15), t.color.withValues(alpha: 0.05)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 10,
              bottom: 5,
              child: Text(
                t.emoji,
                style: TextStyle(fontSize: 50, color: Colors.white.withValues(alpha: 0.35)),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 10,
              child: Text(t.emoji, style: const TextStyle(fontSize: 36)),
            ),
          ],
        ),
      );

  Widget _buildSection(BuildContext context, _Topic t,
      {List<QueryDocumentSnapshot>? docs, List<SpecArticle>? hardcoded}) {
    void open(String title, String body, String image) => Navigator.push(context,
        MaterialPageRoute(builder: (_) => _ArticlePage(
          title: title, body: body, image: image, color: t.color, place: _place)));

    final itemsCount = docs != null ? docs.length : (hardcoded != null ? hardcoded.length : 0);
    if (itemsCount == 0) return const SizedBox.shrink();

    if (horizontal) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carousel Header
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: t.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  t.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2D3A),
                  ),
                ),
                const SizedBox(width: 6),
                Text(t.emoji, style: const TextStyle(fontSize: 18)),
              ],
            ),
            const SizedBox(height: 12),
            // Carousel
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                reverse: true,
                itemCount: itemsCount,
                itemBuilder: (context, i) {
                  String title = '';
                  String body = '';
                  String image = '';
                  if (docs != null) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    title = d['title'] as String? ?? '';
                    body = d['body'] as String? ?? '';
                    image = d['image'] as String? ?? '';
                  } else if (hardcoded != null) {
                    title = hardcoded[i].title;
                    body = hardcoded[i].body;
                    image = '';
                  }
                  return GestureDetector(
                    onTap: () => open(title, body, image),
                    child: Container(
                      width: 240,
                      margin: EdgeInsets.only(left: i == itemsCount - 1 ? 0 : 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top part (Image or Placeholder with category badge)
                          SizedBox(
                            width: double.infinity,
                            height: 90,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(18),
                                      topLeft: Radius.circular(18),
                                    ),
                                    child: ArticleImage(
                                      title: title,
                                      section: 'health',
                                      networkUrl: image.isNotEmpty ? image : null,
                                      width: double.infinity,
                                      height: 90,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                // Category badge
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      t.title,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: t.color,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Text section
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2D2D3A),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time, size: 12, color: Colors.grey[400]),
                                      const SizedBox(width: 4),
                                      Text(
                                        'قراءة سريعة',
                                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                                      ),
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
                },
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(right: 4, bottom: 8),
          child: Text('${t.emoji} ${t.title}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1B1320)))),
        if (docs != null)
          ...docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final title = d['title'] as String? ?? '';
            final body = d['body'] as String? ?? '';
            final image = d['image'] as String? ?? '';
            return _ArticleCard(title: title, image: image, color: t.color,
              onTap: () => open(title, body, image));
          }),
        if (hardcoded != null)
          ...hardcoded.map((a) => _ArticleCard(title: a.title, image: '', color: t.color,
            onTap: () => open(a.title, a.body, ''))),
      ]),
    );
  }

  List<_Topic> _topicsFor(Map<String, dynamic> d) {
    final stage = d['lifeStage'];
    final out = <_Topic>[];
    if (stage == 'pregnant') {
      final p = (d['pregnancyProfile'] as Map?) ?? {};
      if (p['babies'] == 'twins' || p['babies'] == 'more') { out.add(const _Topic('👶👶', 'الحمل بتوأم', 'twins', Color(0xFFE91E63))); }
      if (p['condition'] == 'diabetes') { out.add(const _Topic('🩸', 'سكري الحمل', 'diabetes', Color(0xFFEF5350))); }
      if (p['condition'] == 'hypertension') { out.add(const _Topic('🩺', 'ارتفاع الضغط في الحمل', 'htn', Color(0xFF7E57C2))); }
      if (p['condition'] == 'nausea') { out.add(const _Topic('🤢', 'غثيان الحمل', 'nausea', Color(0xFF66BB6A))); }
      if (p['firstPregnancy'] == true) { out.add(const _Topic('🌸', 'دليل الحمل الأول', 'firstPreg', Color(0xFFEC407A))); }
      // الاستعداد للولادة القيصرية — تظهر في الحمل عند تسجيل خطة قيصرية (الشهر الثامن)
      if (d['birthType'] == 'cesarean') { out.add(const _Topic('🏥', 'الاستعداد للولادة القيصرية', 'cesareanPrep', Color(0xFF5C6BC0))); }
    } else if (stage == 'baby') {
      final p = (d['babyProfile'] as Map?) ?? {};
      // الطفل الخديج (ولادة مبكرة قبل الأسبوع 37) — علامة على وثيقة المستخدمة
      if (d['pretermBirth'] == true) { out.add(const _Topic('👶', 'العناية بالطفل الخديج', 'preterm', Color(0xFFAB47BC))); }
      // التعافي بعد الولادة القيصرية — تظهر في رعاية الطفل عند ولادة قيصرية
      if (d['birthType'] == 'cesarean') { out.add(const _Topic('🏥', 'التعافي بعد الولادة القيصرية', 'cesarean', Color(0xFF5C6BC0))); }
      if (p['feeding'] == 'formula') { out.add(const _Topic('🍼', 'الرضاعة الصناعية', 'formula', Color(0xFF42A5F5))); }
      else if (p['feeding'] == 'mixed') { out.add(const _Topic('🍼', 'الرضاعة المختلطة', 'mixed', Color(0xFF26A69A))); }
      if (p['firstChild'] == true) out.add(const _Topic('🤱', 'طفلك الأول', 'firstChild', Color(0xFF7E57C2)));
    } else if (stage == 'cycle') {
      final p = (d['cycleProfile'] as Map?) ?? {};
      if (p['regular'] == 'no') out.add(const _Topic('📅', 'الدورة غير المنتظمة', 'irregular', Color(0xFFFF7043)));
    } else if (stage == 'planning') {
      final fp = (d['fertilityProfile'] as Map?) ?? {};
      if (fp['condition'] == 'pcos') out.add(const _Topic('🩺', 'تكيّس المبايض', 'pcos', Color(0xFF7E57C2)));
      if (fp['condition'] == 'thyroid') out.add(const _Topic('🦋', 'الغدة الدرقية', 'thyroid', Color(0xFF42A5F5)));
    }
    return out;
  }
}

class _Topic {
  final String emoji, title, key;
  final Color color;
  const _Topic(this.emoji, this.title, this.key, this.color);
}

class _ArticleCard extends StatelessWidget {
  final String title, image;
  final Color color;
  final VoidCallback onTap;
  const _ArticleCard({required this.title, required this.image, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4))]),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: ArticleImage(
              title: title,
              section: 'health',
              networkUrl: image.isNotEmpty ? image : null,
              width: 46,
              height: 46,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1B1320)))),
          const Icon(Icons.arrow_back_ios, size: 14, color: Color(0xFFC9BCBC)),
        ]),
      ),
    );
  }

  // ignore: unused_element
  static Widget _ph(Color c) => Container(
    width: 46, height: 46,
    decoration: BoxDecoration(shape: BoxShape.circle, color: c.withValues(alpha: 0.15)),
    child: const Center(child: Icon(Icons.article_outlined, color: Color(0xFF8E8295), size: 20)));
}

/// صفحة المقال — بنفس تنسيق مقالات التطبيق: صورة رأسية + عنوان + خانات إعلانات/منتجات
/// (NabdaAd يعرض إعلانًا أو منتجًا قريبًا عند غيابه) موزّعة على المقال.
class _ArticlePage extends StatelessWidget {
  final String title, body, image, place;
  final Color color;
  const _ArticlePage({required this.title, required this.body, this.image = '',
    this.place = 'all', this.color = const Color(0xFFE91E63)});

  @override
  Widget build(BuildContext context) {
    final paragraphs = body.split('\n\n').where((p) => p.trim().isNotEmpty).toList();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: color,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: ArticleImage(
                title: title,
                section: 'health',
                networkUrl: image.isNotEmpty ? image : null,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1F1A20), height: 1.5)),
                const SizedBox(height: 16),
                // إعلان/منتج أعلى المقال
                NabdaAd(slot: 0, groupId: title, place: place, color: color),
                const SizedBox(height: 18),
                for (int i = 0; i < paragraphs.length; i++) ...[
                  Text(paragraphs[i].trim(), style: const TextStyle(fontSize: 16, height: 1.9, color: Color(0xFF333333))),
                  if (i < paragraphs.length - 1) const SizedBox(height: 16),
                  // إعلان/منتج وسط المقال
                  if (i == 1 && paragraphs.length > 3) ...[
                    const SizedBox(height: 14),
                    NabdaAd(slot: 1, groupId: title, place: place, color: color),
                    const SizedBox(height: 14),
                  ],
                ],
                const SizedBox(height: 22),
                // منتجات/إعلان أسفل المقال
                NabdaAd(slot: 2, groupId: title, place: place, color: color),
                const SizedBox(height: 30),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
