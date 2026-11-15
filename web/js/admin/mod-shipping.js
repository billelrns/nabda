// أسعار الشحن: 58 ولاية × (منزل، مكتب، مفعّل) — حفظ دفعة واحدة في site_config/shipping
import { db, esc, toast, log, FV } from './core.js';

let rates = {}; let wilayas = []; let dirty = false;
export default {
  render(el) {
    el.innerHTML = `<div class="ad-page-head"><div><h1>أسعار الشحن</h1><p>تُطبَّق فوراً على نموذج الطلب في صفحات المنتجات والسلة</p></div>
      <div class="ad-actions"><button class="btn" id="sh-bulk">⚡ تعديل جماعي</button><button class="btn btn-primary" id="sh-save" disabled>💾 حفظ التغييرات</button></div></div>
      <div class="toolbar"><input class="input" id="sh-q" placeholder="🔍 ابحثي عن ولاية…" style="flex:1"></div>
      <div class="card"><div class="tbl-wrap"><table class="tbl"><thead><tr><th style="width:60px">الرقم</th><th>الولاية</th><th>🏠 للمنزل (دج)</th><th>🏢 للمكتب (دج)</th><th>متاحة</th></tr></thead><tbody id="sh-body"><tr><td colspan="5"><div class="skel" style="height:200px"></div></td></tr></tbody></table></div></div>`;
    Promise.all([fetch('/data/algeria_cities.json').then((r) => r.json()), db.collection('site_config').doc('shipping').get()]).then(([c, d]) => {
      wilayas = c.wilayas || []; rates = d.exists ? d.data() : {}; delete rates.updatedAt; draw();
    }).catch((e) => toast('تعذّر التحميل: ' + (e.code || e.message), 'error'));
    el.querySelector('#sh-q').oninput = (e) => draw(e.target.value.trim());
    el.querySelector('#sh-save').onclick = save;
    el.querySelector('#sh-bulk').onclick = bulk;
    const warn = (e) => { if (dirty) { e.preventDefault(); e.returnValue = ''; } };
    window.addEventListener('beforeunload', warn);
    return () => window.removeEventListener('beforeunload', warn);
  },
};
const def = (name, home) => { const central = ['الجزائر', 'البليدة', 'بومرداس', 'تيبازة'].includes(name); return home ? (central ? 450 : 650) : (central ? 300 : 400); };
function draw(q = '') {
  const b = document.getElementById('sh-body'); if (!b) return;
  b.innerHTML = wilayas.filter((w) => !q || w.wilaya_name_arabic.includes(q) || (w.wilaya_name_latin || '').toLowerCase().includes(q.toLowerCase()) || String(w.wilaya_id) === q).map((w) => {
    const n = w.wilaya_name_arabic; const r = rates[n] || {};
    return `<tr><td class="num"><b>${w.wilaya_id}</b></td><td><b>${esc(n)}</b> <span class="muted">${esc(w.wilaya_name_latin || '')}</span></td>
      <td><input class="input num" style="width:120px" type="number" min="0" data-w="${esc(n)}" data-k="home" value="${r.home ?? ''}" placeholder="${def(n, true)}"></td>
      <td><input class="input num" style="width:120px" type="number" min="0" data-w="${esc(n)}" data-k="desk" value="${r.desk ?? ''}" placeholder="${def(n, false)}"></td>
      <td><label class="switch"><input type="checkbox" data-w="${esc(n)}" data-k="enabled" ${r.enabled === false ? '' : 'checked'}><span></span></label></td></tr>`;
  }).join('');
  b.querySelectorAll('input[data-w]').forEach((i) => i.onchange = () => {
    const r = rates[i.dataset.w] = rates[i.dataset.w] || {};
    if (i.dataset.k === 'enabled') r.enabled = i.checked; else if (i.value === '') delete r[i.dataset.k]; else r[i.dataset.k] = Math.max(0, Number(i.value) || 0);
    dirty = true; document.getElementById('sh-save').disabled = false;
  });
}
async function bulk() {
  const { openModal, closeModal } = await import('./core.js');
  openModal({ title: 'تعديل جماعي لكل الولايات', body: `<div class="form"><div class="f-row"><div class="field"><label>للمنزل</label><input class="input" type="number" id="bk-h" placeholder="اتركيه فارغاً لعدم التغيير"></div><div class="field"><label>للمكتب</label><input class="input" type="number" id="bk-d"></div></div><label class="check"><input type="checkbox" id="bk-central"> استثناء ولايات الوسط (الجزائر، البليدة، بومرداس، تيبازة)</label></div>`,
    foot: '<button class="btn btn-primary" id="bk-ok">تطبيق</button><button class="btn" data-close-modal>إلغاء</button>' });
  document.getElementById('bk-ok').onclick = () => {
    const h = document.getElementById('bk-h').value; const d = document.getElementById('bk-d').value; const ex = document.getElementById('bk-central').checked;
    wilayas.forEach((w) => { const n = w.wilaya_name_arabic; if (ex && ['الجزائر', 'البليدة', 'بومرداس', 'تيبازة'].includes(n)) return; const r = rates[n] = rates[n] || {}; if (h !== '') r.home = Number(h); if (d !== '') r.desk = Number(d); });
    dirty = true; document.getElementById('sh-save').disabled = false; closeModal(); draw(); toast('طُبّق — اضغطي «حفظ التغييرات»');
  };
}
async function save() {
  try {
    await db.collection('site_config').doc('shipping').set({ ...rates, updatedAt: FV().serverTimestamp() });
    dirty = false; document.getElementById('sh-save').disabled = true;
    log('shipping.update', `${Object.keys(rates).length} ولاية`); toast('حُفظت أسعار الشحن ✓', 'success');
  } catch (e) { toast('تعذّر الحفظ (صلاحية المشرفة): ' + (e.code || ''), 'error'); }
}
