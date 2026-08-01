// جالب Shopify — يعتمد على نقطة /products.json العامة (مدعومة في كل متاجر Shopify)
const { getJson } = require('./http');

function clean(u) {
  return u.replace(/\/+$/, '');
}

// يعيد قائمة منتجات موحّدة: {sourceId, name, description, price, oldPrice, images, url}
async function fetchShopify(store) {
  const base = clean(store.url);
  const out = [];
  for (let page = 1; page <= 50; page++) {
    let data;
    try {
      data = await getJson(`${base}/products.json?limit=250&page=${page}`);
    } catch (e) {
      console.warn(`  ⚠ Shopify page ${page} فشل: ${e.message}`);
      break;
    }
    const products = (data && data.products) || [];
    if (products.length === 0) break;

    for (const p of products) {
      const variants = p.variants || [];
      const v0 = variants[0] || {};
      const price = v0.price != null ? String(v0.price) : '';
      // compare_at_price = السعر القديم (المشطوب)
      const oldPrice =
        v0.compare_at_price && Number(v0.compare_at_price) > Number(v0.price || 0)
          ? String(v0.compare_at_price)
          : '';
      const images = (p.images || []).map((im) => im.src).filter(Boolean);

      out.push({
        sourceId: String(p.id),
        name: (p.title || '').trim(),
        description: stripHtml(p.body_html || ''),
        price,
        oldPrice,
        images,
        productType: p.product_type || '',
        tags: p.tags || [],
        url: `${base}/products/${p.handle}`,
        handle: p.handle,
      });
    }
    console.log(`  ↳ صفحة ${page}: ${products.length} منتج`);
    if (products.length < 250) break;
  }
  return out;
}

function stripHtml(html) {
  return html
    .replace(/<\s*br\s*\/?>/gi, '\n')
    .replace(/<\/(p|div|li|h[1-6])>/gi, '\n')
    .replace(/<[^>]+>/g, '')
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
}

module.exports = { fetchShopify, stripHtml };
