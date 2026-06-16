import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nabda_app/main.dart' show MainNav;

/// شاشة تحديث حالة الحمل — تتعامل مع الولادة وفقدان الحمل بنبرة رحيمة.
/// كل الخيارات خاصّة بالمستخدمة، بلا إجبار على ذكر السبب أو تاريخ،
/// وبلا أي تهنئة أو إيموجي احتفالي في مسار الفقدان.
class EndPregnancyScreen extends StatefulWidget {
  const EndPregnancyScreen({Key? key}) : super(key: key);

  @override
  State<EndPregnancyScreen> createState() => _EndPregnancyScreenState();
}

class _EndPregnancyScreenState extends State<EndPregnancyScreen> {
  static const Color _teal = Color(0xFF009688);
  static const Color _pink = Color(0xFFE91E63);
  static const Color _textPrimary = Color(0xFF2D2D3A);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _bg = Color(0xFFF9F9F9);

  bool _busy = false;
  bool _showLossPath = false;
  bool _showBirthPath = false;

  /// الأرشفة الصامتة + مسح بيانات الحمل النشطة + ضبط المرحلة التالية.
  Future<void> _finish({required String outcome, String nextStage = 'cycle', String? birthType}) async {
    if (_busy) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _busy = true);
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final snap = await userRef.get();
      final d = snap.data() ?? {};

      // حساب أسبوع الحمل عند الولادة لرصد الولادة المبكرة (قبل الأسبوع 37)
      // نفس اصطلاح بقية التطبيق: الأسبوع = الأيام منذ بداية الحمل ÷ 7
      int? birthWeek;
      bool isPreterm = false;
      if (outcome == 'birth') {
        final startTs = d['pregnancyStartDate'];
        if (startTs is Timestamp) {
          final w = (DateTime.now().difference(startTs.toDate()).inDays / 7)
              .floor()
              .clamp(1, 42);
          birthWeek = w;
          isPreterm = w < 37;
        }
      }

      // أرشفة صامتة (لا حذف) — قد تكون مهمّة طبيًا وقد ترغب المستخدمة بتذكّرها
      await userRef.collection('pregnancyHistory').add({
        'startDate': d['pregnancyStartDate'],
        'endDate': FieldValue.serverTimestamp(),
        'outcome': outcome, // 'birth' | 'loss' | 'unspecified'
        if (birthWeek != null) 'birthWeek': birthWeek,
        if (outcome == 'birth') 'pretermBirth': isPreterm,
        if (birthType != null) 'birthType': birthType, // 'vaginal' | 'cesarean'
        'archivedAt': FieldValue.serverTimestamp(),
      });

      final stage = outcome == 'birth' ? 'baby' : nextStage;
      final update = <String, dynamic>{
        'pregnancyStartDate': null,
        'postTermAck': null,
        'lifeStage': stage,
      };
      if (outcome == 'birth') {
        update['babyBirthDate'] = FieldValue.serverTimestamp(); // قابل للتعديل لاحقًا
        // علامات الولادة المبكرة لتفعيل محتوى «الطفل الخديج» في رعاية الطفل
        update['pretermBirth'] = isPreterm;
        if (birthWeek != null) update['birthWeek'] = birthWeek;
        // نوع الولادة (يؤكّد أو يحدّث الخطة المسجّلة) لتفعيل محتوى «التعافي بعد القيصرية»
        if (birthType != null) update['birthType'] = birthType;
      }
      // ملاحظة: لا نضبط lastPeriodStart عند الفقدان — تُسجّلها المستخدمة عند عودة دورتها.
      await userRef.set(update, SetOptions(merge: true));

      // مزامنة المرحلة محليًا حتى يهبط التنقّل على التبويب الصحيح فورًا
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('life_stage', stage);

      if (!mounted) return;
      final msg = outcome == 'birth'
          ? 'مبروك قدوم صغيركِ 🤍 انتقلنا إلى رعاية الطفل'
          : 'سجّلي بداية دورتكِ عندما تعود 🤍';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF00897B),
        duration: const Duration(seconds: 3),
      ));
      // استبدال شجرة التنقّل بـ MainNav جديدة تهبط على تبويب المرحلة الجديدة
      // (الدورة عند الفقدان، الطفل عند الولادة) بدل البقاء على تبويب الحمل
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => MainNav()),
        (r) => false,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('تعذّر التحديث: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: const Text('تحديث حالة الحمل',
              style: TextStyle(fontWeight: FontWeight.bold, color: _textPrimary)),
          backgroundColor: Colors.white,
          foregroundColor: _teal,
          elevation: 0,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
        ),
        body: AbsorbPointer(
          absorbing: _busy,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _showLossPath
                ? _buildLossPath()
                : _showBirthPath
                    ? _buildBirthTypePath()
                    : _buildOptions(),
          ),
        ),
      ),
    );
  }

  // ── الخيارات الرئيسية ──
  Widget _buildOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text('حدّثي حالة حملكِ متى شئتِ. كل خياراتكِ خاصّة بكِ.',
            style: TextStyle(fontSize: 15, height: 1.7, color: _textSecondary)),
        const SizedBox(height: 24),
        _optionCard(
          emoji: '🤍',
          title: 'وضعتُ مولودي',
          subtitle: 'الانتقال إلى متابعة رعاية الطفل',
          color: _pink,
          onTap: () => setState(() => _showBirthPath = true),
        ),
        _optionCard(
          emoji: '🌧️',
          title: 'توقّف الحمل',
          subtitle: 'خيارات لطيفة ودعم لكِ',
          color: const Color(0xFF7E8CA0),
          onTap: () => setState(() => _showLossPath = true),
        ),
        _optionCard(
          emoji: '•••',
          title: 'أفضّل عدم التحديد',
          subtitle: 'إيقاف متابعة الحمل والعودة لتتبّع الدورة',
          color: _teal,
          onTap: () => _finish(outcome: 'unspecified'),
        ),
        if (_busy) ...[
          const SizedBox(height: 20),
          const Center(child: CircularProgressIndicator(color: _teal)),
        ],
      ],
    );
  }

  // ── مسار الولادة: اختيار نوع الولادة (لطيف واختياري) ──
  Widget _buildBirthTypePath() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text('مبروك قدوم صغيركِ 🤍',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: _textPrimary)),
        const SizedBox(height: 10),
        const Text('كيف وضعتِ مولودكِ؟ هذا يساعدنا على تقديم محتوى تعافٍ مناسب لكِ. وكل خياراتكِ خاصّة بكِ.',
            style: TextStyle(fontSize: 15, height: 1.7, color: _textSecondary)),
        const SizedBox(height: 24),
        _optionCard(
          emoji: '🌸',
          title: 'ولادة طبيعية',
          subtitle: 'الانتقال إلى متابعة رعاية الطفل',
          color: _pink,
          onTap: () => _finish(outcome: 'birth', birthType: 'vaginal'),
        ),
        _optionCard(
          emoji: '🏥',
          title: 'ولادة قيصرية',
          subtitle: 'سنعرض لكِ محتوى التعافي بعد القيصرية',
          color: const Color(0xFF5C6BC0),
          onTap: () => _finish(outcome: 'birth', birthType: 'cesarean'),
        ),
        _optionCard(
          emoji: '•••',
          title: 'أفضّل عدم التحديد',
          subtitle: 'الانتقال إلى رعاية الطفل مباشرة',
          color: _teal,
          onTap: () => _finish(outcome: 'birth'),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _busy ? null : () => setState(() => _showBirthPath = false),
            icon: const Icon(Icons.arrow_forward, size: 16, color: _textSecondary),
            label: const Text('رجوع', style: TextStyle(color: _textSecondary)),
          ),
        ),
        if (_busy) ...[
          const SizedBox(height: 20),
          const Center(child: CircularProgressIndicator(color: _teal)),
        ],
      ],
    );
  }

  // ── مسار الفقدان (رحيم، بلا تهنئة) ──
  Widget _buildLossPath() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF3F8),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x22000000)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('نحن معكِ 🤍',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: _textPrimary)),
              SizedBox(height: 12),
              Text(
                'نُؤسفنا لما تمرّين به. خذي وقتكِ في الراحة والتعافي، ولا تترددي في طلب الدعم ممّن تثقين بهم أو من مختصّة. أنتِ لستِ وحدكِ.',
                style: TextStyle(fontSize: 15, height: 1.8, color: Color(0xFF4A4F58)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // مصدر دعم
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const _LossSupportArticleScreen())),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 8, offset: Offset(0, 3))],
            ),
            child: Row(children: const [
              Icon(Icons.menu_book_outlined, color: _teal),
              SizedBox(width: 12),
              Expanded(
                child: Text('اقرئي عن التعافي بعد فقدان الحمل',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: _textPrimary)),
              ),
              Icon(Icons.arrow_back_ios, size: 14, color: Color(0xFFC9BCBC)),
            ]),
          ),
        ),
        const SizedBox(height: 24),
        const Text('كيف تحبّين المتابعة؟',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _textPrimary)),
        const SizedBox(height: 12),
        _optionCard(
          emoji: '🌱',
          title: 'العودة لتتبّع الدورة',
          subtitle: 'سجّلي بداية دورتكِ عندما تعود',
          color: _teal,
          onTap: () => _finish(outcome: 'loss', nextStage: 'cycle'),
        ),
        _optionCard(
          emoji: '⏸️',
          title: 'إيقاف المتابعة مؤقّتًا',
          subtitle: 'بلا أي ضغط — في وقتكِ الخاص',
          color: const Color(0xFF7E8CA0),
          onTap: () => _finish(outcome: 'loss', nextStage: 'cycle'),
        ),
        if (_busy) ...[
          const SizedBox(height: 20),
          const Center(child: CircularProgressIndicator(color: _teal)),
        ],
        const SizedBox(height: 10),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _showLossPath = false),
            child: const Text('رجوع', style: TextStyle(color: _textSecondary)),
          ),
        ),
      ],
    );
  }

  Widget _optionCard({
    required String emoji,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Row(children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _textPrimary)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(fontSize: 12.5, color: _textSecondary)),
              ]),
            ),
            Icon(Icons.arrow_back_ios, size: 14, color: color),
          ]),
        ),
      ),
    );
  }
}

/// مقال دعم لطيف عن التعافي بعد فقدان الحمل (ليس بديلًا عن استشارة مختصّة).
class _LossSupportArticleScreen extends StatelessWidget {
  const _LossSupportArticleScreen();

  static const Color _teal = Color(0xFF009688);
  static const Color _textPrimary = Color(0xFF2D2D3A);

  @override
  Widget build(BuildContext context) {
    const paragraphs = [
      'فقدان الحمل تجربة موجعة، ومشاعر الحزن والصدمة والغضب وحتى الذنب كلّها طبيعية تمامًا. لا يوجد شكل «صحيح» للحزن، ولا جدول زمني له؛ امنحي نفسكِ الإذن بأن تشعري بما تشعرين به دون أن تحاسبي نفسكِ.',
      'جسديًا، يحتاج جسمكِ وقتًا للتعافي. قد يستمرّ بعض النزيف لأيام، وقد تعودين تدريجيًا لطاقتكِ. راقبي علاماتكِ، وراجعي طبيبتكِ إذا ظهر نزيف غزير أو ألم شديد أو حمّى أو إفرازات ذات رائحة — فهذه علامات تستدعي رعاية فورية.',
      'عودة الدورة تختلف من امرأة لأخرى، وغالبًا تعود خلال أربعة إلى ستة أسابيع تقريبًا. لذلك في التطبيق لن نضع لكِ تاريخًا تلقائيًا؛ سجّلي بداية دورتكِ بنفسكِ عندما تعود، لتكون التوقّعات دقيقة وغير مزعجة.',
      'نفسيًا، اسمحي لنفسكِ بطلب الدعم. تحدّثي مع شريككِ أو صديقة أو فرد تثقين به، أو انضمّي لمجموعة دعم. مشاركة ما تشعرين به تخفّف ثقله. وإن استمرّ الحزن الشديد أو فقدان الاهتمام بالحياة اليومية أكثر من أسبوعين، فاستشارة مختصّة نفسية خطوة قوية لا ضعف فيها.',
      'اعتني بأساسيّاتكِ: نوم كافٍ قدر الإمكان، طعام مغذٍّ، وترطيب جيّد، وحركة لطيفة عندما تشعرين بالاستعداد. الأشياء الصغيرة تساعد في الأيام الثقيلة.',
      'وأخيرًا: لستِ مسؤولة عمّا حدث، ولستِ وحدكِ. كثيرات مررن بهذه التجربة وتعافين. خذي وقتكِ، وكوني لطيفة مع نفسكِ.',
    ];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('التعافي بعد فقدان الحمل',
              style: TextStyle(fontWeight: FontWeight.bold, color: _textPrimary)),
          backgroundColor: Colors.white,
          foregroundColor: _teal,
          elevation: 0,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            for (final p in paragraphs) ...[
              Text(p, style: const TextStyle(fontSize: 16, height: 1.9, color: Color(0xFF333333))),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'تنويه: هذا المحتوى للدعم والمعلومة العامة، وليس بديلًا عن استشارة طبيبتكِ أو مختصّة.',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF4A3F4F), height: 1.6),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
