// ═══════════════════════════════════════════════════════════════════
//  الغلاف الموحد لموقع نبضة (Shell: Header, Footer, Auth, Cart, Drawer)
// ═══════════════════════════════════════════════════════════════════

import { PLAY_URL, OFFICIAL_FACEBOOK } from './site-config.js';
import { auth, db } from './firebase-init.js';
import { getCart, getCartCount, getCartTotal, updateQty, removeFromCart, onCartChange } from './cart.js';
import { escapeHtml as esc, pregnancyFromUser } from './utils.js';
import { MARKETS, currentMarket, saveMarket, switchMarketUrl, mUrl, money, detectCountryOnce, savedMarket, syncShopPath } from './market.js';
import { cartKey } from './cart.js';

// ── 1. SVG Animated Logo Template ──
const SVG_LOGO = `
<svg class="nbl" viewBox="0 0 2820 1000" role="img" aria-label="نبضة" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <radialGradient id="nblB" cx="30%" cy="24%" r="88%"><stop offset="0%" stop-color="#FF9BC4"/><stop offset="38%" stop-color="#F0347C"/><stop offset="74%" stop-color="#E0195B"/><stop offset="100%" stop-color="#A80D48"/></radialGradient>
    <radialGradient id="nblP" cx="32%" cy="26%" r="86%"><stop offset="0%" stop-color="#FFFFFF"/><stop offset="30%" stop-color="#FFE4EF"/><stop offset="70%" stop-color="#FFD6E3"/><stop offset="100%" stop-color="#F48CB3"/></radialGradient>
    <radialGradient id="nblC" cx="40%" cy="68%" r="80%"><stop offset="0%" stop-color="#D9799B" stop-opacity=".62"/><stop offset="100%" stop-color="#FFD6E3" stop-opacity=".88"/></radialGradient>
    <linearGradient id="nblR" x1="0" y1="0" x2="1" y2="1"><stop offset="0%" stop-color="#fff" stop-opacity=".78"/><stop offset="45%" stop-color="#fff" stop-opacity=".05"/><stop offset="100%" stop-color="#FF8FBB" stop-opacity=".45"/></linearGradient>
    <linearGradient id="nblW" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stop-color="#F0347C"/><stop offset="100%" stop-color="#C2185B"/></linearGradient>
    <filter id="nblF1" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="26"/></filter>
    <filter id="nblF2" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="13"/></filter>
    <filter id="nblF3" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="5"/></filter>
    <path id="nblH" d="M50 32C36 6 4 12 4 38C4 60 28 74 50 92C72 74 96 60 96 38C96 12 64 6 50 32Z"/>
    <g id="nblD"><use href="#nblH" x="-50" y="-50" fill="url(#nblB)"/><use href="#nblH" x="-50" y="-50" fill="none" stroke="#fff" stroke-opacity=".5" stroke-width="3.4"/><ellipse cx="-21" cy="-26" rx="17" ry="10" fill="#fff" fill-opacity=".62" filter="url(#nblF3)"/><ellipse cx="-26" cy="-30" rx="5.5" ry="3.4" fill="#fff" fill-opacity=".95"/></g>
  </defs>
  <image class="nblMo" href="/landing-assets/heart-big.webp" x="1779" y="40" width="1000" height="921" style="transform-origin:2279px 500px"/>
  <image class="nblBa" href="/landing-assets/heart-small.webp" x="2081" y="374" width="450" height="382" style="transform-origin:2306px 565px"/>
  <g transform="translate(40 168) scale(0.7508)">
    <path fill="url(#nblW)" d="M446 193L446 537Q446 543 450 547Q454 551 462 551L496 551L496 680L417 680Q366 680 324 640Q275 689 206 689L205 689L203 689Q103 689 46 606Q0 541 0 451Q0 341 70 269Q133 204 227 204Q278 204 328 225L369 193ZM291 344Q267 338 246 338Q202 338 177 368Q152 398 152 451Q152 501 179.5 533Q207 565 251 565Q268 565 291 560ZM823 343Q950 207 1123 207Q1247 207 1330 281Q1407 350 1407 456L1407 512Q1407 524 1408 551L1439 551L1439 680L1420 680L1382 634L1380 634Q1342 680 1283 680L489 680L489 551L669 551L669 220L823 220ZM1253 473Q1252 408 1201 370Q1159 339 1104 339Q984 339 884 457Q878 467 863 488Q835 529 822 551L1238 551Q1253 551 1253 537ZM1766 220L1766 542Q1766 546 1767 551L1816 551L1816 680L1785 680L1741 634L1739 634Q1701 680 1641 680L1432 680L1432 551L1592 551Q1601 551 1606 545Q1612 540 1612 531L1612 220ZM2143 220L2143 556Q2143 600 2114 635Q2076 680 2018 680L1809 680L1809 551L1974 551Q1980 551 1984 548Q1989 544 1989 537L1989 220Z"/>
    <g class="nbd d1"><g class="nbp"><use href="#nblD" transform="translate(2065 78) scale(1.95)"/></g></g>
    <g class="nbd d2"><g class="nbp"><use href="#nblD" transform="translate(1688 804.5) scale(1.95)"/></g></g>
    <g class="nbd d3"><g class="nbp"><use href="#nblD" transform="translate(1058 78) scale(1.95)"/></g></g>
    <g class="nbd d4"><g class="nbp"><use href="#nblD" transform="translate(368 78) scale(1.95)"/></g></g>
    <g class="nbd d5"><g class="nbp"><use href="#nblD" transform="translate(188.5 78) scale(1.95)"/></g></g>
  </g>
</svg>`;

// ── 2. Helper to determine active link ──
function getActivePath() {
  const p = window.location.pathname.toLowerCase().replace(/^\/sa(?=\/|$)/, '') || '/';
  if (p === '/' || p === '/index.html' || p === '/home.html') return '/';
  if (p.startsWith('/pregnancy')) return '/pregnancy';
  if (p.startsWith('/baby')) return '/baby';
  if (p.startsWith('/cycle')) return '/cycle';
  if (p.startsWith('/fertility')) return '/fertility';
  if (p.startsWith('/community')) return '/community';
  if (p.startsWith('/shop') || p.startsWith('/product') || p.startsWith('/cart') || p.startsWith('/checkout')) return '/shop';
  if (p.startsWith('/article')) return '/articles';
  if (p.startsWith('/account')) return '/account';
  return p;
}

// ── 3. Render Header ──
function renderHeader(user, userData) {
  const headerEl = document.getElementById('nb-header');
  if (!headerEl) return;

  const currentPath = getActivePath();
  const cartCount = getCartCount();

  let actionsHtml = '';
  if (user) {
    const name = esc(userData?.displayName || user.displayName || user.email?.split('@')[0] || 'عضوة نبضة');
    const photo = esc(userData?.photoURL || userData?.photoUrl || user.photoURL || '');
    
    // Stage badge calculation
    let stageBadge = 'عضوة نبضة 💗';
    let journeyLink = '/pregnancy';
    const preg = pregnancyFromUser(userData);
    if (preg) {
      stageBadge = `🤰 الأسبوع ${preg.week} من الحمل`;
      journeyLink = `/pregnancy/week-${preg.week}`;
    } else if (userData?.lifeStage === 'pregnant') {
      stageBadge = '🤰 رحلة الحمل';
    } else if (userData?.lifeStage === 'baby') {
      stageBadge = '👶 رعاية الطفل';
      journeyLink = '/baby';
    } else if (userData?.lifeStage === 'planning' || userData?.goal === 'trying') {
      stageBadge = '🌱 أخطط للحمل';
      journeyLink = '/fertility';
    } else if (userData?.lifeStage === 'cycle') {
      stageBadge = '🌸 متابعة الدورة';
      journeyLink = '/cycle';
    }

    const avatarContent = photo 
      ? `<img src="${photo}" alt="${name}" class="nb-user-avatar">`
      : `<div class="nb-user-avatar">${name.charAt(0).toUpperCase()}</div>`;

    actionsHtml = `
      <button class="nb-cart-btn" id="nb-cart-trigger" title="سلة المشتريات" aria-label="السلة">
        🛒
        ${cartCount > 0 ? `<span class="nb-cart-badge">${cartCount}</span>` : ''}
      </button>

      <div class="nb-user-menu">
        <div class="nb-user-capsule" id="nb-user-capsule" role="button" tabindex="0" aria-haspopup="true" aria-label="قائمة الحساب">
          ${avatarContent}
          <span class="nb-user-name">${name}</span>
          <span style="font-size:11px;color:#9b8f95">▾</span>
        </div>

        <div class="nb-user-dropdown" id="nb-user-dropdown">
          <div class="nb-dropdown-header">
            <div style="font-weight:800;font-size:15px;color:var(--nb-ink)">${name}</div>
            <div class="nb-dropdown-badge">${stageBadge}</div>
          </div>
          <a href="/account" class="nb-dropdown-item">👤 حسابي</a>
          <a href="/account#orders" class="nb-dropdown-item">📦 طلباتي</a>
          <a href="/account#saved" class="nb-dropdown-item">🔖 مقالاتي المحفوظة</a>
          <a href="${journeyLink}" class="nb-dropdown-item">🤰 رحلتي</a>
          <a href="/account#settings" class="nb-dropdown-item">⚙️ الإعدادات والخصوصية</a>
          <a href="/app/" class="nb-dropdown-item" style="color:var(--nb-teal);font-weight:700">📱 النسخة الكاملة</a>
          <div id="nb-staff-slot"></div>
          <div class="nb-dropdown-divider"></div>
          <button id="nb-logout-btn" class="nb-dropdown-item danger" style="width:100%;text-align:right">🚪 تسجيل الخروج</button>
        </div>
      </div>
    `;
  } else {
    actionsHtml = `
      <button class="nb-cart-btn" id="nb-cart-trigger" title="سلة المشتريات" aria-label="السلة">
        🛒
        ${cartCount > 0 ? `<span class="nb-cart-badge">${cartCount}</span>` : ''}
      </button>
      <a href="/login" class="nb-btn-login">تسجيل الدخول</a>
      <a href="/signup" class="nb-btn-signup">إنشاء حساب جديد</a>
    `;
  }

  headerEl.className = 'nb-header-wrap';
  headerEl.innerHTML = `
    <nav class="nb-nav-glass">
      <div style="display:flex;align-items:center;gap:12px">
        <a href="/" class="nb-logo-link" title="نبضة — الصفحة الرئيسية">
          ${SVG_LOGO}
        </a>
      </div>

      <div class="nb-nav-links">
        <a href="/" class="nb-nav-link ${currentPath === '/' ? 'active' : ''}">الرئيسية</a>
        <a href="/pregnancy" class="nb-nav-link ${currentPath === '/pregnancy' ? 'active' : ''}">الحمل</a>
        <a href="/baby" class="nb-nav-link ${currentPath === '/baby' ? 'active' : ''}">الطفل</a>
        <a href="/cycle" class="nb-nav-link ${currentPath === '/cycle' ? 'active' : ''}">الدورة</a>
        <a href="/fertility" class="nb-nav-link ${currentPath === '/fertility' ? 'active' : ''}">الخصوبة</a>
        <a href="/community" class="nb-nav-link ${currentPath === '/community' ? 'active' : ''}">المجتمع</a>
        <a href="/shop" class="nb-nav-link ${currentPath === '/shop' ? 'active' : ''}">المتجر</a>
        <a href="/articles" class="nb-nav-link nb-nav-link-articles ${currentPath === '/articles' ? 'active' : ''}">موسوعة نبضة 📚</a>
      </div>

      <div class="nb-nav-actions">
        ${actionsHtml}
        <button class="nb-mobile-toggle" id="nb-mobile-toggle" aria-label="فتح القائمة">☰</button>
      </div>
    </nav>
  `;

  // Wire User Dropdown
  const capsule = document.getElementById('nb-user-capsule');
  const dropdown = document.getElementById('nb-user-dropdown');
  if (capsule && dropdown) {
    capsule.addEventListener('click', (e) => {
      e.stopPropagation();
      dropdown.classList.toggle('show');
    });
    if (!window.__nbDropdownWired) {
      window.__nbDropdownWired = true;
      document.addEventListener('click', (e) => {
        const dd = document.getElementById('nb-user-dropdown');
        const cp = document.getElementById('nb-user-capsule');
        if (dd && cp && !dd.contains(e.target) && !cp.contains(e.target)) dd.classList.remove('show');
      });
      document.addEventListener('keydown', (e) => { if (e.key === 'Escape') document.getElementById('nb-user-dropdown')?.classList.remove('show'); });
    }
  }

  // Wire Logout
  const logoutBtn = document.getElementById('nb-logout-btn');
  if (logoutBtn) {
    logoutBtn.addEventListener('click', async () => {
      try {
        sessionStorage.removeItem('nb_user_cache');
        await auth.signOut();
        window.location.href = '/';
      } catch (err) {
        console.error('Logout error:', err);
      }
    });
  }

  // Wire Cart Drawer trigger
  const cartTrigger = document.getElementById('nb-cart-trigger');
  if (cartTrigger) {
    cartTrigger.addEventListener('click', () => {
      openCartDrawer();
    });
  }

  mountMarketSwitch();

  // Wire Mobile drawer toggle
  const mobileToggle = document.getElementById('nb-mobile-toggle');
  if (mobileToggle) {
    mobileToggle.addEventListener('click', () => {
      openMobileDrawer();
    });
  }
}

// ── 4. Render Footer ──
function renderFooter() {
  const footerEl = document.getElementById('nb-footer') || document.getElementById('nb-footer-placeholder');
  if (!footerEl) return;

  footerEl.className = 'nb-footer';
  footerEl.innerHTML = `
    <div class="nb-container">
      <div class="nb-footer-grid">
        <div class="nb-footer-col">
          <div style="margin-bottom:16px">${SVG_LOGO}</div>
          <p class="nb-footer-desc">
            نبضة هي المنصة العربية الرائدة المخصصة لصحة المرأة، متابعة رحلة الحمل أسبوعاً بأسبوع، رعاية الطفل، ومجتمع الأمهات الآمن والموثوق.
          </p>
          <div style="font-size:13px;color:var(--nb-ink-3);font-weight:700">
            تحت إشراف وتحرير: <span style="color:var(--nb-pink-deep)">فريق تحرير نبضة</span>
          </div>
        </div>

        <div class="nb-footer-col">
          <h4>أقسام المنصة</h4>
          <ul class="nb-footer-links">
            <li><a href="/pregnancy">رحلة الحمل أسبوعاً بأسبوع</a></li>
            <li><a href="/baby">مراحل نمو ورعاية الطفل</a></li>
            <li><a href="/cycle">متابعة الدورة الشهرية</a></li>
            <li><a href="/fertility">الخصوبة والتخطيط للحمل</a></li>
            <li><a href="/community">مجتمع أمهات نبضة</a></li>
            <li><a href="/articles">موسوعة المقالات الشاملة</a></li>
            <li><a href="/fiqh">فقه المرأة المسلمة</a></li>
            <li><a href="/qadaa">أيام قضاء رمضان</a></li>
            <li><a href="/tools/baby-names.html">معجم الأسماء وأسماء التوائم</a></li>
          </ul>
        </div>

        <div class="nb-footer-col">
          <h4>متجر نبضة</h4>
          <ul class="nb-footer-links">
            <li><a href="/shop">تصفح منتجات الأم والطفل</a></li>
            <li><a href="/cart">سلة المشتريات</a></li>
            <li><a href="/account#orders">تتبع ومتابعة الطلبات</a></li>
            <li><a href="/shop?cat=pregnancy">مستلزمات الحامل</a></li>
            <li><a href="/shop?cat=baby">مستلزمات حديثي الولادة</a></li>
            <li><span style="color:var(--nb-teal);font-weight:700">🚚 توصيل لجميع الـ 58 ولاية</span></li>
          </ul>
        </div>

        <div class="nb-footer-col">
          <h4>حمّلي تطبيق نبضة</h4>
          <p class="nb-footer-desc">استمتعي بالتجربة الكاملة والأدوات التفاعلية والتنبيهات اليومية على هاتفكِ:</p>
          <a href="${PLAY_URL}" target="_blank" rel="noopener" class="nb-play-btn">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="#fff"><path d="M3.609 1.814L13.793 12 3.61 22.186a2.222 2.222 0 0 1-.61-1.577V3.391c0-.608.228-1.168.609-1.577zm11.396 11.398l2.253-2.253-12.06-6.953 9.807 9.206zm2.253-2.253l2.57 1.48a1.69 1.69 0 0 1 0 2.923l-2.57 1.48-2.025-2.025 2.025-1.858zm-3.465 3.069l-9.807 9.206 12.06-6.953-2.253-2.253z"/></svg>
            <div style="text-align:right">
              <div style="font-size:10px;color:#aaa">متاح مجاناً على</div>
              <div style="font-size:14px;font-weight:800">Google Play</div>
            </div>
          </a>
          <div class="nb-social-links">
            <a href="${OFFICIAL_FACEBOOK}" target="_blank" rel="noopener" class="nb-social-btn" title="صفحة نبضة الرسمية على فيسبوك">
              <svg width="20" height="20" fill="currentColor" viewBox="0 0 24 24"><path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/></svg>
            </a>
          </div>
        </div>
      </div>

      <div class="nb-footer-bottom">
        <div>© 2026 نبضة — جميع الحقوق محفوظة • رفيقة الأم والمرأة في كل خطوة</div>
        <div class="nb-footer-bottom-links">
          <a href="/privacy.html">سياسة الخصوصية</a>
          <a href="/terms.html">شروط الاستخدام</a>
          <a href="/delete-account.html">حذف الحساب والبيانات</a>
        </div>
      </div>
    </div>
  `;
}

// ── 5. Render Mobile Drawer & Bottom Tabs ──
function renderMobileElements(user) {
  // يُعاد بناء الدرج عند تغيّر حالة الدخول
  document.getElementById('nb-drawer-backdrop')?.remove();
  document.getElementById('nb-drawer')?.remove();
  document.getElementById('nb-bottom-bar')?.remove();
  {
    const drawerHtml = `
      <div class="nb-drawer-backdrop" id="nb-drawer-backdrop"></div>
      <div class="nb-drawer" id="nb-drawer">
        <div class="nb-drawer-header">
          <span style="font-weight:800;font-size:18px;color:var(--nb-pink)">أقسام نبضة</span>
          <button class="nb-drawer-close" id="nb-drawer-close">✕</button>
        </div>
        <nav class="nb-drawer-nav">
          <a href="/" class="nb-drawer-link">🏠 الرئيسية</a>
          <a href="/pregnancy" class="nb-drawer-link">🤰 الحمل</a>
          <a href="/baby" class="nb-drawer-link">👶 الطفل</a>
          <a href="/cycle" class="nb-drawer-link">🌸 الدورة</a>
          <a href="/fertility" class="nb-drawer-link">🌱 الخصوبة</a>
          <a href="/community" class="nb-drawer-link">💬 المجتمع</a>
          <a href="/shop" class="nb-drawer-link">🛍️ المتجر</a>
          <a href="/articles" class="nb-drawer-link" style="color:var(--nb-pink-hot);font-weight:800">📚 موسوعة نبضة</a>
          <a href="/fiqh" class="nb-drawer-link">🌙 فقه المرأة</a>
          <a href="/qadaa" class="nb-drawer-link">📅 أيام القضاء</a>
          <a href="/tools/baby-names.html" class="nb-drawer-link">👶 الأسماء والتوائم</a>
          <div style="height:1px;background:var(--nb-line);margin:10px 0"></div>
          ${user ? `
            <a href="/account" class="nb-drawer-link">👤 حسابي</a>
            <a href="/account#orders" class="nb-drawer-link">📦 طلباتي</a>
            <a href="/app/" class="nb-drawer-link" style="color:var(--nb-teal)">📱 النسخة الكاملة</a>
            <div id="nb-staff-slot-m"></div>
          ` : `
            <a href="/login" class="nb-drawer-link" style="color:var(--nb-pink);font-weight:800">🔑 تسجيل الدخول</a>
            <a href="/signup" class="nb-drawer-link">✨ إنشاء حساب جديد</a>
          `}
        </nav>
      </div>
    `;
    document.body.insertAdjacentHTML('beforeend', drawerHtml);

    document.getElementById('nb-drawer-backdrop').addEventListener('click', closeMobileDrawer);
    document.getElementById('nb-drawer-close').addEventListener('click', closeMobileDrawer);
  }

  {
    const currentPath = getActivePath();
    const bottomBarHtml = `
      <div class="nb-bottom-bar" id="nb-bottom-bar">
        <div class="nb-bottom-bar-inner">
          <a href="/" class="nb-bottom-tab ${currentPath === '/' ? 'active' : ''}">
            <span class="tab-icon">🏠</span>
            <span>الرئيسية</span>
          </a>
          <a href="/pregnancy" class="nb-bottom-tab ${currentPath === '/pregnancy' ? 'active' : ''}">
            <span class="tab-icon">🤰</span>
            <span>الحمل</span>
          </a>
          <a href="/shop" class="nb-bottom-tab ${currentPath === '/shop' ? 'active' : ''}">
            <span class="tab-icon">🛍️</span>
            <span>المتجر</span>
          </a>
          <a href="/community" class="nb-bottom-tab ${currentPath === '/community' ? 'active' : ''}">
            <span class="tab-icon">💬</span>
            <span>المجتمع</span>
          </a>
          <a href="${user ? '/account' : '/login'}" class="nb-bottom-tab ${currentPath === '/account' ? 'active' : ''}">
            <span class="tab-icon">👤</span>
            <span>${user ? 'حسابي' : 'دخول'}</span>
          </a>
        </div>
      </div>
    `;
    document.body.insertAdjacentHTML('beforeend', bottomBarHtml);
  }
}

function openMobileDrawer() {
  document.getElementById('nb-drawer-backdrop')?.classList.add('show');
  document.getElementById('nb-drawer')?.classList.add('show');
}

function closeMobileDrawer() {
  document.getElementById('nb-drawer-backdrop')?.classList.remove('show');
  document.getElementById('nb-drawer')?.classList.remove('show');
}

// ── 6. Render Mini Cart Drawer ──
function renderCartDrawer() {
  if (document.getElementById('nb-cart-drawer')) {
    updateCartDrawerContent();
    return;
  }

  const drawerHtml = `
    <div class="nb-drawer-backdrop" id="nb-cart-backdrop"></div>
    <div class="nb-cart-drawer" id="nb-cart-drawer">
      <div class="nb-cart-header">
        <div style="display:flex;align-items:center;gap:8px">
          <span style="font-size:20px">🛒</span>
          <span style="font-weight:800;font-size:17px;color:var(--nb-ink)">سلة المشتريات</span>
        </div>
        <button class="nb-drawer-close" id="nb-cart-close">✕</button>
      </div>

      <div class="nb-cart-items" id="nb-cart-drawer-items"></div>

      <div class="nb-cart-footer">
        <div class="nb-cart-total-row">
          <span>المجموع الفرعي:</span>
          <span id="nb-cart-drawer-total" style="color:var(--nb-pink)">${money(0)}</span>
        </div>
        <a href="/checkout" class="nb-btn-primary" style="width:100%;text-align:center;margin-bottom:8px">
          إتمام الطلب — الدفع عند الاستلام 💵
        </a>
        <a href="/cart" style="display:block;text-align:center;font-size:13px;font-weight:700;color:var(--nb-ink-3);padding:6px">
          عرض السلة الكاملة
        </a>
      </div>
    </div>
  `;
  document.body.insertAdjacentHTML('beforeend', drawerHtml);

  document.getElementById('nb-cart-backdrop').addEventListener('click', closeCartDrawer);
  document.getElementById('nb-cart-close').addEventListener('click', closeCartDrawer);

  updateCartDrawerContent();
}

function updateCartDrawerContent() {
  const container = document.getElementById('nb-cart-drawer-items');
  const totalEl = document.getElementById('nb-cart-drawer-total');
  if (!container || !totalEl) return;

  const cart = getCart();
  if (!cart.items || cart.items.length === 0) {
    container.innerHTML = `
      <div style="text-align:center;padding:40px 10px;color:var(--nb-ink-3)">
        <div style="font-size:48px;margin-bottom:12px">🛒</div>
        <div style="font-weight:700;font-size:16px;color:var(--nb-ink)">سلتكِ فارغة حالياً</div>
        <div style="font-size:13px;margin-top:6px">تصفحي المتجر واختاري أفضل المنتجات لكِ ولطفلكِ</div>
        <a href="/shop" class="nb-btn-primary" style="margin-top:20px;font-size:14px;padding:8px 20px" onclick="window.nbCloseCart()">
          تسوقي الآن
        </a>
      </div>
    `;
    totalEl.textContent = money(0);
    return;
  }

  container.innerHTML = cart.items.map(item => `
    <div class="nb-cart-item">
      <img src="${item.image || '/favicon.png'}" alt="${item.name}" class="nb-cart-item-img">
      <div class="nb-cart-item-info">
        <div class="nb-cart-item-title">${item.name}</div>
        ${item.variant ? `<div style="font-size:12px;color:var(--nb-ink-3)">المقاس/النوع: ${item.variant}</div>` : ''}
        <div style="display:flex;align-items:center;justify-content:space-between;margin-top:8px">
          <div class="nb-cart-item-price">${money(item.price * item.qty)}</div>
          <div class="nb-cart-qty-ctrl">
            <button class="nb-cart-qty-btn" onclick="window.nbCartUpdate('${item.productId}', '${item.variant || ''}', ${item.qty - 1})">-</button>
            <span style="font-weight:800;font-size:13px">${item.qty}</span>
            <button class="nb-cart-qty-btn" onclick="window.nbCartUpdate('${item.productId}', '${item.variant || ''}', ${item.qty + 1})">+</button>
          </div>
        </div>
      </div>
    </div>
  `).join('');

  totalEl.textContent = money(getCartTotal());
}

export function openCartDrawer() {
  renderCartDrawer();
  document.getElementById('nb-cart-backdrop')?.classList.add('show');
  document.getElementById('nb-cart-drawer')?.classList.add('show');
}

export function closeCartDrawer() {
  document.getElementById('nb-cart-backdrop')?.classList.remove('show');
  document.getElementById('nb-cart-drawer')?.classList.remove('show');
}

window.nbOpenCart = openCartDrawer;
window.nbCloseCart = closeCartDrawer;
window.nbCartUpdate = (id, variant, qty) => {
  updateQty(id, variant, qty);
  updateCartDrawerContent();
};

// ── 7. Global Toast Notification ──
export function nbToast(msg, type = 'info') {
  let container = document.querySelector('.nb-toast-container');
  if (!container) {
    container = document.createElement('div');
    container.className = 'nb-toast-container';
    document.body.appendChild(container);
  }

  const toast = document.createElement('div');
  toast.className = 'nb-toast';
  const icon = type === 'success' ? '✅' : type === 'error' ? '⚠️' : '💗';
  toast.innerHTML = `<span>${icon}</span><span>${msg}</span>`;
  container.appendChild(toast);

  setTimeout(() => {
    toast.style.transition = 'all 0.3s ease';
    toast.style.opacity = '0';
    toast.style.transform = 'translateY(12px)';
    setTimeout(() => toast.remove(), 300);
  }, 3500);
}
window.nbToast = nbToast;

// ── 8. Shell Init & Auth Observer ──
export function initShell() {
  // Check cached user in sessionStorage for instantaneous render
  let cachedUser = null;
  let cachedData = null;
  try {
    const raw = sessionStorage.getItem('nb_user_cache');
    if (raw) {
      const parsed = JSON.parse(raw);
      cachedUser = parsed.user;
      cachedData = parsed.userData;
    }
  } catch (_) {}

  // Initial render with cache or visitor
  renderHeader(cachedUser, cachedData);
  renderFooter();
  renderMobileElements(cachedUser);
  if (cachedUser?.uid) showStaffLink(cachedUser.uid);
  renderCartDrawer();

  // Watch Cart Changes to update badges
  onCartChange(() => {
    const badge = document.querySelector('.nb-cart-badge');
    const count = getCartCount();
    if (badge) {
      if (count > 0) badge.textContent = count;
      else badge.remove();
    } else if (count > 0) {
      const btn = document.getElementById('nb-cart-trigger');
      if (btn) btn.insertAdjacentHTML('beforeend', `<span class="nb-cart-badge">${count}</span>`);
    }
    updateCartDrawerContent();
  });

  // مزامنة السلة بين التبويبات
  window.addEventListener('storage', (e) => { if (e.key === cartKey()) window.dispatchEvent(new CustomEvent('nb-cart-updated', { detail: getCart() })); });

  // صفحات الموقع التي لها نظير في التطبيق: المسجّلة تُفتح لها نسخة التطبيق
  // (إلا إذا اختارت «تصفّح الموقع» → sessionStorage.nb_site). المقالات والمتجر تبقى صفحات موقع.
  function shouldOpenApp() {
    try {
      const q = new URLSearchParams(location.search);
      if (q.get('site') === '1') sessionStorage.setItem('nb_site', '1');
      if (q.get('app') === '1') sessionStorage.removeItem('nb_site');
      if (sessionStorage.getItem('nb_site') === '1') return false;
    } catch (_) {}
    // الحاسوب: الموقع يبقى كما هو حتى بعد الدخول — التحويل على الهاتف فقط
    if (!(window.matchMedia('(max-width: 820px)').matches || /Android|iPhone|iPad|iPod|Mobile/i.test(navigator.userAgent))) return false;
    const p = location.pathname.replace(/\/+$/, '') || '/';
    return ['/', '/index.html', '/home.html', '/pregnancy', '/baby', '/cycle', '/fertility', '/community'].includes(p);
  }

  // Watch Auth State
  auth.onAuthStateChanged(async (user) => {
    // إشارة للتحويل الفوري (app-redirect.js) + تحويل المسجّلة من صفحات «التطبيق» إلى /app/
    try { localStorage.setItem('nb_auth', user ? '1' : '0'); } catch (_) {}
    if (user && shouldOpenApp()) { location.replace('/app/'); return; }
    if (user) {
      let userData = null;
      try {
        const snap = await db.collection('users').doc(user.uid).get();
        if (snap.exists) userData = snap.data();
      } catch (e) {
        console.error('Error fetching user doc in shell:', e);
      }

      try {
        sessionStorage.setItem('nb_user_cache', JSON.stringify({
          user: { uid: user.uid, displayName: user.displayName, email: user.email, photoURL: user.photoURL },
          userData
        }));
      } catch (_) {}

      renderHeader(user, userData);
      renderMobileElements(user);
      showStaffLink(user.uid);
    } else {
      sessionStorage.removeItem('nb_user_cache');
      renderHeader(null, null);
      renderMobileElements(null);
    }
  });
}

/** رابط «لوحة التحكم» يظهر فقط للطاقم النشط (staff/{uid}.isActive — نفس منطق AdminService في التطبيق) */
const ROLE_AR = { owner: 'المالك', supervisor: 'مشرفة', employee: 'موظفة', agent: 'وكيلة تأكيد' };
async function showStaffLink(uid) {
  let role = null;
  try {
    const c = JSON.parse(sessionStorage.getItem('nb_staff_' + uid) || 'null');
    if (c && Date.now() - c.t < 10 * 60 * 1000) role = c.role;
    else {
      const d = await db.collection('staff').doc(uid).get();
      role = d.exists && d.data().isActive !== false ? (d.data().role || 'employee') : '';
      sessionStorage.setItem('nb_staff_' + uid, JSON.stringify({ role, t: Date.now() }));
    }
  } catch (_) { role = ''; }
  if (!role) return;
  const link = (cls) => `<a href="/admin" class="${cls} nb-admin-link" style="display:flex;align-items:center;gap:8px;font-weight:800;color:#fff;background:linear-gradient(135deg,#1E1B2E,#4A2C5E);border-radius:12px;margin:6px 8px;padding:10px 14px;text-decoration:none">🛡️ لوحة التحكم <span style="margin-inline-start:auto;font-size:10.5px;background:rgba(255,255,255,.18);padding:2px 8px;border-radius:999px">${ROLE_AR[role] || role}</span></a>`;
  const a = document.getElementById('nb-staff-slot'); if (a) a.innerHTML = link('nb-dropdown-item');
  const b = document.getElementById('nb-staff-slot-m'); if (b) b.innerHTML = link('nb-drawer-link');
}

/* ── الدولة / السوق: زر العلم + اكتشاف أوّل زيارة + روابط المتجر بالبادئة الصحيحة ── */
function mountMarketSwitch() {
  const anchor = document.getElementById('nb-cart-trigger');
  if (!anchor || document.getElementById('nb-mk-btn')) return;
  const cur = MARKETS[currentMarket()];
  anchor.insertAdjacentHTML('beforebegin', `
    <div class="nb-mk" style="position:relative">
      <button id="nb-mk-btn" class="nb-cart-btn" title="الدولة والعملة: ${cur.name}" aria-label="تغيير الدولة" aria-haspopup="true" style="font-size:19px">${cur.flag}</button>
      <div id="nb-mk-menu" role="menu" style="display:none;position:absolute;top:calc(100% + 8px);left:0;min-width:210px;background:#fff;border:1px solid #F8E1EA;border-radius:16px;box-shadow:0 16px 40px rgba(233,30,99,.15);padding:6px;z-index:1200">
        <div style="font-size:11.5px;font-weight:800;color:#9b8f95;padding:6px 10px">التسوّق والتوصيل إلى:</div>
        ${Object.values(MARKETS).map((m) => `<button data-mk="${m.code}" role="menuitem" style="display:flex;align-items:center;gap:10px;width:100%;border:none;background:${m.code === cur.code ? '#FFF0F5' : 'none'};border-radius:11px;padding:10px;cursor:pointer;font-family:inherit;font-size:14px;font-weight:800;color:var(--nb-ink);text-align:right"><span style="font-size:20px">${m.flag}</span><span style="flex:1">${m.name}</span><span style="font-size:12px;color:#9b8f95">${m.symbol}</span>${m.code === cur.code ? '<span style="color:var(--nb-pink)">✓</span>' : ''}</button>`).join('')}
      </div>
    </div>`);
  const btn = document.getElementById('nb-mk-btn'); const menu = document.getElementById('nb-mk-menu');
  btn.addEventListener('click', (e) => { e.stopPropagation(); menu.style.display = menu.style.display === 'none' ? 'block' : 'none'; });
  document.addEventListener('click', (e) => { if (!e.target.closest('.nb-mk')) menu.style.display = 'none'; });
  menu.querySelectorAll('[data-mk]').forEach((b) => b.addEventListener('click', () => {
    const code = b.dataset.mk;
    saveMarket(code);
    if (code === currentMarket()) { menu.style.display = 'none'; return; }
    location.href = switchMarketUrl(code);
  }));
}

// نصوص بديلة حسب السوق في الصفحات الثابتة: data-mk-sa="…" (نص) أو data-mk-sa-html="…"
function applyMarketTexts() {
  const c = currentMarket().toLowerCase(); if (c === 'dz') return;
  document.querySelectorAll(`[data-mk-${c}]`).forEach((el) => { el.textContent = el.getAttribute(`data-mk-${c}`); });
  document.querySelectorAll(`[data-mk-${c}-html]`).forEach((el) => { el.innerHTML = el.getAttribute(`data-mk-${c}-html`); });
}
if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', applyMarketTexts); else applyMarketTexts();

// روابط المتجر في أي صفحة تأخذ بادئة السوق المختار (/sa/…) لحظة النقر
document.addEventListener('click', (e) => {
  const a = e.target.closest && e.target.closest('a[href^="/"]');
  if (!a || a.target === '_blank' || a.hasAttribute('data-mk-keep')) return;
  const h = a.getAttribute('href'); const n = mUrl(h);
  if (n !== h) a.setAttribute('href', n);
}, true);

// أوّل زيارة: اكتشاف الدولة؛ إن كانت سوقاً آخر ونحن في صفحة متجر بلا بادئة ننتقل إليها
if (!syncShopPath() && !savedMarket()) {
  const initial = currentMarket();
  detectCountryOnce().then(() => { const s = savedMarket(); if (s && s !== initial && !syncShopPath()) location.reload(); }).catch(() => {});
}

// Auto-run when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initShell);
} else {
  initShell();
}
