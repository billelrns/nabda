import 'package:flutter/material.dart';
import '../../models/pregnancy_week_articles.dart' show pregnancyMonthArForWeek;
import '../../utils/fetus_size.dart';

const Color _bg = Color(0xFFFFF5F7);
const Color _card = Colors.white;
const Color _teal = Color(0xFF00897B);
const Color _pink = Color(0xFFE91E63);
const Color _text1 = Color(0xFF2D2D3A);
const Color _text2 = Color(0xFF6B7280);

class FetusSizeScreen extends StatefulWidget {
  final int initialWeek;
  const FetusSizeScreen({Key? key, this.initialWeek = 8}) : super(key: key);
  @override
  State<FetusSizeScreen> createState() => _FetusSizeScreenState();
}

class _FetusSizeScreenState extends State<FetusSizeScreen> {
  late int _selectedWeek;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _selectedWeek = widget.initialWeek.clamp(4, 42);
    _pageController = PageController(initialPage: _selectedWeek - 4);
  }

  @override
  void dispose() { _pageController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: const Text('حجم جنينك', style: TextStyle(fontWeight: FontWeight.bold, color: _text1, fontSize: 20)),
          backgroundColor: _card, foregroundColor: _teal, elevation: 0, surfaceTintColor: Colors.transparent, centerTitle: true,
        ),
        body: Column(
          children: [
            // Week selector
            Container(
              height: 60,
              color: _card,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                itemCount: 39, // weeks 4-42
                itemBuilder: (_, i) {
                  final week = i + 4;
                  final isSelected = week == _selectedWeek;
                  return GestureDetector(
                    onTap: () {
                      setState(() { _selectedWeek = week; });
                      _pageController.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                    },
                    child: Container(
                      width: 44, margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? _teal : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(child: Text('$week', style: TextStyle(
                        fontSize: 15, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : _text2,
                      ))),
                    ),
                  );
                },
              ),
            ),
            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: 39,
                onPageChanged: (i) => setState(() { _selectedWeek = i + 4; }),
                itemBuilder: (_, i) {
                  final week = i + 4;
                  final data = _weekData[week];
                  if (data == null) return const SizedBox();
                  return _buildWeekPage(week, data);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekPage(int week, _FetusWeekData data) {
    final trimester = week <= 13 ? 1 : week <= 26 ? 2 : 3;
    final trimesterName = ['', 'الأول', 'الثاني', 'الثالث'][trimester];
    final trimesterColor = [Colors.transparent, Colors.blue, Colors.orange, _pink][trimester];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Fruit card
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [data.bgColor.withOpacity(0.15), data.bgColor.withOpacity(0.05)],
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: data.bgColor.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              // الفاكهة والاسم من المصدر الموحّد — مطابقان تماماً لبقية الشاشات
              Text(FetusSize.emoji(week), style: const TextStyle(fontSize: 100)),
              const SizedBox(height: 16),
              Text('بحجم ${FetusSize.name(week)}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: data.bgColor)),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: trimesterColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                    child: Text('الثلث $trimesterName · ${pregnancyMonthArForWeek(week)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: trimesterColor)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: _teal.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Text('الأسبوع $week', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _teal)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Size details
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
          child: Row(
            children: [
              _sizeItem(Icons.straighten, 'الطول', data.length, Colors.blue),
              Container(width: 1, height: 40, color: Colors.grey[200]),
              _sizeItem(Icons.monitor_weight_outlined, 'الوزن', data.weight, Colors.orange),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Development highlights
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: _pink, size: 20),
                  const SizedBox(width: 8),
                  const Text('تطورات هذا الأسبوع', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _text1)),
                ],
              ),
              const SizedBox(height: 14),
              ...data.developments.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 8, height: 8, margin: const EdgeInsets.only(top: 6, left: 10),
                      decoration: BoxDecoration(color: _teal, shape: BoxShape.circle),
                    ),
                    Expanded(child: Text(d, style: const TextStyle(fontSize: 14, color: _text1, height: 1.5))),
                  ],
                ),
              )),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Mom tip
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _pink.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _pink.withOpacity(0.15)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💡', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('نصيحة للأم', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _pink)),
                    const SizedBox(height: 4),
                    Text(data.momTip, style: const TextStyle(fontSize: 13, color: _text1, height: 1.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _sizeItem(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _text1)),
          Text(label, style: TextStyle(fontSize: 12, color: _text2)),
        ],
      ),
    );
  }
}

class _FetusWeekData {
  final String emoji, fruitName, length, weight, momTip;
  final Color bgColor;
  final List<String> developments;
  const _FetusWeekData({required this.emoji, required this.fruitName, required this.length, required this.weight,
    required this.bgColor, required this.developments, required this.momTip});
}

const Map<int, _FetusWeekData> _weekData = {
  4: _FetusWeekData(emoji: '🌰', fruitName: 'بذرة خشخاش', length: '0.1 سم', weight: 'أقل من 1 غ', bgColor: Color(0xFF8D6E63),
    developments: ['بداية تشكل الأنبوب العصبي', 'القلب يبدأ بالتكون', 'تبدأ المشيمة بالتطور'], momTip: 'ابدئي بتناول حمض الفوليك يوميًا'),
  5: _FetusWeekData(emoji: '🫘', fruitName: 'حبة سمسم', length: '0.2 سم', weight: 'أقل من 1 غ', bgColor: Color(0xFF795548),
    developments: ['القلب يبدأ بالنبض', 'تتشكل براعم الأطراف', 'يبدأ الدماغ بالنمو السريع'], momTip: 'الراحة مهمة في هذه المرحلة المبكرة'),
  6: _FetusWeekData(emoji: '🫐', fruitName: 'حبة عدس', length: '0.6 سم', weight: 'أقل من 1 غ', bgColor: Color(0xFF3F51B5),
    developments: ['الأنف والفم يبدآن بالتشكل', 'الأمعاء تتطور', 'بداية تشكل اليدين والقدمين'], momTip: 'الغثيان طبيعي — جربي تناول البسكويت المالح صباحًا'),
  7: _FetusWeekData(emoji: '🫒', fruitName: 'حبة توت', length: '1.3 سم', weight: '1 غ', bgColor: Color(0xFF4CAF50),
    developments: ['الدماغ ينمو بسرعة', 'تتشكل الأصابع', 'الكبد ينتج خلايا الدم'], momTip: 'اشربي الكثير من الماء للحفاظ على رطوبة جسمك'),
  8: _FetusWeekData(emoji: '🍇', fruitName: 'حبة فاصوليا', length: '1.6 سم', weight: '1 غ', bgColor: Color(0xFF9C27B0),
    developments: ['أصابع اليدين والقدمين تتشكل', 'الأذنان تبدآن بالتكون', 'الجنين يبدأ بالتحرك'], momTip: 'تجنبي الأطعمة النيئة والأجبان غير المبسترة'),
  9: _FetusWeekData(emoji: '🍒', fruitName: 'حبة كرز', length: '2.3 سم', weight: '2 غ', bgColor: Color(0xFFE91E63),
    developments: ['العضلات تبدأ بالعمل', 'الأعضاء التناسلية تتشكل', 'الوجه يصبح أكثر وضوحًا'], momTip: 'النوم الكافي يساعد جسمك على التكيف مع التغيرات'),
  10: _FetusWeekData(emoji: '🍓', fruitName: 'فراولة', length: '3.1 سم', weight: '4 غ', bgColor: Color(0xFFF44336),
    developments: ['الأظافر تبدأ بالنمو', 'العظام تبدأ بالتصلب', 'الكلى تنتج البول'], momTip: 'تناولي الأطعمة الغنية بالكالسيوم لدعم عظام طفلك'),
  11: _FetusWeekData(emoji: '🍋', fruitName: 'تين', length: '4.1 سم', weight: '7 غ', bgColor: Color(0xFFFFC107),
    developments: ['الرأس يشكل نصف الطول', 'براعم الأسنان تتشكل', 'الحبل السري يعمل بكفاءة'], momTip: 'قد تلاحظين اختفاء الغثيان تدريجيًا'),
  12: _FetusWeekData(emoji: '🍑', fruitName: 'ليمون', length: '5.4 سم', weight: '14 غ', bgColor: Color(0xFFFF9800),
    developments: ['الأعضاء كلها تشكلت', 'الجنين يتثاءب ويمص إبهامه', 'نهاية المرحلة الحرجة'], momTip: 'نهاية الثلث الأول — أخبري عائلتك بالخبر السعيد!'),
  13: _FetusWeekData(emoji: '🥝', fruitName: 'كيوي', length: '7.4 سم', weight: '23 غ', bgColor: Color(0xFF8BC34A),
    developments: ['بصمات الأصابع تتشكل', 'الحبال الصوتية تتطور', 'المبايض أو الخصيتين تتطور'], momTip: 'بداية الثلث الثاني — ستشعرين بطاقة أكبر'),
  14: _FetusWeekData(emoji: '🍊', fruitName: 'برتقالة صغيرة', length: '8.7 سم', weight: '43 غ', bgColor: Color(0xFFFF9800),
    developments: ['الجنين يستطيع العبوس والتحديق', 'الغدة الدرقية تعمل', 'الشعر الناعم (الزغب) يظهر'], momTip: 'مارسي رياضة المشي الخفيف يوميًا'),
  16: _FetusWeekData(emoji: '🥑', fruitName: 'أفوكادو', length: '11.6 سم', weight: '100 غ', bgColor: Color(0xFF4CAF50),
    developments: ['العينان حساسة للضوء', 'الجهاز العصبي يتطور', 'العظام أصبحت أقوى'], momTip: 'قد تشعرين بأولى حركات الجنين!'),
  18: _FetusWeekData(emoji: '🫑', fruitName: 'فلفل حلو', length: '14.2 سم', weight: '190 غ', bgColor: Color(0xFF4CAF50),
    developments: ['الأذنان تستطيعان السمع', 'الجنين يتقلب ويتحرك بنشاط', 'المايلين يغلف الأعصاب'], momTip: 'تحدثي مع جنينك — هو يسمعك الآن!'),
  20: _FetusWeekData(emoji: '🍌', fruitName: 'موزة', length: '16.4 سم', weight: '300 غ', bgColor: Color(0xFFFFC107),
    developments: ['منتصف الحمل!', 'الجلد يتغطى بمادة شمعية واقية', 'الجنين ينام ويستيقظ بانتظام'], momTip: 'موعد السونار التفصيلي — يمكنك معرفة الجنس'),
  22: _FetusWeekData(emoji: '🥕', fruitName: 'جزرة كبيرة', length: '27.8 سم', weight: '430 غ', bgColor: Color(0xFFFF9800),
    developments: ['حاسة اللمس تتطور', 'الشفاه والحواجب واضحة', 'العينان تكونتا لكن القزحية بلا لون'], momTip: 'تناولي الأطعمة الغنية بالحديد لتجنب فقر الدم'),
  24: _FetusWeekData(emoji: '🌽', fruitName: 'ذرة', length: '30 سم', weight: '600 غ', bgColor: Color(0xFFFFC107),
    developments: ['الرئتان تنتجان مادة السيرفاكتانت', 'الجنين يستجيب للأصوات', 'دورة نوم واستيقاظ منتظمة'], momTip: 'فحص سكري الحمل في هذا الأسبوع'),
  26: _FetusWeekData(emoji: '🥬', fruitName: 'خس', length: '35.6 سم', weight: '760 غ', bgColor: Color(0xFF66BB6A),
    developments: ['العينان تفتحان لأول مرة', 'الرئتان تتطوران بسرعة', 'الدماغ ينمو بشكل مكثف'], momTip: 'بداية الثلث الثالث — ابدئي تحضير حقيبة الولادة'),
  28: _FetusWeekData(emoji: '🍆', fruitName: 'باذنجان', length: '37.6 سم', weight: '1 كغ', bgColor: Color(0xFF7B1FA2),
    developments: ['الجنين يحلم أثناء النوم (REM)', 'يستطيع التمييز بين الأصوات', 'الدهون تتراكم تحت الجلد'], momTip: 'راقبي حركات الجنين — 10 حركات كل ساعتين طبيعي'),
  30: _FetusWeekData(emoji: '🥥', fruitName: 'جوز هند', length: '39.9 سم', weight: '1.3 كغ', bgColor: Color(0xFF795548),
    developments: ['نخاع العظام ينتج خلايا الدم', 'الشعر الحقيقي ينمو', 'الجنين يتنفس السائل للتدريب'], momTip: 'نامي على جانبك الأيسر لتحسين تدفق الدم'),
  32: _FetusWeekData(emoji: '🍊', fruitName: 'برتقالة كبيرة', length: '42.4 سم', weight: '1.7 كغ', bgColor: Color(0xFFFF9800),
    developments: ['العظام تصلبت ما عدا الجمجمة', 'أظافر القدم مكتملة', 'الجلد أصبح أقل شفافية'], momTip: 'قد تشعرين بضيق التنفس — الجنين يضغط على الحجاب الحاجز'),
  34: _FetusWeekData(emoji: '🍈', fruitName: 'شمام', length: '45 سم', weight: '2.1 كغ', bgColor: Color(0xFF8BC34A),
    developments: ['الرئتان شبه مكتملتين', 'الجهاز المناعي يتطور', 'الجنين يستدير برأسه للأسفل'], momTip: 'ابدئي بحضور دورة تحضير الولادة'),
  36: _FetusWeekData(emoji: '🥬', fruitName: 'ملفوف', length: '47.4 سم', weight: '2.6 كغ', bgColor: Color(0xFF4CAF50),
    developments: ['الجنين يكتسب وزنًا سريعًا', 'الكلى والكبد يعملان بكفاءة', 'الزغب يختفي تدريجيًا'], momTip: 'جهّزي حقيبة المستشفى — الولادة قريبة!'),
  38: _FetusWeekData(emoji: '🍉', fruitName: 'بطيخة صغيرة', length: '49.8 سم', weight: '3 كغ', bgColor: Color(0xFF4CAF50),
    developments: ['الأعضاء مكتملة وجاهزة', 'الدماغ والرئتان يكتملان', 'الجنين مكتمل النمو'], momTip: 'راقبي علامات المخاض: تقلصات منتظمة، نزول ماء'),
  40: _FetusWeekData(emoji: '🎃', fruitName: 'يقطينة', length: '51.2 سم', weight: '3.4 كغ', bgColor: Color(0xFFFF9800),
    developments: ['الجنين مكتمل 100%', 'مستعد للقاء العالم', 'الولادة يمكن أن تحدث أي لحظة'], momTip: 'حان الوقت! تواصلي مع طبيبتك عند بدء التقلصات'),
  42: _FetusWeekData(emoji: '🍉', fruitName: 'بطيخة كبيرة', length: '52 سم', weight: '3.7 كغ', bgColor: Color(0xFF388E3C),
    developments: ['الجنين مكتمل تمامًا', 'قد يكون الجلد جافًا قليلًا', 'الطبيب قد يقرر التحريض'], momTip: 'لا تقلقي — طبيبتك ستتابع حالتك عن كثب'),
  // Fill in missing weeks with interpolated data
  15: _FetusWeekData(emoji: '🍎', fruitName: 'تفاحة', length: '10.1 سم', weight: '70 غ', bgColor: Color(0xFFF44336),
    developments: ['الجنين يستطيع الإمساك بقبضته', 'المفاصل تعمل', 'حاسة التذوق تتطور'], momTip: 'أكثري من تناول الفواكه والخضروات'),
  17: _FetusWeekData(emoji: '🥔', fruitName: 'بطاطس', length: '13 سم', weight: '140 غ', bgColor: Color(0xFF8D6E63),
    developments: ['الهيكل العظمي يتحول من غضروف لعظم', 'الحبل السري يزداد قوة', 'بصمات الأصابع فريدة'], momTip: 'ارتدي ملابس مريحة — بطنك يكبر'),
  19: _FetusWeekData(emoji: '🥭', fruitName: 'مانجو', length: '15.3 سم', weight: '240 غ', bgColor: Color(0xFFFF9800),
    developments: ['المادة الشمعية تحمي الجلد', 'الحواس الخمس تتطور', 'الجنين يبتلع السائل الأمنيوسي'], momTip: 'احرصي على ترطيب بشرتك لتقليل علامات التمدد'),
  21: _FetusWeekData(emoji: '🥕', fruitName: 'جزرة', length: '26.7 سم', weight: '360 غ', bgColor: Color(0xFFFF9800),
    developments: ['الجنين يتذوق ما تأكلينه', 'الحواجب والرموش واضحة', 'حركات أقوى وأوضح'], momTip: 'تناولي وجبات صغيرة ومتكررة لتقليل الحرقة'),
  23: _FetusWeekData(emoji: '🥥', fruitName: 'بابايا', length: '28.9 سم', weight: '500 غ', bgColor: Color(0xFFFF7043),
    developments: ['الجلد مجعد وشفاف', 'الأوعية الدموية تتطور في الرئتين', 'الجنين يسمع الموسيقى'], momTip: 'شغّلي موسيقى هادئة — طفلك يستمتع بها'),
  25: _FetusWeekData(emoji: '🥦', fruitName: 'بروكلي', length: '34.6 سم', weight: '660 غ', bgColor: Color(0xFF4CAF50),
    developments: ['الجنين يستجيب للمس بطنك', 'الشعر يبدأ بإظهار لونه', 'حركة التنفس تتدرب'], momTip: 'دلّكي بطنك بلطف — طفلك يشعر بلمستك'),
  27: _FetusWeekData(emoji: '🥬', fruitName: 'قرنبيط', length: '36.6 سم', weight: '875 غ', bgColor: Color(0xFF66BB6A),
    developments: ['الدماغ ينمو بشكل مكثف', 'الجنين يفتح ويغلق عينيه', 'يميز بين صوت الأم والأب'], momTip: 'اشركي زوجك — ليتحدث مع الجنين أيضًا'),
  29: _FetusWeekData(emoji: '🎃', fruitName: 'قرع صغير', length: '38.6 سم', weight: '1.15 كغ', bgColor: Color(0xFFFF9800),
    developments: ['العظام تمتص الكالسيوم بكثافة', 'الجنين يركل بقوة', 'الدهون البيضاء تتراكم'], momTip: 'تناولي الأطعمة الغنية بالكالسيوم والأوميغا 3'),
  31: _FetusWeekData(emoji: '🥥', fruitName: 'جوز هند كبير', length: '41.1 سم', weight: '1.5 كغ', bgColor: Color(0xFF795548),
    developments: ['الجنين يدور ويتقلب', 'جميع الحواس تعمل', 'القزحية تستجيب للضوء'], momTip: 'ارفعي قدميك لتخفيف التورم'),
  33: _FetusWeekData(emoji: '🍍', fruitName: 'أناناس', length: '43.7 سم', weight: '1.9 كغ', bgColor: Color(0xFFFFC107),
    developments: ['المناعة تُبنى من الأم', 'العظام تصلبت أكثر', 'الجنين يحلم!'], momTip: 'استمتعي بهذه اللحظات — الولادة قريبة'),
  35: _FetusWeekData(emoji: '🍈', fruitName: 'شمام صغير', length: '46.2 سم', weight: '2.4 كغ', bgColor: Color(0xFF8BC34A),
    developments: ['الكلى مكتملة', 'الكبد يعالج الفضلات', 'معظم الأعضاء جاهزة'], momTip: 'جهّزي خطة الولادة مع طبيبتك'),
  37: _FetusWeekData(emoji: '🥬', fruitName: 'سلق سويسري', length: '48.6 سم', weight: '2.9 كغ', bgColor: Color(0xFF4CAF50),
    developments: ['الجنين مكتمل النمو رسميًا', 'الرئتان جاهزتان', 'يكتسب 30 غ يوميًا'], momTip: 'الجنين مكتمل — الولادة آمنة من الآن'),
  39: _FetusWeekData(emoji: '🍉', fruitName: 'بطيخة', length: '50.7 سم', weight: '3.2 كغ', bgColor: Color(0xFF4CAF50),
    developments: ['طبقة الدهون مكتملة', 'الصدر يبرز قليلًا', 'مستعد للرضاعة'], momTip: 'كوني جاهزة — أي يوم قد يكون اليوم!'),
  41: _FetusWeekData(emoji: '🍉', fruitName: 'بطيخة كبيرة', length: '51.7 سم', weight: '3.6 كغ', bgColor: Color(0xFF388E3C),
    developments: ['الجنين ناضج تمامًا', 'الأظافر قد تكون طويلة', 'الطبيب قد يناقش التحريض'], momTip: 'تابعي مع طبيبتك — التحريض خيار آمن'),
};
