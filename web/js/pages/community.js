/**
 * Nabda - Community Page Logic (نظير شاشة المجتمع في التطبيق)
 * Author: فريق تحرير نبضة
 */

import { auth, db } from '../firebase-init.js';
import { toDate, escapeHtml } from '../utils.js';

const CAT = { pregnancy: 'الحمل 🤰', baby: 'رعاية الطفل 👶', cycle: 'الدورة 🌸', general: 'عام 💬' };
const singlePostId = (location.pathname.match(/\/community\/post\/([^/?#]+)/) || [])[1] || null;

let currentUser = null;
let userProfile = null;
let currentFilter = 'all';
let posts = [];
let mode = 'public';        // public | club
let myCohort = null;        // نادي المستخدمة (due_YYYY_MM أو born_YYYY_MM)
let viewCohort = null;      // النادي المعروض (قد يكون نادياً آخر للتصفّح)

/* ═════════ أندية الولادة — نفس منطق CohortService في التطبيق ═════════ */
const MONTHS_AR = ['', 'جانفي', 'فيفري', 'مارس', 'أفريل', 'ماي', 'جوان', 'جويلية', 'أوت', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
const pad2 = (n) => String(n).padStart(2, '0');
export function deriveCohortKey(d) {
  const baby = toDate(d.babyBirthDate);
  if (baby && (d.lifeStage === 'baby' || d.lifeStage === 'mother')) return `born_${baby.getFullYear()}_${pad2(baby.getMonth() + 1)}`;
  // حامل: تاريخ الولادة المحفوظ أوّلاً (أدقّ)، وإلا آخر دورة + 280 يوماً
  const due = toDate(d.dueDate);
  const lmp = toDate(d.pregnancyStartDate) || toDate(d.pregnancyStart) || toDate(d.lastPeriodDate);
  const edd = due || (lmp ? new Date(lmp.getTime() + 280 * 86400000) : null);
  if (edd) return `due_${edd.getFullYear()}_${pad2(edd.getMonth() + 1)}`;
  if (baby) return `born_${baby.getFullYear()}_${pad2(baby.getMonth() + 1)}`;
  return null;
}
export function cohortLabel(key) {
  const p = String(key || '').split('_');
  if (p.length < 3) return 'نادي الولادة';
  const m = parseInt(p[2], 10);
  return `مواليد ${MONTHS_AR[m] || ''} ${p[1]}`;
}
function nearbyKeys(center, span = 6) {
  const p = center.split('_'); const y = +p[1]; const m = +p[2];
  const out = [];
  for (let i = -span; i <= span; i++) { const d = new Date(y, m - 1 + i, 1); out.push(`${p[0]}_${d.getFullYear()}_${pad2(d.getMonth() + 1)}`); }
  return out;
}
/** انضمام تلقائي: يحدّث users.cohortKey وعدّادات الأعضاء (معاملة واحدة، مثل syncUserCohort) */
async function syncCohort(uid, newKey) {
  const FV = window.firebase.firestore.FieldValue;
  const userRef = db.collection('users').doc(uid);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(userRef);
    if (!snap.exists) return;
    const old = snap.data().cohortKey || null;
    if (old === newKey) return;
    tx.update(userRef, { cohortKey: newKey, updatedAt: FV.serverTimestamp() });
    if (old) tx.set(db.collection('cohort_members_count').doc(old), { memberCount: FV.increment(-1), lastUpdated: FV.serverTimestamp() }, { merge: true });
    if (newKey) tx.set(db.collection('cohort_members_count').doc(newKey), { memberCount: FV.increment(1), lastUpdated: FV.serverTimestamp() }, { merge: true });
  });
  db.collection('users_directory').doc(uid).set({ cohortKey: newKey, updatedAt: FV.serverTimestamp() }, { merge: true }).catch(() => {});
}

export async function initCommunityPage() {
  auth.onAuthStateChanged(async (user) => {
    currentUser = user;
    const visitorOverlay = document.getElementById('nb-community-visitor-view');
    const memberView = document.getElementById('nb-community-member-view');

    if (user) {
      if (visitorOverlay) visitorOverlay.style.display = 'none';
      if (memberView) memberView.style.display = 'block';

      try {
        const snap = await db.collection('users').doc(user.uid).get();
        if (snap.exists) userProfile = snap.data();
        // نادي الولادة: يُحسب ويُزامَن تلقائياً عند كل دخول
        myCohort = deriveCohortKey(userProfile || {});
        if (myCohort !== ((userProfile || {}).cohortKey || null)) {
          syncCohort(user.uid, myCohort).catch((e) => console.warn('cohort sync', e));
          if (myCohort && !localStorage.getItem('nb_club_intro_' + myCohort)) {
            localStorage.setItem('nb_club_intro_' + myCohort, '1');
            setTimeout(() => window.nbToast?.(`🤱 انضممتِ تلقائياً إلى «${cohortLabel(myCohort)}» حسب تاريخ ولادتكِ المتوقّع`, 'success'), 900);
          }
        }
        viewCohort = myCohort;
        document.getElementById('nb-club-tab-badge').textContent = myCohort ? cohortLabel(myCohort).replace('مواليد ', '') : '';
        // رابط مباشر: /community?club=due_2027_01 أو ?tab=club
        const q = new URLSearchParams(location.search);
        if (q.get('club') && /^(due|born)_\d{4}_\d{2}$/.test(q.get('club'))) { viewCohort = q.get('club'); setMode('club', false); }
        else if (q.get('tab') === 'club') setMode('club', false);
      } catch (e) {
        console.warn('Could not load user profile for community:', e);
      }

      loadCommunityPosts();
    } else {
      if (visitorOverlay) visitorOverlay.style.display = 'block';
      if (memberView) memberView.style.display = 'none';
    }
  });

  setupGroupFilters();
  document.querySelectorAll('.nb-comm-tab').forEach((b) => b.addEventListener('click', () => setMode(b.dataset.mode)));
  setupPostModal();
  setupReportModal();
}

function setupGroupFilters() {
  const pills = document.querySelectorAll('.nb-group-pill');
  pills.forEach(pill => {
    pill.addEventListener('click', () => {
      pills.forEach(p => p.classList.remove('active'));
      pill.classList.add('active');
      currentFilter = pill.dataset.group || 'all';
      renderPosts();
    });
  });
}

async function loadCommunityPosts() {
  const container = document.getElementById('nb-posts-feed');
  if (!container) return;

  container.innerHTML = '<div style="text-align:center;padding:40px;color:var(--nb-ink-3)">جاري تحميل منشورات المجتمع...</div>';

  try {
    posts = [];
    if (singlePostId) {
      const d = await db.collection('community_posts').doc(decodeURIComponent(singlePostId)).get();
      if (d.exists) posts.push({ ...d.data(), id: d.id });
    } else if (mode === 'club') {
      if (!viewCohort) { renderNoClub(); return; }
      // نفس استعلام التطبيق (فهرس cohortKey + createdAt موجود في firestore.indexes.json)
      const snap = await db.collection('community_posts').where('cohortKey', '==', viewCohort).orderBy('createdAt', 'desc').limit(60).get();
      snap.forEach((doc) => posts.push({ ...doc.data(), id: doc.id }));
    } else {
      const snap = await db.collection('community_posts').orderBy('createdAt', 'desc').limit(40).get();
      snap.forEach((doc) => { const d = doc.data(); if (d.isPublic !== false && !d.cohortKey) posts.push({ ...d, id: doc.id }); });
    }

    renderPosts();
  } catch (err) {
    console.error('Error fetching community posts:', err);
    container.innerHTML = '<div style="text-align:center;padding:40px;color:var(--nb-ink-3)">تعذر تحميل المنشورات حالياً، يرجى المحاولة لاحقاً.</div>';
  }
}

function setMode(m, reload = true) {
  mode = m;
  if (m === 'club') {
    currentFilter = 'all';
    document.querySelectorAll('.nb-group-pill').forEach((p) => p.classList.toggle('active', p.dataset.group === 'all'));
  }
  document.querySelectorAll('.nb-comm-tab').forEach((b) => b.classList.toggle('active', b.dataset.mode === m));
  renderClubHeader();
  if (reload) loadCommunityPosts();
}

const countCache = {};
async function clubCount(k) {
  if (k in countCache) return countCache[k];
  try { const d = await db.collection('cohort_members_count').doc(k).get(); countCache[k] = Math.max(0, (d.exists && d.data().memberCount) || 0); }
  catch (_) { countCache[k] = null; }
  return countCache[k];
}
const monthOnly = (k) => { const p = k.split('_'); return MONTHS_AR[parseInt(p[2], 10)] || ''; };
const yearOf = (k) => k.split('_')[1];

/** أيقونة ولون كل شهر (web/img/clubs/month_MM.webp) — [خلفية فاتحة، لون مميّز] */
const MONTH_THEME = [null,
  ['#FFE4EC', '#E2437A'], ['#EFE6FA', '#8A55C6'], ['#DFF4F2', '#1A958D'], ['#FFEBDD', '#E8701F'],
  ['#E3EFFC', '#3580CF'], ['#FFE6EF', '#E04C86'], ['#FFF4D4', '#C98F00'], ['#E4F4E3', '#378F48'],
  ['#F0E6F8', '#9554C3'], ['#FFE5E8', '#E04A66'], ['#E2EEFA', '#2C78BE'], ['#FFF1D8', '#BF820C'],
];
const monthNum = (k) => parseInt(String(k).split('_')[2], 10) || 1;
const clubIcon = (k) => `/img/clubs/month_${pad2(monthNum(k))}.webp`;
const clubStyle = (k) => { const t = MONTH_THEME[monthNum(k)]; return `--cb:${t[0]};--ca:${t[1]}`; };
const clubImg = (k, cls) => `<img class="${cls}" src="${clubIcon(k)}" alt="" width="256" height="256" loading="lazy" decoding="async">`;

/** كاروسال الأندية: الشهر المعروض في الوسط، والأشهر السابقة يميناً واللاحقة يساراً (RTL) */
function renderClubHeader() {
  const box = document.getElementById('nb-club-header');
  const pills = document.querySelector('.nb-group-pills');
  // التصنيفات (الحمل/الطفل/…) خاصة بالمجتمع العامّ فقط
  if (pills) pills.style.display = mode === 'club' ? 'none' : '';
  if (mode !== 'club' || !viewCohort) { box.style.display = 'none'; box.innerHTML = ''; return; }
  box.style.display = 'block';
  const keys = nearbyKeys(viewCohort, 2); // 5 أندية: [-2, -1, الحالي, +1, +2]
  const visiting = viewCohort !== myCohort;
  box.innerHTML = `
    <div class="nb-club-car" id="nb-club-car">
      <button class="nb-club-nav" data-step="-1" aria-label="الشهر السابق"><svg viewBox="0 0 24 24" width="1em" height="1em" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" style="display:block;margin:auto"><path d="M9 5l7 7-7 7"/></svg></button>
      <div class="nb-club-track">
        ${keys.map((k, i) => {
          const off = i - 2;
          if (off === 0) return `
            <div class="nb-club-center ${visiting ? 'visiting' : ''}" style="${clubStyle(k)}">
              <div class="nb-club-tag">${k === myCohort ? '🤱 ناديكِ — انضممتِ تلقائياً' : '👀 تتصفّحين هذا النادي'}</div>
              ${clubImg(k, 'nb-club-ico')}
              <div class="nb-club-month">${escapeHtml(monthOnly(k))}</div>
              <div class="nb-club-year">مواليد ${escapeHtml(monthOnly(k))} ${escapeHtml(yearOf(k))}</div>
              <div class="nb-club-count" data-count="${k}">…</div>
              ${visiting && myCohort ? `<button class="nb-club-back" data-go="${myCohort}">↩ العودة إلى ناديكِ (${escapeHtml(monthOnly(myCohort))})</button>` : ''}
            </div>`;
          return `
            <button class="nb-club-side off${Math.abs(off)} ${k === myCohort ? 'mine' : ''}" data-go="${k}" style="${clubStyle(k)}" aria-label="${escapeHtml(cohortLabel(k))}">
              ${clubImg(k, 'ico')}
              <span class="m">${escapeHtml(monthOnly(k))}</span>
              <span class="y">${escapeHtml(yearOf(k))}</span>
              ${k === myCohort ? '<span class="star">⭐ ناديكِ</span>' : `<span class="c" data-count="${k}"></span>`}
            </button>`;
        }).join('')}
      </div>
      <button class="nb-club-nav" data-step="1" aria-label="الشهر التالي"><svg viewBox="0 0 24 24" width="1em" height="1em" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" style="display:block;margin:auto"><path d="M15 5l-7 7 7 7"/></svg></button>
    </div>
    <div class="nb-club-hint">${visiting ? 'للاطّلاع والتعلّم — النشر يكون في ناديكِ فقط' : 'أمهات موعد ولادتهنّ في نفس الشهر يتقاسمن التجربة 💗'} · <a href="#" id="nb-club-all">كل الأندية</a></div>`;

  const go = (k) => { viewCohort = k; history.replaceState(null, '', k === myCohort ? '/community?tab=club' : '/community?club=' + k); renderClubHeader(); loadCommunityPosts(); };
  box.querySelectorAll('[data-go]').forEach((b) => b.onclick = () => go(b.dataset.go));
  box.querySelectorAll('.nb-club-nav').forEach((b) => b.onclick = () => go(nearbyKeys(viewCohort, 1)[1 + Number(b.dataset.step)]));
  box.querySelector('#nb-club-all').onclick = (e) => { e.preventDefault(); window.nbOpenClubs(); };
  // سحب على الهاتف
  const car = box.querySelector('#nb-club-car'); let x0 = null;
  car.addEventListener('touchstart', (e) => { x0 = e.touches[0].clientX; }, { passive: true });
  car.addEventListener('touchend', (e) => {
    if (x0 === null) return; const dx = e.changedTouches[0].clientX - x0; x0 = null;
    if (Math.abs(dx) > 50) go(nearbyKeys(viewCohort, 1)[dx > 0 ? 2 : 0]); // السحب يميناً = الشهر التالي في RTL
  });
  // أعداد العضوات
  keys.forEach(async (k) => {
    const n = await clubCount(k);
    box.querySelectorAll(`[data-count="${k}"]`).forEach((el) => {
      el.textContent = n === null ? '' : (el.classList.contains('nb-club-count') ? `${n.toLocaleString('en-US')} عضوة` : `${n} عضوة`);
    });
  });
}

function renderNoClub() {
  document.getElementById('nb-posts-feed').innerHTML = `
    <div style="background:#fff;border:1px solid #F8E1EA;border-radius:22px;padding:40px 22px;text-align:center">
      <div style="font-size:46px;margin-bottom:10px">🤱</div>
      <h3 style="font-size:19px;font-weight:900;margin-bottom:8px">نادي الولادة الخاص بكِ</h3>
      <p style="font-size:14px;color:var(--nb-ink-3);line-height:1.8;max-width:520px;margin:0 auto 18px">أندية أشهر الولادة تجمع الحوامل والأمهات اللواتي يمررن بنفس المرحلة لمشاركة التجارب. حدّدي تاريخ حملكِ أو ميلاد طفلكِ لتنضمّي تلقائياً لناديكِ.</p>
      <div style="display:flex;gap:10px;justify-content:center;flex-wrap:wrap">
        <a href="/pregnancy" class="nb-btn-primary" style="text-decoration:none">🤰 تحديد تاريخ الحمل</a>
        <a href="/baby" class="nb-btn-secondary" style="text-decoration:none">👶 تاريخ ميلاد الطفل</a>
        <button class="nb-btn-secondary" onclick="window.nbOpenClubs()">👀 تصفّح الأندية</button>
      </div>
    </div>`;
}

window.nbOpenClubs = async function () {
  const center = viewCohort || myCohort || (() => { const d = new Date(); return `due_${d.getFullYear()}_${pad2(d.getMonth() + 1)}`; })();
  const keys = nearbyKeys(center.replace(/^born_/, 'due_'), 6);
  // أندية المواليد أيضاً (للأمهات)
  if (myCohort && myCohort.startsWith('born_')) keys.unshift(...nearbyKeys(myCohort, 3).filter((k) => !keys.includes(k)));
  const picker = document.getElementById('nb-club-picker');
  picker.innerHTML = keys.map((k) => `<button class="nb-club-opt ${k === myCohort ? 'mine' : ''} ${k === viewCohort ? 'current' : ''}" data-k="${k}" style="${clubStyle(k)}">${clubImg(k, 'ico')}<b>${escapeHtml(cohortLabel(k))}</b><small data-c="${k}">${k === myCohort ? '⭐ ناديكِ' : '…'}</small></button>`).join('');
  picker.querySelectorAll('.nb-club-opt').forEach((b) => b.onclick = () => {
    viewCohort = b.dataset.k;
    document.getElementById('nb-club-modal').classList.remove('open');
    history.replaceState(null, '', '/community?club=' + viewCohort);
    setMode('club');
  });
  document.getElementById('nb-club-modal').classList.add('open');
  // عدد العضوات لكل نادٍ
  keys.forEach(async (k) => {
    if (k === myCohort) return;
    try { const d = await db.collection('cohort_members_count').doc(k).get(); const el = picker.querySelector(`[data-c="${k}"]`); if (el) el.textContent = `${Math.max(0, (d.exists && d.data().memberCount) || 0)} عضوة`; } catch (_) {}
  });
};
window.nbBackToMyClub = function () { viewCohort = myCohort; history.replaceState(null, '', '/community?tab=club'); setMode('club'); };

function renderPosts() {
  const container = document.getElementById('nb-posts-feed');
  if (!container) return;

  const filtered = currentFilter === 'all'
    ? posts
    : posts.filter(p => (p.category || 'general') === currentFilter);

  if (filtered.length === 0) {
    container.innerHTML = `
      <div style="background:#FFFFFF;border:1px solid #F8E1EA;border-radius:20px;padding:40px 20px;text-align:center;box-shadow:0 6px 20px rgba(0,0,0,0.02)">
        <div style="font-size:40px;margin-bottom:10px">🌸</div>
        <h4 style="font-size:16px;font-weight:800;color:var(--nb-ink);margin-bottom:6px">لا توجد منشورات في هذه المجموعة بعد</h4>
        <p style="font-size:13px;color:var(--nb-ink-3);margin-bottom:16px">كوني أول من يطرح سؤالاً أو يشارك تجربته في هذا القسم!</p>
        <button class="nb-btn-primary" onclick="window.openCreatePostModal()">كتابة منشور جديد ✍️</button>
      </div>
    `;
    return;
  }

  container.innerHTML = filtered.map(post => {
    const isLiked = currentUser && Array.isArray(post.likedBy) && post.likedBy.includes(currentUser.uid);
    const likesCount = post.likes || (Array.isArray(post.likedBy) ? post.likedBy.length : 0);
    const commentsCount = Array.isArray(post.comments) ? post.comments.length : (post.commentCount || 0);

    const d = toDate(post.createdAt);
    const timeStr = d ? d.toLocaleDateString('ar-DZ', { month: 'short', day: 'numeric' }) : 'حديثاً';
    const authorName = escapeHtml(post.isAnonymous ? 'مجهولة' : (post.author || post.authorName || 'أم من نبضة'));
    const authorStage = escapeHtml(post.authorStage || 'عضوة نبضة');

    return `
      <article class="nb-post-card" id="post-${post.id}">
        <!-- Post Header -->
        <div class="nb-post-header">
          <div style="display:flex;align-items:center;gap:12px">
            <div class="nb-post-avatar">🌸</div>
            <div>
              <div style="font-weight:800;color:var(--nb-ink);font-size:14.5px">${authorName}</div>
              <div style="font-size:11.5px;color:var(--nb-ink-3)">${authorStage} • ${timeStr}</div>
            </div>
          </div>

          <div style="display:flex;align-items:center;gap:8px">
            <span class="nb-post-badge">${CAT[post.category] || escapeHtml(post.group || 'عام')}</span>
            <button class="nb-btn-secondary" style="font-size:11px;padding:2px 8px;border:none;background:transparent;color:#999" onclick="window.openReportModal('${post.id}')" title="إبلاغ">⚠️</button>
          </div>
        </div>

        <!-- Post Content -->
        ${post.title ? `<h3 style="font-size:16px;font-weight:900;color:var(--nb-ink);margin:4px 0 6px">${escapeHtml(post.title)}</h3>` : ''}
        <div class="nb-post-content" style="white-space:pre-line">${escapeHtml(post.content || '')}</div>
        ${post.imageUrl && /^https:\/\//.test(post.imageUrl) ? `<img src="${escapeHtml(post.imageUrl)}" alt="" loading="lazy" style="width:100%;max-height:420px;object-fit:cover;border-radius:14px;margin-top:10px">` : ''}

        <!-- Post Actions -->
        <div class="nb-post-actions">
          <button class="nb-action-btn ${isLiked ? 'liked' : ''}" onclick="window.toggleLikePost('${post.id}')">
            <span>${isLiked ? '❤️' : '🤍'}</span>
            <span>${likesCount} إعجاب</span>
          </button>

          <button class="nb-action-btn" onclick="window.toggleComments('${post.id}')">
            <span>💬</span>
            <span>${commentsCount} تعليق</span>
          </button>

          <button class="nb-action-btn" onclick="navigator.clipboard.writeText(window.location.origin + '/community/post/' + '${post.id}').then(()=>window.nbToast?.('تم نسخ رابط المنشور 🔗'))">
            <span>🔗</span>
            <span>مشاركة</span>
          </button>
        </div>

        <!-- Comments Section -->
        <div class="nb-comments-box" id="comments-${post.id}" style="display:none">
          <div class="nb-comments-list" id="comments-list-${post.id}">
            ${renderCommentsList(post.comments || [])}
          </div>
          <div class="nb-comment-form">
            <input type="text" id="comment-input-${post.id}" placeholder="اكتبي تعليقاً لطيفاً ومشجعاً..." class="nb-comment-input">
            <button class="nb-btn-primary" style="font-size:12.5px;padding:6px 14px" onclick="window.submitComment('${post.id}')">إرسال</button>
          </div>
        </div>
      </article>
    `;
  }).join('');
}

function renderCommentsList(comments) {
  if (!comments || comments.length === 0) {
    return '<div style="font-size:12px;color:var(--nb-ink-3);padding:8px 0">لا توجد تعليقات بعد. كوني أول المعلقات!</div>';
  }
  return comments.map(c => `
    <div class="nb-comment-item">
      <div style="font-weight:800;font-size:12px;color:var(--nb-ink);margin-bottom:2px">${escapeHtml(c.author || c.authorName || 'أم من نبضة')}</div>
      <div style="font-size:13px;color:var(--nb-ink-2);line-height:1.5">${escapeHtml(c.text || '')}</div>
    </div>
  `).join('');
}

window.toggleComments = function(postId) {
  const box = document.getElementById(`comments-${postId}`);
  if (box) {
    box.style.display = box.style.display === 'none' ? 'block' : 'none';
  }
};

window.toggleLikePost = async function(postId) {
  if (!currentUser) return;
  const post = posts.find(p => p.id === postId);
  if (!post) return;

  const likedBy = Array.isArray(post.likedBy) ? [...post.likedBy] : [];
  const idx = likedBy.indexOf(currentUser.uid);

  if (idx > -1) {
    likedBy.splice(idx, 1);
  } else {
    likedBy.push(currentUser.uid);
  }

  post.likedBy = likedBy;
  post.likes = likedBy.length;
  renderPosts();

  try {
    const FV = window.firebase.firestore.FieldValue;
    await db.collection('community_posts').doc(postId).update(idx > -1
      ? { likes: FV.increment(-1), likedBy: FV.arrayRemove(currentUser.uid) }
      : { likes: FV.increment(1), likedBy: FV.arrayUnion(currentUser.uid) });
  } catch (err) {
    console.error('Error updating like:', err);
  }
};

window.submitComment = async function(postId) {
  if (!currentUser) return;
  const input = document.getElementById(`comment-input-${postId}`);
  if (!input || !input.value.trim()) return;

  const text = input.value.trim();
  const authorName = userProfile?.displayName || 'أم من نبضة';

  // نفس شكل تعليق التطبيق (post_detail_screen.dart)
  const newComment = {
    userId: currentUser.uid,
    author: authorName,
    text: text.slice(0, 1000),
    createdAt: new Date().toISOString()
  };

  const post = posts.find(p => p.id === postId);
  if (!post) return;

  post.comments = post.comments || [];
  post.comments.push(newComment);

  input.value = '';
  const listEl = document.getElementById(`comments-list-${postId}`);
  if (listEl) listEl.innerHTML = renderCommentsList(post.comments);

  try {
    await db.collection('community_posts').doc(postId).update({
      comments: window.firebase.firestore.FieldValue.arrayUnion(newComment)
    });
  } catch (err) {
    console.error('Error submitting comment:', err);
  }
};

function setupPostModal() {
  window.openCreatePostModal = function() {
    const modal = document.getElementById('nb-create-post-modal');
    if (!modal) return;
    let note = document.getElementById('nb-post-where');
    if (!note) {
      note = document.createElement('div'); note.id = 'nb-post-where';
      note.style.cssText = 'background:#FFF0F5;border:1px solid #F8D7E5;border-radius:12px;padding:10px 12px;font-size:13px;font-weight:700;color:#C2185B;margin-bottom:14px';
      modal.querySelector('.nb-modal-card')?.insertBefore(note, modal.querySelector('.nb-modal-card').children[1] || null);
    }
    note.textContent = mode === 'club' && myCohort ? `🤱 سيُنشر في ناديكِ «${cohortLabel(myCohort)}» — تراه عضوات النادي فقط` : '💬 سيُنشر في المجتمع العامّ';
    modal.classList.add('open');
  };

  window.closeCreatePostModal = function() {
    const modal = document.getElementById('nb-create-post-modal');
    if (modal) modal.classList.remove('open');
  };

  window.submitNewPost = async function() {
    if (!currentUser) return;
    const contentInput = document.getElementById('nb-post-content-input');
    const groupInput = document.getElementById('nb-post-group-select');

    if (!contentInput || !contentInput.value.trim()) {
      alert('يرجى كتابة نص المنشور.');
      return;
    }

    const content = contentInput.value.trim();
    if (content.length > 2000) {
      alert('الحد الأقصى لطول المنشور هو 2000 حرف.');
      return;
    }

    const category = groupInput?.value || 'general';
    const authorName = userProfile?.displayName || userProfile?.name || currentUser.displayName || 'مستخدمة';
    const title = (document.getElementById('nb-post-title-input')?.value || '').trim().slice(0, 120);
    const isAnonymous = !!document.getElementById('nb-post-anon')?.checked;

    try {
      // نفس مخطّط CommunityPostModel.toJson() في التطبيق
      const ref = db.collection('community_posts').doc();
      await ref.set({
        id: ref.id,
        userId: currentUser.uid,
        title,
        content,
        author: authorName,
        category,
        imageUrl: null,
        likes: 0,
        likedBy: [],
        comments: [],
        isAnonymous,
        createdAt: window.firebase.firestore.Timestamp.now(),
        updatedAt: null,
        // في تبويب النادي يُنشر في نادي المستخدمة فقط (مثل CreatePostScreen(cohortKey))
        cohortKey: mode === 'club' && myCohort ? myCohort : null,
        isPublic: !(mode === 'club' && myCohort),
      });
      const t = document.getElementById('nb-post-title-input'); if (t) t.value = '';

      contentInput.value = '';
      window.closeCreatePostModal();
      loadCommunityPosts();
    } catch (err) {
      console.error('Error creating post:', err);
      alert('حدث خطأ أثناء نشر المشاركة: ' + err.message);
    }
  };
}

function setupReportModal() {
  let targetPostId = null;

  window.openReportModal = function(postId) {
    targetPostId = postId;
    const modal = document.getElementById('nb-report-modal');
    if (modal) modal.classList.add('open');
  };

  window.closeReportModal = function() {
    targetPostId = null;
    const modal = document.getElementById('nb-report-modal');
    if (modal) modal.classList.remove('open');
  };

  window.submitReport = async function() {
    if (!currentUser || !targetPostId) return;
    const reasonInput = document.getElementById('nb-report-reason-select');
    const reason = reasonInput?.value || 'محتوى غير لائق';

    try {
      await db.collection('reports').add({
        reporterUid: currentUser.uid,
        postId: targetPostId,
        reason: reason,
        status: 'pending',
        createdAt: window.firebase.firestore.FieldValue.serverTimestamp()
      });

      alert('شكراً لحرصكِ. تم رفع البلاغ لمراجعته من قِبل إدارة نبضة.');
      window.closeReportModal();
    } catch (err) {
      console.error('Error sending report:', err);
      alert('حدث خطأ أثناء إرسال البلاغ.');
    }
  };
}
