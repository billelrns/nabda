import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/pregnancy_week_articles.dart';
import '../trackers/health_trackers_screen.dart';


// ─── Fetus Image Helper ───
String _fetusImagePath(int week) {
  // Available PNG (cards): 6,7,9,10,12,13,15,16,18,19,21,22,24,25,27,29,30,31,32,33,34,36,37,39,40
  const pngWeeks = {6,7,9,10,12,13,15,16,18,19,21,22,24,25,27,29,30,31,32,33,34,36,37,39,40,41};
  // Available JPG (banners): 4,5,8,11,14,17,20,23,26,28,35,38
  const jpgWeeks = {4,5,8,11,14,17,20,23,26,28,35,38};

  if (pngWeeks.contains(week)) return 'assets/images/fetus/week_$week.png';
  if (jpgWeeks.contains(week)) return 'assets/images/fetus/week_$week.jpg';

  // For weeks without an exact image, find the nearest available
  int closest = 5;
  int minDiff = 100;
  for (final w in [...pngWeeks, ...jpgWeeks]) {
    final diff = (w - week).abs();
    if (diff < minDiff) {
      minDiff = diff;
      closest = w;
    }
  }
  return pngWeeks.contains(closest)
      ? 'assets/images/fetus/week_$closest.png'
      : 'assets/images/fetus/week_$closest.jpg';
}

// ─── Light Theme Colors ───
const Color _bgColor = Color(0xFFFFF5F7); // Very light pink background
const Color _cardColor = Colors.white;
const Color _teal = Color(0xFF00897B); // Primary teal
const Color _pink = Color(0xFFE91E63); // Accent pink
const Color _softPink = Color(0xFFFFE8EC); // Soft pink for badges/cards
const Color _lightTeal = Color(0xFFE0F2F1); // Light teal for badges
const Color _textPrimary = Color(0xFF2D2D3A); // Dark text
const Color _textSecondary = Color(0xFF6B7280); // Grey text
const Color _divider = Color(0xFFEEEEEE);

// ─── Pregnancy Articles Data ───
class _PregnancyArticle {
  final String title;
  final String subtitle;
  final String category;
  final String emoji;
  final Color color;
  final Color bgColor;
  final String content;

  const _PregnancyArticle({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.emoji,
    required this.color,
    required this.bgColor,
    required this.content,
  });
}

final List<_PregnancyArticle> _pregnancyArticles = [
  _PregnancyArticle(
    title: 'التغذية السليمة أثناء الحمل',
    subtitle: 'دليلك الشامل للأكل الصحي',
    category: 'التغذية',
    emoji: '🥗',
    color: const Color(0xFF43A047),
    bgColor: const Color(0xFFE8F5E9),
    content: 'التغذية السليمة خلال فترة الحمل ضرورية لصحة الأم والجنين. يجب التركيز على تناول البروتينات من مصادر متنوعة كاللحوم البيضاء والبقوليات، والحصول على الكالسيوم من منتجات الألبان والخضراوات الورقية الداكنة. تناولي الأطعمة الغنية بحمض الفوليك مثل السبانخ والعدس والأفوكادو خاصة في الثلث الأول. اشربي ما لا يقل عن 8 أكواب ماء يومياً، وتجنبي الأطعمة النيئة والأسماك عالية الزئبق والكافيين الزائد. قسّمي وجباتك إلى 5-6 وجبات صغيرة لتجنب الغثيان والحموضة.',
  ),
  _PregnancyArticle(
    title: 'تمارين رياضية آمنة للحامل',
    subtitle: 'حافظي على لياقتك بأمان',
    category: 'الرياضة',
    emoji: '🧘‍♀️',
    color: const Color(0xFF5C6BC0),
    bgColor: const Color(0xFFE8EAF6),
    content: 'ممارسة الرياضة أثناء الحمل تساعد على تخفيف آلام الظهر وتحسين المزاج والنوم. من أفضل التمارين: المشي اليومي لمدة 30 دقيقة، السباحة التي تخفف الضغط على المفاصل، تمارين اليوغا للحوامل التي تقوي عضلات الحوض، وتمارين كيجل لتقوية عضلات قاع الحوض استعداداً للولادة. تجنبي التمارين العنيفة والرياضات التي تتضمن خطر السقوط. استشيري طبيبتك قبل البدء بأي برنامج رياضي، وتوقفي فوراً عند الشعور بدوخة أو ألم أو نزيف.',
  ),
  _PregnancyArticle(
    title: 'الصحة النفسية أثناء الحمل',
    subtitle: 'اعتني بمشاعرك وصحتك النفسية',
    category: 'الصحة النفسية',
    emoji: '💆‍♀️',
    color: const Color(0xFF7E57C2),
    bgColor: const Color(0xFFF3E5F5),
    content: 'التقلبات المزاجية أثناء الحمل طبيعية بسبب التغيرات الهرمونية. من المهم التحدث عن مشاعرك مع شريكك أو صديقة مقربة. مارسي تقنيات الاسترخاء مثل التنفس العميق والتأمل. خصصي وقتاً يومياً لنفسك للقراءة أو الاستماع للموسيقى الهادئة. النوم الكافي (7-9 ساعات) يحسن المزاج بشكل كبير. إذا شعرتِ بحزن مستمر أو قلق شديد لأكثر من أسبوعين، لا تترددي في استشارة متخصص. تذكري أن طلب المساعدة علامة قوة وليس ضعف.',
  ),
  _PregnancyArticle(
    title: 'تحضيرات ما قبل الولادة',
    subtitle: 'كل ما تحتاجين معرفته',
    category: 'الولادة',
    emoji: '🏥',
    color: _pink,
    bgColor: _softPink,
    content: 'ابدأي بتحضير حقيبة المستشفى من الأسبوع 36. تحتاجين: ملابس مريحة لك وللمولود، مستلزمات النظافة الشخصية، أوراقك الطبية ونتائج الفحوصات. اختاري مستشفى الولادة مسبقاً وتعرفي على طاقم التمريض. حضري خطة ولادة تتضمن تفضيلاتك (طبيعية أو قيصرية، التخدير). تعلمي تقنيات التنفس للمخاض. جهزي غرفة الطفل وحضري الأساسيات: سرير، حفاضات، ملابس قطنية. رتبي إجازة الأمومة وأبلغي جهة عملك.',
  ),
  _PregnancyArticle(
    title: 'نوم الحامل: نصائح ذهبية',
    subtitle: 'كيف تنامين بشكل مريح',
    category: 'النوم',
    emoji: '😴',
    color: const Color(0xFF0097A7),
    bgColor: const Color(0xFFE0F7FA),
    content: 'النوم على الجانب الأيسر هو الأفضل أثناء الحمل لأنه يحسن تدفق الدم للجنين والكلى. استخدمي وسادة بين الركبتين لتخفيف ضغط الظهر، ووسادة تحت البطن للدعم. تجنبي الأكل الثقيل قبل النوم بساعتين. قللي من شرب السوائل مساءً لتقليل زيارات الحمام الليلية. حافظي على درجة حرارة الغرفة معتدلة. إذا كنتِ تعانين من حرقة المعدة، ارفعي رأسك بوسادة إضافية. تجنبي النوم على الظهر بعد الأسبوع 20 لتفادي الضغط على الأوعية الدموية.',
  ),
  _PregnancyArticle(
    title: 'العناية بالبشرة أثناء الحمل',
    subtitle: 'حافظي على إشراقتك',
    category: 'الجمال',
    emoji: '✨',
    color: const Color(0xFFEF6C00),
    bgColor: const Color(0xFFFFF3E0),
    content: 'التغيرات الهرمونية تؤثر على البشرة أثناء الحمل. لتجنب الكلف وتصبغات الحمل، استخدمي واقي شمس SPF 50 يومياً. رطبي بشرتك بزيت اللوز أو زبدة الشيا لمنع علامات التمدد خاصة على البطن والصدر والأرداف. استخدمي منظفاً لطيفاً خالياً من العطور. تجنبي منتجات الريتينول والساليسيليك أسيد. اشربي الكثير من الماء وتناولي أطعمة غنية بفيتامين C وE. إذا ظهر حب شباب الحمل، استشيري طبيبة جلدية لمنتجات آمنة.',
  ),
  _PregnancyArticle(
    title: 'الرضاعة الطبيعية: استعدي مبكراً',
    subtitle: 'فوائدها وكيفية التحضير',
    category: 'الرضاعة',
    emoji: '🤱',
    color: _teal,
    bgColor: _lightTeal,
    content: 'الرضاعة الطبيعية هي أفضل غذاء لطفلك. ابدأي التحضير من الثلث الثالث بقراءة كتب متخصصة وحضور دورات الرضاعة. حليب الأم يحتوي على أجسام مضادة تحمي الطفل من الأمراض ويتكيف مع احتياجاته. الرضاعة الأولى (اللبأ) مهمة جداً خلال الساعة الأولى بعد الولادة. تأكدي أن وضعية الرضاعة صحيحة لتجنب تشقق الحلمات. أرضعي طفلك عند الطلب (8-12 مرة يومياً). اشربي كمية كافية من الماء وتناولي 500 سعرة حرارية إضافية يومياً.',
  ),
  _PregnancyArticle(
    title: 'فحوصات الحمل المهمة',
    subtitle: 'جدول الفحوصات الدورية',
    category: 'الفحوصات',
    emoji: '🔬',
    color: const Color(0xFFC62828),
    bgColor: const Color(0xFFFFEBEE),
    content: 'الثلث الأول: فحص الدم الشامل، فصيلة الدم، السكر، الغدة الدرقية، الأشعة التلفزيونية للتأكد من نبض الجنين والحمل السليم. الثلث الثاني: فحص السونار التفصيلي (أسبوع 18-22) للكشف عن تشوهات، فحص سكر الحمل (أسبوع 24-28). الثلث الثالث: متابعة نمو الجنين كل أسبوعين ثم أسبوعياً، فحص البكتيريا العقدية (أسبوع 35-37)، مراقبة ضغط الدم للكشف عن تسمم الحمل. لا تفوتي أي موعد متابعة مع طبيبتك.',
  ),
];

// Fruit data mapping for all 40 weeks
const Map<int, List<String>> _fruitData = {
  1: ['🌱', 'بذرة خشخاش'],
  2: ['🫐', 'حبة توت'],
  3: ['🍚', 'حبة أرز'],
  4: ['🌰', 'بندق صغير'],
  5: ['🍎', 'بذرة التفاح'],
  6: ['🥒', 'عدس'],
  7: ['🫒', 'حمص'],
  8: ['🍓', 'فراولة صغيرة'],
  9: ['🍇', 'حبة العنب'],
  10: ['🍑', 'خوخ صغير'],
  11: ['🍋', 'ليمونة صغيرة'],
  12: ['🥝', 'كيوي'],
  13: ['🍑', 'خوخ متوسط'],
  14: ['🫐', 'توت أزرق'],
  15: ['🥬', 'تفاحة صغيرة'],
  16: ['🍊', 'برتقالة صغيرة'],
  17: ['🍌', 'موزة صغيرة'],
  18: ['🍒', 'كيسان فلفل'],
  19: ['🥒', 'خيار صغير'],
  20: ['🍌', 'موزة'],
  21: ['🍕', 'ذرة'],
  22: ['🥕', 'جزرة'],
  23: ['🥒', 'خيار متوسط'],
  24: ['🌽', 'ذرة كاملة'],
  25: ['🥬', 'كرة ملفوف'],
  26: ['🥦', 'برنامج'],
  27: ['🍆', 'باذنجان'],
  28: ['🥔', 'حبة بطاطا'],
  29: ['🥬', 'رأس ملفوف'],
  30: ['🍉', 'شمام'],
  31: ['🍈', 'كنتالوب'],
  32: ['🍍', 'أناناس'],
  33: ['🥝', 'جوز الهند'],
  34: ['🍐', 'كمثرى'],
  35: ['🍎', 'تفاح أحمر'],
  36: ['🧅', 'بصلة'],
  37: ['🥬', 'رومaine'],
  38: ['🍯', 'عسل'],
  39: ['🎃', 'يقطين صغير'],
  40: ['🎃', 'يقطين'],
  41: ['🎃', 'يقطين كبير'],
};

// Trimester-specific medical checklist items
const Map<int, List<List<String>>> _trimesterChecklist = {
  1: [
    ['تناول حمض الفوليك 400 ميكروغرام يومياً', 'folic_acid'],
    ['زيارة طبيب النساء وتسجيل الحمل', 'obgyn_register'],
    ['إجراء اختبارات الدم الأولية', 'blood_test'],
    ['قياس ضغط الدم', 'blood_pressure'],
    ['الفحص الموجات الصوتية الأولى (الثلاثي)', 'ultrasound_1'],
  ],
  2: [
    ['الفحص الموجات الصوتية التفصيلي', 'ultrasound_detailed'],
    ['اختبار تحمل الجلوكوز (screening)', 'glucose_screening'],
    ['فحص الأجسام المضادة', 'antibody_test'],
    ['معالجة أي مشاكل صحية', 'health_issues'],
    ['ممارسة تمارين آمنة للحمل', 'safe_exercises'],
  ],
  3: [
    ['المزيد من اختبارات الموجات الصوتية', 'ultrasound_final'],
    ['فحص انخفاض المشيمة', 'placenta_check'],
    ['قياس كمية السائل الأمنيوسي', 'amniotic_fluid'],
    ['اختبار المجموعة الدموية والعامل الريسوسي', 'blood_group'],
    ['إجراء اختبار المكورات العقدية B', 'strep_b_test'],
  ],
};

class PregnancyWeeksScreen extends StatelessWidget {
  final int? currentWeek;
  final int? daysLeft;
  final double? percent;
  const PregnancyWeeksScreen({Key? key, this.currentWeek, this.daysLeft, this.percent}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (currentWeek != null && currentWeek! >= 1) {
      final week = currentWeek!.clamp(1, 40);
      final article = pregnancyWeekArticles.firstWhere((a) => a.week == week, orElse: () => pregnancyWeekArticles.last);
      return WeekDetailScreen(article: article, currentWeek: currentWeek, daysLeft: daysLeft, percent: percent);
    }
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bgColor,
        appBar: AppBar(
          title: const Text(
            'دليل الحمل أسبوعياً',
            style: TextStyle(fontWeight: FontWeight.bold, color: _textPrimary),
          ),
          backgroundColor: Colors.white,
          foregroundColor: _teal,
          elevation: 0,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: _divider),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: List.generate(3, (ti) {
            final name = ['الثلث الأول', 'الثلث الثاني', 'الثلث الثالث'][ti];
            final weeks = [
              pregnancyWeekArticles.where((a) => a.week <= 12).toList(),
              pregnancyWeekArticles.where((a) => a.week > 12 && a.week <= 27).toList(),
              pregnancyWeekArticles.where((a) => a.week > 27).toList(),
            ][ti];
            final color = [_teal, _pink, const Color(0xFF7E57C2)][ti];
            final bgGradient = [_lightTeal, _softPink, const Color(0xFFF3E5F5)][ti];
            final range = ['1 - 12', '13 - 27', '28 - 40'][ti];
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: color.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon([Icons.spa, Icons.child_friendly, Icons.favorite][ti], color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('الأسبوع $range', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
                    ]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${weeks.length} أسبوع',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ]),
              ),
              ...weeks.map((a) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WeekDetailScreen(article: a))),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: bgGradient,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Image.asset(
                              _fetusImagePath(a.week),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => CustomPaint(painter: RealisticFetusIllustration(week: a.week, isSmall: true, isOnDark: false)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(
                              'الأسبوع ${a.week}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${a.babySizeAr} (${a.babyLength})',
                              style: const TextStyle(color: _textSecondary, fontSize: 12),
                            ),
                          ]),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: bgGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.arrow_back_ios, size: 14, color: color),
                        ),
                      ]),
                    ),
                  ),
                ),
              )),
              const SizedBox(height: 12),
            ]);
          }),
        ),
      ),
    );
  }
}

class WeekDetailScreen extends StatefulWidget {
  final PregnancyWeekArticle article;
  final int? currentWeek;
  final int? daysLeft;
  final double? percent;
  const WeekDetailScreen({Key? key, required this.article, this.currentWeek, this.daysLeft, this.percent}) : super(key: key);
  @override
  State<WeekDetailScreen> createState() => _WeekDetailScreenState();
}

class _WeekDetailScreenState extends State<WeekDetailScreen> {
  Uint8List? _echoImage;
  bool _loadingEcho = true;
  int _kickCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedEcho();
  }

  Future<void> _loadSavedEcho() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loadingEcho = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('echo_images')
          .doc('week_${widget.article.week}')
          .get();
      if (doc.exists && doc.data()?['imageBase64'] != null) {
        setState(() {
          _echoImage = base64Decode(doc.data()!['imageBase64']);
          _loadingEcho = false;
        });
      } else {
        setState(() => _loadingEcho = false);
      }
    } catch (_) {
      setState(() => _loadingEcho = false);
    }
  }

  Future<void> _pickEchoImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 72, maxWidth: 1024);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (bytes.length > 500 * 1024) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الصورة كبيرة جداً')));
      return;
    }
    setState(() => _echoImage = bytes);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('echo_images')
          .doc('week_${widget.article.week}')
          .set({
        'imageBase64': base64Encode(bytes),
        'week': widget.article.week,
        'updatedAt': FieldValue.serverTimestamp()
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم حفظ صورة الإيكو بنجاح'),
            backgroundColor: _teal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Color get _trimesterColor {
    final w = widget.article.week;
    if (w <= 12) return _teal;
    if (w <= 27) return _pink;
    return const Color(0xFF7E57C2);
  }

  Color get _trimesterBg {
    final w = widget.article.week;
    if (w <= 12) return _lightTeal;
    if (w <= 27) return _softPink;
    return const Color(0xFFF3E5F5);
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.article;
    final color = _trimesterColor;
    final trimester = a.week <= 12 ? 1 : a.week <= 27 ? 2 : 3;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bgColor,
        body: CustomScrollView(
          slivers: [
            // ─── Header with fetus illustration ───
            SliverAppBar(
              expandedHeight: 380,
              pinned: true,
              backgroundColor: Colors.white,
              foregroundColor: _teal,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: widget.currentWeek == null,
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.list_alt, size: 20),
                  ),
                  tooltip: 'جميع الأسابيع',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PregnancyWeeksScreen()),
                  ),
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.date_range, size: 20),
                  ),
                  tooltip: 'تغيير تاريخ الحمل',
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().subtract(const Duration(days: 140)),
                      firstDate: DateTime.now().subtract(const Duration(days: 280)),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(primary: _teal, secondary: _pink),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (date != null) {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
                          {'pregnancyStartDate': Timestamp.fromDate(date)},
                          SetOptions(merge: true),
                        );
                      }
                    }
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'الأسبوع ${a.week}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: _textPrimary, fontSize: 16),
                ),
                centerTitle: true,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _softPink.withOpacity(0.6),
                        _lightTeal.withOpacity(0.3),
                        Colors.white,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 50),
                      // ── Circular progress ring with fetus ──
                      SizedBox(
                        width: 190,
                        height: 190,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Background ring
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: _divider, width: 2),
                              ),
                            ),
                            // Progress ring
                            SizedBox(
                              width: 190,
                              height: 190,
                              child: CustomPaint(
                                painter: _ProgressRingPainter(
                                  progress: (a.week / 40).clamp(0.0, 1.0),
                                  color: _pink,
                                  bgColor: _softPink,
                                ),
                              ),
                            ),
                            // Fetus illustration
                            Container(
                              width: 145,
                              height: 145,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(color: _pink.withOpacity(0.08), blurRadius: 20, spreadRadius: 5),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  _fetusImagePath(a.week),
                                  fit: BoxFit.cover,
                                  width: 145,
                                  height: 145,
                                  errorBuilder: (_, __, ___) => CustomPaint(painter: RealisticFetusIllustration(week: a.week, isOnDark: false)),
                                ),
                              ),
                            ),
                            // Week badge
                            Positioned(
                              bottom: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _teal,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(color: _teal.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2)),
                                  ],
                                ),
                                child: Text(
                                  'الأسبوع ${a.week}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Fruit comparison
                      if (_fruitData[a.week] != null) ...[
                        Text(
                          _fruitData[a.week]![0],
                          style: const TextStyle(fontSize: 30),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'بحجم ${_fruitData[a.week]![1]}',
                          style: const TextStyle(
                            color: _textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _trimesterBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            a.getTrimesterAr(),
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // ─── Content ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Progress card (if current week)
                    if (widget.currentWeek != null) ...[
                      _buildProgressCard(color),
                      const SizedBox(height: 16),
                    ],

                    // ── Quick info row ──
                    _buildQuickInfoRow(a),
                    const SizedBox(height: 16),

                    // ── Articles Carousel ──
                    _buildArticlesCarousel(),
                    const SizedBox(height: 16),

                    // Baby size card
                    _buildArticleCard(
                      '🍎 حجم الجنين',
                      'عن البيبي',
                      _teal,
                      _lightTeal,
                      child: Column(
                        children: [
                          _buildSizeRow('مثل', a.babySizeAr, Icons.circle),
                          const Divider(height: 20, color: _divider),
                          _buildSizeRow('الطول', a.babyLength, Icons.height),
                          const Divider(height: 20, color: _divider),
                          _buildSizeRow('الوزن', a.babyWeight, Icons.monitor_weight_outlined),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Echo card
                    _buildEchoCard(color),
                    const SizedBox(height: 14),

                    // Fetal development card
                    _buildArticleCard(
                      '👶 تطور الجنين',
                      'عن البيبي',
                      _teal,
                      _lightTeal,
                      child: Text(
                        a.fetalDevAr,
                        style: const TextStyle(fontSize: 14, height: 1.8, color: _textSecondary),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Mother symptoms card
                    _buildArticleCard(
                      '❤️ أعراض الأم',
                      'عن الأم',
                      _pink,
                      _softPink,
                      child: Text(
                        a.symptomsAr,
                        style: const TextStyle(fontSize: 14, height: 1.8, color: _textSecondary),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Nutrition card
                    _buildArticleCard(
                      '🥗 التغذية',
                      'التغذية',
                      const Color(0xFF43A047),
                      const Color(0xFFE8F5E9),
                      child: Text(
                        a.nutritionAr,
                        style: const TextStyle(fontSize: 14, height: 1.8, color: _textSecondary),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Tips card
                    _buildArticleCard(
                      '💡 نصائح',
                      'نصائح نفسية',
                      const Color(0xFF5C6BC0),
                      const Color(0xFFE8EAF6),
                      child: Text(
                        a.tipsAr,
                        style: const TextStyle(fontSize: 14, height: 1.8, color: _textSecondary),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Medical checklist
                    if (widget.currentWeek != null) ...[
                      _buildMedicalChecklist(trimester, color),
                      const SizedBox(height: 14),
                      // Kick counter
                      _buildKickCounter(color),
                      const SizedBox(height: 14),
                    ],

                    // ── Discover Section Header ──
                    const SizedBox(height: 24),
                    // ─── Health Trackers Banner ───
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthTrackersScreen())),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [const Color(0xFF5C6BC0).withOpacity(0.1), _teal.withOpacity(0.08)],
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5C6BC0).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.monitor_heart, color: Color(0xFF5C6BC0), size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("العدادات الصحية 📊", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D2D3A))),
                                  SizedBox(height: 2),
                                  Text("تتبعي الوزن والضغط والانقباضات وشرب الماء", style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_back_ios, size: 16, color: Color(0xFF6B7280)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_pink.withOpacity(0.08), _teal.withOpacity(0.06)],
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _pink.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.explore, color: _pink, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('اكتشفي المزيد 💡', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textPrimary)),
                                SizedBox(height: 2),
                                Text('مقالات ونصائح في مختلف المجالات', style: TextStyle(fontSize: 13, color: _textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Featured Articles Section (hardcoded) ──
                    ..._buildFeaturedArticles(context),

                    // ── All Discover Sections ──
                    ..._buildAllDiscoverSections(),

                    // Navigation buttons
                    Row(
                      children: [
                        if (a.week > 1)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                final p = pregnancyWeekArticles.firstWhere((x) => x.week == a.week - 1);
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => WeekDetailScreen(
                                      article: p,
                                      currentWeek: widget.currentWeek,
                                      daysLeft: widget.daysLeft,
                                      percent: widget.percent,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.arrow_forward),
                              label: Text('الأسبوع ${a.week - 1}'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: color,
                                side: BorderSide(color: color.withOpacity(0.3)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        if (a.week > 1 && a.week < 40) const SizedBox(width: 12),
                        if (a.week < 40)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final n = pregnancyWeekArticles.firstWhere((x) => x.week == a.week + 1);
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => WeekDetailScreen(
                                      article: n,
                                      currentWeek: widget.currentWeek,
                                      daysLeft: widget.daysLeft,
                                      percent: widget.percent,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.arrow_back),
                              label: Text('الأسبوع ${a.week + 1}'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: color,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                      ],
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

  // ── Quick info chips ──
  Widget _buildQuickInfoRow(PregnancyWeekArticle a) {
    return Row(
      children: [
        Expanded(child: _infoChip('📏', 'الطول', a.babyLength, _lightTeal, _teal)),
        const SizedBox(width: 10),
        Expanded(child: _infoChip('⚖️', 'الوزن', a.babyWeight, _softPink, _pink)),
        const SizedBox(width: 10),
        Expanded(child: _infoChip(_fruitData[a.week]?[0] ?? '🍎', 'بحجم', _fruitData[a.week]?[1] ?? '', const Color(0xFFFFF3E0), const Color(0xFFE65100))),
      ],
    );
  }

  Widget _infoChip(String emoji, String label, String value, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Articles Carousel ──
  Widget _buildArticlesCarousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _pink,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'مقالات مفيدة لكِ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const _AllArticlesScreen()),
                  );
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('عرض الكل', style: TextStyle(color: _teal, fontSize: 13, fontWeight: FontWeight.w600)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_back_ios, size: 12, color: _teal),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Carousel
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            reverse: true, // RTL
            itemCount: _pregnancyArticles.length,
            itemBuilder: (context, index) {
              final article = _pregnancyArticles[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _ArticleDetailScreen(article: article),
                    ),
                  );
                },
                child: Container(
                  width: 240,
                  margin: EdgeInsets.only(left: index == _pregnancyArticles.length - 1 ? 0 : 12),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top colored section
                      Container(
                        width: double.infinity,
                        height: 90,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [article.bgColor, article.bgColor.withOpacity(0.5)],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(18),
                            topLeft: Radius.circular(18),
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Background emoji
                            Positioned(
                              left: 10,
                              bottom: 5,
                              child: Text(
                                article.emoji,
                                style: TextStyle(fontSize: 50, color: Colors.white.withOpacity(0.3)),
                              ),
                            ),
                            // Category badge
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  article.category,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: article.color,
                                  ),
                                ),
                              ),
                            ),
                            // Main emoji
                            Positioned(
                              right: 12,
                              bottom: 10,
                              child: Text(article.emoji, style: const TextStyle(fontSize: 36)),
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
                                article.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                article.subtitle,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  Icon(Icons.access_time, size: 12, color: _textSecondary.withOpacity(0.6)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '3 دقائق قراءة',
                                    style: TextStyle(fontSize: 10, color: _textSecondary.withOpacity(0.6)),
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
    );
  }

  // ── All Discover Sections embedded in page ──
  void _showFirestoreArticle(BuildContext context, Map<String, dynamic> d) {
    final hasImg = d['imageUrl'] != null && (d['imageUrl'] as String).isNotEmpty;
    final contentImages = (d['contentImages'] as List<dynamic>?) ?? [];
    Navigator.push(context, MaterialPageRoute(builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(d['category'] ?? '', style: const TextStyle(color: _textPrimary, fontSize: 16)),
          backgroundColor: Colors.white, foregroundColor: _teal, elevation: 0, surfaceTintColor: Colors.transparent),
        body: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (hasImg)
            Image.network(d['imageUrl'], width: double.infinity, height: 220, fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return SizedBox(height: 220, child: Center(child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes! : null,
                  color: _teal)));
              },
              errorBuilder: (_, error, ___) {
                debugPrint('Article header image error: $error');
                return Container(height: 120, color: _teal.withOpacity(0.05),
                  child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.image_not_supported_outlined, size: 40, color: _teal.withOpacity(0.3)),
                    const SizedBox(height: 8),
                    Text('تعذّر تحميل الصورة', style: TextStyle(fontSize: 12, color: _textSecondary)),
                  ])));
              }),
          Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d['title'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _textPrimary, height: 1.4)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: _teal.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(d['category'] ?? '', style: TextStyle(fontSize: 12, color: _teal, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
            Text(d['content'] ?? '', style: TextStyle(fontSize: 16, color: _textSecondary, height: 1.8)),
            if (contentImages.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...contentImages.map((url) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(borderRadius: BorderRadius.circular(12),
                  child: Image.network(url.toString(), width: double.infinity, fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return SizedBox(height: 150, child: Center(child: CircularProgressIndicator(color: _teal)));
                    },
                    errorBuilder: (_, error, ___) {
                      debugPrint('Article content image error: $error');
                      return const SizedBox.shrink();
                    })))),
            ],
          ])),
        ])),
      ),
    )));
  }

  List<Widget> _buildFeaturedArticles(BuildContext context) {
    final featured = <Map<String, dynamic>>[
      {'title': 'التغيرات في جسمك أسبوعياً', 'category': 'أسبوع بأسبوع', 'image': 'https://images.unsplash.com/photo-1493894473891-10fc1e5dbd22?w=400&q=80'},
      {'title': 'الأطعمة المفيدة للحامل', 'category': 'التغذية', 'image': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400&q=80'},
      {'title': 'المشي أثناء الحمل', 'category': 'الرياضة', 'image': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&q=80'},
      {'title': 'تحضير حقيبة المولود', 'category': 'التحضير للولادة', 'image': 'https://images.unsplash.com/photo-1522771930-78848d9293e8?w=400&q=80'},
      {'title': 'القلق من الولادة', 'category': 'الصحة النفسية', 'image': 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=400&q=80'},
      {'title': 'دور الأب أثناء الحمل', 'category': 'العلاقة الزوجية', 'image': 'https://images.unsplash.com/photo-1531983412531-1f49a365ffed?w=400&q=80'},
      {'title': 'فحوصات الثلث الأول', 'category': 'الفحوصات', 'image': 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=400&q=80'},
      {'title': 'العناية بالبشرة', 'category': 'الجمال والعناية', 'image': 'https://images.unsplash.com/photo-1556228578-0d85b1a4d571?w=400&q=80'},
    ];

    return [
      const SizedBox(height: 20),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Container(width: 4, height: 22, decoration: BoxDecoration(color: _teal, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          const Text('\u{1F4F0}', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 6),
          const Text('مقالات جديدة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textPrimary)),
        ]),
      ),
      const SizedBox(height: 10),
      SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: featured.length,
          itemBuilder: (_, i) {
            final item = featured[i];
            return GestureDetector(
              onTap: () {
                // Find matching article in discover categories
                for (final cat in _discoverCategories) {
                  for (final art in cat.articles) {
                    if (art.title == item['title']) {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => _DiscoverDetailScreen(article: art, categoryName: cat.name),
                      ));
                      return;
                    }
                  }
                }
              },
              child: Container(
                width: 160, margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(item['image']!, width: 160, height: 100, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(height: 100, color: _teal.withOpacity(0.08),
                        child: const Center(child: Icon(Icons.article, size: 40, color: _teal)))),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item['title']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textPrimary),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: _teal.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(item['category']!, style: TextStyle(fontSize: 9, color: _teal, fontWeight: FontWeight.bold)),
                      ),
                    ]),
                  ),
                ]),
              ),
            );
          },
        ),
      ),
    ];
  }

  List<Widget> _buildAllDiscoverSections() {
    return _discoverCategories.map((cat) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Section title
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(color: _pink, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 8),
              Text(cat.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  cat.name,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: _textPrimary),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => _CategoryArticlesScreen(category: cat),
                  ));
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('عرض الكل', style: TextStyle(color: _teal, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_back_ios, size: 12, color: _teal),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Horizontal carousel
          SizedBox(
            height: 195,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              reverse: true,
              itemCount: cat.articles.length,
              itemBuilder: (context, i) {
                final art = cat.articles[i];
                final isFirst = i == 0;
                return GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => _DiscoverDetailScreen(article: art, categoryName: cat.name),
                    ));
                  },
                  child: Container(
                    width: isFirst ? 270 : 195,
                    margin: EdgeInsets.only(left: i == cat.articles.length - 1 ? 0 : 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [art.color1.withOpacity(0.15), art.color1.withOpacity(0.04)],
                      ),
                      boxShadow: [
                        BoxShadow(color: art.color1.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Background emoji
                        Positioned(
                          left: -10,
                          bottom: -10,
                          child: Text(art.emoji, style: TextStyle(fontSize: isFirst ? 90 : 65, color: art.color1.withOpacity(0.07))),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: art.color1.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.article_outlined, size: 13, color: art.color1),
                                    const SizedBox(width: 3),
                                    Text('مقال', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: art.color1)),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Text(art.emoji, style: const TextStyle(fontSize: 32)),
                              const SizedBox(height: 6),
                              Text(
                                art.title,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textPrimary, height: 1.3),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
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
      );
    }).toList();
  }

  Widget _buildProgressCard(Color color) {
    final w = widget.currentWeek ?? widget.article.week;
    final d = widget.daysLeft ?? max(0, (40 * 7) - (w * 7));
    final p = widget.percent ?? (w / 40).clamp(0.0, 1.0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_teal, _teal.withOpacity(0.85)],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: _teal.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الأسبوع $w',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$d يوم متبقي',
                    style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${(p * 100).toInt()}%',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: p,
              backgroundColor: Colors.white.withOpacity(0.25),
              color: Colors.white,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(
    String title,
    String category,
    Color accentColor,
    Color bgTint, {
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bgTint.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(18),
                topLeft: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Card body
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildSizeRow(String label, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _lightTeal,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: _teal),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: _textSecondary),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _textPrimary,
          ),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }

  Widget _buildEchoCard(Color c) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E5F5).withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(18),
                topLeft: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _pink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt, color: _pink, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'صورة الإيكو / السونار 3D',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _textPrimary),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _loadingEcho
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: _pink),
                    ),
                  )
                : _echoImage != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.memory(
                              _echoImage!,
                              width: double.infinity,
                              height: 220,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: GestureDetector(
                              onTap: _pickEchoImage,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.edit, color: _pink, size: 14),
                                    const SizedBox(width: 4),
                                    const Text('تغيير', style: TextStyle(color: _pink, fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : GestureDetector(
                        onTap: _pickEchoImage,
                        child: Container(
                          width: double.infinity,
                          height: 140,
                          decoration: BoxDecoration(
                            color: _softPink.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _pink.withOpacity(0.2), width: 1.5),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _pink.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.add_a_photo, size: 32, color: _pink.withOpacity(0.6)),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'أضيفي صورة الإيكو أو السونار 3D',
                                style: TextStyle(
                                  color: _pink.withOpacity(0.8),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalChecklist(int trimester, Color c) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    final mk = DateTime.now().toIso8601String().substring(0, 7);
    final items = _trimesterChecklist[trimester] ?? [];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _lightTeal.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(18),
                topLeft: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'أسئلة للطبيب',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _teal),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '📋 الفحوصات - الثلث ${['الأول', 'الثاني', 'الثالث'][trimester - 1]}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _teal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: items.map((item) {
                final did = '${mk}_${item[1]}';
                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('weekly_checklist')
                      .doc(did)
                      .snapshots(),
                  builder: (ctx, snap) {
                    bool done = snap.hasData &&
                        snap.data!.exists &&
                        ((snap.data!.data() as Map<String, dynamic>?)?['done'] ?? false);
                    return InkWell(
                      onTap: () => FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('weekly_checklist')
                          .doc(did)
                          .set({
                        'text': item[0],
                        'done': !done,
                        'key': item[1],
                        'updatedAt': FieldValue.serverTimestamp()
                      }),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: done ? _teal : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: done ? _teal : _textSecondary.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: done
                                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item[0],
                                style: TextStyle(
                                  fontSize: 14,
                                  decoration: done ? TextDecoration.lineThrough : null,
                                  color: done ? _textSecondary : _textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKickCounter(Color c) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _softPink.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(18),
                topLeft: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _pink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'مراقبة',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _pink),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    '👣 عداد حركات الجنين',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _pink),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _softPink.withOpacity(0.5),
                    border: Border.all(color: _pink.withOpacity(0.2), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '$_kickCount',
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: _pink),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'حركة',
                  style: TextStyle(color: _textSecondary, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _kickCount++),
                      icon: const Icon(Icons.touch_app),
                      label: const Text('ركلة!'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pink,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          final dk = DateTime.now().toIso8601String().substring(0, 10);
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .collection('kick_logs')
                              .doc(dk)
                              .set({
                            'count': _kickCount,
                            'date': dk,
                            'updatedAt': FieldValue.serverTimestamp()
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('تم حفظ $_kickCount حركة'),
                                backgroundColor: _teal,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        }
                        setState(() => _kickCount = 0);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _teal,
                        side: BorderSide(color: _teal.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('حفظ وإعادة'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Article Detail Screen ───
class _ArticleDetailScreen extends StatelessWidget {
  final _PregnancyArticle article;
  const _ArticleDetailScreen({Key? key, required this.article}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bgColor,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: Colors.white,
              foregroundColor: _teal,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  article.category,
                  style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                centerTitle: true,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [article.bgColor, article.bgColor.withOpacity(0.3), Colors.white],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 30),
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: article.color.withOpacity(0.15), blurRadius: 20, spreadRadius: 5),
                            ],
                          ),
                          child: Center(
                            child: Text(article.emoji, style: const TextStyle(fontSize: 45)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: article.bgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        article.category,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: article.color),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Title
                    Text(
                      article.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Subtitle
                    Text(
                      article.subtitle,
                      style: const TextStyle(fontSize: 15, color: _textSecondary),
                    ),
                    const SizedBox(height: 8),
                    // Meta info
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: _textSecondary.withOpacity(0.6)),
                        const SizedBox(width: 4),
                        Text('3 دقائق قراءة', style: TextStyle(fontSize: 12, color: _textSecondary.withOpacity(0.6))),
                        const SizedBox(width: 16),
                        Icon(Icons.favorite_border, size: 14, color: _textSecondary.withOpacity(0.6)),
                        const SizedBox(width: 4),
                        Text('مقال مفيد', style: TextStyle(fontSize: 12, color: _textSecondary.withOpacity(0.6))),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Divider
                    Container(height: 1, color: _divider),
                    const SizedBox(height: 20),
                    // Content
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Text(
                        article.content,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 2.0,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Tip box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _lightTeal,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _teal.withOpacity(0.15)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _teal.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.lightbulb_outline, color: _teal, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'نصيحة',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _teal),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'استشيري طبيبتك دائماً قبل اتخاذ أي قرارات صحية مهمة أثناء الحمل.',
                                  style: TextStyle(fontSize: 13, color: _textSecondary, height: 1.6),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

// ─── All Articles Screen ───
class _AllArticlesScreen extends StatelessWidget {
  const _AllArticlesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bgColor,
        appBar: AppBar(
          title: const Text(
            'مقالات الحمل',
            style: TextStyle(fontWeight: FontWeight.bold, color: _textPrimary),
          ),
          backgroundColor: Colors.white,
          foregroundColor: _teal,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: _divider),
          ),
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _pregnancyArticles.length,
          itemBuilder: (context, index) {
            final article = _pregnancyArticles[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _ArticleDetailScreen(article: article),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    // Image section
                    Container(
                      width: 100,
                      height: 110,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [article.bgColor, article.bgColor.withOpacity(0.5)],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(18),
                          bottomRight: Radius.circular(18),
                        ),
                      ),
                      child: Center(
                        child: Text(article.emoji, style: const TextStyle(fontSize: 40)),
                      ),
                    ),
                    // Text section
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: article.bgColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                article.category,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: article.color),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              article.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              article.subtitle,
                              style: const TextStyle(fontSize: 12, color: _textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Icon(Icons.arrow_back_ios, size: 14, color: _textSecondary.withOpacity(0.4)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Discover Data Models ───
class _DiscoverArt {
  final String title;
  final String emoji;
  final Color color1;
  final String content;
  const _DiscoverArt({required this.title, required this.emoji, required this.color1, required this.content});
}

class _DiscoverCat {
  final String name;
  final String emoji;
  final List<_DiscoverArt> articles;
  const _DiscoverCat({required this.name, required this.emoji, required this.articles});
}

final List<_DiscoverCat> _discoverCategories = [
  _DiscoverCat(name: 'التغذية والأطعمة', emoji: '🥗', articles: [
    _DiscoverArt(title: 'الأطعمة المفيدة للحامل', emoji: '🥑', color1: const Color(0xFF43A047),
      content: 'أهم الأطعمة: السلمون (أوميغا 3 لنمو دماغ الجنين)، البيض (بروتين وكولين)، البقوليات (حمض الفوليك والحديد)، البطاطا الحلوة (فيتامين A)، الخضراوات الورقية (كالسيوم وحديد)، التوت والفراولة (فيتامين C ومضادات أكسدة)، اللحوم الحمراء قليلة الدهن (حديد)، منتجات الألبان (كالسيوم وبروتين)، والمكسرات (دهون صحية وبروتين).'),
    _DiscoverArt(title: 'أطعمة يجب تجنبها', emoji: '⚠️', color1: const Color(0xFFE53935),
      content: 'تجنبي: اللحوم والأسماك النيئة (السوشي)، الأجبان الطرية غير المبسترة، البيض النيء، الأسماك عالية الزئبق (التونة الكبيرة)، الكبد بكميات كبيرة، الكافيين أكثر من 200 ملغ يومياً، الكحول نهائياً، والأطعمة غير المطهية جيداً. اغسلي الفواكه والخضراوات جيداً قبل الأكل.'),
    _DiscoverArt(title: 'المشروبات الصحية', emoji: '🥤', color1: const Color(0xFF00ACC1),
      content: 'الماء هو الأفضل - 8-10 أكواب يومياً. عصائر طبيعية بدون سكر، حليب قليل الدسم، شاي الزنجبيل (يخفف الغثيان)، ماء جوز الهند. قللي الشاي الأخضر والأسود لاحتوائهما على كافيين، وتجنبي المشروبات الغازية ومشروبات الطاقة.'),
    _DiscoverArt(title: 'الفيتامينات الضرورية', emoji: '💊', color1: const Color(0xFFFF8F00),
      content: 'حمض الفوليك (400 ميكروغرام يومياً) يمنع تشوهات الأنبوب العصبي. الحديد (27 ملغ) يمنع فقر الدم. الكالسيوم (1000 ملغ) لعظام الجنين. فيتامين D لامتصاص الكالسيوم. أوميغا 3 DHA لنمو الدماغ. استشيري طبيبتك قبل تناول أي مكملات.'),
  ]),
  _DiscoverCat(name: 'الجسم والتغيرات', emoji: '🩺', articles: [
    _DiscoverArt(title: 'آلام الظهر وكيفية التخفيف', emoji: '💆‍♀️', color1: const Color(0xFF5C6BC0),
      content: 'آلام الظهر شائعة بسبب الوزن الزائد. للتخفيف: حافظي على وضعية جلوس صحيحة، استخدمي وسادة داعمة، ارتدي أحذية مريحة مسطحة، نامي على جانبك مع وسادة بين الركبتين، مارسي تمارين إطالة خفيفة، جربي الكمادات الدافئة والسباحة.'),
    _DiscoverArt(title: 'الغثيان الصباحي', emoji: '🤢', color1: const Color(0xFF26A69A),
      content: 'يصيب 80% من الحوامل في الثلث الأول. للتخفيف: كلي بسكويت جاف قبل النهوض من السرير، قسّمي الوجبات لـ 5-6 وجبات صغيرة، تجنبي الأطعمة الدسمة والروائح القوية، جربي الزنجبيل. إذا كان شديداً ولا تستطيعين الأكل راجعي طبيبتك.'),
    _DiscoverArt(title: 'تورم القدمين والساقين', emoji: '🦶', color1: const Color(0xFF8E24AA),
      content: 'التورم طبيعي في النصف الثاني من الحمل. للتخفيف: ارفعي قدميك، تجنبي الوقوف طويلاً، ارتدي جوارب ضغط طبية، اشربي ماء أكثر، قللي الملح. إذا كان التورم مفاجئاً في الوجه واليدين مع صداع شديد اذهبي للطوارئ فوراً.'),
    _DiscoverArt(title: 'علامات التمدد والوقاية', emoji: '✨', color1: const Color(0xFFEC407A),
      content: 'تظهر عند 90% من الحوامل على البطن والصدر والأرداف. رطبي بشرتك يومياً بزيت اللوز أو زبدة الشيا، اشربي كمية كافية من الماء، تناولي فيتامين C وE، وحافظي على زيادة وزن تدريجية. العلامات تبهت بعد الولادة.'),
  ]),
  _DiscoverCat(name: 'التمارين والرياضة', emoji: '🧘‍♀️', articles: [
    _DiscoverArt(title: 'المشي أثناء الحمل', emoji: '🚶‍♀️', color1: const Color(0xFF66BB6A),
      content: 'المشي أفضل تمرين للحامل. ابدأي بـ 15 دقيقة وزيدي حتى 30 دقيقة يومياً. يحسن الدورة الدموية، يقلل التورم والإمساك، يحسن المزاج والنوم، ويقوي العضلات. ارتدي حذاء مريح واحملي ماء. توقفي عند الدوخة.'),
    _DiscoverArt(title: 'يوغا الحوامل', emoji: '🧘‍♀️', color1: const Color(0xFF7E57C2),
      content: 'تقوي عضلات الحوض، تخفف آلام الظهر، تحسن التوازن والمرونة، وتقلل التوتر. وضعيات آمنة: القطة والبقرة، الفراشة، المحارب المعدلة. تجنبي الاستلقاء على الظهر بعد الأسبوع 20 والالتواءات العميقة.'),
    _DiscoverArt(title: 'السباحة للحامل', emoji: '🏊‍♀️', color1: const Color(0xFF29B6F6),
      content: 'الماء يدعم وزنك ويخفف الضغط على المفاصل. تمرين كامل للجسم بدون إجهاد، تخفف تورم القدمين وتبرد الجسم. يمكنك السباحة طوال فترة الحمل. تجنبي الجاكوزي وحمامات البخار.'),
    _DiscoverArt(title: 'تمارين كيجل المهمة', emoji: '💪', color1: const Color(0xFFEF5350),
      content: 'تقوي عضلات قاع الحوض للولادة ومنع سلس البول. اقبضي عضلات الحوض 5 ثوان ثم استرخي 5 ثوان. كرري 10 مرات، 3 مجموعات يومياً. ابدأي من الثلث الأول واستمري بعد الولادة.'),
  ]),
  _DiscoverCat(name: 'الرضاعة والمولود', emoji: '🤱', articles: [
    _DiscoverArt(title: 'الرضاعة الطبيعية: البداية', emoji: '🤱', color1: const Color(0xFFE91E63),
      content: 'ابدأي خلال الساعة الأولى بعد الولادة. اللبأ غني بالأجسام المضادة. تأكدي أن فمه يغطي معظم الهالة. أرضعيه عند الطلب 8-12 مرة يومياً. الرضاعة الصحيحة لا تسبب ألماً. لا تترددي في طلب مساعدة استشارية رضاعة.'),
    _DiscoverArt(title: 'تحضير حقيبة المولود', emoji: '👶', color1: const Color(0xFF42A5F5),
      content: '6-8 بدلات قطنية، قبعات وجوارب، بطانيات، حفاضات حديثي الولادة، مناديل مبللة، كريم طفح الحفاض، حوض استحمام، شامبو لطيف، مقص أظافر، ميزان حرارة، وكرسي سيارة آمن. جهزي كل شيء من الأسبوع 34.'),
    _DiscoverArt(title: 'الرضاعة بالزجاجة', emoji: '🍼', color1: const Color(0xFF26C6DA),
      content: 'اختاري حليباً مناسباً لعمر طفلك. عقمي الزجاجات قبل كل استخدام. حضري الحليب بالماء المغلي المبرد. لا تسخني في الميكروويف. تأكدي من درجة الحرارة على معصمك. احملي طفلك بزاوية 45 درجة.'),
  ]),
  _DiscoverCat(name: 'النوم والراحة', emoji: '😴', articles: [
    _DiscoverArt(title: 'وضعيات النوم الآمنة', emoji: '🛏️', color1: const Color(0xFF5C6BC0),
      content: 'الجانب الأيسر هو الأفضل - يحسن تدفق الدم للجنين. ضعي وسادة بين ركبتيك. استخدمي وسادة الحمل U-shape. بعد الأسبوع 20 تجنبي النوم على الظهر. إذا استيقظتِ على ظهرك لا تقلقي، فقط انقلبي.'),
    _DiscoverArt(title: 'التغلب على الأرق', emoji: '🌙', color1: const Color(0xFF7E57C2),
      content: 'حافظي على روتين نوم ثابت، تجنبي الشاشات قبل النوم بساعة، خذي حماماً دافئاً، مارسي تنفس عميق، اشربي بابونج، تجنبي الأكل الثقيل قبل 3 ساعات، واجعلي الغرفة مظلمة وباردة.'),
    _DiscoverArt(title: 'التعب والإرهاق', emoji: '😮‍💨', color1: const Color(0xFF78909C),
      content: 'التعب طبيعي بسبب التغيرات الهرمونية. خذي قيلولة 20-30 دقيقة، كلي وجبات صغيرة متكررة، مارسي رياضة خفيفة، اقبلي المساعدة، وتأكدي من عدم نقص الحديد.'),
  ]),
  _DiscoverCat(name: 'الصحة النفسية', emoji: '🧠', articles: [
    _DiscoverArt(title: 'التقلبات المزاجية', emoji: '😊', color1: const Color(0xFFFFB300),
      content: 'طبيعية 100% بسبب الهرمونات. من الطبيعي أن تبكي بدون سبب أو تنزعجي من أشياء صغيرة. تحدثي عن مشاعرك، مارسي رياضة خفيفة، خصصي وقتاً لهوايتك، ونامي كفاية. هذا مؤقت وليس ضعفاً.'),
    _DiscoverArt(title: 'القلق من الولادة', emoji: '💭', color1: const Color(0xFF26A69A),
      content: 'طبيعي خاصة في الحمل الأول. تعلمي عن مراحل الولادة، احضري دورة تحضير، تعلمي تقنيات التنفس، تحدثي مع أمهات سابقات، ناقشي مخاوفك مع طبيبتك. جسمك مصمم لهذا وأنتِ أقوى مما تظنين.'),
    _DiscoverArt(title: 'الاسترخاء والتأمل', emoji: '🕊️', color1: const Color(0xFFAB47BC),
      content: 'خصصي 10 دقائق يومياً للتأمل والتنفس العميق. استمعي لموسيقى هادئة، جربي تمارين الاسترخاء التدريجي للعضلات، اكتبي يومياً عن مشاعرك. هذه التقنيات تساعد أيضاً أثناء المخاض.'),
  ]),
  _DiscoverCat(name: 'العمل والحمل', emoji: '💼', articles: [
    _DiscoverArt(title: 'متى تخبرين عملك؟', emoji: '📢', color1: const Color(0xFF42A5F5),
      content: 'معظم النساء ينتظرن حتى الأسبوع 12-13. أخبري مديرك أولاً في اجتماع خاص. حضري خطة لتغطية عملك. اعرفي حقوقك في إجازة الأمومة. إذا كان عملك يتضمن مخاطر أخبريهم مبكراً.'),
    _DiscoverArt(title: 'الراحة في المكتب', emoji: '🪑', color1: const Color(0xFF78909C),
      content: 'كرسي مريح مع دعم للظهر، قومي وتمشي كل 30 دقيقة، اشربي ماء كافي، احتفظي بوجبات خفيفة صحية، ارتدي ملابس مريحة، ارفعي الشاشة لمستوى العين.'),
    _DiscoverArt(title: 'إجازة الأمومة', emoji: '📋', color1: const Color(0xFFFF7043),
      content: 'وثقي مهامك لمن سيغطي عملك، درّبي زميلتك البديلة قبل شهر، نظمي ملفاتك، أبلغي العملاء المهمين. خططي: دوام كامل أم جزئي عند العودة؟ رتبي رعاية الطفل مسبقاً.'),
  ]),
  _DiscoverCat(name: 'العلاقات والأسرة', emoji: '👨‍👩‍👧', articles: [
    _DiscoverArt(title: 'دور الأب أثناء الحمل', emoji: '👨', color1: const Color(0xFF5C6BC0),
      content: 'حضور مواعيد الطبيبة، المساعدة في الأعمال المنزلية، تحضير وجبات صحية، تدليك الظهر والقدمين، التحدث مع الجنين (يسمع من الأسبوع 25)، تحضير غرفة الطفل معاً، والصبر والتفهم.'),
    _DiscoverArt(title: 'تحضير الأبناء للمولود', emoji: '👧', color1: const Color(0xFFEC407A),
      content: 'أخبريهم بعد الثلث الأول بطريقة تناسب عمرهم. اشركيهم في التحضيرات. اقرأي لهم كتب عن المولود الجديد. أكدي أن حبكم لن يتغير. بعد الولادة خصصي وقتاً لكل طفل.'),
    _DiscoverArt(title: 'العلاقة الزوجية والحمل', emoji: '❤️', color1: const Color(0xFFE91E63),
      content: 'تواصلوا بصراحة عن المشاعر. خططوا لمواعيد رومانسية. تقاسموا المسؤوليات. ناقشوا أسلوب التربية. العلاقة الحميمية آمنة في معظم الحالات. أنتم فريق واحد.'),
  ]),
  _DiscoverCat(name: 'الفحوصات الطبية', emoji: '🔬', articles: [
    _DiscoverArt(title: 'فحوصات الثلث الأول', emoji: '🩸', color1: const Color(0xFFE53935),
      content: 'أسبوع 6-8: سونار للتأكد من نبض القلب. أسبوع 8-10: تحاليل دم شاملة (فصيلة الدم، فقر الدم، السكر، الغدة الدرقية). أسبوع 11-13: فحص الشفافية القفوية للكشف عن متلازمة داون.'),
    _DiscoverArt(title: 'فحص السونار التفصيلي', emoji: '📺', color1: const Color(0xFF7E57C2),
      content: 'أسبوع 18-22: يفحص الدماغ، العمود الفقري، القلب، الكلى، الأطراف، المشيمة والسائل الأمنيوسي. يمكن معرفة جنس الجنين. أهم فحص خلال الحمل - لا تفوتيه.'),
    _DiscoverArt(title: 'فحص سكر الحمل', emoji: '🍬', color1: const Color(0xFFFF8F00),
      content: 'أسبوع 24-28: تشربين محلول سكري ويقاس السكر قبل وبعد ساعة وساعتين. يصيب 5-10% من الحوامل. إذا شُخّص: حمية قليلة السكر ورياضة خفيفة. معظم الحالات تختفي بعد الولادة.'),
  ]),
  _DiscoverCat(name: 'الجمال والعناية', emoji: '💅', articles: [
    _DiscoverArt(title: 'العناية بالبشرة', emoji: '🧴', color1: const Color(0xFFFF7043),
      content: 'واقي شمس SPF 50 يومياً لمنع الكلف. رطبي بشرتك صباحاً ومساءً. تجنبي الريتينول وحمض الساليسيليك. آمنة: حمض الهيالورونيك، فيتامين C، نياسيناميد، وزيوت طبيعية.'),
    _DiscoverArt(title: 'العناية بالشعر', emoji: '💇‍♀️', color1: const Color(0xFF8D6E63),
      content: 'الهرمونات تجعل الشعر أكثر كثافة. استخدمي شامبو لطيف بدون كبريتات. تجنبي الصبغات الكيميائية في الثلث الأول - الحناء الطبيعية آمنة. البروتين والكيراتين غير آمنين. بعد الولادة سيتساقط الشعر الزائد مؤقتاً.'),
    _DiscoverArt(title: 'الولادة والتحضير', emoji: '🏥', color1: const Color(0xFFAB47BC),
      content: 'حضري حقيبة المستشفى من الأسبوع 36: ملابس مريحة لك وللمولود، مستلزمات النظافة، أوراقك الطبية. اختاري المستشفى مسبقاً. تعلمي تقنيات التنفس للمخاض. جهزي غرفة الطفل.'),
  ]),
];

// ─── Discover Article Detail Screen ───
class _DiscoverDetailScreen extends StatelessWidget {
  final _DiscoverArt article;
  final String categoryName;
  const _DiscoverDetailScreen({Key? key, required this.article, required this.categoryName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bgColor,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: Colors.white,
              foregroundColor: _teal,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(categoryName, style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                centerTitle: true,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [article.color1.withOpacity(0.2), article.color1.withOpacity(0.05), Colors.white],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          width: 95,
                          height: 95,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: article.color1.withOpacity(0.15), blurRadius: 20, spreadRadius: 5)],
                          ),
                          child: Center(child: Text(article.emoji, style: const TextStyle(fontSize: 48))),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: article.color1.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Text(categoryName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: article.color1)),
                    ),
                    const SizedBox(height: 14),
                    Text(article.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textPrimary, height: 1.4)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Icon(Icons.access_time, size: 14, color: _textSecondary.withOpacity(0.6)),
                      const SizedBox(width: 4),
                      Text('3 دقائق قراءة', style: TextStyle(fontSize: 12, color: _textSecondary.withOpacity(0.6))),
                    ]),
                    const SizedBox(height: 20),
                    Container(height: 1, color: const Color(0xFFEEEEEE)),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
                      ),
                      child: Text(article.content, style: const TextStyle(fontSize: 16, height: 2.0, color: _textPrimary)),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _lightTeal,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _teal.withOpacity(0.15)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: _teal.withOpacity(0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.lightbulb_outline, color: _teal, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('نصيحة مهمة', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _teal)),
                                SizedBox(height: 4),
                                Text('استشيري طبيبتك دائماً قبل اتخاذ أي قرارات صحية. كل حمل مختلف.',
                                  style: TextStyle(fontSize: 13, color: _textSecondary, height: 1.6)),
                              ],
                            ),
                          ),
                        ],
                      ),
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

// ─── Category All Articles Screen ───
class _CategoryArticlesScreen extends StatelessWidget {
  final _DiscoverCat category;
  const _CategoryArticlesScreen({Key? key, required this.category}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bgColor,
        appBar: AppBar(
          title: Text(
            '${category.emoji} ${category.name}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: _textPrimary, fontSize: 18),
          ),
          backgroundColor: Colors.white,
          foregroundColor: _teal,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: _divider),
          ),
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: category.articles.length,
          itemBuilder: (context, index) {
            final art = category.articles[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _DiscoverDetailScreen(article: art, categoryName: category.name),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    // Emoji section
                    Container(
                      width: 100,
                      height: 110,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [art.color1.withOpacity(0.2), art.color1.withOpacity(0.08)],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(18),
                          bottomRight: Radius.circular(18),
                        ),
                      ),
                      child: Center(
                        child: Text(art.emoji, style: const TextStyle(fontSize: 40)),
                      ),
                    ),
                    // Text section
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: art.color1.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                category.name,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: art.color1),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              art.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 12, color: _textSecondary.withOpacity(0.6)),
                                const SizedBox(width: 4),
                                Text('3 دقائق قراءة', style: TextStyle(fontSize: 11, color: _textSecondary.withOpacity(0.6))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Icon(Icons.arrow_back_ios, size: 14, color: _textSecondary.withOpacity(0.4)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Progress ring painter
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;

  _ProgressRingPainter({required this.progress, required this.color, this.bgColor = const Color(0xFFFFE8EC)});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    final strokeWidth = 7.0;

    // Background circle
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = bgColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Progress arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter old) => old.progress != progress;
}

class RealisticFetusIllustration extends CustomPainter {
  final int week;
  final bool isSmall;
  final bool isOnDark;
  RealisticFetusIllustration({required this.week, this.isSmall = false, this.isOnDark = false});

  static const Color _skinBase = Color(0xFFE8A090);
  static const Color _skinLight = Color(0xFFF2C4B6);
  static const Color _skinDark = Color(0xFFC47A6C);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = min(cx, cy) * 0.85;
    // Background glow
    if (!isSmall) {
      final glowPaint = Paint()
        ..shader = ui.Gradient.radial(Offset(cx, cy), r * 1.3,
            [const Color(0xFFE8B4B8).withOpacity(0.12), Colors.transparent],
            [0.0, 1.0]);
      canvas.drawCircle(Offset(cx, cy), r * 1.3, glowPaint);
    }
    canvas.save();
    canvas.translate(cx, cy);
    if (week <= 4) {
      _drawEarly(canvas, r);
    } else if (week <= 8) {
      _drawEmbryo(canvas, r);
    } else if (week <= 14) {
      _drawEarlyFetus(canvas, r, _skinLight);
    } else if (week <= 26) {
      _drawMidFetus(canvas, r, _skinLight);
    } else {
      _drawLateFetus(canvas, r, _skinLight);
    }
    canvas.restore();
  }

  void _drawEarly(Canvas canvas, double r) {
    final rng = Random(42);
    for (int i = 0; i < 12; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final dist = rng.nextDouble() * r * 0.35;
      final cr = r * (0.1 + rng.nextDouble() * 0.12);
      final p = Paint()
        ..shader = ui.Gradient.radial(
            Offset(cos(angle) * dist - cr * 0.2, sin(angle) * dist - cr * 0.2),
            cr,
            [_skinLight.withOpacity(0.9), _skinBase.withOpacity(0.7)],
            [0.0, 1.0]);
      canvas.drawCircle(Offset(cos(angle) * dist, sin(angle) * dist), cr, p);
    }
    final memb = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = _skinDark.withOpacity(0.3);
    canvas.drawCircle(Offset.zero, r * 0.55, memb);
  }

  void _drawEmbryo(Canvas canvas, double r) {
    final bodyPath = Path();
    final s = r * 0.6;
    bodyPath.moveTo(0, -s * 0.8);
    bodyPath.cubicTo(s * 0.7, -s * 0.6, s * 0.7, s * 0.3, s * 0.2, s * 0.7);
    bodyPath.cubicTo(s * 0.1, s * 0.8, -s * 0.1, s * 0.8, -s * 0.15, s * 0.6);
    bodyPath.cubicTo(-s * 0.3, s * 0.2, -s * 0.4, -s * 0.3, 0, -s * 0.8);
    bodyPath.close();

    final bodyPaint = Paint()
      ..shader = ui.Gradient.radial(
          Offset(s * 0.1, -s * 0.1), s,
          [_skinLight, _skinBase, _skinDark],
          [0.0, 0.6, 1.0]);
    canvas.drawPath(bodyPath, bodyPaint);

    final headPaint = Paint()
      ..shader = ui.Gradient.radial(
          Offset(-s * 0.05, -s * 0.7), s * 0.4,
          [_skinLight, _skinBase],
          [0.0, 1.0]);
    canvas.drawCircle(Offset(s * 0.05, -s * 0.65), s * 0.3, headPaint);

    final eye = Paint()..color = const Color(0xFF3A2520).withOpacity(0.6);
    canvas.drawCircle(Offset(s * 0.15, -s * 0.7), s * 0.04, eye);
  }

  void _drawEarlyFetus(Canvas canvas, double r, Color light) {
    final s = r * 0.7;
    _head(canvas, Offset(0, -s * 0.4), s * 0.35, light);
    final bodyPath = Path();
    bodyPath.moveTo(-s * 0.2, -s * 0.1);
    bodyPath.cubicTo(-s * 0.35, s * 0.3, -s * 0.15, s * 0.7, s * 0.05, s * 0.6);
    bodyPath.cubicTo(s * 0.25, s * 0.5, s * 0.35, s * 0.1, s * 0.2, -s * 0.1);
    bodyPath.close();
    final bp = Paint()
      ..shader = ui.Gradient.radial(
          Offset(0, s * 0.2), s * 0.7,
          [light, _skinBase, _skinDark],
          [0.0, 0.5, 1.0]);
    canvas.drawPath(bodyPath, bp);
    final limb = Paint()..color = _skinBase.withOpacity(0.8);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(-s * 0.35, s * 0.15), width: s * 0.12, height: s * 0.3), const Radius.circular(6)), limb);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(s * 0.3, s * 0.15), width: s * 0.12, height: s * 0.3), const Radius.circular(6)), limb);
    canvas.drawCircle(Offset(s * 0.08, -s * 0.45), s * 0.035, Paint()..color = const Color(0xFF3A2520).withOpacity(0.7));
    _cord(canvas, Offset(s * 0.05, s * 0.55), s);
  }

  void _drawMidFetus(Canvas canvas, double r, Color light) {
    final s = r * 0.8;
    canvas.save();
    canvas.rotate(-0.3);
    _head(canvas, Offset(s * 0.05, -s * 0.45), s * 0.32, light);
    final body = Path();
    body.moveTo(-s * 0.15, -s * 0.15);
    body.cubicTo(-s * 0.3, s * 0.15, -s * 0.25, s * 0.55, 0, s * 0.5);
    body.cubicTo(s * 0.2, s * 0.45, s * 0.3, s * 0.1, s * 0.15, -s * 0.15);
    body.close();
    final bp = Paint()
      ..shader = ui.Gradient.radial(
          Offset(0, s * 0.1), s * 0.6,
          [light, _skinBase, _skinDark],
          [0.0, 0.5, 1.0]);
    canvas.drawPath(body, bp);
    final armP = Paint()
      ..shader = ui.Gradient.linear(
          Offset(-s * 0.3, 0), Offset(-s * 0.5, s * 0.2),
          [_skinBase, _skinDark],
          [0.0, 1.0])
      ..strokeWidth = s * 0.08
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(-s * 0.2, s * 0.0), Offset(-s * 0.35, s * 0.25), armP);
    canvas.drawCircle(Offset(-s * 0.36, s * 0.26), s * 0.05, Paint()..color = _skinBase);
    final legP = Paint()
      ..shader = ui.Gradient.linear(
          Offset(0, s * 0.4), Offset(-s * 0.15, s * 0.65),
          [_skinBase, _skinDark],
          [0.0, 1.0])
      ..strokeWidth = s * 0.09
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final leg = Path();
    leg.moveTo(-s * 0.05, s * 0.45);
    leg.cubicTo(-s * 0.2, s * 0.6, -s * 0.3, s * 0.5, -s * 0.25, s * 0.35);
    canvas.drawPath(leg, legP);
    canvas.drawOval(Rect.fromCenter(center: Offset(-s * 0.25, s * 0.34), width: s * 0.1, height: s * 0.06),
        Paint()..color = _skinBase);
    canvas.drawCircle(Offset(s * 0.15, -s * 0.5), s * 0.03, Paint()..color = const Color(0xFF3A2520).withOpacity(0.8));
    canvas.drawArc(Rect.fromCenter(center: Offset(-s * 0.08, -s * 0.42), width: s * 0.1, height: s * 0.12),
        0.5, 2.5, false, Paint()..color = _skinDark.withOpacity(0.4)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    canvas.drawCircle(Offset(s * 0.2, -s * 0.43), s * 0.025, Paint()..color = _skinDark.withOpacity(0.5));
    _cord(canvas, Offset(s * 0.05, s * 0.5), s);
    canvas.restore();
  }

  void _drawLateFetus(Canvas canvas, double r, Color light) {
    final s = r * 0.85;
    canvas.save();
    canvas.rotate(-0.25);
    _head(canvas, Offset(s * 0.05, -s * 0.42), s * 0.35, light);
    final body = Path();
    body.moveTo(-s * 0.18, -s * 0.1);
    body.cubicTo(-s * 0.35, s * 0.2, -s * 0.3, s * 0.55, 0, s * 0.52);
    body.cubicTo(s * 0.25, s * 0.48, s * 0.35, s * 0.15, s * 0.18, -s * 0.1);
    body.close();
    final bp = Paint()
      ..shader = ui.Gradient.radial(
          Offset(0, s * 0.15), s * 0.6,
          [light, _skinBase, _skinDark],
          [0.0, 0.45, 1.0]);
    canvas.drawPath(body, bp);
    final bellyGlow = Paint()
      ..shader = ui.Gradient.radial(
          Offset(s * 0.05, s * 0.2), s * 0.2,
          [light.withOpacity(0.5), Colors.transparent],
          [0.0, 1.0]);
    canvas.drawCircle(Offset(s * 0.05, s * 0.2), s * 0.2, bellyGlow);
    final armP = Paint()
      ..shader = ui.Gradient.linear(
          Offset(-s * 0.2, s * 0.05), Offset(s * 0.1, s * 0.15),
          [_skinBase, _skinDark],
          [0.0, 1.0])
      ..strokeWidth = s * 0.08
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final arm1 = Path();
    arm1.moveTo(-s * 0.2, s * 0.05);
    arm1.cubicTo(-s * 0.15, s * 0.15, -s * 0.05, s * 0.18, s * 0.05, s * 0.1);
    canvas.drawPath(arm1, armP);
    canvas.drawCircle(Offset(s * 0.06, s * 0.09), s * 0.05, Paint()..color = _skinBase);
    for (int i = 0; i < 4; i++) {
      final fa = -0.4 + i * 0.25;
      canvas.drawLine(
          Offset(s * 0.06 + cos(fa) * s * 0.05, s * 0.09 + sin(fa) * s * 0.05),
          Offset(s * 0.06 + cos(fa) * s * 0.08, s * 0.09 + sin(fa) * s * 0.08),
          Paint()..color = _skinDark.withOpacity(0.3)..strokeWidth = 1.0..strokeCap = StrokeCap.round);
    }
    final legP = Paint()
      ..shader = ui.Gradient.linear(
          Offset(-s * 0.05, s * 0.45), Offset(-s * 0.25, s * 0.2),
          [_skinBase, _skinDark],
          [0.0, 1.0])
      ..strokeWidth = s * 0.1
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final leg1 = Path();
    leg1.moveTo(-s * 0.05, s * 0.48);
    leg1.cubicTo(-s * 0.2, s * 0.55, -s * 0.35, s * 0.45, -s * 0.3, s * 0.3);
    canvas.drawPath(leg1, legP);
    final leg2 = Path();
    leg2.moveTo(s * 0.1, s * 0.48);
    leg2.cubicTo(-s * 0.05, s * 0.6, -s * 0.2, s * 0.55, -s * 0.2, s * 0.4);
    canvas.drawPath(leg2, legP);
    canvas.drawOval(Rect.fromCenter(center: Offset(-s * 0.3, s * 0.29), width: s * 0.11, height: s * 0.07),
        Paint()..color = _skinBase);
    canvas.drawOval(Rect.fromCenter(center: Offset(-s * 0.2, s * 0.39), width: s * 0.11, height: s * 0.07),
        Paint()..color = _skinBase);
    final eyeP = Paint()..color = const Color(0xFF3A2520).withOpacity(0.7)..strokeWidth = 1.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCenter(center: Offset(s * 0.14, -s * 0.47), width: s * 0.08, height: s * 0.04), 0, pi, false, eyeP);
    final nosePath = Path();
    nosePath.moveTo(s * 0.2, -s * 0.44);
    nosePath.cubicTo(s * 0.24, -s * 0.42, s * 0.24, -s * 0.38, s * 0.2, -s * 0.37);
    canvas.drawPath(nosePath, Paint()..color = _skinDark.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 1.2);
    canvas.drawArc(Rect.fromCenter(center: Offset(s * 0.16, -s * 0.33), width: s * 0.08, height: s * 0.04),
        0.2, 2.2, false, Paint()..color = const Color(0xFFBF7E7E).withOpacity(0.6)..style = PaintingStyle.stroke..strokeWidth = 1.2);
    final earPath = Path();
    earPath.moveTo(-s * 0.05, -s * 0.42);
    earPath.cubicTo(-s * 0.12, -s * 0.48, -s * 0.14, -s * 0.38, -s * 0.08, -s * 0.35);
    canvas.drawPath(earPath, Paint()..color = _skinDark.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 1.8);
    if (week >= 32) {
      final hairP = Paint()..color = const Color(0xFF5D4037).withOpacity(0.3)..strokeWidth = 1.0..strokeCap = StrokeCap.round;
      for (int i = 0; i < 8; i++) {
        final a = -1.8 + i * 0.3;
        canvas.drawLine(
            Offset(s * 0.05 + cos(a) * s * 0.33, -s * 0.42 + sin(a) * s * 0.33),
            Offset(s * 0.05 + cos(a) * s * 0.4, -s * 0.42 + sin(a) * s * 0.4),
            hairP);
      }
    }
    _cord(canvas, Offset(s * 0.05, s * 0.52), s);
    canvas.restore();
  }

  void _head(Canvas canvas, Offset center, double radius, Color light) {
    final hp = Paint()
      ..shader = ui.Gradient.radial(
          Offset(center.dx - radius * 0.15, center.dy - radius * 0.15), radius,
          [light, _skinBase, _skinDark],
          [0.0, 0.6, 1.0]);
    canvas.drawOval(
        Rect.fromCenter(center: center, width: radius * 2, height: radius * 2.15), hp);
    final hl = Paint()
      ..shader = ui.Gradient.radial(
          Offset(center.dx - radius * 0.2, center.dy - radius * 0.3), radius * 0.5,
          [light.withOpacity(0.6), Colors.transparent],
          [0.0, 1.0]);
    canvas.drawCircle(Offset(center.dx - radius * 0.15, center.dy - radius * 0.2), radius * 0.5, hl);
  }

  void _cord(Canvas canvas, Offset start, double s) {
    final cordPath = Path();
    cordPath.moveTo(start.dx, start.dy);
    cordPath.cubicTo(start.dx + s * 0.15, start.dy + s * 0.15, start.dx - s * 0.1, start.dy + s * 0.3,
        start.dx + s * 0.2, start.dy + s * 0.35);
    final cordPaint = Paint()
      ..shader = ui.Gradient.linear(
          start, Offset(start.dx + s * 0.2, start.dy + s * 0.35),
          [_skinDark.withOpacity(0.6), const Color(0xFF8B6F6F).withOpacity(0.3)],
          [0.0, 1.0])
      ..strokeWidth = s * 0.04
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(cordPath, cordPaint);
  }

  @override
  bool shouldRepaint(covariant RealisticFetusIllustration old) => old.week != week;
}
                                           