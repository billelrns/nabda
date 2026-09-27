import 'package:flutter/material.dart';
import '../../models/smart_article.dart';
import '../../services/smart_articles_service.dart';
import 'article_detail_screen.dart';
import 'articles_list_screen.dart';
import 'articles_hub_screen.dart';
import '../pregnancy/due_date_countdown_screen.dart';
import '../pregnancy/kick_counter_screen.dart';
import '../pregnancy/fetus_size_screen.dart';
import '../pregnancy/hospital_bag_screen.dart';
import '../pregnancy/exercises_screen.dart';
import '../pregnancy/pregnancy_journal_screen.dart';
import '../fertility/fertility_screen.dart';
import '../cycle/symptom_logger.dart';
import '../baby/baby_dashboard.dart';
import '../baby/vaccination_schedule.dart';
import '../baby_names/baby_names_screen.dart';
import '../trackers/weight_tracker_screen.dart';
import '../health/health_measurements_screen.dart';
import '../health/medication_tracker_screen.dart';
import '../qadaa/qadaa_screen.dart';
import '../fiqh/womens_fiqh_screen.dart';
import '../ai_chat/ai_chat_screen.dart';
import '../doctors/doctors_list_screen.dart';
import '../../config/play_compliance.dart';

/// نموذج بيانات أداة نبضة الذكية القابلة للبحث
class SmartToolItem {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final IconData icon;
  final Color color;
  final List<String> keywords;
  final Widget Function(BuildContext) builder;

  const SmartToolItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.color,
    required this.keywords,
    required this.builder,
  });
}

class ArticlesSearchScreen extends StatefulWidget {
  final String? initialQuery;
  const ArticlesSearchScreen({Key? key, this.initialQuery}) : super(key: key);

  @override
  State<ArticlesSearchScreen> createState() => _ArticlesSearchScreenState();
}

class _ArticlesSearchScreenState extends State<ArticlesSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final SmartArticlesService _service = SmartArticlesService();
  
  List<SmartArticle> _articleResults = [];
  List<SmartToolItem> _toolResults = [];
  bool _searching = false;
  String _lastQuery = '';
  String _activeFilter = 'all'; // 'all', 'tools', 'articles'

  // ── قائمة الأدوات الذكية المتاحة للبحث المباشر ──
  late final List<SmartToolItem> _allTools = [
    SmartToolItem(
      id: 'due_date',
      title: 'حاسبة موعد الولادة المتوقع',
      subtitle: 'حساب موعد الولادة الدقيق وأسابيع الحمل بناءً على آخر دورة',
      category: 'الحمل والولادة',
      icon: Icons.event_available_rounded,
      color: const Color(0xFFE91E63),
      keywords: ['موعد الولادة', 'حاسبة الحمل', 'تاريخ الولادة', 'حساب الحمل', 'اسابيع الحمل', 'ولادة', 'due date'],
      builder: (_) => const DueDateCountdownScreen(),
    ),
    SmartToolItem(
      id: 'ovulation',
      title: 'حاسبة التبويض وأيام الخصوبة',
      subtitle: 'تحديد نافذة الخصوبة وأيام التبويض لزيادة فرص الحمل',
      category: 'التبويض والخصوبة',
      icon: Icons.calendar_month_rounded,
      color: const Color(0xFF7E57C2),
      keywords: ['تبويض', 'خصوبة', 'فرص الحمل', 'ايام التبويض', 'حمل', 'نافذة الخصوبة', 'ovulation', 'تأخر الحمل'],
      builder: (_) => const FertilityScreen(userData: {}),
    ),
    SmartToolItem(
      id: 'kick_counter',
      title: 'متتبع ركلات وحركة الجنين',
      subtitle: 'عداد ذكي لمراقبة ركلات وحركة الجنين اليومية والاطمئنان عليه',
      category: 'الحمل والولادة',
      icon: Icons.touch_app_rounded,
      color: const Color(0xFFFF4081),
      keywords: ['ركلات', 'حركة الجنين', 'عداد الركلات', 'جنين', 'رفرفة', 'kick counter', 'نبض الجنين'],
      builder: (_) => const KickCounterScreen(),
    ),
    SmartToolItem(
      id: 'fetus_size',
      title: 'مقارنة حجم الجنين بالفاكهة',
      subtitle: 'مقارنة بصرية أسبوعية لطول ووزن الجنين مع الفواكه اللطيفة',
      category: 'الحمل والولادة',
      icon: Icons.child_care_rounded,
      color: const Color(0xFF00897B),
      keywords: ['حجم الجنين', 'وزن الجنين', 'طول الجنين', 'فاكهة', 'شكل الجنين', 'تطور الجنين', 'أسبوع الحمل'],
      builder: (_) => const FetusSizeScreen(),
    ),
    SmartToolItem(
      id: 'hospital_bag',
      title: 'حقيبة المستشفى والولادة',
      subtitle: 'قائمة تفاعلية شاملة لمستلزمات الأم والطفل وحقيبة الولادة',
      category: 'الحمل والولادة',
      icon: Icons.work_outline_rounded,
      color: const Color(0xFFEC407A),
      keywords: ['حقيبة المستشفى', 'شنطة الولادة', 'مستلزمات البيبي', 'تجهيز الولادة', 'اغراض المستشفى', 'نفاس'],
      builder: (_) => const HospitalBagScreen(),
    ),
    SmartToolItem(
      id: 'cycle_logger',
      title: 'سجل وأعراض الدورة الشهرية',
      subtitle: 'متابعة مراحل الدورة وتسجيل المزاج والأعراض والمغص والتوقعات',
      category: 'الدورة الشهرية',
      icon: Icons.water_drop_rounded,
      color: const Color(0xFFE91E63),
      keywords: ['الدورة الشهرية', 'حيض', 'طمث', 'اعراض الدورة', 'المزاج', 'المغص', 'سجل الدورة', 'period'],
      builder: (_) => const SymptomLogger(),
    ),
    SmartToolItem(
      id: 'baby_growth',
      title: 'سجل نمو وتطور الرضيع',
      subtitle: 'متابعة رضاعة ونوم وحفاضات وتطور مهارات الرضيع شهراً بشهر',
      category: 'رعاية الرضيع',
      icon: Icons.child_friendly_rounded,
      color: const Color(0xFF29B6F6),
      keywords: ['رضيع', 'طفل', 'نمو الطفل', 'وزن الرضيع', 'طول الطفل', 'رضاعة', 'نوم الرضيع', 'baby'],
      builder: (_) => const BabyDashboard(),
    ),
    SmartToolItem(
      id: 'vaccinations',
      title: 'جدول تطعيمات ولقاحات الطفل',
      subtitle: 'تذكير بمواعيد تطعيمات طفلكِ — تأكدي منها مع طبيبتكِ',
      category: 'رعاية الرضيع',
      icon: Icons.medical_services_rounded,
      color: const Color(0xFF26A69A),
      keywords: ['تطعيم', 'تطعيمات', 'لقاح', 'لقاحات', 'جدول التطعيمات', 'صحة الطفل', 'vaccine'],
      builder: (_) => const VaccinationSchedule(),
    ),
    SmartToolItem(
      id: 'weight_tracker',
      title: 'حاسبة الوزن ومؤشر كتلة الجسم (BMI)',
      subtitle: 'متابعة الزيادة الصحية للوزن أثناء الحمل ومسار الرشاقة',
      category: 'صحة ورشاقة',
      icon: Icons.monitor_weight_rounded,
      color: const Color(0xFFFF9800),
      keywords: ['وزن', 'ميزان', 'كتلة الجسم', 'bmi', 'رجيم', 'رشاقة', 'زيادة الوزن', 'تنحيف', 'سعرات'],
      builder: (_) => const WeightTrackerScreen(),
    ),
    SmartToolItem(
      id: 'health_measurements',
      title: 'سجل القياسات الحيوية (الضغط والسكري)',
      subtitle: 'مراقبة وتسجيل ضغط الدم، سكري الحمل، والحرارة ومشاركتها مع الطبيب',
      category: 'صحة ورشاقة',
      icon: Icons.favorite_rounded,
      color: const Color(0xFFD32F2F),
      keywords: ['ضغط الدم', 'السكر', 'سكري الحمل', 'ضغط', 'قياسات', 'سكر', 'نبض', 'حرارة'],
      builder: (_) => const HealthMeasurementsScreen(),
    ),
    SmartToolItem(
      id: 'medications',
      title: 'متتبع الأدوية والفيتامينات',
      subtitle: 'تذكير ذكي بحمض الفوليك، الحديد، الكالسيوم ومواعيد الأدوية',
      category: 'صحة ورشاقة',
      icon: Icons.medication_rounded,
      color: const Color(0xFF7E57C2),
      keywords: ['دواء', 'ادوية', 'فيتامين', 'فيتامينات', 'حمض الفوليك', 'حديد', 'كالسيوم', 'تذكير دواء'],
      builder: (_) => const MedicationTrackerScreen(),
    ),
    SmartToolItem(
      id: 'baby_names',
      title: 'دليل أسماء المواليد والتوائم ومعانيها',
      subtitle: 'آلاف الأسماء العربية والإسلامية للبنات والأولاد مع معانيها وتوافقاتها',
      category: 'رعاية الرضيع',
      icon: Icons.menu_book_rounded,
      color: const Color(0xFF9C27B0),
      keywords: ['اسماء', 'اسم بيبي', 'اسماء بنات', 'اسماء اولاد', 'معاني الاسماء', 'توأم', 'اسماء مواليد'],
      builder: (_) => const BabyNamesScreen(),
    ),
    SmartToolItem(
      id: 'qadaa',
      title: 'حاسبة قضاء الصيام',
      subtitle: 'حساب وتتبع الأيام الفائتة من رمضان بسبب الحيض أو الحمل أو النفاس',
      category: 'فقه وأحكام',
      icon: Icons.nights_stay_rounded,
      color: const Color(0xFF5C6BC0),
      keywords: ['قضاء', 'صيام', 'رمضان', 'صوم', 'دين الصيام', 'ايام فائتة', 'كفارة'],
      builder: (_) => const QadaaScreen(),
    ),
    SmartToolItem(
      id: 'fiqh',
      title: 'فقه المرأة المسلمة',
      subtitle: 'أحكام الطهارة، الصلاة، الحيض، الاستحاضة والنفاس وفق الشريعة الإسلامية',
      category: 'فقه وأحكام',
      icon: Icons.auto_stories_rounded,
      color: const Color(0xFF43A047),
      keywords: ['فقه', 'حيض', 'نفاس', 'استحاضة', 'طهارة', 'صلاة', 'احكام المرأة', 'فتاوى'],
      builder: (_) => const WomensFiqhScreen(),
    ),
    SmartToolItem(
      id: 'ai_chat',
      title: 'مساعدة نبضة الذكية (Nabda AI)',
      subtitle: 'إجابات عامة فورية بالذكاء الاصطناعي — لا تغني عن استشارة الطبيبة',
      category: 'استشارات',
      icon: Icons.smart_toy_rounded,
      color: const Color(0xFFE91E63),
      keywords: ['ذكاء', 'مساعد', 'استشارة', 'سؤال', 'ai', 'شات', 'طبيبة'],
      builder: (_) => const AIChatScreen(),
    ),
    SmartToolItem(
      id: 'doctors',
      title: 'دليل الطبيبات والعيادات المعتمدة',
      subtitle: 'البحث عن أفضل طبيبات النساء والتوليد والمراكز القريبة منكِ',
      category: 'دليل طبي',
      icon: Icons.local_hospital_rounded,
      color: const Color(0xFF00ACC1),
      keywords: ['طبيبة', 'طبيب', 'دكتور', 'عيادة', 'مستشفى', 'توليد', 'سونار', 'مركز طبي'],
      builder: (_) => const DoctorsListScreen(),
    ),
    SmartToolItem(
      id: 'exercises',
      title: 'تمارين الحمل واليوغا وكيجل',
      subtitle: 'تمارين آمنة لتقوية الحوض، تخفيف آلام الظهر وتسهيل عملية الولادة',
      category: 'صحة ورشاقة',
      icon: Icons.fitness_center_rounded,
      color: const Color(0xFFFF7043),
      keywords: ['تمارين', 'رياضة', 'يوغا', 'كيجل', 'تسهيل الولادة', 'الم الظهر', 'لياقة'],
      builder: (_) => const ExercisesScreen(),
    ),
    SmartToolItem(
      id: 'journal',
      title: 'مذكرات ويوميات الأمومة',
      subtitle: 'تدوين ذكرياتكِ ومشاعركِ وصور بطنكِ في كل أسبوع من الحمل',
      category: 'الحمل والولادة',
      icon: Icons.edit_note_rounded,
      color: const Color(0xFFAB47BC),
      keywords: ['يوميات', 'مذكرات', 'ذكريات', 'صور الحمل', 'تدوين', 'دفتر'],
      builder: (_) => const PregnancyJournalScreen(),
    ),
    SmartToolItem(
      id: 'encyclopedia_hub',
      title: 'مكتبة نبضة',
      subtitle: 'آلاف المقالات في الحمل والعافية والجمال ورعاية الطفل',
      category: 'الموسوعة',
      icon: Icons.library_books_rounded,
      color: const Color(0xFFE91E63),
      keywords: ['موسوعة', 'مقالات', 'مقال', 'اقسام', 'تصنيفات', 'بحث'],
      builder: (_) => const ArticlesHubScreen(),
    ),
  ]..removeWhere((t) => kHideMedicalFeatures && _medicalToolIds.contains(t.id));

  /// أدوات طبية مخفية في نسخة الحساب الشخصي (انظر play_compliance.dart)
  static const Set<String> _medicalToolIds = {
    'health_measurements',
    'medications',
    'vaccinations',
    'kick_counter',
    'ai_chat',
    'doctors',
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _controller.text = widget.initialQuery!;
      _performSearch(widget.initialQuery!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _normalize(String s) {
    return s
        .replaceAll(RegExp(r'[\u064B-\u065F]'), '') // tashkeel
        .replaceAll(RegExp(r'[أإآ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .toLowerCase()
        .trim();
  }

  Future<void> _performSearch(String q) async {
    final query = q.trim();
    if (query.length < 2) {
      if (mounted) {
        setState(() {
          _articleResults = [];
          _toolResults = [];
          _searching = false;
          _lastQuery = query;
        });
      }
      return;
    }

    setState(() {
      _searching = true;
      _lastQuery = query;
    });

    final normQuery = _normalize(query);

    // 1. بحث الأدوات الذكية
    final matchingTools = _allTools.where((t) {
      final normTitle = _normalize(t.title);
      final normSubtitle = _normalize(t.subtitle);
      final normCat = _normalize(t.category);
      if (normTitle.contains(normQuery) || normSubtitle.contains(normQuery) || normCat.contains(normQuery)) {
        return true;
      }
      return t.keywords.any((k) => _normalize(k).contains(normQuery));
    }).toList();

    // 2. بحث المقالات الطبية في قاعدة البيانات
    final articles = await _service.search(query);

    if (!mounted) return;
    setState(() {
      _toolResults = matchingTools;
      _articleResults = articles.take(50).toList();
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _controller.text.trim().length >= 2;
    final totalCount = _toolResults.length + _articleResults.length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8FB),
        appBar: AppBar(
          backgroundColor: const Color(0xFFE91E63),
          foregroundColor: Colors.white,
          elevation: 2,
          title: TextField(
            controller: _controller,
            autofocus: widget.initialQuery == null,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            cursorColor: Colors.white,
            decoration: const InputDecoration(
              hintText: 'ابحثي في المقالات والأدوات الذكية...',
              hintStyle: TextStyle(color: Colors.white70, fontSize: 14.5),
              border: InputBorder.none,
            ),
            onChanged: _performSearch,
          ),
          actions: [
            if (_controller.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.white),
                onPressed: () {
                  _controller.clear();
                  _performSearch('');
                },
              ),
          ],
        ),
        body: _searching
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFE91E63)))
            : !hasQuery
                ? _buildEmptyStateOrSuggestions()
                : totalCount == 0
                    ? _buildNoResults()
                    : _buildSearchResults(),
      ),
    );
  }

  // ── عرض اقتراحات البحث والأدوات الشائعة عند فتح الشاشة ──
  Widget _buildEmptyStateOrSuggestions() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 1. أدوات نبضة الذكية الأكثر استخداماً
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '🛠️ أدوات نبضة الذكية',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1B1320)),
            ),
            Text(
              '${_allTools.length} أداة تفاعلية',
              style: const TextStyle(fontSize: 12, color: Color(0xFF8E8295)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _allTools.take(8).length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final tool = _allTools[i];
              return InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: tool.builder)),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 115,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: tool.color.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: tool.color.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: tool.color.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(tool.icon, color: tool.color, size: 24),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tool.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, height: 1.2),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 26),

        // 2. الكلمات الأكثر بحثاً
        const Text(
          '🔥 الكلمات الأكثر بحثاً',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1B1320)),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            'حساب موعد الولادة',
            'غثيان الحمل',
            'أيام التبويض',
            'تساقط الشعر',
            'روتين العناية بالبشرة',
            'حجم الجنين',
            'لغات الحب الزوجية',
            'جدول نوم الرضيع',
            'حمض الفوليك',
            'تكيس المبايض',
            'قضاء الصيام',
            'السونار التفصيلي',
          ].map((tag) {
            return InkWell(
              onTap: () {
                _controller.text = tag;
                _performSearch(tag);
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF3D0DE)),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF4A3F4F)),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 26),

        // 3. تصفح حسب أقسام الموسوعة
        const Text(
          '📚 تصفح موسوعة نبضة حسب القسم',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1B1320)),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _buildCategoryTile('🤰 الحمل والولادة', 'pregnancy', const Color(0xFFE91E63)),
            _buildCategoryTile('🥗 صحة ورشاقة', 'health', const Color(0xFF00897B)),
            _buildCategoryTile('💄 جمال وعناية', 'beauty', const Color(0xFFFF4081)),
            _buildCategoryTile('💍 زوجيات وسكينة', 'marriage', const Color(0xFFEC407A)),
            _buildCategoryTile('👶 رعاية الرضيع', 'baby', const Color(0xFF29B6F6)),
            _buildCategoryTile('🌸 تبويض وخصوبة', 'fertility', const Color(0xFF7E57C2)),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryTile(String title, String catId, Color color) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ArticlesListScreen(
            categoryId: catId,
            categoryName: title,
          ),
        ),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 32,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF1B1320)),
              ),
            ),
            const Icon(Icons.arrow_back_ios, size: 12, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ── عرض رسالة عدم وجود نتائج ──
  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 72, color: Color(0xFFC7A8EB)),
            const SizedBox(height: 16),
            Text(
              'لم نجد نتائج مطابقة لـ "$_lastQuery"',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1B1320)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'تأكدي من صحة الكلمات أو جربي البحث بكلمة عامة مثل: حمل، طفل، بشرة، تغذية، أو تصفحي موسوعة نبضة.',
              style: TextStyle(color: Color(0xFF8E8295), fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ArticlesHubScreen())),
              icon: const Icon(Icons.auto_stories),
              label: const Text('تصفح موسوعة نبضة كاملة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── عرض النتائج الموحدة (الأدوات الذكية + المقالات) ──
  Widget _buildSearchResults() {
    return Column(
      children: [
        // شريط التصفية السريع: الكل | الأدوات | المقالات
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Row(
            children: [
              _buildFilterChip('الكل (${_toolResults.length + _articleResults.length})', 'all'),
              const SizedBox(width: 8),
              if (_toolResults.isNotEmpty) ...[
                _buildFilterChip('🛠️ الأدوات (${_toolResults.length})', 'tools'),
                const SizedBox(width: 8),
              ],
              if (_articleResults.isNotEmpty)
                _buildFilterChip('📚 المقالات (${_articleResults.length})', 'articles'),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFF0E6EE)),

        // قائمة النتائج
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              // 1. قسم الأدوات الذكية المطابقة
              if ((_activeFilter == 'all' || _activeFilter == 'tools') && _toolResults.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: const Color(0xFFE91E63).withOpacity(0.12), shape: BoxShape.circle),
                        child: const Icon(Icons.build_circle_rounded, color: Color(0xFFE91E63), size: 18),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'الأدوات الذكية المطابقة (${_toolResults.length})',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1B1320)),
                      ),
                    ],
                  ),
                ),
                ..._toolResults.map((tool) => _buildToolCard(tool)),
                const SizedBox(height: 14),
              ],

              // 2. قسم المقالات الطبية المطابقة
              if ((_activeFilter == 'all' || _activeFilter == 'articles') && _articleResults.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: const Color(0xFF00897B).withOpacity(0.12), shape: BoxShape.circle),
                        child: const Icon(Icons.article_rounded, color: Color(0xFF00897B), size: 18),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'المقالات (${_articleResults.length})',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1B1320)),
                      ),
                    ],
                  ),
                ),
                ..._articleResults.map((art) => _buildArticleCard(art)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String id) {
    final active = _activeFilter == id;
    return InkWell(
      onTap: () => setState(() => _activeFilter = id),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE91E63) : const Color(0xFFFFF1F6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? const Color(0xFFE91E63) : const Color(0xFFF3D0DE)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : const Color(0xFF4A3F4F),
          ),
        ),
      ),
    );
  }

  // بطاقة أداة ذكية مطابقة
  Widget _buildToolCard(SmartToolItem tool) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tool.color.withOpacity(0.22), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: tool.color.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: tool.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(tool.icon, color: tool.color, size: 26),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                tool.title,
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF1B1320)),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: tool.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'أداة ذكية ⚡',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: tool.color),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            tool.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B6470), height: 1.35),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xFFFFF1F6),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFE91E63)),
        ),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: tool.builder)),
      ),
    );
  }

  // بطاقة مقال طبي مطابق
  Widget _buildArticleCard(SmartArticle a) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0E6EE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: a.themeColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(a.iconEmoji, style: const TextStyle(fontSize: 22)),
          ),
        ),
        title: Text(
          a.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1B1320), height: 1.3),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Text(
                a.categoryName,
                style: TextStyle(color: a.themeColor, fontSize: 11.5, fontWeight: FontWeight.w800),
              ),
              if (a.subcategoryName != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Text(
                    '${a.subcategoryEmoji ?? "🔖"} ${a.subcategoryName}',
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF166534)),
                  ),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule, size: 11, color: Colors.grey.shade500),
                  const SizedBox(width: 3),
                  Text(
                    a.readTime,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 13, color: Color(0xFFB0A7B5)),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: a)),
        ),
      ),
    );
  }
}
