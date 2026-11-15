/**
 * Nabda - Baby Page Logic (نظير شاشة BabyPage في التطبيق)
 * Author: فريق تحرير نبضة
 */

import { auth, db } from '../firebase-init.js';
import { toDate, escapeHtml as esc, getTopArticles, articleCardHtml, getVisibleProducts, productMatchesStage, productCardHtml } from '../utils.js';

let babyMonthsData = [];
let currentMonth = 0;
let currentUser = null;
let userProfile = null;
// ── عدّة أطفال، متزامنون لحظياً مع التطبيق (نفس مسار DB.babies في main.dart) ──
let babiesRef = null;   // users/{uid}/babies أو couples/{coupleId}/babies عند الاقتران
let profileRef = null;  // users/{uid} (أو مرآة الزوجين للأب)
let babies = [];        // [{id, name, birthDate, gender, ...}] مرتّبة بتاريخ الإضافة
let selectedBabyId = null;
let editingId = null;   // null = إضافة
let unsubs = [];
let monthFromUrlGlobal = null;
let autoMonthDone = false;

export async function initBabyPage() {
  try {
    const res = await fetch('/data/baby_months.json');
    babyMonthsData = await res.json();
  } catch (err) {
    console.error('Error fetching baby months data:', err);
  }

  const monthFromUrl = parseMonthFromUrl();

  monthFromUrlGlobal = monthFromUrl;
  auth.onAuthStateChanged(async (user) => {
    currentUser = user;
    unsubs.forEach((u) => u()); unsubs = [];
    if (user) {
      try {
        const snap = await db.collection('users').doc(user.uid).get();
        userProfile = snap.exists ? snap.data() : {};
        const cid = userProfile.coupleId || null;
        babiesRef = cid ? db.collection('couples').doc(cid).collection('babies') : db.collection('users').doc(user.uid).collection('babies');
        profileRef = (cid && userProfile.role === 'partner') ? db.collection('couples').doc(cid).collection('shared').doc('userdoc') : db.collection('users').doc(user.uid);
        // تحديث لحظي: أي تغيير من التطبيق يظهر هنا فوراً والعكس
        unsubs.push(babiesRef.onSnapshot((qs) => {
          babies = qs.docs.map((d) => ({ id: d.id, ...d.data() }))
            .sort((a, b) => (toDate(a.createdAt)?.getTime() ?? Infinity) - (toDate(b.createdAt)?.getTime() ?? Infinity));
          renderBabies();
        }, (e) => { console.warn('babies stream', e); handleBabyUserData(userProfile, monthFromUrl); }));
        unsubs.push(profileRef.onSnapshot((d) => {
          userProfile = { ...userProfile, ...(d.exists ? d.data() : {}) };
          if (userProfile.selectedBabyId && userProfile.selectedBabyId !== selectedBabyId) { selectedBabyId = userProfile.selectedBabyId; renderBabies(); }
        }, () => {}));
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

/** الطفل المختار (أو الأول)، مع رجوع لحقول users القديمة إن لم تكن هناك قائمة أطفال */
function activeBaby() {
  if (babies.length) return babies.find((b) => b.id === selectedBabyId) || babies[0];
  if (userProfile && (userProfile.babyBirthDate || userProfile.babyName)) return { id: null, name: userProfile.babyName, birthDate: userProfile.babyBirthDate, gender: userProfile.babyGender };
  return null;
}

function ageText(bDate, name) {
  const diffDays = Math.max(0, Math.floor((Date.now() - bDate.getTime()) / 86400000));
  const months = Math.floor(diffDays / 30.4375);
  const restDays = Math.floor(diffDays - months * 30.4375);
  return { months, text: months < 1 ? `عمر ${name}: ${diffDays} يوماً 🌸` : `عمر ${name}: ${months} ${months <= 10 ? 'أشهر' : 'شهراً'}${restDays ? ` و${restDays} يوماً` : ''} 🌸` };
}

function renderBabies() {
  const b = activeBaby();
  const banner = document.getElementById('nb-baby-status-banner');
  if (!b) {
    if (banner) {
      banner.innerHTML = `
        <div style="display:flex;align-items:center;gap:12px"><span style="font-size:26px">👶</span>
          <div><div style="font-weight:800;color:var(--nb-ink);font-size:15px">أضيفي طفلكِ لمتابعة نموّه شهراً بشهر</div>
          <div style="font-size:13px;color:var(--nb-ink-3)">البيانات متزامنة مع تطبيق نبضة: ما تضيفينه هنا يظهر في التطبيق فوراً.</div></div></div>
        <button class="nb-btn-primary" style="background:#00897B;font-size:12.5px;padding:7px 16px" onclick="window.openBabyProfileModal()">➕ إضافة طفل</button>`;
      banner.style.display = 'flex';
    }
    return;
  }
  const bDate = toDate(b.birthDate);
  const name = esc(b.name || 'صغيركِ');
  const boy = (b.gender || b.babyGender) === 'male';
  const acc = boy ? '#4A90D9' : '#00897B';
  if (bDate) {
    const a = ageText(bDate, name);
    if (monthFromUrlGlobal === null && !autoMonthDone) { autoMonthDone = true; setMonth(Math.min(24, a.months), false); }
    const heroSubtitle = document.getElementById('nb-baby-hero-subtitle');
    if (heroSubtitle) heroSubtitle.textContent = a.text;
  }
  if (!banner) return;
  const chips = babies.map((x) => {
    const on = x.id === b.id; const xb = (x.gender || x.babyGender) === 'male';
    const c = xb ? '#4A90D9' : '#E91E63';
    return `<button class="nb-baby-chip" data-baby="${esc(x.id)}" style="display:inline-flex;align-items:center;gap:6px;border:1.5px solid ${on ? c : '#EEE3EA'};background:${on ? c : '#fff'};color:${on ? '#fff' : 'var(--nb-ink)'};border-radius:999px;padding:7px 14px;font-family:inherit;font-weight:800;font-size:13px;cursor:pointer;box-shadow:${on ? `0 6px 16px ${c}33` : 'none'}">${xb ? '👦' : '👧'} ${esc(x.name || 'طفل')}${on ? ' ✓' : ''}</button>`;
  }).join('');
  banner.innerHTML = `
    <div style="display:flex;flex-direction:column;gap:10px;flex:1;min-width:260px">
      <div style="display:flex;align-items:center;gap:12px"><span style="font-size:26px">${boy ? '👦' : '👶'}</span>
        <div><div style="font-weight:800;color:var(--nb-ink);font-size:15px">مرحباً بكِ وبـ ${name} في نبضة!</div>
        <div style="font-size:13px;color:var(--nb-ink-3)">${bDate ? 'تاريخ الميلاد: ' + bDate.toLocaleDateString('ar-DZ', { day: 'numeric', month: 'long', year: 'numeric' }) + ' · ' : ''}متزامن مع تطبيق نبضة لحظياً</div></div></div>
      ${babies.length ? `<div style="display:flex;gap:8px;flex-wrap:wrap;align-items:center">${chips}
        <button onclick="window.openBabyProfileModal()" style="display:inline-flex;align-items:center;gap:6px;border:1.5px dashed #80CBC4;background:#E0F2F1;color:#00796B;border-radius:999px;padding:7px 14px;font-family:inherit;font-weight:800;font-size:13px;cursor:pointer">➕ إضافة طفل</button></div>` : ''}
    </div>
    <div style="display:flex;gap:8px;flex-wrap:wrap">
      <button class="nb-btn-secondary" style="font-size:12.5px;padding:7px 14px;border-color:${acc};color:${acc}" onclick="window.editActiveBaby()">✏️ تعديل بيانات الطفل</button>
      ${b.id ? `<button class="nb-btn-secondary" style="font-size:12.5px;padding:7px 14px;color:#C62828;border-color:#FFCDD2" onclick="window.deleteActiveBaby()">🗑️ حذف</button>` : ''}
      ${!babies.length ? `<button class="nb-btn-primary" style="background:#00897B;font-size:12.5px;padding:7px 14px" onclick="window.openBabyProfileModal()">➕ إضافة طفل</button>` : ''}
    </div>`;
  banner.style.display = 'flex';
  banner.querySelectorAll('[data-baby]').forEach((btn) => btn.onclick = () => selectBaby(btn.dataset.baby));
}

async function selectBaby(id) {
  selectedBabyId = id; autoMonthDone = false; renderBabies();
  const b = babies.find((x) => x.id === id);
  try { await profileRef?.set({ selectedBabyId: id, ...(b ? { babyName: b.name || '', babyBirthDate: b.birthDate || null } : {}) }, { merge: true }); } catch (_) {}
}

function handleBabyUserData(profile, monthFromUrl) {
  const bDate = toDate(profile.babyBirthDate || profile.childBirthDate);
  const babyName = esc(profile.babyName || profile.childName || 'صغيركِ');

  if (bDate) {
    const diffDays = Math.max(0, Math.floor((Date.now() - bDate.getTime()) / 86400000));
    const months = Math.floor(diffDays / 30.4375);
    const restDays = Math.floor(diffDays - months * 30.4375);
    if (monthFromUrl === null) setMonth(Math.min(24, months), false);
    const heroSubtitle = document.getElementById('nb-baby-hero-subtitle');
    if (heroSubtitle) {
      heroSubtitle.textContent = months < 1
        ? `عمر ${babyName}: ${diffDays} يوماً 🌸`
        : `عمر ${babyName}: ${months} ${months <= 10 ? 'أشهر' : 'شهراً'}${restDays ? ` و${restDays} يوماً` : ''} 🌸`;
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
  const btn = container?.querySelector(`.nb-week-pill[data-month="${currentMonth}"]`);
  if (!container || !btn) return;
  const cr = container.getBoundingClientRect(); const br = btn.getBoundingClientRect();
  container.scrollBy({ left: (br.left + br.width / 2) - (cr.left + cr.width / 2), behavior: 'smooth' });
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
  const list = (await getTopArticles('baby')).slice(0, 10);
  if (!list.length) { container.parentElement.style.display = 'none'; return; }
  container.innerHTML = list.map((a) => articleCardHtml(a, '👶')).join('');
}

async function loadBabyProducts() {
  const container = document.getElementById('nb-baby-products-carousel');
  if (!container) return;
  try {
    const all = await getVisibleProducts();
    const fit = all.filter((p) => productMatchesStage(p, 'newborn') || productMatchesStage(p, 'baby'));
    const list = [...fit, ...all.filter((p) => !fit.includes(p))].slice(0, 10);
    if (!list.length) { container.parentElement.style.display = 'none'; return; }
    container.innerHTML = list.map(productCardHtml).join('');
  } catch (err) {
    console.error('Error loading baby products:', err);
    container.parentElement.style.display = 'none';
  }
}

// ── نافذة إضافة / تعديل طفل (نفس الحقول التي يكتبها التطبيق) ──
function fillModal(b) {
  const t = document.getElementById('nb-baby-modal-title');
  if (t) t.textContent = b ? `تعديل بيانات ${b.name || 'الطفل'}` : (currentUser ? 'إضافة طفل جديد' : 'تحديد عمر وبيانات طفلكِ');
  document.getElementById('nb-baby-name-input').value = b?.name || '';
  const d = b ? toDate(b.birthDate) : null;
  document.getElementById('nb-baby-birth-input').value = d ? `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}` : '';
  const g = document.getElementById('nb-baby-gender-input'); if (g) g.value = (b?.gender || b?.babyGender || '');
  const del = document.getElementById('nb-baby-delete-btn'); if (del) del.style.display = b && b.id ? 'inline-flex' : 'none';
}

window.openBabyProfileModal = function() {
  editingId = null; fillModal(null);
  document.getElementById('nb-baby-date-modal')?.classList.add('open');
};
window.editActiveBaby = function() {
  const b = activeBaby();
  if (!b) return window.openBabyProfileModal();
  editingId = b.id || '__legacy__'; fillModal(b);
  document.getElementById('nb-baby-date-modal')?.classList.add('open');
};

window.closeBabyProfileModal = function() {
  document.getElementById('nb-baby-date-modal')?.classList.remove('open');
};

window.saveBabyBirthDate = async function() {
  const nameInput = document.getElementById('nb-baby-name-input');
  const dateInput = document.getElementById('nb-baby-birth-input');
  const gender = document.getElementById('nb-baby-gender-input')?.value || '';
  if (!dateInput || !dateInput.value) { alert('يرجى اختيار تاريخ ميلاد الطفل.'); return; }
  const bDate = new Date(dateInput.value + 'T12:00:00');
  if (isNaN(bDate.getTime()) || bDate > new Date()) { alert('يرجى إدخال تاريخ ميلاد صحيح في الماضي.'); return; }
  const babyName = nameInput?.value?.trim() || 'صغيركِ';
  const months = Math.min(24, Math.floor((Date.now() - bDate.getTime()) / 86400000 / 30.4375));

  if (currentUser && babiesRef) {
    const FS = window.firebase.firestore;
    const ts = FS.Timestamp.fromDate(bDate);
    try {
      let id = editingId;
      if (!id || id === '__legacy__') {
        // إضافة: نفس وثيقة التطبيق (_addBaby في main.dart)
        const ref = await babiesRef.add({ name: babyName, birthDate: ts, weight: 0, height: 0, gender, createdAt: FS.FieldValue.serverTimestamp(), userId: currentUser.uid });
        id = ref.id;
      } else {
        await babiesRef.doc(id).set({ name: babyName, birthDate: ts, gender, updatedAt: FS.FieldValue.serverTimestamp() }, { merge: true });
      }
      // الطفل النشط في الحساب (يقرؤه التطبيق) — لا نغيّر مرحلة الحياة إلا إن لم تُحدَّد
      const upd = { selectedBabyId: id, babyName, babyBirthDate: ts, babyGender: gender, updatedAt: FS.FieldValue.serverTimestamp() };
      if (!userProfile?.lifeStage) upd.lifeStage = 'baby';
      await profileRef.set(upd, { merge: true });
      selectedBabyId = id; autoMonthDone = false;
      sessionStorage.removeItem('nb_user_cache');
      window.nbToast?.(editingId ? 'حُدّثت بيانات الطفل ✓ (تظهر في التطبيق فوراً)' : 'أُضيف الطفل ✓ (يظهر في التطبيق فوراً)', 'success');
    } catch (err) {
      console.error('Error saving baby profile:', err);
      window.nbToast?.('تعذّر الحفظ، حاولي مجدداً', 'error');
      return;
    }
  }
  setMonth(months, true);
  window.closeBabyProfileModal();
};

window.deleteActiveBaby = async function() {
  const b = editingId && editingId !== '__legacy__' ? babies.find((x) => x.id === editingId) : activeBaby();
  if (!b || !b.id || !babiesRef) return;
  if (!confirm(`حذف «${b.name || 'الطفل'}» وكل بياناته من نبضة (الموقع والتطبيق)؟ لا يمكن التراجع.`)) return;
  const FS = window.firebase.firestore;
  try {
    // سجلّات الطفل اليومية (babies/{id}/logs) ثم وثيقته
    const logs = await babiesRef.doc(b.id).collection('logs').limit(400).get().catch(() => null);
    if (logs && !logs.empty) { const batch = db.batch(); logs.docs.forEach((d) => batch.delete(d.ref)); await batch.commit(); }
    await babiesRef.doc(b.id).delete();
    const rest = babies.filter((x) => x.id !== b.id);
    const next = rest[0];
    await profileRef.set(next
      ? { selectedBabyId: next.id, babyName: next.name || '', babyBirthDate: next.birthDate || null, babyGender: next.gender || '' }
      : { selectedBabyId: FS.FieldValue.delete(), babyName: FS.FieldValue.delete(), babyBirthDate: FS.FieldValue.delete(), babyGender: FS.FieldValue.delete() }, { merge: true });
    selectedBabyId = next ? next.id : null;
    window.closeBabyProfileModal();
    window.nbToast?.('حُذف الطفل', 'success');
  } catch (err) {
    console.error('delete baby', err);
    window.nbToast?.('تعذّر الحذف، حاولي مجدداً', 'error');
  }
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
