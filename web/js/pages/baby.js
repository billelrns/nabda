/**
 * Nabda - Baby Page Logic (نظير شاشة BabyPage في التطبيق)
 * Author: فريق تحرير نبضة
 */

import { auth, db } from '../firebase-init.js';
import { isHiddenProduct } from '../shop-rules.js';

let babyMonthsData = [];
let currentMonth = 0;
let currentUser = null;
let userProfile = null;

export async function initBabyPage() {
  try {
    const res = await fetch('/data/baby_months.json');
    babyMonthsData = await res.json();
  } catch (err) {
    console.error('Error fetching baby months data:', err);
  }

  const monthFromUrl = parseMonthFromUrl();

  auth.onAuthStateChanged(async (user) => {
    currentUser = user;
    if (user) {
      try {
        const snap = await db.collection('users').doc(user.uid).get();
        if (snap.exists) {
          userProfile = snap.data();
          handleBabyUserData(userProfile, monthFromUrl);
        }
      } catch (e) {
        console.warn('Could not read user profile for baby page:', e);
      }
    } else {
      setupVisitorBanner();
    }
  });

  renderMonthStrip();
  loadBabyArticles();
  loadBabyProducts();

  setMonth(monthFromUrl !== null ? monthFromUrl : 0, false);

  window.addEventListener('popstate', () => {
    const m = parseMonthFromUrl();
    if (m !== null && m !== currentMonth) {
      setMonth(m, false);
    }
  });
}

function parseMonthFromUrl() {
  const path = window.location.pathname;
  const match = path.match(/\/baby\/month-(\d+)/);
  if (match) {
    const m = parseInt(match[1], 10);
    if (m >= 0 && m <= 24) return m;
  }
  const params = new URLSearchParams(window.location.search);
  const qMonth = params.get('month');
  if (qMonth !== null) {
    const m = parseInt(qMonth, 10);
    if (m >= 0 && m <= 24) return m;
  }
  return null;
}

function handleBabyUserData(profile, monthFromUrl) {
  const babyBirthStr = profile.babyBirthDate || profile.childBirthDate;
  const babyName = profile.babyName || profile.childName || 'صغيركِ';

  if (babyBirthStr) {
    const bDate = new Date(babyBirthStr);
    if (!isNaN(bDate.getTime())) {
      const now = new Date();
      const diffMs = now.getTime() - bDate.getTime();
      const diffDays = Math.max(0, Math.floor(diffMs / (1000 * 60 * 60 * 24)));
      const months = Math.min(24, Math.floor(diffDays / 30.4375));

      if (monthFromUrl === null) {
        setMonth(months, false);
      }

      const heroSubtitle = document.getElementById('nb-baby-hero-subtitle');
      if (heroSubtitle) {
        heroSubtitle.textContent = `${babyName} يبلغ من العمر ${months} أشهر و ${diffDays % 30} يوماً 🌸`;
      }
    }
  }

  const banner = document.getElementById('nb-baby-status-banner');
  if (banner) {
    banner.innerHTML = `
      <div style="display:flex;align-items:center;gap:12px">
        <span style="font-size:26px">👶</span>
        <div>
          <div style="font-weight:800;color:var(--nb-ink);font-size:15px">مرحباً بكِ وبـ ${babyName} في نبضة!</div>
          <div style="font-size:13px;color:var(--nb-ink-3)">نتابع معكِ مراحل التطور والنمو شهراً بشهر حتى عامه الثاني.</div>
        </div>
      </div>
      <button class="nb-btn-secondary" style="font-size:12.5px;padding:6px 14px" onclick="window.openBabyProfileModal()">تعديل بيانات الطفل</button>
    `;
    banner.style.display = 'flex';
  }
}

function setupVisitorBanner() {
  const banner = document.getElementById('nb-baby-status-banner');
  if (banner) {
    banner.innerHTML = `
      <div style="display:flex;align-items:center;gap:12px">
        <span style="font-size:26px">🍼</span>
        <div>
          <div style="font-weight:800;color:var(--nb-ink);font-size:15px">دليلكِ الشامل لنمو ورعاية طفلكِ من الولادة حتى سنتين</div>
          <div style="font-size:13px;color:var(--nb-ink-3)">سجّلي حسابكِ لحفظ تاريخ ميلاد طفلكِ ومتابعة تطوره خطوة بخطوة.</div>
        </div>
      </div>
      <div style="display:flex;gap:8px">
        <button class="nb-btn-secondary" style="font-size:12.5px;padding:6px 14px" onclick="window.openBabyProfileModal()">تحديد عمر الطفل</button>
        <a href="/login" class="nb-btn-primary" style="font-size:12.5px;padding:6px 14px">تسجيل الدخول</a>
      </div>
    `;
    banner.style.display = 'flex';
  }
}

function renderMonthStrip() {
  const container = document.getElementById('nb-month-strip');
  if (!container) return;

  let html = '';
  for (let m = 0; m <= 24; m++) {
    const label = m === 0 ? 'المولود' : `${m} شهر`;
    html += `
      <button class="nb-week-pill ${m === currentMonth ? 'active' : ''}" 
              data-month="${m}" 
              onclick="window.selectBabyMonth(${m})"
              aria-label="الشهر ${m}">
        <span class="nb-week-pill-num">${m === 0 ? 'حديث' : m}</span>
        <span class="nb-week-pill-label">${m === 0 ? 'ولادة' : 'شهر'}</span>
      </button>
    `;
  }
  container.innerHTML = html;
  scrollActiveMonthIntoView();
}

function scrollActiveMonthIntoView() {
  const container = document.getElementById('nb-month-strip');
  const activeBtn = container?.querySelector(`.nb-week-pill[data-month="${currentMonth}"]`);
  if (container && activeBtn) {
    const offset = activeBtn.offsetLeft - (container.clientWidth / 2) + (activeBtn.clientWidth / 2);
    container.scrollTo({ left: offset, behavior: 'smooth' });
  }
}

window.selectBabyMonth = function(m) {
  setMonth(m, true);
};

export function setMonth(m, updateHistory = true) {
  currentMonth = m;

  document.querySelectorAll('.nb-week-pill').forEach(btn => {
    btn.classList.toggle('active', parseInt(btn.dataset.month, 10) === m);
  });
  scrollActiveMonthIntoView();

  const data = babyMonthsData.find(item => item.month === m) || getFallbackMonth(m);

  updateBabyHero(data);
  updateBabyContent(data);
  updateBabySeo(m, data);

  if (updateHistory) {
    window.history.pushState({ month: m }, '', `/baby/month-${m}`);
  }
}

function updateBabyHero(data) {
  const title = document.getElementById('nb-baby-hero-title');
  if (title) title.textContent = data.title || `طفلكِ في الشهر ${data.month}`;

  const ageBadge = document.getElementById('nb-baby-age-badge');
  if (ageBadge) ageBadge.textContent = data.ageRange || `${data.month} شهر`;

  const weightVal = document.getElementById('nb-baby-weight');
  if (weightVal) weightVal.textContent = data.avgWeight || '—';

  const heightVal = document.getElementById('nb-baby-height');
  if (heightVal) heightVal.textContent = data.avgHeight || '—';
}

function updateBabyContent(data) {
  // Milestones
  const milContainer = document.getElementById('nb-baby-milestones');
  if (milContainer) {
    const list = data.milestones || [];
    milContainer.innerHTML = list.map(item => `
      <li style="display:flex;align-items:flex-start;gap:10px;line-height:1.7;color:var(--nb-ink-2);font-size:14.5px">
        <span class="nb-check-icon" style="background:#E1F5FE;color:#0288D1">✓</span>
        <span>${item}</span>
      </li>
    `).join('');
  }

  // Feeding & Sleep
  const feedingEl = document.getElementById('nb-baby-feeding');
  if (feedingEl) feedingEl.textContent = data.feeding || 'الرضاعة الطبيعية هي الخيار الأمثل لنمو طفلك.';

  const sleepEl = document.getElementById('nb-baby-sleep');
  if (sleepEl) sleepEl.textContent = data.sleep || 'ساعات نوم هادئة وآمنة.';

  // Activities & Care Tips
  const actEl = document.getElementById('nb-baby-activities');
  if (actEl) actEl.textContent = data.activities || 'أنشطة ترفيهية وتفاعلية ملائمة لعمره.';

  const careEl = document.getElementById('nb-baby-care-tips');
  if (careEl) careEl.textContent = data.careTips || 'نصائح وقائية وعناية يومية بنظافة وترطيب بشرته.';
}

function updateBabySeo(monthNum, data) {
  const title = `رعاية الطفل في ${data.title || `الشهر ${monthNum}`}: النمو والرضاعة والنوم — نبضة`;
  document.title = title;

  const desc = `دليل شامل لنمو الطفل في ${data.title}: الوزن والطول المعتاد، مراحل التطور، نصائح الرضاعة والنوم من فريق تحرير نبضة.`;
  const metaDesc = document.querySelector('meta[name="description"]');
  if (metaDesc) metaDesc.setAttribute('content', desc);
}

async function loadBabyArticles() {
  const container = document.getElementById('nb-baby-articles-carousel');
  if (!container) return;

  try {
    const res = await fetch('/data/articles/index.json');
    const articles = await res.json();
    const babyArts = articles.filter(a => {
      const cat = (a.categoryName || '').toLowerCase();
      const title = (a.title || '').toLowerCase();
      return cat.includes('طفل') || cat.includes('رضيع') || title.includes('طفل') || title.includes('رضيع') || a.categoryId === 3;
    }).slice(0, 6);

    if (babyArts.length === 0) {
      container.parentElement.style.display = 'none';
      return;
    }

    container.innerHTML = babyArts.map(art => `
      <a href="/article/${art.id}" class="nb-art-card">
        <div class="nb-art-img-wrap">
          <img src="${art.imagePath || '/img/articles_bg/art_bg_2.png'}" alt="${art.title}" class="nb-art-img" loading="lazy">
          <span class="nb-art-float-cat">👶 رعاية الطفل</span>
        </div>
        <div class="nb-art-body">
          <h4 class="nb-art-title">${art.title}</h4>
          <p class="nb-art-desc">${art.summary || 'نصائح وإرشادات موثوقة من فريق تحرير نبضة لمرافقة نمو صغيركِ.'}</p>
          <div class="nb-art-footer">
            <span class="nb-art-time">⏱️ ${art.readTime || '3 دقائق'}</span>
            <span class="nb-art-cta">قراءة المقال ←</span>
          </div>
        </div>
      </a>
    `).join('');
  } catch (err) {
    console.error('Error loading baby articles:', err);
  }
}

async function loadBabyProducts() {
  const container = document.getElementById('nb-baby-products-carousel');
  if (!container) return;

  try {
    const snap = await db.collection('products')
      .where('active', '==', true)
      .limit(20)
      .get();

    const products = [];
    snap.forEach(doc => {
      const p = { id: doc.id, ...doc.data() };
      if (!isHiddenProduct(p)) {
        const tags = p.lifeStageTags || [];
        const cat = p.category || '';
        if (tags.includes('baby') || tags.includes('newborn') || cat.includes('طفل') || cat.includes('مولود') || cat.includes('ملابس أطفال')) {
          products.push(p);
        } else if (products.length < 4) {
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
              <div style="font-size:11px;color:var(--nb-pink);font-weight:800;margin-bottom:4px">${p.category || 'مستلزمات الطفل'}</div>
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
    console.error('Error loading baby products:', err);
  }
}

// Modal for setting/updating baby's birth date
window.openBabyProfileModal = function() {
  const modal = document.getElementById('nb-baby-date-modal');
  if (modal) modal.classList.add('open');
};

window.closeBabyProfileModal = function() {
  const modal = document.getElementById('nb-baby-date-modal');
  if (modal) modal.classList.remove('open');
};

window.saveBabyBirthDate = async function() {
  const nameInput = document.getElementById('nb-baby-name-input');
  const dateInput = document.getElementById('nb-baby-birth-input');
  if (!dateInput || !dateInput.value) {
    alert('يرجى اختيار تاريخ ميلاد الطفل.');
    return;
  }

  const bDate = new Date(dateInput.value);
  if (isNaN(bDate.getTime()) || bDate > new Date()) {
    alert('يرجى إدخال تاريخ ميلاد صحيح في الماضي.');
    return;
  }

  const babyName = nameInput?.value?.trim() || 'صغيركِ';
  const now = new Date();
  const diffDays = Math.floor((now.getTime() - bDate.getTime()) / (1000 * 60 * 60 * 24));
  const months = Math.min(24, Math.floor(diffDays / 30.4375));

  if (currentUser) {
    try {
      await db.collection('users').doc(currentUser.uid).set({
        babyBirthDate: dateInput.value,
        babyName: babyName,
        lifeStage: 'baby',
        updatedAt: firebase.firestore.FieldValue.serverTimestamp()
      }, { merge: true });
    } catch (err) {
      console.error('Error saving baby profile:', err);
    }
  }

  setMonth(months, true);
  window.closeBabyProfileModal();
};

function getFallbackMonth(m) {
  return {
    month: m,
    title: `الشهر ${m}`,
    ageRange: `${m} شهر`,
    avgWeight: '—',
    avgHeight: '—',
    milestones: ['متابعة النمو والحركة والتواصل البصري'],
    feeding: 'تغذية متوازنة تناسب مرحلته العمرية.',
    sleep: 'تنظيم أوقات النوم في بيئة هادئة.',
    activities: 'ألعاب تفاعلية خفيفة مع الأم والأب.',
    careTips: 'النظافة والاهتمام اليومي براحة الصغير.',
    author: 'فريق تحرير نبضة'
  };
}
