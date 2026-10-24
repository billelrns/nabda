/**
 * Script to migrate products in Firestore:
 * - Fills missing `slug` (cleaned Arabic name without diacritics + last 4 chars of id)
 * - Ensures `images` array is populated from `image` or `imageUrl`
 * - Sets default `active: true`, `stock`, `soldCount: 0`
 * Run: node tool/migrate_products.js
 */

const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

// Initialize with application default credentials or local emulator
try {
  initializeApp({
    projectId: 'nabda-app-ca864'
  });
} catch (e) {
  console.log('App already initialized or using default');
}

const db = getFirestore();

function generateSlug(name, id) {
  if (!name) return 'product-' + id.slice(-4);
  
  // Remove diacritics / tashkeel
  const clean = name
    .replace(/[\u064B-\u065F\u0670]/g, '')
    .trim()
    .toLowerCase()
    .replace(/[^\u0600-\u06FFa-zA-Z0-9\s-]/g, '')
    .replace(/\s+/g, '-')
    .slice(0, 50);

  const suffix = id.slice(-4);
  return `${clean}-${suffix}`;
}

async function migrateProducts() {
  console.log('Starting products migration...');
  const snap = await db.collection('products').get();
  console.log(`Found ${snap.size} products.`);

  let updated = 0;
  for (const doc of snap.docs) {
    const data = doc.data();
    const updates = {};

    // 1. Slug
    if (!data.slug || String(data.slug).trim() === '') {
      updates.slug = generateSlug(data.name || data.title, doc.id);
    }

    // 2. Images array
    if (!Array.isArray(data.images) || data.images.length === 0) {
      const img = data.image || data.imageUrl;
      if (img) {
        updates.images = [img];
      }
    }

    // 3. Defaults
    if (typeof data.active === 'undefined') {
      updates.active = true;
    }
    if (typeof data.soldCount === 'undefined') {
      updates.soldCount = 0;
    }
    if (typeof data.stock === 'undefined') {
      updates.stock = 15;
    }

    if (Object.keys(updates).length > 0) {
      await doc.ref.update(updates);
      updated++;
      console.log(`Updated product: ${doc.id} -> ${JSON.stringify(updates)}`);
    }
  }

  console.log(`Migration complete! Updated ${updated} products.`);
}

migrateProducts().catch(err => {
  console.error('Migration failed:', err.message);
});
