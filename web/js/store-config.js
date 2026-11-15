// ═══════════════════════════════════════════════════════════════════
//  إعدادات المتجر الحيّة (من site_config في Firestore — يديرها الأدمن) — حسب السوق
// ═══════════════════════════════════════════════════════════════════
import { db } from './firebase-init.js';
import { currentMarket, MARKETS, getMarketsConfig } from './market.js';

const CENTRAL = ['الجزائر', 'البليدة', 'بومرداس', 'تيبازة'];
const _shipping = {};
let _settings = null;

/** الجزائر: site_config/shipping = { "<الولاية>": { home, desk, enabled } }
 *  السعودية: site_config/shipping_SA = { "<المنطقة>": { home, enabled }, _default: { home } } */
export async function getShippingRates(code = currentMarket()) {
  if (_shipping[code]) return _shipping[code];
  try {
    const snap = await db.collection('site_config').doc(code === 'DZ' ? 'shipping' : 'shipping_' + code).get();
    _shipping[code] = snap.exists ? snap.data() : {};
  } catch (_) { _shipping[code] = {}; }
  return _shipping[code];
}

/** رسوم الشحن بعملة السوق: من جدول الأدمن، وإلا تقدير افتراضي */
export function shippingFeeFor(rates, region, isHome, code = currentMarket()) {
  if (!region) return 0;
  const r = rates && rates[region];
  if (code !== 'DZ') {
    if (r && r.home) return Number(r.home) || 0;
    return Number(rates?._default?.home ?? MARKETS[code]?.defaultShipping ?? 0) || 0;
  }
  if (r && (r.home || r.desk)) return Number(isHome ? (r.home || r.desk) : (r.desk || r.home)) || 0;
  const central = CENTRAL.includes(region);
  return isHome ? (central ? 450 : 650) : (central ? 300 : 400);
}

/** هل الولاية/المنطقة متاحة للتوصيل؟ (enabled === false تعني موقوفة) */
export function wilayaEnabled(rates, wilaya) {
  return !(rates && rates[wilaya] && rates[wilaya].enabled === false);
}

/**
 * site_config/settings = { whatsapp, storeName, returnPolicy, shippingPolicy, shopBanner }
 * للأسواق الأخرى تُستبدل بقيم site_config/markets.<CC> (رقم واتساب، لافتة وسياسات بلهجة السوق)
 */
export async function getStoreSettings() {
  if (_settings) return _settings;
  try {
    const snap = await db.collection('site_config').doc('settings').get();
    _settings = snap.exists ? snap.data() : {};
  } catch (_) { _settings = {}; }
  const code = currentMarket();
  if (code !== 'DZ') {
    const m = (await getMarketsConfig(db))?.[code] || {};
    _settings = { ..._settings, whatsapp: m.whatsapp || '', shopBanner: m.shopBanner || '', shippingPolicy: m.shippingPolicy || '', returnPolicy: m.returnPolicy || '' };
  }
  return _settings;
}

/** رابط واتساب صالح، أو null إن لم يُضبط الرقم في لوحة التحكم */
export function whatsappLink(settings, text) {
  const num = String((settings && settings.whatsapp) || '').replace(/\D/g, '');
  if (num.length < 9) return null;
  return `https://wa.me/${num}?text=${encodeURIComponent(text || '')}`;
}
