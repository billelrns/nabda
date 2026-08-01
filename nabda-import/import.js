// ═══════════════════════════════════════════════════════════════════════
//  import.js — يجلب كل المتاجر في config.stores، يحوّلها لصيغة نبضة،
//              ويكتبها في nabda-products.json (بدون لمس Firestore بعد)
//  التشغيل:  node import.js
// ═══════════════════════════════════════════════════════════════════════
const fs = require('fs');
const cfg = require('./config');
const { fetchShopify } = require('./lib/shopify');
const { fetchGeneric } = require('./lib/generic');
const { toNabda } = require('./lib/mapper');

(async () => {
  const all = [];
  const seen = new Set();

  for (const store of cfg.stores) {
    if (store.enabled === false) continue;
    if (/REPLACE/i.test(store.url)) {
      console.log(`⏭  تخطّي "${store.name}" — الرابط لم يُعدّل بعد في config.js`);
      continue;
    }
    console.log(`\n🏪 ${store.name}  [${store.type}]  ${store.url}`);
    let raw = [];
    try {
      raw = store.type === 'shopify' ? await fetchShopify(store) : await fetchGeneric(store);
    } catch (e) {
      console.warn(`  ✗ فشل الجلب: ${e.message}`);
      continue;
    }

    let added = 0;
    for (const p of raw) {
      if (!p.name || !p.name.trim()) continue;
      const doc = toNabda(p, store, cfg);
      const key = `${store.name}::${doc._source.sourceId || doc.name}`;
      if (seen.has(key)) continue;
      seen.add(key);
      all.push(doc);
      added++;
    }
    console.log(`  ✓ أُضيف ${added} منتج من ${store.name}`);
  }

  fs.writeFileSync(cfg.outputFile, JSON.stringify(all, null, 2), 'utf8');

  // ملخص
  const byCat = {};
  const noImg = all.filter((p) => !p.imageUrl).length;
  const noPrice = all.filter((p) => !p.price).length;
  for (const p of all) byCat[p.category] = (byCat[p.category] || 0) + 1;

  console.log('\n═══════════════ ملخص ═══════════════');
  console.log(`إجمالي المنتجات: ${all.length}`);
  console.log(`بدون صورة: ${noImg}  |  بدون سعر: ${noPrice}`);
  console.log('حسب الفئة:');
  Object.entries(byCat).sort((a, b) => b[1] - a[1]).forEach(([c, n]) => console.log(`  ${c}: ${n}`));
  console.log(`\n💾 حُفظ في ${cfg.outputFile}`);
  console.log('راجع الملف ثم شغّل:  node upload.js');
})();
