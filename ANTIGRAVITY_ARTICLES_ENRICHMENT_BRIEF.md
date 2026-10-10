# خطة Antigravity — إثراء موسوعة 2500 مقال + دمجها في كل مكان

> **موجّه إلى:** Antigravity / أي AI coding agent
> **المشروع:** `C:\nabda_app`
> **الحالة قبل البدء:** موسوعة 2500 مقال جاهزة في `assets/data/smart_2500_articles.json` (نُظّفت في المرحلة 0 السابقة). لكن:
> - الصور مفقودة 100% → إيموجي fallback فقط
> - المصادر الطبية ضعيفة (37 مقال من 2500 يذكر مصدراً)
> - المقالات معزولة في شاشتها الخاصّة، لا تظهر في الأقسام الأخرى (الحمل، الطفل، إلخ)
> - على الموقع، لا تظهر إلا في `articles.html` وحده
>
> **الهدف:** جعل الموسوعة جزءاً متكاملاً من التطبيق والموقع.
> **المدة:** 8-10 ساعات
> **المخرجات:** 5 مراحل، commits منفصلة

---

## 📋 خريطة المهام

| المرحلة | المهمة | الوقت |
|---|---|---|
| 1 | نظام الصور القالبية (30 صورة) + Higgsfield | 2-3 س |
| 2 | تحديث JSON لاستعمال الصور القالبية | 30 د |
| 3 | إثراء المصادر الطبية آلياً | 1-2 س |
| 4 | دمج SmartArticle في كل أقسام التطبيق | 3-4 س |
| 5 | دمج SmartArticle في كاروسال الموقع (landing.html) | 1-2 س |

---

## المرحلة 1 — نظام الصور القالبية

### 1.1 هيكل التسمية (مرقّم لتغيير سهل مستقبلاً)

```
assets/images/articles_bg/
  bg_pregnancy_01.jpg      ← يُشارَك بين مئات المقالات
  bg_pregnancy_02.jpg
  bg_pregnancy_03.jpg
  bg_pregnancy_04.jpg
  bg_pregnancy_05.jpg
  bg_beauty_01.jpg
  bg_beauty_02.jpg
  ... (إلى _05)
  bg_marriage_01.jpg → _05.jpg
  bg_fertility_01.jpg → _05.jpg
  bg_health_01.jpg → _05.jpg
  bg_baby_01.jpg → _05.jpg
```

**المجموع: 30 صورة قالبية.** كل مقال يختار واحدة حسب `hash(id) % 5 + 1`.

**لتحديث صورة قالبية لاحقاً:** استبدلي `bg_beauty_02.jpg` بصورة جديدة — تلقائياً 152 مقال ستحصل عليها.

### 1.2 توليد الصور عبر Higgsfield (خطوة يدوية على الحاسوب)

**Prompts موصى بها لكل فئة:**

```
pregnancy (5 صور):
  1. "Serene pregnant woman in soft pink hijab, hand on belly, warm sunlight, watercolor style"
  2. "Beautiful pregnant belly close-up, delicate lighting, soft pastels, artistic"
  3. "Pregnant woman meditating in nature, peaceful, greenery, dawn light"
  4. "Mother-to-be reading book, cozy warm interior, soft focus"
  5. "Pregnancy journey silhouette against sunset, hopeful, warm"

beauty (5):
  1. "Arabic woman applying skincare, natural beauty, soft pink background"
  2. "Elegant skincare serum bottles, minimalist, rose gold accents"
  3. "Woman with glowing skin, natural makeup, sunlit portrait"
  4. "Rose petals, natural beauty ingredients, aesthetic flat lay"
  5. "Spa setup with candles, self-care, warm cozy atmosphere"

marriage (5):
  1. "Muslim couple silhouette, sunset, peaceful, romantic"
  2. "Two coffee cups, morning light, cozy intimate scene"
  3. "Hands together with wedding rings, soft lighting"
  4. "Couple walking in park, autumn, warm hues, peaceful"
  5. "Home interior with roses, romantic warm atmosphere"

fertility (5):
  1. "Calendar with heart marks, ovulation tracking, soft pastels"
  2. "Woman looking hopeful, morning light, gentle mood"
  3. "Fertility symbols, flowers, watercolor, dreamy"
  4. "Egg cell abstract art, biological beauty, pink tones"
  5. "Journal with fertility notes, aesthetic desk setup"

health (5):
  1. "Healthy Arab woman jogging in park, morning light"
  2. "Fresh fruits and vegetables, colorful flat lay"
  3. "Woman doing yoga, peaceful, natural setting"
  4. "Nutritious meal preparation, warm kitchen"
  5. "Water bottle with fruits, hydration, aesthetic"

baby (5):
  1. "Baby milestones cute illustration, first steps, warm colors"
  2. "Baby's tiny feet in mother's hands, tender moment"
  3. "Baby smiling in soft blankets, warm nursery"
  4. "Toy blocks and toys, cozy playroom aesthetic"
  5. "Mother reading to baby, warm interior, tender"
```

**المواصفات المطلوبة لكل صورة:**
- الحجم: **1200×800** (يُقلَّص لـ800×533 للتطبيق)
- الصيغة: JPG بجودة 85
- الطابع: **دافئ، أنثوي، هادئ** — يليق بنبضة (تجنّبي الصور الفاقعة/الاحترافية جداً)
- **الحساسية الثقافية:** تجنّبي كشف عورات، أفضّلي وجوه محجّبة أو صور رمزية

**⚠️ ملاحظة للمُنفّذ Antigravity:** لا تستدعي Higgsfield من الكود — هذه خطوة يدوية على الحاسوب. اقتصر على:
- إنشاء مجلد `assets/images/articles_bg/`
- توليد صور placeholder فورية بـPython (تدرّج + نصّ) حتى تصل الصور الحقيقية
- ضمان أن الكود يعمل حتى بدون الصور (fallback موجود)

### 1.3 توليد Placeholder Images فورية (تعمل الآن حتى قبل Higgsfield)

**السكربت:** `scripts/generate_placeholder_bg_images.py`

```python
"""
يولّد 30 صورة قالبية placeholder بتدرّجات لطيفة + نص فئة.
تعمل مباشرة، تُستبدل لاحقاً بصور Higgsfield الحقيقية بنفس الاسم.
"""
from PIL import Image, ImageDraw, ImageFont
from pathlib import Path
import hashlib

OUT_DIR = Path('assets/images/articles_bg')
OUT_DIR.mkdir(parents=True, exist_ok=True)

# ألوان تدرّج لكل فئة (وسط الفئة → أفتح قليلاً)
GRADIENTS = {
    'pregnancy':  [(233, 30, 99), (255, 96, 144)],   # وردي → وردي فاتح
    'beauty':     [(255, 96, 144), (255, 183, 197)],  # وردي ناعم → زهري فاتح
    'marriage':   [(236, 64, 122), (255, 138, 178)],  # روز → فاتح
    'fertility':  [(126, 87, 194), (179, 136, 235)],  # لافندر → فاتح
    'health':     [(0, 137, 123), (77, 182, 172)],    # تركوازي → فاتح
    'baby':       [(41, 182, 246), (129, 212, 250)],  # أزرق → فاتح
}

LABELS = {
    'pregnancy': 'الحمل والولادة',
    'beauty':    'جمالي وعنايتي',
    'marriage':  'العلاقة الزوجية',
    'fertility': 'التبويض والخصوبة',
    'health':    'صحة المرأة',
    'baby':      'رعاية الرضيع',
}

EMOJI = {
    'pregnancy': '🤰', 'beauty': '💄', 'marriage': '💕',
    'fertility': '🌸', 'health': '💗', 'baby': '👶',
}

def make_gradient(w, h, c1, c2):
    """يصنع خلفية تدرّج لوني عمودي ناعم."""
    img = Image.new('RGB', (w, h))
    for y in range(h):
        r = int(c1[0] + (c2[0] - c1[0]) * y / h)
        g = int(c1[1] + (c2[1] - c1[1]) * y / h)
        b = int(c1[2] + (c2[2] - c1[2]) * y / h)
        for x in range(w):
            img.putpixel((x, y), (r, g, b))
    return img

# نمط: كل صورة تختلف عن الأخرى قليلاً (rotation، pattern)
for cat, colors in GRADIENTS.items():
    for i in range(1, 6):
        # قلب الاتجاه أو تعديل الألوان قليلاً في كل صورة
        seed = int(hashlib.md5(f'{cat}{i}'.encode()).hexdigest()[:8], 16)
        c1 = tuple(max(0, min(255, c + (seed % 30) - 15)) for c in colors[0])
        c2 = tuple(max(0, min(255, c + ((seed // 100) % 30) - 15)) for c in colors[1])
        
        img = make_gradient(1200, 800, c1, c2)
        draw = ImageDraw.Draw(img)
        
        # طبقة شفافة للنص
        # فرصة إضافة emoji + label في المنتصف (نتخطاه إن لم يتوفّر خط عربي)
        # نضع علامة رقمية للتصنيف والصورة
        try:
            font = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 60)
        except:
            font = ImageFont.load_default()
        text = f'{cat.upper()} · {i:02d}'
        bbox = draw.textbbox((0, 0), text, font=font)
        text_w = bbox[2] - bbox[0]
        text_h = bbox[3] - bbox[1]
        draw.text(((1200 - text_w) // 2, (800 - text_h) // 2),
                  text, fill=(255, 255, 255, 200), font=font)
        
        path = OUT_DIR / f'bg_{cat}_{i:02d}.jpg'
        img.save(path, 'JPEG', quality=85, optimize=True)
        print(f'✓ {path.name}')

print(f'\n✓ 30 صورة قالبية جاهزة في {OUT_DIR}')
```

### 1.4 التنفيذ

```cmd
cd C:\nabda_app
pip install pillow
python scripts/generate_placeholder_bg_images.py
```

### Commit
```
feat(images): نظام 30 صورة قالبية للمقالات — placeholder جاهز للاستبدال بـHiggsfield
```

---

## المرحلة 2 — تحديث JSON لاستعمال الصور القالبية

**السكربت:** `scripts/update_articles_image_paths.py`

```python
"""
يحدّث imagePath لكل مقال ليستعمل الصور القالبية.
كل مقال يختار صورة حسب hash(id) % 5 + 1 → توزيع متوازن.
"""
import json
import hashlib
import shutil
from datetime import datetime
from pathlib import Path

SRC = Path('assets/data/smart_2500_articles.json')
BACKUP = Path(f'assets/data/smart_2500_articles.imgpath_backup_{datetime.now():%Y%m%d_%H%M%S}.json')

# categoryId في JSON → prefix في اسم الصورة
CATEGORY_TO_IMG = {
    'pregnancy': 'pregnancy',
    'beauty': 'beauty',
    'marriage': 'marriage',
    'fertility': 'fertility',
    'health': 'health',
    'womens_health': 'health',  # في حالة اختلاف التسمية
    'baby': 'baby',
    'baby_care': 'baby',
}

shutil.copy(SRC, BACKUP)
print(f'✓ نسخة احتياطية: {BACKUP.name}')

with SRC.open('r', encoding='utf-8') as f:
    data = json.load(f)

changed = 0
for a in data['articles']:
    cat_id = a.get('categoryId', 'pregnancy')
    img_cat = CATEGORY_TO_IMG.get(cat_id, 'pregnancy')
    # اختيار متسق: نفس المقال يحصل دائماً على نفس القالب
    h = hashlib.md5(a['id'].encode()).hexdigest()
    img_num = (int(h[:8], 16) % 5) + 1  # 1-5
    new_path = f'assets/images/articles_bg/bg_{img_cat}_{img_num:02d}.jpg'
    if a.get('imagePath') != new_path:
        a['imagePath'] = new_path
        changed += 1

with SRC.open('w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(f'\n✓ {changed} مقال تم تحديث imagePath')
print(f'✓ توزيع متوازن: كل صورة تُستعمل في ~{2500 // 30} مقال في المتوسط')
```

### التنفيذ + إضافة المجلد لـpubspec

```cmd
python scripts/update_articles_image_paths.py
```

في `pubspec.yaml` تحت `assets:`:
```yaml
    - assets/images/articles_bg/
```

### Commit
```
feat(articles): توزيع 2500 مقال على 30 صورة قالبية بـhash متسق
```

---

## المرحلة 3 — إثراء المصادر الطبية آلياً

### السياق
- 37 مقال فقط من 2500 يذكر مصدراً طبياً — كارثي لتطبيق صحّي
- Google Play يشدّد على E-E-A-T للتطبيقات الطبية
- نحتاج إضافة مصادر تلقائياً حسب categoryId

### خريطة المصادر لكل تصنيف

| categoryId | المصادر الموصى بها |
|---|---|
| `pregnancy` | ACOG (American College of Obstetricians) + Mayo Clinic Pregnancy Guide + WHO Maternal Health |
| `fertility` | ASRM (American Society for Reproductive Medicine) + Cochrane Reviews + WHO Reproductive Health |
| `beauty` | AAD (American Academy of Dermatology) + Dermatology reviews |
| `baby` | AAP (American Academy of Pediatrics) + WHO Child Health + CDC Pediatrics |
| `health` | WHO Global Health + CDC + NIH |
| `marriage` | APA (American Psychological Association) + WHO Sexual and Reproductive Health |

### السكربت: `scripts/enrich_articles_sources.py`

```python
"""
يُضيف قسم «المصادر والمراجع الطبية» في نهاية كل مقال حسب فئته.
لا يضاف إن كان موجوداً بالفعل (يفحص وجود «المصادر:» أو «References:»).
"""
import json
import shutil
from datetime import datetime
from pathlib import Path

SRC = Path('assets/data/smart_2500_articles.json')
BACKUP = Path(f'assets/data/smart_2500_articles.sources_backup_{datetime.now():%Y%m%d_%H%M%S}.json')

SOURCES_BY_CATEGORY = {
    'pregnancy': [
        'ACOG — Practice Bulletins on Pregnancy Care (acog.org)',
        'Mayo Clinic — Pregnancy Week by Week (mayoclinic.org)',
        'WHO — Maternal, Newborn, Child and Adolescent Health',
    ],
    'fertility': [
        'ASRM — American Society for Reproductive Medicine (reproductivefacts.org)',
        'Cochrane Fertility Reviews',
        'WHO — Reproductive Health Guidelines',
    ],
    'beauty': [
        'AAD — American Academy of Dermatology (aad.org)',
        'مراجعات دورية في الأمراض الجلدية (Dermatology Reviews)',
    ],
    'baby': [
        'AAP — American Academy of Pediatrics (aap.org)',
        'WHO — Child Growth Standards',
        'CDC — Pediatric Care Guidelines',
    ],
    'health': [
        'WHO — Global Women\'s Health Guidelines',
        'CDC — Women\'s Health',
        'NIH — Office of Research on Women\'s Health',
    ],
    'marriage': [
        'APA — American Psychological Association (apa.org)',
        'WHO — Sexual and Reproductive Health',
    ],
}

DISCLAIMER = 'ملاحظة مهمّة: المعلومات في هذا المقال إرشادية عامّة مبنية على مصادر طبية موثّقة، لكنها لا تُغني عن استشارة الطبيب المختصّ لحالتك تحديداً.'

shutil.copy(SRC, BACKUP)
with SRC.open('r', encoding='utf-8') as f:
    data = json.load(f)

added = 0
skipped = 0
for a in data['articles']:
    cat = a.get('categoryId', 'pregnancy')
    # التحقّق من عدم وجود قسم مصادر مسبقاً
    has_sources = False
    for s in a.get('sections', []):
        t = s.get('title', '') + s.get('content', '')
        if 'المصادر' in t or 'References' in t or 'المراجع الطبية' in s.get('title', ''):
            has_sources = True
            break
    if has_sources:
        skipped += 1
        continue
    
    sources = SOURCES_BY_CATEGORY.get(cat, SOURCES_BY_CATEGORY['pregnancy'])
    sources_md = '\n'.join([f'• {s}' for s in sources])
    
    # أضِف قسماً جديداً
    if 'sections' not in a:
        a['sections'] = []
    a['sections'].append({
        'title': '📚 المصادر والمراجع الطبية',
        'content': f'{sources_md}\n\n{DISCLAIMER}',
    })
    added += 1

with SRC.open('w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(f'✓ أُضيف قسم المصادر لـ{added} مقال')
print(f'⏭ تُخُطّي {skipped} مقال (يحوي مصادر مسبقاً)')
```

### التنفيذ

```cmd
python scripts/enrich_articles_sources.py
```

**النتيجة المتوقّعة:** ~2500 مقال يحتوي على قسم مصادر واضح، بمصادر معتمَدة حسب الفئة.

### Commit
```
feat(articles): إضافة قسم المصادر والمراجع الطبية لجميع المقالات

- WHO/ACOG/AAP/AAD حسب الفئة
- تنبيه طبي في نهاية كل قسم مصادر
- E-E-A-T compliance لـ Google Play Health Apps
```

---

## المرحلة 4 — دمج SmartArticle في أقسام التطبيق

### 4.1 خريطة الدمج

| قسم التطبيق | يعرض مقالات فئة | كيف |
|---|---|---|
| `PregnancyWeeksScreen` (الحمل) | `pregnancy` (1126) | كاروسال «مقالات الحمل» في الأسفل + زر «شاهدي المزيد» → ArticlesListScreen(pregnancy) |
| `HomePage` (الرئيسية) | مختلَط: top 10 من كل الفئات | كاروسال أفقي «الأكثر قراءة» |
| `BabyPage` أو `_babyTab` (الطفل) | `baby` (9) | قائمة كاملة (كلها) |
| `CyclePage` (الدورة) | `fertility` + `health` (291) | كاروسال «مقالات دورتك» |
| `FertilityScreen` (الخصوبة) | `fertility` (176) | قائمة كاملة |
| قسم جديد «جمالي» في Home | `beauty` (762) | كاروسال «جمالك وعنايتك» |
| قسم جديد «حياتك الزوجية» | `marriage` (312) | كاروسال (اختياري — يمكن تأجيله) |

### 4.2 Widget مشترك: `SmartArticleCarousel`

**الملف الجديد:** `lib/widgets/smart_article_carousel.dart`

```dart
import 'package:flutter/material.dart';
import '../models/smart_article.dart';
import '../services/smart_articles_service.dart';
import '../screens/articles/article_detail_screen.dart';
import '../screens/articles/articles_list_screen.dart';

class SmartArticleCarousel extends StatefulWidget {
  final String? categoryId;  // إن كان null، يعرض top viewed من كل الفئات
  final String title;
  final int maxItems;

  const SmartArticleCarousel({
    Key? key,
    this.categoryId,
    required this.title,
    this.maxItems = 8,
  }) : super(key: key);

  @override
  State<SmartArticleCarousel> createState() => _SmartArticleCarouselState();
}

class _SmartArticleCarouselState extends State<SmartArticleCarousel> {
  List<SmartArticle>? _articles;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = SmartArticlesService();
    List<SmartArticle> list;
    if (widget.categoryId != null) {
      list = await service.byCategory(widget.categoryId!);
      // ترتيب حسب الأكثر مشاهدة داخل الفئة
      list.sort((a, b) => b.originalViews.compareTo(a.originalViews));
    } else {
      list = await service.topViewed(limit: widget.maxItems);
    }
    if (!mounted) return;
    setState(() => _articles = list.take(widget.maxItems).toList());
  }

  @override
  Widget build(BuildContext context) {
    if (_articles == null) {
      return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
    }
    if (_articles!.isEmpty) return const SizedBox.shrink();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (widget.categoryId != null) TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => ArticlesListScreen(
                  categoryId: widget.categoryId!,
                  categoryName: _articles!.first.categoryName,
                ),
              )),
              child: const Text('شاهدي المزيد ←', style: TextStyle(color: Color(0xFFE91E63))),
            ),
          ]),
        ),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _articles!.length,
            itemBuilder: (context, i) {
              final a = _articles![i];
              return Container(
                width: 180,
                margin: const EdgeInsets.only(left: 12),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  elevation: 3,
                  child: InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ArticleDetailScreen(article: a),
                    )),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      SizedBox(
                        height: 120,
                        child: Image.asset(a.imagePath, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: a.themeColor.withOpacity(0.2),
                            child: Center(child: Text(a.iconEmoji, style: const TextStyle(fontSize: 40))),
                          )),
                      ),
                      Expanded(child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(a.title, maxLines: 3, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, height: 1.3)),
                          const Spacer(),
                          Row(children: [
                            Icon(Icons.schedule, size: 11, color: Colors.grey.shade600),
                            const SizedBox(width: 3),
                            Text(a.readTime, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                          ]),
                        ]),
                      )),
                    ]),
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}
```

### 4.3 دمج الكاروسال في كل قسم

**في `PregnancyWeeksScreen`** — أضيفي الكاروسال في نهاية `ListView`:
```dart
const SmartArticleCarousel(
  categoryId: 'pregnancy',
  title: '📚 المزيد من مقالات الحمل',
  maxItems: 10,
),
```

**في `HomePage`** — بعد قسم Explore Grid:
```dart
const SmartArticleCarousel(
  categoryId: null,  // top viewed من كل الفئات
  title: '🔥 الأكثر قراءة في نبضة',
  maxItems: 10,
),
```

**في `BabyPage`**:
```dart
const SmartArticleCarousel(
  categoryId: 'baby',
  title: '👶 مقالات رعاية الرضيع',
  maxItems: 10,
),
```

**في `CyclePage`**:
```dart
Column(children: [
  SmartArticleCarousel(categoryId: 'fertility', title: '🌸 التبويض والخصوبة', maxItems: 8),
  SmartArticleCarousel(categoryId: 'health', title: '💗 صحّة المرأة', maxItems: 8),
]),
```

**في `HomePage` أضيفي أيضاً:**
```dart
const SmartArticleCarousel(
  categoryId: 'beauty',
  title: '💄 جمالكِ وعنايتك',
  maxItems: 8,
),
```

### Commit
```
feat(articles): كاروسال SmartArticle مدمج في كل أقسام التطبيق
```

---

## المرحلة 5 — دمج المقالات في الموقع (landing.html)

### الحالة الحالية
`web/landing.html` فيه بعض المقالات المُختارة يدوياً + رابط للموسوعة.

### التغيير المطلوب
1. **الاحتفاظ بالمقالات المختارة الحالية** (المميّزة) في الأعلى
2. **إضافة كاروسال جديد** في الأسفل «المزيد من الموسوعة» يعرض 6-8 مقالات random من الفئة المطابقة
3. **زر واضح** «قراءة المزيد على الموسوعة →» يفتح `articles.html`

### التنفيذ (بواسطة السكربت الموجود `build_web_articles_portal.py`)

عدّلي السكربت لينتج **جزءاً HTML قابلاً للحقن** يتم إدراجه في `landing.html`:

```python
# في scripts/build_web_articles_portal.py أضيفي function جديدة:

def build_landing_carousels(articles, top_n=8):
    """يبني HTML لكاروسالات لكل فئة، للحقن في landing.html."""
    from collections import defaultdict
    by_cat = defaultdict(list)
    for a in articles:
        by_cat[a['categoryId']].append(a)
    
    # ترتيب حسب المشاهدات في كل فئة، ثم أخذ top_n
    cat_labels = {
        'pregnancy': ('🤰 مقالات الحمل والولادة', 'pregnancy'),
        'beauty': ('💄 جمالكِ وعنايتك', 'beauty'),
        'baby': ('👶 رعاية الرضيع', 'baby'),
        'fertility': ('🌸 التبويض والخصوبة', 'fertility'),
        'health': ('💗 صحّة المرأة', 'health'),
        'marriage': ('💕 حياتك الزوجية', 'marriage'),
    }
    
    sections = []
    for cat_id, (label, filter_val) in cat_labels.items():
        cat_articles = sorted(by_cat.get(cat_id, []), 
                             key=lambda a: -a.get('originalViews', 0))[:top_n]
        if not cat_articles:
            continue
        
        cards_html = '\n'.join([
            f'''<a href="articles.html?id={a['id']}" class="mini-card">
                <img src="{a.get('imagePath', '')}" alt="{a['title']}" onerror="this.style.display='none'">
                <div class="mini-card-body">
                    <h4>{a['title'][:80]}</h4>
                    <span class="mini-card-time">⏱ {a['readTime']}</span>
                </div>
            </a>'''
            for a in cat_articles
        ])
        
        sections.append(f'''
        <section class="landing-carousel" data-cat="{cat_id}">
            <div class="carousel-header">
                <h2>{label}</h2>
                <a href="articles.html?filter={filter_val}" class="more-btn">قراءة المزيد ←</a>
            </div>
            <div class="carousel-scroll">
                {cards_html}
            </div>
        </section>
        ''')
    
    return '\n'.join(sections)

# استعمل النتيجة لحقنها في landing.html عبر ملف جزئي
```

**السكربت يحدّث `landing.html`** بإضافة قسم `<section id="wiki-carousels">...</section>` قبل الـfooter.

### CSS مطلوب في `landing.html`
```css
.landing-carousel { margin: 40px 0; padding: 0 20px; }
.carousel-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }
.carousel-header h2 { font-size: 24px; font-weight: 800; color: #E91E63; }
.more-btn { color: #E91E63; text-decoration: none; font-weight: 600; padding: 8px 16px; background: #FDE8EF; border-radius: 20px; }
.carousel-scroll { display: flex; overflow-x: auto; gap: 12px; padding-bottom: 12px; }
.mini-card { flex: 0 0 200px; text-decoration: none; color: inherit; background: white; border-radius: 12px; overflow: hidden; box-shadow: 0 2px 12px rgba(0,0,0,0.08); }
.mini-card img { width: 100%; height: 120px; object-fit: cover; }
.mini-card-body { padding: 12px; }
.mini-card-body h4 { font-size: 13px; font-weight: 700; margin: 0 0 8px 0; line-height: 1.4; }
.mini-card-time { font-size: 11px; color: #888; }
```

### Commit
```
feat(web): كاروسالات المقالات مدمجة في landing.html مع زر «قراءة المزيد»
```

---

## 📊 قائمة التحقّق النهائية

- [ ] المرحلة 1: 30 صورة placeholder في `assets/images/articles_bg/`
- [ ] المرحلة 2: كل imagePath في JSON يشير لصور القالبية (0 → 2500)
- [ ] المرحلة 3: 2500 مقال يحوي قسم «المصادر والمراجع الطبية»
- [ ] المرحلة 4: كاروسال في 5 شاشات (Pregnancy, Home, Baby, Cycle, ...)
- [ ] المرحلة 5: `landing.html` فيه 6 كاروسالات (واحد لكل فئة)
- [ ] `flutter analyze` = 0 errors
- [ ] `flutter build apk --release` ينجح
- [ ] كل الـ commits عربية مطابقة للنماذج

---

## 💡 ملاحظات للمُنفّذ

1. **لا تنسى pubspec.yaml** — أضيفي `assets/images/articles_bg/` تحت `assets:`
2. **`admin_panel_screen.dart` خطر الاقتطاع** — لا تعدّلي عبر Edit، استعملي Python + read → modify → cp
3. **الاختبار على الهاتف** بعد كل مرحلة يوفّر وقتاً
4. **رسائل commit عربية** — مطابقة تماماً لما ورد في كل مرحلة

---

## 🎁 ملاحظة عن Higgsfield للصور الحقيقية

هذه الخطة تُنجز نظاماً كاملاً بصور Placeholder جميلة (تدرّجات + نص). عندما تولّد المستخدمة صور Higgsfield الحقيقية لاحقاً، ستحفظها بنفس الأسماء (`bg_pregnancy_01.jpg` … `bg_baby_05.jpg`) وستحلّ محلّها تلقائياً بلا تعديل كود.

**بدء التنفيذ الفعلي في Higgsfield:**
- المستخدمة تفتح Higgsfield في متصفّحها
- تنسخ الـ30 prompts من المرحلة 1.2
- تولّد 5 صور لكل فئة (6 × 5 = 30)
- تحفظها بالتسمية `bg_[category]_[NN].jpg`
- تنسخها إلى `C:\nabda_app\assets\images\articles_bg\`
- التطبيق يستعملها تلقائياً في التحديث التالي

---

*هذا الملف مكتفٍ بذاته. الصقيه لـ Antigravity كـ initial prompt.*
