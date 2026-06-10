import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// أقسام محتوى تظهر فقط حسب ملف المستخدمة (توأم/سكري حمل/رضاعة صناعية…).
/// مستقلّة بذاتها: تُدرَج بسطر واحد في أي تبويب وتفلتر حسب lifeStage.
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
        final items = _itemsFor(d);
        if (items.isEmpty) return const SizedBox.shrink();
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(padding: EdgeInsets.only(right: 4, bottom: 8),
                child: Text('📌 محتوى يخصّكِ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1B1320)))),
              ...items.map((it) => _card(context, it)),
            ]),
          ),
        );
      },
    );
  }

  Widget _card(BuildContext context, _CItem it) => GestureDetector(
    onTap: () => Navigator.push(context,
      MaterialPageRoute(builder: (_) => _ArticlePage(title: it.title, body: it.body))),
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4))]),
      child: Row(children: [
        Container(width: 46, height: 46,
          decoration: BoxDecoration(shape: BoxShape.circle, color: it.color.withValues(alpha: 0.15)),
          child: Center(child: Text(it.emoji, style: const TextStyle(fontSize: 20)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(it.title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF1B1320))),
          const SizedBox(height: 3),
          Text(it.sub, style: const TextStyle(fontSize: 12, color: Color(0xFF8E8295)),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        const Icon(Icons.arrow_back_ios, size: 14, color: Color(0xFFC9BCBC)),
      ]),
    ),
  );

  List<_CItem> _itemsFor(Map<String, dynamic> d) {
    final stage = d['lifeStage'];
    final out = <_CItem>[];
    if (stage == 'pregnant') {
      final p = (d['pregnancyProfile'] as Map?) ?? {};
      if (p['babies'] == 'twins' || p['babies'] == 'more') {
        out.add(_CItem('👶👶', 'الحمل بتوأم', 'تغذية ومتابعة وعلامات مهمة', const Color(0xFFE91E63), _twins));
      }
      if (p['condition'] == 'diabetes') {
        out.add(_CItem('🩸', 'سكري الحمل', 'نظام غذائي ومراقبة السكر', const Color(0xFFEF5350), _diabetes));
      }
      if (p['condition'] == 'hypertension') {
        out.add(_CItem('🩺', 'ارتفاع الضغط في الحمل', 'علامات تحذيرية ونصائح', const Color(0xFF7E57C2), _htn));
      }
    } else if (stage == 'baby') {
      final p = (d['babyProfile'] as Map?) ?? {};
      if (p['feeding'] == 'formula') {
        out.add(_CItem('🍼', 'الرضاعة الصناعية', 'تحضير وتعقيم وكميات', const Color(0xFF42A5F5), _formula));
      } else if (p['feeding'] == 'mixed') {
        out.add(_CItem('🍼', 'الرضاعة المختلطة', 'الموازنة والحفاظ على الإدرار', const Color(0xFF26A69A), _mixed));
      }
    } else if (stage == 'cycle') {
      final p = (d['cycleProfile'] as Map?) ?? {};
      if (p['regular'] == 'no') {
        out.add(_CItem('📅', 'الدورة غير المنتظمة', 'الأسباب ومتى تراجعين الطبيب', const Color(0xFFFF7043), _irregular));
      }
    }
    return out;
  }

  // ===== نصوص المقالات =====
  static const _twins = 'الحمل بتوأم رحلة مميّزة تحتاج رعاية إضافية.\n\nاحتياجك الغذائي أعلى: زيدي البروتين والحديد وحمض الفوليك والكالسيوم، واسألي طبيبك عن المكمّلات المناسبة. الزيادة الموصى بها في الوزن أكبر من الحمل المفرد.\n\nالمتابعة الطبية أكثر تكراراً، إذ يرتفع احتمال الولادة المبكرة وسكري الحمل وارتفاع الضغط. احرصي على الراحة وعدم إجهاد نفسك.\n\nراجعي طبيبك فوراً عند انقباضات مبكرة أو نزيف أو تورّم مفاجئ. (محتوى إرشادي لا يغني عن استشارة الطبيب.)';
  static const _diabetes = 'سكري الحمل قابل للسيطرة بالتغذية والمتابعة.\n\nقسّمي طعامك إلى وجبات صغيرة متكرّرة، قلّلي السكريات والنشويات السريعة، وركّزي على الحبوب الكاملة والخضار والبروتين. تجنّبي المشروبات المحلّاة.\n\nراقبي سكر الدم حسب تعليمات طبيبك، ومارسي نشاطاً خفيفاً كالمشي بعد الوجبات إن سمح طبيبك.\n\nمعظم الحالات تنضبط بالنظام الغذائي، وبعضها يحتاج دواءً أو إنسولين بإشراف طبي. التزمي بالمواعيد. (إرشادي فقط.)';
  static const _htn = 'ارتفاع ضغط الدم في الحمل يحتاج متابعة دقيقة.\n\nراقبي ضغطك بانتظام، قلّلي الملح والأطعمة المصنّعة، واحصلي على راحة كافية. لا تتناولي أي دواء دون استشارة الطبيب.\n\nراجعي الطبيب فوراً عند: صداع شديد مستمر، اضطراب الرؤية، تورّم مفاجئ في الوجه واليدين، أو ألم أعلى البطن — فقد تكون علامات ما قبل التسمّم الحملي.\n\nالمتابعة المنتظمة تحمي صحتك وصحة جنينك. (إرشادي لا يغني عن الطبيب.)';
  static const _formula = 'الرضاعة الصناعية تتطلّب نظافة ودقّة في التحضير.\n\nعقّمي الزجاجات والحلمات جيداً قبل كل استخدام في الأشهر الأولى. اغسلي يديك دائماً قبل التحضير.\n\nحضّري الحليب بالنسب المكتوبة على العلبة تماماً (لا تزيدي أو تنقصي المسحوق)، باستخدام ماء مغليّ ومبرّد. اختبري الحرارة على معصمك.\n\nلا تحتفظي بالحليب المحضّر أكثر من ساعة في الحرارة، وتخلّصي من المتبقّي بعد الرضعة. قدّمي الزجاجة عند الطلب ولا تجبري الطفل على إنهائها. (إرشادي فقط.)';
  static const _mixed = 'الرضاعة المختلطة تجمع بين الثدي والحليب الصناعي.\n\nللحفاظ على إدرار حليبك، قدّمي الثدي أولاً قبل إكمال الرضعة بالصناعي، وأرضعي بانتظام لأن الإدرار يعتمد على الطلب.\n\nأدخلي الزجاجة تدريجياً، ويفضّل بعد ترسيخ الرضاعة الطبيعية (بعد الأسابيع الأولى) لتجنّب ارتباك الحلمة.\n\nراقبي علامات الشبع وعدد الحفّاضات المبلّلة كمؤشّر على كفاية التغذية. استشيري طبيبك لتحديد الكمية المناسبة لعمر طفلك. (إرشادي فقط.)';
  static const _irregular = 'الدورة غير المنتظمة شائعة ولها أسباب متعددة.\n\nقد تنتج عن اضطراب هرموني، تكيّس المبايض، مشاكل الغدة الدرقية، التوتر، أو تغيّر الوزن. سجّلي بداية كل دورة في التطبيق بانتظام لتحسين دقّة التوقّعات.\n\nنمط حياة متوازن (نوم كافٍ، تغذية صحية، تقليل التوتر، نشاط معتدل) يساعد على انتظام الدورة.\n\nراجعي الطبيب إذا غابت الدورة أكثر من 3 أشهر، أو تكرّر عدم الانتظام، أو صاحبها ألم شديد أو نزيف غزير. (إرشادي لا يغني عن الطبيب.)';
}

class _CItem {
  final String emoji, title, sub, body;
  final Color color;
  _CItem(this.emoji, this.title, this.sub, this.color, this.body);
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
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          ...paras.map((p) => Padding(padding: const EdgeInsets.only(bottom: 16),
            child: Text(p.trim(), style: const TextStyle(fontSize: 15.5, height: 1.9, color: Color(0xFF3A343B))))),
        ]),
      ),
    );
  }
}
