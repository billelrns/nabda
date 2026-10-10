# خطة Antigravity — قارئ مقالات موحّد + ربط أدوات + كاروسال منتجات + إعلانات

> **موجّه إلى:** Antigravity / أي AI coding agent
> **المشروع:** `C:\nabda_app`
> **الهدف:** توحيد تجربة قراءة كل المقالات (القديمة والجديدة) بتصميم واحد فاخر مثل `ArticleDetailScreen`، مع ربط الأدوات، وكاروسالات منتجات ذكيّة، وأماكن إعلانات Google
> **المدة:** 6-8 ساعات
> **المخرجات:** 6 مراحل، commits منفصلة

---

## 📐 السياق الحالي

**المقالات الحالية موزّعة على عدّة تصاميم:**

| المصدر | العدد | التصميم الحالي |
|---|---|---|
| `assets/data/smart_2500_articles.json` | 2,500 | ✨ **تصميم جديد فاخر** (`ArticleDetailScreen`) |
| `lib/screens/pregnancy/discover_articles_screen.dart` | 37 | 🚧 تصميم قديم بسيط |
| `lib/data/specialized_articles.dart` | 85 | 🚧 عرض داخل `pregnancy_weeks_screen` بتصميم قديم |
| `lib/models/pregnancy_week_articles.dart` | 41×4 حقول | 🚧 عرض في شاشات الأسابيع |
| `lib/data/religious_articles.dart` | 11 | 🚧 لا شاشة عرض مخصّصة |
| Firestore `dynamic_articles` | ~50 | 🚧 عرض بسيط في `news_section.dart` |

**النتيجة:** المستخدمة ترى تجربة قراءة **مختلفة كلّ مرّة** حسب مصدر المقال.

**الأدوات الموجودة في التطبيق (للربط):**
- `weight_tracker_screen.dart` — متتبّع الوزن
- `medication_tracker_screen.dart` — تذكير الأدوية
- `health_trackers_screen.dart` — 7 متتبّعات صحّية
- `kick_counter_screen.dart` — عدّاد ركلات الجنين
- `due_date_countdown_screen.dart` — عدّاد ولادة
- `hospital_bag_screen.dart` — حقيبة الولادة
- `nutrition_screen.dart` — التغذية
- `exercises_screen.dart` — التمارين
- `pregnancy_calendar_screen.dart` — تقويم الحمل
- `pregnancy_journal_screen.dart` — يوميات الحمل
- `baby_names_screen.dart` — أسماء الأطفال
- `fertility_screen.dart` — الخصوبة
- `vaccination_schedule.dart` — لقاحات الطفل
- `ai_chat_screen.dart` — المساعد الذكي
- `symptom_logger.dart` — سجل الأعراض
- `qadaa_screen.dart` — قضاء الصلاة
- `womens_fiqh_screen.dart` — فقه المرأة

---

## المرحلة 1 — نموذج `UnifiedArticle` (يجمع كل الأنواع)

### الملف الجديد
- `lib/models/unified_article.dart`

### التنفيذ
```dart
import 'package:flutter/material.dart';
import 'smart_article.dart';
import 'pregnancy_week_articles.dart';

/// نموذج موحّد لأي مقال في التطبيق — يقبل مصادر متعدّدة ويعرضها بتصميم واحد.
class UnifiedArticle {
  final String id;
  final String source;               // 'smart' | 'discover' | 'specialized' | 'week' | 'religious' | 'dynamic'
  final String categoryId;
  final String categoryName;
  final String title;
  final String summary;
  final String iconEmoji;
  final Color themeColor;
  final String readTime;
  final String author;
  final String? badge;
  final String imagePath;
  final List<ArticleSection> sections;
  final List<ArticleFaq> faqs;
  final String? toolType;
  final String? toolTitle;
  final String? toolSubtitle;
  final int views;

  const UnifiedArticle({
    required this.id,
    required this.source,
    required this.categoryId,
    required this.categoryName,
    required this.title,
    required this.summary,
    required this.iconEmoji,
    required this.themeColor,
    required this.readTime,
    required this.author,
    this.badge,
    required this.imagePath,
    required this.sections,
    this.faqs = const [],
    this.toolType,
    this.toolTitle,
    this.toolSubtitle,
    this.views = 0,
  });

  /// من SmartArticle مباشرة
  factory UnifiedArticle.fromSmart(SmartArticle a) => UnifiedArticle(
    id: a.id, source: 'smart',
    categoryId: a.categoryId, categoryName: a.categoryName,
    title: a.title, summary: a.summary,
    iconEmoji: a.iconEmoji, themeColor: a.themeColor,
    readTime: a.readTime, author: a.author, badge: a.badge,
    imagePath: a.imagePath,
    sections: a.sections, faqs: a.faqs,
    toolType: a.toolType, toolTitle: a.toolTitle, toolSubtitle: a.toolSubtitle,
    views: a.originalViews,
  );

  /// من مقال متخصّص (specialized_articles.dart) — SpecArticle(title, body)
  factory UnifiedArticle.fromSpecialized({
    required String topic,
    required String title,
    required String body,
    int index = 0,
  }) {
    // تقسيم body إلى sections عبر الفقرات
    final paragraphs = body.split('\n\n');
    final sections = <ArticleSection>[];
    for (int i = 0; i < paragraphs.length; i++) {
      sections.add(ArticleSection(
        title: '', // الفقرات لا تحوي عناوين — نتركها فارغة
        content: paragraphs[i].trim(),
      ));
    }
    return UnifiedArticle(
      id: 'spec_${topic}_$index',
      source: 'specialized',
      categoryId: _topicToCategoryId(topic),
      categoryName: _topicLabel(topic),
      title: title,
      summary: paragraphs.isNotEmpty ? paragraphs[0].substring(0, 
        paragraphs[0].length > 150 ? 150 : paragraphs[0].length) + '...' : '',
      iconEmoji: _topicEmoji(topic),
      themeColor: Color(_topicColor(topic)),
      readTime: '${(body.length / 500).ceil()} دقائق',
      author: 'فريق التحرير الطبي — نبضة',
      imagePath: 'assets/images/articles_bg/bg_${_topicImgCat(topic)}_${(index % 5) + 1}.jpg'.padLeft(2, '0'),
      sections: sections,
    );
  }

  /// من مقال ديني (religious_articles.dart)
  factory UnifiedArticle.fromReligious({
    required String title,
    required String body,
    required String category, // حمل، ولادة، رضاعة، تربية، أحكام
    int index = 0,
  }) {
    final paragraphs = body.split('\n\n');
    final sections = paragraphs.map((p) => 
      ArticleSection(title: '', content: p.trim())).toList();
    return UnifiedArticle(
      id: 'religious_$index',
      source: 'religious',
      categoryId: 'religious',
      categoryName: '📖 $category',
      title: title,
      summary: paragraphs.isNotEmpty ? paragraphs[0].substring(0,
        paragraphs[0].length > 120 ? 120 : paragraphs[0].length) + '...' : '',
      iconEmoji: '☪️',
      themeColor: const Color(0xFF00897B),
      readTime: '${(body.length / 500).ceil()} دقائق',
      author: 'فريق التحرير الشرعي — نبضة',
      imagePath: 'assets/images/articles_bg/bg_pregnancy_${(index % 5) + 1}.jpg'.padLeft(2, '0'),
      sections: sections,
    );
  }

  /// من _DiscoverArticle
  factory UnifiedArticle.fromDiscover({
    required String title,
    required String content,
    required String emoji,
    required Color color,
    required String image,
    required String category,
    int index = 0,
  }) {
    final paragraphs = content.split('\n\n');
    final sections = paragraphs.map((p) => 
      ArticleSection(title: '', content: p.trim())).toList();
    return UnifiedArticle(
      id: 'discover_$index',
      source: 'discover',
      categoryId: 'discover',
      categoryName: category,
      title: title,
      summary: paragraphs.isNotEmpty ? paragraphs[0].substring(0,
        paragraphs[0].length > 150 ? 150 : paragraphs[0].length) + '...' : '',
      iconEmoji: emoji,
      themeColor: color,
      readTime: '${(content.length / 500).ceil()} دقائق',
      author: 'فريق التحرير — نبضة',
      imagePath: image.isNotEmpty ? image : 'assets/images/articles_bg/bg_pregnancy_01.jpg',
      sections: sections,
    );
  }

  // Helpers
  static String _topicToCategoryId(String topic) {
    const map = {
      'twins': 'pregnancy', 'diabetes': 'pregnancy', 'htn': 'pregnancy',
      'preterm': 'pregnancy', 'cesarean': 'pregnancy', 'nausea': 'pregnancy',
      'formula': 'baby', 'mixed': 'baby',
      'irregular': 'health', 'pcos': 'fertility', 'thyroid': 'health',
    };
    return map[topic] ?? 'health';
  }

  static String _topicLabel(String topic) {
    const map = {
      'twins': 'الحمل بتوأم', 'diabetes': 'سكري الحمل', 'htn': 'ضغط الحمل',
      'preterm': 'الولادة المبكرة', 'cesarean': 'الولادة القيصرية',
      'nausea': 'الغثيان', 'formula': 'الحليب الصناعي',
      'mixed': 'الرضاعة المختلطة', 'irregular': 'دورة غير منتظمة',
      'pcos': 'تكيّس المبايض', 'thyroid': 'الغدة الدرقية',
    };
    return map[topic] ?? topic;
  }

  static String _topicEmoji(String topic) {
    const map = {
      'twins': '👶👶', 'diabetes': '🩸', 'htn': '💓',
      'preterm': '⏰', 'cesarean': '🏥', 'nausea': '🤢',
      'formula': '🍼', 'mixed': '🍼', 'irregular': '📅',
      'pcos': '🩺', 'thyroid': '💊',
    };
    return map[topic] ?? '📄';
  }

  static int _topicColor(String topic) {
    // ألوان نبضة الرسمية
    return 0xFFE91E63; // نُبقي وردي نبضة الأساسي
  }

  static String _topicImgCat(String topic) {
    return _topicToCategoryId(topic);
  }
}
```

### Commit
```
feat(articles): نموذج UnifiedArticle موحّد لكل مصادر المقالات
```

---

## المرحلة 2 — خدمة ربط الأدوات (`ArticleToolRouter`)

### الملف الجديد
- `lib/services/article_tool_router.dart`

### التنفيذ
```dart
import 'package:flutter/material.dart';
import '../screens/trackers/weight_tracker_screen.dart';
import '../screens/trackers/health_trackers_screen.dart';
import '../screens/health/medication_tracker_screen.dart';
import '../screens/pregnancy/kick_counter_screen.dart';
import '../screens/pregnancy/due_date_countdown_screen.dart';
import '../screens/pregnancy/hospital_bag_screen.dart';
import '../screens/pregnancy/nutrition_screen.dart';
import '../screens/pregnancy/exercises_screen.dart';
import '../screens/pregnancy/pregnancy_calendar_screen.dart';
import '../screens/pregnancy/pregnancy_journal_screen.dart';
import '../screens/baby_names/baby_names_screen.dart';
import '../screens/fertility/fertility_screen.dart';
import '../screens/baby/vaccination_schedule.dart';
import '../screens/ai_chat/ai_chat_screen.dart';
import '../screens/cycle/symptom_logger.dart';
import '../screens/qadaa/qadaa_screen.dart';

/// خريطة toolType → شاشة التطبيق المناسبة
class ArticleToolRouter {
  static void openTool(BuildContext context, String? toolType) {
    if (toolType == null || toolType.isEmpty) {
      _showComingSoon(context);
      return;
    }

    final builder = _routes[toolType.toLowerCase()];
    if (builder == null) {
      _showComingSoon(context, toolType);
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: builder));
  }

  static bool hasRoute(String? toolType) =>
      toolType != null && _routes.containsKey(toolType.toLowerCase());

  static final Map<String, WidgetBuilder> _routes = {
    // الحمل والولادة
    'ovulation_calc': (_) => const FertilityScreen(),
    'due_date_calc': (_) => const DueDateCountdownScreen(),
    'due_date_countdown': (_) => const DueDateCountdownScreen(),
    'kick_counter': (_) => const KickCounterScreen(),
    'hospital_bag': (_) => const HospitalBagScreen(),
    'pregnancy_calendar': (_) => const PregnancyCalendarScreen(),
    'pregnancy_journal': (_) => const PregnancyJournalScreen(),
    'pregnancy_nutrition': (_) => const NutritionScreen(),
    'pregnancy_exercises': (_) => const ExercisesScreen(),
    
    // الطفل والرضيع
    'baby_names': (_) => const BabyNamesScreen(),
    'baby_names_search': (_) => const BabyNamesScreen(),
    'vaccine_schedule': (_) => const VaccinationSchedule(),
    'vaccination_schedule': (_) => const VaccinationSchedule(),
    
    // الدورة والصحة
    'cycle_calc': (_) => const SymptomLogger(),
    'symptom_logger': (_) => const SymptomLogger(),
    'fertility_calc': (_) => const FertilityScreen(),
    
    // المتتبّعات العامّة
    'weight_tracker': (_) => const WeightTrackerScreen(),
    'bmi_calc': (_) => const HealthTrackersScreen(),
    'water_tracker': (_) => const HealthTrackersScreen(),
    'sleep_tracker': (_) => const HealthTrackersScreen(),
    'health_tracker': (_) => const HealthTrackersScreen(),
    'medication_tracker': (_) => const MedicationTrackerScreen(),
    'medication_reminder': (_) => const MedicationTrackerScreen(),
    
    // خدمات
    'ai_chat': (_) => const AIChatScreen(),
    'ai_assistant': (_) => const AIChatScreen(),
    
    // شرعيّات
    'qadaa': (_) => const QadaaScreen(),
    'qadaa_calc': (_) => const QadaaScreen(),
  };

  static void _showComingSoon(BuildContext context, [String? toolType]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(toolType != null
          ? 'الأداة «$toolType» قيد التطوير، ستتوفّر قريباً بإذن الله 💫'
          : 'هذه الأداة قيد التطوير'),
        backgroundColor: const Color(0xFF00897B),
      ),
    );
  }
}
```

### Commit
```
feat(articles): ArticleToolRouter لربط أدوات المقالات بشاشاتها الفعلية
```

---

## المرحلة 3 — كاروسال المنتجات الذكي (شخصنة حسب المستخدمة)

### الملف الجديد
- `lib/widgets/smart_products_carousel.dart`

### التنفيذ (يقرأ من Firestore `products` أو `dynamic_products`)
```dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/shop/landing_product_screen.dart';

/// كاروسال منتجات ذكيّة يعرض:
/// - منتجات مطابقة لموضوع المقال (categoryId)
/// - مطابقة لملف المستخدمة (حامل / لديها طفل / تخطّط)
class SmartProductsCarousel extends StatefulWidget {
  final String articleCategoryId;   // مثل 'pregnancy' أو 'baby'
  final String title;
  final bool small;                 // small=true للكاروسال الصغير في منتصف المقال
  final int maxItems;

  const SmartProductsCarousel({
    Key? key,
    required this.articleCategoryId,
    this.title = 'منتجات قد تهمّك',
    this.small = false,
    this.maxItems = 8,
  }) : super(key: key);

  @override
  State<SmartProductsCarousel> createState() => _SmartProductsCarouselState();
}

class _SmartProductsCarouselState extends State<SmartProductsCarousel> {
  List<QueryDocumentSnapshot>? _products;
  String? _userStage;  // 'pregnant' | 'has_baby' | 'trying' | 'cycle'

  @override
  void initState() {
    super.initState();
    _loadUserAndProducts();
  }

  Future<void> _loadUserAndProducts() async {
    // 1. حدّد ملف المستخدمة
    final uid = FirebaseAuth.instance.currentUser?.uid;
    String stage = 'cycle';
    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users').doc(uid).get();
        final data = doc.data() ?? {};
        if (data['pregnancyStartDate'] != null) stage = 'pregnant';
        else if (data['babyBirthDate'] != null) stage = 'has_baby';
        else if (data['goal'] == 'trying') stage = 'trying';
        else stage = data['lifeStage']?.toString() ?? 'cycle';
      } catch (_) {}
    }
    _userStage = stage;

    // 2. حدّد فئات المنتجات المطلوبة
    final categories = _matchProductCategories(widget.articleCategoryId, stage);

    // 3. اجلب المنتجات
    try {
      final snap = await FirebaseFirestore.instance
          .collection('products')
          .where('category', whereIn: categories.isEmpty ? ['general'] : categories)
          .where('active', isEqualTo: true)
          .limit(widget.maxItems)
          .get();
      if (!mounted) return;
      setState(() => _products = snap.docs);
    } catch (_) {
      if (mounted) setState(() => _products = []);
    }
  }

  /// خريطة categoryId المقال + ملف المستخدمة → فئات المنتجات
  List<String> _matchProductCategories(String articleCat, String stage) {
    if (articleCat == 'pregnancy' || stage == 'pregnant') {
      return ['maternity_clothes', 'maternity_care', 'vitamins', 
              'hospital_bag', 'pregnancy_pillows'];
    }
    if (articleCat == 'baby' || stage == 'has_baby') {
      return ['baby_care', 'baby_clothes', 'diapers', 'feeding',
              'toys', 'baby_health'];
    }
    if (articleCat == 'beauty') {
      return ['skincare', 'beauty', 'hair_care', 'body_care'];
    }
    if (articleCat == 'fertility' || stage == 'trying') {
      return ['fertility_supplements', 'ovulation_kits', 'vitamins'];
    }
    if (articleCat == 'health') {
      return ['vitamins', 'supplements', 'medical_devices'];
    }
    return ['general', 'women_essentials'];
  }

  @override
  Widget build(BuildContext context) {
    if (_products == null) {
      return SizedBox(
        height: widget.small ? 140 : 220,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_products!.isEmpty) return const SizedBox.shrink();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Icon(widget.small ? Icons.shopping_bag_outlined : Icons.storefront,
                color: const Color(0xFFE91E63),
                size: widget.small ? 18 : 22),
              const SizedBox(width: 6),
              Expanded(child: Text(widget.title,
                style: TextStyle(
                  fontSize: widget.small ? 14 : 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFE91E63),
                ))),
            ]),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: widget.small ? 150 : 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _products!.length,
              itemBuilder: (context, i) {
                final d = _products![i].data() as Map<String, dynamic>;
                return _productCard(d, _products![i].id, widget.small);
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _productCard(Map<String, dynamic> d, String id, bool small) {
    final imageUrl = d['images']?[0] ?? d['image'] ?? '';
    final name = d['name'] ?? d['title'] ?? '';
    final price = d['price'] ?? 0;
    final currency = d['currency'] ?? 'دج';
    
    return Container(
      width: small ? 110 : 150,
      margin: const EdgeInsets.only(left: 10),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => LandingProductScreen(productId: id),
          )),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              height: small ? 80 : 130,
              child: imageUrl.toString().isNotEmpty
                ? Image.network(imageUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.shopping_bag,
                        size: 40, color: Colors.grey))
                : Container(color: Colors.grey.shade100,
                    child: const Icon(Icons.shopping_bag, size: 40, color: Colors.grey)),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: small ? 11 : 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('$price $currency',
                  style: TextStyle(fontSize: small ? 12 : 14, fontWeight: FontWeight.w800,
                    color: const Color(0xFFE91E63))),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
```

### Commit
```
feat(articles): SmartProductsCarousel — منتجات مشخصنة حسب المقال + المستخدمة
```

---

## المرحلة 4 — Widget مساحة إعلان Google (AdMob Placeholder)

### الملف الجديد
- `lib/widgets/google_ad_slot.dart`

### التنفيذ
```dart
import 'package:flutter/material.dart';

/// مساحة محجوزة لإعلان Google AdMob (تُفعّل لاحقاً بإضافة google_mobile_ads)
class GoogleAdSlot extends StatelessWidget {
  final AdSize size;
  const GoogleAdSlot({Key? key, this.size = AdSize.medium}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // بمجرّد ربط AdMob، استبدل هذا بـ AdWidget
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      height: _height(size),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid, width: 1),
      ),
      child: Center(
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.ad_units, color: Colors.grey.shade400, size: 20),
          const SizedBox(width: 8),
          Text('مساحة إعلانية', 
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
        ]),
      ),
    );
  }

  double _height(AdSize s) {
    switch (s) {
      case AdSize.small: return 60;      // Banner
      case AdSize.medium: return 100;    // Large Banner
      case AdSize.large: return 250;     // Medium Rectangle
    }
  }
}

enum AdSize { small, medium, large }
```

### Commit
```
feat(articles): GoogleAdSlot placeholder جاهز لإعلانات AdMob
```

---

## المرحلة 5 — قارئ المقال الموحّد (`UnifiedArticleReader`)

### الملف الجديد
- `lib/screens/articles/unified_article_reader.dart`

### التنفيذ (المحور الأساسي)
```dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/unified_article.dart';
import '../../services/article_tool_router.dart';
import '../../services/smart_articles_service.dart';
import '../../widgets/smart_products_carousel.dart';
import '../../widgets/google_ad_slot.dart';

class UnifiedArticleReader extends StatefulWidget {
  final UnifiedArticle article;
  const UnifiedArticleReader({Key? key, required this.article}) : super(key: key);
  @override
  State<UnifiedArticleReader> createState() => _UnifiedArticleReaderState();
}

class _UnifiedArticleReaderState extends State<UnifiedArticleReader> {
  final _scrollController = ScrollController();
  double _readProgress = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.maxScrollExtent > 0) {
        final p = _scrollController.position.pixels / 
                  _scrollController.position.maxScrollExtent;
        if ((p - _readProgress).abs() > 0.02) {
          setState(() => _readProgress = p.clamp(0.0, 1.0));
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _shareArticle() async {
    final url = 'https://nabda.online/articles.html?id=${widget.article.id}';
    await Share.share(
      '${widget.article.title}\n\nاقرئي المقال كاملاً:\n$url',
      subject: widget.article.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.article;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Column(children: [
          // شريط التقدّم في القراءة
          LinearProgressIndicator(
            value: _readProgress,
            minHeight: 2,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(a.themeColor),
          ),
          Expanded(child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // 1) الصورة + شريط علوي
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: a.themeColor,
                actions: [
                  IconButton(icon: const Icon(Icons.share), onPressed: _shareArticle),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(fit: StackFit.expand, children: [
                    Image.asset(a.imagePath, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: a.themeColor)),
                    // تدرّج داكن للنص
                    DecoratedBox(decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter, end: Alignment.topCenter,
                        colors: [Colors.black.withOpacity(0.55), Colors.transparent],
                      ),
                    )),
                    // Badge
                    if (a.badge != null) Positioned(
                      bottom: 16, right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(a.badge!, 
                          style: TextStyle(color: a.themeColor, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  ]),
                ),
              ),
              // 2) العنوان + الميتا
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(a.iconEmoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: a.themeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(a.categoryName,
                        style: TextStyle(color: a.themeColor, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Text(a.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.4)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(child: Text(a.author, 
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
                    Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(a.readTime, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ]),
                  const SizedBox(height: 12),
                  if (a.summary.isNotEmpty) Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: a.themeColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border(right: BorderSide(color: a.themeColor, width: 4)),
                    ),
                    child: Text(a.summary,
                      style: const TextStyle(fontSize: 14, height: 1.6, fontStyle: FontStyle.italic)),
                  ),
                ]),
              )),
              // 3) الأقسام + إعلان في الوسط
              SliverList(delegate: SliverChildBuilderDelegate((context, i) {
                if (i >= a.sections.length) return null;
                
                // إعلان في منتصف المقال
                final middle = a.sections.length ~/ 2;
                if (i == middle && a.sections.length >= 4) {
                  return Column(children: [
                    _buildSection(a.sections[i], a.themeColor),
                    const GoogleAdSlot(size: AdSize.medium),
                    // كاروسال منتجات صغير بعد الإعلان
                    SmartProductsCarousel(
                      articleCategoryId: a.categoryId,
                      title: '🛍️ منتجات ذات صلة',
                      small: true,
                      maxItems: 6,
                    ),
                  ]);
                }
                return _buildSection(a.sections[i], a.themeColor);
              })),
              // 4) بطاقة الأداة إن وُجدت
              if (a.toolTitle != null && a.toolTitle!.isNotEmpty)
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: InkWell(
                    onTap: () => ArticleToolRouter.openTool(context, a.toolType),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [a.themeColor, a.themeColor.withOpacity(0.75)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            ArticleToolRouter.hasRoute(a.toolType)
                              ? Icons.play_arrow : Icons.build,
                            color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(a.toolTitle!, 
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          if (a.toolSubtitle != null) Text(a.toolSubtitle!,
                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
                        ])),
                        const Icon(Icons.arrow_back_ios, color: Colors.white, size: 16),
                      ]),
                    ),
                  ),
                )),
              // 5) FAQs
              if (a.faqs.isNotEmpty) SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('❓ أسئلة شائعة', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...a.faqs.map((f) => Card(
                    child: ExpansionTile(
                      title: Text(f.question, 
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      children: [Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(f.answer, style: const TextStyle(height: 1.6)),
                      )],
                    ),
                  )),
                ]),
              )),
              // 6) إعلان قبل كاروسال النهاية
              const SliverToBoxAdapter(child: GoogleAdSlot(size: AdSize.large)),
              // 7) كاروسال كبير: منتجات قد تهمك
              SliverToBoxAdapter(child: SmartProductsCarousel(
                articleCategoryId: a.categoryId,
                title: '🛍️ منتجات قد تهمّك',
                small: false,
                maxItems: 10,
              )),
              // 8) مقالات ذات صلة
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(child: _RelatedSection(article: a)),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          )),
        ]),
      ),
    );
  }

  Widget _buildSection(ArticleSection s, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (s.title.isNotEmpty) Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Container(width: 4, height: 22, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(s.title, 
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ]),
        ),
        Text(s.content, style: const TextStyle(fontSize: 15, height: 1.8)),
      ]),
    );
  }
}

// قسم المقالات ذات الصلة (يستعمل smart articles من نفس الفئة)
class _RelatedSection extends StatefulWidget {
  final UnifiedArticle article;
  const _RelatedSection({required this.article});
  @override
  State<_RelatedSection> createState() => _RelatedSectionState();
}

class _RelatedSectionState extends State<_RelatedSection> {
  List? _related;
  @override
  void initState() {
    super.initState();
    _load();
  }
  Future<void> _load() async {
    try {
      final svc = SmartArticlesService();
      final list = await svc.byCategory(widget.article.categoryId);
      list.shuffle();
      if (!mounted) return;
      setState(() => _related = list.take(6).toList());
    } catch (_) {}
  }
  @override
  Widget build(BuildContext context) {
    if (_related == null || (_related?.isEmpty ?? true)) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('📚 مقالات ذات صلة',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _related!.map<Widget>((a) => Container(
              width: 160,
              margin: const EdgeInsets.only(left: 8),
              child: Card(
                child: InkWell(
                  onTap: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(
                      builder: (_) => UnifiedArticleReader(
                        article: UnifiedArticle.fromSmart(a),
                      ),
                    ));
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(a.iconEmoji, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 6),
                      Text(a.title, maxLines: 3, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ),
              ),
            )).toList(),
          ),
        ),
      ]),
    );
  }
}
```

### Commit
```
feat(articles): UnifiedArticleReader — قارئ موحّد بتصميم فاخر + أدوات + منتجات + إعلانات
```

---

## المرحلة 6 — استبدال الشاشات القديمة بالقارئ الموحّد

### التغييرات المطلوبة

**1. `lib/screens/articles/article_detail_screen.dart`** — تحويله لـwrapper:
```dart
import 'package:flutter/material.dart';
import '../../models/smart_article.dart';
import '../../models/unified_article.dart';
import 'unified_article_reader.dart';

class ArticleDetailScreen extends StatelessWidget {
  final SmartArticle article;
  const ArticleDetailScreen({Key? key, required this.article}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return UnifiedArticleReader(article: UnifiedArticle.fromSmart(article));
  }
}
```

**2. في `lib/screens/pregnancy/discover_articles_screen.dart`** — عند فتح مقال:
```dart
// بدل التصميم القديم:
Navigator.push(context, MaterialPageRoute(
  builder: (_) => UnifiedArticleReader(
    article: UnifiedArticle.fromDiscover(
      title: article.title,
      content: article.content,
      emoji: article.emoji,
      color: article.gradientStart,
      image: article.image,
      category: categoryName,
      index: articleIndex,
    ),
  ),
));
```

**3. في `lib/screens/pregnancy/pregnancy_weeks_screen.dart`** — عند فتح مقال متخصّص:
```dart
// عند فتح SpecArticle:
Navigator.push(context, MaterialPageRoute(
  builder: (_) => UnifiedArticleReader(
    article: UnifiedArticle.fromSpecialized(
      topic: topicKey,
      title: specArticle.title,
      body: specArticle.body,
      index: articleIndex,
    ),
  ),
));
```

**4. لملفات المقالات الدينية في `lib/data/religious_articles.dart`** — أنشئ شاشة عرض:
```dart
// إنشاء lib/screens/articles/religious_articles_screen.dart
// تعرض قائمة المقالات الدينية وتفتحها بـ UnifiedArticleReader
```

### Commit
```
refactor(articles): توحيد كل شاشات عرض المقالات على UnifiedArticleReader
```

---

## 📋 قائمة تحقّق نهائية

- [ ] `UnifiedArticle` model يعمل مع 4 مصادر (smart, specialized, religious, discover)
- [ ] `ArticleToolRouter` يفتح الأدوات الصحيحة بلا crash
- [ ] `SmartProductsCarousel` يقرأ ملف المستخدمة ويعرض منتجات مطابقة
- [ ] `GoogleAdSlot` يظهر بمساحة واضحة (grey placeholder)
- [ ] `UnifiedArticleReader` يعرض كل الأقسام بالترتيب:
  - Hero image + badge
  - Meta (المؤلّف، الوقت، الفئة)
  - Summary highlight
  - Sections
  - إعلان في الوسط + كاروسال منتجات صغير
  - Tool card (إن وُجد) — قابل للضغط
  - FAQs قابلة للطي
  - إعلان قبل النهاية
  - كاروسال منتجات كبير
  - مقالات ذات صلة
- [ ] الشاشات القديمة كلّها تستعمل `UnifiedArticleReader`
- [ ] `flutter analyze` = 0 errors

---

## ⚠️ ملاحظات للمُنفّذ

1. **لا تحذف الشاشات القديمة** — فقط استبدل ما بداخلها بـwrapper يستدعي `UnifiedArticleReader`
2. **إن لم توجد منتجات مطابقة في Firestore** — الكاروسال يختفي تلقائياً (return SizedBox.shrink)
3. **الإعلانات ستكون placeholder grey** — عند تفعيل AdMob لاحقاً، استبدل `GoogleAdSlot` بـ`AdWidget`
4. **`admin_panel_screen.dart` خطر الاقتطاع** — استعمل Python + read all → modify → cp
5. رسائل commit عربية مطابقة للمذكورة

---

## 🎁 مكافأة اختيارية

**قسم منتج مقترح ذكي:** استخدم Firestore query تعتمد على:
- `article.categoryId`
- `user.lifeStage` (pregnant / has_baby / trying / cycle)
- `user.pregnancyWeek` (لعرض منتجات مطابقة للأسبوع الحالي)
- `user.babyAgeMonths` (لعرض ألعاب/ملابس مناسبة للعمر)

**مثال:** حامل في الأسبوع 30 تفتح مقالاً عن حقيبة الولادة → كاروسال يعرض «حقيبة أم مثالية + ملابس مولود مقاس صفر + قطن + مناديل».

---

*هذا الملف مكتفٍ بذاته. الصقيه لـ Antigravity كـ initial prompt.*
