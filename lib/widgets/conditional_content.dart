import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nabda_app/data/specialized_articles.dart';

/// أقسام محتوى تظهر حسب ملف المستخدمة، كل موضوع قائمة مقالات متخصّصة.
class ConditionalContentSection extends StatelessWidget {
  const ConditionalContentSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final d = snap.data!.data() as Map<String, dynamic>? ?? {};
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

  Widget _section(BuildContext context, _Topic t) {
    final arts = specializedArticles[t.key]!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(right: 4, bottom: 8),
          child: Text('${t.emoji} ${t.title}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1B1320)))),
        ...arts.map((a) => GestureDetector(
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => _ArticlePage(title: a.title, body: a.body))),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4))]),
            child: Row(children: [
              Container(width: 42, height: 42,
                decoration: BoxDecoration(shape: BoxShape.circle, color: t.color.withValues(alpha: 0.15)),
                child: const Center(child: Icon(Icons.article_outlined, color: Color(0xFF8E8295), size: 20))),
              const SizedBox(width: 12),
              Expanded(child: Text(a.title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1B1320)))),
              const Icon(Icons.arrow_back_ios, size: 14, color: Color(0xFFC9BCBC)),
            ]),
          ),
        )),
      ]),
    );
  }

  List<_Topic> _topicsFor(Map<String, dynamic> d) {
    final stage = d['lifeStage'];
    final out = <_Topic>[];
    if (stage == 'pregnant') {
      final p = (d['pregnancyProfile'] as Map?) ?? {};
      if (p['babies'] == 'twins' || p['babies'] == 'more') out.add(const _Topic('👶👶', 'الحمل بتوأم', 'twins', Color(0xFFE91E63)));
      if (p['condition'] == 'diabetes') out.add(const _Topic('🩸', 'سكري الحمل', 'diabetes', Color(0xFFEF5350)));
      if (p['condition'] == 'hypertension') out.add(const _Topic('🩺', 'ارتفاع الضغط في الحمل', 'htn', Color(0xFF7E57C2)));
      if (p['condition'] == 'nausea') out.add(const _Topic('🤢', 'غثيان الحمل', 'nausea', Color(0xFF66BB6A)));
      if (p['firstPregnancy'] == true) out.add(const _Topic('🌸', 'دليل الحمل الأول', 'firstPreg', Color(0xFFEC407A)));
    } else if (stage == 'baby') {
      final p = (d['babyProfile'] as Map?) ?? {};
      if (p['feeding'] == 'formula') out.add(const _Topic('🍼', 'الرضاعة الصناعية', 'formula', Color(0xFF42A5F5)));
      else if (p['feeding'] == 'mixed') out.add(const _Topic('🍼', 'الرضاعة المختلطة', 'mixed', Color(0xFF26A69A)));
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

class _ArticlePage extends StatelessWidget {
  final String title, body;
  const _ArticlePage({required this.title, required this.body});
  @override
  Widget build(BuildContext context) {
    final paras = body.split('\n\n').where((p) => p.trim().isNotEmpty).toList();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFCF7F7),
        appBar: AppBar(backgroundColor: const Color(0xFFE91E63), foregroundColor: Colors.white,
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          ...paras.map((p) => Padding(padding: const EdgeInsets.only(bottom: 16),
            child: Text(p.trim(), style: const TextStyle(fontSize: 15.5, height: 1.9, color: Color(0xFF3A343B))))),
        ]),
      ),
    );
  }
}
