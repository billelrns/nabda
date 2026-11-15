/**
 * نبضة — صفحة المنتج المستقلّة (/product/<slug>)
 * معرض + تكبير، متغيّرات، طلب COD مباشر، سلة، واتساب، تبويبات، مشابهة، شاهدتِها مؤخراً، SEO
 */
import { auth, db } from '../firebase-init.js';
import { isHiddenProduct } from '../shop-rules.js';
import { addToCart } from '../cart.js';
import { escapeHtml as esc, getVisibleProducts, productCardHtml, productImg, productImages, productOldPrice, formatDA, toDate } from '../utils.js';
import { getShippingRates, shippingFeeFor, wilayaEnabled, getStoreSettings, whatsappLink } from '../store-config.js';
import { M, currentMarket, mUrl, syncShopPath, marketEnabled, mAvailable, localize, normPhoneFor, validPhoneFor, intlPhone, SA_REGIONS } from '../market.js';

let currentUser = null;
let product = null;
let images = [];
let imgIndex = 0;
let qty = 1;
let selected = {}; // { 'المقاس': 'M' }
let cities = null;
let rates = {};
let settings = {};
let raw = null; // المنتج كما في Firestore (قبل التوطين) — لروابط hreflang

auth.onAuthStateChanged((u) => { currentUser = u; });

export async function initProductPage() {
  if (syncShopPath()) return;
  const slug = slugFromUrl();
  const [rr, ss] = await Promise.all([getShippingRates(), getStoreSettings(), loadCities()]);
  rates = rr; settings = ss;
  if (!slug) return notFound();
  try {
    raw = await fetchProduct(slug);
  } catch (e) {
    console.error('product fetch', e);
  }
  // غير موجود، معطّل، ممنوع (مكمّلات/أجهزة طبية)، أو غير مسعّر في هذا السوق → صفحة بديلة
  if (!raw || isHiddenProduct(raw) || !mAvailable(raw) || !(await marketEnabled(db))) return notFound();
  product = localize(raw);

  // الرابط الرسمي بالـ slug (إن فُتح بالمعرّف)
  if (product.slug && slug !== product.slug) {
    history.replaceState(null, '', mUrl('/product/' + encodeURIComponent(product.slug)) + location.search);
  }
  render();
  wireForm();
  wireTabs();
  saveRecent();
  loadSimilar();
  renderRecent();
  seo();
}

function slugFromUrl() {
  const m = location.pathname.match(/\/product\/([^/?#]+)/);
  if (m) return decodeURIComponent(m[1]);
  const q = new URLSearchParams(location.search);
  return q.get('slug') || q.get('id');
}

async function fetchProduct(slug) {
  const snap = await db.collection('products').where('slug', '==', slug).limit(1).get();
  if (!snap.empty) { const d = snap.docs[0]; return { id: d.id, ...d.data() }; }
  const doc = await db.collection('products').doc(slug).get();
  return doc.exists ? { id: doc.id, ...doc.data() } : null;
}

async function notFound() {
  document.getElementById('nb-product-view-container').style.display = 'none';
  document.getElementById('nb-product-not-found').style.display = 'block';
  document.title = 'المنتج غير متوفّر — متجر نبضة';
  const meta = document.createElement('meta'); meta.name = 'robots'; meta.content = 'noindex'; document.head.appendChild(meta);
  try {
    const list = (await getVisibleProducts()).slice(0, 8);
    document.getElementById('nb-alt-products-grid').innerHTML = list.map(productCardHtml).join('');
  } catch (_) {}
}

/* ─────────────── العرض ─────────────── */
function hasStockField(p) { return typeof p.stock === 'number'; }
function inStock(p) { return !hasStockField(p) || p.stock > 0; }

function render() {
  const p = product;
  const cat = p.category || 'المتجر';
  const bc = document.getElementById('nb-bc-category');
  bc.textContent = cat; bc.href = mUrl('/shop?cat=' + encodeURIComponent(cat));
  document.getElementById('nb-bc-title').textContent = p.name;
  document.getElementById('nb-p-title').textContent = p.name;
  document.getElementById('nb-p-brand').textContent = p.brand ? p.brand : cat;

  const rating = Number(p.rating || 0);
  const rc = Number(p.reviewCount || 0);
  document.getElementById('nb-p-rating').innerHTML = rating
    ? `<span class="nb-stars">${'★'.repeat(Math.round(rating))}${'☆'.repeat(5 - Math.round(rating))}</span> ${rating.toFixed(1)} ${rc ? `(${rc} تقييم)` : ''}`
    : '';
  if (p.soldCount > 10) document.getElementById('nb-p-sold').textContent = `🔥 بيع ${p.soldCount}+ قطعة`;

  const price = Number(p.price || 0);
  const old = productOldPrice(p);
  document.getElementById('nb-p-price').textContent = formatDA(price);
  if (old) {
    const o = document.getElementById('nb-p-old-price'); o.textContent = formatDA(old); o.style.display = 'inline-block';
    const b = document.getElementById('nb-p-savings-badge');
    b.textContent = `وفّري ${formatDA(old - price)} (-${Math.round((1 - price / old) * 100)}%)`; b.style.display = 'inline-block';
    const g = document.getElementById('nb-gal-badge'); g.textContent = `-${Math.round((1 - price / old) * 100)}%`; g.style.display = 'inline-block';
  }

  const st = document.getElementById('nb-p-stock-badge');
  if (!inStock(p)) {
    st.textContent = 'نفد مؤقتاً'; st.style.background = '#FCE4EC'; st.style.color = '#C2185B';
    const box = document.getElementById('nb-oos-box');
    box.innerHTML = 'هذا المنتج نفد حالياً. <a href="#" id="nb-notify-link" style="color:#C2185B;font-weight:900">أعلميني عند توفّره ←</a>';
    box.style.display = 'block';
    document.getElementById('nb-cod-form').style.display = 'none';
    document.getElementById('nb-add-cart-btn').disabled = true;
    document.getElementById('nb-notify-link')?.addEventListener('click', (e) => { e.preventDefault(); notifyMe(); });
  } else if (hasStockField(p) && p.stock <= 5) {
    st.textContent = `بقي ${p.stock} فقط!`; st.style.background = '#FFF3E0'; st.style.color = '#E65100';
  } else {
    st.textContent = 'متوفّر ✓'; st.style.background = '#E8F5E9'; st.style.color = '#2E7D32';
  }

  images = productImages(p);
  renderGallery();
  renderVariants();
  renderDescription();
  renderSpecs();
  renderReviews();
  if (settings.returnPolicy || settings.shippingPolicy) {
    document.getElementById('nb-custom-policy').innerHTML = paragraphs([settings.shippingPolicy, settings.returnPolicy].filter(Boolean).join('\n\n'));
  }
  if (whatsappLink(settings, 'x')) document.getElementById('nb-wa-btn').style.display = 'block';

  document.getElementById('nb-sticky-thumb').src = images[0];
  document.getElementById('nb-sticky-price').textContent = formatDA(price);
  document.getElementById('nb-sticky-buy-bar').style.display = inStock(p) ? 'flex' : 'none';
  updateTotals();
}

function renderGallery() {
  const main = document.getElementById('nb-main-img');
  main.src = images[imgIndex]; main.alt = product.name;
  const strip = document.getElementById('nb-gallery-thumbs');
  if (images.length <= 1) { strip.style.display = 'none'; return; }
  strip.innerHTML = images.map((src, i) => `
    <button class="nb-thumb-btn ${i === imgIndex ? 'active' : ''}" data-i="${i}" aria-label="الصورة ${i + 1}">
      <img src="${esc(src)}" alt="" class="nb-thumb-img" loading="lazy">
    </button>`).join('');
  strip.querySelectorAll('.nb-thumb-btn').forEach((b) => b.addEventListener('click', () => { imgIndex = +b.dataset.i; renderGallery(); }));
  // سحب على الهاتف
  const wrap = document.getElementById('nb-main-img-wrap');
  if (!wrap.dataset.swipe) {
    wrap.dataset.swipe = 1;
    let x0 = null;
    wrap.addEventListener('touchstart', (e) => { x0 = e.touches[0].clientX; }, { passive: true });
    wrap.addEventListener('touchend', (e) => {
      if (x0 === null) return; const dx = e.changedTouches[0].clientX - x0; x0 = null;
      if (Math.abs(dx) > 40) { imgIndex = (imgIndex + (dx > 0 ? 1 : -1) + images.length) % images.length; renderGallery(); }
    });
  }
}

window.nbOpenLightbox = () => { document.getElementById('nb-lightbox-img').src = images[imgIndex]; document.getElementById('nb-lightbox').classList.add('open'); };
window.nbCloseLightbox = () => document.getElementById('nb-lightbox').classList.remove('open');
window.nbLightboxStep = (d) => { imgIndex = (imgIndex + d + images.length) % images.length; document.getElementById('nb-lightbox-img').src = images[imgIndex]; renderGallery(); };
document.addEventListener('keydown', (e) => {
  if (!document.getElementById('nb-lightbox')?.classList.contains('open')) return;
  if (e.key === 'Escape') window.nbCloseLightbox();
  if (e.key === 'ArrowLeft') window.nbLightboxStep(1);
  if (e.key === 'ArrowRight') window.nbLightboxStep(-1);
});

function renderVariants() {
  const box = document.getElementById('nb-p-variants-box');
  const vs = Array.isArray(product.variants) ? product.variants.filter((v) => v && (v.options || []).length) : [];
  if (!vs.length) { box.style.display = 'none'; return; }
  box.innerHTML = vs.map((v, vi) => `
    <div style="margin-bottom:12px">
      <div style="font-size:12.5px;font-weight:800;color:var(--nb-ink);margin-bottom:6px">${esc(v.label || 'الخيار')}: <span id="nb-vsel-${vi}" style="color:var(--nb-pink)">${esc(v.options[0])}</span></div>
      <div style="display:flex;gap:8px;flex-wrap:wrap">
        ${v.options.map((o, oi) => `<button type="button" class="nb-variant-btn ${oi === 0 ? 'active' : ''}" data-vi="${vi}" data-oi="${oi}">${esc(o)}</button>`).join('')}
      </div>
    </div>`).join('');
  vs.forEach((v) => { selected[v.label || 'الخيار'] = v.options[0]; });
  box.querySelectorAll('.nb-variant-btn').forEach((b) => b.addEventListener('click', () => {
    const v = vs[+b.dataset.vi]; const o = v.options[+b.dataset.oi];
    selected[v.label || 'الخيار'] = o;
    b.parentElement.querySelectorAll('.nb-variant-btn').forEach((x) => x.classList.remove('active'));
    b.classList.add('active');
    document.getElementById('nb-vsel-' + b.dataset.vi).textContent = o;
  }));
}
function variantText() { return Object.entries(selected).map(([k, v]) => `${k}: ${v}`).join(' • '); }

/** نص الوصف آمن: فقرات + قوائم (أسطر تبدأ بـ - أو •) + **غامق** */
function paragraphs(text) {
  const blocks = String(text || '').replace(/\r/g, '').split(/\n{2,}/);
  return blocks.map((b) => {
    const lines = b.split('\n').filter((l) => l.trim());
    if (lines.length && lines.every((l) => /^\s*[-•*]\s+/.test(l))) {
      return '<ul>' + lines.map((l) => `<li>${fmt(l.replace(/^\s*[-•*]\s+/, ''))}</li>`).join('') + '</ul>';
    }
    return `<p>${lines.map(fmt).join('<br>')}</p>`;
  }).join('');
}
function fmt(s) { return esc(s).replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>'); }

function renderDescription() {
  const d = product.description || product.desc || '';
  document.getElementById('nb-p-desc-content').innerHTML = d ? paragraphs(d) : '<p>منتج مختار بعناية لكِ ولطفلكِ من متجر نبضة.</p>';
}

function renderSpecs() {
  const rows = [];
  if (product.brand) rows.push(['الماركة', product.brand]);
  if (product.category) rows.push(['القسم', product.category]);
  if (product.sku) rows.push(['رمز المنتج', product.sku]);
  if (product.specs && typeof product.specs === 'object') Object.entries(product.specs).forEach(([k, v]) => rows.push([k, v]));
  (product.variants || []).forEach((v) => v && v.options && rows.push([v.label || 'الخيارات', v.options.join('، ')]));
  const t = document.getElementById('nb-spec-table');
  t.innerHTML = rows.length ? rows.map(([k, v]) => `<tr><td>${esc(k)}</td><td>${esc(v)}</td></tr>`).join('') : '<tr><td colspan="2">لا توجد مواصفات إضافية.</td></tr>';
}

function renderReviews() {
  const box = document.getElementById('nb-reviews-box');
  const list = Array.isArray(product.reviews) ? product.reviews : [];
  const rating = Number(product.rating || 0);
  const rc = Number(product.reviewCount || list.length || 0);
  document.getElementById('nb-tab-reviews-btn').textContent = `التقييمات${rc ? ` (${rc})` : ''}`;
  box.innerHTML = `
    ${rating ? `<div class="nb-rating-summary"><div class="nb-rating-big">${rating.toFixed(1)}</div><div><div class="nb-stars" style="font-size:20px">${'★'.repeat(Math.round(rating))}${'☆'.repeat(5 - Math.round(rating))}</div><div style="font-size:13px;color:var(--nb-ink-3)">${rc} تقييم</div></div></div>` : ''}
    ${list.length ? list.slice(0, 20).map((r) => `
      <div class="nb-review">
        <div style="display:flex;justify-content:space-between;align-items:center"><strong style="color:var(--nb-ink)">${esc(r.name || 'زبونة نبضة')}</strong><span class="nb-stars">${'★'.repeat(Math.max(1, Math.min(5, Math.round(r.rating || 5))))}</span></div>
        <p style="margin:6px 0 0">${esc(r.text || r.comment || '')}</p>
      </div>`).join('') : '<p>لا توجد تقييمات مكتوبة بعد. كوني أول من يقيّم هذا المنتج بعد استلامه 🌸</p>'}`;
}

function wireTabs() {
  document.querySelectorAll('.nb-tab-btn').forEach((b) => b.addEventListener('click', () => {
    document.querySelectorAll('.nb-tab-btn').forEach((x) => x.classList.remove('active'));
    document.querySelectorAll('.nb-tab-panel').forEach((x) => x.classList.remove('active'));
    b.classList.add('active');
    document.getElementById('tab-' + b.dataset.tab).classList.add('active');
  }));
}

/* ─────────────── نموذج الطلب ─────────────── */
async function loadCities() {
  if (currentMarket() !== 'DZ') { cities = { wilayas: [], communes: [] }; return; }
  try { cities = await (await fetch('/data/algeria_cities.json')).json(); } catch (_) { cities = { wilayas: [], communes: [] }; }
}

/** حقول العنوان حسب السوق: السعودية = المناطق + مدينة نصّية، بلا استلام من مكتب */
function adaptFormToMarket() {
  const mk = M();
  if (mk.code === 'DZ') return;
  const lab = (id) => document.querySelector(`label[for="${id}"]`);
  lab('nb-cod-wilaya').textContent = mk.regionLabel + ' *';
  lab('nb-cod-commune').textContent = mk.cityLabel;
  lab('nb-cod-phone').textContent = mk.phoneLabel + ' *';
  document.getElementById('err-wilaya').textContent = 'اختاري ' + mk.regionLabel;
  document.getElementById('err-phone').textContent = 'رقم جوال سعودي من 10 أرقام يبدأ بـ 05';
  document.getElementById('nb-cod-phone').placeholder = mk.phoneHint;
  document.getElementById('nb-cod-name').placeholder = 'مثال: نورة العتيبي';
  const old = document.getElementById('nb-cod-commune');
  const inp = document.createElement('input');
  inp.type = 'text'; inp.id = 'nb-cod-commune'; inp.className = old.className; inp.placeholder = 'مثال: جدة — حي الروضة'; inp.maxLength = 80; inp.autocomplete = 'address-level2';
  old.replaceWith(inp);
  const office = document.querySelector('input[name="deliveryType"][value="office"]');
  if (office) office.closest('label').style.display = 'none';
  document.getElementById('nb-cod-shipping').textContent = 'اختاري ' + mk.regionLabel;
}

function wireForm() {
  adaptFormToMarket();
  const ws = document.getElementById('nb-cod-wilaya');
  if (currentMarket() !== 'DZ') {
    ws.innerHTML = `<option value="">— ${M().regionLabel} —</option>` + SA_REGIONS.filter((r) => wilayaEnabled(rates, r)).map((r) => `<option value="${esc(r)}">${esc(r)}</option>`).join('');
  } else {
  ws.innerHTML = '<option value="">— الولاية —</option>' + (cities.wilayas || [])
    .filter((w) => wilayaEnabled(rates, w.wilaya_name_arabic))
    .map((w) => `<option value="${esc(w.wilaya_name_arabic)}" data-id="${w.wilaya_id}">${w.wilaya_id} - ${esc(w.wilaya_name_arabic)}</option>`).join('');
  }
  ws.addEventListener('change', () => {
    const id = parseInt(ws.options[ws.selectedIndex]?.dataset?.id, 10);
    const cs = document.getElementById('nb-cod-commune');
    if (cs.tagName !== 'SELECT') { clearErr('wilaya'); updateTotals(); return; }
    const list = (cities.communes || []).filter((c) => c.wilaya_id === id);
    cs.innerHTML = '<option value="">— البلدية —</option>' + list.map((c) => {
      const n = c.commune_name_arabic || c.commune_name_latin; return `<option value="${esc(n)}">${esc(n)}</option>`;
    }).join('');
    clearErr('wilaya');
    updateTotals();
  });
  document.querySelectorAll('input[name="deliveryType"]').forEach((r) => r.addEventListener('change', updateTotals));
  document.getElementById('nb-cod-name').addEventListener('input', () => clearErr('name'));
  document.getElementById('nb-cod-phone').addEventListener('input', () => clearErr('phone'));
  // تعبئة تلقائية من آخر طلب
  try {
    const last = JSON.parse(localStorage.getItem('nb_last_customer' + (currentMarket() === 'DZ' ? '' : '_' + currentMarket())) || 'null');
    if (last) {
      document.getElementById('nb-cod-name').value = last.name || '';
      document.getElementById('nb-cod-phone').value = last.phone || '';
      document.getElementById('nb-cod-address').value = last.address || '';
      if (last.wilaya) { ws.value = last.wilaya; ws.dispatchEvent(new Event('change')); document.getElementById('nb-cod-commune').value = last.commune || ''; }
    }
  } catch (_) {}
}

function isHome() { return document.querySelector('input[name="deliveryType"]:checked')?.value !== 'office'; }
function currentShipping() { return shippingFeeFor(rates, document.getElementById('nb-cod-wilaya').value, isHome()); }

function updateTotals() {
  if (!product) return;
  const sub = Number(product.price || 0) * qty;
  const wil = document.getElementById('nb-cod-wilaya')?.value;
  const ship = wil ? currentShipping() : 0;
  document.getElementById('nb-cod-subtotal').textContent = formatDA(sub);
  document.getElementById('nb-cod-shipping').textContent = wil ? formatDA(ship) : 'اختاري ' + M().regionLabel;
  document.getElementById('nb-cod-total').textContent = formatDA(sub + ship);
}

window.changeQuantity = function (d) {
  const max = hasStockField(product || {}) ? Math.max(1, product.stock) : 50;
  qty = Math.min(max, Math.max(1, qty + d));
  document.getElementById('nb-qty-val').textContent = qty;
  updateTotals();
};

function showErr(k) { document.getElementById('err-' + k).style.display = 'block'; document.getElementById('nb-cod-' + k).classList.add('nb-field-error'); }
function clearErr(k) { document.getElementById('err-' + k).style.display = 'none'; document.getElementById('nb-cod-' + k).classList.remove('nb-field-error'); }
export function normalizePhone(v) { return normPhoneFor(v); }

let submitting = false;
window.submitDirectCodOrder = async function () {
  if (!product || submitting) return;
  const name = document.getElementById('nb-cod-name').value.trim();
  const phone = normalizePhone(document.getElementById('nb-cod-phone').value);
  const wilaya = document.getElementById('nb-cod-wilaya').value;
  const commune = document.getElementById('nb-cod-commune').value;
  const address = document.getElementById('nb-cod-address').value.trim();
  let ok = true;
  if (name.length < 2) { showErr('name'); ok = false; }
  if (!validPhoneFor(phone)) { showErr('phone'); ok = false; }
  if (!wilaya) { showErr('wilaya'); ok = false; }
  if (!ok) { document.querySelector('.nb-field-error')?.focus(); return; }

  submitting = true;
  const btn = document.getElementById('nb-cod-submit-btn');
  btn.disabled = true; btn.textContent = 'جاري تأكيد طلبيتكِ… ⏳';
  const unitPrice = Number(product.price || 0);
  const shippingFee = currentShipping();
  const order = {
    userId: currentUser ? currentUser.uid : null,
    source: 'website',
    status: 'pending',
    customerName: name.slice(0, 110),
    customerPhone: phone,
    wilaya,
    commune: commune || '',
    address: address || '',
    deliveryType: isHome() ? 'home' : 'office',
    country: currentMarket(),
    currency: M().currency,
    phoneIntl: intlPhone(phone),
    productId: product.id,
    productName: product.name,
    productImage: images[0] || '',
    quantity: qty,
    unitPrice,
    shippingFee,
    lineTotal: unitPrice * qty + shippingFee,
    variant: variantText(),
    cartId: 'cod_' + Date.now().toString(36) + Math.random().toString(36).slice(2, 6),
    cartSize: 1,
    referrer: document.referrer ? document.referrer.slice(0, 200) : '',
    createdAt: window.firebase.firestore.FieldValue.serverTimestamp(),
  };
  try {
    const ref = await db.collection('orders').add(order);
    localStorage.setItem('nb_last_customer' + (currentMarket() === 'DZ' ? '' : '_' + currentMarket()), JSON.stringify({ name, phone, wilaya, commune, address }));
    thankYou({ id: ref.id, total: order.lineTotal, phone });
  } catch (err) {
    console.error('order error', err);
    window.nbToast?.('تعذّر إرسال الطلب، تحقّقي من الاتصال وحاولي مجدداً', 'error');
    btn.disabled = false; btn.textContent = 'تأكيد الطلب — الدفع عند الاستلام';
  } finally { submitting = false; }
};

function thankYou(info) {
  const code = info.id.slice(-6).toUpperCase();
  const wa = whatsappLink(settings, `مرحباً متجر نبضة، طلبي رقم #${code} — ${product.name}`);
  const c = document.getElementById('nb-product-view-container');
  c.innerHTML = `
    <div style="background:#fff;border:1px solid #C8E6C9;border-radius:28px;padding:48px 28px;text-align:center;max-width:680px;margin:30px auto;box-shadow:0 16px 40px rgba(0,137,123,.1)">
      <div style="font-size:56px;margin-bottom:14px">🎉</div>
      <h1 style="font-size:26px;font-weight:900;color:var(--nb-ink);margin:0 0 10px">تم تسجيل طلبكِ بنجاح!</h1>
      <p style="font-size:15px;color:var(--nb-ink-2);line-height:1.8;margin-bottom:22px">
        رقم الطلب: <strong style="color:var(--nb-pink)">#${code}</strong><br>
        سنتّصل بكِ على <strong dir="ltr">${esc(info.phone)}</strong> لتأكيد العنوان وموعد التوصيل.
      </p>
      <div style="background:#F1F8E9;border:1px solid #C8E6C9;border-radius:18px;padding:16px;margin-bottom:26px;font-size:15px;color:#2E7D32;font-weight:900">المبلغ عند الاستلام: ${formatDA(info.total)}</div>
      <div style="display:flex;gap:12px;justify-content:center;flex-wrap:wrap">
        ${wa ? `<a href="${wa}" target="_blank" rel="noopener" class="nb-btn-primary" style="background:#25D366;text-decoration:none;padding:12px 22px">💬 تابعي طلبكِ عبر واتساب</a>` : ''}
        <a href="${mUrl('/shop')}" class="nb-btn-secondary" style="text-decoration:none;padding:12px 22px">مواصلة التسوّق 🛍️</a>
      </div>
    </div>
    <section style="margin:30px 0"><h2 style="font-size:19px;font-weight:900;margin-bottom:16px">قد يعجبكِ أيضاً</h2><div class="nb-prod" id="nb-ty-grid"></div></section>`;
  document.getElementById('nb-sticky-buy-bar').style.display = 'none';
  window.scrollTo({ top: 0, behavior: 'smooth' });
  getVisibleProducts().then((l) => {
    document.getElementById('nb-ty-grid').innerHTML = l.filter((p) => p.id !== product.id).slice(0, 8).map(productCardHtml).join('');
  }).catch(() => {});
}

window.addToCartFromPage = function () {
  if (!product || !inStock(product)) return;
  addToCart({ productId: product.id, slug: product.slug || product.id, name: product.name, image: images[0], price: Number(product.price || 0), oldPrice: productOldPrice(product), variant: variantText(), qty });
  window.nbToast?.('أُضيف المنتج إلى السلة 🛒', 'success');
  window.nbOpenCart?.();
};

window.orderViaWhatsApp = function () {
  const link = whatsappLink(settings, `مرحباً متجر نبضة، أريد طلب: ${product.name}${variantText() ? ' (' + variantText() + ')' : ''} — الكمية ${qty} — ${formatDA(product.price)}\n${location.origin}${mUrl('/product/' + encodeURIComponent(product.slug || product.id))}`);
  if (link) window.open(link, '_blank', 'noopener');
};

async function notifyMe() {
  if (!currentUser) { location.href = '/login?next=' + encodeURIComponent(location.pathname); return; }
  const phone = normalizePhone(prompt('رقم هاتفكِ لنعلمكِ عند توفّر المنتج:') || '');
  if (!validPhoneFor(phone)) { window.nbToast?.('رقم الهاتف غير صحيح', 'error'); return; }
  try {
    // الحقول مطابقة تماماً لقاعدة waitlist (hasOnly)
    await db.collection('waitlist').add({
      phone, userId: currentUser.uid, productId: product.id, productName: String(product.name).slice(0, 200),
      status: 'waiting', type: 'restock', createdAt: window.firebase.firestore.FieldValue.serverTimestamp(),
    });
    window.nbToast?.('سنعلمكِ فور توفّر المنتج 💗', 'success');
  } catch (e) { window.nbToast?.('تعذّر التسجيل، حاولي لاحقاً', 'error'); }
}

/* ─────────────── مشابهة + مؤخراً ─────────────── */
async function loadSimilar() {
  const box = document.getElementById('nb-similar-products-grid');
  try {
    const all = (await getVisibleProducts()).filter((p) => p.id !== product.id);
    const same = all.filter((p) => p.category && p.category === product.category);
    const list = [...same, ...all.filter((p) => !same.includes(p))].slice(0, 10);
    if (!list.length) { box.parentElement.style.display = 'none'; return; }
    box.innerHTML = list.map(productCardHtml).join('');
  } catch (_) { box.parentElement.style.display = 'none'; }
}

const recentKey = () => 'nb_recent_viewed' + (currentMarket() === 'DZ' ? '' : '_' + currentMarket());
function saveRecent() {
  try {
    let r = JSON.parse(localStorage.getItem(recentKey()) || '[]').filter((x) => x.id !== product.id);
    r.unshift({ id: product.id, slug: product.slug || product.id, name: product.name, price: product.price, oldPrice: productOldPrice(product), image: images[0], category: product.category });
    localStorage.setItem(recentKey(), JSON.stringify(r.slice(0, 12)));
  } catch (_) {}
}

function renderRecent() {
  try {
    const r = JSON.parse(localStorage.getItem(recentKey()) || '[]').filter((x) => x.id !== product.id);
    if (!r.length) return;
    document.getElementById('nb-recent-grid').innerHTML = r.slice(0, 8).map((x) => productCardHtml({ ...x, images: [x.image] })).join('');
    document.getElementById('nb-recent-sec').style.display = 'block';
  } catch (_) {}
}

/* ─────────────── SEO ─────────────── */
function seo() {
  const p = product;
  const path = '/product/' + encodeURIComponent(p.slug || p.id);
  const url = `https://nabda.online${mUrl(path)}`;
  // نسخ المنتج في الأسواق الأخرى (hreflang) — فقط حيث هو متاح ومسعّر
  [['DZ', 'ar-DZ'], ['SA', 'ar-SA']].forEach(([c, lang]) => {
    if (!mAvailable(raw, c)) return;
    const l = document.createElement('link'); l.rel = 'alternate'; l.hreflang = lang; l.href = `https://nabda.online${mUrl(path, c)}`; document.head.appendChild(l);
  });
  const desc = String(p.seoDescription || p.description || p.desc || '').replace(/\s+/g, ' ').slice(0, 160);
  document.title = `${p.seoTitle || p.name} — متجر نبضة`;
  setMeta('name', 'description', desc);
  setMeta('property', 'og:title', `${p.name} | ${formatDA(p.price)}`);
  setMeta('property', 'og:description', desc);
  setMeta('property', 'og:image', images[0]);
  setMeta('property', 'og:url', url);
  let c = document.querySelector('link[rel="canonical"]');
  if (!c) { c = document.createElement('link'); c.rel = 'canonical'; document.head.appendChild(c); }
  c.href = url;
  const ld = {
    '@context': 'https://schema.org', '@type': 'Product', name: p.name, image: images, description: desc, sku: p.sku || p.id,
    brand: p.brand ? { '@type': 'Brand', name: p.brand } : undefined,
    offers: { '@type': 'Offer', url, price: Number(p.price || 0), priceCurrency: M().currency, availability: inStock(p) ? 'https://schema.org/InStock' : 'https://schema.org/OutOfStock' },
  };
  if (p.rating && p.reviewCount) ld.aggregateRating = { '@type': 'AggregateRating', ratingValue: Number(p.rating), reviewCount: Number(p.reviewCount) };
  const s = document.createElement('script'); s.type = 'application/ld+json'; s.textContent = JSON.stringify(ld); document.head.appendChild(s);
}
function setMeta(attr, key, val) {
  let m = document.querySelector(`meta[${attr}="${key}"]`);
  if (!m) { m = document.createElement('meta'); m.setAttribute(attr, key); document.head.appendChild(m); }
  m.setAttribute('content', val || '');
}
