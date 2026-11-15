// ═══════════════════════════════════════════════════════════════════
//  نواة لوحة التحكم: الحالة، الصلاحيات، أدوات الواجهة (نوافذ، درج، تنبيهات، جداول، CSV)
// ═══════════════════════════════════════════════════════════════════
import { db, auth, storage, firebase } from '../firebase-init.js';
export { db, auth, storage, firebase };

export const FV = () => firebase.firestore.FieldValue;
export const TS = () => firebase.firestore.Timestamp;

/* ─────────── الحالة العامة ─────────── */
export const S = {
  user: null,
  staff: null,        // وثيقة staff/{uid}
  role: 'employee',   // owner | supervisor | employee (| agent)
  orders: [],         // طلبات السوق المختار فقط (لا تُخلط العملات أبداً)
  allOrders: [],      // كل الطلبات لكل الأسواق
  market: (() => { try { return localStorage.getItem('ad_market') === 'SA' ? 'SA' : 'DZ'; } catch (_) { return 'DZ'; } })(),
  products: [],
  productsLoaded: false,
  blocked: new Set(), // أرقام محظورة
  listeners: new Set(),
};

/** إشعار الوحدات عند تغيّر البيانات */
export function emit(type) { S.listeners.forEach((fn) => { try { fn(type); } catch (e) { console.error(e); } }); }
export function onData(fn) { S.listeners.add(fn); return () => S.listeners.delete(fn); }

/* ─────────── الصلاحيات (الواجهة فقط — الحماية الحقيقية في firestore.rules) ─────────── */
const PERMS = {
  owner: ['*'],
  supervisor: ['dashboard', 'orders', 'orders.edit', 'products', 'products.delete', 'content', 'site', 'shipping', 'customers', 'waitlist', 'moderation', 'settings', 'users', 'users.ban', 'coupons', 'ads', 'support', 'notify'],
  employee: ['dashboard', 'orders', 'products', 'customers', 'waitlist', 'content', 'users'],
  agent: ['dashboard', 'orders', 'customers', 'waitlist'],
};
export function can(perm) {
  const p = PERMS[S.role] || PERMS.employee;
  return p.includes('*') || p.includes(perm);
}
export const ROLE_LABEL = { owner: 'المالك', supervisor: 'مشرفة', employee: 'موظفة', agent: 'موظفة تأكيد' };

/* ─────────── تنسيق ─────────── */
export function esc(s) {
  if (s === null || s === undefined) return '';
  return String(s).replace(/[&<>"']/g, (m) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[m]));
}
export function toDate(v) {
  if (!v) return null;
  if (v instanceof Date) return v;
  if (typeof v.toDate === 'function') return v.toDate();
  if (typeof v === 'object' && 'seconds' in v) return new Date(v.seconds * 1000);
  const d = new Date(v); return isNaN(d) ? null : d;
}
/* ─────────── الأسواق (الدول) — انظري web/js/market.js ─────────── */
export const MK = { DZ: { flag: '🇩🇿', name: 'الجزائر', currency: 'DZD', symbol: 'دج' }, SA: { flag: '🇸🇦', name: 'السعودية', currency: 'SAR', symbol: 'ر.س' } };
const SYM = { DZD: 'دج', SAR: 'ر.س' };
/** سوق الطلب: country صريح، وإلا من العملة، وإلا الجزائر (كل الطلبات القديمة) */
export const marketOf = (o) => (o && MK[o.country] ? o.country : o && o.currency === 'SAR' ? 'SA' : 'DZ');
/** المبلغ بعملة: صريحة، أو عملة السوق المختار في اللوحة */
export const da = (n, cur) => {
  const c = cur || MK[S.market].currency; const v = Number(n || 0);
  const s = c === 'SAR' && v % 1 ? v.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) : Math.round(v).toLocaleString('en-US');
  return `${s} ${SYM[c] || c}`;
};
/** مبلغ الطلب بعملته الخاصة */
export const daO = (n, o) => da(n, MK[marketOf(o)].currency);
/** سعر المنتج في سوق (الجزائر = الحقول الأصلية) */
export const pPrice = (p, m = S.market) => (m === 'DZ' ? Number(p.price || 0) : Number(p.markets?.[m]?.price || 0));
export const pAvail = (p, m) => (m === 'DZ' ? p.active !== false && p.markets?.DZ?.active !== false : p.active !== false && p.markets?.[m]?.active !== false && Number(p.markets?.[m]?.price) > 0);
export const num = (n) => Number(n || 0).toLocaleString('en-US');
export function fmtDate(v, withTime = true) {
  const d = toDate(v); if (!d) return '—';
  const s = d.toLocaleDateString('ar-DZ', { day: 'numeric', month: 'short', year: d.getFullYear() !== new Date().getFullYear() ? 'numeric' : undefined });
  return withTime ? `${s} • ${d.toLocaleTimeString('ar-DZ', { hour: '2-digit', minute: '2-digit' })}` : s;
}
export function ago(v) {
  const d = toDate(v); if (!d) return '—';
  const s = Math.floor((Date.now() - d) / 1000);
  if (s < 60) return 'الآن';
  if (s < 3600) return `منذ ${Math.floor(s / 60)} د`;
  if (s < 86400) return `منذ ${Math.floor(s / 3600)} س`;
  if (s < 86400 * 7) return `منذ ${Math.floor(s / 86400)} يوم`;
  return fmtDate(d, false);
}
export const code = (id) => '#' + String(id || '').slice(-6).toUpperCase();
export function normPhone(v) {
  let p = String(v || '').replace(/[\s\-.]/g, '');
  if (p.startsWith('+213')) p = '0' + p.slice(4); else if (p.startsWith('00213')) p = '0' + p.slice(5);
  return p;
}

/* ─────────── حالات الطلب ─────────── */
export const STATUSES = [
  ['pending', 'جديد', '🆕'], ['no_answer', 'لم يرد', '📵'], ['confirmed', 'مؤكَّد', '✅'], ['shipped', 'شُحن', '🚚'],
  ['delivered', 'سُلِّم', '🎉'], ['returned', 'مُرتجع', '↩️'], ['cancelled', 'ملغى', '✖️'], ['waitlist', 'قائمة انتظار', '⏳'],
];
export const statusLabel = (s) => (STATUSES.find((x) => x[0] === s) || [s, s || '—'])[1];
export const statusPill = (s) => `<span class="pill s-${esc(s || 'pending')}">${esc(statusLabel(s || 'pending'))}</span>`;
export function orderTotal(o) {
  if (typeof o.lineTotal === 'number') return o.lineTotal;
  return (Number(o.unitPrice) || 0) * (Number(o.quantity) || 1) + (Number(o.shippingFee) || 0);
}

/* ─────────── تنبيهات ─────────── */
export function toast(msg, type = 'info') {
  const el = document.createElement('div');
  el.className = 'toast ' + type;
  el.innerHTML = `<span>${type === 'success' ? '✓' : type === 'error' ? '⚠' : 'ℹ'}</span><span>${esc(msg)}</span>`;
  document.getElementById('toasts').appendChild(el);
  setTimeout(() => { el.style.transition = '.3s'; el.style.opacity = '0'; setTimeout(() => el.remove(), 300); }, 3600);
}

/* ─────────── الدرج الجانبي ─────────── */
const $ = (id) => document.getElementById(id);
export function openDrawer({ title, body, foot = '' }) {
  $('drawer-title').textContent = title;
  $('drawer-body').innerHTML = body;
  $('drawer-foot').innerHTML = foot;
  $('drawer-foot').style.display = foot ? 'flex' : 'none';
  $('drawer').classList.add('show'); $('drawer').setAttribute('aria-hidden', 'false');
  $('backdrop').classList.add('show');
  return $('drawer');
}
export function closeDrawer() { $('drawer').classList.remove('show'); $('drawer').setAttribute('aria-hidden', 'true'); if (!$('modal').classList.contains('show')) $('backdrop').classList.remove('show'); }

/* ─────────── النوافذ ─────────── */
let modalResolve = null;
export function openModal({ title, body, foot = '', wide = false }) {
  $('modal-title').textContent = title;
  $('modal-body').innerHTML = body;
  $('modal-foot').innerHTML = foot;
  $('modal-foot').style.display = foot ? 'flex' : 'none';
  $('modal-card').classList.toggle('wide', wide);
  $('modal').classList.add('show');
  $('backdrop').classList.add('show');
  setTimeout(() => $('modal-body').querySelector('input:not([type=hidden]):not([type=checkbox]),textarea,select')?.focus(), 50);
  return $('modal');
}
export function closeModal() {
  $('modal').classList.remove('show');
  if (!$('drawer').classList.contains('show')) $('backdrop').classList.remove('show');
  if (modalResolve) { modalResolve(false); modalResolve = null; }
}
/** نافذة تأكيد تعيد true/false */
export function confirmBox(message, { title = 'تأكيد', ok = 'تأكيد', danger = false } = {}) {
  return new Promise((resolve) => {
    openModal({ title, body: `<p style="line-height:1.9;font-size:14.5px">${esc(message)}</p>`,
      foot: `<button class="btn ${danger ? 'btn-danger' : 'btn-primary'}" id="cf-ok">${esc(ok)}</button><button class="btn" data-close-modal>إلغاء</button>` });
    modalResolve = resolve;
    $('cf-ok').onclick = () => { modalResolve = null; closeModal(); resolve(true); };
  });
}
/** نافذة إدخال نص */
export function promptBox(label, { title = 'إدخال', value = '', placeholder = '', textarea = false } = {}) {
  return new Promise((resolve) => {
    openModal({ title, body: `<div class="field"><label>${esc(label)}</label>${textarea ? `<textarea class="textarea" id="pb-in" rows="4" placeholder="${esc(placeholder)}">${esc(value)}</textarea>` : `<input class="input" id="pb-in" value="${esc(value)}" placeholder="${esc(placeholder)}">`}</div>`,
      foot: '<button class="btn btn-primary" id="pb-ok">حفظ</button><button class="btn" data-close-modal>إلغاء</button>' });
    modalResolve = () => resolve(null);
    $('pb-ok').onclick = () => { const v = $('pb-in').value; modalResolve = null; closeModal(); resolve(v); };
  });
}

document.addEventListener('click', (e) => {
  if (e.target.closest('[data-close-modal]')) closeModal();
  if (e.target.closest('[data-close-drawer]')) closeDrawer();
  if (e.target.id === 'backdrop') { if ($('modal').classList.contains('show')) closeModal(); else closeDrawer(); }
  if (e.target.id === 'modal') closeModal();
});
document.addEventListener('keydown', (e) => {
  if (e.key !== 'Escape') return;
  if ($('modal').classList.contains('show')) closeModal(); else if ($('drawer').classList.contains('show')) closeDrawer();
});

/* ─────────── جدول عام قابل للفرز والتصفّح والتحديد ─────────── */
/**
 * mountTable(el, { columns:[{key,label,render(row),sort(row)->value,width}], rows, pageSize, selectable, onRow(row), rowId(row), empty, onSelect(ids) })
 * يعيد { setRows(rows), selected:Set }
 */
export function mountTable(el, opts) {
  const st = { rows: opts.rows || [], page: 1, sortKey: opts.sortKey || null, dir: opts.sortDir || -1, selected: new Set() };
  const size = opts.pageSize || 25;
  const idOf = opts.rowId || ((r) => r.id);
  function sorted() {
    if (!st.sortKey) return st.rows;
    const col = opts.columns.find((c) => c.key === st.sortKey);
    const val = col.sort || ((r) => r[col.key]);
    return [...st.rows].sort((a, b) => { const x = val(a), y = val(b); return (x > y ? 1 : x < y ? -1 : 0) * st.dir; });
  }
  function draw() {
    const rows = sorted();
    const pages = Math.max(1, Math.ceil(rows.length / size));
    st.page = Math.min(st.page, pages);
    const slice = rows.slice((st.page - 1) * size, st.page * size);
    const allSel = slice.length && slice.every((r) => st.selected.has(idOf(r)));
    el.innerHTML = `
      <div class="tbl-wrap"><table class="tbl"><thead><tr>
        ${opts.selectable ? `<th style="width:36px"><input type="checkbox" data-selall ${allSel ? 'checked' : ''} aria-label="تحديد الكل"></th>` : ''}
        ${opts.columns.map((c) => `<th class="${c.sort !== false ? 'sortable' : ''}" data-k="${c.key}" style="${c.width ? 'width:' + c.width : ''}">${esc(c.label)}${st.sortKey === c.key ? (st.dir > 0 ? ' ▲' : ' ▼') : ''}</th>`).join('')}
      </tr></thead><tbody>
        ${slice.length ? slice.map((r) => `<tr class="${opts.onRow ? 'clickable' : ''} ${st.selected.has(idOf(r)) ? 'sel' : ''}" data-id="${esc(idOf(r))}">
          ${opts.selectable ? `<td data-nc><input type="checkbox" data-sel="${esc(idOf(r))}" ${st.selected.has(idOf(r)) ? 'checked' : ''}></td>` : ''}
          ${opts.columns.map((c) => `<td>${c.render ? c.render(r) : esc(r[c.key])}</td>`).join('')}</tr>`).join('')
        : `<tr><td colspan="${opts.columns.length + (opts.selectable ? 1 : 0)}"><div class="empty"><div class="em">${opts.emptyIcon || '🗂️'}</div>${esc(opts.empty || 'لا توجد بيانات')}</div></td></tr>`}
      </tbody></table></div>
      ${rows.length > size ? `<div class="pager"><span>${num((st.page - 1) * size + 1)}–${num(Math.min(st.page * size, rows.length))} من ${num(rows.length)}</span>
        <span style="display:flex;gap:6px"><button class="btn btn-sm" data-pg="-1" ${st.page === 1 ? 'disabled' : ''}>السابق</button><button class="btn btn-sm" data-pg="1" ${st.page === pages ? 'disabled' : ''}>التالي</button></span></div>` : ''}`;
  }
  el.addEventListener('click', (e) => {
    const th = e.target.closest('th.sortable');
    if (th) { const k = th.dataset.k; st.dir = st.sortKey === k ? -st.dir : -1; st.sortKey = k; draw(); return; }
    const pg = e.target.closest('[data-pg]');
    if (pg) { st.page += Number(pg.dataset.pg); draw(); return; }
    if (e.target.matches('[data-selall]')) {
      const rows = sorted().slice((st.page - 1) * size, st.page * size);
      rows.forEach((r) => e.target.checked ? st.selected.add(idOf(r)) : st.selected.delete(idOf(r)));
      draw(); opts.onSelect?.(st.selected); return;
    }
    if (e.target.matches('[data-sel]')) {
      const id = e.target.dataset.sel; e.target.checked ? st.selected.add(id) : st.selected.delete(id);
      e.target.closest('tr').classList.toggle('sel', e.target.checked); opts.onSelect?.(st.selected); return;
    }
    if (e.target.closest('[data-nc],button,a,input,select,label,textarea')) return;
    const tr = e.target.closest('tr[data-id]');
    if (tr && opts.onRow) { const r = st.rows.find((x) => String(idOf(x)) === tr.dataset.id); if (r) opts.onRow(r); }
  });
  draw();
  return {
    setRows(rows, keepPage = false) { st.rows = rows; if (!keepPage) st.page = 1; const ids = new Set(rows.map(idOf)); [...st.selected].forEach((id) => { if (!ids.has(id)) st.selected.delete(id); }); draw(); },
    selected: st.selected,
    clearSelection() { st.selected.clear(); draw(); opts.onSelect?.(st.selected); },
    redraw: draw,
  };
}

/* ─────────── CSV ─────────── */
export function downloadCSV(filename, rows) {
  if (!rows.length) return toast('لا توجد بيانات للتصدير', 'error');
  const keys = Object.keys(rows[0]);
  const escCell = (v) => { const s = v === null || v === undefined ? '' : String(v); return /[",\n;]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s; };
  const csv = '﻿' + [keys.join(','), ...rows.map((r) => keys.map((k) => escCell(r[k])).join(','))].join('\n');
  const a = document.createElement('a');
  a.href = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8' }));
  a.download = filename; a.click();
  setTimeout(() => URL.revokeObjectURL(a.href), 2000);
}
export function parseCSV(text) {
  const rows = []; let row = []; let cell = ''; let q = false;
  text = text.replace(/^﻿/, '');
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (q) { if (c === '"' && text[i + 1] === '"') { cell += '"'; i++; } else if (c === '"') q = false; else cell += c; }
    else if (c === '"') q = true;
    else if (c === ',') { row.push(cell); cell = ''; }
    else if (c === '\n' || c === '\r') { if (c === '\r' && text[i + 1] === '\n') i++; row.push(cell); rows.push(row); row = []; cell = ''; }
    else cell += c;
  }
  if (cell || row.length) { row.push(cell); rows.push(row); }
  const [head, ...body] = rows.filter((r) => r.some((x) => x.trim()));
  return body.map((r) => Object.fromEntries(head.map((h, i) => [h.trim(), (r[i] || '').trim()])));
}

/* ─────────── سجلّ النشاط ─────────── */
export async function log(action, target = '', details = null) {
  try {
    await db.collection('admin_logs').add({
      uid: S.user?.uid || '', name: S.staff?.name || S.user?.email || '', role: S.role,
      action, target: String(target).slice(0, 200), details: details ? JSON.stringify(details).slice(0, 1500) : null,
      at: FV().serverTimestamp(),
    });
  } catch (e) { console.warn('log failed', e); }
}

/* ─────────── رفع الصور مع الضغط ─────────── */
export async function compressImage(file, max = 1600, quality = 0.85) {
  if (!file.type.startsWith('image/') || file.type === 'image/gif' || file.type === 'image/svg+xml') return file;
  const bmp = await createImageBitmap(file).catch(() => null);
  if (!bmp) return file;
  const scale = Math.min(1, max / Math.max(bmp.width, bmp.height));
  const c = document.createElement('canvas');
  c.width = Math.round(bmp.width * scale); c.height = Math.round(bmp.height * scale);
  c.getContext('2d').drawImage(bmp, 0, 0, c.width, c.height);
  const blob = await new Promise((r) => c.toBlob(r, 'image/webp', quality));
  return blob && blob.size < file.size ? new File([blob], file.name.replace(/\.\w+$/, '') + '.webp', { type: 'image/webp' }) : file;
}
export async function uploadImage(file, folder) {
  const f = await compressImage(file);
  const name = `${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 7)}.${(f.type.split('/')[1] || 'jpg').replace('jpeg', 'jpg')}`;
  const ref = storage.ref(`${folder}/${name}`);
  await ref.put(f, { contentType: f.type, cacheControl: 'public, max-age=31536000' });
  return ref.getDownloadURL();
}

/* ─────────── المنتجات (تحميل مرّة) ─────────── */
export async function loadProducts(force = false) {
  if (S.productsLoaded && !force) return S.products;
  const snap = await db.collection('products').get();
  S.products = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
  S.products.sort((a, b) => (toDate(b.createdAt)?.getTime() || 0) - (toDate(a.createdAt)?.getTime() || 0));
  S.productsLoaded = true;
  return S.products;
}

/**
 * توحيد شكل الطلب في الذاكرة: طلبات التطبيق (landing_product_screen.dart) تستعمل
 * phone / items[] / totalAmount / shipping / status 'processing'، وطلبات الموقع تستعمل
 * customerPhone / productName / quantity / unitPrice / lineTotal. لا يُكتب شيء من هذا إلى Firestore.
 */
export function normalizeOrder(o) {
  const it = Array.isArray(o.items) ? o.items : [];
  const first = it[0] || {};
  const n = { ...o };
  n.customerPhone = o.customerPhone || o.phone || '';
  n.customerName = o.customerName || o.name || '';
  n.productName = o.productName || first.name || '';
  n.productId = o.productId || first.productId || '';
  n.quantity = Number(o.quantity) || it.reduce((s, x) => s + (Number(x.quantity) || 1), 0) || 1;
  if (o.unitPrice === undefined && first.priceValue !== undefined) n.unitPrice = Number(first.priceValue) || 0;
  if (o.shippingFee === undefined && o.shipping !== undefined) n.shippingFee = Number(o.shipping) || 0;
  if (typeof o.lineTotal !== 'number' && typeof o.totalAmount === 'number') n.lineTotal = o.totalAmount;
  if (!o.variant && (first.variant || first.option)) n.variant = [first.variant, first.option].filter(Boolean).join(' • ');
  if (it.length > 1) { n.productName += ` +${it.length - 1}`; }
  if (o.status === 'processing') n.status = 'confirmed';
  n.wilaya = o.wilaya || (typeof o.address === 'object' && o.address ? o.address.wilaya || o.address.state || '' : '');
  if (typeof o.address === 'object' && o.address) n.address = [o.address.street, o.address.city, o.address.commune].filter(Boolean).join('، ');
  return n;
}

/** صورة المنتج (مخطّط التطبيق: imageUrls + coverImage) */
export function pimg(p) { return (p.images && p.images[0]) || (p.imageUrls && p.imageUrls[0]) || p.coverImage || p.imageUrl || p.image || '/favicon.png'; }
export function pimages(p) { const l = (Array.isArray(p.images) && p.images.length ? p.images : Array.isArray(p.imageUrls) ? p.imageUrls : [p.coverImage || p.imageUrl || p.image]).filter(Boolean); return [...new Set(l)]; }
/** التطبيق يقرأ price/oldPrice كنصوص (Text(d['price'])) — نكتبها دائماً نصاً */
export const priceStr = (n) => (n === '' || n === null || n === undefined || Number(n) <= 0) ? '' : String(Math.round(Number(n)));

/* ─────────── فترات زمنية ─────────── */
export function rangeStart(key) {
  const d = new Date(); d.setHours(0, 0, 0, 0);
  const days = { today: 0, '7d': 6, '30d': 29, '90d': 89 }[key] ?? 29;
  d.setDate(d.getDate() - days);
  return d;
}
export const dayKey = (d) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;

/** تجميع الطلبات في سلال (طلب الموقع متعدّد المنتجات = عدّة وثائق تشترك في cartId) */
export function groupCarts(orders) {
  const m = new Map();
  orders.forEach((o) => { const k = o.cartId || o.id; if (!m.has(k)) m.set(k, []); m.get(k).push(o); });
  return [...m.values()];
}

/** تكرار: نفس الهاتف أكثر من سلّة خلال 24 ساعة */
export function duplicatePhones(orders) {
  const byPhone = new Map();
  groupCarts(orders).forEach((cart) => {
    const o = cart[0]; const p = normPhone(o.customerPhone); if (!p) return;
    const t = toDate(o.createdAt)?.getTime() || 0;
    if (!byPhone.has(p)) byPhone.set(p, []);
    byPhone.get(p).push(t);
  });
  const dups = new Set();
  byPhone.forEach((times, p) => { times.sort(); for (let i = 1; i < times.length; i++) if (times[i] - times[i - 1] < 86400000) dups.add(p); });
  return dups;
}

/** صوت تنبيه بسيط عبر WebAudio */
let audioCtx = null;
export function chime() {
  if (localStorage.getItem('ad_sound') === 'off') return;
  try {
    audioCtx = audioCtx || new (window.AudioContext || window.webkitAudioContext)();
    [[880, 0], [1320, 0.13]].forEach(([f, t]) => {
      const o = audioCtx.createOscillator(); const g = audioCtx.createGain();
      o.type = 'sine'; o.frequency.value = f; o.connect(g); g.connect(audioCtx.destination);
      const s = audioCtx.currentTime + t; g.gain.setValueAtTime(0.0001, s); g.gain.exponentialRampToValueAtTime(0.25, s + 0.02); g.gain.exponentialRampToValueAtTime(0.0001, s + 0.35);
      o.start(s); o.stop(s + 0.4);
    });
  } catch (_) {}
}
