/**
 * Nabda - Cycle Page Logic (نظير شاشة CyclePage في التطبيق)
 * Author: فريق تحرير نبضة
 */

import { auth, db } from '../firebase-init.js';
import { isHiddenProduct } from '../shop-rules.js';

let currentUser = null;
let userProfile = null;
let currentMonthDate = new Date();
let lastPeriodDate = null;
let cycleLength = 28;
let periodDuration = 5;

export async function initCyclePage() {
  auth.onAuthStateChanged(async (user) => {
    currentUser = user;
    if (user) {
      try {
        const snap = await db.collection('users').doc(user.uid).get();
        if (snap.exists) {
          userProfile = snap.data();
          if (userProfile.lastPeriodDate) {
            lastPeriodDate = new Date(userProfile.lastPeriodDate);
          }
          if (userProfile.cycleLength) {
            cycleLength = parseInt(userProfile.cycleLength, 10) || 28;
          }
          if (userProfile.periodDuration) {
            periodDuration = parseInt(userProfile.periodDuration, 10) || 5;
          }
        }
      } catch (err) {
        console.warn('Error reading user cycle data:', err);
      }
    }

    // Default if not set
    if (!lastPeriodDate || isNaN(lastPeriodDate.getTime())) {
      lastPeriodDate = new Date();
      lastPeriodDate.setDate(lastPeriodDate.getDate() - 14); // mid-cycle default
    }

    renderCycleSummary();
    renderCalendar(currentMonthDate);
  });

  setupCycleModal();
  loadCycleArticles();
  loadCycleProducts();

  // Calendar prev/next buttons
  const prevBtn = document.getElementById('nb-cal-prev');
  const nextBtn = document.getElementById('nb-cal-next');
  if (prevBtn) {
    prevBtn.addEventListener('click', () => {
      currentMonthDate.setMonth(currentMonthDate.getMonth() - 1);
      renderCalendar(currentMonthDate);
    });
  }
  if (nextBtn) {
    nextBtn.addEventListener('click', () => {
      currentMonthDate.setMonth(currentMonthDate.getMonth() + 1);
      renderCalendar(currentMonthDate);
    });
  }
}

function renderCycleSummary() {
  if (!lastPeriodDate) return;

  const now = new Date();
  const diffMs = now.getTime() - lastPeriodDate.getTime();
  const cycleDay = Math.max(1, (Math.floor(diffMs / (1000 * 60 * 60 * 24)) % cycleLength) + 1);

  const dayEl = document.getElementById('nb-cycle-current-day');
  if (dayEl) dayEl.textContent = `اليوم ${cycleDay}`;

  // Next period date
  const nextPeriod = new Date(lastPeriodDate.getTime());
  const cyclesPassed = Math.floor(diffMs / (cycleLength * 24 * 60 * 60 * 1000));
  nextPeriod.setDate(lastPeriodDate.getDate() + ((cyclesPassed + 1) * cycleLength));

  const nextPeriodEl = document.getElementById('nb-next-period-date');
  if (nextPeriodEl) {
    nextPeriodEl.textContent = nextPeriod.toLocaleDateString('ar-DZ', { day: 'numeric', month: 'long' });
  }

  // Days until next period
  const daysUntilNext = Math.max(0, Math.ceil((nextPeriod.getTime() - now.getTime()) / (1000 * 60 * 60 * 24)));
  const daysUntilEl = document.getElementById('nb-days-until-next');
  if (daysUntilEl) {
    daysUntilEl.textContent = daysUntilNext > 0 ? `بقي ${daysUntilNext} يوماً` : 'اليوم المتوقع';
  }

  // Phase analysis
  const phaseTitle = document.getElementById('nb-cycle-phase-title');
  const phaseDesc = document.getElementById('nb-cycle-phase-desc');
  const phaseEmoji = document.getElementById('nb-cycle-phase-emoji');

  const ovulationDay = Math.round(cycleLength - 14);

  if (cycleDay <= periodDuration) {
    if (phaseEmoji) phaseEmoji.textContent = '🩸';
    if (phaseTitle) phaseTitle.textContent = 'أيام الدورة الشهرية (مرحلة الراحة)';
    if (phaseDesc) phaseDesc.textContent = 'جسمكِ يتخلص من بطانة الرحم ويبدأ دورة جديدة. احرصي على التدفئة وشرب المشروبات الدافئة وأخذ قسط وافر من الراحة.';
  } else if (cycleDay < ovulationDay - 2) {
    if (phaseEmoji) phaseEmoji.textContent = '✨';
    if (phaseTitle) phaseTitle.textContent = 'المرحلة الجريبية (تجدد النشاط)';
    if (phaseDesc) phaseDesc.textContent = 'ترتفع مستويات هرمون الإستروجين لتمنحكِ طاقة وحيوية عالية وصفاء في المزاج والبشرة.';
  } else if (cycleDay <= ovulationDay + 2) {
    if (phaseEmoji) phaseEmoji.textContent = '🥚';
    if (phaseTitle) phaseTitle.textContent = 'أيام التبويض ونافذة الخصوبة العالية';
    if (phaseDesc) phaseDesc.textContent = 'تنطلق البويضة من المبيض وتصل الخصوبة إلى ذروتها. هذه الأيام الأنسب لمن تخطط للحمل.';
  } else {
    if (phaseEmoji) phaseEmoji.textContent = '🌙';
    if (phaseTitle) phaseTitle.textContent = 'المرحلة الأصفرية (ما قبل الدورة)';
    if (phaseDesc) phaseDesc.textContent = 'يرتفع هرمون البروجسترون ليهيئ الرحم. قد تشعرين بحاجة للمزيد من النوم وتناول الأطعمة المغذية كالمكسرات والخضار الورقية.';
  }
}

function renderCalendar(date) {
  const calTitle = document.getElementById('nb-cal-month-title');
  if (calTitle) {
    calTitle.textContent = date.toLocaleDateString('ar-DZ', { month: 'long', year: 'numeric' });
  }

  const grid = document.getElementById('nb-calendar-grid');
  if (!grid) return;

  const year = date.getFullYear();
  const month = date.getMonth();

  const firstDay = new Date(year, month, 1).getDay(); // 0 is Sun
  // Convert for RTL / Arabic week starting Saturday: Sat = 0, Sun = 1, Mon = 2, Tue = 3, Wed = 4, Thu = 5, Fri = 6
  const startOffset = (firstDay + 1) % 7;

  const totalDays = new Date(year, month + 1, 0).getDate();

  let html = '';

  // Blank days
  for (let i = 0; i < startOffset; i++) {
    html += '<div class="nb-cal-day empty"></div>';
  }

  const now = new Date();
  const todayStr = `${now.getFullYear()}-${now.getMonth()}-${now.getDate()}`;

  for (let d = 1; d <= totalDays; d++) {
    const curDate = new Date(year, month, d);
    const curStr = `${year}-${month}-${d}`;
    const isToday = curStr === todayStr;

    // Calculate phase status for curDate
    let statusClass = '';
    let statusBadge = '';

    if (lastPeriodDate) {
      const diffDays = Math.floor((curDate.getTime() - lastPeriodDate.getTime()) / (1000 * 60 * 60 * 24));
      const dayInCycle = ((diffDays % cycleLength) + cycleLength) % cycleLength + 1;
      const ovulationDay = Math.round(cycleLength - 14);

      if (dayInCycle <= periodDuration) {
        statusClass = 'period-day';
        statusBadge = '<span class="nb-day-dot period"></span>';
      } else if (dayInCycle >= ovulationDay - 3 && dayInCycle <= ovulationDay + 1) {
        if (dayInCycle === ovulationDay) {
          statusClass = 'ovulation-day';
          statusBadge = '<span class="nb-day-egg">🥚</span>';
        } else {
          statusClass = 'fertile-day';
          statusBadge = '<span class="nb-day-dot fertile"></span>';
        }
      }
    }

    html += `
      <div class="nb-cal-day ${statusClass} ${isToday ? 'today' : ''}">
        <span class="nb-day-num">${d}</span>
        ${statusBadge}
      </div>
    `;
  }

  grid.innerHTML = html;
}

function setupCycleModal() {
  window.openCycleModal = function() {
    const modal = document.getElementById('nb-cycle-log-modal');
    if (modal) modal.classList.add('open');
  };

  window.closeCycleModal = function() {
    const modal = document.getElementById('nb-cycle-log-modal');
    if (modal) modal.classList.remove('open');
  };

  window.saveCycleLog = async function() {
    const dateInput = document.getElementById('nb-cycle-date-input');
    const lengthInput = document.getElementById('nb-cycle-length-input');

    if (!dateInput || !dateInput.value) {
      alert('يرجى إدخال تاريخ بداية الدورة.');
      return;
    }

    const newDate = new Date(dateInput.value);
    const newLen = parseInt(lengthInput?.value, 10) || 28;

    lastPeriodDate = newDate;
    cycleLength = newLen;

    if (currentUser) {
      try {
        await db.collection('users').doc(currentUser.uid).set({
          lastPeriodDate: dateInput.value,
          cycleLength: newLen,
          lifeStage: 'cycle',
          updatedAt: firebase.firestore.FieldValue.serverTimestamp()
        }, { merge: true });
      } catch (err) {
        console.error('Error saving cycle data to firestore:', err);
      }
    }

    renderCycleSummary();
    renderCalendar(currentMonthDate);
    window.closeCycleModal();
  };
}

async function loadCycleArticles() {
  const container = document.getElementById('nb-cycle-articles-grid');
  if (!container) return;

  try {
    const res = await fetch('/data/articles/index.json');
    const articles = await res.json();
    const cycleArts = articles.filter(a => {
      const cat = (a.categoryName || '').toLowerCase();
      const title = (a.title || '').toLowerCase();
      return cat.includes('دورة') || cat.includes('هرمون') || title.includes('دورة') || a.categoryId === 1;
    }).slice(0, 3);

    if (cycleArts.length === 0) {
      container.parentElement.style.display = 'none';
      return;
    }

    container.innerHTML = cycleArts.map(art => `
      <a href="/article/${art.id}" class="nb-art-card">
        <div class="nb-art-img-wrap">
          <img src="${art.imagePath || '/img/articles_bg/art_bg_3.png'}" alt="${art.title}" class="nb-art-img" loading="lazy">
          <span class="nb-art-float-cat">🩸 صحة الدورة</span>
        </div>
        <div class="nb-art-body">
          <h4 class="nb-art-title">${art.title}</h4>
          <p class="nb-art-desc">${art.summary || 'دليل متوازن لفهم دورتكِ الشهرية والتغيرات الهرمونية.'}</p>
          <div class="nb-art-footer">
            <span class="nb-art-time">⏱️ ${art.readTime || '3 دقائق'}</span>
            <span class="nb-art-cta">قراءة المقال ←</span>
          </div>
        </div>
      </a>
    `).join('');
  } catch (err) {
    console.error('Error loading cycle articles:', err);
  }
}

async function loadCycleProducts() {
  const container = document.getElementById('nb-cycle-products-carousel');
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
        const cat = (p.category || '').toLowerCase();
        if (cat.includes('عناية') || cat.includes('راحة') || cat.includes('شخصية')) {
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

    container.innerHTML = products.slice(0, 4).map(p => {
      const slug = p.slug || p.id;
      const img = p.image || p.imageUrl || (p.images && p.images[0]) || '/landing-assets/slide-store.png';
      const price = Number(p.price || 0).toLocaleString();

      return `
        <div class="nb-prod-card" onclick="window.location.href='/product/${slug}'">
          <div class="nb-prod-img-wrap">
            <img src="${img}" alt="${p.name}" class="nb-prod-img" loading="lazy">
          </div>
          <div class="nb-prod-body">
            <div style="font-size:11px;color:var(--nb-pink);font-weight:800;margin-bottom:4px">العناية والراحة</div>
            <h4 style="font-size:14px;font-weight:800;color:var(--nb-ink);line-height:1.4;margin-bottom:8px">${p.name}</h4>
            <div style="font-size:15px;font-weight:900;color:var(--nb-pink);margin-bottom:10px">${price} دج</div>
            <button class="nb-btn-primary" style="width:100%;font-size:12.5px;padding:6px 12px">عرض المنتج</button>
          </div>
        </div>
      `;
    }).join('');
  } catch (err) {
    console.error('Error loading cycle products:', err);
  }
}
