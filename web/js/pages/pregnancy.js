/**
 * Nabda - Pregnancy Page Logic (نظير كامل لشاشة PregnancyWeeksScreen)
 * Author: فريق تحرير نبضة
 */

import { auth, db } from '../firebase-init.js';
import { isHiddenProduct } from '../shop-rules.js';
import { SITE_HIDE_MEDICAL, PLAY_STORE_URL } from '../site-config.js';

// Fruit & Object comparisons emoji map for 42 weeks
const FRUIT_EMOJIS = {
  1: '🌱', 2: '🌾', 3: '🌰', 4: '🌾', 5: '🍎', 6: '🫘', 7: '🫐', 8: '🍇', 9: '🍒', 10: '🍓',
  11: '🍋', 12: '🥝', 13: '🍑', 14: '🍋', 15: '🍎', 16: '🥑', 17: '🍐', 18: '🍠', 19: '🫑', 20: '🍌',
  21: '🥕', 22: '🥥', 23: '🥭', 24: '🌽', 25: '🥦', 26: '🥬', 27: '🥗', 28: '🍆', 29: '🎃', 30: '🍈',
  31: '🍍', 32: '🥥', 33: '🍍', 34: '🍈', 35: '🍈', 36: '🥬', 37: '🍉', 38: '🎃', 39: '🍉', 40: '🍉',
  41: '🍉', 42: '👶'
};

let allWeeksData = [];
let discoverData = null;
let currentWeek = 12;
let currentUser = null;
let userProfile = null;
let userStartDate = null;

// Initialize Page
export async function initPregnancyPage() {
  try {
    // 1. Fetch weeks data
    const res = await fetch('/data/pregnancy_weeks.json');
    allWeeksData = await res.json();
  } catch (err) {
    console.error('Error fetching pregnancy weeks data:', err);
  }

  // 2. Fetch discover data
  try {
    const dRes = await fetch('/data/pregnancy_discover.json');
    discoverData = await dRes.json();
  } catch (err) {
    console.error('Error fetching discover data:', err);
  }

  // 3. Determine initial week from URL
  const weekFromUrl = parseWeekFromUrl();

  // 4. Listen to Auth State
  auth.onAuthStateChanged(async (user) => {
    currentUser = user;
    if (user) {
      try {
        const snap = await db.collection('users').doc(user.uid).get();
        if (snap.exists) {
          userProfile = snap.data();
          handleUserData(userProfile, weekFromUrl);
        }
      } catch (e) {
        console.warn('Could not read user profile:', e);
      }
    } else {
      setupVisitorState(weekFromUrl || 12);
    }
  });

  // Render week strip
  renderWeekStrip();

  // Setup tab buttons
  setupTabs();

  // Setup Due Date Modal
  setupDueDateModal();

  // Load articles & products
  loadPregnancyArticles();
  loadPregnancyProducts();

  // Initial render if week was in URL or default 12
  setWeek(weekFromUrl || 12, false);

  // Handle popstate for browser Back/Forward
  window.addEventListener('popstate', () => {
    const w = parseWeekFromUrl();
    if (w && w !== currentWeek) {
      setWeek(w, false);
    }
  });
}

function parseWeekFromUrl() {
  const path = window.location.pathname;
  const match = path.match(/\/pregnancy\/week-(\d+)/);
  if (match) {
    const w = parseInt(match[1], 10);
    if (w >= 1 && w <= 42) return w;
  }
  const params = new URLSearchParams(window.location.search);
  const qWeek = parseInt(params.get('week'), 10);
  if (qWeek >= 1 && qWeek <= 42) return qWeek;
  return null;
}

function handleUserData(profile, weekFromUrl) {
  // If user has goal == trying
  if (profile.goal === 'trying' || profile.lifeStage === 'trying') {
    const tryingCard = document.getElementById('nb-trying-card');
    if (tryingCard) tryingCard.style.display = 'flex';
  }

  // Calculate pregnancy week from pregnancyStartDate or lastPeriodDate
  const startDateStr = profile.pregnancyStartDate || profile.lastPeriodDate;
  if (startDateStr) {
    const start = new Date(startDateStr);
    if (!isNaN(start.getTime())) {
      userStartDate = start;
      const now = new Date();
      const diffMs = now.getTime() - start.getTime();
      const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));

      // Check if baby was already born (> 294 days = 42 weeks)
      if (diffDays > 294) {
        const bornCard = document.getElementById('nb-baby-born-card');
        if (bornCard) bornCard.style.display = 'flex';
      }

      const calculatedWeek = Math.min(42, Math.max(1, Math.floor(diffDays / 7) + 1));
      
      // If no explicit week was in URL, jump to user's week
      if (!weekFromUrl) {
        setWeek(calculatedWeek, false);
      }

      updateUserMilestoneDates(start);
    }
  }

  // Update user banner
  const userBanner = document.getElementById('nb-user-status-banner');
  if (userBanner) {
    userBanner.innerHTML = `
      <div style="display:flex;align-items:center;gap:12px">
        <span style="font-size:24px">🤰</span>
        <div>
          <div style="font-weight:800;color:var(--nb-ink);font-size:15px">مرحباً بكِ، ${profile.displayName || 'عزيزتي الأم'} 🌸</div>
          <div style="font-size:13px;color:var(--nb-ink-3)">رحلتكِ مُتابعة بدقة بحسب موعد ولادتكِ المحفوظ في نبضة.</div>
        </div>
      </div>
      <button class="nb-btn-secondary" style="font-size:12.5px;padding:6px 14px" onclick="window.openDueDateModal()">تعديل تاريخ الحمل</button>
    `;
    userBanner.style.display = 'flex';
  }
}

function setupVisitorState(defaultWeek) {
  const userBanner = document.getElementById('nb-user-status-banner');
  if (userBanner) {
    userBanner.innerHTML = `
      <div style="display:flex;align-items:center;gap:12px">
        <span style="font-size:24px">✨</span>
        <div>
          <div style="font-weight:800;color:var(--nb-ink);font-size:15px">تابعي حملكِ أسبوعاً بأسبوع بدقة متناهية</div>
          <div style="font-size:13px;color:var(--nb-ink-3)">سجّلي حسابكِ المجاني لحفظ موعد ولادتكِ وتلقي التحديثات والنصائح اليومية المخصصة لكِ.</div>
        </div>
      </div>
      <div style="display:flex;gap:8px">
        <button class="nb-btn-secondary" style="font-size:12.5px;padding:6px 14px" onclick="window.openDueDateModal()">حساب أسبوعي</button>
        <a href="/login" class="nb-btn-primary" style="font-size:12.5px;padding:6px 14px">إنشاء حساب</a>
      </div>
    `;
    userBanner.style.display = 'flex';
  }
}

// Render Week Strip (1 to 42)
function renderWeekStrip() {
  const container = document.getElementById('nb-week-strip');
  if (!container) return;

  let html = '';
  for (let w = 1; w <= 42; w++) {
    html += `
      <button class="nb-week-pill ${w === currentWeek ? 'active' : ''}" 
              data-week="${w}" 
              onclick="window.selectPregnancyWeek(${w})"
              aria-label="الأسبوع ${w}">
        <span class="nb-week-pill-num">${w}</span>
        <span class="nb-week-pill-label">الأسبوع</span>
      </button>
    `;
  }
  container.innerHTML = html;

  // Scroll active pill into view
  scrollActivePillIntoView();
}

function scrollActivePillIntoView() {
  const container = document.getElementById('nb-week-strip');
  const activeBtn = container?.querySelector(`.nb-week-pill[data-week="${currentWeek}"]`);
  if (container && activeBtn) {
    const offset = activeBtn.offsetLeft - (container.clientWidth / 2) + (activeBtn.clientWidth / 2);
    container.scrollTo({ left: offset, behavior: 'smooth' });
  }
}

// Select Week
window.selectPregnancyWeek = function(w) {
  setWeek(w, true);
};

export function setWeek(w, updateHistory = true) {
  currentWeek = w;

  // Update strip active state
  document.querySelectorAll('.nb-week-pill').forEach(btn => {
    btn.classList.toggle('active', parseInt(btn.dataset.week, 10) === w);
  });
  scrollActivePillIntoView();

  // Find week data
  const data = allWeeksData.find(item => item.week === w) || getFallbackWeek(w);

  // Update DOM elements
  updateHero(data);
  updateQuickInfo(data);
  updateContentSections(data);
  updateBirthPlanVisibility(w);
  updateDiscoverSections(w);

  // SEO Update
  updateSeo(w, data);

  // Update URL if requested
  if (updateHistory) {
    const newPath = `/pregnancy/week-${w}`;
    window.history.pushState({ week: w }, '', newPath);
  }
}

function updateHero(data) {
  // Title & subtitles
  const wTitle = document.getElementById('nb-hero-week-title');
  if (wTitle) wTitle.textContent = `الأسبوع ${data.week} من الحمل`;

  const wStage = document.getElementById('nb-hero-stage-badge');
  if (wStage) wStage.textContent = `${data.trimesterAr || 'الثلث الثاني'} • ${data.monthAr || 'الشهر الخامس'}`;

  // Image & fruit badge
  const fetusImg = document.getElementById('nb-fetus-img');
  if (fetusImg) {
    fetusImg.src = data.image || `/img/fetus/week_${data.week}.webp`;
    fetusImg.alt = `جنين في الأسبوع ${data.week}`;
  }

  const fruitBadge = document.getElementById('nb-fruit-badge');
  const fruitEmoji = FRUIT_EMOJIS[data.week] || '🌱';
  if (fruitBadge) {
    fruitBadge.innerHTML = `<span style="font-size:18px">${fruitEmoji}</span> بحجم <strong>${data.babySizeAr || 'ثمار الطبيعة'}</strong>`;
  }

  // Progress bar (% of 40 weeks)
  const pct = Math.min(100, Math.round((data.week / 40) * 100));
  const progressFill = document.getElementById('nb-hero-progress-fill');
  const progressText = document.getElementById('nb-hero-progress-pct');
  if (progressFill) progressFill.style.width = `${pct}%`;
  if (progressText) progressText.textContent = `${pct}% من رحلة الحمل`;

  // Days left calculation
  const daysLeft = Math.max(0, (40 - data.week) * 7);
  const daysLeftEl = document.getElementById('nb-hero-days-left');
  if (daysLeftEl) {
    daysLeftEl.textContent = daysLeft > 0 ? `بقي حوالي ${daysLeft} يوماً` : 'حان موعد لقاء ملاككِ الصغير بإذن الله!';
  }

  // Update Dates Milestone in sidebar
  updateSidebarMilestones(data.week);
}

function updateQuickInfo(data) {
  const sizeEl = document.getElementById('nb-info-size');
  const weightEl = document.getElementById('nb-info-weight');
  const lengthEl = document.getElementById('nb-info-length');

  if (sizeEl) sizeEl.textContent = data.babySizeAr || 'حبة عنب';
  if (weightEl) weightEl.textContent = data.babyWeight || '—';
  if (lengthEl) lengthEl.textContent = data.babyLength || '—';
}

function updateContentSections(data) {
  const devEl = document.getElementById('nb-sec-dev');
  const symEl = document.getElementById('nb-sec-symptoms');
  const nutEl = document.getElementById('nb-sec-nutrition');
  const tipEl = document.getElementById('nb-sec-tips');

  if (devEl) devEl.innerHTML = formatParagraphWithChecklist(data.fetalDevAr);
  if (symEl) symEl.innerHTML = formatParagraphWithChecklist(data.symptomsAr);
  if (nutEl) nutEl.innerHTML = formatParagraphWithChecklist(data.nutritionAr);
  if (tipEl) tipEl.innerHTML = formatParagraphWithChecklist(data.tipsAr);
}

function formatParagraphWithChecklist(text) {
  if (!text) return '<p>المعلومات قيد التحديث...</p>';
  const sentences = text.split(/(?<=[.!?؟])\s+/).filter(Boolean);
  
  if (sentences.length <= 2) {
    return `<p style="line-height:1.8;color:var(--nb-ink)">${text}</p>`;
  }

  const intro = sentences.slice(0, 2).join(' ');
  const points = sentences.slice(2);

  return `
    <p style="line-height:1.8;margin-bottom:16px;color:var(--nb-ink);font-size:15px">${intro}</p>
    <ul class="nb-article-checklist">
      ${points.map(pt => `<li><span class="nb-check-icon">✓</span> <span>${pt}</span></li>`).join('')}
    </ul>
  `;
}

function updateBirthPlanVisibility(w) {
  const birthPlanCard = document.getElementById('nb-birth-plan-card');
  if (!birthPlanCard) return;
  // If week >= 32, feature prominently, else provide exploration toggle
  const badge = document.getElementById('nb-birth-plan-badge');
  if (badge) {
    badge.textContent = w >= 32 ? 'موصى بها لمرحلتكِ الحالية (الثلث الثالث)' : 'جاهزة للتحضير المسبق';
  }
}

function updateDiscoverSections(w) {
  const container = document.getElementById('nb-discover-grid');
  if (!container || !discoverData || !discoverData.categories) return;

  const cats = discoverData.categories;
  container.innerHTML = cats.map(cat => `
    <div class="nb-discover-cat-box">
      <div class="nb-discover-cat-header">
        <span style="font-size:22px">${cat.emoji || '💡'}</span>
        <h4 style="font-size:16px;font-weight:800;color:var(--nb-ink);margin:0">${cat.name}</h4>
      </div>
      <div class="nb-discover-subgrid">
        ${(cat.articles || []).slice(0, 3).map(art => `
          <div class="nb-discover-card" onclick="window.showDiscoverModal('${escapeHtml(art.title)}', '${escapeHtml(art.content)}')">
            <div class="nb-discover-card-img" style="background-image:url('${art.image}')">
              <span class="nb-discover-emoji">${art.emoji || '✨'}</span>
            </div>
            <div class="nb-discover-card-body">
              <div class="nb-discover-card-title">${art.title}</div>
              <div class="nb-discover-card-summary">${art.summary || ''}</div>
              <span class="nb-discover-read-btn">قراءة الدليل ←</span>
            </div>
          </div>
        `).join('')}
      </div>
    </div>
  `).join('');
}

window.showDiscoverModal = function(title, content) {
  let modal = document.getElementById('nb-discover-modal');
  if (!modal) {
    modal = document.createElement('div');
    modal.id = 'nb-discover-modal';
    modal.className = 'nb-modal-backdrop';
    document.body.appendChild(modal);
  }

  modal.innerHTML = `
    <div class="nb-modal-card">
      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px">
        <h3 style="font-size:18px;font-weight:800;color:var(--nb-ink);margin:0">${title}</h3>
        <button class="nb-modal-close" onclick="document.getElementById('nb-discover-modal').classList.remove('open')">✕</button>
      </div>
      <div style="line-height:1.8;color:var(--nb-ink-2);font-size:15px;margin-bottom:20px;white-space:pre-line">${content}</div>
      <div style="display:flex;justify-content:space-between;align-items:center;padding-top:14px;border-top:1px solid #F8E1EA">
        <span style="font-size:12px;color:var(--nb-ink-3)">المصدر: فريق تحرير نبضة</span>
        <button class="nb-btn-primary" style="font-size:13px;padding:8px 18px" onclick="document.getElementById('nb-discover-modal').classList.remove('open')">إغلاق</button>
      </div>
    </div>
  `;
  modal.classList.add('open');
};

function updateSidebarMilestones(weekNum) {
  const dueDateVal = document.getElementById('nb-sidebar-due-date');
  const daysVal = document.getElementById('nb-sidebar-days-left');
  const trimVal = document.getElementById('nb-sidebar-trimester');

  let trimester = 'الثلث الأول (الأسابيع 1-13)';
  if (weekNum >= 14 && weekNum <= 27) trimester = 'الثلث الثاني (الأسابيع 14-27)';
  else if (weekNum >= 28) trimester = 'الثلث الثالث (الأسابيع 28-40)';

  if (trimVal) trimVal.textContent = trimester;

  if (userStartDate) {
    const due = new Date(userStartDate.getTime() + (280 * 24 * 60 * 60 * 1000));
    if (dueDateVal) dueDateVal.textContent = due.toLocaleDateString('ar-DZ', { year: 'numeric', month: 'long', day: 'numeric' });
    const now = new Date();
    const diff = Math.max(0, Math.ceil((due.getTime() - now.getTime()) / (1000 * 60 * 60 * 24)));
    if (daysVal) daysVal.textContent = `${diff} يوماً`;
  } else {
    // Estimations based on week
    const weeksRemaining = Math.max(0, 40 - weekNum);
    const approxDays = weeksRemaining * 7;
    const estDate = new Date();
    estDate.setDate(estDate.getDate() + approxDays);

    if (dueDateVal) dueDateVal.textContent = estDate.toLocaleDateString('ar-DZ', { year: 'numeric', month: 'long', day: 'numeric' });
    if (daysVal) daysVal.textContent = `${approxDays} يوماً`;
  }
}

function updateUserMilestoneDates(startDate) {
  const due = new Date(startDate.getTime() + (280 * 24 * 60 * 60 * 1000));
  const datesRow = document.getElementById('nb-hero-dates-row');
  if (datesRow) {
    const startStr = startDate.toLocaleDateString('ar-DZ', { month: 'short', day: 'numeric', year: 'numeric' });
    const dueStr = due.toLocaleDateString('ar-DZ', { month: 'short', day: 'numeric', year: 'numeric' });
    datesRow.innerHTML = `من <strong>${startStr}</strong> إلى <strong>${dueStr}</strong> (الموعد المقدر)`;
  }
}

// Mobile Tabs
function setupTabs() {
  const tabs = document.querySelectorAll('.nb-content-tab');
  tabs.forEach(tab => {
    tab.addEventListener('click', () => {
      tabs.forEach(t => t.classList.remove('active'));
      tab.classList.add('active');
      const targetId = tab.dataset.target;
      document.querySelectorAll('.nb-week-section-card').forEach(card => {
        if (targetId === 'all') {
          card.style.display = 'block';
        } else {
          card.style.display = card.id === targetId ? 'block' : 'none';
        }
      });
    });
  });
}

// Due Date Calculator Modal
function setupDueDateModal() {
  window.openDueDateModal = function() {
    const modal = document.getElementById('nb-due-date-modal');
    if (modal) modal.classList.add('open');
  };

  window.closeDueDateModal = function() {
    const modal = document.getElementById('nb-due-date-modal');
    if (modal) modal.classList.remove('open');
  };

  window.saveCalculatedDueDate = async function() {
    const input = document.getElementById('nb-calc-lmp-date');
    if (!input || !input.value) {
      alert('يرجى تحديد تاريخ أول يوم من آخر دورة شهرية.');
      return;
    }

    const lmpDate = new Date(input.value);
    if (isNaN(lmpDate.getTime()) || lmpDate > new Date()) {
      alert('يرجى إدخال تاريخ صحيح في الماضي القريب.');
      return;
    }

    userStartDate = lmpDate;
    const now = new Date();
    const diffDays = Math.floor((now.getTime() - lmpDate.getTime()) / (1000 * 60 * 60 * 24));
    const calcWeek = Math.min(42, Math.max(1, Math.floor(diffDays / 7) + 1));

    // If logged in, save to Firestore
    if (currentUser) {
      try {
        await db.collection('users').doc(currentUser.uid).set({
          pregnancyStartDate: input.value,
          lifeStage: 'pregnant',
          updatedAt: firebase.firestore.FieldValue.serverTimestamp()
        }, { merge: true });
      } catch (err) {
        console.error('Error saving pregnancy date:', err);
      }
    }

    setWeek(calcWeek, true);
    updateUserMilestoneDates(lmpDate);
    window.closeDueDateModal();
  };
}

// Articles Carousel (from web/data/articles/index.json)
async function loadPregnancyArticles() {
  const container = document.getElementById('nb-pregnancy-articles-carousel');
  if (!container) return;

  try {
    const res = await fetch('/data/articles/index.json');
    const articles = await res.json();

    // Filter articles for pregnancy category or tags
    const pregArticles = articles.filter(a => {
      const cat = (a.categoryName || '').toLowerCase();
      const title = (a.title || '').toLowerCase();
      return cat.includes('حمل') || title.includes('حمل') || title.includes('جنين') || a.categoryId === 2 || a.categoryId === 'pregnancy';
    }).slice(0, 8);

    if (pregArticles.length === 0) {
      container.parentElement.style.display = 'none';
      return;
    }

    container.innerHTML = pregArticles.map(art => `
      <a href="/article/${art.id}" class="nb-art-card">
        <div class="nb-art-img-wrap">
          <img src="${art.imagePath || '/img/articles_bg/art_bg_1.png'}" alt="${art.title}" class="nb-art-img" loading="lazy">
          <span class="nb-art-float-cat">🤰 ${art.categoryName || 'موسوعة الحمل'}</span>
        </div>
        <div class="nb-art-body">
          <div>
            <h4 class="nb-art-title">${art.title}</h4>
            <p class="nb-art-desc">${art.summary || 'دليل شامل وموثوق من فريق تحرير نبضة لمرافقتكِ أسبوعاً بأسبوع.'}</p>
          </div>
          <div class="nb-art-footer">
            <span class="nb-art-time">⏱️ ${art.readTime || '3 دقائق'} قراءة</span>
            <span class="nb-art-cta">قراءة المقال ←</span>
          </div>
        </div>
      </a>
    `).join('');
  } catch (err) {
    console.error('Error loading pregnancy articles:', err);
  }
}

// Pregnancy Recommended Products Carousel (filtered by isHiddenProduct)
async function loadPregnancyProducts() {
  const container = document.getElementById('nb-pregnancy-products-carousel');
  if (!container) return;

  try {
    const snap = await db.collection('products')
      .where('active', '==', true)
      .limit(20)
      .get();

    const products = [];
    snap.forEach(doc => {
      const p = { id: doc.id, ...doc.data() };
      // Filter compliance (no medical/supplements)
      if (!isHiddenProduct(p)) {
        // Prefer products tagged for pregnancy/mom or maternity
        const tags = p.lifeStageTags || [];
        const cat = p.category || '';
        if (tags.includes('pregnant') || tags.includes('mom') || cat.includes('حمل') || cat.includes('أمومة') || cat.includes('رضاعة')) {
          products.push(p);
        } else if (products.length < 6) {
          products.push(p);
        }
      }
    });

    if (products.length === 0) {
      container.parentElement.style.display = 'none';
      return;
    }

    container.innerHTML = products.slice(0, 8).map(p => {
      const slug = p.slug || p.id;
      const img = p.image || p.imageUrl || (p.images && p.images[0]) || '/landing-assets/slide-store.png';
      const price = Number(p.price || 0).toLocaleString();

      return `
        <div class="nb-prod-card" onclick="window.location.href='/product/${slug}'">
          <div class="nb-prod-img-wrap">
            <img src="${img}" alt="${p.name}" class="nb-prod-img" loading="lazy">
          </div>
          <div class="nb-prod-body">
            <div>
              <div style="font-size:11px;color:var(--nb-pink);font-weight:800;margin-bottom:4px">${p.category || 'العناية بالحامل'}</div>
              <h4 style="font-size:14px;font-weight:800;color:var(--nb-ink);line-height:1.4;margin-bottom:8px">${p.name}</h4>
            </div>
            <div>
              <div style="font-size:15px;font-weight:900;color:var(--nb-pink);margin-bottom:10px">${price} دج</div>
              <button class="nb-btn-primary" style="width:100%;font-size:12.5px;padding:6px 12px">عرض المنتج</button>
            </div>
          </div>
        </div>
      `;
    }).join('');
  } catch (err) {
    console.error('Error loading pregnancy products:', err);
  }
}

// Print Birth Plan
window.printBirthPlan = function() {
  window.print();
};

function updateSeo(weekNum, data) {
  const title = `الأسبوع ${weekNum} من الحمل: حجم الجنين وتطوّره ونصائح — نبضة`;
  document.title = title;

  const desc = (data.fetalDevAr || '').slice(0, 155) + '...';
  const metaDesc = document.querySelector('meta[name="description"]');
  if (metaDesc) metaDesc.setAttribute('content', desc);

  // Canonical
  let canonical = document.querySelector('link[rel="canonical"]');
  if (!canonical) {
    canonical = document.createElement('link');
    canonical.rel = 'canonical';
    document.head.appendChild(canonical);
  }
  canonical.href = `https://nabda.online/pregnancy/week-${weekNum}`;

  // Structured Data (JSON-LD)
  let script = document.getElementById('nb-json-ld');
  if (!script) {
    script = document.createElement('script');
    script.id = 'nb-json-ld';
    script.type = 'application/ld+json';
    document.head.appendChild(script);
  }

  const jsonLd = {
    '@context': 'https://schema.org',
    '@type': 'Article',
    'headline': title,
    'description': desc,
    'image': data.image ? `https://nabda.online${data.image}` : undefined,
    'author': {
      '@type': 'Organization',
      'name': 'فريق تحرير نبضة',
      'url': 'https://nabda.online'
    },
    'publisher': {
      '@type': 'Organization',
      'name': 'نبضة',
      'logo': {
        '@type': 'ImageObject',
        'url': 'https://nabda.online/favicon.png'
      }
    },
    'mainEntityOfPage': {
      '@type': 'WebPage',
      '@id': `https://nabda.online/pregnancy/week-${weekNum}`
    }
  };
  script.textContent = JSON.stringify(jsonLd);
}

function getFallbackWeek(w) {
  return {
    week: w,
    babySizeAr: 'تطور مميز',
    babyWeight: '—',
    babyLength: '—',
    trimesterAr: w <= 13 ? 'الثلث الأول' : (w <= 27 ? 'الثلث الثاني' : 'الثلث الثالث'),
    monthAr: `الشهر ${Math.ceil(w / 4.3)}`,
    fetalDevAr: `في الأسبوع ${w} من الحمل، يواصل جنينك نموه الرائع داخل رحمك بكل دقة. تتطور أعضاؤه وحواسه يومياً استعداداً لاستقبال الحياة.`,
    symptomsAr: `تغيرات هرمونية وجسدية طبيعية تصاحب الأسبوع ${w}. حافظي على راحتك واحرصي على شرب الماء والنوم الكافي.`,
    nutritionAr: `أكثري من الخضراوات الورقية والفواكه والبروتينات الصحية لضمان التغذية المثالية لكِ ولجنينكِ.`,
    tipsAr: `استمتعي بكل لحظة من هذا الأسبوع وخصصي وقتاً للراحة النفسية والدعاء لصغيرك بالصحة والعافية.`,
    image: `/img/fetus/week_${w}.webp`,
    author: 'فريق تحرير نبضة'
  };
}

function escapeHtml(str) {
  if (!str) return '';
  return str.replace(/[&<>"']/g, m => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
  }[m]));
}
