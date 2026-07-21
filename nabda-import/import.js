/**
 * نبضة — سكريبت استيراد كل المنتجات من متاجر المنافسين ورفعها إلى Firestore
 * ----------------------------------------------------------------------
 * يجلب الكتالوجات من:
 *   1) El Baraa   (Shopify)   → products.json
 *   2) Le coin    (FlexDZ)    → sitemap + JSON-LD / OpenGraph
 *   3) Firas Jeux (منصة خاصة)  → sitemap + JSON-LD / OpenGraph
 *
 * ثم يحوّلها لصيغة نبضة ويرفعها إلى مجموعة Firestore اسمها "products".
 * السعر يبقى كما هو في المتجر الأصلي (بدون هامش) — العمولة تُخصم لاحقاً.
 *
 * التشغيل:
 *   1) npm install
 *   2) ضع مفتاح خدمة Firebase باسم serviceAccount.json في نفس المجلد
 *   3) node import.js            (يرفع إلى Firestore)
 *      node import.js --dry      (يحفظ products.json فقط بدون رفع — للمعاينة)
 */

const fs = require('fs');
const path = require('path');

// ====== الإعدادات ======
const STORES = [
  { name: 'El Baraa',  base: 'https://elbaraa.myshopify.com', type: 'shopify' },
  { name: 'Le coin des accessoires', base: 'https://lecoindesaccessoires.flexdz.store', type: 'generic' },
  { name: 'Firas Jeux', base: 'https://firasjeux.com', type: 'generic' },
];
const COLLECTION = 'products';
const CURRENCY = 'DZD';
const DRY = process.argv.includes('--dry');
// UID مالك المتجر في نبضة (يُنسب المنتج إليه) — من مستند منتج موجود
const OWNER_UID = 'zG9jnOX9U3eXs2r3t5ENO8v2HH52';

// ====== أدوات مساعدة ======
const sleep = (ms) => new Promise(r => setTimeout(r, ms));
async function getText(url) {
  const res = await fetch(url, { headers: { 'User-Agent': 'Mozilla/5.0 NabdaImporter' } });
  if (!res.ok) throw new Error(`HTTP ${res.status} @ ${url}`);
  return res.text();
}
async function getJson(url) { return JSON.parse(await getText(url)); }
function clean(s) { return (s || '').replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim(); }
function slug(s) { return (s || '').toString().trim().toLowerCase().replace(/[^\w؀-ۿ]+/g, '-').replace(/^-+|-+$/g, '').slice(0, 60); }

// تخمين فئة نبضة (نفس فئات المتجر في التطبيق)
function guessCategory(title) {
  const t = (title || '').toLowerCase();
  if (/(حلمة|رضاع|شفاط|حليب|تغذية|breast|lait|tire|biberon)/i.test(t)) return 'الرضاعة والتغذية';
  if (/(حفاض|بانيو|منشفة|نظاف|couche|serviette|bain)/i.test(t)) return 'الحفاضات والنظافة';
  if (/(مولود|body|barboteuse|ملابس.*مولود)/i.test(t)) return 'ملابس المولود';
  if (/(سرير|فراش|بينوار|مطلة|لعب|كرسي|matelas|jeu|toy|رضيع|bébé|bebe)/i.test(t)) return 'لوازم الرضيع';
  if (/(فيتامين|مكمل|مسمنة|vitamin)/i.test(t)) return 'فيتامينات ومكملات';
  if (/(حقيبة الولادة|valise)/i.test(t)) return 'حقيبة الولادة';
  if (/(ملابس.*حمل|حامل)/i.test(t)) return 'ملابس الحمل';
  return 'عناية بالحامل';
}
const EMOJIS = { 'الرضاعة والتغذية':'🍼','الحفاضات والنظافة':'🧴','ملابس المولود':'👶','لوازم الرضيع':'🧸','فيتامينات ومكملات':'💊','حقيبة الولادة':'🎒','ملابس الحمل':'🤰','عناية بالحامل':'🌸' };

// ====== جلب متجر Shopify ======
async function fetchShopify(store) {
  const out = [];
  for (let page = 1; page <= 20; page++) {
    let data;
    try { data = await getJson(`${store.base}/products.json?limit=250&page=${page}`); }
    catch (e) { break; }
    if (!data.products || !data.products.length) break;
    for (const p of data.products) {
      const v = p.variants && p.variants[0];
      out.push({
        title: p.title.trim(),
        price: v ? parseInt(v.price) || 0 : 0,
        description: clean(p.body_html),
        images: (p.images || []).map(i => i.src.split('?')[0]),
        link: `${store.base}/products/${p.handle}`,
        store: store.name,
      });
    }
    await sleep(300);
  }
  return out;
}

// ====== جلب متجر عام (FlexDZ / منصة خاصة) عبر sitemap + JSON-LD ======
async function fetchGeneric(store) {
  const out = [];
  // 1) جرّب products.json (بعض المنصات تدعمه)
  try {
    const data = await getJson(`${store.base}/products.json?limit=250`);
    if (data.products && data.products.length) return fetchShopify(store);
  } catch (e) {}

  // 2) اجمع روابط المنتجات من sitemap
  let urls = new Set();
  for (const sm of ['/sitemap.xml', '/sitemap_products_1.xml', '/product-sitemap.xml', '/sitemap-products.xml']) {
    try {
      const xml = await getText(store.base + sm);
      const locs = [...xml.matchAll(/<loc>([^<]+)<\/loc>/g)].map(m => m[1]);
      // إن كان sitemap فهرساً، ادخل الفرعية
      for (const l of locs) {
        if (/sitemap.*\.xml/i.test(l)) {
          try { const sub = await getText(l); [...sub.matchAll(/<loc>([^<]+)<\/loc>/g)].forEach(m => urls.add(m[1])); } catch (e) {}
        } else urls.add(l);
      }
    } catch (e) {}
  }
  const productUrls = [...urls].filter(u => /\/product/i.test(u));
  console.log(`   ${store.name}: ${productUrls.length} رابط منتج من sitemap`);

  // 3) افتح كل صفحة واستخرج JSON-LD أو OpenGraph
  for (const url of productUrls) {
    try {
      const html = await getText(url);
      let prod = extractJsonLd(html) || extractOg(html);
      if (prod && prod.title) {
        out.push({
          title: prod.title.trim(),
          price: prod.price || 0,
          description: clean(prod.description),
          images: prod.images || [],
          link: url,
          store: store.name,
        });
      }
    } catch (e) {}
    await sleep(250);
  }
  return out;
}

function extractJsonLd(html) {
  const blocks = [...html.matchAll(/<script[^>]*type=["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi)];
  for (const b of blocks) {
    try {
      let data = JSON.parse(b[1].trim());
      const arr = Array.isArray(data) ? data : (data['@graph'] || [data]);
      const prod = arr.find(x => x['@type'] === 'Product' || (Array.isArray(x['@type']) && x['@type'].includes('Product')));
      if (prod) {
        const offers = Array.isArray(prod.offers) ? prod.offers[0] : prod.offers;
        return {
          title: prod.name,
          description: prod.description,
          images: [].concat(prod.image || []).map(i => typeof i === 'string' ? i : i.url).filter(Boolean),
          price: offers ? parseInt(offers.price) || 0 : 0,
        };
      }
    } catch (e) {}
  }
  return null;
}
function extractOg(html) {
  const m = (p) => { const r = html.match(new RegExp(`<meta[^>]+property=["']${p}["'][^>]+content=["']([^"']+)["']`, 'i')); return r ? r[1] : ''; };
  const title = m('og:title'); if (!title) return null;
  const img = m('og:image');
  const price = m('product:price:amount') || m('og:price:amount');
  return { title, description: m('og:description'), images: img ? [img] : [], price: parseInt(price) || 0 };
}

// ====== التحويل لمخطط نبضة الحقيقي (Firestore collection: products) ======
function toNabda(p) {
  const cat = guessCategory(p.title);
  const priceStr = String(p.price);
  const imgs = (p.images && p.images.length) ? p.images : [];
  return {
    name: p.title,
    shortName: p.title.slice(0, 40),
    category: cat,
    description: p.description || '',
    shortDescription: (p.description || '').slice(0, 60),
    price: priceStr,
    oldPrice: '',
    costPrice: '',
    imageUrl: imgs[0] || '',
    imageUrls: imgs,
    coverImage: imgs[0] || '',
    descImages: [],
    emoji: EMOJIS[cat] || '🌸',
    displayType: 'card',
    stock: 50,
    weight: 0,
    rating: 5,
    reviews: [],
    secondaryOptions: [],
    variants: [],
    offers: [{
      title: 'قطعة واحدة', quantity: 1, pricePerPiece: Number(p.price) || 0,
      isDefault: true, isBest: false, freeShipping: false, image: ''
    }],
    settings: { allowBackorder: false, customThankYou: false, hideRelated: false, skipCart: true, strictOptions: false, thankYouText: '' },
    shipping: { customShipping: false, customShippingPickup: false, customShippingPickupPrice: 0, customShippingPrice: 0, freeShipping: false, freeShippingPickupOnly: true },
    // بيانات مصدر داخلية (لا يستعملها التطبيق لكنها مفيدة للتتبع)
    _sourceStore: p.store,
    _sourceLink: p.link,
    _imagesRegenerated: false,
    createdBy: OWNER_UID,
  };
}

// ====== main ======
(async () => {
  let all = [];
  for (const store of STORES) {
    console.log(`\n📦 جلب: ${store.name} ...`);
    try {
      const items = store.type === 'shopify' ? await fetchShopify(store) : await fetchGeneric(store);
      console.log(`   ✓ ${items.length} منتج`);
      all = all.concat(items);
    } catch (e) { console.log(`   ✗ فشل: ${e.message}`); }
  }

  // إزالة التكرار حسب الرابط
  const seen = new Set();
  all = all.filter(p => (p.link && !seen.has(p.link)) ? seen.add(p.link) : false);
  const products = all.filter(p => p.price > 0).map(toNabda);

  console.log(`\n🧮 الإجمالي بعد التنظيف: ${products.length} منتج`);

  // احفظ نسخة JSON دائماً
  const snap = path.join(__dirname, 'nabda-products.json');
  fs.writeFileSync(snap, JSON.stringify({ store: 'nabda', currency: CURRENCY, count: products.length, products }, null, 2), 'utf8');
  console.log(`💾 حُفظت نسخة: ${snap}`);

  if (DRY) { console.log('\n(وضع المعاينة --dry: لم يتم الرفع إلى Firestore)'); return; }

  // الرفع إلى Firestore
  const saPath = path.join(__dirname, 'serviceAccount.json');
  if (!fs.existsSync(saPath)) {
    console.log('\n⚠️ لم يُعثر على serviceAccount.json — تم تخطي الرفع. حمّل المفتاح من Firebase Console → إعدادات المشروع → حسابات الخدمة.');
    return;
  }
  const admin = require('firebase-admin');
  admin.initializeApp({ credential: admin.credential.cert(require(saPath)) });
  const db = admin.firestore();

  console.log(`\n⬆️ الرفع إلى مجموعة "${COLLECTION}" ...`);
  const TS = admin.firestore.FieldValue.serverTimestamp();
  let n = 0;
  // دفعات من 400 (حد Firestore 500 لكل batch) — معرّفات تلقائية كما يفعل التطبيق
  for (let i = 0; i < products.length; i += 400) {
    const batch = db.batch();
    for (const p of products.slice(i, i + 400)) {
      const ref = db.collection(COLLECTION).doc(); // auto-ID
      batch.set(ref, { ...p, createdAt: TS, updatedAt: TS });
      n++;
    }
    await batch.commit();
    console.log(`   … ${n}/${products.length}`);
  }
  console.log(`\n✅ تم رفع ${n} منتج إلى Firestore (${COLLECTION}) — ستظهر في متجر نبضة مباشرة.`);
})();
