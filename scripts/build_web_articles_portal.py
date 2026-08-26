import os
import json
import shutil

json_path = r'C:\nabda_app\assets\data\smart_100_articles.json'
with open(json_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

articles = data['articles']
articles_json_str = json.dumps(articles, ensure_ascii=False)

html_content = f"""<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>موسوعة نبضة الطبية والتفاعلية — 100+ مقال ودليل مصور موثق لصحة المرأة والطفل</title>
  <meta name="description" content="موسوعة نبضة الطبية الشاملة والمصورة: أكثر من 100 مقال تفاعلي موثق حول الحمل والولادة، التبويض والخصوبة، رعاية الرضيع، العناية بالبشرة، والصحة النسائية.">
  <link rel="icon" type="image/png" href="favicon.png">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Tajawal:wght@400;500;700;800;900&display=swap" rel="stylesheet">
  <style>
    :root {{
      --primary: #E91E63;
      --primary-dark: #C2185B;
      --primary-light: #FCE4EC;
      --secondary: #9C27B0;
      --teal: #00897B;
      --dark: #1B1320;
      --text: #2C2230;
      --text-muted: #6B6470;
      --bg: #FBF8FA;
      --card-bg: #FFFFFF;
      --border: #F0E8EE;
      --radius: 20px;
      --shadow: 0 10px 30px rgba(0,0,0,0.05);
      --font: 'Tajawal', -apple-system, BlinkMacSystemFont, sans-serif;
    }}

    * {{
      box-sizing: border-box;
      margin: 0;
      padding: 0;
      font-family: var(--font);
    }}

    body {{
      background: var(--bg);
      color: var(--text);
      line-height: 1.6;
      padding-bottom: 60px;
    }}

    /* Header & Nav */
    header {{
      background: rgba(255,255,255,0.95);
      backdrop-filter: blur(12px);
      position: sticky;
      top: 0;
      z-index: 100;
      border-bottom: 1px solid var(--border);
      padding: 14px 24px;
    }}
    .nav-container {{
      max-width: 1200px;
      margin: 0 auto;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }}
    .logo-box {{
      display: flex;
      align-items: center;
      gap: 12px;
      text-decoration: none;
      color: var(--dark);
    }}
    .logo-box img {{
      height: 40px;
      width: 40px;
      border-radius: 12px;
    }}
    .logo-text {{
      font-size: 22px;
      font-weight: 900;
      color: var(--primary);
    }}
    .nav-actions {{
      display: flex;
      align-items: center;
      gap: 12px;
    }}
    .btn-app {{
      background: linear-gradient(135deg, var(--primary), var(--secondary));
      color: #fff;
      padding: 10px 20px;
      border-radius: 50px;
      text-decoration: none;
      font-weight: 700;
      font-size: 14px;
      box-shadow: 0 4px 15px rgba(233,30,99,0.3);
      transition: all 0.2s ease;
    }}
    .btn-app:hover {{
      transform: translateY(-2px);
      box-shadow: 0 6px 20px rgba(233,30,99,0.4);
    }}

    /* Hero Section */
    .hero {{
      background: linear-gradient(180deg, #FFF0F5 0%, var(--bg) 100%);
      padding: 50px 20px 30px;
      text-align: center;
    }}
    .hero-badge {{
      display: inline-block;
      background: var(--primary-light);
      color: var(--primary);
      padding: 6px 16px;
      border-radius: 30px;
      font-size: 13px;
      font-weight: 800;
      margin-bottom: 16px;
    }}
    .hero h1 {{
      font-size: 36px;
      font-weight: 900;
      color: var(--dark);
      margin-bottom: 12px;
      line-height: 1.3;
    }}
    .hero p {{
      font-size: 16px;
      color: var(--text-muted);
      max-width: 650px;
      margin: 0 auto 30px;
    }}

    /* Search & Filter */
    .search-box {{
      max-width: 600px;
      margin: 0 auto 24px;
      position: relative;
    }}
    .search-input {{
      width: 100%;
      padding: 16px 24px 16px 50px;
      border-radius: 50px;
      border: 1.5px solid var(--border);
      background: #fff;
      font-size: 15px;
      box-shadow: var(--shadow);
      outline: none;
      transition: all 0.2s;
    }}
    .search-input:focus {{
      border-color: var(--primary);
      box-shadow: 0 0 0 4px rgba(233,30,99,0.15);
    }}
    .search-icon {{
      position: absolute;
      left: 20px;
      top: 50%;
      transform: translateY(-50%);
      font-size: 20px;
      color: var(--text-muted);
    }}

    .categories-bar {{
      display: flex;
      justify-content: center;
      gap: 10px;
      flex-wrap: wrap;
      max-width: 1000px;
      margin: 0 auto 40px;
    }}
    .cat-btn {{
      background: #fff;
      border: 1.5px solid var(--border);
      padding: 10px 20px;
      border-radius: 50px;
      font-size: 14px;
      font-weight: 700;
      color: var(--text-muted);
      cursor: pointer;
      transition: all 0.2s;
    }}
    .cat-btn:hover, .cat-btn.active {{
      background: var(--primary);
      color: #fff;
      border-color: var(--primary);
      box-shadow: 0 4px 12px rgba(233,30,99,0.25);
    }}

    /* Grid */
    .container {{
      max-width: 1200px;
      margin: 0 auto;
      padding: 0 20px;
    }}
    .articles-grid {{
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
      gap: 24px;
    }}

    /* Article Card with Photo */
    .article-card {{
      background: var(--card-bg);
      border: 1.5px solid var(--border);
      border-radius: var(--radius);
      overflow: hidden;
      transition: all 0.25s ease;
      cursor: pointer;
      display: flex;
      flex-direction: column;
      justify-content: space-between;
      position: relative;
    }}
    .article-card:hover {{
      transform: translateY(-6px);
      box-shadow: 0 18px 40px rgba(0,0,0,0.09);
      border-color: rgba(233,30,99,0.3);
    }}
    .card-thumb-wrap {{
      position: relative;
      height: 180px;
      overflow: hidden;
      background: #ECE4EA;
    }}
    .card-thumb {{
      width: 100%;
      height: 100%;
      object-fit: cover;
      transition: transform 0.4s ease;
    }}
    .article-card:hover .card-thumb {{
      transform: scale(1.05);
    }}
    .card-thumb-badge {{
      position: absolute;
      top: 12px;
      right: 12px;
      background: rgba(255, 255, 255, 0.92);
      backdrop-filter: blur(8px);
      padding: 4px 10px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 800;
      display: flex;
      align-items: center;
      gap: 4px;
      box-shadow: 0 4px 10px rgba(0,0,0,0.1);
    }}
    .card-body {{
      padding: 20px;
      display: flex;
      flex-direction: column;
      flex-grow: 1;
      justify-content: space-between;
    }}
    .card-title {{
      font-size: 17.5px;
      font-weight: 900;
      color: var(--dark);
      line-height: 1.45;
      margin-bottom: 10px;
    }}
    .card-summary {{
      font-size: 13.5px;
      color: var(--text-muted);
      line-height: 1.6;
      margin-bottom: 18px;
      display: -webkit-box;
      -webkit-line-clamp: 2;
      -webkit-box-orient: vertical;
      overflow: hidden;
    }}
    .card-footer {{
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding-top: 14px;
      border-top: 1px solid var(--border);
    }}
    .tool-tag {{
      background: var(--primary-light);
      color: var(--primary);
      font-size: 12px;
      font-weight: 700;
      padding: 5px 12px;
      border-radius: 8px;
      display: flex;
      align-items: center;
      gap: 4px;
    }}
    .read-more {{
      font-size: 13px;
      font-weight: 800;
      color: var(--primary);
    }}

    /* Modal / Reader */
    .modal {{
      display: none;
      position: fixed;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      background: rgba(0,0,0,0.65);
      backdrop-filter: blur(10px);
      z-index: 1000;
      overflow-y: auto;
      padding: 20px;
    }}
    .modal-content {{
      background: #fff;
      max-width: 820px;
      margin: 30px auto;
      border-radius: 24px;
      overflow: hidden;
      position: relative;
      animation: modalFadeIn 0.3s ease;
      box-shadow: 0 25px 60px rgba(0,0,0,0.25);
    }}
    @keyframes modalFadeIn {{
      from {{ opacity: 0; transform: translateY(20px); }}
      to {{ opacity: 1; transform: translateY(0); }}
    }}
    .modal-header-img {{
      position: relative;
      height: 280px;
      width: 100%;
      background: #2C2230;
    }}
    .modal-header-img img {{
      width: 100%;
      height: 100%;
      object-fit: cover;
    }}
    .modal-header-grad {{
      position: absolute;
      inset: 0;
      background: linear-gradient(180deg, rgba(0,0,0,0.2) 0%, rgba(27,19,32,0.85) 100%);
    }}
    .modal-header-content {{
      position: absolute;
      bottom: 24px;
      right: 24px;
      left: 24px;
      color: #fff;
    }}
    .close-modal {{
      position: absolute;
      left: 20px;
      top: 20px;
      font-size: 24px;
      cursor: pointer;
      background: rgba(255,255,255,0.9);
      width: 38px;
      height: 38px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      color: var(--dark);
      border: none;
      z-index: 10;
      transition: transform 0.2s;
    }}
    .close-modal:hover {{
      transform: scale(1.1);
    }}
    .modal-inner-body {{
      padding: 30px 34px;
    }}
    .modal-title {{
      font-size: 24px;
      font-weight: 900;
      color: #fff;
      line-height: 1.35;
      text-shadow: 0 2px 10px rgba(0,0,0,0.5);
    }}
    .section-block {{
      margin-bottom: 28px;
    }}
    .section-title {{
      font-size: 19px;
      font-weight: 800;
      color: var(--dark);
      margin-bottom: 10px;
    }}
    .section-text {{
      font-size: 15.5px;
      color: #3D3540;
      line-height: 1.8;
      margin-bottom: 12px;
    }}
    .bullet-list {{
      list-style: none;
      padding: 0;
      margin: 14px 0;
    }}
    .bullet-list li {{
      padding: 8px 14px;
      margin-bottom: 6px;
      background: #FDF9FA;
      border-right: 4px solid var(--primary);
      border-radius: 6px;
      font-size: 14.5px;
      color: #4A404E;
    }}
    .callout-box {{
      padding: 16px 20px;
      border-radius: 14px;
      margin: 16px 0;
      font-size: 14.5px;
    }}
    .callout-tip {{
      background: #E8F5E9;
      color: #2E7D32;
      border-right: 5px solid #43A047;
    }}
    .callout-warning {{
      background: #FFF3E0;
      color: #E65100;
      border-right: 5px solid #FF9800;
    }}
    .tool-banner {{
      background: linear-gradient(135deg, #FFF0F5, #F3E5F5);
      border: 2px dashed var(--primary);
      padding: 20px;
      border-radius: 16px;
      text-align: center;
      margin: 30px 0;
    }}
    .tool-btn {{
      display: inline-block;
      margin-top: 10px;
      background: var(--primary);
      color: #fff;
      padding: 12px 28px;
      border-radius: 50px;
      font-weight: 800;
      text-decoration: none;
      font-size: 15px;
    }}

    /* Footer */
    footer {{
      text-align: center;
      margin-top: 60px;
      padding: 30px;
      color: var(--text-muted);
      font-size: 14px;
      border-top: 1px solid var(--border);
    }}

    @media (max-width: 768px) {{
      .articles-grid {{
        grid-template-columns: 1fr;
      }}
      .hero h1 {{
        font-size: 26px;
      }}
      .modal-inner-body {{
        padding: 20px;
      }}
      .modal-header-img {{
        height: 220px;
      }}
      .modal-title {{
        font-size: 19px;
      }}
    }}
  </style>
</head>
<body>

  <!-- Header -->
  <header>
    <div class="nav-container">
      <a href="landing.html" class="logo-box">
        <img src="favicon.png" alt="نبضة">
        <span class="logo-text">نبضة</span>
      </a>
      <div class="nav-actions">
        <a href="landing.html" style="color: var(--text-muted); text-decoration: none; font-weight: 700; font-size: 14px;">الرئيسية</a>
        <a href="https://play.google.com/store/apps/details?id=com.nabda.app" target="_blank" class="btn-app">📲 حملي التطبيق</a>
      </div>
    </div>
  </header>

  <!-- Hero Section -->
  <section class="hero">
    <span class="hero-badge">🌟 الموسوعة الطبية المصورة الشاملة</span>
    <h1>أكثر من 100 مقال ودليل طبي موثق بالصور</h1>
    <p>محتوى علمي وطبي تفاعلي مصحوب بصور توضيحية عالية الجودة، يجمع بين دقة المعلومة وسهولة التطبيق وسحر الأدوات الذكية.</p>

    <!-- Search Box -->
    <div class="search-box">
      <input type="text" id="searchInput" class="search-input" placeholder="ابحثي عن موضوع، عَرَض، أو استفسار طبي مصور...">
      <span class="search-icon">🔍</span>
    </div>

    <!-- Category Filters -->
    <div class="categories-bar">
      <button class="cat-btn active" onclick="filterCategory('all', this)">🌟 جميع المقالات (100)</button>
      <button class="cat-btn" onclick="filterCategory('pregnancy', this)">🤰 الحمل والولادة</button>
      <button class="cat-btn" onclick="filterCategory('fertility', this)">🩸 الخصوبة والتبويض</button>
      <button class="cat-btn" onclick="filterCategory('baby', this)">👶 رعاية الرضيع والطفل</button>
      <button class="cat-btn" onclick="filterCategory('beauty', this)">💄 الجمال والعناية</button>
      <button class="cat-btn" onclick="filterCategory('health', this)">🥗 الصحة والرشاقة</button>
      <button class="cat-btn" onclick="filterCategory('marriage', this)">💍 الحياة الزوجية</button>
    </div>
  </section>

  <!-- Articles Grid Container -->
  <main class="container">
    <div id="articlesGrid" class="articles-grid"></div>
  </main>

  <!-- Article Detail Modal -->
  <div id="articleModal" class="modal" onclick="closeModalOnBackdrop(event)">
    <div class="modal-content">
      <button class="close-modal" onclick="closeModal()">×</button>
      <div id="modalBody"></div>
    </div>
  </div>

  <!-- Footer -->
  <footer>
    <p>© 2026 تطبيق نبضة — جميع الحقوق محفوظة. المحتوى الطبي للإرشاد والتوعية ولا يغني عن استشارة الطبيب المختص.</p>
  </footer>

  <script>
    const allArticles = {articles_json_str};
    let currentCategory = 'all';
    let searchQuery = '';

    function renderArticles() {{
      const grid = document.getElementById('articlesGrid');
      grid.innerHTML = '';

      const filtered = allArticles.filter(art => {{
        const matchCat = currentCategory === 'all' || art.categoryId === currentCategory;
        if (!matchCat) return false;
        if (!searchQuery) return true;
        const q = searchQuery.toLowerCase();
        return art.title.toLowerCase().includes(q) || art.summary.toLowerCase().includes(q) || art.categoryName.toLowerCase().includes(q);
      }});

      if (filtered.length === 0) {{
        grid.innerHTML = `
          <div style="grid-column: 1/-1; text-align: center; padding: 60px 20px;">
            <div style="font-size: 48px; margin-bottom: 12px;">🔍</div>
            <h3 style="font-size: 20px; font-weight: 800;">لم نجد نتائج مطابقة لبحثكِ</h3>
            <p style="color: var(--text-muted);">جربي البحث بكلمات أخرى أو اختاري تصنيفاً مختلفاً</p>
          </div>
        `;
        return;
      }}

      filtered.forEach(art => {{
        const card = document.createElement('div');
        card.className = 'article-card';
        card.onclick = () => openArticleModal(art);

        const imgSrc = art.imagePath ? art.imagePath.replace('assets/', '') : 'images/smart_articles/photo_pregnant_belly.jpg';

        card.innerHTML = `
          <div class="card-thumb-wrap">
            <img src="${{imgSrc}}" alt="${{art.title}}" class="card-thumb" onerror="this.src='landing-assets/slide-pregnancy.png'">
            <div class="card-thumb-badge" style="color: ${{art.themeColorHex}}">
              <span>${{art.iconEmoji}}</span> ${{art.categoryName}}
            </div>
          </div>
          <div class="card-body">
            <div>
              <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:8px;">
                <span class="card-badge">${{art.badge}}</span>
                <span style="font-size:12px; color:var(--text-muted);">⏱️ ${{art.readTime}}</span>
              </div>
              <h3 class="card-title">${{art.title}}</h3>
              <p class="card-summary">${{art.summary}}</p>
            </div>
            <div class="card-footer">
              <span class="tool-tag">${{art.toolTitle ? '⚡ ' + art.toolTitle : '📖 نبضة'}}</span>
              <span class="read-more">اقرأي الدليل ←</span>
            </div>
          </div>
        `;
        grid.appendChild(card);
      }});
    }}

    function filterCategory(cat, btn) {{
      currentCategory = cat;
      document.querySelectorAll('.cat-btn').forEach(b => b.classList.remove('active'));
      if (btn) btn.classList.add('active');
      renderArticles();
    }}

    document.getElementById('searchInput').addEventListener('input', (e) => {{
      searchQuery = e.target.value.trim();
      renderArticles();
    }});

    function openArticleModal(art) {{
      const modal = document.getElementById('articleModal');
      const body = document.getElementById('modalBody');

      const imgSrc = art.imagePath ? art.imagePath.replace('assets/', '') : 'images/smart_articles/photo_pregnant_belly.jpg';

      let sectionsHtml = '';
      art.sections.forEach(s => {{
        let bulletsHtml = '';
        if (s.bulletPoints && s.bulletPoints.length > 0) {{
          bulletsHtml = '<ul class="bullet-list">' + s.bulletPoints.map(b => `<li>${{b}}</li>`).join('') + '</ul>';
        }}
        let tipHtml = s.calloutTip ? `<div class="callout-box callout-tip">💡 <strong>نصيحة ذهبية:</strong> ${{s.calloutTip}}</div>` : '';
        let warningHtml = s.calloutWarning ? `<div class="callout-box callout-warning">⚠️ <strong>تنبيه طبي:</strong> ${{s.calloutWarning}}</div>` : '';

        sectionsHtml += `
          <div class="section-block">
            <h3 class="section-title">${{s.title}}</h3>
            <p class="section-text">${{s.content}}</p>
            ${{bulletsHtml}}
            ${{tipHtml}}
            ${{warningHtml}}
          </div>
        `;
      }});

      let faqsHtml = '';
      if (art.faqs && art.faqs.length > 0) {{
        faqsHtml = '<h3 class="section-title" style="margin-top:30px;">❓ أسئلة وإجابات شائعة</h3>';
        art.faqs.forEach(f => {{
          faqsHtml += `
            <div style="background:#FBF8FA; padding:16px; border-radius:12px; margin-bottom:10px;">
              <strong style="color:var(--dark); display:block; margin-bottom:6px;">س: ${{f.question}}</strong>
              <p style="color:#5A5260; font-size:14px; margin:0;">ج: ${{f.answer}}</p>
            </div>
          `;
        }});
      }}

      let toolHtml = '';
      if (art.toolTitle) {{
        toolHtml = `
          <div class="tool-banner">
            <h4 style="font-size:17px; font-weight:800; color:var(--dark);">${{art.toolTitle}}</h4>
            <p style="font-size:13.5px; color:var(--text-muted); margin-top:4px;">${{art.toolSubtitle || ''}}</p>
            <a href="https://play.google.com/store/apps/details?id=com.nabda.app" target="_blank" class="tool-btn">📱 افتحي الأداة في تطبيق نبضة</a>
          </div>
        `;
      }}

      body.innerHTML = `
        <div class="modal-header-img">
          <img src="${{imgSrc}}" alt="${{art.title}}" onerror="this.src='landing-assets/slide-pregnancy.png'">
          <div class="modal-header-grad"></div>
          <div class="modal-header-content">
            <div style="display:flex; gap:8px; align-items:center; margin-bottom:8px;">
              <span style="background:rgba(255,255,255,0.25); padding:3px 10px; border-radius:20px; font-size:12px; font-weight:700;">${{art.iconEmoji}} ${{art.categoryName}}</span>
              <span style="font-size:12px; opacity:0.9;">⏱️ ${{art.readTime}} · ${{art.author}}</span>
            </div>
            <h1 class="modal-title">${{art.title}}</h1>
          </div>
        </div>
        <div class="modal-inner-body">
          <p style="font-size:15px; color:#5A5260; line-height:1.7; background:#FFF5F8; padding:14px 18px; border-radius:12px; border-right:4px solid var(--primary); margin-bottom:24px;">${{art.summary}}</p>
          ${{sectionsHtml}}
          ${{toolHtml}}
          ${{faqsHtml}}
        </div>
      `;

      modal.style.display = 'block';
      document.body.style.overflow = 'hidden';
    }}

    function closeModal() {{
      document.getElementById('articleModal').style.display = 'none';
      document.body.style.overflow = 'auto';
    }}

    function closeModalOnBackdrop(e) {{
      if (e.target.id === 'articleModal') {{
        closeModal();
      }}
    }}

    // Initial Render
    renderArticles();
  </script>
</body>
</html>
"""

web_articles_path = r'C:\nabda_app\web\articles.html'
with open(web_articles_path, 'w', encoding='utf-8') as f:
    f.write(html_content)

# Also ensure assets folder in web exists
web_img_dir = r'C:\nabda_app\web\images\smart_articles'
os.makedirs(web_img_dir, exist_ok=True)
import shutil
src_dir = r'C:\nabda_app\assets\images\smart_articles'
for item in os.listdir(src_dir):
    s = os.path.join(src_dir, item)
    d = os.path.join(web_img_dir, item)
    if os.path.isfile(s):
        shutil.copy2(s, d)

print(f"SUCCESS: Generated complete web articles portal with images at {web_articles_path}")
