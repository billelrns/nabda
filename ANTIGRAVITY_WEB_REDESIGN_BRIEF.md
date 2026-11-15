# خطة Antigravity — إعادة تصميم موقع nabda.online + تحويل روابط المقالات لصفحات مستقلّة + تحويل Sidebar إلى TopBar بعد تسجيل الدخول

> ⚠️ **محدَّث:** المرحلتان 4 و 5 (تعديل Sidebar في Flutter و ProfilePage) **ملغاتان** — حلّ محلّهما `ANTIGRAVITY_FULL_WEBSITE_BRIEF.md` (موقع HTML موحّد، و Flutter ينتقل إلى `/app/`). ونفّذ `article.html` بقراءة `web/data/articles/<id>.json` (انظر §0.4 في الملف الجديد) لا `/assets/data/smart_2500_articles.json`.

> **الموجّه إلى:** Antigravity
> **المشروع:** `C:\nabda_app`
> **الهدف:**
> 1. روابط المقالات `/article/<id>` تفتح **صفحة HTML مستقلّة** (لا داخل تطبيق Flutter)
> 2. بعد تسجيل الدخول، إرجاع **شريط التنقّل العلوي** بدل Sidebar اليميني
> 3. وضع أيقونة الحساب في الزاوية العلوية + صفحة حساب أنيقة
> 4. تصميم إبداعي بروح علامة نبضة (💗 وردي + 🌿 أخضر Teal)
> **المدة:** 6-8 ساعات  •  **المخرجات:** 5 مراحل

---

## 📐 المشكلة الحالية (كما يراها المستخدم)

في الصورة الثالثة التي أرسلتها Billel، نرى:
- URL = `nabda.online/article/125055?fbclid=...`
- لا توجد قاعدة rewrite في `firebase.json` لـ `/article/*` (مفرد) — فقط `/articles/**` (جمع)
- النتيجة: URL يتجاوز كل الـ rewrites ويصل إلى `index.html` (Flutter)
- Flutter يفتح الصفحة الرئيسية مع **Sidebar يميني كامل** (رحلة الحمل، الدورة، رعاية الطفل، إلخ)
- المستخدمة ترى واجهة متابعة الحمل بدل المقال الذي أرادت قراءته

في الصور 1 و 2 (Babylist، WhatToExpect) — المرجع الذي يريده المستخدم:
- شريط علوي أفقي (header) مع روابط الأقسام
- أيقونة المستخدمة فوق يمين
- محتوى موسّع بعرض كامل
- لا sidebar عمودي

---

## المرحلة 1 — إصلاح Firebase Hosting: روابط المقالات تفتح HTML مباشر

### الملف: `firebase.json`

**قبل:**
```json
"rewrites": [
  { "source": "/shop", "destination": "/shop.html" },
  { "source": "/shop/**", "destination": "/shop.html" },
  { "source": "/articles", "destination": "/articles.html" },
  { "source": "/articles/**", "destination": "/articles.html" },
  { "source": "/landing", "destination": "/landing.html" },
  { "source": "**", "destination": "/index.html" }
]
```

**بعد:**
```json
"rewrites": [
  { "source": "/shop", "destination": "/shop.html" },
  { "source": "/shop/**", "destination": "/shop.html" },
  { "source": "/articles", "destination": "/articles.html" },
  { "source": "/articles/**", "destination": "/articles.html" },
  { "source": "/article", "destination": "/article.html" },
  { "source": "/article/**", "destination": "/article.html" },
  { "source": "/landing", "destination": "/landing.html" },
  { "source": "**", "destination": "/index.html" }
]
```

### Commit
```
fix(hosting): rewrites لـ /article/* يفتح صفحة article.html المستقلّة
```

---

## المرحلة 2 — صفحة `article.html` المستقلّة (standalone reader)

### الملف الجديد: `web/article.html`

**مواصفات التصميم (إبداعية — بروح Nabda):**

```html
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title id="art-title">نبضة — جاري تحميل المقال...</title>
  <meta name="description" id="art-desc" content="موسوعة نبضة لصحة المرأة والأمومة">
  <!-- Open Graph للمشاركة الاجتماعية -->
  <meta property="og:type" content="article">
  <meta property="og:site_name" content="نبضة — صحة المرأة العربية">
  <meta property="og:title" id="og-title" content="نبضة">
  <meta property="og:description" id="og-desc" content="">
  <meta property="og:image" id="og-image" content="https://nabda.online/favicon.png">
  <meta property="og:url" id="og-url" content="https://nabda.online">
  <meta name="twitter:card" content="summary_large_image">
  <link rel="canonical" id="art-canonical" href="https://nabda.online">
  <link rel="icon" type="image/png" href="favicon.png">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
  <style>
    :root {
      --primary: #E91E63;
      --primary-hover: #c91845;
      --accent: #00897B;
      --soft-pink-bg: linear-gradient(135deg, #FFF8FB 0%, #FFF0F4 100%);
      --card-radius: 20px;
      --shadow-card: 0 10px 40px rgba(228, 37, 88, 0.08);
      --text-dark: #1A1A1A;
      --text-muted: #666;
      --font: 'Cairo', sans-serif;
    }
    * { margin: 0; padding: 0; box-sizing: border-box; font-family: var(--font); }
    body { background: var(--soft-pink-bg); color: var(--text-dark); line-height: 1.8; direction: rtl; }

    /* ─── شريط التنقّل العلوي الموحّد ─── */
    .nav-top {
      background: #fff;
      position: sticky; top: 0; z-index: 100;
      box-shadow: 0 2px 20px rgba(0,0,0,0.06);
    }
    .nav-container {
      max-width: 1280px; margin: 0 auto;
      padding: 14px 24px;
      display: flex; align-items: center; justify-content: space-between; gap: 20px;
    }
    .brand {
      display: flex; align-items: center; gap: 10px; text-decoration: none;
    }
    .brand img { width: 42px; height: 42px; border-radius: 10px; }
    .brand-text { display: flex; flex-direction: column; }
    .brand-name {
      font-size: 22px; font-weight: 900; color: var(--primary); line-height: 1;
    }
    .brand-tag { font-size: 11px; color: var(--text-muted); margin-top: 2px; }
    .nav-links {
      display: flex; gap: 6px; align-items: center;
    }
    .nav-links a {
      padding: 8px 16px; border-radius: 999px;
      text-decoration: none; color: var(--text-dark);
      font-weight: 700; font-size: 14px;
      transition: all 0.2s;
    }
    .nav-links a:hover { background: #FFF0F4; color: var(--primary); }
    .nav-links a.active { background: var(--primary); color: #fff; }
    .nav-right { display: flex; align-items: center; gap: 10px; }
    .btn-app {
      background: linear-gradient(135deg, #E91E63, #FF6090);
      color: #fff; border: none; padding: 10px 20px;
      border-radius: 999px; font-weight: 800; font-size: 13px;
      cursor: pointer; text-decoration: none;
      box-shadow: 0 6px 16px rgba(228,37,88,0.25);
    }
    @media (max-width: 768px) {
      .nav-links { display: none; }
    }

    /* ─── حاوية المقال ─── */
    .article-container {
      max-width: 820px; margin: 30px auto;
      padding: 0 20px;
    }

    /* ─── Hero ─── */
    .hero {
      border-radius: var(--card-radius);
      overflow: hidden;
      box-shadow: var(--shadow-card);
      background: #fff;
      margin-bottom: 20px;
    }
    .hero-img {
      width: 100%; height: 380px; object-fit: cover;
      display: block;
    }
    .hero-content { padding: 28px 32px; }
    .hero-category {
      display: inline-block;
      background: var(--primary); color: #fff;
      padding: 6px 14px; border-radius: 999px;
      font-size: 12px; font-weight: 800; margin-bottom: 12px;
    }
    .hero-title {
      font-size: 32px; font-weight: 900;
      color: var(--text-dark); line-height: 1.3;
      margin-bottom: 16px;
    }
    .hero-meta {
      display: flex; gap: 16px; flex-wrap: wrap;
      color: var(--text-muted); font-size: 13px;
    }
    .hero-meta span { display: flex; align-items: center; gap: 4px; }

    /* ─── Body ─── */
    .article-body {
      background: #fff; padding: 32px;
      border-radius: var(--card-radius);
      box-shadow: var(--shadow-card);
      margin-bottom: 20px;
    }
    .article-body h2 {
      font-size: 22px; font-weight: 900;
      margin: 24px 0 12px; color: var(--primary);
      padding-right: 14px;
      border-right: 4px solid var(--primary);
    }
    .article-body p { font-size: 16px; margin-bottom: 14px; }
    .article-body ul { margin: 14px 0; padding-right: 24px; }
    .article-body li { margin-bottom: 8px; }
    .tip-box {
      background: linear-gradient(135deg, #FFF8E1, #FFF3C4);
      border-right: 4px solid #FBC02D;
      padding: 14px 18px; border-radius: 12px;
      margin: 16px 0;
    }
    .warn-box {
      background: linear-gradient(135deg, #FFEBEE, #FFCDD2);
      border-right: 4px solid #D32F2F;
      padding: 14px 18px; border-radius: 12px;
      margin: 16px 0;
    }
    .faq { margin-top: 24px; }
    .faq-item {
      background: #FFF8FB; padding: 14px 18px;
      border-radius: 12px; margin-bottom: 10px;
      border-right: 3px solid var(--primary);
    }
    .faq-q { font-weight: 800; color: var(--primary); margin-bottom: 6px; }

    /* ─── CTA للتطبيق ─── */
    .cta-app-box {
      background: linear-gradient(135deg, #E91E63, #FF6090);
      color: #fff; padding: 28px; border-radius: var(--card-radius);
      text-align: center; margin: 24px 0;
    }
    .cta-app-box h3 { font-size: 22px; margin-bottom: 10px; }
    .cta-app-box p { opacity: 0.95; margin-bottom: 16px; }
    .cta-app-box a {
      background: #fff; color: var(--primary);
      padding: 12px 28px; border-radius: 999px;
      font-weight: 900; text-decoration: none; display: inline-block;
    }

    /* ─── مقالات ذات صلة ─── */
    .related {
      display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
      gap: 14px; margin-top: 20px;
    }
    .related-card {
      background: #fff; padding: 14px; border-radius: 14px;
      box-shadow: 0 4px 14px rgba(0,0,0,0.05);
      cursor: pointer; transition: transform 0.2s;
      text-decoration: none; color: var(--text-dark);
    }
    .related-card:hover { transform: translateY(-4px); }
    .related-img {
      width: 100%; height: 120px; object-fit: cover;
      border-radius: 10px; margin-bottom: 10px;
    }
    .related-title { font-size: 14px; font-weight: 800; line-height: 1.4; }

    /* ─── Footer ─── */
    .footer {
      background: #1A1A1A; color: #ccc;
      padding: 30px 20px; margin-top: 40px; text-align: center;
    }
    .footer a { color: #FF6090; text-decoration: none; margin: 0 10px; }

    /* Loading */
    .loading { text-align: center; padding: 80px 20px; color: var(--text-muted); }
    .spinner {
      width: 44px; height: 44px; border: 4px solid #FFE0E8;
      border-top-color: var(--primary); border-radius: 50%;
      animation: spin 1s linear infinite; margin: 0 auto 16px;
    }
    @keyframes spin { to { transform: rotate(360deg); } }
  </style>
</head>
<body>
  <!-- ─── Header ─── -->
  <nav class="nav-top">
    <div class="nav-container">
      <a href="/" class="brand">
        <img src="nabda_heart.png" alt="نبضة"/>
        <div class="brand-text">
          <div class="brand-name">نبضة</div>
          <div class="brand-tag">صحة المرأة العربية</div>
        </div>
      </a>
      <div class="nav-links">
        <a href="/landing">الرئيسية</a>
        <a href="/articles?cat=pregnancy">الحمل</a>
        <a href="/articles?cat=baby">رعاية الطفل</a>
        <a href="/articles?cat=beauty">العناية والجمال</a>
        <a href="/articles?cat=health">صحة المرأة</a>
        <a href="/shop">المتجر</a>
        <a href="/articles" class="active">الموسوعة</a>
      </div>
      <div class="nav-right">
        <a href="https://play.google.com/store/apps/details?id=com.nabda.womenhealth"
           class="btn-app" target="_blank">📱 حمّلي التطبيق</a>
      </div>
    </div>
  </nav>

  <!-- ─── Main ─── -->
  <main class="article-container" id="main">
    <div class="loading">
      <div class="spinner"></div>
      <p>جاري تحميل المقال...</p>
    </div>
  </main>

  <!-- ─── Footer ─── -->
  <footer class="footer">
    <p>© نبضة 2026 — كل نبضة حب 💗</p>
    <p style="margin-top:10px">
      <a href="/privacy.html">الخصوصية</a> •
      <a href="/terms.html">الشروط</a> •
      <a href="/landing">الرئيسية</a>
    </p>
  </footer>

  <script>
    // ─── 1) استخرج معرّف المقال من URL ───
    function getArticleId() {
      // دعم: /article/125055  أو  /article?id=125055  أو  /article#125055
      const path = location.pathname;
      if (path.startsWith('/article/')) {
        return decodeURIComponent(path.substring('/article/'.length).split('/')[0].split('?')[0]);
      }
      const q = new URLSearchParams(location.search).get('id');
      if (q) return q;
      if (location.hash) return location.hash.substring(1);
      return null;
    }

    // ─── 2) حمّل JSON و افتح المقال ───
    async function loadArticle() {
      const id = getArticleId();
      if (!id) { showError('رابط غير صالح'); return; }

      try {
        const resp = await fetch('/assets/data/smart_2500_articles.json');
        const articles = await resp.json();
        const art = articles.find(a => String(a.id) === String(id) 
          || String(a.originalId) === String(id));
        if (!art) { showError('المقال غير موجود'); return; }
        renderArticle(art, articles);
      } catch (e) {
        showError('تعذّر تحميل المقال، تحقّقي من الاتصال');
        console.error(e);
      }
    }

    function showError(msg) {
      document.getElementById('main').innerHTML = `
        <div class="loading">
          <div style="font-size:48px">😢</div>
          <h2 style="margin:16px 0">${msg}</h2>
          <a href="/articles" style="color:var(--primary);font-weight:800">
            → تصفّحي كل المقالات
          </a>
        </div>`;
    }

    // ─── 3) ارسم المقال ───
    function renderArticle(art, all) {
      // SEO meta
      document.getElementById('art-title').textContent = art.title + ' — نبضة';
      document.getElementById('art-desc').setAttribute('content', art.summary || '');
      document.getElementById('og-title').setAttribute('content', art.title);
      document.getElementById('og-desc').setAttribute('content', art.summary || '');
      document.getElementById('og-image').setAttribute('content',
        location.origin + '/' + (art.imagePath || 'favicon.png'));
      document.getElementById('og-url').setAttribute('content', location.href);
      document.getElementById('art-canonical').setAttribute('href', location.href);

      const img = art.imagePath 
        ? ('/' + art.imagePath.replace(/^\.?\//, '')) 
        : '/favicon.png';
      const views = art.originalViews || Math.floor(1500 + Math.random() * 3000);

      let sectionsHtml = '';
      (art.sections || []).forEach(s => {
        const paras = (s.content || '').split('\n\n')
          .filter(p => p.trim())
          .map(p => `<p>${p}</p>`).join('');
        const bullets = (s.bulletPoints || []).length 
          ? `<ul>${s.bulletPoints.map(b => `<li>${b}</li>`).join('')}</ul>` : '';
        const tip = s.calloutTip ? `<div class="tip-box">💡 <strong>نصيحة:</strong> ${s.calloutTip}</div>` : '';
        const warn = s.calloutWarning ? `<div class="warn-box">⚠️ <strong>تنبيه:</strong> ${s.calloutWarning}</div>` : '';
        sectionsHtml += `
          <section>
            ${s.title ? `<h2>${s.title}</h2>` : ''}
            ${paras}${bullets}${tip}${warn}
          </section>`;
      });

      let faqsHtml = '';
      if ((art.faqs || []).length) {
        faqsHtml = `
          <div class="faq">
            <h2>❓ أسئلة شائعة</h2>
            ${art.faqs.map(f => `
              <div class="faq-item">
                <div class="faq-q">${f.question}</div>
                <div>${f.answer}</div>
              </div>`).join('')}
          </div>`;
      }

      let toolHtml = '';
      if (art.toolTitle) {
        toolHtml = `
          <div class="cta-app-box">
            <h3>⚡ ${art.toolTitle}</h3>
            <p>${art.toolSubtitle || 'تابعي يومياتك مع نبضة'}</p>
            <a href="https://play.google.com/store/apps/details?id=com.nabda.womenhealth" 
               target="_blank">📱 افتحي الأداة في التطبيق</a>
          </div>`;
      }

      // مقالات ذات صلة (نفس التصنيف — 4 عناوين عشوائية)
      const related = all
        .filter(a => a.categoryId === art.categoryId && a.id !== art.id)
        .sort(() => Math.random() - 0.5).slice(0, 4);
      const relatedHtml = related.length ? `
        <h2 style="margin-top:30px">📚 مقالات ذات صلة</h2>
        <div class="related">
          ${related.map(r => `
            <a href="/article/${r.id}" class="related-card">
              <img class="related-img" 
                src="/${(r.imagePath || 'favicon.png').replace(/^\.?\//, '')}" 
                onerror="this.style.display='none'">
              <div class="related-title">${r.title}</div>
            </a>`).join('')}
        </div>` : '';

      document.getElementById('main').innerHTML = `
        <article class="hero">
          <img class="hero-img" src="${img}" onerror="this.style.display='none'">
          <div class="hero-content">
            <span class="hero-category">${art.categoryName || 'نبضة'}</span>
            <h1 class="hero-title">${art.title}</h1>
            <div class="hero-meta">
              <span>👤 ${art.author || 'فريق تحرير نبضة'}</span>
              <span>⏱️ ${art.readTime || '5 دقائق'}</span>
              <span>👁️ ${views.toLocaleString('ar-EG')} قراءة</span>
            </div>
          </div>
        </article>
        <div class="article-body">
          ${art.summary ? `<p style="font-style:italic;color:#666;margin-bottom:20px">${art.summary}</p>` : ''}
          ${sectionsHtml}
          ${toolHtml}
          ${faqsHtml}
        </div>
        ${relatedHtml}
      `;

      // JSON-LD للمقال (SEO)
      const ld = {
        "@context": "https://schema.org", "@type": "Article",
        "headline": art.title,
        "image": [location.origin + '/' + img.replace(/^\//, '')],
        "author": { "@type": "Organization", "name": art.author || "نبضة" },
        "publisher": { "@type": "Organization", "name": "نبضة",
          "logo": { "@type": "ImageObject", "url": location.origin + "/favicon.png" }},
        "description": art.summary || art.title
      };
      const script = document.createElement('script');
      script.type = 'application/ld+json';
      script.textContent = JSON.stringify(ld);
      document.head.appendChild(script);
    }

    loadArticle();
  </script>
</body>
</html>
```

### Commit
```
feat(web): صفحة article.html مستقلّة بتصميم فاخر — Hero + Sections + CTA + Related + SEO
```

---

## المرحلة 3 — تحديث روابط المشاركة في app Flutter

### الملف: `lib/screens/articles/article_detail_screen.dart`
(والـ `UnifiedArticleReader` إن تمّ إنشاؤه)

### التغيير
```dart
// بدل:
final url = 'https://nabda.online/articles?id=${article.id}';

// استعمل:
final url = 'https://nabda.online/article/${article.id}';
```

**لماذا:** الرابط الجديد `/article/<id>` يفتح `article.html` المستقل مباشرة (لا داخل Flutter)، وهذا هو ما يريده المستخدم.

كذلك في `web/articles.html` عند توليد روابط المشاركة من داخل الModal:
```javascript
// بدل:
const shareUrl = 'https://nabda.online/articles.html?id=' + art.id;
// استعمل:
const shareUrl = 'https://nabda.online/article/' + art.id;
```

### Commit
```
refactor(share): كل روابط مشاركة المقالات تستعمل /article/<id> الجديد
```

---

## المرحلة 4 — تحويل Sidebar إلى TopBar في Flutter Web (بعد تسجيل الدخول)

### الملف: `lib/main.dart` — دالة `_buildWideLayout` و `_buildSidebar`

### المبدأ
على الويب (`kIsWeb && width ≥ 900`):
- **قبل:** `Row(children: [Expanded(content), Sidebar(272px)])` — sidebar يميني
- **بعد:** `Column(children: [TopBar(72px), Expanded(content)])` — شريط علوي

### التنفيذ المقترح

```dart
// استبدل كامل _buildWideLayout:
Widget _buildWideLayout(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFFFF8FB),
    body: Column(
      children: [
        _buildTopNavBar(context),  // شريط علوي جديد
        Expanded(child: _webContent(context)),
      ],
    ),
  );
}

// ─── الشريط العلوي الجديد (TopNavBar) ───
Widget _buildTopNavBar(BuildContext context) {
  const brand = Color(0xFFC2185B);
  const line = Color(0xFFF0E4EA);
  return Container(
    height: 72,
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: line)),
      boxShadow: [BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 2))],
    ),
    child: Row(children: [
      // Logo
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: const [
          _SidebarLogo(),
          SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('نبضة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: brand, height: 1)),
            Text('كل نبضة حب', style: TextStyle(fontSize: 10, color: Color(0xFF9B8F95))),
          ]),
        ]),
      ),
      const SizedBox(width: 24),
      
      // Nav Links (قابلة للتمرير أفقياً)
      Expanded(child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _topNavItem(context, '🏠', 'الرئيسية', tabIndex: 0),
          _topNavItem(context, '🤰', 'رحلة الحمل', tabIndex: 2),
          _topNavItem(context, '📅', 'الدورة', tabIndex: 1),
          _topNavItem(context, '👶', 'رعاية الطفل', tabIndex: 3),
          _topNavItem(context, '🛍️', 'المتجر', tabIndex: 4),
          _topNavItem(context, '👥', 'المجتمع',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityScreen()))),
          _topNavItem(context, '📚', 'المكتبة',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ArticlesHubScreen()))),
          _topNavItem(context, '💕', 'الخصوبة', onTap: () => _soon(context)),
          if (!kHideMedicalFeatures)
            _topNavItem(context, '🩺', 'الأطباء',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorsListScreen()))),
        ]),
      )),
      
      // أيقونة الحساب (يسار الشريط = top-left RTL)
      _buildAccountMenu(context),
      const SizedBox(width: 16),
    ]),
  );
}

Widget _topNavItem(BuildContext context, String emoji, String label, {int? tabIndex, VoidCallback? onTap}) {
  final active = tabIndex != null && _index == tabIndex;
  return InkWell(
    onTap: () {
      if (tabIndex != null) goToTab(tabIndex);
      else if (onTap != null) onTap();
    },
    borderRadius: BorderRadius.circular(999),
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFC2185B) : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(
          fontWeight: FontWeight.bold, fontSize: 13,
          color: active ? Colors.white : const Color(0xFF1F1A20),
        )),
      ]),
    ),
  );
}

// ─── قائمة الحساب (أيقونة + Popup Menu) ───
Widget _buildAccountMenu(BuildContext context) {
  return StreamBuilder<DocumentSnapshot>(
    stream: DB.userDoc.snapshots(),
    builder: (context, snap) {
      final d = (snap.data?.data() as Map<String, dynamic>?) ?? {};
      final name = (d['displayName'] ?? d['name'] ?? 'حسابي') as String;
      return PopupMenuButton<String>(
        offset: const Offset(0, 50),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F4),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFF8D7E5)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const CircleAvatar(radius: 16, backgroundColor: Color(0xFFFCE4EC),
              child: Text('👩🏻', style: TextStyle(fontSize: 16))),
            const SizedBox(width: 8),
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF9B8F95)),
          ]),
        ),
        itemBuilder: (ctx) => [
          _menuItem('profile', '👤', 'الملف الشخصي'),
          _menuItem('favorites', '🔖', 'مقالاتي المحفوظة'),
          _menuItem('posts', '📝', 'منشوراتي'),
          _menuItem('health', '📈', 'صحتي'),
          _menuItem('fiqh', '📗', 'فقه المرأة'),
          _menuItem('duas', '🤲', 'أدعية الذرّية'),
          _menuItem('qadaa', '🌙', 'قضاء الصيام'),
          _menuItem('partner', '💑', 'أشركي زوجكِ'),
          _menuItem('privacy', '🛡️', 'الخصوصية والبيانات'),
          _menuItem('blocked', '🚫', 'المحظورون'),
          _menuItem('support', '💬', 'الدعم'),
          _menuItem('about', 'ℹ️', 'عن نبضة'),
          const PopupMenuDivider(),
          _menuItem('logout', '🚪', 'تسجيل الخروج'),
        ],
        onSelected: (val) => _handleAccountAction(context, val),
      );
    },
  );
}

PopupMenuItem<String> _menuItem(String value, String emoji, String label) =>
  PopupMenuItem(value: value, child: Row(children: [
    Text(emoji, style: const TextStyle(fontSize: 16)),
    const SizedBox(width: 10),
    Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
  ]));

void _handleAccountAction(BuildContext context, String action) {
  final push = (Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  switch (action) {
    case 'profile': push(ProfilePage()); break;
    case 'favorites': push(const FavoritesScreen()); break;
    case 'posts': push(const MyPostsScreen()); break;
    case 'health': push(const HealthTrackersScreen()); break;
    case 'fiqh': push(const WomensFiqhScreen()); break;
    case 'duas': push(const FertilityDuasScreen()); break;
    case 'qadaa': push(const QadaaScreen()); break;
    case 'partner': push(const InvitePartnerScreen()); break;
    case 'privacy': push(const DataControlScreen()); break;
    case 'blocked': push(const BlockedUsersScreen()); break;
    case 'support': push(const SupportScreen()); break;
    case 'about': push(const AboutScreen()); break;
    case 'logout':
      FirebaseAuth.instance.signOut();
      break;
  }
}
```

### احذف
- دالة `_buildSidebar()` كاملة (أو احتفظ بها معطّلة للمرجع)
- `_sidebarDivider()` إن لم تعد مستعملة

### احتفظ بـ `_buildBottomNav` لـ Mobile (narrow layout)

### Commit
```
refactor(web): استبدال Sidebar اليميني بشريط علوي + قائمة حساب (PopupMenu) على desktop
```

---

## المرحلة 5 — تحسين صفحة الملف الشخصي (ProfilePage)

### الملف: `lib/main.dart` → class `ProfilePage` (أو منفصل)

**الفكرة:** صفحة أنيقة بتصميم مُسطّح، معلومات واضحة، أزرار CRUD واضحة.

```dart
// 1) هيدر بالصورة + الاسم + Badge لحظة الحياة
// 2) إحصائيات (دورة سابقة، عدد المقالات المحفوظة، أيام الحمل، إلخ)
// 3) أزرار: تعديل البيانات، تغيير الصورة، إعدادات
// 4) قسم: الأهداف اليومية، النشاط، التفاعل
// 5) زر خطير أحمر: حذف الحساب (gated to show once)
```

### Commit
```
feat(profile): تصميم صفحة Profile حديثة بـ Hero + Stats + Actions
```

---

## 📋 قائمة التحقّق النهائية

- [ ] `firebase.json` فيه rewrites لـ `/article` و `/article/**` → `/article.html`
- [ ] `web/article.html` موجود ويحمّل من `/assets/data/smart_2500_articles.json`
- [ ] الدخول على `https://nabda.online/article/125055` يفتح الصفحة الجديدة (لا Flutter)
- [ ] SEO: title + description + Open Graph + JSON-LD يعمل
- [ ] كل رابط `/articles?id=xxx` بدأ يُستبدل بـ `/article/xxx`
- [ ] في Flutter web (`width ≥ 900`): شريط علوي بدل sidebar
- [ ] أيقونة الحساب في زاوية الشريط العلوي مع قائمة Popup
- [ ] `flutter analyze` = 0 errors
- [ ] الهاتف (narrow) لا يزال يستعمل `BottomNav` كالعادة
- [ ] Deploy: `firebase deploy --only hosting`

---

## ⚠️ ملاحظات هامة

1. **لا تحذف `articles.html`** — ما زال يُستخدم كصفحة فهرس (`/articles`)
2. **بعد `firebase deploy`** قد يحتاج المستخدم مسح cache المتصفّح (Ctrl+F5)
3. **قاعدة rewrite `**`** تظلّ آخر قاعدة — لا تُسبق أبداً
4. تأكّد أن ترتيب الـ rewrites: الأكثر تحديداً أوّلاً، ثمّ الأعمّ
5. اختبر هذه الروابط بعد النشر:
   - `nabda.online/article/125055` → صفحة المقال المستقلّة
   - `nabda.online/articles?cat=pregnancy` → فهرس المقالات
   - `nabda.online/` → Flutter app
   - `nabda.online/landing` → صفحة الهبوط

---

## 🎁 مكافأة اختيارية

**Progressive Web App:** يمكن إضافة `manifest.json` إضافي لصفحة المقالات لحفظها كـ PWA وقراءتها Offline.

**Share buttons:** في `article.html` أضف أزرار مشاركة لـ WhatsApp و Facebook و Twitter.

*انتهى. الصق الملف كـ initial prompt لـ Antigravity.*
