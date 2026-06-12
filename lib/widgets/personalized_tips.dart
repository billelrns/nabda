import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// بطاقة نصائح مخصّصة تُحسب من بيانات الاستبيانات وتظهر أعلى كل تبويب.
/// مستقلّة بذاتها: تقرأ وثيقة المستخدمة داخليًا، فتُدرَج بسطر واحد في أي مكان.
class PersonalizedTipsCard extends StatelessWidget {
  /// مرحلة التبويب الذي أُدرجت فيه البطاقة (pregnant/baby/cycle).
  final String stage;
  const PersonalizedTipsCard({Key? key, required this.stage}) : super(key: key);

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
        final tips = _tipsFor(d);
        if (tips.isEmpty) return const SizedBox.shrink();
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topRight, end: Alignment.bottomLeft,
                colors: [Color(0xFFFCE4EC), Color(0xFFE0F2F1)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x22E91E63)),
              boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: const [
                Icon(Icons.auto_awesome, color: Color(0xFFE91E63), size: 20),
                SizedBox(width: 8),
                Text('نصائح مخصّصة لكِ',
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: Color(0xFF1F1A20))),
              ]),
              const SizedBox(height: 10),
              ...tips.take(3).map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Padding(padding: EdgeInsets.only(top: 6),
                    child: Icon(Icons.circle, size: 6, color: Color(0xFFE91E63))),
                  const SizedBox(width: 8),
                  Expanded(child: Text(t,
                    style: const TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF4A3F4F)))),
                ]),
              )),
            ]),
          ),
        );
      },
    );
  }

  List<String> _tipsFor(Map<String, dynamic> d) {
    final stage = d['lifeStage'];
    final out = <String>[];
    if (stage == 'pregnant') {
      final p = (d['pregnancyProfile'] as Map?) ?? {};
      if (p['babies'] == 'twins' || p['babies'] == 'more') {
        out.add('حملكِ بتوأم: احتياجكِ من السعرات والحديد والفولات أعلى، ومتابعتكِ الطبية أكثر تكراراً.');
      }
      if (p['condition'] == 'diabetes') {
        out.add('مع سكري الحمل: راقبي سكر الدم، قلّلي السكريات السريعة، وقسّمي وجباتكِ، والتزمي بمواعيد الطبيب.');
      } else if (p['condition'] == 'hypertension') {
        out.add('مع ارتفاع الضغط: راقبي ضغطكِ، قلّلي الملح، وراجعي الطبيب فوراً عند صداع شديد أو تورّم أو اضطراب رؤية.');
      } else if (p['condition'] == 'nausea') {
        out.add('للغثيان الشديد: وجبات صغيرة متكرّرة والزنجبيل وتجنّب الروائح المحفّزة؛ راجعي الطبيب إن منعكِ الأكل والشرب.');
      }
      if (p['firstPregnancy'] == true) {
        out.add('أول حمل؟ كل تغيّر جديد طبيعي — تابعي أسبوعكِ بأسبوع وسجّلي أي عرض يقلقكِ.');
      }
      if (p['age'] == '35-39' || p['age'] == '40+') {
        out.add('بعد سن 35 قد يطلب الطبيب فحوصات إضافية؛ حافظي على متابعة منتظمة.');
      }
    } else if (stage == 'baby') {
      final p = (d['babyProfile'] as Map?) ?? {};
      final f = p['feeding'];
      if (f == 'breast') {
        out.add('الرضاعة الطبيعية: أرضعي عند الطلب، واهتمّي بترطيبكِ وتغذيتكِ، وتابعي عدد الحفّاضات المبلّلة كمؤشّر للكفاية.');
      } else if (f == 'formula') {
        out.add('الرضاعة الصناعية: عقّمي الأدوات، حضّري الحليب بالنسب الصحيحة، ولا تحتفظي بالمتبقّي أكثر من ساعة.');
      } else if (f == 'mixed') {
        out.add('الرضاعة المختلطة: قدّمي الثدي أولاً للحفاظ على الإدرار، ثم أكملي بالصناعي حسب حاجة طفلكِ.');
      }
      if (p['firstChild'] == true) {
        out.add('طفلكِ الأول؟ النوم المتقطّع والبكاء طبيعيان — ثقي بنفسكِ واطلبي الدعم عند الحاجة.');
      }
    } else if (stage == 'cycle') {
      final p = (d['cycleProfile'] as Map?) ?? {};
      if (p['regular'] == 'no') {
        out.add('دورتكِ غير منتظمة: التوقّعات تقريبية — سجّلي بداية كل دورة بانتظام لتحسين الدقّة، وراجعي الطبيب إن طال عدم الانتظام.');
      }
      final g = p['trackingGoal'];
      if (g == 'fertility') {
        out.add('لتتبّع الخصوبة: ركّزي على أيام التبويض (منتصف الدورة تقريباً) وعلامات المخاط. يمكنكِ تفعيل وضع «أحاول الحمل».');
      } else if (g == 'avoid') {
        out.add('لتنظيم الحمل: التقويم وحده غير موثوق لمنع الحمل؛ استشيري الطبيب حول وسيلة مناسبة لكِ.');
      } else if (g == 'health') {
        out.add('متابعة صحية: تسجيل المزاج والأعراض يساعدكِ على فهم نمط جسمكِ عبر الأشهر.');
      }
    }
    return out;
  }
}
