/**
 * سكريبت رفع المقالات إلى Firebase Firestore عبر Firestore REST API
 * المشروع: nabda-app-ca864
 * المجموعة المستهدفة: articles
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

function getAccessToken() {
  const tokenPath = 'C:\\Users\\AMT mobile\\.config\\configstore\\firebase-tools.json';
  if (!fs.existsSync(tokenPath)) {
    throw new Error('لم يتم العثور على ملف توكن Firebase CLI!');
  }
  let tokenData = JSON.parse(fs.readFileSync(tokenPath, 'utf8')).tokens;
  
  // إذا شارف على الانتهاء (أقل من 5 دقائق)، قم بتحديثه عبر تشغيل أمر سريع
  if (tokenData.expires_at - Date.now() < 5 * 60 * 1000) {
    console.log('🔄 تحديث التوكن عبر Firebase CLI...');
    try {
      execSync('firebase projects:list', { stdio: 'ignore' });
      tokenData = JSON.parse(fs.readFileSync(tokenPath, 'utf8')).tokens;
    } catch (e) {}
  }
  return tokenData.access_token;
}

// دالة تحويل كائنات JavaScript إلى تنسيق Firestore REST API
function toFirestoreValue(val) {
  if (val === null || val === undefined) {
    return { nullValue: null };
  }
  if (typeof val === 'string') {
    return { stringValue: val };
  }
  if (typeof val === 'boolean') {
    return { booleanValue: val };
  }
  if (typeof val === 'number') {
    if (Number.isInteger(val)) {
      return { integerValue: String(val) };
    }
    return { doubleValue: val };
  }
  if (Array.isArray(val)) {
    return {
      arrayValue: {
        values: val.map(toFirestoreValue)
      }
    };
  }
  if (typeof val === 'object') {
    const fields = {};
    for (const [k, v] of Object.entries(val)) {
      if (v !== undefined) {
        fields[k] = toFirestoreValue(v);
      }
    }
    return { mapValue: { fields } };
  }
  return { stringValue: String(val) };
}

function toFirestoreFields(obj) {
  const fields = {};
  for (const [k, v] of Object.entries(obj)) {
    if (v !== undefined) {
      fields[k] = toFirestoreValue(v);
    }
  }
  return fields;
}

async function uploadArticles(jsonFilePath, collectionName = 'articles') {
  console.log(`============================================================`);
  console.log(`🚀 بدء رفع المقالات إلى Firestore (${collectionName})...`);
  console.log(`📄 المصدر: ${jsonFilePath}`);
  console.log(`============================================================\n`);

  if (!fs.existsSync(jsonFilePath)) {
    throw new Error(`الملف غير موجود: ${jsonFilePath}`);
  }

  const raw = JSON.parse(fs.readFileSync(jsonFilePath, 'utf8'));
  const articles = raw.articles || [];
  console.log(`📊 إجمالي المقالات المطلوب رفعها: ${articles.length} مقال\n`);

  let token = getAccessToken();
  const nowIso = new Date().toISOString();
  let successCount = 0;
  let failCount = 0;

  // معالجة المقالات على دفعات متوازية
  const CONCURRENCY = 20;
  for (let i = 0; i < articles.length; i += CONCURRENCY) {
    const chunk = articles.slice(i, i + CONCURRENCY);
    
    // فحص التوكن كل 100 مقال
    if (i % 100 === 0) {
      token = getAccessToken();
    }

    const promises = chunk.map(async (art) => {
      const docId = art.id;
      const url = `https://firestore.googleapis.com/v1/projects/nabda-app-ca864/databases/(default)/documents/${collectionName}/${docId}`;

      const docData = {
        id: art.id,
        originalId: art.originalId || '',
        rank: art.rank || 0,
        title: art.title,
        originalTitle: art.originalTitle || '',
        category: art.categoryName || 'صحة عامة',
        categoryId: art.categoryId || 'health',
        type: art.categoryId || 'smart',
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
        originalViews: Number(art.originalViews || 0),
        imageUrl: art.imagePath || '',
        createdAt: nowIso,
        updatedAt: nowIso,
        source: 'nabda_smart_encyclopedia',
        active: true
      };

      const firestoreDoc = {
        fields: toFirestoreFields(docData)
      };

      try {
        const res = await fetch(url, {
          method: 'PATCH',
          headers: {
            'Authorization': 'Bearer ' + token,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(firestoreDoc)
        });

        if (res.ok) {
          successCount++;
        } else {
          const err = await res.json();
          console.error(`  ⚠️ فشل رفع ${docId}:`, err?.error?.message || err);
          failCount++;
        }
      } catch (e) {
        console.error(`  ⚠️ استثناء أثناء رفع ${docId}:`, e.message);
        failCount++;
      }
    });

    await Promise.all(promises);
    const processed = Math.min(i + CONCURRENCY, articles.length);
    console.log(`  ✅ تقدم الرفع: ${processed}/${articles.length} (نجاح: ${successCount} | فشل: ${failCount})`);
  }

  console.log(`\n============================================================`);
  console.log(`🎉 تم الانتهاء من الرفع: ${successCount} مقال نجح | ${failCount} فشل`);
  console.log(`============================================================\n`);
  return { successCount, failCount };
}

// تنفيذ الرفع
const targetJson = process.argv[2] || path.resolve(__dirname, '..', 'assets', 'data', 'smart_500_articles.json');
uploadArticles(targetJson)
  .then(() => process.exit(0))
  .catch(err => {
    console.error('❌ خطأ فادح:', err);
    process.exit(1);
  });
