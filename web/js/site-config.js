// ═══════════════════════════════════════════════════════════════════
//  إعدادات موقع نبضة — nabda.online
//  امتثال كامل لسياسات Google Play ومتطلبات النشر
// ═══════════════════════════════════════════════════════════════════

// حجب الميزات الطبية التزاماً بسياسات Google Play
export const SITE_HIDE_MEDICAL = true;

// رابط متجر Google Play الرسمي الصحيح
export const PLAY_URL = "https://play.google.com/store/apps/details?id=com.nabda.womenhealth";

// المؤلّف دائماً فريق التحرير — ممنوع ذكر «فريق طبي» أو «د.»
export const EDITORIAL_AUTHOR = "فريق تحرير نبضة";

// اسم المنصة وهوية العلامة
export const SITE_NAME = "نبضة";
export const SITE_TAGLINE = "رفيقتكِ الموثوقة لصحة المرأة، رحلة الحمل، والأمومة";
export const OFFICIAL_FACEBOOK = "https://www.facebook.com/nabda.official";
// رقم واتساب المتجر يُضبط من لوحة التحكم ← الإعدادات (site_config/settings.whatsapp)
export const OFFICIAL_WHATSAPP = "";

// إعدادات Firebase الرسمية لمنصة الويب
export const firebaseConfig = {
  apiKey: "AIzaSyCXiztfIkw1oRPT0pYVuZJ1cTkadgVDZQ4",
  authDomain: "nabda-app-ca864.firebaseapp.com",
  projectId: "nabda-app-ca864",
  storageBucket: "nabda-app-ca864.firebasestorage.app",
  messagingSenderId: "911912460091",
  appId: "1:911912460091:web:a53336443c06b82d5b611e",
  measurementId: "G-G3W9D08JHT"
};

// ═══════════════ مساحات الإعلانات (Google AdSense) ═══════════════
// قبل الموافقة على AdSense: تظهر مساحات محجوزة بأبعادها (لا قفز في التصميم لاحقاً).
// بعد الموافقة: ضعي معرّف الناشر (ca-pub-…) ومعرّفات الوحدات هنا فقط، وأضيفي نطاقات Google
// للإعلانات إلى Content-Security-Policy في firebase.json (انظري التعليق في js/ads.js).
// الإعلانات على الموقع فقط — تطبيق Android مصرَّح عنه في Play بـ «لا إعلانات».
export const ADS = {
  client: '',              // مثال: 'ca-pub-1234567890123456'
  showPlaceholders: true,  // إظهار مساحة «إعلان» فارغة قبل التفعيل
  slots: {
    articleTop: '',        // داخل المقال بعد الفقرات الأولى
    articleMid: '',        // منتصف المقال
    articleEnd: '',        // قبل الأسئلة الشائعة
    sidebar: '',           // الشريط الجانبي (300×250)
    sidebarSticky: '',     // الشريط الجانبي اللاصق (300×600)
    listing: '',           // بين بطاقات الموسوعة
  },
};
