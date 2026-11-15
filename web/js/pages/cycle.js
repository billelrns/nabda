/**
 * Nabda - Cycle Page Logic (نظير شاشة CyclePage في التطبيق)
 * Author: فريق تحرير نبضة
 */

import { auth, db } from '../firebase-init.js';
import { toDate, getTopArticles, articleCardHtml, getVisibleProducts, productMatchesStage, productCardHtml } from '../utils.js';

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
          // التطبيق يحفظ lastPeriodStart (Timestamp)
          lastPeriodDate = toDate(userProfile.lastPeriodStart || userProfile.lastPeriodDate);
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

    // زائرة: آخر قيمة أدخلتها محلياً (لا نختلق تاريخاً وهمياً أبداً)
    if (!lastPeriodDate) {
      try {
        const loc = JSON.parse(localStorage.getItem('nb_cycle_local') || 'null');
        if (loc) { lastPeriodDate = toDate(loc.start); cycleLength = loc.len || 28; }
      } catch (_) {}
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
  if (!lastPeriodDate) {
    const set = (id, v) => { const el = document.getElementById(id); if (el) el.textContent = v; };
    set('nb-cycle-current-day', '—');
    set('nb-next-period-date', '—');
    set('nb-days-until-next', 'أدخلي تاريخ آخر دورة');
    set('nb-cycle-phase-emoji', '🌸');
    set('nb-cycle-phase-title', 'لنبدأ: متى بدأت آخر دورة؟');
    set('nb-cycle-phase-desc', 'أدخلي تاريخ أول يوم من آخر دورة ومتوسط طولها، وسنلوّن لكِ التقويم بالدورة المتوقّعة وأيام الخصوبة.');
    return;
  }

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

    const newDate = new Date(dateInput.value + 'T00:00:00');
    const newLen = Math.min(45, Math.max(20, parseInt(lengthInput?.value, 10) || 28));
    if (isNaN(newDate) || newDate > new Date()) { alert('يرجى إدخال تاريخ صحيح في الماضي.'); return; }

    lastPeriodDate = newDate;
    cycleLength = newLen;

    if (currentUser) {
      try {
        const FS = window.firebase.firestore;
        const upd = { lastPeriodStart: FS.Timestamp.fromDate(newDate), cycleLength: newLen, updatedAt: FS.FieldValue.serverTimestamp() };
        // لا نغيّر وضع التطبيق لمن هي حامل أو أم — فقط من لا مرحلة لها
        if (!userProfile || !userProfile.lifeStage) upd.lifeStage = 'cycle';
        await db.collection('users').doc(currentUser.uid).set(upd, { merge: true });
        window.nbToast?.('تم حفظ دورتكِ ✓', 'success');
      } catch (err) {
        console.error('Error saving cycle data to firestore:', err);
        window.nbToast?.('تعذّر الحفظ، حاولي مجدداً', 'error');
      }
    } else {
      localStorage.setItem('nb_cycle_local', JSON.stringify({ start: newDate.toISOString(), len: newLen }));
    }

    renderCycleSummary();
    renderCalendar(currentMonthDate);
    window.closeCycleModal();
  };
}

async function loadCycleArticles() {
  const container = document.getElementById('nb-cycle-articles-grid');
  if (!container) return;
  const list = (await getTopArticles('health')).filter((a) => a.subcategoryId === 'health_period_cycle' || /دورة|الطمث|الحيض/.test(a.title));
  const fill = list.length >= 6 ? list : [...list, ...(await getTopArticles('health'))].filter((a, i, arr) => arr.indexOf(a) === i);
  if (!fill.length) { container.parentElement.style.display = 'none'; return; }
  container.innerHTML = fill.slice(0, 4).map((a) => articleCardHtml(a, '🌸')).join('');
}

async function loadCycleProducts() {
  const container = document.getElementById('nb-cycle-products-carousel');
  if (!container) return;
  try {
    const all = await getVisibleProducts();
    const fit = all.filter((p) => productMatchesStage(p, 'mom'));
    const list = [...fit, ...all.filter((p) => !fit.includes(p))].slice(0, 4);
    if (!list.length) { container.parentElement.style.display = 'none'; return; }
    container.innerHTML = list.map(productCardHtml).join('');
  } catch (err) {
    container.parentElement.style.display = 'none';
  }
}
