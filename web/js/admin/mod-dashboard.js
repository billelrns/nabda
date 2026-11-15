// لوحة القيادة: مؤشرات مع مقارنة بالفترة السابقة، رسوم بيانية، أفضل المنتجات والولايات، تنبيهات المخزون
import { S, db, esc, da, num, toDate, code, statusPill, orderTotal, rangeStart, dayKey, groupCarts, onData, loadProducts, STATUSES, ago, pimg, can, TS } from './core.js';
import { openOrder } from './mod-orders.js';

let range = localStorage.getItem('ad_range') || '30d';
const charts = [];

export default {
  render(view) {
    view.innerHTML = `
      <div class="ad-page-head">
        <div><h1>لوحة القيادة</h1><p id="db-sub">نظرة لحظية على أداء متجر نبضة</p></div>
        <div class="ad-actions"><div class="seg" id="db-range">
          ${[['today', 'اليوم'], ['7d', '7 أيام'], ['30d', '30 يوماً'], ['90d', '90 يوماً']].map(([k, l]) => `<button data-r="${k}" class="${range === k ? 'active' : ''}">${l}</button>`).join('')}
        </div></div>
      </div>
      <div class="grid g-4" id="db-kpis"></div>
      <div class="grid g-4" id="db-app" style="margin-top:16px"></div>
      <div class="grid g-21" style="margin-top:16px">
        <div class="card"><div class="card-h"><h3>📈 الطلبات والإيراد</h3><span class="tag" id="db-chart-tag"></span></div><div class="card-b" style="height:300px"><canvas id="ch-trend"></canvas></div></div>
        <div class="card"><div class="card-h"><h3>🍩 توزيع الحالات</h3></div><div class="card-b" style="height:300px"><canvas id="ch-status"></canvas></div></div>
      </div>
      <div class="grid g-3" style="margin-top:16px">
        <div class="card"><div class="card-h"><h3>🏆 الأكثر مبيعاً</h3></div><div class="card-b" id="db-top-products"></div></div>
        <div class="card"><div class="card-h"><h3>📍 أعلى الولايات</h3></div><div class="card-b" id="db-top-wilayas"></div></div>
        <div class="card"><div class="card-h"><h3>⚠️ تنبيهات المخزون</h3><a class="btn btn-sm" href="#products">المنتجات</a></div><div class="card-b" id="db-stock"></div></div>
      </div>
      <div class="grid g-21" style="margin-top:16px">
        <div class="card"><div class="card-h"><h3>🕐 أحدث الطلبات</h3><a class="btn btn-sm" href="#orders">كل الطلبات</a></div><div id="db-recent"></div></div>
        <div class="card"><div class="card-h"><h3>⏰ ساعات الذروة</h3><span class="tag">آخر 30 يوماً</span></div><div class="card-b"><div class="heat" id="db-heat"></div><div style="display:flex;justify-content:space-between;font-size:11px;color:var(--ink-3);margin-top:6px"><span>00</span><span>06</span><span>12</span><span>18</span><span>23</span></div><div id="db-peak" style="margin-top:12px;font-weight:800;font-size:13px"></div></div></div>
      </div>`;
    view.querySelector('#db-range').onclick = (e) => {
      const b = e.target.closest('[data-r]'); if (!b) return;
      range = b.dataset.r; localStorage.setItem('ad_range', range);
      view.querySelectorAll('#db-range button').forEach((x) => x.classList.toggle('active', x === b));
      draw();
    };
    loadProducts().then(draw).catch(() => draw());
    draw();
    appPulse();
    const off = onData((t) => { if (t === 'orders' || t === 'theme') draw(); });
    return () => { off(); charts.splice(0).forEach((c) => c.destroy()); };
  },
};

function inRange(o, from, to) { const t = toDate(o.createdAt)?.getTime() || 0; return t >= from && t < to; }

function stats(list) {
  const carts = groupCarts(list);
  const by = (s) => list.filter((o) => (o.status || 'pending') === s);
  const delivered = by('delivered'); const returned = by('returned');
  const decided = list.filter((o) => !['pending', 'no_answer', 'waitlist'].includes(o.status || 'pending'));
  const confirmedish = list.filter((o) => ['confirmed', 'shipped', 'delivered', 'returned'].includes(o.status));
  const revenue = delivered.reduce((s, o) => s + orderTotal(o), 0);
  const pipeline = list.filter((o) => ['confirmed', 'shipped'].includes(o.status)).reduce((s, o) => s + orderTotal(o), 0);
  const cartValues = carts.map((c) => c.reduce((s, o) => s + orderTotal(o), 0));
  return {
    orders: carts.length,
    revenue, pipeline,
    aov: cartValues.length ? cartValues.reduce((a, b) => a + b, 0) / cartValues.length : 0,
    confirmRate: decided.length ? confirmedish.length / decided.length : 0,
    deliveryRate: delivered.length + returned.length ? delivered.length / (delivered.length + returned.length) : 0,
    returnRate: delivered.length + returned.length ? returned.length / (delivered.length + returned.length) : 0,
    pending: carts.filter((c) => (c[0].status || 'pending') === 'pending').length,
  };
}

function delta(cur, prev, invert = false) {
  if (!prev && !cur) return '<span class="delta flat">—</span>';
  if (!prev) return '<span class="delta up">جديد</span>';
  const d = (cur - prev) / prev;
  const good = invert ? d < 0 : d > 0;
  return `<span class="delta ${Math.abs(d) < 0.005 ? 'flat' : good ? 'up' : 'down'}">${d > 0 ? '↑' : d < 0 ? '↓' : ''} ${Math.abs(d * 100).toFixed(0)}%</span>`;
}

function draw() {
  const el = document.getElementById('db-kpis'); if (!el) return;
  const from = rangeStart(range).getTime();
  const now = Date.now() + 1;
  const span = now - from;
  const cur = S.orders.filter((o) => inRange(o, from, now));
  const prev = S.orders.filter((o) => inRange(o, from - span, from));
  const a = stats(cur); const b = stats(prev);
  const pct = (x) => (x * 100).toFixed(0) + '%';
  const kpi = (ic, bg, label, val, d, sub = '') => `
    <div class="card kpi"><div class="kpi-top"><span>${label}</span><span class="kpi-ic" style="background:${bg}">${ic}</span></div>
    <div class="kpi-val num">${val}</div><div class="kpi-sub">${d}<span>${sub}</span></div></div>`;
  el.innerHTML = [
    kpi('🛒', 'var(--pink-soft)', 'الطلبات (سلال)', num(a.orders), delta(a.orders, b.orders), `${num(a.pending)} بانتظار التأكيد`),
    kpi('💰', 'var(--green-soft)', 'الإيراد المُسلَّم', da(a.revenue), delta(a.revenue, b.revenue), `+ ${da(a.pipeline)} قيد التوصيل`),
    kpi('🧺', 'var(--blue-soft)', 'متوسط السلّة', da(Math.round(a.aov)), delta(a.aov, b.aov)),
    kpi('✅', 'var(--teal-soft)', 'نسبة التأكيد', pct(a.confirmRate), delta(a.confirmRate, b.confirmRate)),
    kpi('🎉', 'var(--green-soft)', 'نسبة التسليم', pct(a.deliveryRate), delta(a.deliveryRate, b.deliveryRate), 'من الطرود المحسومة'),
    kpi('↩️', 'var(--red-soft)', 'نسبة الإرجاع', pct(a.returnRate), delta(a.returnRate, b.returnRate, true)),
    kpi('📦', 'var(--violet-soft)', 'قطع مباعة', num(cur.filter((o) => !['cancelled', 'returned'].includes(o.status)).reduce((s, o) => s + (Number(o.quantity) || 1), 0)), ''),
    kpi('🌐', 'var(--amber-soft)', 'من الموقع / التطبيق', `${num(groupCarts(cur.filter((o) => o.source === 'website')).length)} / ${num(groupCarts(cur.filter((o) => o.source !== 'website')).length)}`, ''),
  ].join('');
  document.getElementById('db-sub').textContent = `آخر تحديث ${new Date().toLocaleTimeString('ar-DZ', { hour: '2-digit', minute: '2-digit' })} • ${num(S.orders.length)} طلب محمّل`;

  drawCharts(cur, from);
  topProducts(cur);
  topWilayas(cur);
  stock();
  recent();
  heat();
}

function css(v) { return getComputedStyle(document.documentElement).getPropertyValue(v).trim(); }

function drawCharts(cur, from) {
  if (!window.Chart) { setTimeout(() => drawCharts(cur, from), 300); return; }
  charts.splice(0).forEach((c) => c.destroy());
  const Chart = window.Chart;
  Chart.defaults.font.family = 'Cairo'; Chart.defaults.color = css('--ink-3');
  const days = []; const d = new Date(from);
  const end = new Date(); end.setHours(0, 0, 0, 0);
  while (d <= end) { days.push(dayKey(d)); d.setDate(d.getDate() + 1); }
  if (days.length === 1) days.unshift(dayKey(new Date(Date.now() - 86400000)));
  const ordersBy = Object.fromEntries(days.map((k) => [k, new Set()]));
  const revBy = Object.fromEntries(days.map((k) => [k, 0]));
  cur.forEach((o) => {
    const t = toDate(o.createdAt); if (!t) return;
    const k = dayKey(t); if (!(k in ordersBy)) return;
    ordersBy[k].add(o.cartId || o.id);
    if (o.status === 'delivered') revBy[k] += orderTotal(o);
  });
  document.getElementById('db-chart-tag').textContent = `${days.length} يوماً`;
  const grid = css('--line-2');
  charts.push(new Chart(document.getElementById('ch-trend'), {
    data: {
      labels: days.map((k) => k.slice(5).replace('-', '/')),
      datasets: [
        { type: 'line', label: 'الطلبات', data: days.map((k) => ordersBy[k].size), borderColor: '#E91E63', backgroundColor: 'rgba(233,30,99,.12)', fill: true, tension: .35, pointRadius: days.length > 40 ? 0 : 3, yAxisID: 'y' },
        { type: 'bar', label: 'إيراد مُسلَّم (دج)', data: days.map((k) => revBy[k]), backgroundColor: 'rgba(0,137,123,.35)', borderRadius: 6, yAxisID: 'y1' },
      ],
    },
    options: { responsive: true, maintainAspectRatio: false, interaction: { mode: 'index', intersect: false },
      plugins: { legend: { position: 'bottom', labels: { usePointStyle: true } } },
      scales: { x: { grid: { display: false }, reverse: true }, y: { beginAtZero: true, ticks: { precision: 0 }, grid: { color: grid }, position: 'right' }, y1: { beginAtZero: true, grid: { display: false }, position: 'left' } } },
  }));
  const colors = { pending: '#F59E0B', no_answer: '#FB923C', confirmed: '#3B82F6', shipped: '#8B5CF6', delivered: '#16A34A', returned: '#E53935', cancelled: '#A8A29E', waitlist: '#06B6D4' };
  const counts = STATUSES.map(([s]) => cur.filter((o) => (o.status || 'pending') === s).length);
  charts.push(new Chart(document.getElementById('ch-status'), {
    type: 'doughnut',
    data: { labels: STATUSES.map((s) => s[1]), datasets: [{ data: counts, backgroundColor: STATUSES.map(([s]) => colors[s]), borderWidth: 0 }] },
    options: { responsive: true, maintainAspectRatio: false, cutout: '68%', plugins: { legend: { position: 'bottom', labels: { usePointStyle: true, boxWidth: 8 } } } },
  }));
}

function bars(el, rows, fmt) {
  const max = Math.max(1, ...rows.map((r) => r[1]));
  el.innerHTML = rows.length ? rows.map(([label, val, sub]) => `
    <div class="list-row"><div style="flex:0 0 42%;font-weight:800;font-size:13px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap" title="${esc(label)}">${esc(label)}</div>
    <div class="bar-track"><div class="bar-fill" style="width:${(val / max) * 100}%"></div></div>
    <div class="num" style="flex:0 0 auto;font-weight:900;font-size:13px">${fmt(val)}</div>${sub ? `<div class="muted" style="font-size:11px;color:var(--ink-3)">${sub}</div>` : ''}</div>`).join('')
    : '<div class="empty" style="padding:24px">لا بيانات في هذه الفترة</div>';
}
function topProducts(cur) {
  const m = new Map();
  cur.filter((o) => !['cancelled', 'returned'].includes(o.status)).forEach((o) => {
    const k = o.productName || o.productId; m.set(k, (m.get(k) || 0) + (Number(o.quantity) || 1));
  });
  bars(document.getElementById('db-top-products'), [...m].sort((a, b) => b[1] - a[1]).slice(0, 7), (v) => num(v) + ' قطعة');
}
function topWilayas(cur) {
  const m = new Map();
  groupCarts(cur).forEach((c) => { const w = c[0].wilaya || '—'; m.set(w, (m.get(w) || 0) + 1); });
  bars(document.getElementById('db-top-wilayas'), [...m].sort((a, b) => b[1] - a[1]).slice(0, 7), (v) => num(v));
}
function stock() {
  const el = document.getElementById('db-stock');
  const list = S.products.filter((p) => p.active !== false && typeof p.stock === 'number' && p.stock <= 5).sort((a, b) => a.stock - b.stock).slice(0, 8);
  el.innerHTML = !S.productsLoaded ? '<div class="skel" style="height:120px"></div>' : list.length ? list.map((p) => `
    <div class="list-row"><img src="${esc(pimg(p))}" style="width:36px;height:36px;border-radius:9px;object-fit:cover" alt="">
      <div style="flex:1;font-weight:800;font-size:13px">${esc(p.name)}</div>
      <span class="tag ${p.stock === 0 ? 'red' : 'amber'}">${p.stock === 0 ? 'نفد' : `بقي ${p.stock}`}</span></div>`).join('')
    : '<div class="empty" style="padding:24px"><div class="em">✅</div>المخزون بخير</div>';
}
function recent() {
  const el = document.getElementById('db-recent');
  const carts = groupCarts(S.orders).slice(0, 8);
  el.innerHTML = carts.length ? `<div class="tbl-wrap"><table class="tbl"><tbody>${carts.map((c) => {
    const o = c[0];
    return `<tr class="clickable" data-o="${esc(o.id)}"><td><b class="num">${code(o.cartId && c.length > 1 ? o.cartId : o.id)}</b><div class="muted">${ago(o.createdAt)}</div></td>
      <td><div class="cell-strong">${esc(o.customerName || '—')}</div><div class="muted" dir="ltr" style="text-align:right">${esc(o.customerPhone || '')}</div></td>
      <td class="muted">${esc(o.wilaya || '')}</td><td>${esc(o.productName || '')}${c.length > 1 ? ` <span class="tag">+${c.length - 1}</span>` : ''}</td>
      <td class="num cell-strong">${da(c.reduce((s, x) => s + orderTotal(x), 0))}</td><td>${statusPill(o.status)}</td></tr>`;
  }).join('')}</tbody></table></div>` : '<div class="empty"><div class="em">📭</div>لا طلبات بعد</div>';
  el.querySelectorAll('[data-o]').forEach((tr) => tr.onclick = () => { location.hash = 'orders'; setTimeout(() => openOrder(tr.dataset.o), 80); });
}
function heat() {
  const el = document.getElementById('db-heat');
  const from = Date.now() - 30 * 86400000;
  const h = Array(24).fill(0);
  groupCarts(S.orders).forEach((c) => { const t = toDate(c[0].createdAt); if (t && t.getTime() >= from) h[t.getHours()]++; });
  const max = Math.max(1, ...h);
  el.innerHTML = h.map((v, i) => `<div title="${i}:00 — ${v} طلب" style="opacity:${0.08 + (v / max) * 0.92}"></div>`).join('');
  const peak = h.indexOf(Math.max(...h));
  document.getElementById('db-peak').textContent = Math.max(...h) ? `ذروة الطلبات بين ${peak}:00 و ${(peak + 1) % 24}:00 — أنسب وقت لنشر الإعلانات وتأكيد الطلبات.` : '';
}

/** نبض التطبيق: المستخدمات، البلاغات، طلبات الاستعادة، الإشعارات — بطاقات تفتح الوحدة المعنية */
async function appPulse() {
  const box = document.getElementById('db-app'); if (!box) return;
  const card = (href, ic, bg, l, v, sub) => `<a class="card kpi" href="#${href}" style="text-decoration:none;color:inherit"><div class="kpi-top"><span>${l}</span><span class="kpi-ic" style="background:${bg}">${ic}</span></div><div class="kpi-val num">${v}</div><div class="kpi-sub"><span>${sub}</span></div></a>`;
  const safe = async (fn) => { try { return await fn(); } catch (_) { return null; } };
  // count() غير متاح في كل نسخ SDK compat — نرجع لقراءة محدودة عند الحاجة
  const countOf = async (q) => { try { return (await q.count().get()).data().count; } catch (_) { return (await q.limit(3000).get()).size; } };
  const weekAgo = TS().fromDate(new Date(Date.now() - 7 * 86400000));
  const [users, fresh, reports, resets] = await Promise.all([
    can('users') ? safe(() => countOf(db.collection('users_directory'))) : null,
    can('users') ? safe(() => countOf(db.collection('users_directory').where('createdAt', '>=', weekAgo))) : null,
    can('moderation') ? safe(async () => (await db.collection('reports').where('status', '==', 'pending').limit(200).get()).size) : null,
    can('support') ? safe(async () => (await db.collection('password_reset_requests').limit(200).get()).docs.filter((d) => d.data().status !== 'resolved').length) : null,
  ]);
  if (!document.getElementById('db-app')) return;
  const items = [];
  if (users !== null) items.push(card('users', '👩', 'var(--pink-soft)', 'مستخدمات التطبيق', num(users), fresh !== null ? `+${num(fresh)} هذا الأسبوع` : ''));
  if (reports !== null) items.push(card('moderation', '🛡️', reports ? 'var(--red-soft)' : 'var(--green-soft)', 'بلاغات بانتظار المراجعة', num(reports), reports ? 'تحتاج قراراً' : 'لا شيء معلّق ✓'));
  if (resets !== null) items.push(card('support', '🔑', resets ? 'var(--amber-soft)' : 'var(--green-soft)', 'طلبات استعادة كلمة المرور', num(resets), resets ? 'ردّي عبر واتساب' : 'لا شيء معلّق ✓'));
  if (can('notify')) items.push(card('notify', '📣', 'var(--teal-soft)', 'إشعار جماعي', '➜', 'أرسلي عرضاً أو مقالاً لكل المستخدمات'));
  box.innerHTML = items.join('');
  box.style.display = items.length ? '' : 'none';
}
