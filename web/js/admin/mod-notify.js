// الإشعارات الجماعية — نفس _NotificationsScreen: app_config/notifications (مفاتيح التشغيل) + notifications (type: broadcast)
// الإرسال الفعلي تقوم به دالة sendBroadcast (Cloud Functions) إلى موضوع FCM «nabda_all» وتكتب status: sent|failed|rejected.
import { S, db, esc, ago, toast, confirmBox, openModal, closeModal, log, FV, loadProducts, pimg, da } from './core.js';
import { isHiddenProduct } from '../shop-rules.js';

const AUTO = [['water', '💧', 'تذكير شرب الماء'], ['tips', '💡', 'نصائح يومية'], ['pregnancy', '🤰', 'متابعة الحمل والدورة'], ['products', '🛍️', 'عروض ومنتجات المتجر (3 يومياً)'], ['articles', '📖', 'مقال اليوم']];
let unsubs = []; let link = null;

export default {
  render(el) {
    link = null;
    el.innerHTML = `<div class="ad-page-head"><div><h1>الإشعارات الجماعية</h1><p>إشعار فوري لكل مستخدمات التطبيق + التحكم في الإشعارات التلقائية</p></div></div>
      <div class="grid g-21">
        <div class="card"><div class="card-h"><h3>📣 إشعار جديد</h3></div><div class="card-b form">
          <div class="field"><label>العنوان *</label><input class="input" id="nt-title" maxlength="100" placeholder="🛍️ عرض خاص لأمهات نبضة"></div>
          <div class="field"><label>النص *</label><textarea class="textarea" id="nt-body" rows="3" maxlength="240" placeholder="اطلبيه الآن بالدفع عند الاستلام 💗"></textarea><span class="hint" id="nt-cnt">0 / 240</span></div>
          <div class="f-row"><button class="btn" id="nt-prod">🛍️ إرفاق منتج</button><button class="btn" id="nt-art">📖 إرفاق مقال</button></div>
          <div id="nt-link"></div>
          <div class="field"><label>أو رابط صورة مباشر (https://…)</label><input class="input" id="nt-img" dir="ltr"></div>
          <div class="alert amber">⚠️ لا تُرسلي نصائح علاجية أو أدوية، ولا تروّجي للمكمّلات أو الأجهزة الطبية (سياسة Google Play).</div>
          <button class="btn btn-primary" id="nt-send">🚀 إرسال لكل المستخدمات</button>
        </div></div>
        <div style="display:grid;gap:14px;align-self:start">
          <div class="card"><div class="card-h"><h3>📱 المعاينة</h3></div><div class="card-b"><div id="nt-prev"></div></div></div>
          <div class="card"><div class="card-h"><h3>⏰ الإشعارات التلقائية</h3></div><div class="card-b" id="nt-auto"><div class="skel" style="height:120px"></div></div></div>
        </div>
      </div>
      <div class="card" style="margin-top:14px"><div class="card-h"><h3>🕘 الإشعارات السابقة</h3></div><div class="card-b" id="nt-hist"><div class="skel" style="height:120px"></div></div></div>`;
    const $ = (i) => document.getElementById(i);
    const preview = () => {
      const img = /^https:\/\//.test($('nt-img').value.trim()) ? $('nt-img').value.trim() : (link?.image || '');
      $('nt-cnt').textContent = `${$('nt-body').value.length} / 240`;
      $('nt-prev').innerHTML = `<div style="background:var(--surface-2);border-radius:16px;padding:12px;display:grid;gap:8px">
        <div style="display:flex;gap:8px;align-items:center;font-size:11.5px;color:var(--ink-3)"><img src="/favicon.png" alt="" style="width:18px;height:18px;border-radius:5px"> نبضة · الآن</div>
        <b style="font-size:14px">${esc($('nt-title').value || 'عنوان الإشعار')}</b><div style="font-size:13px;color:var(--ink-2);line-height:1.6">${esc($('nt-body').value || 'نص الإشعار يظهر هنا…')}</div>
        ${img ? `<img src="${esc(img)}" alt="" style="width:100%;max-height:170px;object-fit:cover;border-radius:12px" onerror="this.remove()">` : ''}</div>`;
      $('nt-link').innerHTML = link ? `<div class="alert teal" style="display:flex;align-items:center;gap:8px">${link.type === 'product' ? '🛍️' : '📖'} مُرفق: <b style="flex:1;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${esc(link.label)}</b><button class="btn btn-xs" id="nt-unlink">✕</button></div>` : '';
      $('nt-unlink')?.addEventListener('click', () => { link = null; preview(); });
    };
    ['nt-title', 'nt-body', 'nt-img'].forEach((i) => $(i).addEventListener('input', preview));
    preview();

    $('nt-prod').onclick = async () => {
      const list = (await loadProducts()).filter((p) => p.active !== false && !isHiddenProduct(p)).slice(0, 80);
      pick('اختاري منتجاً', list.map((p) => ({ id: p.id, label: p.name || '', sub: da(p.price), image: pimg(p) })), (it) => {
        link = { type: 'product', ...it };
        if (!$('nt-title').value.trim()) $('nt-title').value = '🛍️ ' + it.label;
        if (!$('nt-body').value.trim()) $('nt-body').value = `${it.sub} — اطلبيه الآن من متجر نبضة بالدفع عند الاستلام 💗`;
        preview();
      });
    };
    $('nt-art').onclick = async () => {
      try {
        const s = await db.collection('articles').orderBy('createdAt', 'desc').limit(60).get();
        pick('اختاري مقالاً', s.docs.map((d) => ({ id: d.id, label: d.data().title || '', sub: d.data().category || '', image: d.data().imageUrl || '' })), (it) => {
          link = { type: 'article', ...it };
          if (!$('nt-title').value.trim()) $('nt-title').value = '📖 مقال جديد في نبضة';
          if (!$('nt-body').value.trim()) $('nt-body').value = it.label;
          preview();
        });
      } catch (e) { toast('تعذّر تحميل المقالات: ' + (e.code || ''), 'error'); }
    };
    $('nt-send').onclick = async () => {
      const title = $('nt-title').value.trim(); const body = $('nt-body').value.trim(); const img = $('nt-img').value.trim();
      if (!title || !body) return toast('أدخلي العنوان والنص', 'error');
      if (img && !/^https:\/\//.test(img)) return toast('رابط الصورة يجب أن يبدأ بـ https://', 'error');
      if (!(await confirmBox(`سيصل هذا الإشعار إلى كل مستخدمات التطبيق فوراً:\n«${title}»`, { ok: 'إرسال الآن' }))) return;
      try {
        const data = { title, body, type: 'broadcast', createdAt: FV().serverTimestamp(), sentBy: S.user.uid };
        if (img) data.imageUrl = img;
        if (link) data.link = { type: link.type, id: link.id };
        await db.collection('notifications').add(data);
        log('notify.broadcast', title); toast('أُرسل الطلب ✓ — تابعي حالته في القائمة', 'success');
        $('nt-title').value = ''; $('nt-body').value = ''; $('nt-img').value = ''; link = null; preview();
      } catch (e) { toast('تعذّر: ' + (e.code || e.message), 'error'); }
    };

    unsubs.push(db.collection('app_config').doc('notifications').onSnapshot((d) => {
      const data = d.exists ? d.data() : {};
      const box = $('nt-auto'); if (!box) return;
      box.innerHTML = AUTO.map(([k, ic, l]) => `<div class="list-row"><span style="font-size:20px">${ic}</span><span style="flex:1;font-weight:800">${l}</span><label class="switch"><input type="checkbox" data-k="${k}" ${data[k] !== false ? 'checked' : ''}><span></span></label></div>`).join('')
        + '<span class="hint">إيقاف مفتاح يوقف هذا النوع لكل المستخدمات.</span>';
      box.querySelectorAll('[data-k]').forEach((i) => i.onchange = async () => { try { await db.collection('app_config').doc('notifications').set({ [i.dataset.k]: i.checked }, { merge: true }); log('notify.auto', i.dataset.k, { on: i.checked }); } catch (e) { toast('تعذّر (مالك/مشرفة): ' + (e.code || ''), 'error'); i.checked = !i.checked; } });
    }, () => {}));
    unsubs.push(db.collection('notifications').orderBy('createdAt', 'desc').limit(30).onSnapshot((s) => {
      const box = $('nt-hist'); if (!box) return;
      const ST = { sent: ['✓ أُرسل', 'teal'], failed: ['✗ فشل', 'red'], rejected: ['✗ مرفوض', 'red'] };
      const stale = s.docs.some((d) => !d.data().status && (Date.now() - (d.data().createdAt?.toMillis?.() || Date.now())) > 5 * 60000);
      box.innerHTML = (stale ? '<div class="alert amber" style="margin-bottom:10px">⏳ إشعارات بقيت «قيد الإرسال» أكثر من 5 دقائق: دالة <b>sendBroadcast</b> غير منشورة (Cloud Functions تتطلّب خطة Blaze في Firebase).</div>' : '')
        + (s.empty ? '<div class="empty"><div class="em">🔔</div>لا توجد إشعارات سابقة</div>' : s.docs.map((d) => { const n = d.data(); const [l, c] = ST[n.status] || ['⏳ قيد الإرسال', 'amber']; const img = n.resolvedImage || n.imageUrl || '';
          return `<div class="list-row">${img ? `<img src="${esc(img)}" alt="" style="width:52px;height:52px;border-radius:10px;object-fit:cover" onerror="this.remove()">` : '<span class="kpi-ic" style="background:var(--pink-soft)">🔔</span>'}
            <div style="flex:1;min-width:0"><b>${esc(n.title || '')}</b><div style="font-size:12.5px;color:var(--ink-3);overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${esc(n.body || '')}</div>${n.error ? `<div style="font-size:11.5px;color:var(--red)">${esc(n.error)}</div>` : ''}</div>
            <div style="text-align:left"><span class="tag ${c}">${l}</span><div style="font-size:11px;color:var(--ink-3);margin-top:4px">${ago(n.createdAt)}</div></div></div>`; }).join(''));
    }, (e) => { const box = $('nt-hist'); if (box) box.innerHTML = `<div class="alert red">${esc(e.code || e.message)}</div>`; }));
    return () => { unsubs.forEach((u) => u()); unsubs = []; };
  },
};

function pick(title, items, done) {
  openModal({ title, wide: true, body: `<input class="input" id="pk-q" placeholder="🔍 بحث…" style="margin-bottom:10px"><div id="pk-list" style="max-height:60vh;overflow:auto"></div>` });
  const draw = (q = '') => {
    const list = items.filter((i) => !q || i.label.toLowerCase().includes(q));
    document.getElementById('pk-list').innerHTML = list.length ? list.map((it, n) => `<button class="list-row" data-n="${items.indexOf(it)}" style="width:100%;background:none;border:none;border-bottom:1px solid var(--line-2);cursor:pointer;text-align:right;font-family:inherit">
      ${/^https?:/.test(it.image) ? `<img src="${esc(it.image)}" alt="" style="width:48px;height:48px;border-radius:10px;object-fit:cover">` : '<span class="kpi-ic" style="background:var(--surface-2)">🖼️</span>'}
      <span style="flex:1;min-width:0"><b style="display:block;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${esc(it.label)}</b><small style="color:${/^https?:/.test(it.image) ? 'var(--ink-3)' : '#B45309'}">${/^https?:/.test(it.image) ? esc(it.sub) : '⚠️ بلا صورة'}</small></span></button>`).join('') : '<div class="empty">لا عناصر</div>';
    document.querySelectorAll('#pk-list [data-n]').forEach((b) => b.onclick = () => { closeModal(); done(items[+b.dataset.n]); });
  };
  document.getElementById('pk-q').oninput = (e) => draw(e.target.value.trim().toLowerCase());
  draw();
}
