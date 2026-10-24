/**
 * Nabda - Dedicated Product Page Controller
 * Author: فريق تحرير نبضة
 */

import { auth, db } from '../firebase-init.js';
import { isHiddenProduct } from '../shop-rules.js';
import { addToCart } from '../cart.js';

let currentProduct = null;
let selectedQuantity = 1;
let selectedVariant = null;
let citiesData = null;
let shippingRates = {};

export async function initProductPage() {
  const slug = getProductSlugFromUrl();
  if (!slug) {
    showProductNotFound();
    return;
  }

  // Load cities & shipping
  loadAlgeriaCities();
  loadShippingConfig();

  // Fetch Product
  await fetchProductData(slug);
}

function getProductSlugFromUrl() {
  const path = window.location.pathname;
  const match = path.match(/\/product\/([^/?#]+)/);
  if (match) return decodeURIComponent(match[1]);

  const params = new URLSearchParams(window.location.search);
  return params.get('slug') || params.get('id');
}

async function fetchProductData(slugOrId) {
  try {
    // 1. Try querying by slug
    let snap = await db.collection('products')
      .where('slug', '==', slugOrId)
      .limit(1)
      .get();

    // 2. If not found by slug, fallback to document ID
    if (snap.empty) {
      const doc = await db.collection('products').doc(slugOrId).get();
      if (doc.exists) {
        currentProduct = { id: doc.id, ...doc.data() };
      }
    } else {
      const doc = snap.docs[0];
      currentProduct = { id: doc.id, ...doc.data() };
    }

    if (!currentProduct || !currentProduct.active || isHiddenProduct(currentProduct)) {
      showProductNotFound();
      return;
    }

    renderProductView(currentProduct);
    saveRecentlyViewed(currentProduct);
    loadSimilarProducts(currentProduct);
    updateProductSeo(currentProduct);
  } catch (err) {
    console.error('Error fetching product:', err);
    showProductNotFound();
  }
}

function showProductNotFound() {
  document.getElementById('nb-product-view-container').style.display = 'none';
  document.getElementById('nb-product-not-found').style.display = 'block';
  loadSimilarProducts(null);
}

function renderProductView(p) {
  // Breadcrumb
  const bcCat = document.getElementById('nb-bc-category');
  if (bcCat) {
    bcCat.textContent = p.category || 'المتجر';
    bcCat.href = `/shop?cat=${encodeURIComponent(p.category || 'all')}`;
  }
  const bcName = document.getElementById('nb-bc-title');
  if (bcName) bcName.textContent = p.name;

  // Title, Brand & Ratings
  const nameEl = document.getElementById('nb-p-title');
  if (nameEl) nameEl.textContent = p.name;

  const brandEl = document.getElementById('nb-p-brand');
  if (brandEl) brandEl.textContent = p.brand ? `الماركة: ${p.brand}` : 'علامة موثوقة ومضمونة';

  const ratingEl = document.getElementById('nb-p-rating');
  if (ratingEl) ratingEl.textContent = `${p.rating || 4.9} ★ (${p.reviewCount || 24} تقييم)`;

  // Pricing
  const price = Number(p.price || 0);
  const oldPrice = p.oldPrice || p.originalPrice ? Number(p.oldPrice || p.originalPrice) : null;

  const priceEl = document.getElementById('nb-p-price');
  if (priceEl) priceEl.textContent = `${price.toLocaleString()} دج`;

  const oldPriceEl = document.getElementById('nb-p-old-price');
  if (oldPriceEl) {
    if (oldPrice && oldPrice > price) {
      oldPriceEl.textContent = `${oldPrice.toLocaleString()} دج`;
      oldPriceEl.style.display = 'inline-block';

      const saveBadge = document.getElementById('nb-p-savings-badge');
      if (saveBadge) {
        const diff = oldPrice - price;
        saveBadge.textContent = `وفّري ${diff.toLocaleString()} دج 🔥`;
        saveBadge.style.display = 'inline-block';
      }
    } else {
      oldPriceEl.style.display = 'none';
    }
  }

  // Stock
  const stockEl = document.getElementById('nb-p-stock-badge');
  if (stockEl) {
    if (p.stock > 0 && p.stock <= 5) {
      stockEl.textContent = `بقي ${p.stock} قطع فقط في المخزن!`;
      stockEl.style.color = '#E65100';
    } else if (p.stock > 5) {
      stockEl.textContent = 'متوفر في المخزن وجاهز للشحن الفوري ✓';
      stockEl.style.color = '#2E7D32';
    } else {
      stockEl.textContent = 'نفد من المخزن مؤقتاً';
      stockEl.style.color = '#C2185B';
    }
  }

  // Gallery
  const images = (Array.isArray(p.images) && p.images.length > 0)
    ? p.images
    : [p.image || p.imageUrl || '/landing-assets/slide-store.png'];

  renderGallery(images);

  // Variants
  renderVariants(p.variants);

  // Description & Tabs
  const descEl = document.getElementById('nb-p-desc-content');
  if (descEl) descEl.innerHTML = p.description || p.desc || '<p>منتج عالي الجودة لراحة طفلكِ وسلامته.</p>';

  // Setup COD calculations
  updateCodTotals();

  // Sticky mobile bar
  setupStickyMobileBar(p);
}

function renderGallery(images) {
  const mainImg = document.getElementById('nb-main-img');
  if (mainImg) {
    mainImg.src = images[0];
    mainImg.alt = currentProduct?.name || 'صورة المنتج';
  }

  const thumbStrip = document.getElementById('nb-gallery-thumbs');
  if (!thumbStrip) return;

  if (images.length <= 1) {
    thumbStrip.style.display = 'none';
    return;
  }

  thumbStrip.innerHTML = images.map((img, idx) => `
    <button class="nb-thumb-btn ${idx === 0 ? 'active' : ''}" onclick="window.selectGalleryImage('${img}', this)">
      <img src="${img}" alt="معاينة" class="nb-thumb-img">
    </button>
  `).join('');
}

window.selectGalleryImage = function(src, btn) {
  const mainImg = document.getElementById('nb-main-img');
  if (mainImg) mainImg.src = src;

  document.querySelectorAll('.nb-thumb-btn').forEach(b => b.classList.remove('active'));
  if (btn) btn.classList.add('active');
};

function renderVariants(variants) {
  const container = document.getElementById('nb-p-variants-box');
  if (!container) return;

  if (!Array.isArray(variants) || variants.length === 0) {
    container.style.display = 'none';
    return;
  }

  container.innerHTML = variants.map(v => `
    <div style="margin-bottom:12px">
      <div style="font-size:12.5px;font-weight:700;color:var(--nb-ink);margin-bottom:6px">${v.label || 'الخيارات'}:</div>
      <div style="display:flex;gap:8px;flex-wrap:wrap">
        ${(v.options || []).map((opt, i) => `
          <button class="nb-variant-btn ${i === 0 ? 'active' : ''}" onclick="window.selectProductVariant('${opt}', this)">
            ${opt}
          </button>
        `).join('')}
      </div>
    </div>
  `).join('');

  selectedVariant = variants[0]?.options?.[0] || null;
}

window.selectProductVariant = function(opt, btn) {
  selectedVariant = opt;
  const parent = btn.parentElement;
  parent.querySelectorAll('.nb-variant-btn').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
};

// Quantity controls
window.changeQuantity = function(delta) {
  selectedQuantity = Math.max(1, selectedQuantity + delta);
  const qEl = document.getElementById('nb-qty-val');
  if (qEl) qEl.textContent = selectedQuantity;
  updateCodTotals();
};

async function loadAlgeriaCities() {
  try {
    const res = await fetch('/data/algeria_cities.json');
    citiesData = await res.json();
    populateWilayas();
  } catch (e) {
    console.error('Error loading algeria_cities.json:', e);
  }
}

function populateWilayas() {
  const wilayaSelect = document.getElementById('nb-cod-wilaya');
  if (!wilayaSelect || !citiesData || !citiesData.wilayas) return;

  wilayaSelect.innerHTML = '<option value="">-- اختاري الولاية (58 ولاية) --</option>' +
    citiesData.wilayas.map(w => `
      <option value="${w.wilaya_name_arabic}" data-id="${w.wilaya_id}">
        ${w.wilaya_id} - ${w.wilaya_name_arabic}
      </option>
    `).join('');

  wilayaSelect.addEventListener('change', () => {
    const selectedOption = wilayaSelect.options[wilayaSelect.selectedIndex];
    const wId = parseInt(selectedOption?.dataset?.id, 10);
    populateCommunes(wId);
    updateCodTotals();
  });
}

function populateCommunes(wilayaId) {
  const communeSelect = document.getElementById('nb-cod-commune');
  if (!communeSelect || !citiesData) return;

  const communes = (citiesData.communes || []).filter(c => c.wilaya_id === wilayaId);

  if (communes.length === 0) {
    communeSelect.innerHTML = '<option value="">-- البلدية / الدائرة --</option>';
    return;
  }

  communeSelect.innerHTML = '<option value="">-- اختاري البلدية --</option>' +
    communes.map(c => `
      <option value="${c.commune_name_arabic || c.commune_name_latin}">
        ${c.commune_name_arabic || c.commune_name_latin}
      </option>
    `).join('');
}

async function loadShippingConfig() {
  try {
    const snap = await db.collection('site_config').doc('shipping').get();
    if (snap.exists) {
      shippingRates = snap.data();
    }
  } catch (e) {
    console.warn('Using default shipping rates map');
  }
}

function getCalculatedShippingFee() {
  const wilaya = document.getElementById('nb-cod-wilaya')?.value;
  const isHome = document.querySelector('input[name="deliveryType"]:checked')?.value !== 'office';

  if (!wilaya) return 600; // default average

  // If customized in site_config/shipping
  if (shippingRates[wilaya]) {
    return isHome ? (shippingRates[wilaya].home || 600) : (shippingRates[wilaya].desk || 400);
  }

  // Standard defaults by region
  const central = ['الجزائر', 'البليدة', 'بومرداس', 'تيبازة'];
  if (central.includes(wilaya)) return isHome ? 450 : 300;

  return isHome ? 650 : 400;
}

function updateCodTotals() {
  if (!currentProduct) return;

  const unitPrice = Number(currentProduct.price || 0);
  const subtotal = unitPrice * selectedQuantity;
  const shipping = getCalculatedShippingFee();
  const total = subtotal + shipping;

  const subtotalEl = document.getElementById('nb-cod-subtotal');
  const shipEl = document.getElementById('nb-cod-shipping');
  const totalEl = document.getElementById('nb-cod-total');

  if (subtotalEl) subtotalEl.textContent = `${subtotal.toLocaleString()} دج`;
  if (shipEl) shipEl.textContent = `${shipping.toLocaleString()} دج`;
  if (totalEl) totalEl.textContent = `${total.toLocaleString()} دج`;
}

// Order Confirmation (Direct COD Form)
window.submitDirectCodOrder = async function() {
  if (!currentProduct) return;

  const name = document.getElementById('nb-cod-name')?.value?.trim();
  const phone = document.getElementById('nb-cod-phone')?.value?.trim();
  const wilaya = document.getElementById('nb-cod-wilaya')?.value;
  const commune = document.getElementById('nb-cod-commune')?.value;
  const address = document.getElementById('nb-cod-address')?.value?.trim();
  const deliveryType = document.querySelector('input[name="deliveryType"]:checked')?.value || 'home';

  // Validation
  if (!name || name.length < 2) {
    alert('يرجى إدخال اسمكِ الكامل.');
    return;
  }

  const phoneRegex = /^0[567]\d{8}$/;
  if (!phone || !phoneRegex.test(phone)) {
    alert('يرجى إدخال رقم هاتف جزائري صحيح (مثال: 0550123456 أو 0660123456).');
    return;
  }

  if (!wilaya) {
    alert('يرجى اختيار الولاية.');
    return;
  }

  const submitBtn = document.getElementById('nb-cod-submit-btn');
  if (submitBtn) {
    submitBtn.disabled = true;
    submitBtn.innerHTML = 'جاري تأكيد طلبيتكِ... ⏳';
  }

  const unitPrice = Number(currentProduct.price || 0);
  const shippingFee = getCalculatedShippingFee();
  const cartId = 'cod_' + Date.now() + '_' + Math.random().toString(36).substr(2, 6);

  const orderData = {
    userId: currentUser ? currentUser.uid : null,
    source: 'website',
    status: 'pending',
    customerName: name,
    customerPhone: phone,
    wilaya: wilaya,
    commune: commune || '',
    address: address || '',
    deliveryType: deliveryType,
    productId: currentProduct.id,
    productName: currentProduct.name,
    quantity: parseInt(selectedQuantity, 10),
    unitPrice: unitPrice,
    shippingFee: shippingFee,
    variant: selectedVariant || '',
    cartId: cartId,
    createdAt: firebase.firestore.FieldValue.serverTimestamp()
  };

  try {
    const docRef = await db.collection('orders').add(orderData);

    // Show Thank You Screen
    showThankYouView({
      orderId: docRef.id,
      productName: currentProduct.name,
      total: (unitPrice * selectedQuantity) + shippingFee,
      customerPhone: phone
    });
  } catch (err) {
    console.error('Error creating order:', err);
    alert('حدث خطأ أثناء حفظ الطلب: ' + err.message);
    if (submitBtn) {
      submitBtn.disabled = false;
      submitBtn.innerHTML = 'تأكيد الطلب — الدفع عند الاستلام 🚚';
    }
  }
};

function showThankYouView(info) {
  const container = document.getElementById('nb-product-view-container');
  if (!container) return;

  const whatsappMsg = encodeURIComponent(`مرحباً نبضة، قمت بتأكيد طلبيتي لرقم الطلب #${info.orderId.slice(-6)} للمنتج: ${info.productName}`);
  const whatsappUrl = `https://wa.me/213550000000?text=${whatsappMsg}`;

  container.innerHTML = `
    <div style="background:#FFFFFF;border:1px solid #C8E6C9;border-radius:28px;padding:48px 32px;text-align:center;max-width:680px;margin:40px auto;box-shadow:0 16px 40px rgba(0,137,123,0.1)">
      <div style="font-size:56px;margin-bottom:14px">🎉</div>
      <h2 style="font-size:26px;font-weight:900;color:var(--nb-ink);margin:0 0 10px">تم تأكيد طلبيتكِ بنجاح!</h2>
      <p style="font-size:15px;color:var(--nb-ink-2);line-height:1.7;margin-bottom:24px">
        شكراً لثقتكِ بمتجر نبضة. رقم طلبيتكِ هو: <strong style="color:var(--nb-pink)">#${info.orderId.slice(-6)}</strong>.<br>
        سيتصل بكِ فريق خدمة العملاء هاتفياً على الرقم <strong>${info.customerPhone}</strong> لتأكيد العنوان وموعد الشحن.
      </p>

      <div style="background:#F1F8E9;border:1px solid #C8E6C9;border-radius:18px;padding:18px;margin-bottom:28px;font-size:14px;color:#2E7D32;font-weight:700">
        المبلغ الإجمالي للدفع عند الاستلام: ${info.total.toLocaleString()} دج
      </div>

      <div style="display:flex;gap:14px;justify-content:center;flex-wrap:wrap">
        <a href="${whatsappUrl}" target="_blank" class="nb-btn-primary" style="background:#25D366;font-size:13.5px;padding:12px 24px;text-decoration:none">
          متابعة الطلبية عبر واتساب 💬
        </a>
        <a href="/shop" class="nb-btn-secondary" style="font-size:13.5px;padding:12px 24px;text-decoration:none">
          مواصلة التسوق 🛍️
        </a>
      </div>
    </div>
  `;
}

window.addToCartFromPage = function() {
  if (!currentProduct) return;
  addToCart({
    productId: currentProduct.id,
    slug: currentProduct.slug || currentProduct.id,
    name: currentProduct.name,
    image: currentProduct.image || currentProduct.imageUrl || (currentProduct.images && currentProduct.images[0]),
    price: Number(currentProduct.price || 0),
    variant: selectedVariant,
    qty: selectedQuantity
  });

  if (window.openCartDrawer) {
    window.openCartDrawer();
  }
};

window.orderViaWhatsApp = function() {
  if (!currentProduct) return;
  const url = window.location.href;
  const msg = encodeURIComponent(`مرحباً متجر نبضة، أود طلب المنتج: ${currentProduct.name} - السعر: ${currentProduct.price} دج. الرابط: ${url}`);
  window.open(`https://wa.me/213550000000?text=${msg}`, '_blank');
};

function setupStickyMobileBar(p) {
  const bar = document.getElementById('nb-sticky-buy-bar');
  if (!bar) return;

  const thumb = document.getElementById('nb-sticky-thumb');
  const price = document.getElementById('nb-sticky-price');
  if (thumb) thumb.src = p.image || p.imageUrl || (p.images && p.images[0]) || '';
  if (price) price.textContent = `${Number(p.price || 0).toLocaleString()} دج`;

  bar.style.display = 'flex';
}

function saveRecentlyViewed(p) {
  try {
    let recent = JSON.parse(localStorage.getItem('nb_recent_viewed') || '[]');
    recent = recent.filter(item => item.id !== p.id);
    recent.unshift({
      id: p.id,
      slug: p.slug || p.id,
      name: p.name,
      price: p.price,
      image: p.image || p.imageUrl || (p.images && p.images[0])
    });
    localStorage.setItem('nb_recent_viewed', JSON.stringify(recent.slice(0, 8)));
  } catch (e) {}
}

async function loadSimilarProducts(p) {
  const container = document.getElementById('nb-similar-products-grid');
  if (!container) return;

  try {
    const snap = await db.collection('products')
      .where('active', '==', true)
      .limit(10)
      .get();

    const products = [];
    snap.forEach(doc => {
      const item = { id: doc.id, ...doc.data() };
      if (item.id !== p?.id && !isHiddenProduct(item)) {
        products.push(item);
      }
    });

    if (products.length === 0) {
      container.parentElement.style.display = 'none';
      return;
    }

    container.innerHTML = products.slice(0, 4).map(prod => `
      <div class="nb-shop-card" onclick="window.location.href='/product/${prod.slug || prod.id}'">
        <div class="nb-shop-card-img-wrap" style="height:170px">
          <img src="${prod.image || prod.imageUrl || (prod.images && prod.images[0])}" alt="${prod.name}" class="nb-shop-img" loading="lazy">
        </div>
        <div class="nb-shop-card-body">
          <h4 class="nb-shop-card-title">${prod.name}</h4>
          <div style="font-size:15px;font-weight:900;color:var(--nb-pink);margin-bottom:8px">${Number(prod.price || 0).toLocaleString()} دج</div>
          <button class="nb-btn-primary" style="width:100%;font-size:12px;padding:6px">عرض المنتج</button>
        </div>
      </div>
    `).join('');
  } catch (err) {
    console.error('Error loading similar products:', err);
  }
}

function updateProductSeo(p) {
  const title = `${p.name} — متجر نبضة`;
  document.title = title;

  const desc = (p.description || p.desc || '').slice(0, 160);
  const metaDesc = document.querySelector('meta[name="description"]');
  if (metaDesc) metaDesc.setAttribute('content', desc);

  // Canonical
  let canonical = document.querySelector('link[rel="canonical"]');
  if (!canonical) {
    canonical = document.createElement('link');
    canonical.rel = 'canonical';
    document.head.appendChild(canonical);
  }
  canonical.href = `https://nabda.online/product/${p.slug || p.id}`;

  // Structured Data
  let script = document.getElementById('nb-product-jsonld');
  if (!script) {
    script = document.createElement('script');
    script.id = 'nb-product-jsonld';
    script.type = 'application/ld+json';
    document.head.appendChild(script);
  }

  const jsonLd = {
    '@context': 'https://schema.org',
    '@type': 'Product',
    'name': p.name,
    'image': p.image || p.imageUrl || (p.images && p.images[0]),
    'description': desc,
    'offers': {
      '@type': 'Offer',
      'price': p.price,
      'priceCurrency': 'DZD',
      'availability': p.stock > 0 ? 'https://schema.org/InStock' : 'https://schema.org/OutOfStock'
    }
  };
  script.textContent = JSON.stringify(jsonLd);
}
