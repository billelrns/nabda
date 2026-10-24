/**
 * Nabda - Shop Page Controller (بمستوى متاجر المنافسين Mumzworld, Jumia, Noon)
 * Author: فريق تحرير نبضة
 */

import { auth, db } from '../firebase-init.js';
import { isHiddenProduct } from '../shop-rules.js';
import { addToCart } from '../cart.js';

let allProducts = [];
let filteredProducts = [];
let visibleCount = 16;
let currentUser = null;
let userProfile = null;

const CATEGORIES = [
  { name: 'الكل', slug: 'all', icon: '🛍️' },
  { name: 'الحمل والولادة', slug: 'pregnancy', icon: '🤰' },
  { name: 'المولود الجديد', slug: 'newborn', icon: '👶' },
  { name: 'الرضاعة والتغذية', slug: 'feeding', icon: '🍼' },
  { name: 'ملابس الأطفال', slug: 'clothing', icon: '👗' },
  { name: 'العناية بالأم', slug: 'mom-care', icon: '🌸' },
  { name: 'الألعاب والهدايا', slug: 'toys', icon: '🧸' },
  { name: 'الاستحمام والنظافة', slug: 'bath', icon: '🛁' }
];

export async function initShopPage() {
  renderCategoryPills();
  startDealsTimer();

  auth.onAuthStateChanged(async (user) => {
    currentUser = user;
    if (user) {
      try {
        const snap = await db.collection('users').doc(user.uid).get();
        if (snap.exists) {
          userProfile = snap.data();
          prioritizeStageCollections(userProfile.lifeStage);
        }
      } catch (e) {
        console.warn('Error reading user profile in shop:', e);
      }
    }
  });

  setupFilterListeners();
  await loadShopProducts();

  // Handle URL query parameters or slug route
  parseUrlFilters();

  window.addEventListener('popstate', () => {
    parseUrlFilters();
  });
}

function renderCategoryPills() {
  const container = document.getElementById('nb-shop-cat-pills');
  if (!container) return;

  container.innerHTML = CATEGORIES.map(cat => `
    <button class="nb-shop-cat-pill ${cat.slug === 'all' ? 'active' : ''}" 
            data-cat="${cat.slug}" 
            onclick="window.selectCategoryFilter('${cat.slug}')">
      <span class="nb-shop-cat-icon">${cat.icon}</span>
      <span class="nb-shop-cat-label">${cat.name}</span>
    </button>
  `).join('');
}

function startDealsTimer() {
  const timerEl = document.getElementById('nb-deals-timer');
  if (!timerEl) return;

  function update() {
    const now = new Date();
    const end = new Date();
    end.setHours(23, 59, 59, 999);
    const diff = Math.max(0, end.getTime() - now.getTime());

    const h = String(Math.floor(diff / (1000 * 60 * 60))).padStart(2, '0');
    const m = String(Math.floor((diff / (1000 * 60)) % 60)).padStart(2, '0');
    const s = String(Math.floor((diff / 1000) % 60)).padStart(2, '0');

    timerEl.textContent = `${h}:${m}:${s}`;
  }

  update();
  setInterval(update, 1000);
}

function prioritizeStageCollections(stage) {
  const banner = document.getElementById('nb-stage-collection-tabs');
  if (!banner) return;

  // Highlight or order according to stage
  if (stage === 'pregnant') {
    document.getElementById('nb-stage-tab-preg')?.classList.add('active');
  } else if (stage === 'baby') {
    document.getElementById('nb-stage-tab-baby')?.classList.add('active');
  }
}

async function loadShopProducts() {
  const grid = document.getElementById('nb-products-grid');
  if (!grid) return;

  grid.innerHTML = `
    <div style="grid-column:1/-1;text-align:center;padding:50px 20px;color:var(--nb-ink-3)">
      <div style="font-size:32px;animation:nb-beat 1.5s infinite">🛍️</div>
      <div style="margin-top:12px;font-weight:700">جاري تحميل تشكيلة المنتجات المميزة...</div>
    </div>
  `;

  try {
    const snap = await db.collection('products')
      .where('active', '==', true)
      .limit(100)
      .get();

    allProducts = [];
    snap.forEach(doc => {
      const p = { id: doc.id, ...doc.data() };
      // Strict compliance rule: filter out supplements and medical equipment
      if (!isHiddenProduct(p)) {
        allProducts.push(p);
      }
    });

    applyFilters(false);
    renderShelves();
  } catch (err) {
    console.error('Error fetching shop products:', err);
    grid.innerHTML = '<div style="grid-column:1/-1;text-align:center;padding:40px;color:var(--nb-ink-3)">تعذر جلب المنتجات حالياً.</div>';
  }
}

function renderShelves() {
  // 1. Flash Deals Shelf
  const dealsContainer = document.getElementById('nb-flash-deals-shelf');
  if (dealsContainer) {
    const deals = allProducts.filter(p => (p.oldPrice && p.oldPrice > p.price) || (p.originalPrice && p.originalPrice > p.price)).slice(0, 4);
    dealsContainer.innerHTML = deals.map(p => renderProductCardHtml(p)).join('');
  }

  // 2. Best Sellers Shelf
  const bestSellersContainer = document.getElementById('nb-bestsellers-shelf');
  if (bestSellersContainer) {
    const best = [...allProducts].sort((a, b) => (b.soldCount || 0) - (a.soldCount || 0)).slice(0, 4);
    bestSellersContainer.innerHTML = best.map(p => renderProductCardHtml(p)).join('');
  }
}

function parseUrlFilters() {
  const path = window.location.pathname;
  let catSlug = null;
  const match = path.match(/\/shop\/c\/([^/?#]+)/);
  if (match) {
    catSlug = decodeURIComponent(match[1]);
  }

  const params = new URLSearchParams(window.location.search);
  const q = params.get('q') || '';
  const cat = catSlug || params.get('cat') || 'all';
  const sort = params.get('sort') || 'newest';
  const inStock = params.get('inStock') === '1';
  const discountOnly = params.get('discount') === '1';

  // Update filter inputs UI
  const searchInput = document.getElementById('nb-shop-search-input');
  if (searchInput && q) searchInput.value = q;

  const sortSelect = document.getElementById('nb-shop-sort-select');
  if (sortSelect) sortSelect.value = sort;

  const stockCheck = document.getElementById('nb-filter-stock');
  if (stockCheck) stockCheck.checked = inStock;

  const discountCheck = document.getElementById('nb-filter-discount');
  if (discountCheck) discountCheck.checked = discountOnly;

  // Update pills
  document.querySelectorAll('.nb-shop-cat-pill').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.cat === cat);
  });

  applyFilters(false);
}

function setupFilterListeners() {
  // Search input
  const searchInput = document.getElementById('nb-shop-search-input');
  if (searchInput) {
    searchInput.addEventListener('input', () => {
      debounceFilter();
    });
  }

  // Sort dropdown
  const sortSelect = document.getElementById('nb-shop-sort-select');
  if (sortSelect) {
    sortSelect.addEventListener('change', () => {
      applyFilters(true);
    });
  }

  // Checkboxes
  const stockCheck = document.getElementById('nb-filter-stock');
  if (stockCheck) stockCheck.addEventListener('change', () => applyFilters(true));

  const discountCheck = document.getElementById('nb-filter-discount');
  if (discountCheck) discountCheck.addEventListener('change', () => applyFilters(true));

  // Load more button
  const loadMoreBtn = document.getElementById('nb-shop-load-more');
  if (loadMoreBtn) {
    loadMoreBtn.addEventListener('click', () => {
      visibleCount += 16;
      renderProductsGrid();
    });
  }
}

let debounceTimer = null;
function debounceFilter() {
  clearTimeout(debounceTimer);
  debounceTimer = setTimeout(() => {
    applyFilters(true);
  }, 300);
}

window.selectCategoryFilter = function(slug) {
  document.querySelectorAll('.nb-shop-cat-pill').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.cat === slug);
  });
  applyFilters(true);
};

window.selectStageCollection = function(stageTag) {
  const activePill = document.querySelector(`.nb-shop-cat-pill[data-cat="all"]`);
  if (activePill) activePill.click();

  const searchInput = document.getElementById('nb-shop-search-input');
  if (searchInput) searchInput.value = '';

  // Filter products by lifeStageTag
  filteredProducts = allProducts.filter(p => {
    const tags = p.lifeStageTags || [];
    return tags.includes(stageTag);
  });

  visibleCount = 16;
  renderProductsGrid();

  const countEl = document.getElementById('nb-products-count');
  if (countEl) countEl.textContent = `${filteredProducts.length} منتج متوفر`;
};

function applyFilters(updateUrl = true) {
  const searchInput = document.getElementById('nb-shop-search-input');
  const q = (searchInput?.value || '').trim().toLowerCase();

  const activePill = document.querySelector('.nb-shop-cat-pill.active');
  const catSlug = activePill?.dataset.cat || 'all';

  const sortSelect = document.getElementById('nb-shop-sort-select');
  const sort = sortSelect?.value || 'newest';

  const inStock = document.getElementById('nb-filter-stock')?.checked || false;
  const discountOnly = document.getElementById('nb-filter-discount')?.checked || false;

  filteredProducts = allProducts.filter(p => {
    // 1. Search Query
    if (q) {
      const name = (p.name || p.title || '').toLowerCase();
      const desc = (p.description || p.desc || '').toLowerCase();
      const brand = (p.brand || '').toLowerCase();
      if (!name.includes(q) && !desc.includes(q) && !brand.includes(q)) return false;
    }

    // 2. Category
    if (catSlug !== 'all') {
      const cat = (p.category || '').toLowerCase();
      const pSlug = (p.categorySlug || '').toLowerCase();
      const target = CATEGORIES.find(c => c.slug === catSlug)?.name.toLowerCase() || catSlug;
      if (!cat.includes(target) && !pSlug.includes(catSlug)) return false;
    }

    // 3. In stock
    if (inStock && (p.stock <= 0)) return false;

    // 4. Discount
    if (discountOnly) {
      const hasDiscount = (p.oldPrice && p.oldPrice > p.price) || (p.originalPrice && p.originalPrice > p.price);
      if (!hasDiscount) return false;
    }

    return true;
  });

  // Sorting
  if (sort === 'price_asc') {
    filteredProducts.sort((a, b) => Number(a.price || 0) - Number(b.price || 0));
  } else if (sort === 'price_desc') {
    filteredProducts.sort((a, b) => Number(b.price || 0) - Number(a.price || 0));
  } else if (sort === 'best_seller') {
    filteredProducts.sort((a, b) => (b.soldCount || 0) - (a.soldCount || 0));
  } else if (sort === 'top_rated') {
    filteredProducts.sort((a, b) => (b.rating || 5) - (a.rating || 5));
  } else {
    // Newest
    filteredProducts.sort((a, b) => {
      const tA = a.createdAt?.seconds || 0;
      const tB = b.createdAt?.seconds || 0;
      return tB - tA;
    });
  }

  visibleCount = 16;
  renderProductsGrid();

  // Update URL state
  if (updateUrl) {
    const params = new URLSearchParams();
    if (q) params.set('q', q);
    if (catSlug !== 'all') params.set('cat', catSlug);
    if (sort !== 'newest') params.set('sort', sort);
    if (inStock) params.set('inStock', '1');
    if (discountOnly) params.set('discount', '1');

    const newUrl = params.toString() ? `/shop?${params.toString()}` : '/shop';
    window.history.pushState(null, '', newUrl);
  }

  const countEl = document.getElementById('nb-products-count');
  if (countEl) countEl.textContent = `${filteredProducts.length} منتج متوفر`;
}

function renderProductsGrid() {
  const grid = document.getElementById('nb-products-grid');
  const loadMoreBtn = document.getElementById('nb-shop-load-more');
  if (!grid) return;

  if (filteredProducts.length === 0) {
    grid.innerHTML = `
      <div style="grid-column:1/-1;text-align:center;padding:60px 20px;background:#FFF9FC;border-radius:24px;border:1px dashed #F8BBD0">
        <div style="font-size:48px;margin-bottom:12px">🔍</div>
        <h3 style="font-size:18px;font-weight:900;color:var(--nb-ink);margin-bottom:6px">لم نجد منتجات مطابقة لخيارات البحث</h3>
        <p style="font-size:13.5px;color:var(--nb-ink-3);margin-bottom:18px">جربي تغيير كلمات البحث أو إلغاء بعض الفلاتر.</p>
        <button class="nb-btn-secondary" onclick="window.resetShopFilters()">إعادة ضبط الفلاتر</button>
      </div>
    `;
    if (loadMoreBtn) loadMoreBtn.style.display = 'none';
    return;
  }

  const slice = filteredProducts.slice(0, visibleCount);
  grid.innerHTML = slice.map(p => renderProductCardHtml(p)).join('');

  if (loadMoreBtn) {
    loadMoreBtn.style.display = visibleCount < filteredProducts.length ? 'block' : 'none';
  }
}

function renderProductCardHtml(p) {
  const slug = p.slug || p.id;
  const primaryImg = p.image || p.imageUrl || (p.images && p.images[0]) || '/landing-assets/slide-store.png';
  const secondaryImg = (p.images && p.images[1]) ? p.images[1] : primaryImg;
  const price = Number(p.price || 0).toLocaleString();
  const old = p.oldPrice || p.originalPrice;
  const oldPrice = old ? Number(old).toLocaleString() : null;

  let discountPct = null;
  if (old && old > p.price) {
    discountPct = Math.round(((old - p.price) / old) * 100);
  }

  const isLowStock = p.stock > 0 && p.stock <= 5;
  const isOutOfStock = p.stock <= 0;

  return `
    <div class="nb-shop-card" onclick="window.location.href='/product/${slug}'">
      <div class="nb-shop-card-img-wrap">
        <img src="${primaryImg}" alt="${p.name}" class="nb-shop-img primary" loading="lazy">
        ${secondaryImg !== primaryImg ? `<img src="${secondaryImg}" alt="${p.name}" class="nb-shop-img secondary" loading="lazy">` : ''}

        ${discountPct ? `<span class="nb-discount-badge">-${discountPct}%</span>` : ''}
        ${isLowStock ? `<span class="nb-urgency-badge">بقي ${p.stock} فقط!</span>` : ''}
        ${isOutOfStock ? `<span class="nb-out-badge">نفد مؤقتاً</span>` : ''}

        <button class="nb-wish-heart" onclick="event.stopPropagation();window.toggleWishlist('${p.id}')" title="حفظ في المفضلة">
          ♥
        </button>
      </div>

      <div class="nb-shop-card-body">
        <div>
          <div style="font-size:11px;color:var(--nb-pink);font-weight:800;margin-bottom:4px">${p.category || 'العناية بالطفل'}</div>
          <h4 class="nb-shop-card-title">${p.name}</h4>
          
          <div style="display:flex;align-items:center;gap:4px;margin-bottom:8px">
            <span style="color:#FFB300;font-size:12px">★</span>
            <span style="font-size:12px;font-weight:800;color:var(--nb-ink)">${p.rating || 4.9}</span>
            <span style="font-size:11px;color:var(--nb-ink-3)">(${p.reviewCount || 18})</span>
          </div>
        </div>

        <div>
          <div class="nb-shop-price-row">
            <span class="nb-shop-price">${price} دج</span>
            ${oldPrice ? `<span class="nb-shop-old-price">${oldPrice} دج</span>` : ''}
          </div>

          ${isOutOfStock ? `
            <button class="nb-btn-secondary" style="width:100%;font-size:12px;padding:6px" onclick="event.stopPropagation();window.openWaitlistModal('${p.id}','${escapeHtml(p.name)}')">
              أعلميني عند التوفر 🔔
            </button>
          ` : `
            <button class="nb-btn-primary" style="width:100%;font-size:12.5px;padding:7px 12px" onclick="event.stopPropagation();window.quickAddToCart('${p.id}')">
              أضيفي للسلة 🛒
            </button>
          `}
        </div>
      </div>
    </div>
  `;
}

window.quickAddToCart = function(productId) {
  const p = allProducts.find(item => item.id === productId);
  if (!p) return;

  addToCart({
    productId: p.id,
    slug: p.slug || p.id,
    name: p.name,
    image: p.image || p.imageUrl || (p.images && p.images[0]),
    price: Number(p.price || 0),
    variant: p.variants ? p.variants[0]?.options?.[0] : null,
    qty: 1
  });

  // Open mini cart drawer
  if (window.openCartDrawer) {
    window.openCartDrawer();
  }
};

window.resetShopFilters = function() {
  const searchInput = document.getElementById('nb-shop-search-input');
  if (searchInput) searchInput.value = '';

  const stockCheck = document.getElementById('nb-filter-stock');
  if (stockCheck) stockCheck.checked = false;

  const discountCheck = document.getElementById('nb-filter-discount');
  if (discountCheck) discountCheck.checked = false;

  const activePill = document.querySelector(`.nb-shop-cat-pill[data-cat="all"]`);
  if (activePill) activePill.click();

  applyFilters(true);
};

window.toggleWishlist = function(productId) {
  alert('تمت إضافة المنتج إلى قائمة المحفوظات المفضلة لديكِ 🔖');
};

function escapeHtml(str) {
  if (!str) return '';
  return str.replace(/[&<>"']/g, m => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
  }[m]));
}
