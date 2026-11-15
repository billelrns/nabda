// ═══════════════════════════════════════════════════════════════════
//  لوحة تحكم نبضة — التشغيل: الدخول، الصلاحيات، القائمة، الموجّه، البحث الشامل، الطلبات اللحظية
// ═══════════════════════════════════════════════════════════════════
import { S, db, auth, firebase, can, ROLE_LABEL, esc, toast, emit, chime, toDate, normPhone, code, da, daO, closeDrawer, closeModal, normalizeOrder, MK, marketOf } from './core.js';
import dashboard from './mod-dashboard.js';
import orders, { openOrder } from './mod-orders.js';
import products, { openProductEditor } from './mod-products.js';
import customers from './mod-customers.js';
import waitlist from './mod-waitlist.js';
import content from './mod-content.js';
import site from './mod-site.js';
import shipping from './mod-shipping.js';
import moderation from './mod-moderation.js';
import staff from './mod-staff.js';
import logs from './mod-logs.js';
import settings from './mod-settings.js';
import users from './mod-users.js';
import coupons from './mod-coupons.js';
import ads from './mod-ads.js';
import support from './mod-support.js';
import notify from './mod-notify.js';
import markets from './mod-markets.js';

const MODULES = [
  { group: 'المتجر' },
  { id: 'dashboard', icon: '📊', label: 'لوحة القيادة', mod: dashboard },
  { id: 'orders', icon: '📦', label: 'الطلبات', mod: orders, badge: () => S.orders.filter((o) => o.status === 'pending' || !o.status).length },
  { id: 'products', icon: '🛍️', label: 'المنتجات', mod: products },
  { id: 'customers', icon: '👥', label: 'العميلات', mod: customers },
  { id: 'waitlist', icon: '🔔', label: 'قائمة الانتظار', mod: waitlist },
  { id: 'shipping', icon: '🚚', label: 'أسعار الشحن', mod: shipping, perm: 'shipping' },
  { id: 'markets', icon: '🌍', label: 'الأسواق والدول', mod: markets, perm: 'shipping' },
  { id: 'coupons', icon: '🎟️', label: 'الكوبونات والعروض', mod: coupons, perm: 'coupons' },
  { group: 'التطبيق والمستخدمات' },
  { id: 'users', icon: '👩', label: 'المستخدمات', mod: users, perm: 'users' },
  { id: 'moderation', icon: '🛡️', label: 'البلاغات والإشراف', mod: moderation, perm: 'moderation' },
  { id: 'notify', icon: '📣', label: 'الإشعارات الجماعية', mod: notify, perm: 'notify' },
  { id: 'ads', icon: '📢', label: 'إعلانات التطبيق', mod: ads, perm: 'ads' },
  { id: 'support', icon: '💬', label: 'الدعم والاستعادة', mod: support, perm: 'support' },
  { group: 'الموقع والمحتوى' },
  { id: 'site', icon: '🎨', label: 'واجهة الموقع', mod: site, perm: 'site' },
  { id: 'content', icon: '📰', label: 'المحتوى', mod: content },
  { group: 'الإدارة' },
  { id: 'staff', icon: '🧑‍💼', label: 'الطاقم والصلاحيات', mod: staff, perm: 'staff' },
  { id: 'logs', icon: '📜', label: 'سجلّ النشاط', mod: logs, perm: 'logs' },
  { id: 'settings', icon: '⚙️', label: 'الإعدادات', mod: settings, perm: 'settings' },
];
const visible = () => MODULES.filter((m) => !m.group && can(m.perm || m.id) || m.group).filter((m, i, a) => !m.group || (a[i + 1] && !a[i + 1].group));

const show = (id) => ['gate-loading', 'gate-login', 'gate-denied', 'app'].forEach((x) => document.getElementById(x).classList.toggle('hidden', x !== id));

/* ─────────── الدخول ─────────── */
document.getElementById('login-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  const err = document.getElementById('lg-err'); err.classList.add('hidden');
  try { await auth.signInWithEmailAndPassword(document.getElementById('lg-email').value.trim(), document.getElementById('lg-pass').value); }
  catch (ex) { err.textContent = 'تعذّر الدخول: تحقّقي من البريد وكلمة المرور.'; err.classList.remove('hidden'); }
});
document.getElementById('lg-google').onclick = async () => {
  try { await auth.signInWithPopup(new firebase.auth.GoogleAuthProvider()); } catch (ex) { if (ex.code !== 'auth/popup-closed-by-user') toast('تعذّر الدخول عبر Google', 'error'); }
};
const logout = async () => { await auth.signOut(); location.reload(); };
document.getElementById('logout').onclick = logout;
document.getElementById('denied-logout').onclick = logout;

auth.onAuthStateChanged(async (user) => {
  if (!user) return show('gate-login');
  show('gate-loading');
  try {
    const snap = await db.collection('staff').doc(user.uid).get();
    const st = snap.exists ? snap.data() : null;
    if (!st || st.isActive !== true) {
      document.getElementById('denied-msg').innerHTML = `الحساب <b dir="ltr">${esc(user.email || user.uid)}</b> ليس ضمن طاقم نبضة النشط.<br><small style="color:var(--ink-3)">UID: <span dir="ltr">${esc(user.uid)}</span></small>`;
      return show('gate-denied');
    }
    S.user = user; S.staff = st; S.role = st.role || 'employee';
    start();
  } catch (e) {
    console.error(e);
    document.getElementById('denied-msg').textContent = 'تعذّر التحقّق من الصلاحيات (تحقّقي من الاتصال).';
    show('gate-denied');
  }
});

/* ─────────── التشغيل ─────────── */
let current = null;
function start() {
  show('app');
  const name = S.staff.name || S.user.displayName || S.user.email || 'الطاقم';
  document.getElementById('me-name').textContent = name;
  document.getElementById('me-role').textContent = ROLE_LABEL[S.role] || S.role;
  document.getElementById('me-av').textContent = name.trim().charAt(0).toUpperCase();
  renderNav();
  mountMarketSwitch();
  listenOrders();
  listenBlocked();
  window.addEventListener('hashchange', route);
  route();
  setupChrome();
}

function renderNav() {
  document.getElementById('nav').innerHTML = visible().map((m) => m.group
    ? `<div class="ad-nav-group">${m.group}</div>`
    : `<button class="ad-nav-item ${current === m.id ? 'active' : ''}" data-mod="${m.id}" title="${m.label}">
        <span class="ad-nav-ic">${m.icon}</span><span class="ad-nav-label">${m.label}</span>
        ${m.badge && m.badge() ? `<span class="ad-nav-badge">${m.badge()}</span>` : ''}</button>`).join('');
  document.querySelectorAll('.ad-nav-item').forEach((b) => b.onclick = () => { location.hash = b.dataset.mod; document.getElementById('app').classList.remove('mobile-open'); });
}

let cleanup = null;
function route() {
  const [id, ...rest] = (location.hash.slice(1) || 'dashboard').split('/');
  const m = visible().find((x) => x.id === id) || visible().find((x) => x.id);
  current = m.id;
  closeDrawer(); closeModal();
  if (typeof cleanup === 'function') { try { cleanup(); } catch (_) {} }
  const view = document.getElementById('view');
  view.innerHTML = '';
  view.scrollTop = 0; window.scrollTo(0, 0);
  document.title = `${m.label} — لوحة تحكم نبضة`;
  renderNav();
  try { cleanup = m.mod.render(view, rest) || null; }
  catch (e) { console.error(e); view.innerHTML = `<div class="alert red">حدث خطأ في تحميل الوحدة: ${esc(e.message)}</div>`; }
}

/* ─────────── السوق المعروض في اللوحة: الطلبات والإحصاءات لسوق واحد بعملته ─────────── */
function mountMarketSwitch() {
  const box = document.querySelector('.ad-top-actions'); if (!box || document.getElementById('mk-seg')) return;
  box.insertAdjacentHTML('afterbegin', `<div class="seg" id="mk-seg" title="السوق المعروض (الطلبات، الإيراد، العميلات)">${Object.entries(MK).map(([k, m]) => `<button data-mk="${k}" class="${S.market === k ? 'active' : ''}">${m.flag} ${m.name}<span class="ad-nav-badge" data-mkb="${k}" style="position:static;margin-right:6px;display:none"></span></button>`).join('')}</div>`);
  box.querySelectorAll('[data-mk]').forEach((b) => b.onclick = () => {
    if (S.market === b.dataset.mk) return;
    S.market = b.dataset.mk; try { localStorage.setItem('ad_market', S.market); } catch (_) {}
    box.querySelectorAll('[data-mk]').forEach((x) => x.classList.toggle('active', x === b));
    S.orders = S.allOrders.filter((o) => marketOf(o) === S.market);
    renderNav(); route(); emit('orders');
    toast(`السوق المعروض: ${MK[S.market].flag} ${MK[S.market].name} — المبالغ بـ${MK[S.market].symbol}`);
  });
}
function marketBadges() {
  Object.keys(MK).forEach((k) => {
    const el = document.querySelector(`[data-mkb="${k}"]`); if (!el) return;
    const n = S.allOrders.filter((o) => marketOf(o) === k && (o.status === 'pending' || !o.status)).length;
    el.textContent = n; el.style.display = n && k !== S.market ? '' : 'none';
  });
}

/* ─────────── الطلبات اللحظية + إشعار الطلبات الجديدة ─────────── */
let firstLoad = true;
let unseen = 0;
function listenOrders() {
  db.collection('orders').orderBy('createdAt', 'desc').limit(1500).onSnapshot((snap) => {
    const changes = snap.docChanges ? snap.docChanges() : [];
    S.allOrders = snap.docs.map((d) => normalizeOrder({ id: d.id, ...d.data() }));
    S.orders = S.allOrders.filter((o) => marketOf(o) === S.market);
    if (!firstLoad) {
      const fresh = changes.filter((c) => c.type === 'added').map((c) => normalizeOrder({ id: c.doc.id, ...c.doc.data() }));
      // نُنبّه مرّة لكل سلّة جديدة
      const carts = new Set(fresh.map((o) => o.cartId || o.id));
      if (carts.size) {
        chime();
        unseen += carts.size;
        document.title = `(${unseen}) طلب جديد — نبضة`;
        const o = fresh[0];
        toast(`🛒 طلب جديد ${MK[marketOf(o)].flag} ${code(o.id)} — ${o.customerName || ''} (${o.wilaya || ''})`, 'success');
        if ('Notification' in window && Notification.permission === 'granted') {
          try { new Notification('طلب جديد في متجر نبضة', { body: `${o.customerName || ''} — ${o.productName || ''} — ${daO(o.lineTotal || o.unitPrice, o)}`, icon: '/favicon.png' }); } catch (_) {}
        }
      }
    }
    firstLoad = false;
    renderNav();
    marketBadges();
    emit('orders');
  }, (err) => { console.error(err); toast('تعذّر تحميل الطلبات: ' + (err.code || err.message), 'error'); });
}
document.addEventListener('visibilitychange', () => { if (!document.hidden && unseen) { unseen = 0; document.title = document.title.replace(/^\(\d+\)\s*/, ''); } });

function listenBlocked() {
  db.collection('blocked_phones').onSnapshot((snap) => { S.blocked = new Set(snap.docs.map((d) => d.id)); emit('blocked'); }, () => {});
}

/* ─────────── الواجهة العامة: القائمة، الوضع الليلي، الصوت، البحث، الخمول ─────────── */
function setupChrome() {
  const app = document.getElementById('app');
  if (localStorage.getItem('ad_side') === 'collapsed') app.classList.add('collapsed');
  document.getElementById('toggle-side').onclick = () => {
    if (window.innerWidth <= 980) { app.classList.toggle('mobile-open'); return; }
    app.classList.toggle('collapsed'); localStorage.setItem('ad_side', app.classList.contains('collapsed') ? 'collapsed' : '');
  };
  const themeBtn = document.getElementById('theme-btn');
  const syncTheme = () => { themeBtn.textContent = document.documentElement.dataset.theme === 'dark' ? '☀️' : '🌙'; };
  syncTheme();
  themeBtn.onclick = () => {
    const dark = document.documentElement.dataset.theme !== 'dark';
    document.documentElement.dataset.theme = dark ? 'dark' : '';
    localStorage.setItem('ad_theme', dark ? 'dark' : 'light'); syncTheme(); emit('theme');
  };
  const soundBtn = document.getElementById('sound-btn');
  const syncSound = () => { soundBtn.textContent = localStorage.getItem('ad_sound') === 'off' ? '🔕' : '🔔'; };
  syncSound();
  soundBtn.onclick = async () => {
    localStorage.setItem('ad_sound', localStorage.getItem('ad_sound') === 'off' ? 'on' : 'off'); syncSound();
    if (localStorage.getItem('ad_sound') !== 'off') { chime(); if ('Notification' in window && Notification.permission === 'default') Notification.requestPermission(); }
  };

  // البحث الشامل
  const inp = document.getElementById('gsearch');
  const box = document.getElementById('gsearch-results');
  let items = []; let sel = 0;
  const run = () => {
    const q = inp.value.trim();
    if (q.length < 2) { box.classList.add('hidden'); return; }
    const ql = q.toLowerCase(); const qp = normPhone(q);
    const ords = S.orders.filter((o) => (qp.length >= 4 && normPhone(o.customerPhone).includes(qp)) || (o.customerName || '').toLowerCase().includes(ql) || o.id.toLowerCase().includes(ql.replace('#', '')) || (o.cartId || '').toLowerCase().includes(ql)).slice(0, 7);
    const prods = S.products.filter((p) => (p.name || '').toLowerCase().includes(ql) || (p.sku || '').toLowerCase() === ql).slice(0, 6);
    items = [...ords.map((o) => ({ t: 'o', o })), ...prods.map((p) => ({ t: 'p', p }))];
    sel = 0;
    box.innerHTML = items.length ? `
      ${ords.length ? '<div class="grp">الطلبات</div>' : ''}${ords.map((o, i) => `<button data-i="${i}">📦 <b>${code(o.id)}</b> ${esc(o.customerName || '')} <span style="color:var(--ink-3)" dir="ltr">${esc(o.customerPhone || '')}</span> <span class="pill s-${esc(o.status || 'pending')}" style="margin-right:auto">${esc(o.status || 'pending')}</span></button>`).join('')}
      ${prods.length ? '<div class="grp">المنتجات</div>' : ''}${prods.map((p, i) => `<button data-i="${ords.length + i}">🛍️ ${esc(p.name)} <span style="margin-right:auto;color:var(--ink-3)">${da(p.price)}</span></button>`).join('')}`
      : '<div class="empty" style="padding:20px">لا نتائج</div>';
    box.classList.remove('hidden');
    hl();
  };
  const hl = () => box.querySelectorAll('button[data-i]').forEach((b) => b.classList.toggle('sel', +b.dataset.i === sel));
  const pick = (i) => {
    const it = items[i]; if (!it) return;
    box.classList.add('hidden'); inp.value = ''; inp.blur();
    if (it.t === 'o') { if (current !== 'orders') location.hash = 'orders'; setTimeout(() => openOrder(it.o.id), 60); }
    else { if (current !== 'products') location.hash = 'products'; setTimeout(() => openProductEditor(it.p.id), 60); }
  };
  inp.addEventListener('input', run);
  inp.addEventListener('focus', () => { if (!S.productsLoaded) import('./core.js').then((c) => c.loadProducts()); });
  inp.addEventListener('keydown', (e) => {
    if (e.key === 'ArrowDown') { sel = Math.min(items.length - 1, sel + 1); hl(); e.preventDefault(); }
    if (e.key === 'ArrowUp') { sel = Math.max(0, sel - 1); hl(); e.preventDefault(); }
    if (e.key === 'Enter') { pick(sel); e.preventDefault(); }
    if (e.key === 'Escape') { box.classList.add('hidden'); inp.blur(); }
  });
  box.addEventListener('click', (e) => { const b = e.target.closest('button[data-i]'); if (b) pick(+b.dataset.i); });
  document.addEventListener('click', (e) => { if (!e.target.closest('.ad-search')) box.classList.add('hidden'); });
  document.addEventListener('keydown', (e) => {
    if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'k') { e.preventDefault(); inp.focus(); inp.select(); }
  });

  // قفل بعد 30 دقيقة خمول
  let idle;
  const reset = () => { clearTimeout(idle); idle = setTimeout(async () => { toast('انتهت الجلسة بسبب الخمول', 'info'); await auth.signOut(); location.reload(); }, 30 * 60 * 1000); };
  ['click', 'keydown', 'mousemove', 'touchstart'].forEach((ev) => document.addEventListener(ev, reset, { passive: true }));
  reset();
}
