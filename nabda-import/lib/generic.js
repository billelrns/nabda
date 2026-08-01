// جالب عام لمنصات لا تدعم products.json (FlexDZ / Firas / WooCommerce / مخصص)
// الاستراتيجية بالترتيب:
//   1) WooCommerce Store API  (/wp-json/wc/store/products)  — إن وُجد
//   2) sitemap.xml → صفحات المنتجات → JSON-LD (schema.org/Product) + Open Graph
//
// ملاحظة: بعض المنصات (FlexDZ/Firas) تُصيّر المحتوى عبر JavaScript وتمنع الجلب البسيط.
// إن أعاد هذا الجالب 0 منتج، فالمنصة تحتاج جلباً عبر المتصفح (Chrome) — انظر README.

const { getText, getJson } = require('./http');
const { stripHtml } = require('./shopify');

function clean(u) {
  return u.replace(/\/+$/, '');
}

// ── 1) WooCommerce Store API ───────────────────────────────────────────
async function tryWoo(base) {
  const out = [];
  for (let page = 1; page <= 50; page++) {
    let data;
    try {
      data = await getJson(`${base}/wp-json/wc/store/products?per_page=100&page=${page}`);
    } catch {
      return null; // ليست WooCommerce
    }
    if (!Array.isArray(data) || data.length === 0) break;
    for (const p of data) {
      const images = (p.images || []).map((im) => im.src).filter(Boolean);
      out.push({
        sourceId: String(p.id),
        name: (p.name || '').trim(),
        description: stripHtml(p.description || p.short_description || ''),
        price: p.prices ? centsToStr(p.prices.price, p.prices) : '',
        oldPrice:
          p.prices && p.prices.regular_price && p.prices.regular_price !== p.prices.price
            ? centsToStr(p.prices.regular_price, p.prices)
            : '',
        images,
        url: p.permalink || base,
        tags: (p.categories || []).map((c) => c.name),
      });
    }
    if (data.length < 100) break;
  }
  return out.length ? out : null;
}

function centsToStr(val, prices) {
  const minor = prices.currency_minor_unit != null ? prices.currency_minor_unit : 2;
  const n = Number(val) / Math.pow(10, minor);
  return Number.isFinite(n) ? String(Math.round(n)) : '';
}

// ── 2) sitemap + JSON-LD ───────────────────────────────────────────────
async function collectSitemapUrls(base) {
  const candidates = [
    `${base}/sitemap.xml`,
    `${base}/sitemap_index.xml`,
    `${base}/product-sitemap.xml`,
    `${base}/sitemap-products.xml`,
  ];
  const urls = new Set();
  for (const sm of candidates) {
    let xml;
    try {
      xml = await getText(sm);
    } catch {
      continue;
    }
    const locs = [...xml.matchAll(/<loc>\s*([^<]+?)\s*<\/loc>/gi)].map((m) => m[1]);
    // إن كان فهرس sitemaps فرعية اجلبها
    const subs = locs.filter((u) => /sitemap.*\.xml/i.test(u));
    if (subs.length) {
      for (const s of subs) {
        try {
          const sx = await getText(s);
          [...sx.matchAll(/<loc>\s*([^<]+?)\s*<\/loc>/gi)].forEach((m) => urls.add(m[1]));
        } catch {}
      }
    } else {
      locs.forEach((u) => urls.add(u));
    }
  }
  // أبقِ روابط تبدو كصفحات منتج
  return [...urls].filter((u) => /(product|produit|prod|p\/|shop|store|article)/i.test(u));
}

function extractJsonLd(html) {
  const blocks = [...html.matchAll(/<script[^>]*type=["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi)];
  for (const b of blocks) {
    let json;
    try {
      json = JSON.parse(b[1].trim());
    } catch {
      continue;
    }
    const arr = Array.isArray(json) ? json : json['@graph'] ? json['@graph'] : [json];
    for (const node of arr) {
      if (node && (node['@type'] === 'Product' || (Array.isArray(node['@type']) && node['@type'].includes('Product')))) {
        return node;
      }
    }
  }
  return null;
}

function meta(html, prop) {
  const re = new RegExp(`<meta[^>]+(?:property|name)=["']${prop}["'][^>]+content=["']([^"']+)["']`, 'i');
  const m = html.match(re);
  return m ? m[1] : '';
}

function parseProductPage(html, url) {
  const ld = extractJsonLd(html);
  let name = '', description = '', price = '', images = [];
  if (ld) {
    name = (ld.name || '').toString().trim();
    description = stripHtml((ld.description || '').toString());
    const offers = Array.isArray(ld.offers) ? ld.offers[0] : ld.offers;
    if (offers && offers.price != null) price = String(offers.price).replace(/[^\d.]/g, '');
    if (ld.image) images = (Array.isArray(ld.image) ? ld.image : [ld.image]).filter(Boolean);
  }
  // احتياط: Open Graph
  if (!name) name = meta(html, 'og:title');
  if (!description) description = meta(html, 'og:description');
  if (images.length === 0) {
    const og = meta(html, 'og:image');
    if (og) images = [og];
  }
  if (!price) {
    const pm = meta(html, 'product:price:amount') || meta(html, 'og:price:amount');
    if (pm) price = pm.replace(/[^\d.]/g, '');
  }
  if (!name) return null;
  return {
    sourceId: url,
    name: name.trim(),
    description,
    price,
    oldPrice: '',
    images,
    url,
    tags: [],
  };
}

async function fetchGeneric(store) {
  const base = clean(store.url);

  // 1) WooCommerce
  const woo = await tryWoo(base);
  if (woo) {
    console.log(`  ↳ WooCommerce: ${woo.length} منتج`);
    return woo;
  }

  // 2) sitemap + JSON-LD
  const urls = await collectSitemapUrls(base);
  console.log(`  ↳ عُثر على ${urls.length} رابط منتج محتمل عبر sitemap`);
  const out = [];
  for (const u of urls) {
    try {
      const html = await getText(u);
      const p = parseProductPage(html, u);
      if (p) out.push(p);
    } catch (e) {
      // تجاهل الصفحات الفاشلة
    }
    await new Promise((r) => setTimeout(r, 150)); // لطف مع الخادم
  }
  console.log(`  ↳ استُخرج ${out.length} منتج من الصفحات`);
  return out;
}

module.exports = { fetchGeneric };
