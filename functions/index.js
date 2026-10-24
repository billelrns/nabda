/**
 * ═══════════════════════════════════════════════════════════════════
 *  Cloud Functions — نبضة
 *
 *  ١) askAssistant          وكيل المساعد الذكي: مفتاح Gemini يبقى سرّاً
 *                           على الخادم، مع الفلتر الطبّي والحصّة اليومية.
 *  ٢) pushPartnerNotification  إشعار فوري (FCM) للطرف الآخر من الزوجين
 *                           عند كل حدث في couples/{id}/notifications.
 *  ٣) syncPartnerMirror     تحديث مرآة الزوجة تلقائياً عند أي تعديل على
 *                           وثيقتها — فلا ينتظر الأب أن تفتح تطبيقها.
 *
 *  ⚠️ المنطقة REGION يجب أن تطابق منطقة قاعدة Firestore
 *     (تحقّق بـ: firebase firestore:databases:get "(default)").
 *     nam5 / us-*  → us-central1      eur3 / europe-* → europe-west1
 *     وغيّر kFunctionsRegion في lib/config/functions_config.dart بالقيمة نفسها.
 * ═══════════════════════════════════════════════════════════════════
 */
const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentCreated, onDocumentWritten } = require('firebase-functions/v2/firestore');
const { setGlobalOptions } = require('firebase-functions/v2');
const { defineSecret } = require('firebase-functions/params');
const logger = require('firebase-functions/logger');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();
const db = getFirestore();

const REGION = 'us-central1';

// maxInstances يحدّ من الكلفة القصوى مهما حدث (هجوم، حلقة، خطأ)
setGlobalOptions({ region: REGION, maxInstances: 10 });

// يُضبط مرّة واحدة: firebase functions:secrets:set GEMINI_API_KEY
const GEMINI_API_KEY = defineSecret('GEMINI_API_KEY');

// ══════════════════════════════════════════════════════════════════
//  ١) المساعد الذكي
// ══════════════════════════════════════════════════════════════════

const DAILY_LIMIT = 50;
const GEMINI_MODEL = 'gemini-flash-latest';

/**
 * نفس نصّ kAssistantSystemPrompt في lib/config/play_compliance.dart.
 * ⚠️ صار الخادم هو المرجع الوحيد: العميل لم يعد يستطيع تغيير التعليمات،
 *    وهذا يقوّي الامتثال لسياسة Google Play (لا إجابات طبّية).
 */
const SYSTEM_PROMPT =
  'أنتِ «مساعدة نبضة»، مساعدة لطيفة لأمور الحياة اليومية للمرأة والأم، وتجيبين دائمًا بالعربية وبإيجاز. ' +
  'نطاقكِ فقط: اقتراح أسماء المواليد ومعانيها، تحضير حقيبة الولادة ومستلزمات الطفل، تنظيم اليوم والروتين، ' +
  'أفكار وصفات ووجبات عادية، ديكور غرفة الطفل، رسائل التهنئة، أفكار الهدايا والاحتفالات، وشرح طريقة استعمال تطبيق نبضة. ' +
  'ممنوع منعًا باتًا: تفسير أي عرض أو ألم أو نزيف، اقتراح أي دواء أو مكمّل أو جرعة، تفسير التحاليل أو السونار، ' +
  'تقييم خطورة حالة صحية، أو أي نصيحة طبية أو علاجية للأم أو الجنين أو الطفل. ' +
  'إذا كان السؤال صحيًا أو طبيًا بأي شكل، فلا تجيبي عن مضمونه، وقولي فقط بلطف إنكِ لا تجيبين عن الأسئلة الصحية ' +
  'وإن الطبيبة هي الجهة المناسبة، ثم اقترحي ما يمكنكِ المساعدة فيه.';

const MEDICAL_REDIRECT =
  'هذا سؤال صحي، ولا أجيب عن الأسئلة الصحية أو الطبية 🌸\n\n' +
  'للأعراض أو الأدوية أو أي قلق على صحتكِ أو صحة طفلكِ، راجعي طبيبتكِ مباشرة. ' +
  'وفي الحالات الطارئة اتصلي بالإسعاف فورًا.\n\n' +
  'يمكنني مساعدتكِ في: أسماء المواليد، حقيبة الولادة، تنظيم يومكِ، أفكار الوجبات والديكور والتهاني.';

/** نسخة من _medicalWords في play_compliance.dart — صارمة عمداً */
const MEDICAL_WORDS = [
  'أعراض', 'اعراض', ' عرض ', 'ألم', ' الم ', 'آلام', ' الام', 'وجع', 'يؤلم', 'نزيف', 'نزف', ' دم', 'الدم', 'حرار', 'حمى', 'حمّى', 'سخون', 'مريض', 'يوجع', 'توجع', 'ينزف', 'تنزف',
  'دواء', 'أدوية', 'ادوية', 'علاج', 'جرعة', 'حبوب', 'مضاد', 'مسكن', 'باراسيتامول', 'فيتامين', 'مكمل', 'مكمّل', 'حديد', 'فوليك',
  'مرض', 'التهاب', 'عدوى', 'فيروس', 'تشخيص', 'طبيب', 'طبيبة', 'دكتور', 'مستشفى', 'إسعاف', 'طوارئ',
  'إجهاض', 'اجهاض', 'تحليل', 'تحاليل', 'سونار', 'أشعة', 'ضغط', 'سكر', 'سكري', 'غدة', 'تكيس', 'هرمون',
  'إفرازات', 'افرازات', 'تقيؤ', 'استفراغ', 'غثيان', 'إسهال', 'اسهال', 'إمساك', 'امساك', 'طفح', 'حكة', 'حساسية',
  'انقباض', 'تقلصات', 'مخاض', 'طلق', 'حركة الجنين', 'نبض الجنين', 'تأخر الدورة', 'تأخر الحمل', 'عقم', 'خصوبة',
  'لقاح', 'تطعيم', 'اكتئاب', 'قلق', 'نوبة', 'دوخة', 'دوار', 'إغماء', 'تنفس', 'سعال', 'كحة', 'رشح', 'زكام',
  'symptom', 'pain', 'bleed', 'medicine', 'drug', 'dose', 'fever', 'doctor', 'pregnan', 'disease',
];

function isMedicalQuestion(text) {
  const t = ` ${String(text).toLowerCase()} `;
  return MEDICAL_WORDS.some((w) => t.includes(w));
}

/** الحصّة اليومية — على الخادم الآن، فلا يمكن تجاوزها من الهاتف */
async function consumeQuota(uid) {
  const ref = db.collection('ai_quota').doc(uid);
  const today = new Date().toISOString().slice(0, 10);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    let count = 0;
    if (snap.exists && snap.get('date') === today) {
      count = Number(snap.get('count')) || 0;
    }
    if (count >= DAILY_LIMIT) return false;
    tx.set(ref, {
      date: today,
      count: count + 1,
      updatedAt: FieldValue.serverTimestamp(),
    });
    return true;
  });
}

/** ينقّي سجلّ المحادثة القادم من العميل: أدوار وأطوال محدودة فقط */
function sanitizeHistory(history) {
  if (!Array.isArray(history)) return [];
  return history
    .slice(-20)
    .filter((m) => m && (m.role === 'user' || m.role === 'model'))
    .map((m) => {
      const text = Array.isArray(m.parts) && m.parts[0] && typeof m.parts[0].text === 'string'
        ? m.parts[0].text
        : '';
      return { role: m.role, parts: [{ text: text.slice(0, 4000) }] };
    })
    .filter((m) => m.parts[0].text.length > 0);
}

exports.askAssistant = onCall(
  { secrets: [GEMINI_API_KEY], timeoutSeconds: 30, memory: '256MiB' },
  async (req) => {
    if (!req.auth) {
      throw new HttpsError('unauthenticated', 'يجب تسجيل الدخول');
    }
    const message = String((req.data && req.data.message) || '').trim();
    if (!message) throw new HttpsError('invalid-argument', 'الرسالة فارغة');
    if (message.length > 2000) throw new HttpsError('invalid-argument', 'الرسالة طويلة جداً');

    // الفلتر الطبّي على الخادم — لا يُرسل السؤال الطبّي إلى النموذج أبداً
    if (isMedicalQuestion(message)) {
      return { reply: MEDICAL_REDIRECT, medical: true };
    }

    const allowed = await consumeQuota(req.auth.uid);
    if (!allowed) {
      return { reply: null, quotaExceeded: true, limit: DAILY_LIMIT };
    }

    const contents = sanitizeHistory(req.data && req.data.history)
      .concat([{ role: 'user', parts: [{ text: message }] }]);

    let res;
    try {
      res = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            // المفتاح في الترويسة لا في الرابط — فلا يظهر في السجلّات
            'x-goog-api-key': GEMINI_API_KEY.value(),
          },
          body: JSON.stringify({
            systemInstruction: { parts: [{ text: SYSTEM_PROMPT }] },
            contents,
          }),
        },
      );
    } catch (e) {
      logger.error('Gemini network error', e);
      throw new HttpsError('unavailable', 'المساعد غير متاح مؤقتاً');
    }

    if (!res.ok) {
      const body = await res.text();
      logger.error(`Gemini HTTP ${res.status}`, body.slice(0, 300));
      throw new HttpsError('unavailable', 'المساعد غير متاح مؤقتاً');
    }

    const data = await res.json();
    const reply = data && data.candidates && data.candidates[0] &&
      data.candidates[0].content && data.candidates[0].content.parts &&
      data.candidates[0].content.parts[0] && data.candidates[0].content.parts[0].text;

    if (!reply) {
      logger.warn('Gemini empty reply', JSON.stringify(data).slice(0, 300));
      throw new HttpsError('unavailable', 'لم أتمكّن من الإجابة');
    }
    return { reply };
  },
);

// ══════════════════════════════════════════════════════════════════
//  صور الإشعارات
//  FCM لا يقبل إلا رابط https عامّاً، ويُستحسن أقلّ من 1MB.
//  الصورة تظهر تلقائياً على أندرويد حين يكون التطبيق مغلقاً.
// ══════════════════════════════════════════════════════════════════

function httpsOrNull(u) {
  const s = String(u || '').trim();
  return s.startsWith('https://') && s.length < 2000 ? s : null;
}

/** أوّل صورة صالحة للمنتج — نفس ترتيب صفحة المنتج في التطبيق */
function productImage(p) {
  if (!p) return null;
  const cover = httpsOrNull(p.coverImage);
  if (cover) return cover;
  if (Array.isArray(p.imageUrls)) {
    for (const u of p.imageUrls) {
      const ok = httpsOrNull(u);
      if (ok) return ok;
    }
  }
  return httpsOrNull(p.imageUrl);
}

async function imageForProduct(productId) {
  if (!productId || typeof productId !== 'string' || productId.includes('/')) return null;
  try {
    const snap = await db.doc(`products/${productId}`).get();
    return snap.exists ? productImage(snap.data()) : null;
  } catch (_) {
    return null;
  }
}

// ══════════════════════════════════════════════════════════════════
//  ٢) إشعار فوري للطرف الآخر
// ══════════════════════════════════════════════════════════════════

exports.pushPartnerNotification = onDocumentCreated(
  'couples/{coupleId}/notifications/{notifId}',
  async (event) => {
    const n = event.data && event.data.data();
    if (!n) return;

    const coupleSnap = await db.doc(`couples/${event.params.coupleId}`).get();
    if (!coupleSnap.exists) return;
    const c = coupleSnap.data();
    if (c.status !== 'linked') return;

    // 🔒 الكاتب يجب أن يكون أحد الزوجين (القواعد تفرض ذلك، وهذا تحقّق ثانٍ)
    if (n.byUid !== c.motherUid && n.byUid !== c.partnerUid) return;

    const recipient = n.byUid === c.motherUid ? c.partnerUid : c.motherUid;
    if (!recipient) return;

    const userRef = db.doc(`users/${recipient}`);
    const token = (await userRef.get()).get('fcmToken');
    if (!token) {
      logger.info(`no fcmToken for ${recipient} — notification stays in-app only`);
      return;
    }

    // صورة صريحة أولاً، وإلا صورة المنتج المرتبط
    const image = httpsOrNull(n.imageUrl) || (await imageForProduct(n.productId));

    try {
      await getMessaging().send({
        token,
        notification: {
          title: String(n.title || 'نبضة').slice(0, 100),
          body: String(n.body || '').slice(0, 240),
          ...(image ? { imageUrl: image } : {}),
        },
        data: {
          type: String(n.type || ''),
          coupleId: event.params.coupleId,
          ...(n.productId ? { productId: String(n.productId) } : {}),
          ...(image ? { image } : {}),
        },
        android: {
          priority: 'high',
          // تُنشأ في AppNotifs._ensureChannels («تنبيهات الزوجين»)
          notification: { channelId: 'partner_channel' },
        },
      });
    } catch (e) {
      // رمز منتهٍ: نحذفه حتى لا نحاول عليه مرّة أخرى
      if (
        e.code === 'messaging/registration-token-not-registered' ||
        e.code === 'messaging/invalid-registration-token'
      ) {
        await userRef.update({ fcmToken: FieldValue.delete() });
      } else {
        logger.error('FCM send failed', e);
      }
    }
  },
);

// ══════════════════════════════════════════════════════════════════
//  ٣) تحديث مرآة الزوجة تلقائياً
// ══════════════════════════════════════════════════════════════════

/**
 * ⛔ قائمة بيضاء — مطابقة لـ _mirroredFields في partner_service.dart.
 *    لا تُضف أيّ حقل دورة شهرية (cycleLength، lastPeriodStart، الأعراض، المزاج).
 */
const MIRRORED = [
  'pregnancyStartDate', 'dueDate', 'dueDateSource', 'postTermAck',
  'babyName', 'babyBirthDate', 'babyGender',
  'displayName', 'name', 'photoUrl',
];

function same(a, b) {
  if (a === b) return true;
  if (a && b && typeof a.isEqual === 'function') return a.isEqual(b);
  return JSON.stringify(a) === JSON.stringify(b);
}

function toDate(v) {
  if (!v) return null;
  if (v instanceof Timestamp) return v.toDate();
  if (typeof v.toDate === 'function') return v.toDate();
  const d = new Date(v);
  return isNaN(d.getTime()) ? null : d;
}

exports.syncPartnerMirror = onDocumentWritten('users/{uid}', async (event) => {
  const after = event.data && event.data.after && event.data.after.data();
  if (!after) return; // حُذفت الوثيقة
  const before = (event.data.before && event.data.before.data()) || {};

  const coupleId = after.coupleId;
  if (!coupleId || after.role === 'partner') return;

  // لا نكتب إلا إن تغيّر حقل مُرآة فعلاً (تحديث رمز FCM مثلاً لا يعنينا)
  const changed =
    before.coupleId !== coupleId || MIRRORED.some((f) => !same(before[f], after[f]));
  if (!changed) return;

  const coupleRef = db.doc(`couples/${coupleId}`);
  const couple = await coupleRef.get();

  // 🔒 حاسم: الدالة تعمل بصلاحيات المدير وتتجاوز القواعد. فلولا هذا الشرط
  //    لاستطاعت أيّ مستخدمة أن تضع coupleId لزوجين آخرين في وثيقتها
  //    فتكتب الدالة بياناتها في مرآتهما.
  if (!couple.exists || couple.get('motherUid') !== event.params.uid) return;

  const safe = {};
  for (const f of MIRRORED) {
    safe[f] = after[f] === undefined ? FieldValue.delete() : after[f];
  }
  safe.mirroredAt = FieldValue.serverTimestamp();
  safe.mirroredBy = 'function';
  await coupleRef.collection('shared').doc('userdoc').set(safe, { merge: true });

  // لقطة الحمل (تاريخ الولادة فقط — الأسبوع يُشتقّ منه عند العرض)
  const lmp = toDate(after.pregnancyStartDate);
  const due = toDate(after.dueDate) ||
    (lmp ? new Date(lmp.getTime() + 280 * 24 * 3600 * 1000) : null);
  if (due) {
    await coupleRef.collection('shared').doc('pregnancy').set({
      dueDate: Timestamp.fromDate(due),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  }
});

// ══════════════════════════════════════════════════════════════════
//  ٤) الإشعارات الجماعية من لوحة الأدمن
//
//  ⚠️ قبل هذه الدالة لم تكن الإشعارات الجماعية تعمل إطلاقاً: كانت
//     اللوحة تكتب في notifications بلا قاعدة Firestore (فتُرفض الكتابة)،
//     ولا يوجد ما يرسلها، ولا يشترك أيّ هاتف في topic.
//     الآن: الأدمن يكتب ← هذه الدالة ترسل إلى topic «nabda_all»
//     الذي يشترك فيه كل تطبيق عند الإقلاع (NotificationService).
// ══════════════════════════════════════════════════════════════════

const BROADCAST_TOPIC = 'nabda_all';

async function imageForArticle(articleId) {
  if (!articleId || typeof articleId !== 'string' || articleId.includes('/')) return null;
  try {
    const snap = await db.doc(`articles/${articleId}`).get();
    return snap.exists ? httpsOrNull(snap.get('imageUrl')) : null;
  } catch (_) {
    return null;
  }
}

exports.sendBroadcast = onDocumentCreated('notifications/{id}', async (event) => {
  const snap = event.data;
  if (!snap) return;
  const n = snap.data();
  if (n.type !== 'broadcast') return;
  if (n.status) return; // عولج من قبل

  // 🔒 إشعار لكل المستخدمين قرار عالي الأثر: نتحقّق ثانيةً أنّ المُرسِل
  //    موظّف نشط، حتى لو تساهلت القواعد يوماً ما.
  const staff = n.sentBy ? await db.doc(`staff/${n.sentBy}`).get() : null;
  if (!staff || !staff.exists || staff.get('isActive') !== true) {
    await snap.ref.update({ status: 'rejected', error: 'المُرسِل ليس موظّفاً نشطاً' });
    return;
  }

  const title = String(n.title || '').trim().slice(0, 100);
  const body = String(n.body || '').trim().slice(0, 240);
  if (!title || !body) {
    await snap.ref.update({ status: 'failed', error: 'العنوان أو النصّ فارغ' });
    return;
  }

  // الصورة: صريحة، وإلا صورة المنتج أو المقال المُرفق
  const link = n.link && typeof n.link === 'object' ? n.link : null;
  let image = httpsOrNull(n.imageUrl);
  if (!image && link && link.type === 'product') image = await imageForProduct(link.id);
  if (!image && link && link.type === 'article') image = await imageForArticle(link.id);

  try {
    const messageId = await getMessaging().send({
      topic: BROADCAST_TOPIC,
      notification: { title, body, ...(image ? { imageUrl: image } : {}) },
      data: {
        type: 'broadcast',
        ...(link && link.type ? { linkType: String(link.type), linkId: String(link.id || '') } : {}),
        ...(image ? { image } : {}),
      },
      android: {
        priority: 'high',
        // قناة «عروض ومنتجات نبضة» الموجودة على كل الأجهزة
        notification: { channelId: 'products_channel' },
      },
    });
    await snap.ref.update({
      status: 'sent',
      sentAt: FieldValue.serverTimestamp(),
      messageId,
      resolvedImage: image || null,
    });
  } catch (e) {
    logger.error('broadcast failed', e);
    await snap.ref.update({ status: 'failed', error: String(e.message || e).slice(0, 300) });
  }
});

// ══════════════════════════════════════════════════════════════════
//  ٥) معاينة روابط المنتجات (Open Graph للمتجر)
// ══════════════════════════════════════════════════════════════════
const HIDDEN_CATS = new Set(['فيتامينات ومكملات','مكملات غذائية','مكملات طبيعية','أطعمة ومكملات','أجهزة طبية']);
const SUPP_WORDS = ['مكمل','مكمّل','فيتامينات','حمض الفوليك','أوميغا','حديد +','كالسيوم +'];
function isHiddenProduct(p){
  if (!p) return false;
  if (HIDDEN_CATS.has(String(p.category||'').trim())) return true;
  const n = String(p.name||p.title||'');
  return SUPP_WORDS.some(w => n.includes(w));
}

exports.productPage = onRequest({ region: REGION }, async (req, res) => {
  const parts = req.path.split('/');
  const slug = decodeURIComponent(parts[parts.length - 1] || '');

  try {
    let snap = await db.collection('products').where('slug', '==', slug).limit(1).get();
    if (snap.empty) {
      const doc = await db.collection('products').doc(slug).get();
      if (doc.exists) snap = { empty: false, docs: [doc] };
    }

    const p = !snap.empty ? snap.docs[0].data() : null;
    if (!p || isHiddenProduct(p) || p.active === false) {
      res.redirect(301, '/shop');
      return;
    }

    const name = String(p.name || 'منتج من متجر نبضة').replace(/"/g, '&quot;');
    const desc = String(p.description || p.desc || 'تسوقي بأمان من متجر نبضة للأم والطفل. الدفع عند الاستلام والتوصيل لـ 58 ولاية.').slice(0, 200).replace(/"/g, '&quot;');
    const img = p.image || p.imageUrl || (p.images && p.images[0]) || 'https://nabda.online/landing-assets/slide-store.png';
    const price = Number(p.price || 0).toLocaleString();

    const html = `<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <title>${name} — متجر نبضة</title>
  <meta name="description" content="${desc}">
  <meta property="og:title" content="${name} | ${price} دج">
  <meta property="og:description" content="${desc}">
  <meta property="og:image" content="${img}">
  <meta property="og:type" content="product">
  <meta property="og:url" content="https://nabda.online/product/${encodeURIComponent(slug)}">
  <meta property="product:price:amount" content="${p.price}">
  <meta property="product:price:currency" content="DZD">
  <meta http-equiv="refresh" content="0; url=/product/${encodeURIComponent(slug)}">
  <script>location.replace('/product/${encodeURIComponent(slug)}');</script>
</head>
<body>
  <p>يتم تحويلكِ إلى <a href="/product/${encodeURIComponent(slug)}">${name}</a>...</p>
</body>
</html>`;

    res.set('Cache-Control', 'public, max-age=300, s-maxage=600');
    res.send(html);
  } catch (err) {
    logger.error('productPage error', err);
    res.redirect(302, '/shop');
  }
});

// ══════════════════════════════════════════════════════════════════
//  ٦) إنقاص المخزون وتحديث المبيعات تلقائياً عند إنشاء طلب
// ══════════════════════════════════════════════════════════════════
exports.onOrderCreated = onDocumentCreated('orders/{orderId}', async (event) => {
  const snap = event.data;
  if (!snap) return;
  const order = snap.data();
  const productId = order.productId;
  const qty = parseInt(order.quantity, 10) || 1;

  if (!productId) return;

  try {
    const prodRef = db.collection('products').doc(productId);
    await db.runTransaction(async (t) => {
      const doc = await t.get(prodRef);
      if (!doc.exists) return;
      const currentStock = doc.data().stock || 0;
      const newStock = Math.max(0, currentStock - qty);
      const newSold = (doc.data().soldCount || 0) + qty;
      t.update(prodRef, {
        stock: newStock,
        soldCount: newSold,
        updatedAt: FieldValue.serverTimestamp()
      });
    });
    logger.info(`Stock updated for product ${productId}: -${qty}`);
  } catch (err) {
    logger.error('Error updating stock on order created:', err);
  }
});

