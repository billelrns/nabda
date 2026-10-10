/**
 * سكريبت رفع المقالات الـ 500 الذكية إلى Firebase Firestore
 * المشروع: nabda-app-ca864
 * المجموعة المستهدفة: articles
 */

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const saPath = path.join(__dirname, 'serviceAccount.json');
if (!fs.existsSync(saPath)) {
  console.error('❌ لم يتم العثور على serviceAccount.json في مجلد nabda-import!');
  process.exit(1);
}

const serviceAccount = require(saPath);
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const COLLECTION = 'articles';

// تحميل ملف المقالات الـ 500
const articlesPath = path.resolve(__dirname, '..', 'assets', 'data', 'smart_500_articles.json');
if (!fs.existsSync(articlesPath)) {
  console.error(`❌ لم يتم العثور على ملف المقالات: ${articlesPath}`);
  process.exit(1);
}

const articlesData = JSON.parse(fs.readFileSync(articlesPath, 'utf8'));
const articles = articlesData.articles || [];

console.log(`============================================================`);
console.log(`🚀 بدء رفع ${articles.length} مقال ذكي إلى Firestore...`);
console.log(`📁 المجموعة: ${COLLECTION}`);
console.log(`============================================================\n`);

(async () => {
  const TS = admin.firestore.FieldValue.serverTimestamp();
  const BATCH_SIZE = 400; // حد فايربيز 500
  let uploaded = 0;
  let batchIndex = 1;

  for (let i = 0; i < articles.length; i += BATCH_SIZE) {
    const chunk = articles.slice(i, i + BATCH_SIZE);
    const batch = db.batch();

    for (const art of chunk) {
      // استخدام ID مخصص وثابت لتجنب التكرار في حالة إعادة التشغيل
      const docRef = db.collection(COLLECTION).doc(art.id);
      
      // مطابقة صيغة Firestore الحالية مع الاحتفاظ بكامل التفاصيل الذكية
      const firestoreDoc = {
        id: art.id,
        originalId: art.originalId || '',
        rank: art.rank || 0,
        title: art.title,
        originalTitle: art.originalTitle || '',
        category: art.categoryName || 'صحة عامة',
        categoryId: art.categoryId || 'health',
        type: art.categoryId || 'smart', // cycle, baby, pregnancy, fertility, etc.
        content: art.summary || '',
        summary: art.summary || '',
        readTime: art.readTime || '4 دقائق',
        author: art.author || 'فريق التحرير الطبي — نبضة',
        badge: art.badge || 'موثق طبياً 🩺',
        iconEmoji: art.iconEmoji || '🌸',
        themeColorHex: art.themeColorHex || '#E91E63',
        sections: art.sections || [],
        faqs: art.faqs || [],
        toolType: art.toolType || '',
        toolTitle: art.toolTitle || '',
        toolSubtitle: art.toolSubtitle || '',
        sourceUrl: art.sourceUrl || '',
        originalViews: art.originalViews || 0,
        imageUrl: art.imagePath || '',
        contentImages: [],
        createdAt: TS,
        updatedAt: TS,
        source: 'nabda_smart_encyclopedia',
        active: true
      };

      batch.set(docRef, firestoreDoc, { merge: true });
    }

    await batch.commit();
    uploaded += chunk.length;
    console.log(`  ✅ الدفعة ${batchIndex}: تم رفع ${uploaded}/${articles.length} مقال`);
    batchIndex++;
  }

  console.log(`\n============================================================`);
  console.log(`🎉 تم بنجاح رفع ${uploaded} مقال إلى Firestore (${COLLECTION})!`);
  console.log(`============================================================`);
  process.exit(0);
})().catch(err => {
  console.error('❌ خطأ أثناء الرفع إلى Firestore:', err);
  process.exit(1);
});
