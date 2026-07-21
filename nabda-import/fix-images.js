/**
 * نبضة — نقل صور المنتجات المستوردة إلى Firebase Storage
 * ------------------------------------------------------
 * الصور المستوردة مستضافة على سيرفر المتجر الأصلي (cdn.shopify.com) —
 * تظهر في التطبيق لكن لا تظهر في متصفح الموقع (حماية hotlink).
 * هذا السكريبت ينزّل كل صورة ويرفعها إلى Firebase Storage الخاص بنبضة،
 * ثم يحدّث حقول الصور في Firestore بالروابط الجديدة — فتظهر في الموقع والتطبيق.
 *
 * التشغيل:
 *   node fix-images.js          (يعالج كل المنتجات المستوردة من El Baraa)
 *   node fix-images.js --all    (يعالج أي منتج صوره على cdn.shopify.com)
 */

const path = require('path');
const crypto = require('crypto');
const admin = require('firebase-admin');

const BUCKET = 'nabda-app-ca864.firebasestorage.app';
const saPath = path.join(__dirname, 'serviceAccount.json');
admin.initializeApp({ credential: admin.credential.cert(require(saPath)), storageBucket: BUCKET });
const db = admin.firestore();
const bucket = admin.storage().bucket();
const ALL = process.argv.includes('--all');

async function uploadImage(url, dest) {
  const res = await fetch(url, { headers: { 'User-Agent': 'Mozilla/5.0' } });
  if (!res.ok) throw new Error('HTTP ' + res.status);
  const buf = Buffer.from(await res.arrayBuffer());
  const token = crypto.randomUUID();
  const ext = (res.headers.get('content-type') || 'image/jpeg').includes('png') ? 'png' : 'jpg';
  const finalDest = dest + '.' + ext;
  await bucket.file(finalDest).save(buf, {
    metadata: {
      contentType: res.headers.get('content-type') || 'image/jpeg',
      metadata: { firebaseStorageDownloadTokens: token },
    },
  });
  return `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/${encodeURIComponent(finalDest)}?alt=media&token=${token}`;
}

(async () => {
  let query = db.collection('products');
  const snap = ALL ? await query.get() : await query.where('_sourceStore', '==', 'El Baraa').get();
  console.log(`🔍 ${snap.size} منتج للفحص\n`);

  let done = 0, skipped = 0;
  for (const doc of snap.docs) {
    const p = doc.data();
    let srcImgs = (p.imageUrls && p.imageUrls.length) ? p.imageUrls : (p.imageUrl ? [p.imageUrl] : []);
    srcImgs = srcImgs.filter(Boolean);
    // عالِج فقط الصور الخارجية (غير المرفوعة على Firebase)
    if (!srcImgs.length || !srcImgs.some(u => u.includes('cdn.shopify.com') || u.includes('youcan') || u.includes('lactalove') || u.includes('firasjeux'))) {
      skipped++; continue;
    }
    const newImgs = [];
    for (let i = 0; i < srcImgs.length; i++) {
      try { newImgs.push(await uploadImage(srcImgs[i], `products/imported/${doc.id}_${i}`)); }
      catch (e) { console.log(`   ⚠️ فشل صورة ${i} لـ ${p.name}: ${e.message}`); }
    }
    if (newImgs.length) {
      await doc.ref.update({ imageUrl: newImgs[0], coverImage: newImgs[0], imageUrls: newImgs });
      done++;
      console.log(`✓ ${done}  ${p.name}  (${newImgs.length} صورة)`);
    }
  }
  console.log(`\n✅ انتهى. تمّت معالجة ${done} منتج (تخطّي ${skipped}). الصور الآن على Firebase Storage وستظهر في الموقع.`);
  process.exit(0);
})().catch(e => { console.error('❌', e.message); process.exit(1); });
