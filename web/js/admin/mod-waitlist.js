// قائمة الانتظار: طلبات «أعلميني عند التوفّر» مجمّعة حسب المنتج
import { S, db, esc, num, ago, toast, confirmBox, downloadCSV, log, FV, loadProducts, pimg } from './core.js';

let unsub = null;
export default {
  render(el) {
    el.innerHTML = `<div class="ad-page-head"><div><h1>قائمة الانتظار</h1><p>زبونات طلبن إشعاراً عند توفّر منتج نافد</p></div>
      <div class="ad-actions"><button class="btn" id="wl-csv">⬇️ تصدير</button></div></div><div id="wl-body"><div class="card card-b"><div class="skel" style="height:200px"></div></div></div>`;
    let rows = [];
    loadProducts().catch(() => {});
    unsub = db.collection('waitlist').orderBy('createdAt', 'desc').limit(1000).onSnapshot((snap) => {
      rows = snap.docs.map((d) => ({ id: d.id, ...d.data() })); draw(rows);
    }, (e) => { document.getElementById('wl-body').innerHTML = `<div class="alert red">تعذّر التحميل: ${esc(e.code || e.message)}</div>`; });
    el.querySelector('#wl-csv').onclick = () => downloadCSV('nabda-waitlist.csv', rows.map((r) => ({ المنتج: r.productName, الهاتف: r.phone, الحالة: r.status, التاريخ: ago(r.createdAt) })));
    return () => unsub && unsub();
  },
};

function draw(rows) {
  const groups = new Map();
  rows.forEach((r) => { const k = r.productId || r.productName; if (!groups.has(k)) groups.set(k, []); groups.get(k).push(r); });
  const body = document.getElementById('wl-body'); if (!body) return;
  if (!groups.size) { body.innerHTML = '<div class="card"><div class="empty"><div class="em">🔔</div>لا توجد طلبات انتظار</div></div>'; return; }
  body.innerHTML = `<div class="grid g-2">${[...groups].sort((a, b) => b[1].filter((x) => x.status !== 'notified').length - a[1].filter((x) => x.status !== 'notified').length).map(([pid, list]) => {
    const p = S.products.find((x) => x.id === pid);
    const waiting = list.filter((x) => x.status !== 'notified');
    return `<div class="card"><div class="card-h"><div style="display:flex;gap:10px;align-items:center">${p ? `<img src="${esc(pimg(p))}" style="width:40px;height:40px;border-radius:10px;object-fit:cover" alt="">` : ''}<div><h3>${esc(list[0].productName || pid)}</h3><div style="font-size:12px;color:var(--ink-3)">${p ? (typeof p.stock === 'number' ? (p.stock > 0 ? `<span class="tag teal">متوفّر الآن (${p.stock})</span>` : '<span class="tag red">ما زال نافداً</span>') : '') : ''}</div></div></div>
      <span class="tag pink">${num(waiting.length)} بانتظار</span></div>
      <div class="card-b">${list.slice(0, 12).map((r) => `<div class="list-row"><span class="num" dir="ltr" style="font-weight:800">${esc(r.phone)}</span><span style="flex:1;font-size:12px;color:var(--ink-3)">${ago(r.createdAt)}</span>${r.status === 'notified' ? '<span class="tag teal">✓ أُعلمت</span>' : `<a class="btn btn-xs" target="_blank" rel="noopener" href="https://wa.me/${esc(String(r.phone).replace(/^0/, '213'))}?text=${encodeURIComponent(`مرحباً 🌸 المنتج «${list[0].productName}» متوفّر الآن في متجر نبضة: https://nabda.online/product/${p ? encodeURIComponent(p.slug || p.id) : ''}`)}">💬</a>`}</div>`).join('')}
        ${list.length > 12 ? `<div style="font-size:12px;color:var(--ink-3);margin-top:6px">+${list.length - 12} أخرى</div>` : ''}
        ${waiting.length ? `<button class="btn btn-sm btn-teal" style="margin-top:10px" data-done="${esc(pid)}">✓ تعليم الكل كـ«أُعلمت»</button>` : ''}</div></div>`;
  }).join('')}</div>`;
  body.querySelectorAll('[data-done]').forEach((b) => b.onclick = async () => {
    const list = groups.get(b.dataset.done).filter((x) => x.status !== 'notified');
    if (!(await confirmBox(`تعليم ${list.length} طلب كـ«تمّ الإعلام»؟`))) return;
    try { const batch = db.batch(); list.forEach((r) => batch.update(db.collection('waitlist').doc(r.id), { status: 'notified' })); await batch.commit(); log('waitlist.notified', b.dataset.done); toast('تم', 'success'); }
    catch (e) { toast('تعذّر: ' + (e.code || ''), 'error'); }
  });
}
