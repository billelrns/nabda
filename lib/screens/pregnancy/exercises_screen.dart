import 'package:flutter/material.dart';

const Color _bg = Color(0xFFFFF5F7);
const Color _card = Colors.white;
const Color _teal = Color(0xFF00897B);
const Color _pink = Color(0xFFE91E63);
const Color _text1 = Color(0xFF2D2D3A);
const Color _text2 = Color(0xFF6B7280);

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({Key? key}) : super(key: key);
  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: const Text('تمارين الحمل', style: TextStyle(fontWeight: FontWeight.bold, color: _text1, fontSize: 20)),
          backgroundColor: _card, foregroundColor: _teal, elevation: 0, surfaceTintColor: Colors.transparent, centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            labelColor: _teal, unselectedLabelColor: _text2,
            indicatorColor: _teal, indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: const [Tab(text: 'الثلث الأول'), Tab(text: 'الثلث الثاني'), Tab(text: 'الثلث الثالث')],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTrimesterExercises(1),
            _buildTrimesterExercises(2),
            _buildTrimesterExercises(3),
          ],
        ),
      ),
    );
  }

  Widget _buildTrimesterExercises(int trimester) {
    final exercises = _exercisesByTrimester[trimester] ?? [];
    final safetyTips = _safetyByTrimester[trimester] ?? [];
    final color = [Colors.transparent, Colors.blue, Colors.orange, _pink][trimester];
    final weekRange = ['', '1-13', '14-26', '27-40'][trimester];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withOpacity(0.15), color.withOpacity(0.05)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Text('الثلث ${['', 'الأول', 'الثاني', 'الثالث'][trimester]}',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              Text('الأسابيع $weekRange', style: TextStyle(fontSize: 14, color: _text2)),
              const SizedBox(height: 10),
              Text(_trimesterDesc[trimester] ?? '', style: TextStyle(fontSize: 13, color: _text1, height: 1.5), textAlign: TextAlign.center),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Safety tips
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.warning_amber, color: Colors.amber[700], size: 20),
                const SizedBox(width: 8),
                Text('نصائح أمان', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.amber[800])),
              ]),
              const SizedBox(height: 10),
              ...safetyTips.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('• ', style: TextStyle(color: Colors.amber[700], fontWeight: FontWeight.bold)),
                  Expanded(child: Text(t, style: TextStyle(fontSize: 13, color: Colors.amber[900], height: 1.4))),
                ]),
              )),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Exercises
        ...exercises.map((e) => _buildExerciseCard(e)),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildExerciseCard(_Exercise exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: exercise.color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
          child: Icon(exercise.icon, color: exercise.color, size: 24),
        ),
        title: Text(exercise.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _text1)),
        subtitle: Row(
          children: [
            Icon(Icons.timer, size: 14, color: _text2),
            const SizedBox(width: 4),
            Text(exercise.duration, style: TextStyle(fontSize: 12, color: _text2)),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: exercise.difficulty == 'سهل' ? Colors.green.withOpacity(0.1) :
                       exercise.difficulty == 'متوسط' ? Colors.orange.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(exercise.difficulty, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                color: exercise.difficulty == 'سهل' ? Colors.green :
                       exercise.difficulty == 'متوسط' ? Colors.orange : Colors.red)),
            ),
          ],
        ),
        children: [
          // Benefits
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: _teal.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('الفوائد', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _teal)),
                const SizedBox(height: 6),
                Text(exercise.benefits, style: const TextStyle(fontSize: 13, color: _text1, height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Steps
          const Align(alignment: Alignment.centerRight,
            child: Text('الخطوات', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _text1))),
          const SizedBox(height: 8),
          ...List.generate(exercise.steps.length, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(color: exercise.color.withOpacity(0.15), shape: BoxShape.circle),
                child: Center(child: Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: exercise.color))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(exercise.steps[i], style: const TextStyle(fontSize: 13, color: _text1, height: 1.5))),
            ]),
          )),
          if (exercise.warning != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Icon(Icons.info_outline, color: Colors.red[400], size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(exercise.warning!, style: TextStyle(fontSize: 12, color: Colors.red[700]))),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}

class _Exercise {
  final String name, duration, difficulty, benefits;
  final IconData icon;
  final Color color;
  final List<String> steps;
  final String? warning;
  const _Exercise({required this.name, required this.duration, required this.difficulty,
    required this.benefits, required this.icon, required this.color, required this.steps, this.warning});
}

const _trimesterDesc = {
  1: 'ركّزي على تمارين خفيفة لتخفيف الغثيان والتعب.\nاستمعي لجسمك ولا تبالغي.',
  2: 'أفضل فترة للنشاط! استفيدي من الطاقة المتجددة.\nتجنبي الاستلقاء على الظهر.',
  3: 'ركّزي على التنفس والتمدد وتمارين الحوض.\nاستعدي للولادة.',
};

const _safetyByTrimester = {
  1: ['توقفي فورًا عند الشعور بدوخة أو ألم', 'اشربي الماء قبل وأثناء وبعد التمرين', 'تجنبي الحركات المفاجئة والقفز', 'لا تتمرني في حرارة عالية'],
  2: ['تجنبي الاستلقاء على الظهر بعد الأسبوع 16', 'ارتدي حذاء مريح وداعم', 'توقفي إذا شعرت بانقباضات أو نزيف', 'لا ترفعي أوزان ثقيلة'],
  3: ['تجنبي التمارين عالية الشدة', 'ركّزي على التنفس العميق', 'استخدمي كرسي للدعم في تمارين التوازن', 'استشيري طبيبتك قبل أي تمرين جديد'],
};

const _exercisesByTrimester = {
  1: [
    _Exercise(name: 'المشي الخفيف', duration: '15-20 دقيقة', difficulty: 'سهل',
      benefits: 'يحسن الدورة الدموية، يخفف الغثيان، يعزز المزاج ويساعد على النوم',
      icon: Icons.directions_walk, color: Color(0xFF4CAF50),
      steps: ['ابدئي بمشي بطيء لمدة 5 دقائق للإحماء', 'زيدي السرعة تدريجيًا لمشي متوسط', 'حافظي على ظهرك مستقيمًا ورأسك مرفوعًا', 'أنهي بمشي بطيء لمدة 3 دقائق للتهدئة']),
    _Exercise(name: 'تمارين التنفس العميق', duration: '10 دقائق', difficulty: 'سهل',
      benefits: 'يخفف التوتر والغثيان، يحسن أكسجة الدم للجنين، يساعد على الاسترخاء',
      icon: Icons.air, color: Color(0xFF42A5F5),
      steps: ['اجلسي بوضعية مريحة مع استقامة الظهر', 'تنفسي من الأنف ببطء لـ 4 عدات', 'احبسي النفس لعدتين', 'أخرجي الهواء من الفم ببطء لـ 6 عدات', 'كرري 10-15 مرة']),
    _Exercise(name: 'تمدد الرقبة والكتفين', duration: '10 دقائق', difficulty: 'سهل',
      benefits: 'يخفف توتر الرقبة والصداع، يحسن وضعية الجسم',
      icon: Icons.accessibility_new, color: Color(0xFFAB47BC),
      steps: ['أميلي رأسك ببطء نحو الكتف الأيمن — ثبتي 15 ثانية', 'كرري على الجانب الأيسر', 'أديري كتفيك للأمام 10 مرات ثم للخلف', 'ارفعي ذراعيك للأعلى وتمددي لمدة 10 ثوانٍ']),
    _Exercise(name: 'تمرين كيجل', duration: '5 دقائق', difficulty: 'سهل',
      benefits: 'يقوي عضلات الحوض، يسهل الولادة، يمنع سلس البول',
      icon: Icons.fitness_center, color: Color(0xFFFF7043),
      steps: ['شدي عضلات الحوض كأنك تحبسين البول', 'ثبتي الشد لمدة 5 ثوانٍ', 'استرخي لمدة 5 ثوانٍ', 'كرري 10-15 مرة', 'مارسي 3 مجموعات يوميًا']),
  ],
  2: [
    _Exercise(name: 'المشي السريع', duration: '20-30 دقيقة', difficulty: 'متوسط',
      benefits: 'يقوي القلب والأوعية الدموية، يحافظ على الوزن، يحسن الهضم',
      icon: Icons.directions_walk, color: Color(0xFF4CAF50),
      steps: ['إحماء بمشي بطيء 5 دقائق', 'مشي سريع لمدة 20 دقيقة — يمكنك التحدث بصعوبة', 'تهدئة بمشي بطيء 5 دقائق', 'تمدد خفيف بعد الانتهاء']),
    _Exercise(name: 'يوغا الحمل', duration: '20 دقائق', difficulty: 'متوسط',
      benefits: 'تحسن المرونة والتوازن، تقلل آلام الظهر، تحضر للولادة',
      icon: Icons.self_improvement, color: Color(0xFF7B1FA2),
      steps: ['وضعية القطة-البقرة: على أربع، قوسي ظهرك للأعلى ثم للأسفل ببطء (10 مرات)', 'وضعية الفراشة: اجلسي وضمي باطن قدميك، اضغطي ركبتيك للأسفل بلطف (30 ثانية)', 'وضعية المحارب: قفي وافتحي قدميك، اثني ركبة واحدة وارفعي ذراعيك (15 ثانية لكل جانب)', 'وضعية الطفل: اجلسي على ركبتيك وتمددي للأمام مع مد الذراعين (30 ثانية)'],
      warning: 'تجنبي وضعيات الاستلقاء على الظهر بعد الأسبوع 16'),
    _Exercise(name: 'السباحة', duration: '20-30 دقيقة', difficulty: 'متوسط',
      benefits: 'تمرين كامل الجسم بدون ضغط على المفاصل، يخفف التورم وآلام الظهر',
      icon: Icons.pool, color: Color(0xFF0288D1),
      steps: ['ابدئي بالمشي في الماء للإحماء', 'اسبحي بسرعة مريحة — تجنبي الإجهاد', 'جربي تمارين الأكوا (تمارين في الماء)', 'أنهي بالطفو والاسترخاء'],
      warning: 'تأكدي من نظافة المسبح وتجنبي الجاكوزي الساخن'),
    _Exercise(name: 'تمرين القرفصاء للحمل', duration: '10 دقائق', difficulty: 'متوسط',
      benefits: 'يوسع الحوض ويقوي الأرجل، يسهل وضعية الولادة',
      icon: Icons.fitness_center, color: Color(0xFFFF7043),
      steps: ['قفي مع فتح القدمين بعرض الكتفين', 'انزلي ببطء لوضعية القرفصاء مع إبقاء الظهر مستقيمًا', 'ثبتي لمدة 10-15 ثانية', 'ارتفعي ببطء', 'كرري 8-10 مرات']),
  ],
  3: [
    _Exercise(name: 'تمارين التنفس للولادة', duration: '15 دقيقة', difficulty: 'سهل',
      benefits: 'تحضرك للتعامل مع آلام المخاض، تساعد على الاسترخاء أثناء الانقباضات',
      icon: Icons.air, color: Color(0xFF42A5F5),
      steps: ['التنفس البطيء: شهيق 4 عدات من الأنف، زفير 6 عدات من الفم', 'التنفس السريع: شهيق وزفير سطحي وسريع (لوقت الانقباضات القوية)', 'تنفس الدفع: شهيق عميق ثم ادفعي مع الزفير (للمرحلة الثانية)', 'تدربي على كل نوع لمدة 5 دقائق']),
    _Exercise(name: 'تمدد الظهر والحوض', duration: '15 دقيقة', difficulty: 'سهل',
      benefits: 'يخفف آلام أسفل الظهر، يرخي عضلات الحوض استعدادًا للولادة',
      icon: Icons.accessibility_new, color: Color(0xFFAB47BC),
      steps: ['إمالة الحوض: قفي مقابل الحائط وأميلي حوضك للأمام والخلف (10 مرات)', 'دوائر الحوض: قفي وأديري حوضك بحركة دائرية بطيئة (10 لكل اتجاه)', 'تمدد الفخذ: افتحي ساقيك وانحني ببطء لكل جانب (15 ثانية)', 'وضعية القطة: على أربع، قوسي ظهرك ثم أرخيه (10 مرات)']),
    _Exercise(name: 'المشي اليومي', duration: '15-20 دقيقة', difficulty: 'سهل',
      benefits: 'يساعد الجنين على النزول للحوض، يحسن المزاج، يسهل الولادة',
      icon: Icons.directions_walk, color: Color(0xFF4CAF50),
      steps: ['امشي بسرعة مريحة', 'اختاري أرضية مستوية وآمنة', 'خذي استراحات كلما احتجت', 'اصطحبي أحدًا معك للأمان']),
    _Exercise(name: 'تمرين الكرة للولادة', duration: '15 دقيقة', difficulty: 'سهل',
      benefits: 'يريح أسفل الظهر، يساعد في وضعية الجنين المثالية، يوسع الحوض',
      icon: Icons.sports_basketball, color: Color(0xFFFF9800),
      steps: ['اجلسي على كرة التمارين مع قدمين مسطحتين على الأرض', 'تأرجحي بحوضك للأمام والخلف ببطء', 'أديري حوضك بحركات دائرية', 'ارتدي وتمايلي بلطف من جانب لآخر', 'كرري كل حركة لمدة 3-5 دقائق']),
    _Exercise(name: 'كيجل المكثف', duration: '10 دقائق', difficulty: 'سهل',
      benefits: 'يقوي عضلات الولادة، يسرع التعافي بعد الولادة',
      icon: Icons.fitness_center, color: Color(0xFFE91E63),
      steps: ['شدي عضلات الحوض لمدة 10 ثوانٍ', 'استرخي لمدة 10 ثوانٍ', 'كرري 15-20 مرة', 'جربي الشد السريع: شد واسترخاء سريع 10 مرات', 'مارسي 3 مجموعات يوميًا']),
  ],
};
