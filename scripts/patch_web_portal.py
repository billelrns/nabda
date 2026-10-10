import os
import sys
import re

sys.stdout.reconfigure(encoding='utf-8')

target_script = r'C:\nabda_app\scripts\build_web_articles_portal.py'

with open(target_script, 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Add Subcategories CSS
subcat_css = """
    /* Subcategories Horizontal Bar */
    .subcategories-menu-row {
      background-color: #fff5f8;
      border-bottom: 1px solid #fce4ec;
      overflow-x: auto;
      white-space: nowrap;
      scrollbar-width: none;
      padding: 10px 0;
      transition: all 0.25s ease;
    }
    .subcategories-menu-row::-webkit-scrollbar {
      display: none;
    }
    .subcategories-menu-container {
      max-width: 1280px;
      margin: 0 auto;
      padding: 0 20px;
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .subcat-pill {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 7px 15px;
      border-radius: 50px;
      font-size: 13px;
      font-weight: 700;
      color: #555;
      background: #ffffff;
      border: 1px solid #f3d4df;
      cursor: pointer;
      transition: all 0.2s ease;
      user-select: none;
    }
    .subcat-pill:hover {
      color: var(--primary-pink);
      border-color: var(--primary-pink);
      background: #fffbfe;
      transform: translateY(-1px);
    }
    .subcat-pill.active {
      background: var(--primary-pink);
      color: #ffffff;
      border-color: var(--primary-pink);
      box-shadow: 0 3px 10px rgba(233, 30, 99, 0.25);
    }
    .subcat-pill-count {
      font-size: 11px;
      padding: 1px 7px;
      border-radius: 20px;
      background: rgba(0, 0, 0, 0.06);
    }
    .subcat-pill.active .subcat-pill-count {
      background: rgba(255, 255, 255, 0.25);
      color: #ffffff;
    }
"""

if '.subcategories-menu-row' not in code:
    code = code.replace('/* Content Wrapper & Breadcrumb */', f'{subcat_css}\n    /* Content Wrapper & Breadcrumb */')
    print("✓ Added Subcategories CSS to build_web_articles_portal.py")

# 2. Add Subcategory Bar HTML directly after categories menu
subcat_html = """  <!-- Horizontal Subcategory Bar -->
  <div class="subcategories-menu-row" id="subcatBar">
    <div class="subcategories-menu-container" id="subcatContainer">
      <!-- Injected via JS based on active category -->
    </div>
  </div>
"""

if 'id="subcatBar"' not in code:
    code = code.replace('  </nav>\n\n  <!-- Main Content Area -->', f'  </nav>\n\n{subcat_html}\n  <!-- Main Content Area -->')
    print("✓ Added Subcategories Bar HTML to build_web_articles_portal.py")

# 3. Add subcategories JavaScript data, functions, and state
js_data_and_funcs = """    const subcategoriesByCategory = {
      pregnancy: [
        { id: 'preg_nutrition_vitamins', name: 'تغذية وفيتامينات الحامل', emoji: '🥗' },
        { id: 'preg_labor_delivery', name: 'المخاض والولادة والتحضير', emoji: '🏥' },
        { id: 'preg_health_tests', name: 'فحوصات وسونار ومتاعب الحمل', emoji: '🔬' },
        { id: 'preg_symptoms_weeks', name: 'أعراض الحمل وتطور الجنين', emoji: '🤰' },
        { id: 'preg_postpartum', name: 'ما بعد الولادة والنفاس', emoji: '🌸' }
      ],
      baby: [
        { id: 'baby_development_growth', name: 'مراحل النمو والتطور', emoji: '🧸' },
        { id: 'baby_breastfeeding_food', name: 'الرضاعة والتغذية والفطام', emoji: '🍼' },
        { id: 'baby_sleep_routine', name: 'نوم الرضيع والروتين والبكاء', emoji: '😴' },
        { id: 'baby_health_care', name: 'صحة الرضيع والتطعيمات', emoji: '👶' },
        { id: 'baby_safety_gear', name: 'سلامة الطفل ومستلزماته', emoji: '🛡️' }
      ],
      fertility: [
        { id: 'fert_ovulation_cycle', name: 'حساب التبويض وعلامات الخصوبة', emoji: '🗓️' },
        { id: 'fert_boost_tips', name: 'تعزيز الخصوبة وفرص الحمل', emoji: '🌸' },
        { id: 'fert_pcos_hormones', name: 'تكيس المبايض واضطراب الهرمونات', emoji: '🩺' },
        { id: 'fert_ivf_medical', name: 'الفحوصات والحقن المجهري', emoji: '🔬' }
      ],
      health: [
        { id: 'health_nutrition_fitness', name: 'الرشاقة وإنقاص الوزن والطبخ', emoji: '🥗' },
        { id: 'health_diseases_prevention', name: 'الأمراض النسائية والوقاية', emoji: '🩺' },
        { id: 'health_mental_wellness', name: 'الصحة النفسية والاسترخاء', emoji: '🕊️' },
        { id: 'health_hormones_lifestyle', name: 'الهرمونات ونمط الحياة', emoji: '💗' },
        { id: 'health_period_cycle', name: 'الدورة الشهرية وأعراضها', emoji: '🩸' }
      ],
      beauty: [
        { id: 'beauty_skincare', name: 'العناية بالبشرة والوجه والنضارة', emoji: '✨' },
        { id: 'beauty_haircare', name: 'العناية بالشعر ومنع التساقط', emoji: '💇‍♀️' },
        { id: 'beauty_body_perfume', name: 'العناية بالجسم والتعطير', emoji: '🌸' },
        { id: 'beauty_natural_recipes', name: 'الوصفات والخلطات الطبيعية', emoji: '🌿' },
        { id: 'beauty_pregnancy_safe', name: 'الجمال الآمن للحوامل والأمهات', emoji: '🤰' }
      ],
      marriage: [
        { id: 'marr_communication', name: 'التفاهم والحوار ولغات الحب', emoji: '💑' },
        { id: 'marr_conflicts_solutions', name: 'إدارة الخلافات والضغوط', emoji: '🕊️' },
        { id: 'marr_parenting_partnership', name: 'الشراكة الوالدية وبناء الأسرة', emoji: '👨‍👩‍👧' },
        { id: 'marr_intimacy', name: 'العلاقة الحميمة والانسجام', emoji: '💖' }
      ]
    };

    let currentSubcategory = 'all';

    function renderSubcategoriesBar() {
      const container = document.getElementById('subcatContainer');
      const bar = document.getElementById('subcatBar');
      if (!container || !bar) return;
      container.innerHTML = '';

      let subList = [];
      if (currentCategory === 'all') {
        Object.values(subcategoriesByCategory).forEach(subs => {
          subList.push(...subs);
        });
      } else {
        subList = subcategoriesByCategory[currentCategory] || [];
      }

      if (subList.length === 0) {
        bar.style.display = 'none';
        return;
      }
      bar.style.display = 'block';

      // Count articles per subcategory
      const subCounts = {};
      let catTotal = 0;
      allArticles.forEach(a => {
        if (currentCategory === 'all' || a.categoryId === currentCategory) {
          catTotal++;
          if (a.subcategoryId) {
            subCounts[a.subcategoryId] = (subCounts[a.subcategoryId] || 0) + 1;
          }
        }
      });

      // 'All' Pill
      const allPill = document.createElement('div');
      allPill.className = `subcat-pill ${currentSubcategory === 'all' ? 'active' : ''}`;
      allPill.onclick = () => selectSubcategory('all', allPill);
      allPill.innerHTML = `<span>🌟 الكل</span><span class="subcat-pill-count">${formatNumber(catTotal)}</span>`;
      container.appendChild(allPill);

      subList.forEach(sub => {
        const count = subCounts[sub.id] || 0;
        if (count === 0 && currentCategory === 'all') return;
        const pill = document.createElement('div');
        pill.className = `subcat-pill ${currentSubcategory === sub.id ? 'active' : ''}`;
        pill.onclick = () => selectSubcategory(sub.id, pill);
        pill.innerHTML = `<span>${sub.emoji} ${sub.name}</span><span class="subcat-pill-count">${formatNumber(count)}</span>`;
        container.appendChild(pill);
      });
    }

    function selectSubcategory(subId, el) {
      currentSubcategory = subId;
      currentPage = 1;
      document.querySelectorAll('.subcat-pill').forEach(p => p.classList.remove('active'));
      if (el) {
        el.classList.add('active');
      } else {
        const target = document.querySelector(`.subcat-pill[onclick*="'${subId}'"]`);
        if (target) target.classList.add('active');
      }
      applyFilterAndRender();
    }
"""

if 'subcategoriesByCategory' not in code:
    code = code.replace('let filteredArticles = [];', f'let filteredArticles = [];\n{js_data_and_funcs}')
    print("✓ Added Subcategories JS Data & Functions")

# Update selectCategory to call renderSubcategoriesBar and reset subcategory
old_select_cat = """    function selectCategory(cat, el) {
      currentCategory = cat;
      currentPage = 1;

      document.querySelectorAll('.cat-menu-item').forEach(item => item.classList.remove('active'));
      if (el) {
        el.classList.add('active');
      } else {
        const target = document.querySelector(`.cat-menu-item[data-cat="${cat}"]`);
        if (target) target.classList.add('active');
      }

      const meta = categoryMeta[cat] || categoryMeta.all;
      const bc = document.getElementById('breadcrumbCurrent');
      if (bc) bc.textContent = meta.name;

      const titleEl = document.getElementById('sectionHeaderTitle');
      if (titleEl) titleEl.textContent = meta.title;

      applyFilterAndRender();
      window.scrollTo({ top: 120, behavior: 'smooth' });
    }"""

new_select_cat = """    function selectCategory(cat, el) {
      currentCategory = cat;
      currentSubcategory = 'all';
      currentPage = 1;

      document.querySelectorAll('.cat-menu-item').forEach(item => item.classList.remove('active'));
      if (el) {
        el.classList.add('active');
      } else {
        const target = document.querySelector(`.cat-menu-item[data-cat="${cat}"]`);
        if (target) target.classList.add('active');
      }

      const meta = categoryMeta[cat] || categoryMeta.all;
      const bc = document.getElementById('breadcrumbCurrent');
      if (bc) bc.textContent = meta.name;

      const titleEl = document.getElementById('sectionHeaderTitle');
      if (titleEl) titleEl.textContent = meta.title;

      renderSubcategoriesBar();
      applyFilterAndRender();
      window.scrollTo({ top: 120, behavior: 'smooth' });
    }"""

if old_select_cat in code:
    code = code.replace(old_select_cat, new_select_cat)
    print("✓ Updated selectCategory function")

# Update applyFilterAndRender to filter by subcategory & rich search
old_apply_filter = """    function applyFilterAndRender() {
      const q = searchQuery.toLowerCase();
      filteredArticles = allArticles.filter(art => {
        const matchCat = (currentCategory === 'all') || (art.categoryId === currentCategory);
        if (!matchCat) return false;
        if (!q) return true;
        return (art.title && art.title.toLowerCase().includes(q)) ||
               (art.summary && art.summary.toLowerCase().includes(q)) ||
               (art.categoryName && art.categoryName.toLowerCase().includes(q)) ||
               (art.badge && art.badge.toLowerCase().includes(q));
      });

      const countPill = document.getElementById('resultsCountPill');
      if (countPill) {
        countPill.textContent = `عرض ${formatNumber(filteredArticles.length)} مقال متاح`;
      }

      renderArticlesGrid();
      renderPagination();
    }"""

new_apply_filter = """    function applyFilterAndRender() {
      const q = searchQuery.toLowerCase();
      filteredArticles = allArticles.filter(art => {
        const matchCat = (currentCategory === 'all') || (art.categoryId === currentCategory);
        if (!matchCat) return false;
        const matchSub = (currentSubcategory === 'all') || (art.subcategoryId === currentSubcategory);
        if (!matchSub) return false;
        if (!q) return true;
        return (art.title && art.title.toLowerCase().includes(q)) ||
               (art.summary && art.summary.toLowerCase().includes(q)) ||
               (art.categoryName && art.categoryName.toLowerCase().includes(q)) ||
               (art.subcategoryName && art.subcategoryName.toLowerCase().includes(q)) ||
               (art.specialty && art.specialty.toLowerCase().includes(q)) ||
               (art.badge && art.badge.toLowerCase().includes(q)) ||
               (art.tags && Array.isArray(art.tags) && art.tags.some(t => t.toLowerCase().includes(q)));
      });

      const countPill = document.getElementById('resultsCountPill');
      if (countPill) {
        countPill.textContent = `عرض ${formatNumber(filteredArticles.length)} مقال متاح`;
      }

      renderArticlesGrid();
      renderPagination();
    }"""

if old_apply_filter in code:
    code = code.replace(old_apply_filter, new_apply_filter)
    print("✓ Updated applyFilterAndRender function")

# Update renderArticlesGrid to display subcategory badge
old_card_cat_label = """              <div class="card-cat-label" style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
                <span style="color: var(--accent-teal); font-weight: 800; font-size: 13px;">${art.iconEmoji || '🌸'} ${art.categoryName}</span>
                <span style="background: var(--light-pink-bg); color: var(--primary-pink); padding: 3px 9px; border-radius: 20px; font-size: 11px; font-weight: 700;">${art.badge || 'موثق طبياً 🩺'}</span>
              </div>"""

new_card_cat_label = """              <div class="card-cat-label" style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; flex-wrap: wrap; gap: 4px;">
                <span style="color: var(--accent-teal); font-weight: 800; font-size: 13px;">${art.iconEmoji || '🌸'} ${art.categoryName}</span>
                ${art.subcategoryName ? `<span style="background: #f0fdf4; color: #166534; border: 1px solid #bbf7d0; padding: 2px 8px; border-radius: 12px; font-size: 11px; font-weight: 700;">${art.subcategoryEmoji || '🔖'} ${art.subcategoryName}</span>` : ''}
                <span style="background: var(--light-pink-bg); color: var(--primary-pink); padding: 3px 9px; border-radius: 20px; font-size: 11px; font-weight: 700;">${art.badge || 'موثق طبياً 🩺'}</span>
              </div>"""

if old_card_cat_label in code:
    code = code.replace(old_card_cat_label, new_card_cat_label)
    print("✓ Added subcategory badge in renderArticlesGrid")

# Update modal breadcrumb
old_modal_bc = """            <span>&gt;</span>
            <span onclick="selectCategory('${art.categoryId}'); closeArticleModal();" style="cursor:pointer;">${art.categoryName}</span>
            <span>&gt;</span>
            <span style="color: #666; font-weight: 500;">عرض المقال</span>"""

new_modal_bc = """            <span>&gt;</span>
            <span onclick="selectCategory('${art.categoryId}'); closeArticleModal();" style="cursor:pointer;">${art.categoryName}</span>
            ${art.subcategoryName ? `<span>&gt;</span><span onclick="selectCategory('${art.categoryId}'); selectSubcategory('${art.subcategoryId}'); closeArticleModal();" style="cursor:pointer; color: #00897B; font-weight: 700;">${art.subcategoryEmoji || ''} ${art.subcategoryName}</span>` : ''}
            <span>&gt;</span>
            <span style="color: #666; font-weight: 500;">عرض المقال</span>"""

if old_modal_bc in code:
    code = code.replace(old_modal_bc, new_modal_bc)
    print("✓ Updated modal breadcrumb")

# Update DOMContentLoaded to read URL params (cat, filter, subcat, id, q) and render subcategories
old_dom_ready = """    window.addEventListener('DOMContentLoaded', () => {
      updateCategoryBadges();
      applyFilterAndRender();
      const urlParams = new URLSearchParams(window.location.search);
      const queryId = urlParams.get('id');
      const hashId = window.location.hash ? window.location.hash.substring(1) : null;
      const targetId = queryId || hashId;
      if (targetId) {
        setTimeout(() => { openArticleModal(targetId); }, 200);
      }
    });"""

new_dom_ready = """    window.addEventListener('DOMContentLoaded', () => {
      updateCategoryBadges();

      const urlParams = new URLSearchParams(window.location.search);
      const queryId = urlParams.get('id');
      const hashId = window.location.hash ? window.location.hash.substring(1) : null;
      const targetId = queryId || hashId;

      const catParam = urlParams.get('cat') || urlParams.get('category') || urlParams.get('filter');
      const subcatParam = urlParams.get('subcat') || urlParams.get('subcategory');
      const searchParam = urlParams.get('q') || urlParams.get('search');

      if (catParam && (categoryMeta[catParam] || catParam === 'all')) {
        selectCategory(catParam);
      } else {
        renderSubcategoriesBar();
        applyFilterAndRender();
      }

      if (subcatParam) {
        selectSubcategory(subcatParam);
      }

      if (searchParam) {
        searchQuery = searchParam;
        const sInput = document.getElementById('searchInput');
        if (sInput) sInput.value = searchParam;
        applyFilterAndRender();
      }

      if (targetId) {
        setTimeout(() => { openArticleModal(targetId); }, 250);
      }
    });"""

if old_dom_ready in code:
    code = code.replace(old_dom_ready, new_dom_ready)
    print("✓ Updated DOMContentLoaded in build_web_articles_portal.py")

# 4. Update build_landing_carousels:
# Button: اكتشفي المزيد ←
# Link: articles.html?cat={filter_val}
# Title: موسوعة نبضة الشاملة (7,000+ مقال)
old_carousel_btn = '<a href="articles.html?filter={filter_val}" class="more-btn">قراءة المزيد ←</a>'
new_carousel_btn = '<a href="articles.html?cat={filter_val}" class="more-btn">اكتشفي المزيد ←</a>'
if old_carousel_btn in code:
    code = code.replace(old_carousel_btn, new_carousel_btn)
    print("✓ Changed carousel button to 'اكتشفي المزيد ←'")

old_carousel_title = 'موسوعة نبضة الشاملة (2,500+ مقال)'
new_carousel_title = 'موسوعة نبضة الشاملة (7,000+ مقال)'
if old_carousel_title in code:
    code = code.replace(old_carousel_title, new_carousel_title)
    print("✓ Updated carousel title to (7,000+ مقال)")

# 5. In update_landing_html, also clean any garbled UTF-8 text or outdated counts
landing_replacements = """
    # Update title and button text across landing.html
    html = html.replace('عرض جميع المقالات (2,500+) ←', 'عرض جميع مقالات موسوعة نبضة (7,000+) ←')
    html = html.replace('موسوعة المقالات (2,500+)', 'موسوعة نبضة (7,000+ مقال)')
    html = html.replace('>الموسوعة 📖<', '>موسوعة نبضة 📚<')
    html = html.replace('قراءة المزيد ←', 'اكتشفي المزيد ←')
"""

if 'html.replace(\'عرض جميع المقالات (2,500+) ←\'' not in code:
    code = code.replace("    if 'id=\"wiki-carousels\"' in html:", f"{landing_replacements}\n    if 'id=\"wiki-carousels\"' in html:")
    print("✓ Added landing.html text updates in update_landing_html")

with open(target_script, 'w', encoding='utf-8') as f:
    f.write(code)

print(f"✓ Saved updated script to {target_script}")
