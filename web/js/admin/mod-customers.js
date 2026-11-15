// العميلات: مشتقّة من الطلبات (حسب رقم الهاتف) — لا نقرأ مجموعة users إطلاقاً (بيانات صحية خاصة)
import { S, db, esc, da, num, toDate, normPhone, orderTotal, groupCarts, ago, fmtDate, statusPill, code, mountTable, openDrawer, downloadCSV, onData } from './core.js';
import { openOrder, toggleBlock } from './mod-orders.js';

let table = null; let q = ''; let seg = 'all';
const SEG = { all: 'الكل', vip: '💎 مميّزات (3+ مُسلَّم)', repeat: '🔁 متكرّرات', risky: '⚠️ نسبة إرجاع عالية', blocked: '⛔ محظورات', new: '🆕 جديدات (7 أيام)' };

function build() {
  const m = new Map();
  groupCarts(S.orders).forEach((cart) => {
    const o = cart[0]; const p = normPhone(o.customerPhone); if (!p) return;
    if (!m.has(p)) m.set(p, { id: p, phone: p, name: o.customerName || '', wilaya: o.wilaya || '', carts: 0, delivered: 0, returned: 0, cancelled: 0, spend: 0, first: Infinity, last: 0, lastId: o.id });
    const c = m.get(p);
    const t = toDate(o.createdAt)?.getTime() || 0;
    c.carts++;
    if (o.status === 'delivered') { c.delivered++; c.spend += cart.reduce((s, x) => s + orderTotal(x), 0); }
    if (o.status === 'returned') c.returned++;
    if (o.status === 'cancelled') c.cancelled++;
    if (t > c.last) { c.last = t; c.lastId = o.id; c.name = o.customerName || c.name; c.wilaya = o.wilaya || c.wilaya; }
    c.first = Math.min(c.first, t);
  });
  return [...m.values()];
}
function match(c) {
  if (q && !(`${c.name} ${c.wilaya}`.toLowerCase().includes(q) || c.phone.includes(normPhone(q)))) return false;
  const decided = c.delivered + c.returned;
  if (seg === 'vip') return c.delivered >= 3;
  if (seg === 'repeat') return c.carts >= 2;
  if (seg === 'risky') return decided >= 2 && c.returned / decided >= 0.5;
  if (seg === 'blocked') return S.blocked.has(c.phone);
  if (seg === 'new') return c.first > Date.now() - 7 * 86400000;
  return true;
}

export default {
  render(el) {
    el.innerHTML = `
      <div class="ad-page-head"><div><h1>العميلات</h1><p id="cu-sub">مستخرجة من الطلبات حسب رقم الهاتف</p></div>
        <div class="ad-actions"><button class="btn" id="cu-csv">⬇️ تصدير</button></div></div>
      <div class="grid g-4" id="cu-kpi" style="margin-bottom:16px"></div>
      <div class="chips" id="cu-chips" style="margin-bottom:12px"></div>
      <div class="toolbar"><input class="input" id="cu-q" placeholder="🔍 الاسم، الهاتف، الولاية…" style="flex:1"></div>
      <div class="card" id="cu-tbl"></div>`;
    el.querySelector('#cu-q').oninput = (e) => { q = e.target.value.trim().toLowerCase(); draw(); };
    el.querySelector('#cu-csv').onclick = () => downloadCSV('nabda-customers.csv', build().filter(match).map((c) => ({
      الاسم: c.name, الهاتف: c.phone, الولاية: c.wilaya, الطلبات: c.carts, المسلّم: c.delivered, المرتجع: c.returned, الإنفاق: c.spend, 'آخر طلب': fmtDate(c.last), محظورة: S.blocked.has(c.phone) ? 'نعم' : '' })));
    table = null; draw();
    return onData(() => draw());
  },
};

function draw() {
  const all = build();
  const k = (ic, label, val, sub = '') => `<div class="card kpi"><div class="kpi-top"><span>${label}</span><span>${ic}</span></div><div class="kpi-val num">${val}</div><div class="kpi-sub">${sub}</div></div>`;
  const repeat = all.filter((c) => c.carts >= 2).length;
  const totalSpend = all.reduce((s, c) => s + c.spend, 0);
  document.getElementById('cu-kpi').innerHTML = [
    k('👥', 'إجمالي العميلات', num(all.length)),
    k('🔁', 'نسبة التكرار', all.length ? Math.round((repeat / all.length) * 100) + '%' : '—', `${num(repeat)} زبونة عادت للشراء`),
    k('💰', 'متوسط الإنفاق (مُسلَّم)', da(Math.round(totalSpend / Math.max(1, all.filter((c) => c.delivered).length)))),
    k('⛔', 'أرقام محظورة', num(S.blocked.size)),
  ].join('');
  document.getElementById('cu-chips').innerHTML = Object.entries(SEG).map(([kk, l]) => `<button class="chip ${seg === kk ? 'active' : ''}" data-s="${kk}">${l}</button>`).join('');
  document.querySelectorAll('#cu-chips .chip').forEach((c) => c.onclick = () => { seg = c.dataset.s; draw(); });
  const rows = all.filter(match);
  if (table) return table.setRows(rows, true);
  table = mountTable(document.getElementById('cu-tbl'), {
    rows, pageSize: 30, sortKey: 'last', empty: 'لا عميلات بعد', emptyIcon: '👥', rowId: (c) => c.phone,
    onRow: openCustomer,
    columns: [
      { key: 'name', label: 'الزبونة', render: (c) => `<div class="cell-strong">${esc(c.name || '—')} ${S.blocked.has(c.phone) ? '<span class="tag red">محظورة</span>' : c.delivered >= 3 ? '<span class="tag pink">💎</span>' : ''}</div><div class="muted num" dir="ltr" style="text-align:right">${esc(c.phone)}</div>` },
      { key: 'wilaya', label: 'الولاية' },
      { key: 'carts', label: 'الطلبات', render: (c) => `<b class="num">${num(c.carts)}</b>` },
      { key: 'delivered', label: 'مُسلَّم / مُرتجع', sort: (c) => c.delivered, render: (c) => `<span class="tag teal">✅ ${c.delivered}</span> ${c.returned ? `<span class="tag red">↩️ ${c.returned}</span>` : ''}` },
      { key: 'spend', label: 'الإنفاق', render: (c) => `<b class="num">${da(c.spend)}</b>` },
      { key: 'last', label: 'آخر طلب', render: (c) => `<span class="muted">${ago(c.last)}</span>` },
    ],
  });
}

function openCustomer(c) {
  const orders = S.orders.filter((o) => normPhone(o.customerPhone) === c.phone);
  const intl = c.phone.startsWith('0') ? (S.market === 'SA' ? '966' : '213') + c.phone.slice(1) : c.phone;
  openDrawer({
    title: c.name || c.phone,
    body: `<div class="card" style="margin-bottom:14px"><div class="card-b"><dl class="kv">
        <dt>الهاتف</dt><dd dir="ltr" style="text-align:right">${esc(c.phone)}</dd><dt>الولاية</dt><dd>${esc(c.wilaya || '—')}</dd>
        <dt>زبونة منذ</dt><dd>${fmtDate(c.first, false)}</dd><dt>الطلبات</dt><dd>${c.carts} • ✅ ${c.delivered} • ↩️ ${c.returned} • ✖️ ${c.cancelled}</dd>
        <dt>الإنفاق</dt><dd>${da(c.spend)}</dd></dl>
        <div style="display:flex;gap:6px;margin-top:12px"><a class="btn btn-sm btn-teal" href="tel:${esc(c.phone)}">📞 اتصال</a><a class="btn btn-sm" target="_blank" rel="noopener" href="https://wa.me/${esc(intl)}">💬 واتساب</a></div></div></div>
      <div class="card"><div class="card-h"><h3>سجلّ الطلبات</h3></div>${groupCarts(orders).map((cart) => { const o = cart[0];
        return `<div class="list-row" style="padding:10px 16px;cursor:pointer" data-o="${esc(o.id)}"><div style="flex:1"><b class="num">${code(o.id)}</b> — ${esc(o.productName || '')}${cart.length > 1 ? ` +${cart.length - 1}` : ''}<div style="font-size:12px;color:var(--ink-3)">${fmtDate(o.createdAt)}</div></div><b class="num">${da(cart.reduce((s, x) => s + orderTotal(x), 0))}</b> ${statusPill(o.status)}</div>`; }).join('')}</div>`,
    foot: `<button class="btn ${S.blocked.has(c.phone) ? '' : 'btn-danger'}" id="cu-block">${S.blocked.has(c.phone) ? '✅ رفع الحظر' : '⛔ حظر الرقم'}</button>`,
  });
  document.querySelectorAll('#drawer [data-o]').forEach((r) => r.onclick = () => { location.hash = 'orders'; setTimeout(() => openOrder(r.dataset.o), 80); });
  document.getElementById('cu-block').onclick = () => toggleBlock(c.phone, c.name);
}
