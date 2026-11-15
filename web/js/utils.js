// ═══════════════════════════════════════════════════════════════════
//  أدوات مشتركة لكل صفحات موقع نبضة
// ═══════════════════════════════════════════════════════════════════
import { db } from './firebase-init.js';
import { isHiddenProduct } from './shop-rules.js';
import { currentMarket, mAvailable, localize, money, mUrl, marketEnabled } from './market.js';

/** تحويل أي قيمة تاريخ (Timestamp من Firestore، كائن {seconds} مخزّن، نص، رقم) إلى Date */
export function toDate(v) {
  if (!v) return null;
  if (v instanceof Date) return isNaN(v) ? null : v;
  if (typeof v.toDate === 'function') return v.toDate();
  if (typeof v === 'object' && 'seconds' in v) return new Date(v.seconds * 1000);
  if (typeof v === 'object' && '_seconds' in v) return new Date(v._seconds * 1000);
  const d = new Date(v);
  return isNaN(d) ? null : d;
}

/** نفس حساب التطبيق (main.dart): الأسبوع = floor(الأيام/7) بين 1 و 42 */
export function pregnancyFromStart(start) {
  const s = toDate(start);
  if (!s) return null;
  const days = Math.floor((Date.now() - s.getTime()) / 86400000);
  const week = Math.min(42, Math.max(1, Math.floor(days / 7)));
  const daysLeft = Math.max(0, 280 - days);
  const due = new Date(s.getTime() + 280 * 86400000);
  return { start: s, days, week, daysLeft, due, postTerm: days > 294 };
}

/** مثل PregnancyDates في التطبيق: dueDate (من الطبيبة/الإيكو) أولى من آخر دورة */
export function pregnancyFromUser(d) {
  if (!d) return null;
  const due = toDate(d.dueDate);
  const lmp = toDate(d.pregnancyStartDate) || toDate(d.pregnancyStart) || toDate(d.lastPeriodDate);
  const start = due ? new Date(due.getTime() - 280 * 86400000) : lmp;
  if (!start) return null;
  // من أنهت حملها (ولادة) تُحفظ pregnancyStartDate = null — لا نعتمد dueDate قديماً حينها
  if (!lmp && d.lifeStage === 'baby') return null;
  return pregnancyFromStart(start);
}

export function escapeHtml(str) {
  if (str === null || str === undefined) return '';
  return String(str).replace(/[&<>"']/g, (m) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[m]));
}

/** مسار صورة مقال صالح من أي صفحة (المسارات النسبية تنكسر تحت /pregnancy/week-N) */
export function articleImg(p) {
  if (!p) return '/img/articles_bg/bg_pregnancy_01.jpg';
  if (/^https?:\/\//.test(p)) return p;
  const file = p.split('/').pop();
  if (p.includes('articles_bg')) return '/img/articles_bg/' + file;
  return '/' + p.replace(/^\.?\//, '');
}

/** التصنيفات الفرعية الطبية المخفية (نسخة من kMedicalSubcategories في play_compliance.dart) */
export const MEDICAL_SUBCATS = new Set([
  'health_diseases_prevention', 'preg_health_tests', 'fert_pcos_hormones', 'fert_ivf_medical', 'baby_health_care',
]);

const _topCache = {};
/** أفضل 80 مقالاً لتصنيف (ملف خفيف ~50KB، مرتّب حسب القراءات، بلا التصنيفات الطبية)
 *  cat: pregnancy | baby | fertility | health | beauty | marriage */
export async function getTopArticles(cat) {
  if (_topCache[cat]) return _topCache[cat];
  try {
    const res = await fetch(`/data/articles/top_${cat}.json`);
    const list = await res.json();
    _topCache[cat] = list.filter((a) => !MEDICAL_SUBCATS.has(a.subcategoryId));
  } catch (_) { _topCache[cat] = []; }
  return _topCache[cat];
}

let _productsCache = null;
/**
 * كل المنتجات المعروضة في السوق الحالي (نشطة، غير مخفية، ولها سعر في هذا السوق)،
 * مُوطَّنة: price/oldPrice/stock/name/description بقيم السوق (انظري market.js)
 */
export async function getVisibleProducts() {
  if (_productsCache) return _productsCache;
  const code = currentMarket();
  // سوق مغلق (مثلاً السعودية قبل الافتتاح): لا منتجات في أي مكان من الموقع
  if (!(await marketEnabled(db, code))) { _productsCache = []; return _productsCache; }
  const snap = await db.collection('products').get();
  const list = [];
  snap.forEach((doc) => {
    const p = { id: doc.id, ...doc.data() };
    if (isHiddenProduct(p)) return;
    if (!mAvailable(p, code)) return;
    list.push(localize(p, code));
  });
  list.sort((a, b) => (toDate(b.createdAt)?.getTime() || 0) - (toDate(a.createdAt)?.getTime() || 0));
  _productsCache = list;
  return list;
}

export function productImg(p) {
  // مخطّط التطبيق: imageUrls + coverImage (images/image للتوافق مع القديم)
  return (p.images && p.images[0]) || (p.imageUrls && p.imageUrls[0]) || p.coverImage || p.imageUrl || p.image || '/landing-assets/slide-store.webp';
}
/** كل صور المنتج بالترتيب */
export function productImages(p) {
  const list = (Array.isArray(p.images) && p.images.length ? p.images : Array.isArray(p.imageUrls) && p.imageUrls.length ? p.imageUrls : [p.coverImage || p.imageUrl || p.image]).filter(Boolean);
  return list.length ? list : ['/landing-assets/slide-store.webp'];
}
/** السعر القديم (المنتج مُوطَّن مسبقاً بـ localize) */
export function productOldPrice(p) {
  const o = Number(p.oldPrice || p.originalPrice || 0);
  return o > Number(p.price || 0) ? o : 0;
}
export function productUrl(p) {
  return mUrl('/product/' + encodeURIComponent(p.slug || p.id));
}
/** المبلغ بعملة السوق الحالي (الاسم تاريخي: كان بالدينار فقط) */
export function formatDA(n) {
  return money(n);
}

/** مطابقة منتج لمرحلة: pregnant | newborn | baby | mom */
const STAGE_WORDS = {
  pregnant: ['حمل', 'حامل', 'أمومة', 'ولادة', 'حقيبة'],
  newborn: ['مولود', 'رضاعة', 'رضيع', 'حفاض', 'حديثي'],
  baby: ['ألعاب', 'لعبة', 'أطفال', 'طفل'],
  mom: ['الأم', 'العناية', 'تجميل', 'بشرة'],
};
export function productMatchesStage(p, stage) {
  if ((p.lifeStageTags || []).includes(stage)) return true;
  const txt = `${p.category || ''} ${p.name || ''}`;
  return (STAGE_WORDS[stage] || []).some((w) => txt.includes(w));
}

/** بطاقة منتج موحّدة لكل الكاروسالات */
export function productCardHtml(p) {
  const old = productOldPrice(p);
  const off = old ? Math.round((1 - Number(p.price) / old) * 100) : 0;
  return `
    <a class="nb-prod-card" href="${productUrl(p)}">
      <div class="nb-prod-img-wrap">
        <img src="${escapeHtml(productImg(p))}" alt="${escapeHtml(p.name)}" class="nb-prod-img" loading="lazy">
        ${off ? `<span class="nb-prod-off">-${off}%</span>` : ''}
      </div>
      <div class="nb-prod-body">
        <div>
          <div class="nb-prod-cat">${escapeHtml(p.category || 'متجر نبضة')}</div>
          <h4 class="nb-prod-name">${escapeHtml(p.name)}</h4>
        </div>
        <div class="nb-prod-price-row">
          <span class="nb-prod-price">${formatDA(p.price)}</span>
          ${old ? `<span class="nb-prod-old">${formatDA(old)}</span>` : ''}
        </div>
      </div>
    </a>`;
}

/** بطاقة مقال موحّدة */
export function articleCardHtml(a, emoji = '📖') {
  return `
    <a href="/article/${encodeURIComponent(a.id)}" class="nb-art-card">
      <div class="nb-art-img-wrap">
        <img src="${escapeHtml(articleImg(a.imagePath))}" alt="${escapeHtml(a.title)}" class="nb-art-img" loading="lazy">
        <span class="nb-art-float-cat">${emoji} ${escapeHtml(a.categoryName || 'موسوعة نبضة')}</span>
      </div>
      <div class="nb-art-body">
        <div>
          <h4 class="nb-art-title">${escapeHtml(a.title)}</h4>
          <p class="nb-art-desc">${escapeHtml(a.summary || '')}</p>
        </div>
        <div class="nb-art-footer">
          <span class="nb-art-time">⏱️ ${escapeHtml(a.readTime || '3 دقائق')}</span>
          <span class="nb-art-cta">قراءة المقال ←</span>
        </div>
      </div>
    </a>`;
}
