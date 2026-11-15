// إعلانات التطبيق — نفس مخطّط _AdsManagementScreen (ads: title, link, image, active, priority, target, startAt, endAt, impressions, clicks)
// تظهر داخل قسم المقالات/الأخبار في التطبيق (news_section.dart). بلا إعلانات نشطة يعرض التطبيق منتجاً من المتجر تلقائياً.
import { S, db, esc, num, fmtDate, toast, confirmBox, openModal, closeModal, log, FV, TS, uploadImage } from './core.js';

const TARGETS = { '': 'كل الأماكن', news: 'المقالات/الأخبار', pregnancy: 'الحمل', cycle: 'الدورة', baby: 'الطفل', home: 'الرئيسية', fertility: 'رحلة الخصوبة' };
let unsub = null;

function state(a) {
  const now = Date.now();
  if (a.active === false) return ['⏸ متوقّف', ''];
  if (a.startAt?.toMillis && a.startAt.toMillis() > now) return ['🕒 مجدول', 'amber'];
  if (a.endAt?.toMillis && a.endAt.toMillis() < now) return ['⌛ منتهي', 'red'];
  return ['● يعمل', 'teal'];
}

export default {
  render(el) {
    el.innerHTML = `<div class="ad-page-head"><div><h1>إعلانات التطبيق</h1><p>بانرات داخل المقالات والأقسام في تطبيق نبضة — مع إحصاء المشاهدات والنقرات</p></div>
      <div class="ad-actions"><button class="btn btn-primary" id="ads-new">+ إعلان جديد</button></div></div>
      <div class="alert teal" style="margin-bottom:14px">📐 المقاس الأفضل 1200×628 (أفقي 1.91:1). بلا إعلان نشط يعرض التطبيق منتجاً من متجركِ. إعلانات الموقع (AdSense) تُضبط في <b>js/site-config.js</b>.</div>
      <div class="grid g-4" id="ads-kpi" style="margin-bottom:14px"></div>
      <div class="grid g-3" id="ads-list"><div class="skel" style="height:200px"></div></div>`;
    el.querySelector('#ads-new').onclick = () => edit(null);
    unsub = db.collection('ads').orderBy('createdAt', 'desc').onSnapshot((s) => {
      const rows = s.docs.map((d) => ({ id: d.id, ...d.data() }));
      const imp = rows.reduce((t, a) => t + (a.impressions || 0), 0); const clk = rows.reduce((t, a) => t + (a.clicks || 0), 0);
      const k = (ic, bg, l, v) => `<div class="card kpi"><div class="kpi-top"><span>${l}</span><span class="kpi-ic" style="background:${bg}">${ic}</span></div><div class="kpi-val num">${v}</div></div>`;
      document.getElementById('ads-kpi').innerHTML = k('📢', 'var(--pink-soft)', 'الإعلانات', num(rows.length)) + k('●', 'var(--teal-soft)', 'تعمل الآن', num(rows.filter((a) => state(a)[1] === 'teal').length))
        + k('👁', 'var(--amber-soft)', 'المشاهدات', num(imp)) + k('🖱', 'var(--green-soft)', 'النقرات (CTR)', `${num(clk)} <small style="font-size:13px;color:var(--ink-3)">${imp ? (clk / imp * 100).toFixed(1) : 0}%</small>`);
      const box = document.getElementById('ads-list');
      box.innerHTML = rows.length ? rows.map((a) => { const [lbl, cls] = state(a); return `
        <div class="card" style="overflow:hidden"><img src="${esc(a.image || '')}" alt="" style="width:100%;aspect-ratio:1.91;object-fit:cover;display:block;background:var(--surface-2)" onerror="this.style.visibility='hidden'">
          <div class="card-b" style="display:grid;gap:8px">
            <div style="display:flex;align-items:center;gap:8px"><b style="flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${esc(a.title || 'إعلان')}</b><label class="switch"><input type="checkbox" data-tg="${esc(a.id)}" ${a.active !== false ? 'checked' : ''}><span></span></label></div>
            <div style="display:flex;gap:6px;flex-wrap:wrap"><span class="tag ${cls}">${lbl}</span><span class="tag">🎯 ${esc(TARGETS[a.target || ''] || a.target)}</span><span class="tag">أولوية ${num(a.priority || 1)}</span></div>
            <div style="font-size:12.5px;color:var(--ink-3)">👁 ${num(a.impressions || 0)} · 🖱 ${num(a.clicks || 0)} · CTR ${a.impressions ? ((a.clicks || 0) / a.impressions * 100).toFixed(1) : 0}%</div>
            ${a.startAt || a.endAt ? `<div style="font-size:12px;color:var(--ink-3)">📅 ${a.startAt ? fmtDate(a.startAt, false) : '—'} ← ${a.endAt ? fmtDate(a.endAt, false) : '—'}</div>` : ''}
            ${a.link ? `<a href="${esc(a.link)}" target="_blank" rel="noopener" style="font-size:12px;color:var(--teal);overflow:hidden;text-overflow:ellipsis;white-space:nowrap" dir="ltr">${esc(a.link)}</a>` : ''}
            <div style="display:flex;gap:6px"><button class="btn btn-sm" data-ed="${esc(a.id)}">✏️ تعديل</button><button class="btn btn-sm btn-danger" data-rm="${esc(a.id)}">حذف</button></div>
          </div></div>`; }).join('') : '<div class="card" style="grid-column:1/-1"><div class="empty"><div class="em">📢</div>لا توجد إعلانات — يعرض التطبيق منتجاً من المتجر تلقائياً</div></div>';
      box.querySelectorAll('[data-tg]').forEach((i) => i.onchange = async () => { try { await db.collection('ads').doc(i.dataset.tg).update({ active: i.checked }); log('ad.toggle', i.dataset.tg, { active: i.checked }); } catch (e) { toast('تعذّر: ' + (e.code || ''), 'error'); } });
      box.querySelectorAll('[data-ed]').forEach((b) => b.onclick = () => edit(rows.find((r) => r.id === b.dataset.ed)));
      box.querySelectorAll('[data-rm]').forEach((b) => b.onclick = async () => { if (!(await confirmBox('حذف هذا الإعلان؟', { danger: true, ok: 'حذف' }))) return; try { await db.collection('ads').doc(b.dataset.rm).delete(); log('ad.delete', b.dataset.rm); toast('حُذف', 'success'); } catch (e) { toast('تعذّر: ' + (e.code || ''), 'error'); } });
    }, (e) => { document.getElementById('ads-list').innerHTML = `<div class="alert red">تعذّر التحميل: ${esc(e.code || e.message)} — انشري قواعد Firestore المحدّثة (firebase deploy --only firestore:rules)</div>`; });
    return () => unsub && unsub();
  },
};

function edit(a) {
  const d = (t) => (t?.toDate ? t.toDate().toISOString().slice(0, 10) : '');
  openModal({ title: a ? 'تعديل الإعلان' : 'إعلان جديد', wide: true, body: `<div class="grid g-2" style="gap:18px"><div class="form">
    <div class="field"><label>عنوان الإعلان</label><input class="input" id="ad-title" value="${esc(a?.title || '')}"></div>
    <div class="field"><label>رابط الوجهة</label><input class="input" id="ad-link" dir="ltr" placeholder="https://nabda.online/product/..." value="${esc(a?.link || '')}"></div>
    <div class="f-row"><div class="field"><label>الاستهداف</label><select class="input" id="ad-target">${Object.entries(TARGETS).map(([k, l]) => `<option value="${k}" ${(a?.target || '') === k ? 'selected' : ''}>${l}</option>`).join('')}</select></div>
      <div class="field"><label>الأولوية</label><input class="input" id="ad-prio" type="number" min="1" max="99" value="${esc(a?.priority ?? 1)}"></div></div>
    <div class="f-row"><div class="field"><label>يبدأ (اختياري)</label><input class="input" id="ad-start" type="date" value="${d(a?.startAt)}"></div>
      <div class="field"><label>ينتهي (اختياري)</label><input class="input" id="ad-end" type="date" value="${d(a?.endAt)}"></div></div></div>
    <div class="form"><div class="field"><label>صورة الإعلان *</label>
      <label class="media-drop" style="display:block;cursor:pointer"><input type="file" id="ad-file" accept="image/*" hidden><img id="ad-prev" src="${esc(a?.image || '')}" alt="" style="width:100%;aspect-ratio:1.91;object-fit:cover;border-radius:12px;background:var(--surface-2);${a?.image ? '' : 'display:none'}"><span id="ad-ph" style="${a?.image ? 'display:none' : ''}">📤 اضغطي لرفع صورة (1200×628)</span></label></div>
      <div class="field"><label>أو رابط صورة</label><input class="input" id="ad-img" dir="ltr" placeholder="https://..." value="${esc(a?.image || '')}"></div></div></div>`,
  foot: '<button class="btn btn-primary" id="ad-save">حفظ</button><button class="btn" data-close-modal>إلغاء</button>' });
  let file = null;
  const prev = document.getElementById('ad-prev');
  const showPrev = (src) => { prev.src = src; prev.style.display = src ? '' : 'none'; document.getElementById('ad-ph').style.display = src ? 'none' : ''; };
  document.getElementById('ad-file').onchange = (e) => { file = e.target.files[0] || null; if (file) showPrev(URL.createObjectURL(file)); };
  document.getElementById('ad-img').oninput = (e) => { file = null; showPrev(e.target.value.trim()); };
  document.getElementById('ad-save').onclick = async (ev) => {
    const btn = ev.currentTarget;
    let image = document.getElementById('ad-img').value.trim();
    if (!file && !/^https:\/\//.test(image)) return toast('أضيفي صورة للإعلان (رفع أو رابط https)', 'error');
    const link = document.getElementById('ad-link').value.trim();
    if (link && !/^https?:\/\//.test(link)) return toast('رابط الوجهة يجب أن يبدأ بـ https://', 'error');
    btn.disabled = true; btn.textContent = 'جاري الحفظ…';
    try {
      if (file) image = await uploadImage(file, 'ads');
      const s = document.getElementById('ad-start').value; const e = document.getElementById('ad-end').value;
      const data = { title: document.getElementById('ad-title').value.trim(), link, image, priority: parseInt(document.getElementById('ad-prio').value, 10) || 1, target: document.getElementById('ad-target').value,
        startAt: s ? TS().fromDate(new Date(s + 'T00:00:00')) : null, endAt: e ? TS().fromDate(new Date(e + 'T23:59:00')) : null };
      if (a) await db.collection('ads').doc(a.id).update(data);
      else await db.collection('ads').add({ ...data, active: true, impressions: 0, clicks: 0, createdAt: FV().serverTimestamp(), createdBy: S.user.uid });
      log(a ? 'ad.update' : 'ad.create', data.title || image); toast('حُفظ الإعلان ✓', 'success'); closeModal();
    } catch (ex) { toast('تعذّر: ' + (ex.code || ex.message || ''), 'error'); btn.disabled = false; btn.textContent = 'حفظ'; }
  };
}
