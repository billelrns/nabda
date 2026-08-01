// ═══════════════════════════════════════════════════════════════════════
//  fix-images.js — ينقل صور المنتجات من روابط المتاجر الأصلية إلى
//                  Firebase Storage (تظهر بثبات في الموقع والتطبيق)
//  يعالج فقط المنتجات التي لا تزال صورها على نطاق خارجي.
//  التشغيل:  node fix-images.js
// ═══════════════════════════════════════════════════════════════════════
const fs = require('fs');
const admin = require('firebase-admin');
const cfg = require('./config');

if (!fs.existsSync(cfg.serviceAccountPath)) {
  console.error('✗ مفتاح الخدمة غير موجود: ' + cfg.serviceAccountPath);
  console.error('  حمّله من Firebase Console ← Project Settings ← Service Accounts ← Generate new private key');
  console.error('  وضعه داخل مجلد nabda-import باسم serviceAccountKey.json');
  process.exit(1);
}

const serviceAccount = require(require('path').resolve(cfg.serviceAccountPath));
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: cfg.projectId,
  storageBucket: cfg.storageBucket,
});
const db = admin.firestore();
const bucket = admin.storage().bucket();

function extFromUrl(u) {
  const m = u.split('?')[0].match(/\.(jpe?g|png|webp|gif|avif)$/i);
  return m ? m[1].toLowerCase() : 'jpg';
}
const isStorageUrl = (u) =>
  /firebasestorage\.googleapis\.com|\.firebasestorage\.app/.test(u || '');

async function upload(url, path) {
  const res = await fetch(url, { headers: { 'User-Agent': 'Mozilla/5.0' } });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  const buf = Buffer.from(await res.arrayBuffer());
  const token = require('crypto').randomUUID();
  const file = bucket.file(path);
  await file.save(buf, {
    metadata: {
      contentType: res.headers.get('content-type') || 'image/jpeg',
      metadata: { firebaseStorageDownloadTokens: token },
    },
  });
  return `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(
    path
  )}?alt=media&token=${token}`;
}

(async () => {
  const snap = await db.collection('products').get();
  console.log(`🔎 فحص ${snap.size} منتج...`);
  let touched = 0, imgs = 0, fails = 0;

  for (const d of snap.docs) {
    const data = d.data();
    const urls = Array.isArray(data.imageUrls) ? data.imageUrls : [];
    const external = urls.filter((u) => u && !isStorageUrl(u));
    if (external.length === 0) continue;

    const newUrls = [];
    for (let i = 0; i < urls.length; i++) {
      const u = urls[i];
      if (!u || isStorageUrl(u)) { newUrls.push(u); continue; }
      try {
        const path = `products/${d.id}/${i}.${extFromUrl(u)}`;
        newUrls.push(await upload(u, path));
        imgs++;
      } catch (e) {
        console.warn(`  ⚠ ${d.id} صورة ${i}: ${e.message}`);
        newUrls.push(u); // أبقِ الرابط الأصلي عند الفشل
        fails++;
      }
    }
    await d.ref.update({
      imageUrls: newUrls,
      imageUrl: newUrls[0] || '',
      coverImage: newUrls[0] || '',
    });
    touched++;
    if (touched % 10 === 0) console.log(`  ... ${touched} منتج`);
  }

  console.log(`\n✅ تم — منتجات معدّلة: ${touched} | صور مرفوعة: ${imgs} | فشل: ${fails}`);
  process.exit(0);
})().catch((e) => { console.error('✗ خطأ:', e); process.exit(1); });
