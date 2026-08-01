// ═══════════════════════════════════════════════════════════════════════
//  upload.js — يرفع nabda-products.json إلى Firestore collection 'products'
//  يتجنّب التكرار عبر slug (يحدّث الموجود، يضيف الجديد)
//  التشغيل:  node upload.js
// ═══════════════════════════════════════════════════════════════════════
const fs = require('fs');
const admin = require('firebase-admin');
const cfg = require('./config');

if (!fs.existsSync(cfg.serviceAccountPath)) {
  console.error(`✗ مفتاح الخدمة غير موجود: ${cfg.serviceAccountPath}`);
  console.error('  حمّله من Firebase Console → Project Settings → Service Accounts → Generate new private key');
  process.exit(1);
}
if (/PUT_OWNER_UID/.test(cfg.ownerUid)) {
  console.error('✗ عدّل ownerUid في config.js إلى UID مالك المتجر.');
  process.exit(1);
}

const serviceAccount = require(require('path').resolve(cfg.serviceAccountPath));
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: cfg.projectId,
  storageBucket: cfg.storageBucket,
});
const db = admin.firestore();

(async () => {
  const products = JSON.parse(fs.readFileSync(cfg.outputFile, 'utf8'));
  console.log(`📦 ${products.length} منتج للرفع...`);

  // اجلب الـ slugs الموجودة لتفادي التكرار
  const existing = new Map();
  const snap = await db.collection('products').get();
  snap.forEach((d) => {
    const s = d.get('slug');
    if (s) existing.set(s, d.id);
  });
  console.log(`🔎 يوجد ${snap.size} منتج حالياً في Firestore.`);

  let created = 0, updated = 0, batch = db.batch(), ops = 0;
  const commit = async () => { if (ops) { await batch.commit(); batch = db.batch(); ops = 0; } };

  for (const p of products) {
    const doc = { ...p };
    doc.createdBy = cfg.ownerUid;
    doc.updatedAt = admin.firestore.FieldValue.serverTimestamp();

    const existingId = existing.get(p.slug);
    if (existingId) {
      batch.set(db.collection('products').doc(existingId), doc, { merge: true });
      updated++;
    } else {
      doc.createdAt = admin.firestore.FieldValue.serverTimestamp();
      batch.set(db.collection('products').doc(), doc);
      created++;
    }
    if (++ops >= 400) await commit();
  }
  await commit();

  console.log(`\n✅ تم — جديد: ${created} | محدَّث: ${updated}`);
  console.log('التالي (اختياري): node fix-images.js لنقل الصور إلى Firebase Storage.');
  process.exit(0);
})().catch((e) => { console.error('✗ خطأ الرفع:', e); process.exit(1); });
