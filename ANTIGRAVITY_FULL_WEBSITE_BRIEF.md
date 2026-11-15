# خطة Antigravity — موقع nabda.online كامل: غلاف موحّد + أقسام بمحتوى التطبيق + متجر احترافي + لوحة تحكم أدمن

> **موجّه إلى:** Antigravity  •  **المشروع:** `C:\nabda_app`
> **يحلّ محلّ:** المرحلة 4 و 5 من `ANTIGRAVITY_WEB_REDESIGN_BRIEF.md` (تحويل Sidebar Flutter). المرحلتان 1-3 من ذلك الملف (صفحة `article.html`) تبقى، مع التصحيح المذكور في §0.4 أدناه.
> **المدة التقديرية:** 4-6 أيام عمل • **8 مراحل** • commit منفصل لكل مرحلة، رسائل commit بالعربية.

---

## 🎯 ما يريده المالك (Billel) بالحرف

1. **الهيدر الحالي لـ `landing.html` يبقى ثابتاً في كل صفحات الموقع** (الشعار المتحرّك + الحمل/الطفل/الدورة/المجتمع/المتجر/موسوعة نبضة + أزرار الدخول). عند التنقّل **يتغيّر المحتوى فقط**.
2. **صفحة الحمل** تعرض **كل ما في صفحة الحمل داخل التطبيق** لكن بتصميم ويب جذّاب. ونفس الشيء لباقي الأقسام (الطفل، الدورة، الخصوبة، المجتمع).
3. **المتجر** بمستوى متاجر المنافسين (Mumzworld، Jumia، Noon)، و**لكل منتج رابط مستقلّ**.
4. **لوحة تحكم أدمن احترافية جداً جداً**.
5. بعد تسجيل الدخول: نفس الهيدر، وتُستبدل أزرار الدخول **بأيقونة الحساب** (قائمة منسدلة)، وبيانات الحساب تظهر **في صفحة عادية** `/account`.

---

## §0 — قواعد إلزامية قبل كتابة أي سطر

### 0.1 الامتثال (من `CLAUDE.md` — لا استثناء)
- **لا ميزات طبية على الموقع أيضاً** (نحافظ على اتّساق مع Play): أنشئ `web/js/site-config.js` فيه `SITE_HIDE_MEDICAL = true`، واحجب به: عدّاد الركلات، مؤقّت الانقباضات، قائمة الفحوصات الطبية، اللقاحات، تذكير الأدوية، الضغط/السكر، دليل الأطباء، أي سؤال/جواب صحّي.
- **المؤلّف دائماً «فريق تحرير نبضة»** — ممنوع «فريق طبي» أو «د. ...» أو «مراجعة طبية».
- **المتجر لا يبيع مكمّلات ولا أجهزة طبية.** انقل `isHiddenProduct()` من `lib/config/shop_config.dart` حرفياً إلى `web/js/shop-rules.js` وطبّقها على **كل** قائمة منتجات (المتجر، صفحة المنتج، الكاروسالات، المنتجات المقترحة، لوحة الأدمن تُظهر تحذيراً وتمنع التفعيل):
  ```js
  export const HIDDEN_CATS = new Set(['فيتامينات ومكملات','مكملات غذائية','مكملات طبيعية','أطعمة ومكملات','أجهزة طبية']);
  const SUPP_WORDS = ['مكمل','مكمّل','فيتامينات','حمض الفوليك','أوميغا','حديد +','كالسيوم +'];
  export function isHiddenProduct(p){ if(!p) return false;
    if (HIDDEN_CATS.has(String(p.category||'').trim())) return true;
    const n = String(p.name||p.title||''); return SUPP_WORDS.some(w => n.includes(w)); }
  ```
  ⚠️ `web/shop.html` الحالي **لا يطبّقها** — هذه ثغرة يجب إغلاقها.
- رابط Play الصحيح: `https://play.google.com/store/apps/details?id=com.nabda.womenhealth` (استبدل كل `com.nabda.app` في `web/`).
- مساعد Gemini: إن ظهر على الموقع فهو **مساعد نمط حياة غير طبي** بنفس `kAssistantSystemPrompt` و `isMedicalQuestion()`.

### 0.2 لا تكسر الموجود
- `admin_panel_screen.dart` (5600+ سطر) معرّض للاقتطاع عند التعديل — لا تعدّله في هذه الخطة.
- لا `flutter clean` قبل كل build. ذاكرة الجهاز ~7GB.
- اختبر محلياً بـ `firebase emulators:start --only hosting` أو `firebase hosting:channel:deploy preview` **قبل** النشر على الإنتاج.

### 0.3 التقنية المعتمدة (قرار معماري)
الموقع = **صفحات HTML ثابتة + Vanilla JS (ES modules) + Firebase JS SDK v10 compat** (نفس ما يستعمله `shop.html` حالياً). لا React ولا build step معقّد — سهل الصيانة ويفهمه أي agent لاحقاً.
- Chart.js و أي مكتبة: **استضافة ذاتية** في `web/vendor/` (CSP يسمح بـ `'self'` فقط للسكربتات خارج gstatic).
- تطبيق Flutter Web ينتقل إلى **`/app/`** (يبقى متاحاً كـ «النسخة الكاملة» للميزات غير المنقولة).

### 0.4 تصحيح للبريف السابق (`article.html`)
`article.html` في البريف السابق يجلب `/assets/data/smart_2500_articles.json` — **خطأ**: Flutter يضع الأصول في `/assets/assets/...`، وبعد النقل إلى `/app/` يتغيّر المسار مجدداً، والملف 17MB. **الحلّ:** المرحلة 1 تولّد ملفات مقالات مقسّمة في `web/data/articles/` ويقرأ منها `article.html`.

---

## §1 — البنية النهائية للموقع

```
web/
├── index.html            ← الصفحة الرئيسية (محتوى landing.html الحالي) — يُنسخ وقت البناء
├── landing.html          ← يبقى (redirect 301 إلى / عبر firebase.json)
├── pregnancy.html        ← /pregnancy  و /pregnancy/week-N
├── baby.html             ← /baby  و /baby/month-N
├── cycle.html            ← /cycle
├── fertility.html        ← /fertility
├── community.html        ← /community  و /community/post/<id>
├── shop.html             ← /shop  و /shop/c/<category-slug>   (إعادة بناء)
├── product.html          ← /product/<slug>
├── cart.html             ← /cart
├── checkout.html         ← /checkout
├── account.html          ← /account  (+ /account/orders, /account/saved, /account/settings)
├── login.html            ← /login  و /signup
├── article.html          ← /article/<id>   (من البريف السابق)
├── articles.html         ← /articles (يبقى — يلتحق بالغلاف الموحّد)
├── admin.html            ← /admin  (لوحة التحكم)
├── css/site.css          ← design tokens + header + footer + مكوّنات مشتركة
├── css/admin.css
├── js/site-config.js     ← SITE_HIDE_MEDICAL, PLAY_URL, firebaseConfig
├── js/firebase-init.js   ← تهيئة واحدة (app, auth, firestore, storage)
├── js/shell.js           ← يحقن الهيدر/الفوتر + حالة الدخول + القائمة المنسدلة + السلة
├── js/shop-rules.js      ← isHiddenProduct
├── js/cart.js            ← سلة localStorage
├── js/pages/*.js         ← منطق كل صفحة
├── js/admin/*.js         ← وحدات لوحة التحكم
├── data/                 ← JSON مولّد من بيانات Dart (المرحلة 1)
└── vendor/chart.umd.min.js
```

### 1.1 `firebase.json` — rewrites و redirects (الترتيب مهمّ)
```json
"redirects": [
  { "source": "/landing", "destination": "/", "type": 301 },
  { "source": "/landing.html", "destination": "/", "type": 301 },
  { "source": "/shop/:slug", "destination": "/product/:slug", "type": 301 }
],
"rewrites": [
  { "source": "/app/**",        "destination": "/app/index.html" },
  { "source": "/pregnancy/**",  "destination": "/pregnancy.html" },
  { "source": "/pregnancy",     "destination": "/pregnancy.html" },
  { "source": "/baby/**",       "destination": "/baby.html" },
  { "source": "/baby",          "destination": "/baby.html" },
  { "source": "/cycle",         "destination": "/cycle.html" },
  { "source": "/fertility",     "destination": "/fertility.html" },
  { "source": "/community/**",  "destination": "/community.html" },
  { "source": "/community",     "destination": "/community.html" },
  { "source": "/shop/c/**",     "destination": "/shop.html" },
  { "source": "/shop",          "destination": "/shop.html" },
  { "source": "/product/**",    "function": "productPage" },
  { "source": "/cart",          "destination": "/cart.html" },
  { "source": "/checkout",      "destination": "/checkout.html" },
  { "source": "/account/**",    "destination": "/account.html" },
  { "source": "/account",       "destination": "/account.html" },
  { "source": "/login",         "destination": "/login.html" },
  { "source": "/signup",        "destination": "/login.html" },
  { "source": "/admin/**",      "destination": "/admin.html" },
  { "source": "/admin",         "destination": "/admin.html" },
  { "source": "/article/**",    "destination": "/article.html" },
  { "source": "/articles/**",   "destination": "/articles.html" },
  { "source": "/articles",      "destination": "/articles.html" }
]
```
- **لا قاعدة `**` → index.html بعد الآن** — الصفحات غير الموجودة تذهب إلى `404.html` (صمّمها بروح نبضة مع روابط الأقسام).
- `/shop/:slug` (مقطع واحد) يحوّل الروابط القديمة المنشورة على فيسبوك إلى `/product/:slug`. `/shop/c/x` (مقطعان) لا يتأثّر.
- أضف header `X-Robots-Tag: noindex, nofollow` لـ `/admin/**` و `/admin.html` و `/account/**` و `/cart` و `/checkout`.
- إن تعذّر نشر Cloud Functions (خطة Spark) استعمل `"destination": "/product.html"` بدل `"function"` — يعمل كل شيء ما عدا معاينة فيسبوك (OG).

### 1.2 سكربت البناء `tool/build_site.ps1` (PowerShell — الجهاز Windows)
```powershell
# 1) بناء Flutter تحت /app/
flutter build web --release --base-href /app/
# 2) نقل مخرجات Flutter إلى build/web/app/ ثم وضع صفحات الموقع في الجذر
$tmp = "build/_flutter"; Remove-Item $tmp -Recurse -ErrorAction Ignore
Move-Item build/web $tmp
New-Item build/web -ItemType Directory | Out-Null
Move-Item $tmp build/web/app
# 3) نسخ الموقع الثابت (كل web/ ما عدا index.html الخاص بـ Flutter)
Get-ChildItem web -Exclude index.html,flutter_bootstrap.js,manifest.json | Copy-Item -Destination build/web -Recurse -Force
Copy-Item web/home.html build/web/index.html -Force
# 4) توليد sitemap
dart run tool/gen_sitemap.dart
```
⚠️ لذلك: **انقل محتوى `landing.html` إلى `web/home.html`** (لأن `web/index.html` محجوز لـ bootstrap فلاتر)، واترك `landing.html` كملف redirect بسيط. حدّث `CLAUDE.md` بقسم «Website build» يشرح هذا السكربت.
- روابط تسجيل الدخول/الخروج في تطبيق Flutter Web التي تشير إلى `/` يجب أن تبقى صالحة؛ ابحث في `lib/` عن `Uri.base` و `'/'` في التنقّل وتأكّد أن GoRouter يعمل تحت `/app/`.

---

## المرحلة 1 — تصدير بيانات التطبيق إلى JSON للموقع

السكربت: `tool/export_web_data.dart` (يُشغّل بـ `dart run`؛ يستورد ملفات البيانات مباشرة — بلا Flutter widgets. إن استوردت ملفات `package:flutter` فانسخ الكلاسات النقية إلى `tool/_models.dart`).

| المصدر في Dart | المخرج | يُستعمل في |
|---|---|---|
| `lib/models/pregnancy_week_articles.dart` (41 أسبوع × حقوله) | `web/data/pregnancy_weeks.json` | pregnancy.html |
| بيانات الحجم/الوزن/الطول + الفاكهة (`_fetusImage` و ما حوله في `pregnancy_weeks_screen.dart` سطر ~35-460، و `web/tools/data/fetus_weeks.json` الموجود) | داخل نفس الملف | pregnancy.html |
| `lib/data/specialized_articles*.dart` + `discover` models في `pregnancy_weeks_screen.dart` (سطر 2680+) | `web/data/pregnancy_discover.json` | pregnancy.html |
| بيانات الطفل حسب الشهر (`BabyPage` في `main.dart` سطر 5789+ و `baby_dashboard.dart`) | `web/data/baby_months.json` | baby.html |
| `lib/data/fertility_faith_articles.dart` + أدعية الذرية | `web/data/fertility.json` | fertility.html |
| `assets/data/smart_2500_articles.json` | `web/data/articles/index.json` (id, title, categoryId, categoryName, imagePath, summary≤160, readTime, photoTag, weekTag إن وُجد) + `web/data/articles/<id>.json` لكل مقال | article.html، الكاروسالات |

- كل `author` يُكتب `فريق تحرير نبضة`.
- صور الأجنة: انسخ `assets/images/fetus_hd/week_N.png` إلى `web/img/fetus/week_N.webp` (حوّل إلى webp ≤ 600px — سكربت Python/Pillow).
- صور المقالات القالبية: انسخ `assets/images/articles_bg/` إلى `web/img/articles_bg/`.

**Commit:** `chore(web): تصدير بيانات الحمل والطفل والخصوبة والمقالات إلى JSON للموقع`

---

## المرحلة 2 — الغلاف الموحّد (Header + Footer + Auth) + صفحات الدخول والحساب

### 2.1 الهيدر — نسخة طبق الأصل من `landing.html` (سطر 137-215)
- استخرج الـ glass nav (الشعار SVG المتحرّك + الروابط + الأزرار) إلى `shell.js` كـ template، ويُحقن في `<header id="nb-header" style="min-height:96px"></header>` في كل صفحة (min-height يمنع قفز التخطيط).
- الروابط تصبح حقيقية `<a href>` (لا `onclick="nb(...)"`): الرئيسية `/` • الحمل `/pregnancy` • الطفل `/baby` • الدورة `/cycle` • الخصوبة `/fertility` • المجتمع `/community` • المتجر `/shop` • موسوعة نبضة `/articles`.
- الرابط النشط يُلوَّن تلقائياً حسب `location.pathname` (لون `#F43F7E` + نقطة صغيرة تحته).
- **زائرة:** «تسجيل الدخول» + «إنشاء حساب جديد» (كما الآن).
- **مسجّلة:** تختفي الأزرار ويظهر:
  - 🛒 أيقونة السلة + عدّاد (من `cart.js`)
  - 🔖 المحفوظات
  - **كبسولة الحساب**: صورة/إيموجي + الاسم + سهم ▾ → قائمة منسدلة زجاجية:
    ```
    [صورة]  billel
            🤰 الأسبوع 19 من الحمل        ← شارة المرحلة (من users doc)
    ─────────────
    👤 حسابي            /account
    📦 طلباتي           /account/orders
    🔖 مقالاتي المحفوظة  /account/saved
    🤰 رحلتي            /pregnancy (أو حسب المرحلة)
    ⚙️ الإعدادات والخصوصية /account/settings
    📱 النسخة الكاملة    /app/
    ─────────────
    🚪 تسجيل الخروج
    ```
- **الهاتف (<900px):** الشعار + أيقونة الحساب/الدخول + زر ☰ يفتح درجاً جانبياً (من اليمين) بكل الروابط. وأسفل الشاشة شريط تبويبات ثابت (الرئيسية، الحمل، المتجر، المجتمع، حسابي) — مثل التطبيق.
- أثناء انتظار `onAuthStateChanged` اعرض skeleton دائري مكان الأزرار (لا وميض بين الحالتين). خزّن آخر حالة في `sessionStorage` لعرض فوري.

### 2.2 الفوتر
4 أعمدة: عن نبضة + الأقسام + المتجر (سياسة التوصيل/الإرجاع/تتبّع الطلب) + تحميل التطبيق (شارة Play) + روابط التواصل (فيسبوك nabda.official). سطر سفلي: الخصوصية • الشروط • حذف الحساب (`/delete-account.html`) • © 2026 نبضة.

### 2.3 `login.html` (`/login` و `/signup` بنفس الصفحة، تبويبان)
- تصميم منقسم: يمين النموذج، يسار صورة من `landing-assets/` مع اقتباس.
- Email/Password + زر Google (`signInWithPopup`، fallback `signInWithRedirect` على الهاتف) — نفس مزوّدي `lib/services/auth_service.dart`.
- **إنشاء الحساب يكتب وثيقة `users/{uid}` بنفس الحقول التي يكتبها التطبيق** — اقرأ `auth_service.dart` و شاشة الـ onboarding و انسخ أسماء الحقول بالضبط (`displayName`, `lifeStage`, `pregnancyStartDate`, `goal`, `createdAt`...). بعد التسجيل: خطوة اختيار المرحلة (أخطّط للحمل / حامل + تاريخ آخر دورة / لديّ طفل + تاريخ الميلاد / أتابع دورتي).
- `?next=/product/xyz` يعيدها حيث كانت.
- نسيت كلمة المرور → `sendPasswordResetEmail`.

### 2.4 `account.html` — صفحة الحساب «عادية» وجميلة
- **Hero**: غلاف متدرّج وردي + صورة دائرية + الاسم + شارة المرحلة + «عضوة منذ …».
- **بطاقات إحصاء**: أسبوع الحمل/عمر الطفل • عدد الطلبات • المقالات المحفوظة • منشوراتي.
- تبويبات (URL لكل تبويب): **نظرة عامة** • **طلباتي** (`orders where userId == uid`، مع حالة الطلب كخطّ زمني: قيد المراجعة → مؤكَّد → شُحن → سُلِّم) • **المحفوظات** • **بياناتي** (تعديل الاسم، المرحلة، التواريخ، الصورة → Storage `profile_photos/{uid}`) • **الخصوصية** (تنزيل بياناتي، رابط حذف الحساب، تسجيل الخروج من كل الأجهزة).

**Commit:** `feat(web): غلاف موحّد للموقع (هيدر landing + حالة الدخول + قائمة الحساب) وصفحات الدخول والحساب`

---

## المرحلة 3 — الصفحة الرئيسية

- `home.html` = محتوى `landing.html` الحالي **كما هو** (السلايدر، شريط الميزات، الأدوات، كاروسالات المقالات) لكن داخل الغلاف الموحّد.
- عند تسجيل الدخول أضف تحت السلايدر **بطاقة «رحلتي اليوم»** مخصّصة: حامل → الأسبوع + حجم الجنين + رابط؛ أمّ → عمر الطفل + نصيحة اليوم؛ دورة → اليوم في الدورة + التوقّع.
- شرائح السلايدر تُقرأ من `site_config/home` (يديرها الأدمن — المرحلة 7) مع fallback إلى `NB_SLIDES` الحالية.
- كاروسال «من متجر نبضة» (8 منتجات مميّزة `featured == true`، مُرشّحة بـ `isHiddenProduct`).

**Commit:** `feat(web): الصفحة الرئيسية داخل الغلاف الموحّد + بطاقة رحلتي المخصّصة`

---

## المرحلة 4 — صفحة الحمل (`/pregnancy` و `/pregnancy/week-N`) — نظير كامل لشاشة التطبيق

المرجع: `PregnancyPage` (`main.dart` 5518) → `PregnancyWeeksScreen` (`lib/screens/pregnancy/pregnancy_weeks_screen.dart`). **انقل كل قسم فيها**، بالترتيب التالي، بتخطيط ويب من عمودين على الشاشات العريضة (المحتوى 2/3 + عمود جانبي لاصق 1/3):

| # | القسم في التطبيق | على الويب |
|---|---|---|
| 1 | Header + حلقة التقدّم مع صورة الجنين (سطر ~703-870) | **Hero** وردي متدرّج: صورة الجنين في دائرة متوهّجة + شارة «بحجم 🫑 فلفل حلو»، «الأسبوع 19 من الحمل»، «الشهر الخامس • بقي 142 يوماً»، شريط تقدّم %، «من 7 يونيو 2026 إلى 14 مارس 2027». (طابق تصميم الـ Hero الذي يظهر في Flutter web حالياً — المالك أعجبه) |
| 2 | Quick info row (سطر 1216) | 3 بطاقات: الحجم • الوزن • الطول — بأيقونات كبيرة وعدّاد متحرّك |
| 3 | — (جديد للويب) | **شريط الأسابيع 1→42** أفقي قابل للسحب + أسهم السابق/التالي؛ كل أسبوع رابط `/pregnancy/week-N` (SEO: «الأسبوع N من الحمل») |
| 4 | محتوى `PregnancyWeekArticle` (تطوّر الجنين، تغيّرات جسمكِ، النصائح…) | بطاقات بعناوين ملوّنة وقوائم ✓ (كما في الصورة: «تطور الجنين هذا الأسبوع 💗») + تبويبات «طفلكِ / جسمكِ / نصائح» على الهاتف |
| 5 | تاريخ الولادة المتوقّع قابل للتعديل (سطر 888) | بطاقة في العمود الجانبي + زر «تعديل» (للمسجّلة يكتب `pregnancyStartDate`) |
| 6 | خطّة الولادة (أسبوع ≥ 32، سطر 3852) | بطاقة اختيار طبيعية/قيصرية + قائمة تفضيلات قابلة للطباعة |
| 7 | Articles Carousel (سطر 1254) | كاروسال مقالات الحمل من `data/articles/index.json` (أولوية لمقالات هذا الأسبوع/الثلث) → `/article/<id>` |
| 8 | دليل أسماء المواليد (سطر 905) | بطاقة عريضة → `/tools/baby-names.html` |
| 9 | Health Trackers Banner (سطر 975) | بانر «متتبّعاتي» (الوزن، الماء، النوم فقط — غير طبي) → يدعو لتحميل التطبيق |
| 10 | Featured + Dynamic Discover + All Discover Sections (سطر 1057-1130، 1448) | أقسام «اكتشفي المزيد 💡» بشبكة بطاقات حسب التصنيف، + `dynamic_articles` من Firestore |
| 11 | «منتجات قد تهمك» (سطر 3179) | كاروسال منتجات الحمل (`lifeStageTags` يحوي `pregnant`) مُرشّح بـ `isHiddenProduct` |
| 12 | أدوات الحمل | شبكة أيقونات 3D (`assets/icons_3d/`): حاسبة الموعد • حجم الجنين • حقيبة الولادة • التغذية • التمارين • يوميات الحمل • التقويم. الأدوات غير المنقولة → «متاحة في التطبيق» مع QR |
| ✖ | عدّاد الركلات (سطر 2173)، القائمة الطبية (سطر 2046)، صورة الإيكو | **مخفيّة** (`SITE_HIDE_MEDICAL`) — الإيكو بيانات شخصية تبقى في التطبيق |

- **زائرة:** يُعرض الأسبوع من الـ URL (افتراضياً 12) + بانر لطيف «سجّلي لنتابع حملكِ أسبوعاً بأسبوع» + حاسبة سريعة «أدخلي تاريخ آخر دورة» تحسب الأسبوع محلياً.
- **مسجّلة حامل:** يُحسب الأسبوع من `pregnancyStartDate` كما في `main.dart` (`week = floor(days/7)`، حدود 1..42، `daysLeft = 280 - days`) ويُفتح أسبوعها تلقائياً. بعد 294 يوماً: بطاقة «هل وُلد طفلكِ؟» كما في التطبيق (سطر 5570-5630).
- **مسجّلة `goal == 'trying'`:** بطاقة «أحاول الحمل 🌱» → `/fertility` (كما في التطبيق).
- SEO لكل أسبوع: `<title>الأسبوع 19 من الحمل: حجم الجنين وتطوّره ونصائح — نبضة</title>`، description من أوّل فقرة، JSON-LD `Article`، canonical.

**Commit:** `feat(web): صفحة الحمل الكاملة مع رابط لكل أسبوع (نظير PregnancyWeeksScreen)`

---

## المرحلة 5 — الطفل، الدورة، الخصوبة، المجتمع

نفس المبدأ: **افتح الشاشة المقابلة في التطبيق، اجرد أقسامها، وانقل كل ما ليس طبياً.**

### `/baby` و `/baby/month-N` ← `BabyPage` (main.dart 5789) + `baby_dashboard.dart`
Hero بعمر الطفل (أشهر/أيام) + اسم الطفل • شريط الأشهر 0→24 • مراحل النموّ للشهر • الرضاعة والنوم (نصائح عامّة) • ألعاب/أنشطة مناسبة للعمر • مقالات `baby` • منتجات (`newborn`/`baby`) • أسماء المواليد. ✖ اللقاحات مخفيّة.

### `/cycle` ← `CyclePage` (main.dart 4742) + `cycle_dashboard.dart` + `lib/blocs/cycle/`
تقويم شهري كبير يلوّن: الدورة المتوقّعة، نافذة الخصوبة، يوم التبويض (من بيانات المستخدمة — اقرأ نموذج الدورة وأسماء الحقول من `lib/models/` و `CycleBloc`) • بطاقة «اليوم N من دورتكِ» • تسجيل بداية الدورة (للمسجّلة) • مقالات + منتجات العناية بالدورة. **زائرة:** حاسبة محلية (آخر دورة + طول الدورة).

### `/fertility`
حاسبة التبويض (أعد استعمال `tools/ovulation.html`) • أدعية الذرّية (`fertility.json`) • مقالات الخصوبة • خطوات «التخطيط للحمل». بلا مكمّلات.

### `/community` و `/community/post/<id>`
- القواعد: `community_posts` تتطلّب `isAuthenticated()` للقراءة. **زائرة:** واجهة جذّابة بمعاينة مموّهة (blur) لـ 3 منشورات وهمية + «انضمّي لمجتمع الأمهات» → `/signup`. **لا تغيّر القاعدة.**
- **مسجّلة:** خلاصة منشورات (أحدث/الأكثر تفاعلاً)، فلترة بالمجموعات، إنشاء منشور، تعليقات، إعجاب، إبلاغ (`reports` بنفس حقول التطبيق — `reporterUid`)، حظر. استعمل نفس الحقول التي يكتبها `create_post_screen.dart` و `post_detail_screen.dart`.

**Commit:** `feat(web): صفحات الطفل والدورة والخصوبة والمجتمع (نظير شاشات التطبيق)`

---

## المرحلة 6 — المتجر الاحترافي (بمستوى Mumzworld / Jumia / Noon)

### 6.1 مخطّط المنتج (مع الحفاظ على الحقول الحالية)
الحقول الموجودة اليوم (من `shop.html`): `name, slug, category, brand, price, oldPrice|originalPrice, image|imageUrl, images?, description|desc, emoji, rating, reviewCount, createdAt, active, stock`. أضف (اختيارية، والكود يتحمّل غيابها):
```
images: [url...]            gallery مرتّبة
variants: [{label:'المقاس', options:['S','M','L']}]
lifeStageTags: ['pregnant','newborn','baby','mom']   ← للتخصيص في المقالات والأقسام
featured: bool, badge: 'جديد'|'الأكثر مبيعاً'|..., soldCount: int
seoTitle, seoDescription, sku
```
- **سعر التكلفة لا يوضع في `products`** (قراءتها عامّة) → `products_private/{id}` (طاقم فقط).
- اكتب سكربت ترحيل `tool/migrate_products.js` (firebase-admin) يملأ `slug` الناقص (من الاسم: إزالة التشكيل، مسافات → `-`، ويُلحق آخر 4 أحرف من الـ id لضمان التفرّد) و `images` من `image`.

### 6.2 `/shop` — واجهة المتجر
- **Hero بانرات** دوّارة (من `site_config/shop`) + 3 بانرات ترويجية صغيرة.
- **شريط تصنيفات بأيقونات دائرية** (مثل Mumzworld): الحمل والولادة • المولود • الرضاعة • ملابس الأطفال • العناية بالأم • الألعاب • الاستحمام • …
- **مجموعات حسب المرحلة:** «لكِ أثناء الحمل» • «لمولودكِ الجديد» • «لطفلكِ 1-3 سنوات» — للمسجّلة تُرتَّب حسب مرحلتها.
- رفوف: ⚡ عروض اليوم (عدّاد تنازلي) • الأكثر مبيعاً • وصل حديثاً.
- **صفحة النتائج** (`/shop?q=&cat=&sort=` و `/shop/c/<slug>`): فلاتر جانبية (التصنيف، السعر بمنزلق مزدوج، الماركة، متوفّر فقط، تخفيض فقط) — درج سفلي على الهاتف • فرز (الأحدث، الأقل سعراً، الأعلى سعراً، الأكثر مبيعاً، الأعلى تقييماً) • عدّاد النتائج • **كل الفلاتر في الـ URL** (قابلة للمشاركة والرجوع) • تحميل لا نهائي بـ «عرض المزيد».
- **بطاقة المنتج:** صورة ثانية عند المرور • شارة خصم `-25%` • قلب مفضّلة • نجوم + عدد التقييمات • السعر + القديم مشطوب • «أضيفي للسلة» سريع • شارة «بقي 3 فقط» إن `stock ≤ 5` • «نفد» رمادية + «أعلميني عند التوفّر» (`waitlist` — يتطلّب دخول حسب القاعدة).
- بحث فوري بالاقتراحات (فهرس محلي للأسماء يُحمّل مرّة).
- الأداء: Firestore `where('active','==',true)` + ترتيب، ثم الترشيح بـ `isHiddenProduct` على العميل. صور lazy + `srcset`.

### 6.3 `/product/<slug>` — صفحة منتج مستقلّة
- مسار الخبز: الرئيسية › المتجر › التصنيف › المنتج.
- **معرض**: صورة كبيرة + مصغّرات، تكبير عند المرور (desktop)، سحب (mobile)، فتح بملء الشاشة.
- الاسم، الماركة، النجوم، السعر + القديم + «وفّري 1,200 دج»، مؤشّر المخزون، المتغيّرات (أزرار)، الكمّية.
- **نموذج الطلب COD مباشرة في الصفحة** (أعلى معدّل تحويل في الجزائر): الاسم • الهاتف (تحقّق `^0[567]\d{8}$`) • الولاية + البلدية (من `assets/data/algeria_cities.json` → انسخه إلى `web/data/`) • العنوان • التوصيل للمنزل/مكتب • **رسوم الشحن تُحسب من `site_config/shipping`** • الإجمالي • زر «تأكيد الطلب — الدفع عند الاستلام».
- أزرار ثانوية: «أضيفي للسلة» • «اطلبي عبر واتساب» (رسالة مُعبّأة بالاسم والرابط).
- شارات ثقة: 🚚 توصيل لـ 58 ولاية • 💵 الدفع عند الاستلام • ↩️ الإرجاع خلال 7 أيام • ✅ منتج أصلي.
- تبويبات: الوصف • المواصفات • التوصيل والإرجاع • التقييمات.
- «منتجات مشابهة» + «شاهدتِها مؤخراً» (localStorage).
- **شريط شراء لاصق أسفل الشاشة على الهاتف**.
- SEO: JSON-LD `Product` (name, image, offers.price, priceCurrency DZD, availability)، canonical `/product/<slug>`.
- **منتج مخفي (`isHiddenProduct`) أو غير نشط → صفحة «المنتج غير متوفّر» + منتجات بديلة** (لا 404 خام).

### 6.4 Cloud Function `productPage` (معاينة فيسبوك/واتساب)
فيسبوك لا يشغّل JavaScript، فالمعاينة تحتاج OG tags في HTML الخام. في `functions/`:
```js
exports.productPage = onRequest(async (req, res) => {
  const slug = decodeURIComponent(req.path.split('/')[2] || '');
  const tpl = await fetchTemplate();             // يقرأ product.html من الاستضافة ويخزّنه في الذاكرة
  const snap = await db.collection('products').where('slug','==',slug).limit(1).get();
  const p = snap.empty ? null : snap.docs[0].data();
  const meta = p && !isHiddenProduct(p) ? ogTags(p, slug) : ogTags(null, slug);
  res.set('Cache-Control','public, max-age=300, s-maxage=600');
  res.send(tpl.replace('<!--OG-->', meta));
});
```
(نفس الفكرة قابلة لاحقاً لـ `/article/<id>`.)

### 6.5 السلة و Checkout
- `cart.js`: localStorage `{items:[{productId, slug, name, image, price, variant, qty}]}` + عدّاد الهيدر + درج سلة جانبي يظهر عند الإضافة.
- `/checkout` صفحة واحدة: نفس حقول COD + ملخّص الطلب.
- **التوافق مع قاعدة `orders` الحالية** (طلب الزائر يتطلّب `productId` واحد و `quantity` int): **أنشئ وثيقة طلب لكل سطر** تشترك في `cartId` (uuid) — لا حاجة لتعديل القاعدة. الحقول الإلزامية للزائر: `userId: null, source: 'website', status: 'pending', customerName, customerPhone, wilaya, productId, quantity` + إضافية: `commune, address, deliveryType, shippingFee, unitPrice, productName, variant, cartId, createdAt`. للمسجّلة: `userId: uid`.
- **إنقاص المخزون:** القاعدة الحالية تسمح للمسجّلة فقط. أضف Cloud Function `onOrderCreated` (Firestore trigger) تُنقص `stock` وتزيد `soldCount` بـ Admin SDK — وأزل الإنقاص من العميل.
- صفحة الشكر: رقم الطلب + «سنتّصل بكِ لتأكيد الطلب» + زر واتساب + منتجات مقترحة.
- (اختياري، بموافقة المالك) Meta Pixel + GA4 events: ViewContent, AddToCart, InitiateCheckout, Purchase — يتطلّب تعديل CSP (`connect-src`/`script-src`/`img-src` لـ `connect.facebook.net` و `www.facebook.com`) وتحديث `privacy.html`.

**Commit:** `feat(shop): متجر احترافي — واجهة + فلاتر + صفحة مستقلّة لكل منتج + سلة + COD`

---

## المرحلة 7 — لوحة التحكم `/admin` (احترافية جداً)

### 7.1 الوصول والأمان
- `admin.html` + `<meta name="robots" content="noindex,nofollow">`.
- تسجيل دخول Firebase → قراءة `staff/{uid}` → `isActive == true` وإلا شاشة «غير مصرّح» + خروج. الدور (`owner` / `supervisor` / **جديد** `agent`) يتحكّم بما يظهر — **الحماية الحقيقية في `firestore.rules`** (الواجهة للعرض فقط).
- مهلة خمول 30 دقيقة → قفل.

### 7.2 التصميم
- تخطيط RTL: **شريط جانبي يميني قابل للطيّ** (أيقونات فقط عند الطيّ) + شريط علوي: بحث شامل (طلب برقم الهاتف/الاسم، منتج بالاسم/SKU) بـ `Ctrl+K`، جرس إشعارات، تبديل فاتح/داكن، صورة الموظّف ودوره.
- لوحة ألوان: خلفية `#F7F5F8`، بطاقات بيضاء بحواف 16px، الأساسي `#E91E63`، الثانوي `#00897B`؛ الوضع الداكن `#16131A`. خطّ Cairo. أرقام بخطّ tabular.
- جداول: ترتيب بالنقر على العمود، تحديد متعدّد، إجراءات جماعية، تصفّح، أعمدة قابلة للإخفاء، skeleton عند التحميل، حالات فارغة مرسومة.
- كل إجراء حسّاس (حذف، إلغاء طلب) → نافذة تأكيد. كل نجاح/فشل → toast.

### 7.3 الوحدات
1. **📊 لوحة القيادة**: بطاقات KPI مع مقارنة بالفترة السابقة (↑↓%): طلبات اليوم • إيراد اليوم/الشهر (للمُسلَّمة فقط) • متوسّط السلّة • نسبة التأكيد • نسبة التسليم • نسبة الإرجاع • منتجات نافدة/منخفضة. رسوم (Chart.js ذاتي الاستضافة): الطلبات والإيراد 30 يوماً (خط) • الطلبات حسب الحالة (دونات) • أعلى 10 ولايات (أعمدة) • أعلى المنتجات مبيعاً • ساعات الذروة (heatmap). فلتر فترة: اليوم/7/30/90/مخصّص. + آخر 10 طلبات + تنبيهات المخزون.
2. **📦 الطلبات** (القلب): جدول + **عرض Kanban** بالسحب بين الحالات: `pending` جديد → `no_answer` لم يرد → `confirmed` مؤكَّد → `shipped` شُحن → `delivered` سُلِّم / `returned` مُرتجع / `cancelled` ملغى. **إشعار فوري + صوت** عند طلب جديد (`onSnapshot`). فلاتر: الحالة، التاريخ، الولاية، المصدر (website/app)، بحث. **درج تفاصيل الطلب**: بيانات العميلة، زر اتّصال `tel:`، قوالب رسائل واتساب (تأكيد، شحن، تذكير)، تجميع أسطر نفس `cartId`، تعديل الكمّية/العنوان، ملاحظات داخلية، **خطّ زمني** (`history: [{status, by, at, note}]`). **كشف التكرار** (نفس الهاتف خلال 24 ساعة) و **قائمة سوداء** للأرقام الوهمية (`blocked_phones`) مع تحذير ظاهر. **طباعة** فاتورة وملصق شحن A6 (CSS print) فردياً أو جماعياً. **تصدير CSV/Excel** (لشركات التوصيل).
3. **🛍️ المنتجات**: جدول + شبكة، فلاتر، تفعيل/تعطيل سريع، تعديل السعر/المخزون داخل الجدول. **نموذج المنتج**: الاسم، slug تلقائي قابل للتعديل (مع فحص التفرّد)، الوصف (محرّر نصّي بسيط: عناوين، قوائم، غامق)، التصنيف، الماركة، السعر، القديم، **التكلفة** (→ `products_private`)، المخزون، SKU، المتغيّرات، `lifeStageTags`، `featured`، الشارة، SEO. **رفع صور متعدّدة بالسحب** + إعادة ترتيب + ضغط في المتصفّح (canvas → webp، ≤ 1600px) → Storage `products/{id}/`. معاينة حيّة لبطاقة المنتج. **حارس الامتثال:** إن `isHiddenProduct` صحيحة → شريط أحمر «هذا المنتج ممنوع في متجر نبضة (مكمّلات/أجهزة طبية)» ويُمنع التفعيل. استيراد/تصدير CSV، تكرار منتج، تعديل أسعار جماعي (±%).
4. **🗂️ التصنيفات والمجموعات**: اسم، slug، أيقونة/صورة، ترتيب بالسحب → `site_config/shop`.
5. **🎨 الواجهة**: شرائح سلايدر الرئيسية وبانرات المتجر (صورة، عنوان، وصف، زر، رابط، تاريخ بداية/نهاية) → `site_config/home` و `site_config/shop`، مع معاينة.
6. **🚚 الشحن**: جدول 58 ولاية × (منزل، مكتب، مفعّل) قابل للتعديل الجماعي → `site_config/shipping`.
7. **👥 العميلات**: **مشتقّة من الطلبات** (مجمّعة برقم الهاتف): عدد الطلبات، المُسلَّم، المُرتجع، الإنفاق، آخر طلب، زر حظر. **لا تقرأ مجموعة `users`** (بيانات صحّية خاصّة والقاعدة تمنع ذلك عن قصد). عدد المستخدمات الإجمالي → Cloud Function مجدولة تكتب `stats/users` (count فقط).
8. **📰 المحتوى**: CRUD لـ `dynamic_articles` و `specialized_articles` (المؤلّف ثابت «فريق تحرير نبضة»، غير قابل للتعديل).
9. **🛡️ الإشراف**: `reports` (معاينة المنشور، حذف، تجاهل، حظر الكاتبة) — بنفس منطق تبويب الإشراف في `admin_panel_screen.dart`.
10. **🔔 قائمة الانتظار**: `waitlist` مجمّعة حسب المنتج + «تمّ الإشعار».
11. **🧑‍💼 الطاقم والصلاحيات** (owner فقط): إضافة موظّف بالبريد/UID، الدور، تفعيل/تعطيل.
12. **📜 سجلّ النشاط**: كل تعديل يكتب `admin_logs/{auto}`: `{uid, name, action, target, before?, after?, at}` — عرض قابل للفلترة.
13. **⚙️ الإعدادات**: رقم واتساب المتجر، نصوص سياسات التوصيل والإرجاع، وضع الصيانة.

> **تكافؤ مع لوحة Flutter:** اقرأ `lib/screens/admin/admin_panel_screen.dart` (قراءة فقط) واجرد كل التبويبات (الطلبات، قائمة الانتظار، منتجات المتجر، منتجات الكاروسال، مقالات، منتجات ديناميكية، متخصّصة، …) — **كل ميزة هناك يجب أن تكون موجودة هنا**.

### 7.4 تعديلات `firestore.rules` (أضِف، لا تحذف شيئاً)
```
function staffRole() { return get(/databases/$(database)/documents/staff/$(request.auth.uid)).data.role; }

match /site_config/{doc}       { allow read: if true;            allow write: if isOwnerOrSupervisor(); }
match /products_private/{id}   { allow read, write: if isActiveStaff(); }
match /blocked_phones/{phone}  { allow read, write: if isActiveStaff(); }
match /admin_logs/{id}         { allow create: if isActiveStaff(); allow read: if isAppOwner(); allow update, delete: if false; }
match /stats/{doc}             { allow read: if isActiveStaff(); allow write: if false; }
```
وفي `match /orders/{orderId}` عدّل `allow update` إلى:
```
allow update: if isOwnerOrSupervisor()
  || (isActiveStaff() && staffRole() == 'agent'
      && request.resource.data.diff(resource.data).affectedKeys()
           .hasOnly(['status','history','notes','updatedAt','assignedTo']));
```
اختبر القواعد بـ emulator (`firebase emulators:exec` + سكربت اختبار) قبل `firebase deploy --only firestore:rules`.

**Commit:** `feat(admin): لوحة تحكم ويب احترافية — قيادة، طلبات Kanban، منتجات، شحن، عميلات، صلاحيات، سجلّ`

---

## المرحلة 8 — SEO، الأداء، الاختبار، النشر

- `tool/gen_sitemap.dart` يولّد `web/sitemap.xml`: الصفحات الثابتة + 42 أسبوع حمل + 25 شهر طفل + كل المنتجات النشطة غير المخفيّة + كل المقالات (`/article/<id>`). حدّث `robots.txt` (Disallow: /admin, /account, /cart, /checkout, /app/).
- لكل صفحة: title/description فريد، Open Graph، canonical، `lang="ar" dir="rtl"`.
- الأداء: صور webp + lazy + أبعاد صريحة، خطّ Cairo بـ `display=swap` و preconnect، JS مؤجَّل، Lighthouse ≥ 85 موبايل للرئيسية و صفحة المنتج.
- إمكانية الوصول: تباين كافٍ، `alt` لكل صورة، تنقّل بلوحة المفاتيح في القوائم المنسدلة، `aria-expanded`.
- اختبر على: Chrome desktop 1366px (شاشة المالك)، موبايل 390px، Edge.

### قائمة تحقّق القبول
- [ ] الهيدر نفسه حرفياً في كل الصفحات؛ التنقّل يغيّر المحتوى فقط
- [ ] بعد الدخول: أيقونة الحساب + القائمة المنسدلة بدل الأزرار؛ `/account` صفحة عادية جميلة
- [ ] لا Sidebar في أي مكان من الموقع العام
- [ ] `/pregnancy/week-19` يعرض كل أقسام شاشة الحمل في التطبيق (عدا المخفيّة طبياً)
- [ ] `/baby`، `/cycle`، `/fertility`، `/community` تعمل للزائرة والمسجّلة
- [ ] كل منتج له `/product/<slug>`؛ روابط `/shop/<slug>` القديمة تُحوَّل 301
- [ ] مشاركة رابط منتج على فيسبوك تُظهر الصورة والاسم والسعر
- [ ] طلب COD من زائرة ينجح ويظهر فوراً في `/admin` مع صوت إشعار
- [ ] لا منتج مكمّلات/أجهزة طبية يظهر في أي مكان
- [ ] لا «فريق طبي» ولا اسم طبيب في أي صفحة
- [ ] `/admin` يرفض أي حساب ليس في `staff` نشط؛ `agent` لا يستطيع حذف منتج
- [ ] `/app/` يفتح تطبيق Flutter كاملاً ويعمل تسجيل الدخول فيه
- [ ] `/article/125055` (رابط فيسبوك قديم بـ originalId) يفتح المقال
- [ ] `flutter analyze` = 0 أخطاء جديدة؛ Lighthouse ≥ 85

### النشر
```powershell
.\tool\build_site.ps1
firebase deploy --only firestore:rules,functions,hosting
```
ثم Ctrl+F5 للتحقّق. **وثّق** في `CLAUDE.md` قسماً جديداً «Website (nabda.online)» يشرح: البنية، سكربت البناء، `/app/`، `SITE_HIDE_MEDICAL`، `isHiddenProduct` على الويب، أدوار الطاقم.

---

## 🎨 روح التصميم (للإبداع ضمن هوية واضحة)

- **الاسم الداخلي للأسلوب:** «نعومة فاخرة» — Soft Luxe Maternity.
- **الألوان:** خلفية `#FFF7FA`، وردي الهيدر `#F43F7E → #FF6B9A` (تدرّج)، أساسي `#E91E63`، داكن `#C2185B`، أخضر الثقة `#00897B`، نصوص `#1F1A20` / `#6B6470`.
- **الأشكال:** بطاقات بحواف 24-30px، ظلال وردية ناعمة `0 14px 40px rgba(244,63,126,.08)`، زجاج ضبابي للهيدر والقوائم.
- **الحركة:** نبض القلب في الشعار، رفع البطاقة 4px عند المرور، عدّادات أرقام متحرّكة، ظهور تدريجي عند التمرير (مع احترام `prefers-reduced-motion`).
- **الصور:** صور `landing-assets/` (أمّهات محجّبات بألوان وردية هادئة) — حافظ على نفس الأسلوب في أي صورة جديدة.
- **الأيقونات:** `assets/icons_3d/` للأدوات والأقسام؛ إيموجي للتفاصيل الصغيرة فقط.
- كل الصفحات RTL أوّلاً، وأرقام عربية-غربية (19 لا ١٩) كما في التطبيق.

*انتهى — الصق هذا الملف كاملاً لـ Antigravity. نفّذ المراحل بالترتيب، وانشر على قناة preview بعد كل مرحلة ليراجعها المالك.*
