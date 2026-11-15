// ═══════════════════════════════════════════════════════════════════
//  الأسواق (الدول) — كل دولة سوق مستقل: عملة، أسعار، منتجات متاحة، شحن، لهجة
//
//  مخطّط المنتج (متوافق مع التطبيق):
//   - الجزائر = الحقول الأصلية: price / oldPrice / stock / name / description (لا ترحيل)
//   - الأسواق الأخرى: markets.SA = { price:"89", oldPrice:"", active:true, stock? }
//                     i18n.SA    = { name, description, shortDescription }  (نص باللهجة، اختياري)
//   - منتج بلا سعر في سوق ⇒ لا يظهر فيه. لا تحويل آلي للعملة أبداً.
//  الاختيار: مسار /sa/… ⇐ اختيار محفوظ ⇐ دولة عنوان الإنترنت ⇐ الجزائر
// ═══════════════════════════════════════════════════════════════════

export const MARKETS = {
  DZ: {
    code: 'DZ', flag: '🇩🇿', name: 'الجزائر', currency: 'DZD', symbol: 'دج', decimals: 0, prefix: '',
    phoneCC: '213', phoneHint: '0550123456', phoneLabel: 'رقم الهاتف (موبيليس، جيزي، أوريدو)',
    regionLabel: 'الولاية', cityLabel: 'البلدية', hasOffice: true, locale: 'ar-DZ',
  },
  SA: {
    code: 'SA', flag: '🇸🇦', name: 'السعودية', currency: 'SAR', symbol: 'ر.س', decimals: 2, prefix: '/sa',
    phoneCC: '966', phoneHint: '0551234567', phoneLabel: 'رقم الجوال',
    regionLabel: 'المنطقة', cityLabel: 'المدينة / الحي', hasOffice: false, locale: 'ar-SA',
    defaultShipping: 30,
  },
};
export const MARKET_CODES = Object.keys(MARKETS);
export const SA_REGIONS = ['الرياض', 'مكة المكرمة', 'المدينة المنورة', 'القصيم', 'الشرقية', 'عسير', 'تبوك', 'حائل', 'الحدود الشمالية', 'جازان', 'نجران', 'الباحة', 'الجوف'];

const KEY = 'nb_market';
const SHOP_PATH = /^\/(shop|product|cart|checkout)(\/|\?|#|$)/;

/** السوق من المسار (/sa/…) أو null */
export function marketFromPath(path = location.pathname) {
  const m = path.match(/^\/([a-z]{2})(\/|$)/);
  if (!m) return null;
  const c = m[1].toUpperCase();
  return MARKETS[c] && MARKETS[c].prefix ? c : null;
}

/** السوق الحالي (متزامن) */
export function currentMarket() {
  const fromPath = marketFromPath();
  if (fromPath) return fromPath;
  // صفحات المتجر بلا بادئة = الجزائر دائماً (روابط ثابتة لمحرّكات البحث)
  if (SHOP_PATH.test(location.pathname)) return 'DZ';
  try { const s = localStorage.getItem(KEY); if (MARKETS[s]) return s; } catch (_) {}
  return 'DZ';
}
export const M = () => MARKETS[currentMarket()];

/** الاختيار المحفوظ فقط (null إن لم تختر المستخدمة بعد) */
export function savedMarket() { try { const s = localStorage.getItem(KEY); return MARKETS[s] ? s : null; } catch (_) { return null; } }
export function saveMarket(code) { try { localStorage.setItem(KEY, code); localStorage.setItem(KEY + '_manual', '1'); } catch (_) {} }

/** رابط داخل المتجر بالبادئة الصحيحة: mUrl('/product/x') → /sa/product/x */
export function mUrl(path, code = currentMarket()) {
  const clean = String(path || '/').replace(/^\/[a-z]{2}(?=\/)/, '');
  if (!SHOP_PATH.test(clean)) return clean;
  return (MARKETS[code]?.prefix || '') + clean;
}

/** نفس الصفحة في سوق آخر */
export function switchMarketUrl(code) {
  const base = location.pathname.replace(/^\/[a-z]{2}(?=\/|$)/, '') || '/';
  return mUrl(base, code) + location.search;
}

/**
 * لصفحات المتجر: /sa/… يحفظ السوق، و /shop بلا بادئة لمن اختارت سوقاً آخر يُحوَّل إلى بادئتها.
 * يعيد true إن بدأ التحويل (أوقفي تهيئة الصفحة حينها).
 */
export function syncShopPath() {
  const plain = location.pathname.replace(/^\/[a-z]{2}(?=\/|$)/, '') || '/';
  if (!SHOP_PATH.test(plain)) return false;
  const fromPath = marketFromPath();
  if (fromPath) { try { localStorage.setItem(KEY, fromPath); } catch (_) {} return false; }
  const s = savedMarket();
  if (s && s !== 'DZ') { location.replace(switchMarketUrl(s)); return true; }
  return false;
}

/**
 * عند أوّل زيارة: نكتشف الدولة من عنوان الإنترنت (مرّة واحدة). إن كانت سوقاً مدعوماً تُحفظ.
 * يعيد رمز الدولة المكتشف (حتى غير المدعوم، مثل MA) أو null.
 */
export async function detectCountryOnce() {
  try { if (localStorage.getItem(KEY + '_detected')) return localStorage.getItem(KEY + '_detected'); } catch (_) {}
  let cc = null;
  const tries = [
    async (signal) => (await (await fetch('https://api.country.is/', { cache: 'no-store', signal })).json()).country,
    async (signal) => (await (await fetch('https://ipapi.co/country/', { cache: 'no-store', signal })).text()).trim(),
  ];
  for (const t of tries) {
    const ctl = new AbortController(); const timer = setTimeout(() => ctl.abort(), 3500);
    try { cc = String(await t(ctl.signal) || '').toUpperCase().slice(0, 2); } catch (_) { cc = null; }
    clearTimeout(timer);
    if (cc && /^[A-Z]{2}$/.test(cc)) break; else cc = null;
  }
  try {
    localStorage.setItem(KEY + '_detected', cc || '??');
    if (cc && MARKETS[cc] && !localStorage.getItem(KEY + '_manual')) localStorage.setItem(KEY, cc);
  } catch (_) {}
  return cc;
}

/* ─────────── أسعار المنتج ونصّه حسب السوق ─────────── */
export function mPrice(p, code = currentMarket()) {
  if (code === 'DZ') return Number(p.price || 0);
  return Number(p.markets?.[code]?.price || 0);
}
export function mOldPrice(p, code = currentMarket()) {
  const price = mPrice(p, code);
  const o = code === 'DZ' ? Number(p.oldPrice || p.originalPrice || 0) : Number(p.markets?.[code]?.oldPrice || 0);
  return o > price ? o : 0;
}
export function mStock(p, code = currentMarket()) {
  if (code === 'DZ') return p.stock;
  const s = p.markets?.[code]?.stock;
  return typeof s === 'number' ? s : undefined;
}
/** متاح للبيع في هذا السوق؟ (الحظر العام isHiddenProduct يُطبّق خارجاً) */
export function mAvailable(p, code = currentMarket()) {
  if (!p || p.active === false) return false;
  if (code === 'DZ') return p.markets?.DZ?.active !== false;
  const m = p.markets?.[code];
  return !!m && m.active !== false && Number(m.price) > 0;
}
export function mText(p, field, code = currentMarket()) {
  const v = p.i18n?.[code]?.[field];
  return (typeof v === 'string' && v.trim()) ? v : p[field];
}

/**
 * نسخة من المنتج «مُوطَّنة» للسوق: price/oldPrice/stock/name/description بقيم السوق،
 * فتعمل كل الصفحات الحالية (التي تقرأ p.price و p.name) دون تعديل.
 */
export function localize(p, code = currentMarket()) {
  if (!p) return p;
  const out = { ...p, _market: code, price: mPrice(p, code), oldPrice: mOldPrice(p, code), originalPrice: 0 };
  const st = mStock(p, code);
  if (typeof st === 'number') out.stock = st; else delete out.stock;
  ['name', 'shortName', 'description', 'shortDescription', 'seoTitle', 'seoDescription'].forEach((f) => { const v = mText(p, f, code); if (v !== undefined) out[f] = v; });
  return out;
}

/** تنسيق المبلغ بعملة السوق: 3,500 دج — 89 ر.س — 89.50 ر.س */
export function money(n, code = currentMarket()) {
  const m = MARKETS[code] || MARKETS.DZ;
  const v = Number(n || 0);
  const s = m.decimals && v % 1 !== 0 ? v.toLocaleString('en-US', { minimumFractionDigits: m.decimals, maximumFractionDigits: m.decimals }) : Math.round(v).toLocaleString('en-US');
  return `${s} ${m.symbol}`;
}

/* ─────────── الهاتف ─────────── */
const digits = (v) => String(v || '').replace(/[٠-٩]/g, (d) => '٠١٢٣٤٥٦٧٨٩'.indexOf(d)).replace(/[۰-۹]/g, (d) => '۰۱۲۳۴۵۶۷۸۹'.indexOf(d));
export function normPhoneFor(v, code = currentMarket()) {
  let p = digits(v).replace(/[\s\-.()]/g, '');
  const cc = MARKETS[code]?.phoneCC || '213';
  if (p.startsWith('+' + cc)) p = '0' + p.slice(cc.length + 1);
  else if (p.startsWith('00' + cc)) p = '0' + p.slice(cc.length + 2);
  else if (p.startsWith(cc) && p.length === cc.length + 9) p = '0' + p.slice(cc.length);
  else if (code === 'SA' && /^5\d{8}$/.test(p)) p = '0' + p;
  return p;
}
export function validPhoneFor(p, code = currentMarket()) {
  return code === 'SA' ? /^05\d{8}$/.test(p) : /^0[567]\d{8}$/.test(p);
}
/** الصيغة الدولية للتواصل عبر واتساب: 9665XXXXXXXX */
export function intlPhone(p, code = currentMarket()) {
  return (MARKETS[code]?.phoneCC || '213') + String(p).replace(/^0/, '');
}

/* ─────────── إعدادات الأسواق من لوحة التحكم ─────────── */
let _cfg = null;
/** site_config/markets = { SA: { enabled: true, whatsapp, shopBanner, comingSoonText } } — الجزائر مفعّلة دائماً */
export async function getMarketsConfig(db) {
  if (_cfg) return _cfg;
  try { const d = await db.collection('site_config').doc('markets').get(); _cfg = d.exists ? d.data() : {}; } catch (_) { _cfg = {}; }
  return _cfg;
}
export async function marketEnabled(db, code = currentMarket()) {
  if (code === 'DZ') return true;
  const c = await getMarketsConfig(db);
  return c?.[code]?.enabled === true;
}
