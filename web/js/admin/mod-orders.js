// الطلبات: جدول + كانبان، فلاتر، تحديد جماعي، درج تفاصيل، خطّ زمني، واتساب، طباعة، تصدير، كشف التكرار والقائمة السوداء
import { S, db, esc, da, num, toDate, code, statusPill, statusLabel, orderTotal, STATUSES, fmtDate, ago, normPhone, groupCarts, duplicatePhones,
  onData, mountTable, openDrawer, closeDrawer, toast, confirmBox, promptBox, downloadCSV, log, can, FV, rangeStart, loadProducts, marketOf } from './core.js';
import { getStoreSettingsCached } from './mod-settings.js';

let view = 'table';
const F = { status: 'all', q: '', range: 'all', wilaya: '', source: '' };
let table = null;

const LANES = ['pending', 'no_answer', 'confirmed', 'shipped', 'delivered', 'returned', 'cancelled'];
const WA_TEMPLATES = {
  confirm: (o, t) => `السلام عليكم ${o.customerName || ''} 🌸\nمعكِ متجر نبضة. نؤكّد طلبكِ ${code(o.cartId || o.id)}:\n${t.items}\nالمبلغ عند الاستلام: ${t.total}\nالعنوان: ${o.wilaya || ''} - ${o.commune || ''} ${o.address || ''}\nهل نؤكّد الشحن؟`,
  shipped: (o, t) => `مرحباً ${o.customerName || ''} 💗\nطلبكِ ${code(o.cartId || o.id)} في الطريق إليكِ 🚚\nيرجى إبقاء هاتفكِ مفتوحاً لاتصال عون التوصيل.\nالمبلغ: ${t.total}`,
  noanswer: (o) => `مرحباً ${o.customerName || ''} 🌸\nحاولنا الاتصال بكِ لتأكيد طلبكِ من متجر نبضة ${code(o.cartId || o.id)}. متى يناسبكِ أن نتّصل؟`,
};

export default {
  render(el) {
    view = localStorage.getItem('ad_orders_view') || 'table';
    el.innerHTML = `
      <div class="ad-page-head">
        <div><h1>الطلبات</h1><p id="or-sub">إدارة وتأكيد وشحن الطلبات لحظياً</p></div>
        <div class="ad-actions">
          <div class="seg" id="or-view"><button data-v="table" class="${view === 'table' ? 'active' : ''}">☰ جدول</button><button data-v="kanban" class="${view === 'kanban' ? 'active' : ''}">▦ كانبان</button></div>
          <button class="btn" id="or-export">⬇️ تصدير CSV</button>
        </div>
      </div>
      <div class="chips" id="or-chips" style="margin-bottom:12px"></div>
      <div class="toolbar">
        <input class="input" id="or-q" placeholder="🔍 اسم، هاتف، رقم طلب، منتج…" style="flex:1;min-width:220px" value="${esc(F.q)}">
        <select class="select" id="or-range">
          ${[['all', 'كل الفترات'], ['today', 'اليوم'], ['7d', 'آخر 7 أيام'], ['30d', 'آخر 30 يوماً'], ['90d', 'آخر 90 يوماً']].map(([k, l]) => `<option value="${k}" ${F.range === k ? 'selected' : ''}>${l}</option>`).join('')}
        </select>
        <select class="select" id="or-wilaya"><option value="">كل الولايات</option></select>
        <select class="select" id="or-source"><option value="">كل المصادر</option><option value="website" ${F.source === 'website' ? 'selected' : ''}>الموقع</option><option value="app" ${F.source === 'app' ? 'selected' : ''}>التطبيق</option></select>
      </div>
      <div id="or-body"></div>
      <div class="bulkbar hidden" id="or-bulk">
        <b id="or-bulk-n"></b>
        <select id="or-bulk-status"><option value="">تغيير الحالة إلى…</option>${STATUSES.filter((s) => s[0] !== 'waitlist').map(([k, l]) => `<option value="${k}">${l}</option>`).join('')}</select>
        <button class="btn btn-sm" id="or-bulk-apply">تطبيق</button>
        <button class="btn btn-sm" id="or-bulk-print">🖨️ ملصقات الشحن</button>
        <button class="btn btn-sm" id="or-bulk-csv">⬇️ تصدير المحدّد</button>
        <button class="btn btn-sm" id="or-bulk-clear" style="margin-right:auto">إلغاء التحديد</button>
      </div>`;
    el.querySelector('#or-view').onclick = (e) => { const b = e.target.closest('[data-v]'); if (!b) return; view = b.dataset.v; localStorage.setItem('ad_orders_view', view); el.querySelectorAll('#or-view button').forEach((x) => x.classList.toggle('active', x === b)); table = null; draw(); };
    let t; el.querySelector('#or-q').oninput = (e) => { clearTimeout(t); t = setTimeout(() => { F.q = e.target.value.trim(); draw(); }, 200); };
    el.querySelector('#or-range').onchange = (e) => { F.range = e.target.value; draw(); };
    el.querySelector('#or-wilaya').onchange = (e) => { F.wilaya = e.target.value; draw(); };
    el.querySelector('#or-source').onchange = (e) => { F.source = e.target.value; draw(); };
    el.querySelector('#or-export').onclick = () => downloadCSV(`nabda-orders-${new Date().toISOString().slice(0, 10)}.csv`, filtered().map(csvRow));
    el.querySelector('#or-bulk-clear').onclick = () => table?.clearSelection();
    el.querySelector('#or-bulk-apply').onclick = bulkStatus;
    el.querySelector('#or-bulk-print').onclick = () => printLabels(selectedOrders());
    el.querySelector('#or-bulk-csv').onclick = () => downloadCSV('nabda-orders-selected.csv', selectedOrders().map(csvRow));
    el.querySelector('#or-body').addEventListener('click', async (e) => {
      const q = e.target.closest('[data-quick]'); if (!q) return;
      e.stopPropagation();
      const o = S.orders.find((x) => x.id === q.dataset.quick);
      if (o) await setStatus(cartOf(o), q.dataset.to);
    });
    table = null;
    draw();
    return onData((type) => { if (type === 'orders' || type === 'blocked') draw(true); });
  },
};

function selectedOrders() { return table ? S.orders.filter((o) => table.selected.has(o.id)) : []; }

function filtered(ignoreStatus = false) {
  const qp = normPhone(F.q); const ql = F.q.toLowerCase().replace('#', '');
  const from = F.range === 'all' ? 0 : rangeStart(F.range).getTime();
  return S.orders.filter((o) => {
    if (!ignoreStatus && F.status !== 'all') {
      if (F.status === 'flagged') { if (!flags(o).length) return false; } else if ((o.status || 'pending') !== F.status) return false;
    }
    if (from && (toDate(o.createdAt)?.getTime() || 0) < from) return false;
    if (F.wilaya && o.wilaya !== F.wilaya) return false;
    if (F.source === 'website' && o.source !== 'website') return false;
    if (F.source === 'app' && o.source === 'website') return false;
    if (ql) {
      const hay = `${o.customerName || ''} ${o.productName || ''} ${o.id} ${o.cartId || ''} ${o.address || ''} ${o.commune || ''}`.toLowerCase();
      if (!hay.includes(ql) && !(qp.length >= 4 && normPhone(o.customerPhone).includes(qp))) return false;
    }
    return true;
  });
}

let dupSet = new Set();
function flags(o) {
  const f = []; const p = normPhone(o.customerPhone);
  if (p && S.blocked.has(p)) f.push(['red', '⛔ محظور']);
  if (p && dupSet.has(p)) f.push(['amber', '♻️ مكرّر']);
  if (o.notes) f.push(['teal', '📝']);
  return f;
}

function draw(keep = false) {
  const body = document.getElementById('or-body'); if (!body) return;
  dupSet = duplicatePhones(S.orders.filter((o) => (toDate(o.createdAt)?.getTime() || 0) > Date.now() - 7 * 86400000));
  // الولايات
  const ws = document.getElementById('or-wilaya');
  const wl = [...new Set(S.orders.map((o) => o.wilaya).filter(Boolean))].sort((a, b) => a.localeCompare(b, 'ar'));
  if (ws.options.length - 1 !== wl.length) ws.innerHTML = '<option value="">كل الولايات</option>' + wl.map((w) => `<option ${F.wilaya === w ? 'selected' : ''}>${esc(w)}</option>`).join('');
  // الشرائح
  const base = filtered(true);
  const cnt = (s) => base.filter((o) => (o.status || 'pending') === s).length;
  const flaggedN = base.filter((o) => flags(o).some((f) => f[0] !== 'teal')).length;
  document.getElementById('or-chips').innerHTML = [['all', 'الكل', base.length], ...STATUSES.map(([k, l]) => [k, l, cnt(k)]).filter((x) => x[2] || x[0] === 'pending'), ['flagged', '⚠️ مشبوهة', flaggedN]]
    .map(([k, l, n]) => `<button class="chip ${F.status === k ? 'active' : ''}" data-s="${k}">${l} <b>${num(n)}</b></button>`).join('');
  document.querySelectorAll('#or-chips .chip').forEach((c) => c.onclick = () => { F.status = c.dataset.s; draw(); });
  const list = filtered();
  document.getElementById('or-sub').textContent = `${num(groupCarts(list).length)} سلّة • ${num(list.length)} سطر • إجمالي ${da(list.reduce((s, o) => s + orderTotal(o), 0))}`;
  if (view === 'kanban') return kanban(body, list);
  if (!table || !keep) {
    body.innerHTML = '<div class="card" id="or-tbl"></div>';
    table = mountTable(document.getElementById('or-tbl'), {
      rows: list, selectable: true, pageSize: 30, sortKey: 'createdAt', sortDir: -1,
      empty: 'لا توجد طلبات مطابقة', emptyIcon: '📭',
      onRow: (o) => openOrder(o.id),
      onSelect: (sel) => { const b = document.getElementById('or-bulk'); b.classList.toggle('hidden', !sel.size); document.getElementById('or-bulk-n').textContent = `${sel.size} محدّد`; },
      columns: [
        { key: 'createdAt', label: 'الطلب', sort: (o) => toDate(o.createdAt)?.getTime() || 0, render: (o) => `<b class="num">${code(o.id)}</b>${o.cartSize > 1 ? ` <span class="tag" title="سلّة متعدّدة">🧺 ${o.cartSize}</span>` : ''}<div class="muted">${ago(o.createdAt)}</div>` },
        { key: 'customerName', label: 'الزبونة', render: (o) => `<div class="cell-strong">${esc(o.customerName || '—')}</div><div class="muted num" dir="ltr" style="text-align:right">${esc(o.customerPhone || '')}</div>` },
        { key: 'wilaya', label: 'الولاية', render: (o) => `${esc(o.wilaya || '—')}<div class="muted">${esc(o.commune || '')}${o.deliveryType === 'office' ? ' • مكتب' : ''}</div>` },
        { key: 'productName', label: 'المنتج', render: (o) => `<div style="max-width:240px">${esc(o.productName || o.productId || '')}</div><div class="muted">×${num(o.quantity || 1)}${o.variant ? ' • ' + esc(o.variant) : ''}</div>` },
        { key: 'total', label: 'المبلغ', sort: orderTotal, render: (o) => `<b class="num">${da(orderTotal(o))}</b>` },
        { key: 'status', label: 'الحالة', render: (o) => statusPill(o.status) },
        { key: 'flags', label: '', sort: false, render: (o) => flags(o).map(([c, t]) => `<span class="tag ${c}">${t}</span>`).join(' ') + (o.source === 'website' ? '' : ' <span class="tag">📱</span>') },
        { key: 'act', label: '', sort: false, render: (o) => `<span style="display:flex;gap:4px">${(o.status || 'pending') === 'pending' || o.status === 'no_answer' ? `<button class="btn btn-xs btn-teal" data-quick="${esc(o.id)}" data-to="confirmed" title="تأكيد">✓</button><button class="btn btn-xs" data-quick="${esc(o.id)}" data-to="no_answer" title="لم يرد">📵</button>` : o.status === 'confirmed' ? `<button class="btn btn-xs" data-quick="${esc(o.id)}" data-to="shipped">🚚 شُحن</button>` : o.status === 'shipped' ? `<button class="btn btn-xs btn-teal" data-quick="${esc(o.id)}" data-to="delivered">🎉 سُلّم</button>` : ''}<a class="btn btn-xs" href="tel:${esc(normPhone(o.customerPhone))}" title="اتصال">📞</a></span>` },
      ],
    });
  } else table.setRows(list, true);
}

function kanban(body, list) {
  table = null;
  document.getElementById('or-bulk').classList.add('hidden');
  const carts = groupCarts(list);
  body.innerHTML = `<div class="kanban">${LANES.map((s) => {
    const cs = carts.filter((c) => (c[0].status || 'pending') === s);
    return `<div class="lane" data-lane="${s}"><div class="lane-h"><span>${statusLabel(s)}</span><span class="tag">${num(cs.length)}</span></div>
      <div class="lane-b">${cs.slice(0, 80).map((c) => { const o = c[0]; const fl = flags(o);
        return `<div class="kcard" draggable="true" data-id="${esc(o.id)}">
          <div class="kcard-top"><span class="num">${code(o.id)}</span><span>${ago(o.createdAt)}</span></div>
          <b>${esc(o.customerName || '—')}</b>
          <div style="font-size:12.5px;color:var(--ink-2)">${esc(o.productName || '')}${c.length > 1 ? ` <span class="tag">+${c.length - 1}</span>` : ''}</div>
          <div style="display:flex;justify-content:space-between;align-items:center"><span class="muted" style="font-size:12px;color:var(--ink-3)">📍 ${esc(o.wilaya || '')}</span><b class="num" style="font-size:13px">${da(c.reduce((t, x) => t + orderTotal(x), 0))}</b></div>
          ${fl.length ? `<div>${fl.map(([cl, t]) => `<span class="tag ${cl}">${t}</span>`).join(' ')}</div>` : ''}
        </div>`; }).join('') || '<div class="empty" style="padding:20px;font-size:12px">—</div>'}
        ${cs.length > 80 ? `<div class="muted" style="text-align:center;font-size:12px">+${cs.length - 80} أخرى (استعملي الجدول)</div>` : ''}</div></div>`;
  }).join('')}</div>`;
  let dragId = null;
  body.querySelectorAll('.kcard').forEach((k) => {
    k.addEventListener('dragstart', (e) => { dragId = k.dataset.id; k.classList.add('dragging'); e.dataTransfer.effectAllowed = 'move'; });
    k.addEventListener('dragend', () => k.classList.remove('dragging'));
    k.addEventListener('click', () => openOrder(k.dataset.id));
  });
  body.querySelectorAll('.lane').forEach((lane) => {
    lane.addEventListener('dragover', (e) => { e.preventDefault(); lane.classList.add('drop'); });
    lane.addEventListener('dragleave', () => lane.classList.remove('drop'));
    lane.addEventListener('drop', async (e) => {
      e.preventDefault(); lane.classList.remove('drop');
      const o = S.orders.find((x) => x.id === dragId); if (!o || (o.status || 'pending') === lane.dataset.lane) return;
      await setStatus(cartOf(o), lane.dataset.lane);
    });
  });
}

const cartOf = (o) => (o.cartId ? S.orders.filter((x) => x.cartId === o.cartId) : [o]);

/** تغيير الحالة مع سجلّ زمني (مسموح للموظفة حسب القواعد: status/history/notes/updatedAt/assignedTo) */
export async function setStatus(orders, status, note = '') {
  if (status === 'cancelled' || status === 'returned') {
    if (!(await confirmBox(`تحويل ${orders.length > 1 ? orders.length + ' أسطر' : 'الطلب'} إلى «${statusLabel(status)}»؟`, { danger: true, ok: 'نعم' }))) return false;
  }
  try {
    const batch = db.batch();
    // المخزون لطلبات الموقع: يُخصم عند أوّل تأكيد ويُعاد عند الإلغاء/الإرجاع
    // (طلبات التطبيق تخصم مخزونها بنفسها عند الطلب — لا نلمسها)
    const TAKEN = ['confirmed', 'shipped', 'delivered'];
    const prods = await loadProducts().catch(() => []);
    // مخزون كل سوق منفصل: الجزائر = stock، السعودية = markets.SA.stock
    const delta = new Map();
    orders.forEach((o) => {
      if (o.source !== 'website' || !o.productId) return;
      const was = TAKEN.includes(o.status); const will = TAKEN.includes(status);
      if (was === will) return;
      const q = (Number(o.quantity) || 1) * (will ? -1 : 1);
      const k = o.productId + '|' + marketOf(o);
      delta.set(k, (delta.get(k) || 0) + q);
    });
    delta.forEach((d, k) => {
      const [pid, mk] = k.split('|');
      const p = prods.find((x) => x.id === pid); if (!p || !d) return;
      const upd = { soldCount: FV().increment(-d), updatedAt: FV().serverTimestamp() };
      if (mk === 'DZ' && typeof p.stock === 'number') { upd.stock = FV().increment(d); p.stock = Math.max(0, p.stock + d); }
      if (mk !== 'DZ' && typeof p.markets?.[mk]?.stock === 'number') { upd[`markets.${mk}.stock`] = FV().increment(d); p.markets[mk].stock = Math.max(0, p.markets[mk].stock + d); }
      batch.update(db.collection('products').doc(pid), upd);
    });
    orders.forEach((o) => batch.update(db.collection('orders').doc(o.id), {
      status, updatedAt: FV().serverTimestamp(),
      history: FV().arrayUnion({ status, by: S.staff?.name || S.user?.email || '', uid: S.user?.uid || '', at: new Date().toISOString(), note: note || '' }),
    }));
    await batch.commit();
    toast(`${code(orders[0].cartId || orders[0].id)} ← ${statusLabel(status)}`, 'success');
    log('order.status', orders.map((o) => o.id).join(','), { status });
    return true;
  } catch (e) { console.error(e); toast('تعذّر التحديث: ' + (e.code || e.message), 'error'); return false; }
}

async function bulkStatus() {
  const s = document.getElementById('or-bulk-status').value;
  if (!s) return toast('اختاري الحالة أولاً', 'error');
  const sel = selectedOrders(); if (!sel.length) return;
  if (await setStatus(sel, s)) table?.clearSelection();
}

/* ─────────── درج تفاصيل الطلب ─────────── */
export function openOrder(id) {
  const o = S.orders.find((x) => x.id === id);
  if (!o) return toast('الطلب غير محمّل', 'error');
  const cart = cartOf(o);
  const total = cart.reduce((s, x) => s + orderTotal(x), 0);
  const phone = normPhone(o.customerPhone);
  const history = [...cart.flatMap((x) => x.history || [])].sort((a, b) => String(a.at).localeCompare(String(b.at)));
  const prev = groupCarts(S.orders.filter((x) => normPhone(x.customerPhone) === phone && (x.cartId || x.id) !== (o.cartId || o.id)));
  const delivered = prev.filter((c) => c[0].status === 'delivered').length;
  const returned = prev.filter((c) => c[0].status === 'returned').length;
  const fl = flags(o);
  const editable = can('orders.edit');
  openDrawer({
    title: `طلب ${code(o.cartId && cart.length > 1 ? o.cartId : o.id)}`,
    body: `
      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:14px">${statusPill(o.status)}<span class="muted" style="color:var(--ink-3);font-size:12.5px">${fmtDate(o.createdAt)} • ${o.source === 'website' ? '🌐 الموقع' : '📱 التطبيق'}</span></div>
      ${fl.filter((f) => f[0] !== 'teal').map(([c, t]) => `<div class="alert ${c === 'red' ? 'red' : 'amber'}" style="margin-bottom:10px">${t === '⛔ محظور' ? '⛔ هذا الرقم في القائمة السوداء (طلبات وهمية سابقة).' : '♻️ نفس الرقم أرسل أكثر من طلب خلال 24 ساعة — تحقّقي قبل الشحن.'}</div>`).join('')}
      <div class="card" style="margin-bottom:14px"><div class="card-b">
        <div style="display:flex;justify-content:space-between;align-items:flex-start;gap:10px">
          <div><div style="font-size:17px;font-weight:900">${esc(o.customerName || '—')}</div><div class="num" dir="ltr" style="text-align:right;font-weight:800;color:var(--ink-2)">${esc(o.customerPhone || '')}</div></div>
          <div style="display:flex;gap:6px"><a class="btn btn-sm btn-teal" href="tel:${esc(phone)}">📞 اتصال</a><button class="btn btn-sm" id="od-copy">📋</button></div>
        </div>
        <dl class="kv" style="margin-top:12px">
          <dt>الولاية</dt><dd>${esc(o.wilaya || '—')}</dd>
          <dt>البلدية</dt><dd>${esc(o.commune || '—')}</dd>
          <dt>العنوان</dt><dd>${esc(o.address || '—')}</dd>
          <dt>التوصيل</dt><dd>${o.deliveryType === 'office' ? '🏢 مكتب التوصيل' : '🏠 للمنزل'}</dd>
          <dt>سجلّها</dt><dd>${prev.length ? `${prev.length} طلب سابق • ✅ ${delivered} مُسلَّم • ↩️ ${returned} مُرتجع` : 'زبونة جديدة'}</dd>
        </dl>
      </div></div>
      <div class="card" style="margin-bottom:14px"><div class="card-h"><h3>🧺 المنتجات</h3><span class="tag">${cart.length}</span></div><div class="card-b">
        ${cart.map((x) => `<div class="list-row">${x.productImage ? `<img src="${esc(x.productImage)}" style="width:44px;height:44px;border-radius:10px;object-fit:cover" alt="">` : ''}
          <div style="flex:1"><div class="cell-strong">${esc(x.productName || x.productId)}</div><div class="muted" style="font-size:12px;color:var(--ink-3)">${esc(x.variant || '')} ${x.variant ? '•' : ''} ${da(x.unitPrice)} × ${num(x.quantity || 1)}</div></div>
          <b class="num">${da((Number(x.unitPrice) || 0) * (Number(x.quantity) || 1))}</b></div>`).join('')}
        <div class="list-row"><span style="flex:1;color:var(--ink-3)">التوصيل</span><b class="num">${da(cart.reduce((s, x) => s + (Number(x.shippingFee) || 0), 0))}</b></div>
        <div class="list-row" style="font-size:16px"><b style="flex:1">الإجمالي عند الاستلام</b><b class="num" style="color:var(--pink)">${da(total)}</b></div>
      </div></div>
      <div class="card" style="margin-bottom:14px"><div class="card-h"><h3>🔄 تغيير الحالة</h3></div><div class="card-b"><div class="chips">
        ${STATUSES.filter((s) => s[0] !== 'waitlist').map(([k, l, ic]) => `<button class="chip ${(o.status || 'pending') === k ? 'active' : ''}" data-set="${k}">${ic} ${l}</button>`).join('')}
      </div></div></div>
      <div class="card" style="margin-bottom:14px"><div class="card-h"><h3>💬 رسائل واتساب جاهزة</h3></div><div class="card-b" style="display:flex;gap:6px;flex-wrap:wrap">
        <button class="btn btn-sm" data-wa="confirm">✅ طلب التأكيد</button><button class="btn btn-sm" data-wa="shipped">🚚 تم الشحن</button><button class="btn btn-sm" data-wa="noanswer">📵 لم نتمكّن من الاتصال</button>
      </div></div>
      <div class="card" style="margin-bottom:14px"><div class="card-h"><h3>📝 ملاحظات داخلية</h3><button class="btn btn-sm" id="od-note">+ ملاحظة</button></div><div class="card-b" style="white-space:pre-line;font-size:13.5px">${esc(o.notes || 'لا توجد ملاحظات.')}</div></div>
      <div class="card"><div class="card-h"><h3>🕓 الخطّ الزمني</h3></div><div class="card-b"><div class="timeline">
        <div class="tl-item"><span class="tl-dot" style="background:var(--amber);box-shadow:0 0 0 2px var(--amber)"></span><div><b>استُلم الطلب</b><div style="font-size:12px;color:var(--ink-3)">${fmtDate(o.createdAt)}</div></div></div>
        ${history.map((h) => `<div class="tl-item"><span class="tl-dot"></span><div><b>${esc(statusLabel(h.status))}</b>${h.note ? ` — ${esc(h.note)}` : ''}<div style="font-size:12px;color:var(--ink-3)">${esc(h.by || '')} • ${fmtDate(h.at)}</div></div></div>`).join('')}
      </div></div></div>`,
    foot: `<button class="btn" id="od-print">🖨️ ملصق الشحن</button><button class="btn" id="od-invoice">🧾 فاتورة</button>
      ${editable ? '<button class="btn" id="od-edit">✏️ تعديل البيانات</button>' : ''}
      <button class="btn ${S.blocked.has(phone) ? '' : 'btn-danger'}" id="od-block" style="margin-right:auto">${S.blocked.has(phone) ? '✅ رفع الحظر' : '⛔ حظر الرقم'}</button>`,
  });
  const d = document.getElementById('drawer');
  d.querySelectorAll('[data-set]').forEach((b) => b.onclick = async () => { if (await setStatus(cart, b.dataset.set)) setTimeout(() => openOrder(id), 300); });
  d.querySelectorAll('[data-wa]').forEach((b) => b.onclick = () => {
    const items = cart.map((x) => `• ${x.productName} ×${x.quantity || 1}`).join('\n');
    const msg = WA_TEMPLATES[b.dataset.wa](o, { items, total: da(total) });
    const intl = o.phoneIntl || (phone.startsWith('0') ? (marketOf(o) === 'SA' ? '966' : '213') + phone.slice(1) : phone);
    window.open(`https://wa.me/${intl}?text=${encodeURIComponent(msg)}`, '_blank', 'noopener');
  });
  document.getElementById('od-copy').onclick = () => navigator.clipboard.writeText(`${o.customerName}\n${o.customerPhone}\n${o.wilaya} - ${o.commune || ''}\n${o.address || ''}\n${cart.map((x) => `${x.productName} ×${x.quantity || 1}`).join('\n')}\nالمبلغ: ${da(total)}`).then(() => toast('نُسخت بيانات الشحن', 'success'));
  document.getElementById('od-note').onclick = async () => {
    const v = await promptBox('الملاحظة (تُضاف للسجلّ ولا تراها الزبونة)', { title: 'ملاحظة داخلية', textarea: true });
    if (!v || !v.trim()) return;
    const line = `${new Date().toLocaleString('ar-DZ')} — ${S.staff?.name || ''}: ${v.trim()}`;
    try {
      await db.collection('orders').doc(o.id).update({ notes: (o.notes ? o.notes + '\n' : '') + line, updatedAt: FV().serverTimestamp() });
      toast('أُضيفت الملاحظة', 'success'); setTimeout(() => openOrder(id), 300);
    } catch (e) { toast('تعذّر الحفظ: ' + (e.code || ''), 'error'); }
  };
  document.getElementById('od-print').onclick = () => printLabels(cart);
  document.getElementById('od-invoice').onclick = () => printInvoice(cart);
  document.getElementById('od-block').onclick = () => toggleBlock(phone, o.customerName);
  document.getElementById('od-edit')?.addEventListener('click', () => editOrder(cart));
}

async function editOrder(cart) {
  const o = cart[0];
  const { openModal, closeModal } = await import('./core.js');
  openModal({ title: 'تعديل بيانات الطلب', body: `<div class="form">
      <div class="f-row"><div class="field"><label>الاسم</label><input class="input" id="eo-name" value="${esc(o.customerName || '')}"></div><div class="field"><label>الهاتف</label><input class="input" id="eo-phone" dir="ltr" value="${esc(o.customerPhone || '')}"></div></div>
      <div class="f-row"><div class="field"><label>الولاية</label><input class="input" id="eo-w" value="${esc(o.wilaya || '')}"></div><div class="field"><label>البلدية</label><input class="input" id="eo-c" value="${esc(o.commune || '')}"></div></div>
      <div class="field"><label>العنوان</label><input class="input" id="eo-a" value="${esc(o.address || '')}"></div>
      <div class="f-row"><div class="field"><label>رسوم التوصيل (السطر الأول)</label><input class="input" type="number" id="eo-ship" value="${Number(o.shippingFee) || 0}"></div><div class="field"><label>الكمية (${esc(o.productName || '')})</label><input class="input" type="number" min="1" id="eo-q" value="${Number(o.quantity) || 1}"></div></div>
    </div>`, foot: '<button class="btn btn-primary" id="eo-save">حفظ</button><button class="btn" data-close-modal>إلغاء</button>' });
  document.getElementById('eo-save').onclick = async () => {
    const g = (i) => document.getElementById(i).value.trim();
    const q = Math.max(1, parseInt(g('eo-q'), 10) || 1); const ship = Number(g('eo-ship')) || 0;
    try {
      const batch = db.batch();
      cart.forEach((x, i) => {
        const upd = { customerName: g('eo-name'), customerPhone: normPhone(g('eo-phone')), wilaya: g('eo-w'), commune: g('eo-c'), address: g('eo-a'), updatedAt: FV().serverTimestamp() };
        if (i === 0) { upd.quantity = q; upd.shippingFee = ship; upd.lineTotal = (Number(x.unitPrice) || 0) * q + ship; }
        batch.update(db.collection('orders').doc(x.id), upd);
      });
      await batch.commit(); log('order.edit', o.id);
      closeModal(); toast('حُفظت التعديلات', 'success'); setTimeout(() => openOrder(o.id), 300);
    } catch (e) { toast('تعذّر الحفظ (صلاحيات؟): ' + (e.code || ''), 'error'); }
  };
}

export async function toggleBlock(phone, name = '') {
  if (!phone) return;
  const blocked = S.blocked.has(phone);
  if (!blocked && !(await confirmBox(`حظر الرقم ${phone}؟ ستظهر طلباته القادمة بعلامة «محظور».`, { danger: true, ok: 'حظر' }))) return;
  try {
    const ref = db.collection('blocked_phones').doc(phone);
    if (blocked) await ref.delete(); else await ref.set({ name: name || '', by: S.staff?.name || '', at: FV().serverTimestamp() });
    log(blocked ? 'phone.unblock' : 'phone.block', phone);
    toast(blocked ? 'رُفع الحظر' : 'حُظر الرقم', 'success');
    closeDrawer();
  } catch (e) { toast('تعذّر: ' + (e.code || ''), 'error'); }
}

/* ─────────── طباعة ─────────── */
async function printHtml(html) {
  const area = document.getElementById('print-area');
  area.innerHTML = `<style>
    #print-area{display:block!important;font-family:Cairo,sans-serif;direction:rtl;color:#000}
    .lbl{width:105mm;min-height:148mm;padding:7mm;box-sizing:border-box;border:1px dashed #999;page-break-after:always;display:flex;flex-direction:column;gap:3mm}
    .lbl h2{font-size:15pt;margin:0}.lbl .big{font-size:17pt;font-weight:900}.lbl .row{display:flex;justify-content:space-between;font-size:11pt}
    .lbl .box{border:2px solid #000;border-radius:3mm;padding:3mm}.inv{padding:12mm;font-size:11pt}.inv table{width:100%;border-collapse:collapse}.inv td,.inv th{border-bottom:1px solid #ccc;padding:2mm;text-align:right}
    @page{size:auto;margin:5mm}</style>${html}`;
  await new Promise((r) => setTimeout(r, 120));
  window.print();
  setTimeout(() => { area.innerHTML = ''; }, 800);
}
async function printLabels(orders) {
  if (!orders.length) return;
  const st = await getStoreSettingsCached();
  const carts = groupCarts(orders.flatMap((o) => cartOf(o)).filter((o, i, a) => a.findIndex((x) => x.id === o.id) === i));
  printHtml(carts.map((c) => { const o = c[0]; const total = c.reduce((s, x) => s + orderTotal(x), 0);
    return `<div class="lbl"><div class="row"><h2>💗 ${esc(st.storeName || 'متجر نبضة')}</h2><b>${code(o.cartId || o.id)}</b></div>
      <div class="box"><div style="font-size:10pt">المرسَل إليها</div><div class="big">${esc(o.customerName || '')}</div><div class="big" dir="ltr" style="text-align:right">${esc(o.customerPhone || '')}</div>
      <div style="font-size:13pt;font-weight:800;margin-top:2mm">${esc(o.wilaya || '')} — ${esc(o.commune || '')}</div><div>${esc(o.address || '')}</div><div>${o.deliveryType === 'office' ? '🏢 استلام من المكتب' : '🏠 توصيل للمنزل'}</div></div>
      <div style="font-size:11pt">${c.map((x) => `• ${esc(x.productName)} ×${num(x.quantity || 1)} ${x.variant ? '(' + esc(x.variant) + ')' : ''}`).join('<br>')}</div>
      <div class="box" style="text-align:center"><div style="font-size:10pt">المبلغ عند الاستلام</div><div class="big">${da(total)}</div></div>
      <div class="row" style="font-size:9pt;margin-top:auto"><span>${fmtDate(o.createdAt, false)}</span><span>${esc(st.whatsapp ? 'واتساب: ' + st.whatsapp : 'nabda.online')}</span></div></div>`; }).join(''));
}
async function printInvoice(cart) {
  const st = await getStoreSettingsCached(); const o = cart[0];
  const total = cart.reduce((s, x) => s + orderTotal(x), 0);
  printHtml(`<div class="inv"><h1 style="margin:0">فاتورة — ${esc(st.storeName || 'متجر نبضة')}</h1><p>رقم: ${code(o.cartId || o.id)} • التاريخ: ${fmtDate(o.createdAt, false)}</p>
    <p><b>${esc(o.customerName || '')}</b> — <span dir="ltr">${esc(o.customerPhone || '')}</span><br>${esc(o.wilaya || '')} ${esc(o.commune || '')} ${esc(o.address || '')}</p>
    <table><tr><th>المنتج</th><th>السعر</th><th>الكمية</th><th>المجموع</th></tr>${cart.map((x) => `<tr><td>${esc(x.productName)} ${esc(x.variant || '')}</td><td>${da(x.unitPrice)}</td><td>${num(x.quantity || 1)}</td><td>${da((Number(x.unitPrice) || 0) * (Number(x.quantity) || 1))}</td></tr>`).join('')}
    <tr><td colspan="3">التوصيل</td><td>${da(cart.reduce((s, x) => s + (Number(x.shippingFee) || 0), 0))}</td></tr><tr><th colspan="3">الإجمالي (الدفع عند الاستلام)</th><th>${da(total)}</th></tr></table>
    <p style="margin-top:10mm;font-size:10pt">شكراً لثقتكِ بنبضة 💗 — الإرجاع خلال 7 أيام إذا كان المنتج بحالته الأصلية.</p></div>`);
}

function csvRow(o) {
  return { رقم: code(o.id), السلة: o.cartId || '', التاريخ: fmtDate(o.createdAt), الحالة: statusLabel(o.status || 'pending'), الاسم: o.customerName || '', الهاتف: o.customerPhone || '',
    الولاية: o.wilaya || '', البلدية: o.commune || '', العنوان: o.address || '', التوصيل: o.deliveryType === 'office' ? 'مكتب' : 'منزل', المنتج: o.productName || '', الخيار: o.variant || '',
    الكمية: o.quantity || 1, السعر: o.unitPrice || 0, الشحن: o.shippingFee || 0, المبلغ: orderTotal(o), المصدر: o.source === 'website' ? 'الموقع' : 'التطبيق', ملاحظات: (o.notes || '').replace(/\n/g, ' | ') };
}
