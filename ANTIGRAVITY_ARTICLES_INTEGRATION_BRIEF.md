# خطة Antigravity — دمج 2,500 مقال في تطبيق وموقع نبضة

> **موجّه إلى:** Antigravity / أي AI coding agent
> **المشروع:** `C:\nabda_app`
> **الهدف:** دمج مقالات موسوعة نبضة (2,500) في التطبيق Flutter والموقع Firebase Hosting بحيث تظهر كل الشاشات، موزّعة على 6 تصنيفات، مع نظام بحث وترقيم
> **المصدر:** `assets/data/smart_2500_articles.json` (17.6 MB — موجود مسبقاً)
> **المدة المتوقّعة:** 6-8 ساعات عمل مركّز
> **المخرجات:** 8 مراحل، كل مرحلة commit منفصل

---

## 📐 بنية البيانات المتوفّرة

**الملف:** `assets/data/smart_2500_articles.json` — Dict فيه:
- `count`: 2500
- `version`: 4.0.0
- `last_updated`: 2026-09-03
- `categories_distribution`: توزيع المقالات على 6 فئات
- `articles`: مصفوفة 2500 عنصر

**كل مقال يحتوي:**
```json
{
  "id": "smart_500_001",
  "categoryId": "fertility",
  "categoryName": "التبويض والتخطيط للحمل",
  "title": "...",
  "readTime": "7 دقائق",
  "author": "فريق التحرير الطبي — نبضة",
  "badge": "الأكثر قراءة 🔥",
  "summary": "...",
  "iconEmoji": "🌸",
  "themeColorHex": "#9C27B0",
  "sections": [{"title": "...", "content": "..."}, ...],
  "faqs": [{"question": "...", "answer": "..."}, ...],
  "toolType": "ovulation_calc",
  "toolTitle": "حاسبة أيام التبويض",
  "toolSubtitle": "...",
  "sourceUrl": "https://nabda.app/article/...",
  "originalViews": 5321,
  "imagePath": "assets/images/articles/smart_500_001.jpg",
  "photoTag": "ovulation_calendar"
}
```

## 🗺️ خريطة التصنيفات

| categoryId | categoryName | عدد |
|---|---|---|
| `pregnancy` | الحمل والولادة | 1126 |
| `beauty` | جمالي وعنايتي | 762 |
| `marriage` | العلاقة الزوجية والسكينة | 312 |
| `fertility` | التبويض والتخطيط للحمل | 176 |
| `womens_health` | صحة المرأة والرشاقة | 115 |
| `baby_care` | رعاية وتطور الرضيع | 9 |

**تحذير:** بعض المقالات في التصنيفات القديمة في التطبيق (specialized_articles) قد تتداخل مع هذه. **لا تحذفها** — اعرض الاثنين معاً.

---

## ⚠️ المرحلة 0 — تنظيف بيانات المقالات (إجباري قبل أي شيء آخر)

### السياق
المقالات مأخوذة من موقع منافس (الملكة) وفيها:
- **2500 sourceUrl** يشير إلى `nabda.app` (رابط قديم/خاطئ) — يجب تحويلها إلى `nabda.online`
- **ألوان الملكة** (`#E040FB`، `#9C27B0`، `#4CAF50`، `#00BCD4`، `#FF4081`) — يجب تبديلها بألوان نبضة الرسمية
- كلمة «ملكة» تظهر 14 مرّة **بمعنى إيجابي للأنثى فقط** (تمكين نسائي) — **لا تُغيَّر**

### الملف الجديد
- `scripts/clean_articles_data.py` — سكربت تنظيف يعمل مرّة واحدة

### التنفيذ الكامل
```python
"""
تنظيف smart_2500_articles.json من مراجع «الملكة» + توحيد الألوان مع هوية نبضة.
يعمل مرّة واحدة قبل التكامل مع التطبيق.

الاستخدام:
    cd C:\\nabda_app
    python scripts/clean_articles_data.py
"""
import json
import re
import shutil
from pathlib import Path
from datetime import datetime

SRC = Path('assets/data/smart_2500_articles.json')
BACKUP = Path(f'assets/data/smart_2500_articles.backup_{datetime.now():%Y%m%d_%H%M%S}.json')

# ───────────── الاستبدالات النصّية ─────────────
TEXT_REPLACEMENTS = {
    # الرابط القديم → الحالي (nabda.app لم يعد نطاقنا)
    'https://nabda.app/': 'https://nabda.online/',
    'http://nabda.app/': 'https://nabda.online/',
    'nabda.app/': 'nabda.online/',
    # أي إشارة صريحة لموقع منافس (لم نجد شيئاً محدّداً لكن نتحصّن)
    'malekah.info': 'nabda.online',
    'moqedma.com': 'nabda.online',
    # روابط المصادر الطبية العامّة — نُبقيها كما هي
}

# ───────────── تحويل الألوان (Malika/random → Nabda official) ─────────────
COLOR_MAP = {
    # الوردي الأساسي (pregnancy) — نفس لون نبضة، نُبقيه
    '#E91E63': '#E91E63',
    # وردي زاهي (beauty) → وردي ناعم أهدأ يليق بالجمال
    '#FF4081': '#FF6090',
    # فوشيا صاخب (marriage) → روز أنثوي هادئ
    '#E040FB': '#EC407A',
    # بنفسجي غامق (fertility) → لافندر أنثوي (نبضة الثانوي)
    '#9C27B0': '#7E57C2',
    # أخضر (womens_health) → تركوازي نبضة الرسمي!
    '#4CAF50': '#00897B',
    # سماوي (baby_care) → أزرق فاتح لطيف
    '#00BCD4': '#29B6F6',
    # حالات نادرة أخرى نأخذها لألوان نبضة
    '#e42558': '#E91E63',  # Malika primary → Nabda pink
    '#008299': '#00897B',  # Malika teal → Nabda teal
    '#ff6c93': '#FF6090',  # Malika soft pink → Nabda soft pink
    '#4b5ab9': '#7E57C2',  # Malika purple → Nabda lavender
}


def clean_text(text: str) -> str:
    """يطبّق الاستبدالات النصية على أي نصّ."""
    if not isinstance(text, str):
        return text
    for old, new in TEXT_REPLACEMENTS.items():
        text = text.replace(old, new)
    return text


def clean_color(hex_color: str) -> str:
    """يحوّل ألوان الملكة/الملوّنة إلى ألوان نبضة الرسمية."""
    if not isinstance(hex_color, str):
        return hex_color
    upper = hex_color.upper()
    # ابحث بالحالة الأصلية والـuppercase
    if hex_color in COLOR_MAP:
        return COLOR_MAP[hex_color]
    if upper in COLOR_MAP:
        return COLOR_MAP[upper]
    # للألوان غير المعروفة، اتركها كما هي
    return hex_color


def clean_article(article: dict) -> dict:
    """ينظّف مقالاً واحداً: النصوص + الألوان."""
    # الحقول النصّية العادية
    for key in ['title', 'summary', 'author', 'sourceUrl', 'toolTitle', 'toolSubtitle', 'originalTitle']:
        if key in article and article[key]:
            article[key] = clean_text(article[key])
    # اللون
    if 'themeColorHex' in article:
        article['themeColorHex'] = clean_color(article['themeColorHex'])
    # الأقسام
    for section in article.get('sections', []) or []:
        section['title'] = clean_text(section.get('title', ''))
        section['content'] = clean_text(section.get('content', ''))
    # الأسئلة الشائعة
    for faq in article.get('faqs', []) or []:
        faq['question'] = clean_text(faq.get('question', ''))
        faq['answer'] = clean_text(faq.get('answer', ''))
    return article


def main():
    print(f"═══ تنظيف {SRC} ═══")
    if not SRC.exists():
        print(f"❌ الملف غير موجود: {SRC}")
        return

    # نسخة احتياطية
    shutil.copy(SRC, BACKUP)
    print(f"✓ نسخة احتياطية: {BACKUP.name}")

    # تحميل
    with SRC.open('r', encoding='utf-8') as f:
        data = json.load(f)
    articles = data.get('articles', [])
    print(f"✓ تحميل {len(articles)} مقال")

    # عدّ التغييرات قبل
    counters = {'urls_changed': 0, 'colors_changed': 0}
    for a in articles:
        old_url = a.get('sourceUrl', '')
        old_color = a.get('themeColorHex', '')
        clean_article(a)
        if a.get('sourceUrl', '') != old_url:
            counters['urls_changed'] += 1
        if a.get('themeColorHex', '') != old_color:
            counters['colors_changed'] += 1

    # حفظ
    with SRC.open('w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"\n✓ {counters['urls_changed']} رابط nabda.app → nabda.online")
    print(f"✓ {counters['colors_changed']} لون محوّل لألوان نبضة")
    print(f"\n✓ الملف مُحدَّث: {SRC}")
    print(f"  الحجم: {SRC.stat().st_size / 1024 / 1024:.1f} MB")


if __name__ == '__main__':
    main()
```

### التنفيذ
```cmd
cd C:\nabda_app
python scripts/clean_articles_data.py
```

### النتيجة المتوقّعة
```
═══ تنظيف assets/data/smart_2500_articles.json ═══
✓ نسخة احتياطية: smart_2500_articles.backup_YYYYMMDD_HHMMSS.json
✓ تحميل 2500 مقال

✓ 2500 رابط nabda.app → nabda.online
✓ 1374 لون محوّل لألوان نبضة

✓ الملف مُحدَّث: assets/data/smart_2500_articles.json
```

### معايير القبول
- [ ] النسخة الاحتياطية `smart_2500_articles.backup_*.json` موجودة (في حال أردنا الرجوع)
- [ ] `grep 'nabda.app' assets/data/smart_2500_articles.json` = صفر نتائج
- [ ] `grep -o '"themeColorHex":"[^"]*"' | sort -u` يعرض فقط ألوان نبضة الرسمية:
  - `#E91E63` (pink)
  - `#FF6090` (soft pink)
  - `#EC407A` (rose)
  - `#7E57C2` (lavender)
  - `#00897B` (teal)
  - `#29B6F6` (light blue)

### تحديث web/articles.html (إجباري بعد المرحلة 0)

بعد تنظيف JSON، أعد بناء صفحة الويب بالألوان الجديدة:

```cmd
python scripts/build_web_articles_portal.py
```

**تحديث CSS في `web/articles.html`** (إذا كان build script لا يفعل هذا تلقائياً):
- `#e42558` → `#E91E63`
- `#008299` → `#00897B`
- `#ff6c93` → `#FF6090`
- `#4b5ab9` → `#7E57C2`

استعمل sed أو find-replace في `scripts/build_web_articles_portal.py` لتحديث CSS constants.

### Commit
```
chore(articles): تنظيف بيانات موسوعة 2500 مقال + توحيد الألوان مع هوية نبضة

- تحويل 2500 رابط nabda.app → nabda.online
- توحيد الألوان: 1374 لون → ألوان نبضة الرسمية (#E91E63، #00897B، إلخ)
- الاحتفاظ بكلمة «ملكة» (استعمال إيجابي للأنثى، ليس إشارة لموقع منافس)
- نسخة احتياطية في smart_2500_articles.backup_*.json
```

---

## 📐 قواعد التنفيذ

**قبل البدء:**
1. اقرأ `CLAUDE.md` و `brand.md` و `NABDA_PROJECT_HISTORY.md`
2. اقرأ `article_template.md` لفهم نمط العرض المفضّل
3. **الملف الكبير (`smart_2500_articles.json` 17.6 MB) يجب معالجته بحذر** — لا تُحمّل كل شيء في الذاكرة إلا عند الضرورة

**أثناء التنفيذ:**
- **لا تعدّل `main.dart` مباشرة** — استعمل ملفات منفصلة في `lib/screens/articles/`
- بعد كل مرحلة: `flutter analyze` = 0 errors
- commits عربية منفصلة بالنموذج المذكور في كل مرحلة

---

## المرحلة 1 — نموذج البيانات SmartArticle

### الملفات الجديدة
- `lib/models/smart_article.dart`

### التنفيذ
```dart
import 'package:flutter/material.dart';

class SmartArticle {
  final String id;
  final String originalId;
  final int rank;
  final String categoryId;
  final String categoryName;
  final String title;
  final String? originalTitle;
  final String readTime;
  final String author;
  final String? badge;
  final String summary;
  final String iconEmoji;
  final Color themeColor;
  final List<ArticleSection> sections;
  final List<ArticleFaq> faqs;
  final String? toolType;
  final String? toolTitle;
  final String? toolSubtitle;
  final String? sourceUrl;
  final int originalViews;
  final String imagePath;
  final String? photoTag;

  const SmartArticle({
    required this.id,
    required this.originalId,
    required this.rank,
    required this.categoryId,
    required this.categoryName,
    required this.title,
    this.originalTitle,
    required this.readTime,
    required this.author,
    this.badge,
    required this.summary,
    required this.iconEmoji,
    required this.themeColor,
    required this.sections,
    required this.faqs,
    this.toolType,
    this.toolTitle,
    this.toolSubtitle,
    this.sourceUrl,
    required this.originalViews,
    required this.imagePath,
    this.photoTag,
  });

  factory SmartArticle.fromJson(Map<String, dynamic> json) {
    final hex = (json['themeColorHex'] as String? ?? '#00897B').replaceAll('#', '');
    return SmartArticle(
      id: json['id'] ?? '',
      originalId: json['originalId']?.toString() ?? '',
      rank: json['rank'] ?? 0,
      categoryId: json['categoryId'] ?? '',
      categoryName: json['categoryName'] ?? '',
      title: json['title'] ?? '',
      originalTitle: json['originalTitle'],
      readTime: json['readTime'] ?? '5 دقائق',
      author: json['author'] ?? 'فريق نبضة',
      badge: json['badge'],
      summary: json['summary'] ?? '',
      iconEmoji: json['iconEmoji'] ?? '📖',
      themeColor: Color(int.parse('FF$hex', radix: 16)),
      sections: (json['sections'] as List? ?? [])
          .map((s) => ArticleSection.fromJson(s))
          .toList(),
      faqs: (json['faqs'] as List? ?? [])
          .map((f) => ArticleFaq.fromJson(f))
          .toList(),
      toolType: json['toolType'],
      toolTitle: json['toolTitle'],
      toolSubtitle: json['toolSubtitle'],
      sourceUrl: json['sourceUrl'],
      originalViews: json['originalViews'] ?? 0,
      imagePath: json['imagePath'] ?? 'assets/images/logo_nabda.png',
      photoTag: json['photoTag'],
    );
  }
}

class ArticleSection {
  final String title;
  final String content;
  const ArticleSection({required this.title, required this.content});
  factory ArticleSection.fromJson(Map<String, dynamic> j) =>
      ArticleSection(title: j['title'] ?? '', content: j['content'] ?? '');
}

class ArticleFaq {
  final String question;
  final String answer;
  const ArticleFaq({required this.question, required this.answer});
  factory ArticleFaq.fromJson(Map<String, dynamic> j) =>
      ArticleFaq(question: j['question'] ?? '', answer: j['answer'] ?? '');
}

/// خريطة categoryId → categoryName (للتوحيد)
const Map<String, String> categoryNames = {
  'pregnancy': 'الحمل والولادة',
  'beauty': 'جمالي وعنايتي',
  'marriage': 'العلاقة الزوجية والسكينة',
  'fertility': 'التبويض والتخطيط للحمل',
  'womens_health': 'صحة المرأة والرشاقة',
  'baby_care': 'رعاية وتطور الرضيع',
};

/// خريطة categoryId → emoji مميز
const Map<String, String> categoryEmojis = {
  'pregnancy': '🤰',
  'beauty': '💄',
  'marriage': '💕',
  'fertility': '🌸',
  'womens_health': '💗',
  'baby_care': '👶',
};

/// خريطة categoryId → لون ثيم — ألوان نبضة الرسمية بعد التنظيف
/// (متطابقة مع القيم في smart_2500_articles.json بعد تشغيل المرحلة 0)
const Map<String, int> categoryColors = {
  'pregnancy': 0xFFE91E63,       // Nabda pink (وردي أساسي)
  'beauty': 0xFFFF6090,          // Nabda soft pink (وردي ناعم)
  'marriage': 0xFFEC407A,        // rose (روز أنثوي)
  'fertility': 0xFF7E57C2,       // Nabda lavender (لافندر)
  'womens_health': 0xFF00897B,   // Nabda teal (تركوازي نبضة الرسمي)
  'baby_care': 0xFF29B6F6,       // light blue (أزرق لطيف للرضع)
};

/// ألوان نبضة الرسمية للمرجع
const int kNabdaPink = 0xFFE91E63;        // اللون الأساسي
const int kNabdaTeal = 0xFF00897B;         // اللون الثانوي
const int kNabdaCream = 0xFFFFF8FB;        // خلفية دافئة
const int kNabdaSoftPink = 0xFFFF6090;     // وردي ناعم
const int kNabdaLavender = 0xFF7E57C2;     // بنفسجي أنثوي
```

### Commit
```
feat(models): إضافة نموذج SmartArticle لموسوعة 2500 مقال
```

---

## المرحلة 2 — SmartArticlesService (خدمة تحميل ذكية)

### الملف الجديد
- `lib/services/smart_articles_service.dart`

### الفكرة
الملف 17.6 MB كبير — لا نحمّله كاملاً في الذاكرة. نحمّله مرّة واحدة عند أوّل استعمال، نخزّنه في singleton، ونعرض النتائج بترقيم.

### التنفيذ
```dart
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/smart_article.dart';

class SmartArticlesService {
  static final SmartArticlesService _instance = SmartArticlesService._internal();
  factory SmartArticlesService() => _instance;
  SmartArticlesService._internal();

  List<SmartArticle>? _cache;
  bool _loading = false;

  /// تحميل جميع المقالات (مرة واحدة، ثم مخزّنة)
  Future<List<SmartArticle>> loadAll() async {
    if (_cache != null) return _cache!;
    if (_loading) {
      // انتظار جولة التحميل الجارية
      while (_loading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _cache ?? [];
    }
    _loading = true;
    try {
      final jsonStr = await rootBundle.loadString('assets/data/smart_2500_articles.json');
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final list = (data['articles'] as List)
          .map((a) => SmartArticle.fromJson(a as Map<String, dynamic>))
          .toList();
      _cache = list;
      return list;
    } finally {
      _loading = false;
    }
  }

  /// مقالات حسب التصنيف
  Future<List<SmartArticle>> byCategory(String categoryId) async {
    final all = await loadAll();
    return all.where((a) => a.categoryId == categoryId).toList();
  }

  /// أعلى المقالات مشاهدة (top N)
  Future<List<SmartArticle>> topViewed({int limit = 10}) async {
    final all = await loadAll();
    final sorted = [...all]..sort((a, b) => b.originalViews.compareTo(a.originalViews));
    return sorted.take(limit).toList();
  }

  /// بحث في العناوين والملخصات
  Future<List<SmartArticle>> search(String query) async {
    final all = await loadAll();
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    return all.where((a) =>
      a.title.toLowerCase().contains(q) ||
      a.summary.toLowerCase().contains(q) ||
      a.categoryName.toLowerCase().contains(q)
    ).toList();
  }

  /// مقالات مقترحة (متعلقة) — بناءً على categoryId
  Future<List<SmartArticle>> relatedTo(SmartArticle article, {int limit = 6}) async {
    final all = await loadAll();
    final same = all.where((a) => a.categoryId == article.categoryId && a.id != article.id).toList();
    same.shuffle();
    return same.take(limit).toList();
  }

  /// إحصائيات
  Future<Map<String, int>> categoryStats() async {
    final all = await loadAll();
    final stats = <String, int>{};
    for (final a in all) {
      stats[a.categoryId] = (stats[a.categoryId] ?? 0) + 1;
    }
    return stats;
  }
}
```

### Commit
```
feat(services): إضافة SmartArticlesService لإدارة موسوعة 2500 مقال
```

---

## المرحلة 3 — شاشة الموسوعة الرئيسية (Encyclopedia Hub)

### الملف الجديد
- `lib/screens/articles/articles_hub_screen.dart`

### التنفيذ الكامل
```dart
import 'package:flutter/material.dart';
import '../../models/smart_article.dart';
import '../../services/smart_articles_service.dart';
import 'articles_list_screen.dart';
import 'article_detail_screen.dart';
import 'articles_search_screen.dart';

class ArticlesHubScreen extends StatefulWidget {
  const ArticlesHubScreen({Key? key}) : super(key: key);
  @override
  State<ArticlesHubScreen> createState() => _ArticlesHubScreenState();
}

class _ArticlesHubScreenState extends State<ArticlesHubScreen> {
  final _service = SmartArticlesService();
  Map<String, int>? _stats;
  List<SmartArticle>? _featured;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await _service.categoryStats();
    final featured = await _service.topViewed(limit: 10);
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _featured = featured;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('موسوعة نبضة', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFFE91E63),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const ArticlesSearchScreen(),
              )),
            ),
          ],
        ),
        body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE91E63)))
          : ListView(children: [
              _buildHero(),
              const SizedBox(height: 16),
              _buildCategoriesGrid(),
              const SizedBox(height: 24),
              _buildFeaturedSection(),
              const SizedBox(height: 32),
            ]),
      ),
    );
  }

  Widget _buildHero() {
    final total = _stats?.values.fold(0, (a, b) => a + b) ?? 2500;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFFAB47BC)],
        ),
      ),
      child: Column(children: [
        const Icon(Icons.auto_stories, size: 40, color: Colors.white),
        const SizedBox(height: 12),
        Text('$total مقال طبي موثّق',
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('كل ما تحتاجينه لصحتك ورعاية طفلك',
          style: TextStyle(color: Colors.white70, fontSize: 14)),
      ]),
    );
  }

  Widget _buildCategoriesGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.3,
        children: categoryNames.entries.map((entry) {
          final categoryId = entry.key;
          final name = entry.value;
          final count = _stats?[categoryId] ?? 0;
          final emoji = categoryEmojis[categoryId] ?? '📖';
          final color = Color(categoryColors[categoryId] ?? 0xFFE91E63);
          return InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ArticlesListScreen(categoryId: categoryId, categoryName: name),
            )),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(colors: [color.withOpacity(0.85), color]),
                boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 30)),
                  const SizedBox(height: 6),
                  Text(name, textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('$count مقال',
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeaturedSection() {
    if (_featured == null || _featured!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🔥 الأكثر قراءة',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._featured!.take(5).map((a) => _articleTile(a)).toList(),
      ]),
    );
  }

  Widget _articleTile(SmartArticle a) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: a.themeColor.withOpacity(0.15),
        child: Text(a.iconEmoji, style: const TextStyle(fontSize: 22)),
      ),
      title: Text(a.title, maxLines: 2, overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      subtitle: Row(children: [
        const Icon(Icons.visibility, size: 12, color: Colors.grey),
        const SizedBox(width: 4),
        Text('${a.originalViews}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(width: 12),
        const Icon(Icons.schedule, size: 12, color: Colors.grey),
        const SizedBox(width: 4),
        Text(a.readTime, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ]),
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => ArticleDetailScreen(article: a),
      )),
    ),
  );
}
```

### Commit
```
feat(articles): شاشة الموسوعة الرئيسية مع 6 تصنيفات + الأكثر قراءة
```

---

## المرحلة 4 — شاشة قائمة المقالات حسب تصنيف

### الملف الجديد
- `lib/screens/articles/articles_list_screen.dart`

### التنفيذ
```dart
import 'package:flutter/material.dart';
import '../../models/smart_article.dart';
import '../../services/smart_articles_service.dart';
import 'article_detail_screen.dart';

class ArticlesListScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  const ArticlesListScreen({Key? key, required this.categoryId, required this.categoryName}) : super(key: key);
  @override
  State<ArticlesListScreen> createState() => _ArticlesListScreenState();
}

class _ArticlesListScreenState extends State<ArticlesListScreen> {
  final _service = SmartArticlesService();
  final _controller = ScrollController();
  List<SmartArticle> _all = [];
  List<SmartArticle> _shown = [];
  int _page = 0;
  static const _pageSize = 20;
  bool _loading = true;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _load();
    _controller.addListener(_onScroll);
  }

  Future<void> _load() async {
    final list = await _service.byCategory(widget.categoryId);
    if (!mounted) return;
    setState(() {
      _all = list;
      _shown = list.take(_pageSize).toList();
      _loading = false;
    });
  }

  void _onScroll() {
    if (_loadingMore || _shown.length >= _all.length) return;
    if (_controller.position.pixels > _controller.position.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  void _loadMore() {
    setState(() {
      _loadingMore = true;
      _page++;
      _shown = _all.take((_page + 1) * _pageSize).toList();
      _loadingMore = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.categoryName),
          backgroundColor: const Color(0xFFE91E63),
          foregroundColor: Colors.white,
        ),
        body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE91E63)))
          : ListView.builder(
              controller: _controller,
              padding: const EdgeInsets.all(12),
              itemCount: _shown.length + 1,
              itemBuilder: (context, i) {
                if (i == _shown.length) {
                  if (_shown.length >= _all.length) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: Text('عرضتِ كل المقالات ✓', style: TextStyle(color: Colors.grey))),
                    );
                  }
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final a = _shown[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ArticleDetailScreen(article: a),
                    )),
                    child: Row(children: [
                      Container(
                        width: 100, height: 120,
                        color: a.themeColor.withOpacity(0.15),
                        child: Image.asset(a.imagePath, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(a.iconEmoji, style: const TextStyle(fontSize: 40)),
                          )),
                      ),
                      Expanded(child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          if (a.badge != null) Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: a.themeColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(a.badge!, style: TextStyle(fontSize: 10, color: a.themeColor, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 6),
                          Text(a.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(a.summary, maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          const SizedBox(height: 6),
                          Row(children: [
                            Icon(Icons.schedule, size: 12, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(a.readTime, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            const SizedBox(width: 12),
                            Icon(Icons.visibility, size: 12, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text('${a.originalViews}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          ]),
                        ]),
                      )),
                    ]),
                  ),
                );
              },
            ),
      ),
    );
  }
}
```

### Commit
```
feat(articles): شاشة قائمة المقالات مع lazy loading + ترقيم
```

---

## المرحلة 5 — شاشة تفاصيل المقال (Article Reader)

### الملف الجديد
- `lib/screens/articles/article_detail_screen.dart`

### التنفيذ
عرض كامل للمقال بتصميم شبيه لموقع الملكة:
- Hero image + عنوان + كاتب + شارة + وقت قراءة + مشاهدات
- أزرار مشاركة (نسخ، واتساب، تويتر)
- المحتوى: sections (H2) + FAQs قابلة للطي
- بطاقة الأداة المرتبطة (إذا وجدت toolType)
- مقالات ذات صلة في الأسفل

الكود الكامل في قسم منفصل — راجع `web/articles.html` للتصميم المرجعي.

### Commit
```
feat(articles): شاشة تفاصيل المقال مع مشاركة + FAQs + مقالات ذات صلة
```

---

## المرحلة 6 — شاشة البحث

### الملف الجديد
- `lib/screens/articles/articles_search_screen.dart`

### التنفيذ (مبسّط)
```dart
class ArticlesSearchScreen extends StatefulWidget {
  const ArticlesSearchScreen({Key? key}) : super(key: key);
  @override
  State<ArticlesSearchScreen> createState() => _ArticlesSearchScreenState();
}

class _ArticlesSearchScreenState extends State<ArticlesSearchScreen> {
  final _controller = TextEditingController();
  final _service = SmartArticlesService();
  List<SmartArticle> _results = [];
  bool _searching = false;

  Future<void> _search(String q) async {
    if (q.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    final r = await _service.search(q);
    if (!mounted) return;
    setState(() {
      _results = r.take(50).toList();
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFE91E63),
          foregroundColor: Colors.white,
          title: TextField(
            controller: _controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'ابحثي في 2,500 مقال...',
              hintStyle: TextStyle(color: Colors.white70),
              border: InputBorder.none,
            ),
            onChanged: _search,
          ),
        ),
        body: _searching
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
            ? const Center(child: Text('ابدئي بكتابة كلمة للبحث', style: TextStyle(color: Colors.grey)))
            : ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, i) {
                  final a = _results[i];
                  return ListTile(
                    leading: CircleAvatar(backgroundColor: a.themeColor.withOpacity(0.15),
                      child: Text(a.iconEmoji)),
                    title: Text(a.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text(a.categoryName, style: TextStyle(color: a.themeColor, fontSize: 12)),
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ArticleDetailScreen(article: a),
                    )),
                  );
                },
              ),
      ),
    );
  }
}
```

### Commit
```
feat(articles): شاشة البحث في موسوعة 2500 مقال
```

---

## المرحلة 7 — إضافة الموسوعة إلى pubspec + التطبيق الرئيسي

### 7.1 في `pubspec.yaml`
تحقّق أن هذه الأسطر موجودة تحت `assets:`:
```yaml
    - assets/data/smart_2500_articles.json
    - assets/images/articles/
```

### 7.2 في `lib/main.dart` — إضافة زر «الموسوعة» في `_buildExploreGrid()` أو `HomePage`
ابحث عن `_buildExploreGrid` وأضف بطاقة جديدة:
```dart
_exploreCard(
  emoji: '📚',
  title: 'موسوعة نبضة',
  subtitle: '2,500 مقال',
  color: const Color(0xFFE91E63),
  onTap: () => Navigator.push(context, MaterialPageRoute(
    builder: (_) => const ArticlesHubScreen(),
  )),
),
```

### 7.3 استيراد
في أعلى `main.dart`:
```dart
import 'screens/articles/articles_hub_screen.dart';
```

### Commit
```
feat(main): إضافة زر «موسوعة نبضة» في الصفحة الرئيسية
```

---

## المرحلة 8 — الموقع (Web) — دعم Deep-linking من التطبيق

### الحالة الحالية
`web/articles.html` جاهز ويعمل. لكن التطبيق يفتح شاشات Flutter، وليس صفحات الموقع.

### التحسين المطلوب
دعم Deep-linking بحيث:
- من التطبيق: `ArticleDetailScreen` تعرض المحتوى محلياً
- من الموقع (شارك رابط): `https://nabda.online/articles.html?id=smart_500_001` يفتح المقال مباشرة

### 8.1 تعديل `share_plus` في article_detail
```dart
Future<void> _shareArticle(SmartArticle a) async {
  final url = 'https://nabda.online/articles.html?id=${a.id}';
  await Share.share(
    '${a.title}\n\nاقرئي المقال كاملاً في موسوعة نبضة:\n$url',
    subject: a.title,
  );
}
```

### 8.2 تحقّق أن `web/articles.html` يدعم `?id=` (يجب أن يفتح المقال المحدّد)
افتح `scripts/build_web_articles_portal.py` وتأكّد من وجود منطق قراءة `?id` من URL.

### Commit
```
feat(articles): دعم مشاركة الروابط من التطبيق للموقع (deep-linking)
```

---

## 📊 قائمة تحقّق نهائية

- [ ] `SmartArticle` model يعمل مع JSON
- [ ] `SmartArticlesService` يحمّل من assets ويخزّن في cache
- [ ] `ArticlesHubScreen` تعرض 6 تصنيفات + الأكثر قراءة
- [ ] `ArticlesListScreen` تعرض المقالات مع lazy loading
- [ ] `ArticleDetailScreen` تعرض المقال كاملاً (sections + FAQs + tool + share + related)
- [ ] `ArticlesSearchScreen` تبحث في العناوين والملخصات
- [ ] pubspec.yaml يشمل smart_2500_articles.json
- [ ] `HomePage` فيه زر «موسوعة نبضة»
- [ ] رابط المشاركة يفتح المقال على الموقع
- [ ] `flutter analyze` = 0 errors
- [ ] `flutter build apk --release` ينجح

---

## ⚡ أداء متوقّع

- **تحميل أوّل مرة:** 2-3 ثوانٍ (17.6 MB JSON parse)
- **بعد التخزين المؤقّت:** فوري (<100 ms)
- **حجم APK إضافي:** +18 MB (JSON) + مجلد صور المقالات
- **الذاكرة المستهلكة:** ~40-50 MB بعد التحميل

**لو كانت هناك مشاكل أداء:**
- استعمل `compute()` لـ JSON parsing في isolate منفصل
- خزّن نتائج البحث في مؤقّت
- lazy loading للصور (`Image.asset(..., cacheHeight: 200)`)

---

## 🎨 التصميم — ألوان نبضة الرسمية

**ألوان نبضة الأساسية (بعد التنظيف في المرحلة 0):**
- `#E91E63` — وردي نبضة الأساسي (أزرار CTA، شارات التنبيه، عناوين مهمّة)
- `#00897B` — تركوازي نبضة (H2، تصنيفات، الأدوات)
- `#FF6090` — وردي ناعم (روابط، بطاقات جمالية)
- `#7E57C2` — لافندر (تصنيفات فرعية، شارات خصوبة)
- `#EC407A` — روز (زوجية وأنوثة)
- `#29B6F6` — أزرق فاتح (رعاية الرضيع)
- `#FFF8FB` — خلفية دافئة
- `#4A434B` — نصّ أساسي دافئ

كل مقال يحمل `themeColor` خاصّاً به من JSON (نتيجة المرحلة 0 التنظيفية) — استعمله في:
- شارة التصنيف الطافية على البطاقة
- زخارف بداية H2 داخل المقال
- خلفية بطاقة الأداة المرتبطة (بشفافية 0.15)
- زر «اقرئي المقال» في القائمة

**تحذير:** لا تستعمل ألوان الملكة القديمة (`#e42558`، `#008299`، `#ff6c93`، `#4b5ab9`) — استُبدلت في المرحلة 0.

---

*هذا الملف مكتفٍ بذاته. الصقيه لـ Antigravity كـ initial prompt.*
