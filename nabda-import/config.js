// ═══════════════════════════════════════════════════════════════════════
//  إعدادات خط أنابيب الاستيراد — nabda-import
// ═══════════════════════════════════════════════════════════════════════
//
//  ملاحظة: المتاجر الثلاثة أدناه ليست Shopify:
//    • rasmin.store            → منصة YouCan
//    • lactalove.store         → صفحة هبوط WordPress (منتج واحد)
//    • houloul-herbalance-dz   → منصة PHP مخصّصة
//  لذلك جُلبت منتجاتها المنسّقة (المتعلقة بالأمومة فقط) مسبقاً وبُنيت في
//  nabda-products.json عبر:  node build-curated.js
//  يكفي الآن ضبط ownerUid ومفتاح الخدمة ثم:  node upload.js
//
//  قائمة stores أدناه يستخدمها import.js فقط (الجلب الحيّ التلقائي).
// ═══════════════════════════════════════════════════════════════════════

module.exports = {
  // مفتاح حساب الخدمة من Firebase Console → Project Settings → Service Accounts
  serviceAccountPath: './serviceAccountKey.json',

  projectId: 'nabda-app-ca864',
  storageBucket: 'nabda-app-ca864.firebasestorage.app',

  // ⚠️ عدّل هذا: UID مالك المتجر (نفس createdBy المستخدم سابقاً)
  ownerUid: 'zG9jnOX9U3eXs2r3t5ENO8v2HH52',

  // نموذج الوسيط: 0 = نفس السعر الأصلي. مثال 0.10 = +10%
  markup: 0,

  outputFile: './nabda-products.json',

  // للجلب الحيّ التلقائي عبر import.js (اختياري — المنتجات المنسّقة جاهزة أصلاً)
  stores: [
    { name: 'Rasmin',    type: 'generic', url: 'https://rasmin.store',                  defaultCategory: 'عناية بالحامل', enabled: false }, // YouCan
    { name: 'Lactalove', type: 'generic', url: 'https://lactalove.store',               defaultCategory: 'الرضاعة والتغذية', enabled: false }, // WordPress LP
    { name: 'Houloul',   type: 'generic', url: 'https://houloul-herbalance-dz.net',     defaultCategory: 'عناية بالحامل', enabled: false }, // PHP مخصّص
  ],
};
