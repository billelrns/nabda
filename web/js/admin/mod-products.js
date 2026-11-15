// المنتجات: جدول/شبكة، فلاتر، تعديل سريع للسعر والمخزون، محرّر كامل (صور، متغيّرات، SEO، معاينة)، حارس الامتثال، CSV
import { S, db, esc, da, num, toDate, mountTable, openModal, closeModal, toast, confirmBox, downloadCSV, parseCSV, log, can, FV, loadProducts, uploadImage, onData, pimg, pimages, priceStr, MK, pAvail } from './core.js';
import { isHiddenProduct } from '../shop-rules.js';

const F = { q: '', status: 'all', cat: '', mk: '' };
/** تقريب سعر مقترح لينتهي بـ 9 (89، 149…) */
const round9 = (x) => (x < 10 ? Math.max(1, Math.round(x)) : Math.max(9, Math.round((x + 1) / 10) * 10 - 1));
let _rate = null;
/** سعر الصرف المرجعي للاقتراحات فقط (دج لكل ريال) — يُضبط في «الأسواق والدول» */
async function saRate() {
  if (_rate) return _rate;
  try { const d = await db.collection('site_config').doc('markets').get(); _rate = Number(d.exists && d.data().SA?.rateDZD) || 40; } catch (_) { _rate = 40; }
  return _rate;
}
/** سعر سوق آخر كنص (يقبل الكسور: 89.5) */
const mPriceStr = (n) => (Number(n) > 0 ? String(Math.round(Number(n) * 100) / 100) : '');
let table = null;
const STAGES = [['pregnant', '🤰 الحامل'], ['newborn', '👶 المولود'], ['baby', '🧸 الطفل 1-3'], ['mom', '🌸 الأم']];
const img = pimg;
const hasStock = (p) => typeof p.stock === 'number';

export default {
  render(el) {
    el.innerHTML = `
      <div class="ad-page-head">
        <div><h1>المنتجات والمخزون</h1><p id="pr-sub">…</p></div>
        <div class="ad-actions">
          <button class="btn" id="pr-import">⬆️ استيراد CSV</button>
          <button class="btn" id="pr-export">⬇️ تصدير CSV</button>
          <button class="btn btn-primary" id="pr-new">+ منتج جديد</button>
        </div>
      </div>
      <div class="chips" id="pr-chips" style="margin-bottom:12px"></div>
      <div class="toolbar">
        <input class="input" id="pr-q" placeholder="🔍 الاسم، الماركة، SKU…" style="flex:1;min-width:220px">
        <select class="select" id="pr-cat"><option value="">كل التصنيفات</option></select>
        <select class="select" id="pr-mk" title="التوفّر حسب الدولة"><option value="">🌍 كل الأسواق</option><option value="SA+">🇸🇦 يُباع في السعودية</option><option value="SA-">🇸🇦 غير مسعّر في السعودية</option><option value="DZ-">🇩🇿 غير متاح في الجزائر</option></select>
      </div>
      <div id="pr-body"><div class="card card-b"><div class="skel" style="height:300px"></div></div></div>
      <div class="bulkbar hidden" id="pr-bulk">
        <b id="pr-bulk-n"></b>
        <button class="btn btn-sm" data-bulk="on">تفعيل</button><button class="btn btn-sm" data-bulk="off">إخفاء</button>
        <button class="btn btn-sm" data-bulk="price">± تعديل الأسعار %</button>
        <button class="btn btn-sm" data-bulk="feat">⭐ مميّز</button>
        <button class="btn btn-sm" data-bulk="sa-price">🌍 تحويل إلى السعودية</button>
        <button class="btn btn-sm" data-bulk="sa-off">🇸🇦 إيقاف في السعودية</button>
        <button class="btn btn-sm" id="pr-bulk-clear" style="margin-right:auto">إلغاء التحديد</button>
      </div>
      <input type="file" id="pr-csv-file" accept=".csv,text/csv" class="hidden">`;
    el.querySelector('#pr-new').onclick = () => openProductEditor(null);
    el.querySelector('#pr-export').onclick = exportCSV;
    el.querySelector('#pr-import').onclick = () => el.querySelector('#pr-csv-file').click();
    el.querySelector('#pr-csv-file').onchange = importCSV;
    let t; el.querySelector('#pr-q').oninput = (e) => { clearTimeout(t); t = setTimeout(() => { F.q = e.target.value.trim().toLowerCase(); draw(true); }, 200); };
    el.querySelector('#pr-cat').onchange = (e) => { F.cat = e.target.value; draw(true); };
    el.querySelector('#pr-mk').onchange = (e) => { F.mk = e.target.value; draw(true); };
    el.querySelector('#pr-bulk-clear').onclick = () => table?.clearSelection();
    el.querySelectorAll('[data-bulk]').forEach((b) => b.onclick = () => bulk(b.dataset.bulk));
    el.querySelector('#pr-body').addEventListener('change', inlineEdit);
    el.querySelector('#pr-body').addEventListener('click', (e) => {
      const cv = e.target.closest('[data-conv]');
      if (cv) { e.stopPropagation(); openConvert(S.products.find((x) => x.id === cv.dataset.conv)); return; }
      const tg = e.target.closest('[data-toggle]'); if (!tg) return;
      e.stopPropagation(); toggleActive(tg.dataset.toggle);
    });
    table = null;
    loadProducts(true).then(() => draw()).catch((e) => { el.querySelector('#pr-body').innerHTML = `<div class="alert red">تعذّر التحميل: ${esc(e.message)}</div>`; });
    return onData((t2) => { if (t2 === 'products') draw(true); });
  },
};

function statusOf(p) {
  if (isHiddenProduct(p)) return 'banned';
  if (p.active === false) return 'off';
  if (hasStock(p) && p.stock === 0) return 'out';
  if (hasStock(p) && p.stock <= 5) return 'low';
  return 'on';
}
const ST = { all: 'الكل', on: '🟢 معروض', low: '🟠 مخزون منخفض', out: '🔴 نفد', off: '⚪ مخفي', banned: '⛔ ممنوع (مكمّلات/طبي)' };

function filtered() {
  return S.products.filter((p) => {
    if (F.status !== 'all' && statusOf(p) !== F.status) return false;
    if (F.cat && (p.category || '') !== F.cat) return false;
    if (F.q && !`${p.name || ''} ${p.brand || ''} ${p.sku || ''} ${p.slug || ''}`.toLowerCase().includes(F.q)) return false;
    if (F.mk === 'SA+' && !pAvail(p, 'SA')) return false;
    if (F.mk === 'SA-' && pAvail(p, 'SA')) return false;
    if (F.mk === 'DZ-' && pAvail(p, 'DZ')) return false;
    return true;
  });
}

function draw(keep = false) {
  const body = document.getElementById('pr-body'); if (!body) return;
  const cats = [...new Set(S.products.map((p) => p.category).filter(Boolean))].sort((a, b) => a.localeCompare(b, 'ar'));
  const cs = document.getElementById('pr-cat');
  if (cs.options.length - 1 !== cats.length) cs.innerHTML = '<option value="">كل التصنيفات</option>' + cats.map((c) => `<option ${F.cat === c ? 'selected' : ''}>${esc(c)}</option>`).join('');
  const counts = Object.fromEntries(Object.keys(ST).map((k) => [k, k === 'all' ? S.products.length : S.products.filter((p) => statusOf(p) === k).length]));
  document.getElementById('pr-chips').innerHTML = Object.entries(ST).filter(([k]) => k === 'all' || counts[k]).map(([k, l]) => `<button class="chip ${F.status === k ? 'active' : ''}" data-s="${k}">${l} <b>${num(counts[k])}</b></button>`).join('');
  document.querySelectorAll('#pr-chips .chip').forEach((c) => c.onclick = () => { F.status = c.dataset.s; draw(true); });
  const visible = S.products.filter((p) => statusOf(p) === 'on' || statusOf(p) === 'low');
  const stockValue = S.products.reduce((s, p) => s + (hasStock(p) ? p.stock * (Number(p.price) || 0) : 0), 0);
  document.getElementById('pr-sub').textContent = `${num(S.products.length)} منتج • ${num(visible.length)} معروض في المتجر • قيمة المخزون ${da(stockValue)}`;
  const rows = filtered();
  if (table && keep) return table.setRows(rows, true);
  body.innerHTML = '<div class="card" id="pr-tbl"></div>';
  table = mountTable(document.getElementById('pr-tbl'), {
    rows, selectable: can('products'), pageSize: 25, empty: 'لا توجد منتجات مطابقة', emptyIcon: '🛍️',
    onRow: (p) => openProductEditor(p.id),
    onSelect: (sel) => { document.getElementById('pr-bulk').classList.toggle('hidden', !sel.size); document.getElementById('pr-bulk-n').textContent = `${sel.size} محدّد`; },
    columns: [
      { key: 'name', label: 'المنتج', render: (p) => `<div class="cell-prod"><img src="${esc(img(p))}" alt="" loading="lazy"><div><div class="cell-strong">${esc(p.name || '(بلا اسم)')}</div><div class="muted">${esc(p.brand || '')}${p.sku ? ' • ' + esc(p.sku) : ''}${p.featured ? ' • ⭐' : ''}</div></div></div>` },
      { key: 'category', label: 'التصنيف', render: (p) => `<span class="tag">${esc(p.category || '—')}</span>` },
      { key: 'price', label: '🇩🇿 السعر', sort: (p) => Number(p.price) || 0, render: (p) => `<input class="inline-num num" type="number" min="0" data-edit="price" data-id="${esc(p.id)}" value="${Number(p.price) || 0}" aria-label="السعر">${Number(p.oldPrice) > Number(p.price) ? `<div class="muted" style="text-decoration:line-through">${da(p.oldPrice)}</div>` : ''}` },
      { key: 'sa', label: '🇸🇦 السعر', sort: (p) => Number(p.markets?.SA?.price) || 0, render: (p) => `<input class="inline-num num" type="number" min="0" step="0.01" data-edit="sa-price" data-id="${esc(p.id)}" value="${Number(p.markets?.SA?.price) || ''}" placeholder="—" aria-label="سعر السعودية" style="${pAvail(p, 'SA') ? '' : 'opacity:.55'}">${p.markets?.SA && p.markets.SA.active === false ? '<div class="muted" style="font-size:11px">موقوف</div>' : ''}` },
      { key: 'stock', label: 'المخزون', sort: (p) => (hasStock(p) ? p.stock : 1e9), render: (p) => `<input class="inline-num num" type="number" min="0" data-edit="stock" data-id="${esc(p.id)}" value="${hasStock(p) ? p.stock : ''}" placeholder="∞" aria-label="المخزون">` },
      { key: 'soldCount', label: 'مبيعات', sort: (p) => p.soldCount || 0, render: (p) => `<span class="num">${num(p.soldCount || 0)}</span>` },
      { key: 'st', label: 'الحالة', sort: (p) => statusOf(p), render: (p) => { const s = statusOf(p); return s === 'banned' ? '<span class="tag red">⛔ ممنوع</span>' : `<label class="switch" title="ظهور في المتجر" data-nc><input type="checkbox" data-toggle="${esc(p.id)}" ${p.active !== false ? 'checked' : ''}><span></span></label> ${s === 'out' ? '<span class="tag red">نفد</span>' : s === 'low' ? `<span class="tag amber">بقي ${p.stock}</span>` : ''}`; } },
      { key: 'go', label: '', sort: false, render: (p) => `<button class="btn btn-xs" data-conv="${esc(p.id)}" title="نسخ / تحويل لسوق آخر">🌍</button> <a class="btn btn-xs" href="/product/${encodeURIComponent(p.slug || p.id)}" target="_blank" rel="noopener" title="عرض في المتجر">↗</a>` },
    ],
  });
}

async function inlineEdit(e) {
  const inp = e.target.closest('[data-edit]'); if (!inp) return;
  const p = S.products.find((x) => x.id === inp.dataset.id); if (!p) return;
  const field = inp.dataset.edit;
  const raw = inp.value.trim();
  const n = Math.max(0, Number(raw) || 0);
  if (field === 'sa-price') {
    const v = mPriceStr(raw);
    try {
      await db.collection('products').doc(p.id).set({ markets: { SA: { price: v, ...(v && !p.markets?.SA ? { active: true } : {}) } }, updatedAt: FV().serverTimestamp() }, { merge: true });
      p.markets = p.markets || {}; p.markets.SA = { ...(p.markets.SA || {}), price: v, ...(v && p.markets.SA?.active === undefined ? { active: true } : {}) };
      toast(v ? `🇸🇦 ${p.name}: ${v} ر.س ✓` : `🇸🇦 ${p.name}: لم يعد يُباع في السعودية`, 'success'); log('product.sa-price', p.id, { value: v });
      inp.style.opacity = pAvail(p, 'SA') ? '' : '.55';
    } catch (err) { toast('تعذّر الحفظ: ' + (err.code || ''), 'error'); }
    return;
  }
  const val = field === 'stock' ? (raw === '' ? FV().delete() : n) : priceStr(n);
  try {
    await db.collection('products').doc(p.id).update({ [field]: val, updatedAt: FV().serverTimestamp() });
    if (raw === '' && field === 'stock') delete p.stock; else p[field] = field === 'stock' ? n : val;
    toast(`${field === 'price' ? 'السعر' : 'المخزون'}: ${p.name} ✓`, 'success');
    log('product.' + field, p.id, { value: raw });
  } catch (err) { toast('تعذّر الحفظ: ' + (err.code || ''), 'error'); }
}

async function toggleActive(id) {
  const p = S.products.find((x) => x.id === id); if (!p) return;
  const active = p.active === false;
  try {
    await db.collection('products').doc(id).update({ active, updatedAt: FV().serverTimestamp() });
    p.active = active; toast(active ? 'المنتج معروض الآن' : 'أُخفي المنتج', 'success'); log('product.active', id, { active }); draw(true);
  } catch (err) { toast('تعذّر: ' + (err.code || ''), 'error'); }
}

async function bulk(kind) {
  const ids = [...(table?.selected || [])]; if (!ids.length) return;
  const items = S.products.filter((p) => ids.includes(p.id));
  let upd;
  if (kind === 'on') upd = () => ({ active: true });
  if (kind === 'off') upd = () => ({ active: false });
  if (kind === 'feat') upd = (p) => ({ featured: !p.featured });
  if (kind === 'price') {
    const { promptBox } = await import('./core.js');
    const v = await promptBox('النسبة المئوية (مثال: 10 للزيادة، ‎-15 للتخفيض). السعر القديم يُحفظ تلقائياً عند التخفيض.', { title: 'تعديل الأسعار جماعياً', value: '-10' });
    const pct = Number(v); if (!v || !pct) return;
    upd = (p) => { const np = Math.round((Number(p.price) || 0) * (1 + pct / 100) / 10) * 10; return pct < 0 ? { price: priceStr(np), oldPrice: priceStr(Math.max(Number(p.oldPrice) || 0, Number(p.price) || 0)) } : { price: priceStr(np) }; };
  }
  if (kind === 'sa-off') upd = () => ({ 'markets.SA.active': false });
  if (kind === 'sa-price') {
    const { promptBox } = await import('./core.js');
    const v = await promptBox('نفس المنتجات (نفس الصور والمعطيات والرابط) تُضاف إلى متجر السعودية بسعر بالريال. كم ديناراً مقابل ريال واحد في تسعيركِ؟ (مثال: 40 ⇒ 3500 دج تصبح 89 ر.س). تُقرَّب الأسعار لتنتهي بـ 9، ويمكنكِ تعديل أي سعر بعدها من العمود 🇸🇦. المنتجات المسعّرة مسبقاً لا تُمسّ.', { title: '🌍 تحويل المنتجات المحدّدة إلى السعودية', value: String(await saRate()) });
    const rate = Number(v); if (!(rate > 0)) return;
    upd = (p) => (Number(p.markets?.SA?.price) > 0 ? {} : { 'markets.SA.price': String(round9((Number(p.price) || 0) / rate)), 'markets.SA.active': true, ...(Number(p.oldPrice) > Number(p.price) ? { 'markets.SA.oldPrice': String(round9(Number(p.oldPrice) / rate)) } : {}) });
  }
  if (kind === 'on' && items.some(isHiddenProduct)) return toast('بعض المنتجات المحدّدة ممنوعة (مكمّلات/أجهزة طبية) ولا يمكن عرضها', 'error');
  if (!(await confirmBox(`تطبيق التعديل على ${items.length} منتج؟`))) return;
  try {
    const batch = db.batch();
    items.forEach((p) => {
      const u = upd(p); if (!Object.keys(u).length) return;
      Object.entries(u).forEach(([k, v]) => { if (!k.includes('.')) { p[k] = v; return; } const [a, b, c] = k.split('.'); p[a] = p[a] || {}; p[a][b] = { ...(p[a][b] || {}), [c]: v }; });
      batch.update(db.collection('products').doc(p.id), { ...u, updatedAt: FV().serverTimestamp() });
    });
    await batch.commit(); log('product.bulk.' + kind, ids.join(','));
    toast(`عُدّل ${items.length} منتج`, 'success'); table.clearSelection(); draw(true);
  } catch (err) { toast('تعذّر: ' + (err.code || ''), 'error'); }
}

/* ─────────── محرّر المنتج ─────────── */
export function slugify(s) {
  return String(s || '').trim().toLowerCase()
    .replace(/[ًٌٍَُِّْـ]/g, '').replace(/[^\p{L}\p{N}\s-]/gu, '').replace(/\s+/g, '-').replace(/-+/g, '-').replace(/^-|-$/g, '').slice(0, 70);
}

export async function openProductEditor(id) {
  await loadProducts();
  const src = id ? S.products.find((p) => p.id === id) : null;
  if (id && !src) return toast('المنتج غير موجود', 'error');
  const p = JSON.parse(JSON.stringify(src || { active: true, images: [], variants: [], lifeStageTags: [] }));
  p.images = pimages(p);
  p.variants = Array.isArray(p.variants) ? p.variants : [];
  let cost = '';
  if (id) db.collection('products_private').doc(id).get().then((d) => { cost = d.exists ? (d.data().cost ?? '') : (p.costPrice || ''); const c = document.getElementById('pe-cost'); if (c && cost !== '') { c.value = cost; margin(); } }).catch(() => {});
  const cats = [...new Set(S.products.map((x) => x.category).filter(Boolean))];
  const brands = [...new Set(S.products.map((x) => x.brand).filter(Boolean))];
  openModal({
    title: id ? `تعديل: ${p.name || ''}` : 'منتج جديد', wide: true,
    body: `
      <div style="display:grid;grid-template-columns:minmax(0,1fr) 280px;gap:20px" class="pe-grid">
        <div>
          <div id="pe-banned" class="alert red hidden" style="margin-bottom:12px">⛔ هذا المنتج يطابق قواعد المنع (مكمّلات غذائية/أجهزة طبية) — لن يظهر في الموقع ولا التطبيق ولا يمكن تفعيله.</div>
          <div class="tabs" id="pe-tabs">${['أساسي', 'الصور', 'السعر والمخزون', 'المتغيّرات', 'التنظيم', 'SEO', '🌍 الأسواق'].map((t, i) => `<button data-t="${i}" class="${i === 0 ? 'active' : ''}">${t}</button>`).join('')}</div>
          <div class="pe-pane form" data-p="0">
            <div class="field"><label>اسم المنتج *</label><input class="input" id="pe-name" maxlength="140" value="${esc(p.name || '')}"></div>
            <div class="field"><label>الوصف</label><textarea class="textarea" id="pe-desc" rows="9" placeholder="فقرات مفصولة بسطر فارغ. ابدئي السطر بـ - لقائمة نقطية، و **نص** للغامق.">${esc(p.description || p.desc || '')}</textarea><span class="hint">يظهر في تبويب «الوصف» بصفحة المنتج.</span></div>
          </div>
          <div class="pe-pane hidden" data-p="1">
            <div class="media-grid" id="pe-media"></div>
            <div class="hint" style="margin-top:8px">اسحبي الصور لإعادة الترتيب — الأولى هي الصورة الرئيسية. تُضغط تلقائياً إلى WebP (≤1600px).</div>
            <div class="field" style="margin-top:12px"><label>أو أضيفي رابط صورة</label><div style="display:flex;gap:6px"><input class="input" id="pe-url" placeholder="https://…" dir="ltr" style="flex:1"><button class="btn" id="pe-url-add" type="button">إضافة</button></div></div>
            <input type="file" id="pe-file" accept="image/*" multiple class="hidden">
          </div>
          <div class="pe-pane form hidden" data-p="2">
            <div class="f-row c3">
              <div class="field"><label>السعر (دج) *</label><input class="input num" type="number" min="0" id="pe-price" value="${Number(p.price) || ''}"></div>
              <div class="field"><label>السعر قبل التخفيض</label><input class="input num" type="number" min="0" id="pe-old" value="${Number(p.oldPrice || p.originalPrice) || ''}"></div>
              <div class="field"><label>التكلفة (خاصة بالطاقم)</label><input class="input num" type="number" min="0" id="pe-cost" value="${esc(cost)}"><span class="hint" id="pe-margin"></span></div>
            </div>
            <div class="f-row c3">
              <div class="field"><label>المخزون</label><input class="input num" type="number" min="0" id="pe-stock" value="${hasStock(p) ? p.stock : ''}" placeholder="فارغ = غير محدود"></div>
              <div class="field"><label>رمز المنتج SKU</label><input class="input" id="pe-sku" dir="ltr" value="${esc(p.sku || '')}"></div>
              <div class="field"><label>شارة</label><select class="select" id="pe-badge">${['', 'جديد', 'الأكثر مبيعاً', 'عرض خاص', 'كمية محدودة', 'حصري'].map((b) => `<option ${p.badge === b ? 'selected' : ''} value="${b}">${b || '— بلا —'}</option>`).join('')}</select></div>
            </div>
          </div>
          <div class="pe-pane hidden" data-p="3">
            <div id="pe-variants" class="form"></div>
            <button class="btn btn-sm" id="pe-var-add" type="button" style="margin-top:10px">+ خيار (مقاس، لون…)</button>
          </div>
          <div class="pe-pane form hidden" data-p="4">
            <div class="f-row">
              <div class="field"><label>التصنيف *</label><input class="input" id="pe-cat" list="pe-cats" value="${esc(p.category || '')}"><datalist id="pe-cats">${cats.map((c) => `<option value="${esc(c)}">`).join('')}</datalist></div>
              <div class="field"><label>الماركة</label><input class="input" id="pe-brand" list="pe-brands" value="${esc(p.brand || '')}"><datalist id="pe-brands">${brands.map((c) => `<option value="${esc(c)}">`).join('')}</datalist></div>
            </div>
            <div class="field"><label>مناسب لـ (يحدّد ظهوره في الأقسام والمقالات المخصّصة)</label><div style="display:flex;gap:14px;flex-wrap:wrap">${STAGES.map(([k, l]) => `<label class="check"><input type="checkbox" class="pe-stage" value="${k}" ${(p.lifeStageTags || []).includes(k) ? 'checked' : ''}> ${l}</label>`).join('')}</div></div>
            <div style="display:flex;gap:24px;flex-wrap:wrap">
              <label class="check"><input type="checkbox" id="pe-active" ${p.active !== false ? 'checked' : ''}> معروض في المتجر</label>
              <label class="check"><input type="checkbox" id="pe-featured" ${p.featured ? 'checked' : ''}> ⭐ منتج مميّز (الرئيسية)</label>
            </div>
          </div>
          <div class="pe-pane form hidden" data-p="5">
            <div class="field"><label>الرابط (slug)</label><div style="display:flex;gap:6px;align-items:center"><span class="muted" dir="ltr" style="color:var(--ink-3)">nabda.online/product/</span><input class="input" id="pe-slug" dir="auto" value="${esc(p.slug || '')}" style="flex:1"></div><span class="hint" id="pe-slug-hint">يُولَّد من الاسم إن تُرك فارغاً.</span></div>
            <div class="field"><label>عنوان SEO</label><input class="input" id="pe-seot" maxlength="70" value="${esc(p.seoTitle || '')}" placeholder="افتراضياً: اسم المنتج"></div>
            <div class="field"><label>وصف SEO</label><textarea class="textarea" id="pe-seod" rows="3" maxlength="170" placeholder="افتراضياً: بداية الوصف">${esc(p.seoDescription || '')}</textarea></div>
            <div class="serp"><div class="u" id="pe-serp-u"></div><div class="t" id="pe-serp-t"></div><div class="d" id="pe-serp-d"></div></div>
          </div>
          <div class="pe-pane form hidden" data-p="6">
            <div class="alert teal">كل دولة سوق مستقل: سعر بعملتها، ونص بلهجتها (اختياري). المنتج بلا سعر في سوق لا يظهر فيه، ولا تحويل آلي للعملة.</div>
            <div class="card"><div class="card-h"><h3>🇩🇿 الجزائر</h3><label class="check"><input type="checkbox" id="pe-mk-dz" ${p.markets?.DZ?.active !== false ? 'checked' : ''}> يُباع في الجزائر</label></div>
              <div class="card-b" style="font-size:13px;color:var(--ink-3)">السعر والمخزون والنص من التبويبات الأساسية (بالدينار).</div></div>
            <div class="card" style="margin-top:12px"><div class="card-h"><h3>🇸🇦 السعودية</h3><label class="check"><input type="checkbox" id="pe-mk-sa" ${p.markets?.SA?.active !== false && Number(p.markets?.SA?.price) > 0 ? 'checked' : ''}> يُباع في السعودية</label></div>
              <div class="card-b form">
                <div class="f-row c3">
                  <div class="field"><label>السعر (ر.س) <button class="btn btn-xs" type="button" id="pe-sa-suggest" title="من سعر الجزائر وسعر الصرف المرجعي">⚡ اقتراح</button></label><input class="input num" type="number" min="0" step="0.01" id="pe-sa-price" value="${Number(p.markets?.SA?.price) || ''}"><span class="hint" id="pe-sa-hint"></span></div>
                  <div class="field"><label>قبل التخفيض (ر.س)</label><input class="input num" type="number" min="0" step="0.01" id="pe-sa-old" value="${Number(p.markets?.SA?.oldPrice) || ''}"></div>
                  <div class="field"><label>مخزون السعودية</label><input class="input num" type="number" min="0" id="pe-sa-stock" value="${typeof p.markets?.SA?.stock === 'number' ? p.markets.SA.stock : ''}" placeholder="فارغ = غير محدود"></div>
                </div>
                <div class="field"><label>الاسم للسوق السعودي (اختياري)</label><input class="input" id="pe-sa-name" maxlength="140" value="${esc(p.i18n?.SA?.name || '')}" placeholder="افتراضياً: الاسم الأصلي"></div>
                <div class="field"><label>الوصف باللهجة السعودية/الخليجية (اختياري)</label><textarea class="textarea" id="pe-sa-desc" rows="7" placeholder="افتراضياً: الوصف الأصلي. تجنّبي كلمات الدارجة الجزائرية مثل «بزاف، واش، كاين».">${esc(p.i18n?.SA?.description || '')}</textarea>
                  <div style="display:flex;gap:6px;margin-top:6px"><button class="btn btn-xs" type="button" id="pe-sa-copy">📋 نسخ الوصف الأصلي للتعديل</button><span class="hint" id="pe-sa-warn"></span></div></div>
              </div></div>
          </div>
        </div>
        <div><div style="position:sticky;top:0"><div style="font-weight:900;margin-bottom:8px;font-size:13px;color:var(--ink-3)">معاينة البطاقة</div><div class="preview-card" id="pe-preview"></div></div></div>
      </div>
      <style>@media(max-width:860px){.pe-grid{grid-template-columns:1fr!important}}</style>`,
    foot: `<button class="btn btn-primary" id="pe-save">💾 حفظ</button><button class="btn" data-close-modal>إلغاء</button>
      ${id ? `<button class="btn" id="pe-conv">🌍 نسخ / تحويل لسوق آخر</button><button class="btn" id="pe-dup">📄 نسخ</button>${can('products.delete') ? '<button class="btn btn-danger" id="pe-del" style="margin-right:auto">🗑️ حذف</button>' : ''}` : ''}`,
  });
  const $ = (i) => document.getElementById(i);
  document.querySelectorAll('#pe-tabs button').forEach((b) => b.onclick = () => {
    document.querySelectorAll('#pe-tabs button').forEach((x) => x.classList.toggle('active', x === b));
    document.querySelectorAll('.pe-pane').forEach((x) => x.classList.toggle('hidden', x.dataset.p !== b.dataset.t));
  });

  /* الصور */
  function media() {
    $('pe-media').innerHTML = p.images.map((u, i) => `<div class="media-item" draggable="true" data-i="${i}"><img src="${esc(u)}" alt=""><button class="rm" data-rm="${i}" type="button" aria-label="حذف">✕</button>${i === 0 ? '<span class="main">رئيسية</span>' : ''}</div>`).join('')
      + '<div class="media-drop" id="pe-drop">📷<span>اسحبي الصور هنا<br>أو اضغطي للاختيار</span></div>';
    $('pe-drop').onclick = () => $('pe-file').click();
    $('pe-drop').ondragover = (e) => { e.preventDefault(); $('pe-drop').classList.add('over'); };
    $('pe-drop').ondragleave = () => $('pe-drop').classList.remove('over');
    $('pe-drop').ondrop = (e) => { e.preventDefault(); $('pe-drop').classList.remove('over'); if (e.dataTransfer.files.length) upload([...e.dataTransfer.files]); };
    let from = null;
    $('pe-media').querySelectorAll('.media-item').forEach((m) => {
      m.ondragstart = () => { from = +m.dataset.i; };
      m.ondragover = (e) => e.preventDefault();
      m.ondrop = (e) => { e.preventDefault(); if (from === null) return; const to = +m.dataset.i; const [x] = p.images.splice(from, 1); p.images.splice(to, 0, x); from = null; media(); preview(); };
    });
    $('pe-media').querySelectorAll('[data-rm]').forEach((b) => b.onclick = () => { p.images.splice(+b.dataset.rm, 1); media(); preview(); });
  }
  async function upload(files) {
    const folder = `products/${id || 'new_' + Date.now().toString(36)}`;
    for (const f of files.filter((x) => x.type.startsWith('image/'))) {
      if (f.size > 15 * 1024 * 1024) { toast(`${f.name}: أكبر من 15MB`, 'error'); continue; }
      $('pe-drop').innerHTML = '⏳<span>جاري الرفع…</span>';
      try { p.images.push(await uploadImage(f, folder)); } catch (e) { toast('فشل رفع ' + f.name + ': ' + (e.code || ''), 'error'); }
    }
    media(); preview();
  }
  $('pe-file').onchange = (e) => { upload([...e.target.files]); e.target.value = ''; };
  $('pe-url-add').onclick = () => { const u = $('pe-url').value.trim(); if (/^https?:\/\//.test(u)) { p.images.push(u); $('pe-url').value = ''; media(); preview(); } else toast('رابط غير صالح', 'error'); };
  media();

  /* المتغيّرات */
  function vars() {
    $('pe-variants').innerHTML = p.variants.length ? p.variants.map((v, i) => `<div class="f-row" style="grid-template-columns:180px 1fr 40px;align-items:end">
      <div class="field"><label>الاسم</label><input class="input" data-vl="${i}" value="${esc(v.label || '')}" placeholder="المقاس"></div>
      <div class="field"><label>الخيارات (افصلي بفاصلة)</label><input class="input" data-vo="${i}" value="${esc((v.options || []).join('، '))}" placeholder="S، M، L"></div>
      <button class="btn btn-danger btn-sm" data-vr="${i}" type="button" style="height:38px">✕</button></div>`).join('') : '<div class="muted" style="color:var(--ink-3)">لا خيارات — منتج بخيار واحد.</div>';
    $('pe-variants').querySelectorAll('[data-vl]').forEach((x) => x.oninput = () => { p.variants[+x.dataset.vl].label = x.value; });
    $('pe-variants').querySelectorAll('[data-vo]').forEach((x) => x.oninput = () => { p.variants[+x.dataset.vo].options = x.value.split(/[,،]/).map((s) => s.trim()).filter(Boolean); });
    $('pe-variants').querySelectorAll('[data-vr]').forEach((x) => x.onclick = () => { p.variants.splice(+x.dataset.vr, 1); vars(); });
  }
  $('pe-var-add').onclick = () => { p.variants.push({ label: '', options: [] }); vars(); };
  vars();

  /* معاينة + هامش + SEO + حارس الامتثال */
  function margin() {
    const pr = Number($('pe-price').value) || 0; const c = Number($('pe-cost').value) || 0;
    $('pe-margin').textContent = pr && c ? `الربح: ${da(pr - c)} (${Math.round(((pr - c) / pr) * 100)}%)` : '';
  }
  function preview() {
    const name = $('pe-name').value || 'اسم المنتج'; const pr = Number($('pe-price').value) || 0; const old = Number($('pe-old').value) || 0;
    const off = old > pr && pr ? Math.round((1 - pr / old) * 100) : 0;
    $('pe-preview').innerHTML = `<div style="position:relative"><img src="${esc(p.images[0] || '/favicon.png')}" alt="">${off ? `<span style="position:absolute;top:10px;right:10px;background:#E91E63;color:#fff;font-weight:900;font-size:12px;border-radius:999px;padding:2px 9px">-${off}%</span>` : ''}${$('pe-badge').value ? `<span style="position:absolute;top:10px;left:10px;background:#00897B;color:#fff;font-weight:800;font-size:11px;border-radius:999px;padding:2px 9px">${esc($('pe-badge').value)}</span>` : ''}</div>
      <div style="padding:12px"><div style="font-size:11px;color:var(--pink);font-weight:800">${esc($('pe-brand').value || $('pe-cat').value || '')}</div><div style="font-weight:900;margin:4px 0 8px;line-height:1.5">${esc(name)}</div>
      <div><b style="color:#E91E63">${da(pr)}</b> ${off ? `<s style="color:#999;font-size:12px">${da(old)}</s>` : ''}</div></div>`;
    const banned = isHiddenProduct({ name: $('pe-name').value, category: $('pe-cat').value });
    $('pe-banned').classList.toggle('hidden', !banned);
    if (banned) $('pe-active').checked = false;
    $('pe-active').disabled = banned;
    const slug = $('pe-slug').value || slugify(name);
    $('pe-serp-u').textContent = `nabda.online › product › ${slug}`;
    $('pe-serp-t').textContent = ($('pe-seot').value || name) + ' — متجر نبضة';
    $('pe-serp-d').textContent = ($('pe-seod').value || $('pe-desc').value || '').replace(/\s+/g, ' ').slice(0, 160) || 'وصف المنتج…';
    const clash = S.products.find((x) => x.id !== id && (x.slug || '') === slug);
    $('pe-slug-hint').innerHTML = clash ? `<span style="color:var(--red)">⚠️ الرابط مستخدم من «${esc(clash.name)}» — سنضيف لاحقة تلقائياً.</span>` : 'يُولَّد من الاسم إن تُرك فارغاً.';
    margin();
  }
  document.getElementById('modal-body').addEventListener('input', preview);
  preview();
  /* تبويب الأسواق */
  const DZ_WORDS = ['بزاف', 'واش', 'كاين', 'راهي', 'راه ', 'ماشي', 'برك', 'نتاع', 'ديالك', 'شحال', 'درك'];
  function saHints() {
    const dz = Number($('pe-price').value) || 0; const sa = Number($('pe-sa-price').value) || 0;
    $('pe-sa-hint').textContent = dz && sa ? `≈ ${Math.round(dz / sa)} دج للريال` : '';
    const t = $('pe-sa-desc').value + ' ' + $('pe-sa-name').value;
    const hit = DZ_WORDS.filter((w) => t.includes(w));
    $('pe-sa-warn').innerHTML = hit.length ? `<span style="color:var(--red)">⚠️ كلمات دارجة جزائرية: ${esc(hit.join('، '))}</span>` : '';
    if (sa > 0 && document.activeElement === $('pe-sa-price')) $('pe-mk-sa').checked = true;
  }
  ['pe-sa-price', 'pe-sa-desc', 'pe-sa-name', 'pe-price'].forEach((i) => $(i).addEventListener('input', saHints));
  $('pe-sa-suggest').onclick = async () => {
    const r = await saRate(); const dz = Number($('pe-price').value) || 0; const old = Number($('pe-old').value) || 0;
    if (!dz) return toast('أدخلي سعر الجزائر أولاً (تبويب السعر والمخزون)', 'error');
    $('pe-sa-price').value = round9(dz / r); if (old > dz) $('pe-sa-old').value = round9(old / r);
    $('pe-mk-sa').checked = true; saHints(); toast(`اقتراح بسعر ${r} دج للريال — عدّليه بحرّية`);
  };
  $('pe-sa-copy').onclick = () => { if (!$('pe-sa-desc').value.trim() || confirm('استبدال النص الحالي بالوصف الأصلي؟')) { $('pe-sa-desc').value = $('pe-desc').value; saHints(); } };
  saHints();

  $('pe-save').onclick = async () => {
    const name = $('pe-name').value.trim();
    const price = Number($('pe-price').value);
    const category = $('pe-cat').value.trim();
    if (!name) return toast('الاسم مطلوب', 'error');
    if (!(price > 0)) return toast('السعر مطلوب', 'error');
    if (!category) return toast('التصنيف مطلوب (تبويب التنظيم)', 'error');
    // الرابط الحالي لا يُمسّ (روابط منشورة على فيسبوك) ما لم تغيّره المشرفة يدوياً
    let slug = src && src.slug && $('pe-slug').value.trim() === src.slug ? src.slug : (slugify($('pe-slug').value || name) || 'product');
    while (S.products.some((x) => x.id !== id && x.slug === slug)) slug = slug.replace(/-\w{4}$/, '') + '-' + Math.random().toString(36).slice(2, 6);
    const stockRaw = $('pe-stock').value.trim();
    const data = {
      name, slug, category, price: priceStr(price),
      description: $('pe-desc').value.trim(),
      brand: $('pe-brand').value.trim(),
      oldPrice: Number($('pe-old').value) > price ? priceStr($('pe-old').value) : '',
      sku: $('pe-sku').value.trim(),
      badge: $('pe-badge').value,
      // حقول التطبيق: imageUrls + coverImage + imageUrl (و images/image للتوافق)
      imageUrls: p.images, coverImage: p.images[0] || '', imageUrl: p.images[0] || '', images: p.images, image: p.images[0] || '',
      variants: p.variants.filter((v) => v.label && (v.options || []).length),
      lifeStageTags: [...document.querySelectorAll('.pe-stage:checked')].map((x) => x.value),
      featured: $('pe-featured').checked,
      active: $('pe-active').checked && !isHiddenProduct({ name, category }),
      seoTitle: $('pe-seot').value.trim(), seoDescription: $('pe-seod').value.trim(),
      updatedAt: FV().serverTimestamp(),
    };
    data.stock = stockRaw === '' ? FV().delete() : Math.max(0, parseInt(stockRaw, 10) || 0);
    // الأسواق: الجزائر = الحقول الأصلية + markets.DZ.active، والسعودية = markets.SA + i18n.SA
    const saPrice = mPriceStr($('pe-sa-price').value); const saOld = Number($('pe-sa-old').value) > Number(saPrice) ? mPriceStr($('pe-sa-old').value) : '';
    const saStock = $('pe-sa-stock').value.trim();
    if ($('pe-mk-sa').checked && !saPrice) return toast('🇸🇦 أدخلي سعر السعودية أو ألغي «يُباع في السعودية» (تبويب الأسواق)', 'error');
    data.markets = { DZ: { active: $('pe-mk-dz').checked }, SA: { price: saPrice, oldPrice: saOld, active: $('pe-mk-sa').checked && !!saPrice, stock: saStock === '' ? FV().delete() : Math.max(0, parseInt(saStock, 10) || 0) } };
    data.i18n = { SA: { name: $('pe-sa-name').value.trim(), description: $('pe-sa-desc').value.trim() } };
    if (!id && saStock === '') delete data.markets.SA.stock;
    $('pe-save').disabled = true; $('pe-save').textContent = '⏳ جاري الحفظ…';
    try {
      let ref;
      if (id) { ref = db.collection('products').doc(id); await ref.set(data, { merge: true }); }
      else { ref = db.collection('products').doc(); if (stockRaw === '') delete data.stock; await ref.set({ ...data, createdAt: FV().serverTimestamp(), soldCount: 0 }); }
      const c = $('pe-cost').value.trim();
      if (c !== '') await db.collection('products_private').doc(ref.id).set({ cost: Number(c) || 0, updatedAt: FV().serverTimestamp() }, { merge: true }).catch(() => toast('حُفظ المنتج، لكن تعذّر حفظ التكلفة', 'error'));
      log(id ? 'product.update' : 'product.create', ref.id, { name });
      toast(id ? 'حُفظت التعديلات ✓' : 'أُضيف المنتج ✓', 'success');
      closeModal();
      await loadProducts(true);
      draw();
    } catch (e) {
      console.error(e); toast('تعذّر الحفظ: ' + (e.code || e.message), 'error');
      $('pe-save').disabled = false; $('pe-save').textContent = '💾 حفظ';
    }
  };
  $('pe-conv')?.addEventListener('click', () => { closeModal(); setTimeout(() => openConvert(src), 80); });
  $('pe-dup')?.addEventListener('click', async () => {
    const copy = { ...src }; delete copy.id;
    copy.name = (src.name || '') + ' (نسخة)'; copy.slug = slugify(copy.name) + '-' + Math.random().toString(36).slice(2, 6);
    copy.active = false; copy.soldCount = 0; copy.createdAt = FV().serverTimestamp(); copy.updatedAt = FV().serverTimestamp();
    try { const r = await db.collection('products').add(copy); log('product.duplicate', r.id); toast('أُنشئت نسخة مخفية', 'success'); closeModal(); await loadProducts(true); draw(); openProductEditor(r.id); }
    catch (e) { toast('تعذّر: ' + (e.code || ''), 'error'); }
  });
  $('pe-del')?.addEventListener('click', async () => {
    closeModal();
    if (!(await confirmBox(`حذف «${src.name}» نهائياً؟ الطلبات السابقة تبقى محفوظة. (يُفضَّل الإخفاء بدل الحذف)`, { danger: true, ok: 'حذف نهائي' }))) return;
    try { await db.collection('products').doc(id).delete(); log('product.delete', id, { name: src.name }); toast('حُذف المنتج', 'success'); await loadProducts(true); draw(); }
    catch (e) { toast('تعذّر الحذف (صلاحيات المشرفة فقط): ' + (e.code || ''), 'error'); }
  });
}

/* ─────────── نسخ / تحويل منتج إلى سوق آخر (نفس المعطيات والصور، بعملة أخرى) ─────────── */
export async function openConvert(src) {
  if (!src) return;
  const rate = await saRate();
  const dzP = Number(src.price) || 0; const dzO = Number(src.oldPrice) > dzP ? Number(src.oldPrice) : 0;
  const has = Number(src.markets?.SA?.price) > 0;
  const sug = dzP ? round9(dzP / rate) : '';
  openModal({ title: `🌍 نسخ / تحويل: ${src.name || ''}`, wide: true, body: `
    <div class="grid g-2" style="gap:18px"><div class="form">
      <div class="field"><label>السوق الهدف</label><div class="seg"><button class="active" type="button">🇸🇦 السعودية — ر.س</button></div></div>
      <div class="field"><label>طريقة التحويل</label>
        <label class="check" style="display:flex;margin:6px 0;align-items:flex-start;gap:8px"><input type="radio" name="cv-mode" value="same" checked> <span><b>نفس المنتج في السوقين (موصى به)</b><br><small style="color:var(--ink-3)">نفس الصور والمعطيات والتقييمات، رابطان: /product/… للجزائر و /sa/product/… للسعودية، وكل سوق بسعره ومخزونه.</small></span></label>
        <label class="check" style="display:flex;margin:6px 0;align-items:flex-start;gap:8px"><input type="radio" name="cv-mode" value="copy"> <span><b>نسخة مستقلة للسعودية فقط</b><br><small style="color:var(--ink-3)">منتج جديد بنفس الصور والمعطيات تعدّلينه بحرّية (متغيّرات أو مورّد مختلف). الأصل لا يُمسّ.</small></span></label>
      </div>
      <div id="cv-warn" class="alert amber hidden">⚠️ تطبيق نبضة الحالي لا يعرف الأسواق بعد: النسخة المستقلة ستظهر فيه كمنتج مكرّر بسعر الجزائر إلى أن يُحدَّث التطبيق. الأفضل «نفس المنتج في السوقين».</div>
      ${has ? `<div class="alert teal">هذا المنتج مسعّر للسعودية مسبقاً بـ ${num(src.markets.SA.price)} ر.س — سيُحدَّث السعر.</div>` : ''}
    </div><div class="form">
      <div class="f-row"><div class="field"><label>سعر السعودية (ر.س) *</label><input class="input num" type="number" min="0" step="0.01" id="cv-price" value="${has ? Number(src.markets.SA.price) : sug}"></div>
        <div class="field"><label>قبل التخفيض (ر.س)</label><input class="input num" type="number" min="0" step="0.01" id="cv-old" value="${has ? (Number(src.markets.SA.oldPrice) || '') : (dzO ? round9(dzO / rate) : '')}"></div></div>
      <div class="f-row"><div class="field"><label>سعر الصرف للاقتراح (دج / ريال)</label><input class="input num" type="number" min="1" id="cv-rate" value="${rate}"><span class="hint">الأصل: ${da(dzP, 'DZD')}${dzO ? ' (قبل التخفيض ' + da(dzO, 'DZD') + ')' : ''}</span></div>
        <div class="field"><label>مخزون السعودية</label><input class="input num" type="number" min="0" id="cv-stock" placeholder="فارغ = غير محدود"></div></div>
      <div class="field"><label>الاسم في السعودية (اختياري)</label><input class="input" id="cv-name" value="${esc(src.i18n?.SA?.name || '')}" placeholder="${esc(src.name || '')}"></div>
      <label class="check"><input type="checkbox" id="cv-desc" ${src.i18n?.SA?.description ? '' : 'checked'}> نسخ الوصف إلى نص السعودية لأعدّله باللهجة الخليجية</label>
      <label class="check" style="margin-top:6px"><input type="checkbox" id="cv-open" checked> فتح المنتج بعد التحويل للمراجعة</label>
    </div></div>`,
  foot: '<button class="btn btn-primary" id="cv-go">🌍 تحويل</button><button class="btn" data-close-modal>إلغاء</button>' });
  const $ = (i) => document.getElementById(i);
  document.querySelectorAll('input[name="cv-mode"]').forEach((r) => r.onchange = () => $('cv-warn').classList.toggle('hidden', r.value !== 'copy' || !r.checked));
  $('cv-rate').oninput = () => { const r = Number($('cv-rate').value); if (r > 0 && dzP) { $('cv-price').value = round9(dzP / r); if (dzO) $('cv-old').value = round9(dzO / r); } };
  $('cv-go').onclick = async () => {
    const openAfter = $('cv-open').checked;
    const mode = document.querySelector('input[name="cv-mode"]:checked').value;
    const price = mPriceStr($('cv-price').value); if (!price) return toast('أدخلي سعر السعودية', 'error');
    const old = Number($('cv-old').value) > Number(price) ? mPriceStr($('cv-old').value) : '';
    const st = $('cv-stock').value.trim();
    const SA = { price, oldPrice: old, active: true, ...(st !== '' ? { stock: Math.max(0, parseInt(st, 10) || 0) } : {}) };
    const i18n = { ...(src.i18n?.SA || {}), ...($('cv-name').value.trim() ? { name: $('cv-name').value.trim() } : {}), ...($('cv-desc').checked ? { description: src.description || '' } : {}) };
    try {
      let targetId = src.id;
      if (mode === 'same') {
        await db.collection('products').doc(src.id).set({ markets: { SA }, i18n: { SA: i18n }, updatedAt: FV().serverTimestamp() }, { merge: true });
        log('product.market.add', src.id, { market: 'SA', price });
      } else {
        const copy = JSON.parse(JSON.stringify(src)); delete copy.id;
        copy.slug = (src.slug || slugify(src.name)) + '-sa';
        while (S.products.some((x) => x.slug === copy.slug)) copy.slug = copy.slug.replace(/-\w{4}$/, '') + '-' + Math.random().toString(36).slice(2, 6);
        copy.markets = { DZ: { active: false }, SA }; copy.i18n = { SA: i18n };
        copy.soldCount = 0; copy.copiedFrom = src.id; delete copy.createdAt;
        const ref = await db.collection('products').add({ ...copy, createdAt: FV().serverTimestamp(), updatedAt: FV().serverTimestamp() });
        targetId = ref.id;
        log('product.market.copy', ref.id, { from: src.id, market: 'SA', price });
      }
      toast(mode === 'same' ? `🇸🇦 أُضيف إلى متجر السعودية بـ ${price} ر.س ✓` : '🇸🇦 أُنشئت نسخة مستقلة للسعودية ✓', 'success');
      closeModal(); await loadProducts(true); draw();
      if (openAfter) setTimeout(() => openProductEditor(targetId), 120);
    } catch (e) { toast('تعذّر: ' + (e.code || e.message), 'error'); }
  };
}

/* ─────────── CSV ─────────── */
function exportCSV() {
  downloadCSV(`nabda-products-${new Date().toISOString().slice(0, 10)}.csv`, filtered().map((p) => ({
    id: p.id, name: p.name || '', slug: p.slug || '', category: p.category || '', brand: p.brand || '', price: p.price || 0, oldPrice: p.oldPrice || '',
    stock: hasStock(p) ? p.stock : '', sku: p.sku || '', active: p.active === false ? 0 : 1, featured: p.featured ? 1 : 0, soldCount: p.soldCount || 0,
    image: img(p), description: (p.description || '').replace(/\n/g, '\\n'),
  })));
}
async function importCSV(e) {
  const file = e.target.files[0]; e.target.value = ''; if (!file) return;
  let rows;
  try { rows = parseCSV(await file.text()); } catch (_) { return toast('ملف CSV غير صالح', 'error'); }
  if (!rows.length || !('name' in rows[0]) || !('price' in rows[0])) return toast('الأعمدة المطلوبة: name, price (واختياري: id, category, brand, stock, oldPrice, sku, image, description, active)', 'error');
  const upd = rows.filter((r) => r.id && S.products.some((p) => p.id === r.id)).length;
  if (!(await confirmBox(`استيراد ${rows.length} صف: ${upd} تحديث و ${rows.length - upd} إضافة (الجديدة تُضاف مخفية للمراجعة). متابعة؟`))) return;
  let ok = 0; let banned = 0;
  for (let i = 0; i < rows.length; i += 400) {
    const batch = db.batch();
    rows.slice(i, i + 400).forEach((r) => {
      const name = r.name.trim(); if (!name) return;
      const d = { name, price: priceStr(r.price), updatedAt: FV().serverTimestamp() };
      ['category', 'brand', 'sku'].forEach((k) => { if (r[k]) d[k] = r[k]; });
      if (r.oldPrice) d.oldPrice = priceStr(r.oldPrice);
      if (r.stock !== undefined && r.stock !== '') d.stock = parseInt(r.stock, 10) || 0;
      if (r.image) { d.image = r.image; d.images = [r.image]; d.imageUrls = [r.image]; d.coverImage = r.image; d.imageUrl = r.image; }
      if (r.description) d.description = r.description.replace(/\\n/g, '\n');
      const isBanned = isHiddenProduct({ name, category: d.category });
      if (isBanned) banned++;
      const exists = r.id && S.products.some((p) => p.id === r.id);
      if (exists) { if (r.active !== undefined && r.active !== '') d.active = r.active === '1' && !isBanned; batch.set(db.collection('products').doc(r.id), d, { merge: true }); }
      else batch.set(db.collection('products').doc(), { ...d, slug: slugify(name) + '-' + Math.random().toString(36).slice(2, 6), active: false, createdAt: FV().serverTimestamp(), soldCount: 0 });
      ok++;
    });
    try { await batch.commit(); } catch (err) { toast('توقّف الاستيراد: ' + (err.code || ''), 'error'); break; }
  }
  log('product.import', file.name, { rows: ok });
  toast(`استُورد ${ok} منتج${banned ? ` (${banned} ممنوع بقي مخفياً)` : ''}`, 'success');
  await loadProducts(true); draw();
}
