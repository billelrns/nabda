import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/fertility_duas.dart';
import '../../data/fertility_faith_articles.dart';

/// ═══════════════════════════════════════════════════════════════════
///  «أدعية الذرّية» — أدعية القرآن والسنة لطلب الولد وتأخّر الإنجاب
///
///  كل دعاء يحمل مصدره ودرجته. وتبويب «لا يثبت» يصحّح المنتشر بلا سند
///  — وهو ما يميّز نبضة عن تطبيقات «الأدعية المجرّبة».
/// ═══════════════════════════════════════════════════════════════════
class FertilityDuasScreen extends StatefulWidget {
  const FertilityDuasScreen({super.key});

  @override
  State<FertilityDuasScreen> createState() => _FertilityDuasScreenState();
}

const _green = Color(0xFF1B7A5A);
const _greenDeep = Color(0xFF145C44);
const _gold = Color(0xFFC79A3E);
const _rose = Color(0xFFE0195B);
const _ink = Color(0xFF1F1A20);
const _ink3 = Color(0xFF8E8295);
const _bg = Color(0xFFFBF9F4);

class _FertilityDuasScreenState extends State<FertilityDuasScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 6, vsync: this);
  }

  Future<void> _openRef(FatwaRef r) async {
    final uri = Uri.parse(r.url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'failed';
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('تعذّر فتح الرابط: ${r.url}'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  /// شارة الفتوى المرجعية — قابلة للنقر لفتح الموقع
  Widget _refChip(FatwaRef r) => InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => _openRef(r),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1B7A5A).withOpacity(0.07),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _green.withOpacity(0.22)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.open_in_new, size: 12, color: _green),
            const SizedBox(width: 5),
            Flexible(
              child: Text('مرجع: ${r.site}',
                  style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: _green)),
            ),
          ]),
        ),
      );

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _copy(String t) {
    Clipboard.setData(ClipboardData(text: t));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('نُسخ الدعاء'),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 1),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _green,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text('أدعية الذرّية',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          bottom: TabBar(
            controller: _tab,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: _gold,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            tabs: const [
              Tab(text: '📖 من القرآن'),
              Tab(text: '🌙 من السنة'),
              Tab(text: '⏰ أوقات الإجابة'),
              Tab(text: '⚠️ لا يثبت'),
              Tab(text: '✍️ مقالات'),
              Tab(text: '🔗 المراجع'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tab,
          children: [
            _duaList(quranDuas),
            _duaList(sunnahDuas),
            _timesList(),
            _weakList(),
            _articlesList(),
            _referencesList(),
          ],
        ),
      ),
    );
  }

  // ══════════════════ تنبيه ثابت أعلى القوائم ══════════════════
  Widget _disclaimer() => Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _green.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _green.withOpacity(0.18)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Icon(Icons.verified_outlined, size: 18, color: _green),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'كل دعاء هنا مذكور بمصدره ودرجته، ومراجعه من «الإسلام سؤال وجواب» '
              'و«إسلام ويب». والدعاء عبادة وقربة، ولا يُغني عن الأخذ بالأسباب '
              'ومراجعة الطبيبة — والجمع بينهما هو التوكّل.',
              style: TextStyle(fontSize: 12, height: 1.7, color: _ink),
            ),
          ),
        ]),
      );

  // ══════════════════ قائمة الأدعية ══════════════════
  Widget _duaList(List<Dua> list) => ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: list.length + 1,
        itemBuilder: (c, i) {
          if (i == 0) return _disclaimer();
          final d = list[i - 1];
          return _duaCard(d);
        },
      );

  Widget _duaCard(Dua d) => Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEDE7DC)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // نصّ الدعاء
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
            decoration: BoxDecoration(
              color: d.isQuran ? _green.withOpacity(0.05) : Colors.transparent,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Text(
              d.text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: d.isQuran ? 19 : 17,
                height: 2.1,
                fontWeight: d.isQuran ? FontWeight.w700 : FontWeight.w600,
                color: d.isQuran ? _greenDeep : _ink,
              ),
            ),
          ),
          // المصدر والدرجة
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Wrap(spacing: 8, runSpacing: 6, children: [
              _chip(d.source, _gold),
              _chip(d.grade, _gradeColor(d.grade)),
            ]),
          ),
          if (d.note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text(
                d.note.replaceAll('**', ''),
                style: const TextStyle(
                    fontSize: 12.5, height: 1.9, color: _ink3),
              ),
            ),
          if (d.ref != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _refChip(d.ref!)),
            ),
          const Divider(height: 1, color: Color(0xFFF2EDE4)),
          Row(children: [
            Expanded(
              child: TextButton.icon(
                onPressed: () => _copy(d.text),
                icon: const Icon(Icons.copy, size: 16, color: _ink3),
                label: const Text('نسخ',
                    style: TextStyle(fontSize: 12.5, color: _ink3)),
              ),
            ),
            Container(width: 1, height: 22, color: const Color(0xFFF2EDE4)),
            Expanded(
              child: TextButton.icon(
                onPressed: () => Share.share('${d.text}\n\n﴿${d.source}﴾\n\nمن تطبيق نبضة'),
                icon: const Icon(Icons.share, size: 16, color: _ink3),
                label: const Text('مشاركة',
                    style: TextStyle(fontSize: 12.5, color: _ink3)),
              ),
            ),
          ]),
        ]),
      );

  static Color _gradeColor(String g) => switch (g) {
        'قرآن كريم' => _green,
        'متفق عليه' || 'صحيح' => const Color(0xFF2E7D32),
        'حسن' => const Color(0xFF00897B),
        _ => _rose,
      };

  Widget _chip(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: c.withOpacity(0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: c.withOpacity(0.25)),
        ),
        child: Text(t,
            style: TextStyle(
                fontSize: 10.5, fontWeight: FontWeight.w700, color: c)),
      );

  // ══════════════════ أوقات الإجابة ══════════════════
  Widget _timesList() => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        itemCount: duaTimes.length,
        itemBuilder: (c, i) {
          final t = duaTimes[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEDE7DC)),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _gold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                      child: Text('${i + 1}',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: _gold))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(t.title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _ink)),
                ),
              ]),
              const SizedBox(height: 10),
              Text(t.detail,
                  style:
                      const TextStyle(fontSize: 13, height: 1.9, color: _ink)),
              const SizedBox(height: 10),
              _chip(t.source, _gold),
            ]),
          );
        },
      );

  // ══════════════════ مشهور لا يثبت ══════════════════
  Widget _weakList() => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        itemCount: weakClaims.length + 1,
        itemBuilder: (c, i) {
          if (i == 0) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _rose.withOpacity(0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _rose.withOpacity(0.22)),
              ),
              child: const Text(
                'ينتشر في مواقع ومجموعات كثيرة كلامٌ يُنسب للدين بلا إسناد، '
                'فيزيد المرأة المنتظِرة حرجاً وشعوراً بالذنب. هذه أشهرها، '
                'مع بيان الصواب في كل مسألة.',
                style: TextStyle(fontSize: 12.5, height: 1.9, color: _ink),
              ),
            );
          }
          final w = weakClaims[i - 1];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEDE7DC)),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('⚠️', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(w.claim,
                      style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.8,
                          fontWeight: FontWeight.w700,
                          color: _ink)),
                ),
              ]),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _rose.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('الحكم: ${w.ruling}',
                    style: const TextStyle(
                        fontSize: 12, height: 1.8, color: _rose)),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size: 16, color: _green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(w.correction,
                            style: const TextStyle(
                                fontSize: 12, height: 1.8, color: _greenDeep)),
                      ),
                    ]),
              ),
              if (w.ref != null) ...[
                const SizedBox(height: 10),
                Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: _refChip(w.ref!)),
              ],
            ]),
          );
        },
      );

  // ══════════════════ المراجع ══════════════════
  Widget _referencesList() => ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _green.withOpacity(0.07),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _green.withOpacity(0.18)),
            ),
            child: const Text(
              'المراجع المعتمدة في هذا القسم موقعان موثوقان في الفتوى:\n'
              '• الإسلام سؤال وجواب (islamqa.info)\n'
              '• إسلام ويب — مركز الفتوى (islamweb.net)\n\n'
              'كل مسألة مرتبطة برقم فتواها، ويمكنكِ فتحها والتحقّق بنفسك. '
              'وما وقع فيه خلاف معتبر بين أهل العلم ذُكر خلافاً لا حكماً قاطعاً.',
              style: TextStyle(fontSize: 12.5, height: 2, color: _ink),
            ),
          ),
          const SizedBox(height: 16),
          const Text('قائمة الفتاوى',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(height: 10),
          ...allReferences.map((r) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEDE7DC)),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _openRef(r),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: _green.withOpacity(0.09),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(Icons.menu_book,
                            size: 17, color: _green),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.title,
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      height: 1.6,
                                      fontWeight: FontWeight.w700,
                                      color: _ink)),
                              const SizedBox(height: 3),
                              Text(r.site,
                                  style: const TextStyle(
                                      fontSize: 10.5, color: _green)),
                            ]),
                      ),
                      const Icon(Icons.open_in_new, size: 15, color: _ink3),
                    ]),
                  ),
                ),
              )),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'تنبيه: هذا عرض مبسّط لما ورد في هذه الفتاوى. وللمسائل الخاصّة '
              'بحالتكِ، راجعي عالماً موثوقاً أو دار الإفتاء في بلدكِ.',
              style: TextStyle(fontSize: 11.5, height: 1.9, color: _ink),
            ),
          ),
        ],
      );

  // ══════════════════ المقالات ══════════════════
  Widget _articlesList() => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        itemCount: fertilityFaithArticles.length,
        itemBuilder: (c, i) {
          final a = fertilityFaithArticles[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEDE7DC)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => _FaithArticlePage(article: a)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _green.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                        child: Text(a.emoji,
                            style: const TextStyle(fontSize: 22))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.title,
                              style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: _ink)),
                          const SizedBox(height: 4),
                          Text(a.subtitle,
                              style: const TextStyle(
                                  fontSize: 11.5, color: _ink3, height: 1.4)),
                        ]),
                  ),
                  const Icon(Icons.arrow_back_ios, size: 14, color: _ink3),
                ]),
              ),
            ),
          );
        },
      );
}

// ══════════════════════════════════════════════════════════════
//  صفحة المقال
// ══════════════════════════════════════════════════════════════
class _FaithArticlePage extends StatelessWidget {
  final FaithArticle article;
  const _FaithArticlePage({required this.article});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _green,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => Share.share(
                  '${article.title}\n\n${article.body.replaceAll('**', '')}\n\nمن تطبيق نبضة 💗'),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
          children: [
            Text(article.emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(article.title,
                style: const TextStyle(
                    fontSize: 23, fontWeight: FontWeight.w900, color: _ink)),
            const SizedBox(height: 6),
            Text(article.subtitle,
                style: const TextStyle(
                    fontSize: 13.5, color: _ink3, height: 1.6)),
            const SizedBox(height: 18),
            Container(height: 3, width: 48,
                decoration: BoxDecoration(
                    color: _gold, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(
              article.body.replaceAll('**', ''),
              style: const TextStyle(fontSize: 15, height: 2.2, color: _ink),
            ),
          ],
        ),
      ),
    );
  }
}
