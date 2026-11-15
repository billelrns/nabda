/**
 * Nabda - Pregnancy Page Logic (نظير كامل لشاشة PregnancyWeeksScreen)
 * Author: فريق تحرير نبضة
 */

import { auth, db } from '../firebase-init.js';
import { isHiddenProduct } from '../shop-rules.js';
import { SITE_HIDE_MEDICAL, PLAY_URL } from '../site-config.js';
import { toDate, pregnancyFromStart, pregnancyFromUser, escapeHtml as esc, getTopArticles, articleCardHtml, getVisibleProducts, productMatchesStage, productCardHtml } from '../utils.js';

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
let userPreg = null; // نتيجة pregnancyFromStart للمستخدمة

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
        userProfile = snap.exists ? snap.data() : {};
        handleUserData(userProfile, weekFromUrl);
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
  // تخطّط للحمل (نفس منطق التطبيق: goal == 'trying' أو lifeStage == 'planning')
  if (!profile.pregnancyStartDate && (profile.goal === 'trying' || profile.lifeStage === 'planning')) {
    const tryingCard = document.getElementById('nb-trying-card');
    if (tryingCard) tryingCard.style.display = 'flex';
  }

  userPreg = pregnancyFromUser(profile);
  if (userPreg) {
    userStartDate = userPreg.start;
    // بعد 294 يوماً: سؤال «هل وُلد طفلكِ؟» كما في التطبيق (ما لم تؤكّد أنها ما زالت حاملاً)
    if (userPreg.postTerm && !profile.postTermAck) showBornPrompt();
    // إعادة الرسم بأيامها الفعلية (أو الانتقال لأسبوعها إن لم يُحدَّد أسبوع في الرابط)
    setWeek(weekFromUrl || userPreg.week, false);
    updateUserMilestoneDates(userPreg.start);
  }

  const name = esc(profile.displayName || (currentUser && currentUser.displayName) || 'عزيزتي');
  const userBanner = document.getElementById('nb-user-status-banner');
  if (userBanner) {
    userBanner.innerHTML = userPreg ? `
      <div style="display:flex;align-items:center;gap:12px">
        <span style="font-size:24px">🤰</span>
        <div>
          <div style="font-weight:800;color:var(--nb-ink);font-size:15px">مرحباً ${name} 🌸 أنتِ في الأسبوع ${userPreg.week}</div>
          <div style="font-size:13px;color:var(--nb-ink-3)">بقي ${userPreg.daysLeft} يوماً على الموعد المتوقّع للولادة.</div>
        </div>
      </div>
      <div style="display:flex;gap:8px;flex-wrap:wrap">
        ${currentWeek !== userPreg.week ? `<button class="nb-btn-primary" style="font-size:12.5px;padding:6px 14px" onclick="window.selectPregnancyWeek(${userPreg.week})">أسبوعي الحالي</button>` : ''}
        <button class="nb-btn-secondary" style="font-size:12.5px;padding:6px 14px" onclick="window.openDueDateModal()">تعديل تاريخ الحمل</button>
      </div>` : `
      <div style="display:flex;align-items:center;gap:12px">
        <span style="font-size:24px">🌸</span>
        <div>
          <div style="font-weight:800;color:var(--nb-ink);font-size:15px">مرحباً ${name}، هل أنتِ حامل؟</div>
          <div style="font-size:13px;color:var(--nb-ink-3)">أدخلي تاريخ أول يوم من آخر دورة لنتابع حملكِ أسبوعاً بأسبوع.</div>
        </div>
      </div>
      <button class="nb-btn-primary" style="font-size:12.5px;padding:6px 14px" onclick="window.openDueDateModal()">حدّدي تاريخ الحمل</button>`;
    userBanner.style.display = 'flex';
  }
}

function showBornPrompt() {
  const card = document.getElementById('nb-baby-born-card');
  if (!card) return;
  card.innerHTML = `
    <div style="display:flex;align-items:center;gap:12px">
      <span style="font-size:26px">👶</span>
      <div>
        <div style="font-weight:800;color:#E65100;font-size:15px">تجاوزتِ الأسبوع 42 (${userPreg.days ? Math.floor(userPreg.days / 7) : 42} أسبوعاً). هل وُلد طفلكِ؟</div>
        <div style="font-size:13px;color:#F57C00">عادةً تكون الولادة قد حدثت في هذه المرحلة.</div>
      </div>
    </div>
    <div style="display:flex;gap:8px;flex-wrap:wrap">
      <button class="nb-btn-primary" style="background:#00897B;font-size:13px;padding:8px 18px" onclick="window.nbConfirmBirth()">نعم، وُلد طفلي 🎉</button>
      <button class="nb-btn-secondary" style="font-size:13px;padding:8px 18px" onclick="window.nbStillPregnant()">لا، ما زلت حاملاً</button>
    </div>`;
  card.style.display = 'flex';
}

window.nbConfirmBirth = async function () {
  if (!currentUser) return;
  const FV = window.firebase.firestore.FieldValue;
  const ref = db.collection('users').doc(currentUser.uid);
  try {
    await ref.collection('pregnancyHistory').add({
      startDate: userProfile?.pregnancyStartDate || null, endDate: FV.serverTimestamp(), outcome: 'birth', archivedAt: FV.serverTimestamp(),
    });
    await ref.set({ pregnancyStartDate: null, dueDate: null, postTermAck: null, lifeStage: 'baby', babyBirthDate: FV.serverTimestamp() }, { merge: true });
    sessionStorage.removeItem('nb_user_cache');
    window.nbToast?.('مبروك قدوم صغيركِ 🤍 ننتقل إلى رعاية الطفل', 'success');
    setTimeout(() => { location.href = '/baby'; }, 1200);
  } catch (e) { window.nbToast?.('تعذّر الحفظ، حاولي مجدداً', 'error'); }
};

window.nbStillPregnant = async function () {
  if (!currentUser) return;
  try {
    await db.collection('users').doc(currentUser.uid).set({ postTermAck: true }, { merge: true });
    document.getElementById('nb-baby-born-card').style.display = 'none';
  } catch (_) {}
};

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
  const btn = container?.querySelector(`.nb-week-pill[data-week="${currentWeek}"]`);
  if (!container || !btn) return;
  // حساب يعمل في RTL و LTR: نحرّك الحاوية بالفرق بين مركز الزر ومركزها
  const cr = container.getBoundingClientRect();
  const br = btn.getBoundingClientRect();
  container.scrollBy({ left: (br.left + br.width / 2) - (cr.left + cr.width / 2), behavior: 'smooth' });
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
  const daysLeft = (userPreg && userPreg.week === data.week) ? userPreg.daysLeft : Math.max(0, (40 - data.week) * 7);
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
          <div class="nb-discover-card" onclick="window.showDiscoverByIndex(${cats.indexOf(cat)}, ${(cat.articles || []).indexOf(art)})">
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

window.showDiscoverByIndex = function (ci, ai) {
  const art = discoverData?.categories?.[ci]?.articles?.[ai];
  if (art) window.showDiscoverModal(esc(art.title), esc(art.content || art.summary || ''));
};

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
    const calcWeek = Math.min(42, Math.max(1, Math.floor(diffDays / 7)));
    userPreg = pregnancyFromStart(lmpDate);

    // If logged in, save to Firestore
    if (currentUser) {
      try {
        await db.collection('users').doc(currentUser.uid).set({
          // Timestamp حقيقي — التطبيق يقرأ الحقل كـ Timestamp (النص يُعطّل التطبيق)
          pregnancyStartDate: window.firebase.firestore.Timestamp.fromDate(lmpDate),
          // التطبيق يقدّم dueDate على آخر دورة — نحدّثه معها كي لا يبقى تاريخ قديم
          dueDate: window.firebase.firestore.Timestamp.fromDate(new Date(lmpDate.getTime() + 280 * 86400000)),
          dueDateSource: 'lmp',
          lifeStage: 'pregnant',
          postTermAck: null,
          updatedAt: window.firebase.firestore.FieldValue.serverTimestamp()
        }, { merge: true });
        sessionStorage.removeItem('nb_user_cache');
        window.nbToast?.('تم حفظ تاريخ الحمل ✓', 'success');
      } catch (err) {
        console.error('Error saving pregnancy date:', err);
        window.nbToast?.('تعذّر الحفظ، حاولي مجدداً', 'error');
      }
    }

    setWeek(calcWeek, true);
    updateUserMilestoneDates(lmpDate);
    window.closeDueDateModal();
  };
}

// كاروسال مقالات الحمل (ملف خفيف top_pregnancy.json)
async function loadPregnancyArticles() {
  const container = document.getElementById('nb-pregnancy-articles-carousel');
  if (!container) return;
  const list = (await getTopArticles('pregnancy')).slice(0, 10);
  if (!list.length) { container.closest('section, .nb-section, div').style.display = 'none'; return; }
  container.innerHTML = list.map((a) => articleCardHtml(a, '🤰')).join('');
}

// منتجات قد تهمّكِ — منتجات الحمل أوّلاً، مع استبعاد المكمّلات والأجهزة الطبية
async function loadPregnancyProducts() {
  const container = document.getElementById('nb-pregnancy-products-carousel');
  if (!container) return;
  try {
    const all = await getVisibleProducts();
    const preg = all.filter((p) => productMatchesStage(p, 'pregnant') || productMatchesStage(p, 'mom'));
    const list = [...preg, ...all.filter((p) => !preg.includes(p))].slice(0, 10);
    if (!list.length) { container.parentElement.style.display = 'none'; return; }
    container.innerHTML = list.map(productCardHtml).join('');
  } catch (err) {
    console.error('Error loading pregnancy products:', err);
    container.parentElement.style.display = 'none';
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
