/**
 * نبضة — واجهة المتجر (/shop و /shop/c/<تصنيف>)
 * تصنيفات حيّة من المنتجات، فلاتر (بحث، سعر، ماركة، توفّر، تخفيض)، فرز، كل الحالة في الـ URL،
 * مجموعات حسب المرحلة، رفوف (عروض/الأكثر مبيعاً/جديد)، مفضّلة، إضافة سريعة للسلة.
 */
import { auth, db } from '../firebase-init.js';
import { getStoreSettings } from '../store-config.js';
import { addToCart } from '../cart.js';
import { escapeHtml as esc, getVisibleProducts, productImg, productOldPrice, productUrl, formatDA, toDate, productMatchesStage } from '../utils.js';
import { M, mUrl, syncShopPath, marketEnabled, saveMarket, switchMarketUrl, getMarketsConfig } from '../market.js';

const PAGE = 16;
let all = [];
let filtered = [];
let visible = PAGE;
let currentUser = null;
let stage = null; // مجموعة حسب المرحلة المختارة
let categories = []; // [{name, slug, icon, count}]

const ICONS = [
  [/حمل|حامل|ولادة|أمومة/, '🤰'], [/رضاع|تغذي|رضّاع|ببرونة|زجاج/, '🍼'], [/ملابس|لباس|فستان|بيجام/, '👗'],
  [/لعب|ألعاب|تعليم/, '🧸'], [/استحمام|نظافة|حمام/, '🛁'], [/حفاض|حفاظ/, '🧷'], [/عناية|بشرة|تجميل|الأم/, '🌸'],
  [/نوم|سرير|غرفة/, '🛏️'], [/عرب|تنقّل|كرسي|حمّالة/, '🚼'], [/مولود|رضيع|حديث/, '👶'], [/أمان|حماية/, '🛡️'],
];
const iconFor = (n) => (ICONS.find(([re]) => re.test(n)) || [null, '🛍️'])[1];
const slugOf = (n) => String(n).trim().replace(/\s+/g, '-');

const STAGES = { pregnant: 'لكِ أثناء الحمل 🤰', newborn: 'لمولودكِ الجديد 👶', baby: 'لطفلكِ 1-3 سنوات 🧸', mom: 'العناية بالأم 🌸' };

/* ─────────── المفضّلة (محلياً + حساب المستخدمة) ─────────── */
const WKEY = 'nb_wishlist_v1';
const wish = new Set(JSON.parse(localStorage.getItem(WKEY) || '[]'));
function saveWish() { localStorage.setItem(WKEY, JSON.stringify([...wish])); }

export async function initShopPage() {
  if (syncShopPath()) return;
  const mk = M();
  const pf = [...document.querySelectorAll('.nb-filter-title')].find((x) => x.textContent.includes('السعر'));
  if (pf) pf.textContent = `السعر (${mk.symbol}):`;
  if (mk.code !== 'DZ') document.title = `متجر نبضة ${mk.flag} ${mk.name} — مستلزمات الأم والطفل`;
  if (!(await marketEnabled(db))) return comingSoon(mk);
  auth.onAuthStateChanged(async (u) => {
    currentUser = u;
    if (!u) return;
    try {
      const snap = await db.collection('users').doc(u.uid).get();
      const st = snap.exists ? snap.data().lifeStage : null;
      const map = { pregnant: 'pregnant', baby: 'newborn', planning: 'pregnant' };
      if (map[st]) document.querySelector(`[data-stage="${map[st]}"]`)?.classList.add('nb-suggested');
    } catch (_) {}
  });

  renderStageTabs();
  wireFilters();
  // شريط إعلان من الإعدادات (لوحة التحكم ← الإعدادات)
  getStoreSettings().then((st) => {
    if (!st.shopBanner) return;
    const b = document.createElement('div');
    b.textContent = st.shopBanner;
    b.style.cssText = 'background:linear-gradient(90deg,#E91E63,#F43F7E);color:#fff;text-align:center;font-weight:800;font-size:13.5px;padding:10px 14px;border-radius:14px;margin-bottom:14px';
    document.querySelector('.nb-shop-container')?.prepend(b);
  });
  showLoading();
  try {
    all = await getVisibleProducts();
  } catch (e) {
    console.error('shop load', e);
    document.getElementById('nb-products-grid').innerHTML = '<div style="grid-column:1/-1;text-align:center;padding:40px;color:var(--nb-ink-3)">تعذّر تحميل المنتجات حالياً. أعيدي تحميل الصفحة.</div>';
    return;
  }
  buildCategories();
  buildBrands();
  renderShelves();
  readUrl();
  window.addEventListener('popstate', readUrl);
}

function showLoading() {
  document.getElementById('nb-products-grid').innerHTML = Array.from({ length: 8 }, () =>
    '<div class="nb-shop-card"><div class="nb-shop-card-img-wrap nb-skeleton"></div><div class="nb-shop-card-body"><div class="nb-skeleton" style="height:14px;border-radius:6px;margin-bottom:8px"></div><div class="nb-skeleton" style="height:14px;width:60%;border-radius:6px"></div></div></div>').join('');
}

/* ─────────── التصنيفات والماركات (من المنتجات الفعلية) ─────────── */
function buildCategories() {
  const counts = {};
  all.forEach((p) => { const c = (p.category || '').trim(); if (c) counts[c] = (counts[c] || 0) + 1; });
  categories = Object.entries(counts).sort((a, b) => b[1] - a[1]).map(([name, count]) => ({ name, slug: slugOf(name), icon: iconFor(name), count }));
  const box = document.getElementById('nb-shop-cat-pills');
  box.innerHTML = [{ name: 'الكل', slug: 'all', icon: '🛍️', count: all.length }, ...categories].map((c) => `
    <a class="nb-shop-cat-pill" data-cat="${esc(c.slug)}" href="${mUrl(c.slug === 'all' ? '/shop' : '/shop/c/' + encodeURIComponent(c.slug))}">
      <span class="nb-shop-cat-icon">${c.icon}</span>
      <span class="nb-shop-cat-label">${esc(c.name)}</span>
      <span class="nb-cat-count">${c.count}</span>
    </a>`).join('');
  box.querySelectorAll('a').forEach((a) => a.addEventListener('click', (e) => {
    e.preventDefault();
    stage = null;
    setActiveCat(a.dataset.cat);
    apply(true);
    document.getElementById('nb-shop-results-sec').scrollIntoView({ behavior: 'smooth' });
  }));
}
function setActiveCat(slug) {
  document.querySelectorAll('.nb-shop-cat-pill').forEach((b) => b.classList.toggle('active', b.dataset.cat === slug));
}
function activeCat() { return document.querySelector('.nb-shop-cat-pill.active')?.dataset.cat || 'all'; }

function buildBrands() {
  const brands = [...new Set(all.map((p) => (p.brand || '').trim()).filter(Boolean))].sort();
  if (brands.length < 2) return;
  document.getElementById('nb-brand-filter-sec').style.display = 'block';
  document.getElementById('nb-brand-filters').innerHTML = brands.map((b) => `
    <label class="nb-filter-label"><input type="checkbox" class="nb-brand-cb" value="${esc(b)}"><span>${esc(b)}</span></label>`).join('');
  document.querySelectorAll('.nb-brand-cb').forEach((cb) => cb.addEventListener('change', () => apply(true)));
}

function renderStageTabs() {
  document.querySelectorAll('.nb-stage-tab-btn').forEach((btn) => {
    const m = (btn.getAttribute('onclick') || '').match(/'(\w+)'/);
    if (m) btn.dataset.stage = m[1];
    btn.removeAttribute('onclick');
    btn.addEventListener('click', () => {
      stage = stage === btn.dataset.stage ? null : btn.dataset.stage;
      document.querySelectorAll('.nb-stage-tab-btn').forEach((b) => b.classList.toggle('active', b.dataset.stage === stage));
      setActiveCat('all');
      apply(true);
      document.getElementById('nb-shop-results-sec').scrollIntoView({ behavior: 'smooth' });
    });
  });
}

/* ─────────── الرفوف ─────────── */
function shelf(id, list, secId) {
  const el = document.getElementById(id);
  if (!el) return;
  if (!list.length) { document.getElementById(secId)?.style.setProperty('display', 'none'); return; }
  el.innerHTML = list.map(card).join('');
}
function renderShelves() {
  shelf('nb-flash-deals-shelf', all.filter((p) => productOldPrice(p)).sort((a, b) => discount(b) - discount(a)).slice(0, 10), 'nb-deals-sec');
  const best = [...all].filter((p) => p.soldCount > 0).sort((a, b) => (b.soldCount || 0) - (a.soldCount || 0)).slice(0, 10);
  shelf('nb-bestsellers-shelf', best.length >= 3 ? best : all.filter((p) => p.featured).slice(0, 10), 'nb-best-sec');
  shelf('nb-new-shelf', all.slice(0, 10), 'nb-new-sec');
}
const discount = (p) => { const o = productOldPrice(p); return o ? 1 - Number(p.price) / o : 0; };
const hasStock = (p) => typeof p.stock !== 'number' || p.stock > 0;

/* ─────────── الفلاتر ─────────── */
function wireFilters() {
  let t;
  document.getElementById('nb-shop-search-input')?.addEventListener('input', () => { clearTimeout(t); t = setTimeout(() => apply(true, true), 300); });
  ['nb-shop-sort-select', 'nb-filter-stock', 'nb-filter-discount'].forEach((id) => document.getElementById(id)?.addEventListener('change', () => apply(true)));
  ['nb-price-min', 'nb-price-max'].forEach((id) => document.getElementById(id)?.addEventListener('change', () => apply(true)));
  document.getElementById('nb-shop-load-more')?.addEventListener('click', () => { visible += PAGE; renderGrid(); });
  const panel = document.querySelector('.nb-shop-filters');
  document.getElementById('nb-open-filters')?.addEventListener('click', () => panel.classList.toggle('open'));
  document.addEventListener('click', (e) => { if (panel?.classList.contains('open') && !panel.contains(e.target) && e.target.id !== 'nb-open-filters') panel.classList.remove('open'); });
}

function readUrl() {
  const m = location.pathname.match(/\/shop\/c\/([^/?#]+)/);
  const q = new URLSearchParams(location.search);
  let cat = m ? decodeURIComponent(m[1]) : (q.get('cat') || 'all');
  // دعم الروابط القديمة ?cat=pregnancy / baby من الفوتر
  if (cat !== 'all' && !categories.some((c) => c.slug === cat)) {
    const legacy = { pregnancy: 'pregnant', baby: 'newborn', newborn: 'newborn', mom: 'mom', toys: 'baby' };
    if (legacy[cat]) stage = legacy[cat];
    const byName = categories.find((c) => c.name === cat);
    cat = byName ? byName.slug : 'all';
  }
  if (q.get('stage') && STAGES[q.get('stage')]) stage = q.get('stage');
  setActiveCat(cat);
  document.querySelectorAll('.nb-stage-tab-btn').forEach((b) => b.classList.toggle('active', b.dataset.stage === stage));
  document.getElementById('nb-shop-search-input').value = q.get('q') || '';
  document.getElementById('nb-shop-sort-select').value = q.get('sort') || 'newest';
  document.getElementById('nb-filter-stock').checked = q.get('inStock') === '1';
  document.getElementById('nb-filter-discount').checked = q.get('discount') === '1';
  document.getElementById('nb-price-min').value = q.get('min') || '';
  document.getElementById('nb-price-max').value = q.get('max') || '';
  const brands = (q.get('brand') || '').split(',').filter(Boolean);
  document.querySelectorAll('.nb-brand-cb').forEach((cb) => { cb.checked = brands.includes(cb.value); });
  apply(false);
  if (cat !== 'all' || location.search) document.title = `${categories.find((c) => c.slug === cat)?.name || 'المتجر'} — متجر نبضة للأم والطفل`;
}

function apply(updateUrl, replace = false) {
  const q = document.getElementById('nb-shop-search-input').value.trim().toLowerCase();
  const cat = activeCat();
  const sort = document.getElementById('nb-shop-sort-select').value;
  const inStock = document.getElementById('nb-filter-stock').checked;
  const disc = document.getElementById('nb-filter-discount').checked;
  const min = Number(document.getElementById('nb-price-min').value) || 0;
  const max = Number(document.getElementById('nb-price-max').value) || 0;
  const brands = [...document.querySelectorAll('.nb-brand-cb:checked')].map((c) => c.value);
  const catName = categories.find((c) => c.slug === cat)?.name;

  filtered = all.filter((p) => {
    if (q && !`${p.name || ''} ${p.brand || ''} ${p.category || ''} ${p.description || ''}`.toLowerCase().includes(q)) return false;
    if (cat !== 'all' && (p.category || '').trim() !== catName) return false;
    if (stage && !productMatchesStage(p, stage)) return false;
    if (inStock && !hasStock(p)) return false;
    if (disc && !productOldPrice(p)) return false;
    const price = Number(p.price || 0);
    if (min && price < min) return false;
    if (max && price > max) return false;
    if (brands.length && !brands.includes((p.brand || '').trim())) return false;
    return true;
  });

  const by = {
    price_asc: (a, b) => a.price - b.price,
    price_desc: (a, b) => b.price - a.price,
    best_seller: (a, b) => (b.soldCount || 0) - (a.soldCount || 0),
    top_rated: (a, b) => (b.rating || 0) * Math.log1p(b.reviewCount || 0) - (a.rating || 0) * Math.log1p(a.reviewCount || 0),
    newest: (a, b) => (toDate(b.createdAt)?.getTime() || 0) - (toDate(a.createdAt)?.getTime() || 0),
  };
  filtered.sort(by[sort] || by.newest);
  // المتوفّر قبل النافد دائماً
  filtered.sort((a, b) => Number(hasStock(b)) - Number(hasStock(a)));

  visible = PAGE;
  renderGrid();

  const label = [catName, stage && STAGES[stage]].filter(Boolean).join(' • ');
  document.getElementById('nb-products-count').textContent = `${filtered.length} منتج${label ? ' — ' + label : ''}`;

  if (updateUrl) {
    const p = new URLSearchParams();
    if (q) p.set('q', q);
    if (stage) p.set('stage', stage);
    if (sort !== 'newest') p.set('sort', sort);
    if (inStock) p.set('inStock', '1');
    if (disc) p.set('discount', '1');
    if (min) p.set('min', min);
    if (max) p.set('max', max);
    if (brands.length) p.set('brand', brands.join(','));
    const base = mUrl(cat === 'all' ? '/shop' : '/shop/c/' + encodeURIComponent(cat));
    const url = base + (p.toString() ? '?' + p : '');
    if (url !== location.pathname + location.search) history[replace ? 'replaceState' : 'pushState'](null, '', url);
  }
}

function renderGrid() {
  const grid = document.getElementById('nb-products-grid');
  const more = document.getElementById('nb-shop-load-more');
  if (!filtered.length) {
    grid.innerHTML = `
      <div style="grid-column:1/-1;text-align:center;padding:60px 20px;background:#FFF9FC;border-radius:24px;border:1px dashed #F8BBD0">
        <div style="font-size:48px;margin-bottom:12px">🔍</div>
        <h3 style="font-size:18px;font-weight:900;color:var(--nb-ink);margin-bottom:6px">لا توجد منتجات مطابقة</h3>
        <p style="font-size:13.5px;color:var(--nb-ink-3);margin-bottom:18px">جرّبي كلمات أخرى أو ألغي بعض الفلاتر.</p>
        <button class="nb-btn-secondary" onclick="window.resetShopFilters()">إعادة ضبط الفلاتر</button>
      </div>`;
    more.style.display = 'none';
    return;
  }
  grid.innerHTML = filtered.slice(0, visible).map(card).join('');
  more.style.display = visible < filtered.length ? 'inline-block' : 'none';
  more.textContent = `عرض المزيد (${filtered.length - visible}) ⬇️`;
}

function card(p) {
  const img = productImg(p);
  const img2 = (p.images && p.images[1]) || (p.imageUrls && p.imageUrls[1]) || null;
  const old = productOldPrice(p);
  const off = old ? Math.round((1 - p.price / old) * 100) : 0;
  const out = !hasStock(p);
  const low = typeof p.stock === 'number' && p.stock > 0 && p.stock <= 5;
  const rating = Number(p.rating || 0);
  const rc = Number(p.reviewCount || 0);
  return `
    <article class="nb-shop-card" data-id="${esc(p.id)}">
      <a href="${productUrl(p)}" class="nb-shop-card-img-wrap" aria-label="${esc(p.name)}">
        <img src="${esc(img)}" alt="${esc(p.name)}" class="nb-shop-img primary" loading="lazy">
        ${img2 ? `<img src="${esc(img2)}" alt="" class="nb-shop-img secondary" loading="lazy">` : ''}
        ${off ? `<span class="nb-discount-badge">-${off}%</span>` : ''}
        ${p.badge ? `<span class="nb-urgency-badge" style="background:#00897B">${esc(p.badge)}</span>` : (low ? `<span class="nb-urgency-badge">بقي ${p.stock} فقط!</span>` : '')}
        ${out ? '<span class="nb-out-badge">نفد مؤقتاً</span>' : ''}
      </a>
      <button class="nb-wish-heart ${wish.has(p.id) ? 'on' : ''}" data-wish="${esc(p.id)}" title="المفضّلة" aria-label="أضيفي إلى المفضّلة">♥</button>
      <div class="nb-shop-card-body">
        <div>
          <div style="font-size:11px;color:var(--nb-pink);font-weight:800;margin-bottom:4px">${esc(p.brand || p.category || '')}</div>
          <a href="${productUrl(p)}" style="text-decoration:none"><h3 class="nb-shop-card-title">${esc(p.name)}</h3></a>
          ${rating && rc ? `<div style="display:flex;align-items:center;gap:4px;margin-bottom:8px"><span style="color:#FFB300;font-size:12px">★</span><span style="font-size:12px;font-weight:800;color:var(--nb-ink)">${rating.toFixed(1)}</span><span style="font-size:11px;color:var(--nb-ink-3)">(${rc})</span></div>` : ''}
        </div>
        <div>
          <div class="nb-shop-price-row">
            <span class="nb-shop-price">${formatDA(p.price)}</span>
            ${old ? `<span class="nb-shop-old-price">${formatDA(old)}</span>` : ''}
          </div>
          ${out
            ? `<a href="${productUrl(p)}" class="nb-btn-secondary" style="display:block;text-align:center;width:100%;font-size:12px;padding:7px;text-decoration:none">أعلميني عند التوفّر 🔔</a>`
            : (Array.isArray(p.variants) && p.variants.some((v) => (v.options || []).length > 1)
              ? `<a href="${productUrl(p)}" class="nb-btn-primary" style="display:block;text-align:center;width:100%;font-size:12.5px;padding:7px 12px;text-decoration:none">اختاري المقاس ←</a>`
              : `<button class="nb-btn-primary" data-add="${esc(p.id)}" style="width:100%;font-size:12.5px;padding:7px 12px;border:none;cursor:pointer">أضيفي للسلة 🛒</button>`)}
        </div>
      </div>
    </article>`;
}

// تفويض أحداث واحد لكل البطاقات (الشبكة والرفوف)
document.addEventListener('click', async (e) => {
  const add = e.target.closest('[data-add]');
  if (add) {
    const p = all.find((x) => x.id === add.dataset.add);
    if (!p) return;
    addToCart({ productId: p.id, slug: p.slug || p.id, name: p.name, image: productImg(p), price: Number(p.price || 0), oldPrice: productOldPrice(p), variant: '', qty: 1 });
    window.nbToast?.('أُضيف إلى السلة 🛒', 'success');
    window.nbOpenCart?.();
    return;
  }
  const w = e.target.closest('[data-wish]');
  if (w) {
    const id = w.dataset.wish;
    const on = !wish.has(id);
    on ? wish.add(id) : wish.delete(id);
    saveWish();
    document.querySelectorAll(`[data-wish="${CSS.escape(id)}"]`).forEach((b) => b.classList.toggle('on', on));
    window.nbToast?.(on ? 'أُضيف إلى المفضّلة 💗' : 'أُزيل من المفضّلة');
    if (currentUser) {
      const ref = db.collection('users').doc(currentUser.uid).collection('favorites').doc('product_' + id);
      try { on ? await ref.set({ type: 'product', productId: id, savedAt: window.firebase.firestore.FieldValue.serverTimestamp() }) : await ref.delete(); } catch (_) {}
    }
  }
});

window.resetShopFilters = function () {
  stage = null;
  history.pushState(null, '', mUrl('/shop'));
  readUrl();
};

/** سوق غير مفعّل بعد (مثلاً السعودية قبل تسعير المنتجات): لا نعرض أسعار سوق آخر أبداً */
async function comingSoon(mk) {
  const cfg = (await getMarketsConfig(db))?.[mk.code] || {};
  ['nb-deals-sec', 'nb-best-sec', 'nb-new-sec'].forEach((id) => document.getElementById(id)?.style.setProperty('display', 'none'));
  document.getElementById('nb-shop-cat-pills')?.style.setProperty('display', 'none');
  document.querySelector('.nb-shop-filters')?.style.setProperty('display', 'none');
  document.getElementById('nb-products-count').textContent = '';
  document.getElementById('nb-shop-load-more').style.display = 'none';
  document.getElementById('nb-products-grid').innerHTML = `
    <div style="grid-column:1/-1;text-align:center;padding:56px 22px;background:#FFF9FC;border-radius:28px;border:1px dashed #F8BBD0">
      <div style="font-size:54px;margin-bottom:10px">${mk.flag}</div>
      <h2 style="font-size:22px;font-weight:900;color:var(--nb-ink);margin-bottom:8px">متجر نبضة قادم إلى ${esc(mk.name)} قريباً 💗</h2>
      <p style="font-size:14.5px;color:var(--nb-ink-3);line-height:1.9;max-width:560px;margin:0 auto 20px">${esc(cfg.comingSoonText || 'نجهّز لكِ منتجات مختارة بأسعار بالعملة المحلية وتوصيل إلى باب بيتكِ. في الأثناء، موسوعة نبضة ومجتمع الأمهات متاحان لكِ بالكامل.')}</p>
      <div style="display:flex;gap:10px;justify-content:center;flex-wrap:wrap">
        <a href="/articles" class="nb-btn-primary" style="text-decoration:none">📚 موسوعة نبضة</a>
        <a href="/community" class="nb-btn-secondary" style="text-decoration:none">💬 مجتمع الأمهات</a>
        <a href="${switchMarketUrl('DZ')}" id="nb-mk-dz" data-mk-keep class="nb-btn-secondary" style="text-decoration:none">🇩🇿 التسوّق والتوصيل داخل الجزائر</a>
      </div>
    </div>`;
  document.getElementById('nb-mk-dz').addEventListener('click', () => saveMarket('DZ'));
}
