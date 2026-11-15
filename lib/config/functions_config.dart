/// ═══════════════════════════════════════════════════════════════════
///  إعدادات Cloud Functions
///
///  ⚠️ kFunctionsRegion يجب أن يطابق REGION في functions/index.js،
///     وكلاهما يجب أن يطابق منطقة قاعدة Firestore:
///       nam5 / us-*      → 'us-central1'
///       eur3 / europe-*  → 'europe-west1'
///     للتحقّق: firebase firestore:databases:get "(default)"
/// ═══════════════════════════════════════════════════════════════════
library;

const String kFunctionsRegion = 'us-central1';
const String kFirebaseProjectId = 'nabda-app-ca864';

/// قناة FCM للإشعارات الجماعية — يجب أن تطابق BROADCAST_TOPIC في functions/index.js
const String kBroadcastTopic = 'nabda_all';

/// رابط دالة قابلة للاستدعاء (callable) — بروتوكول HTTPS العادي،
/// فلا نحتاج حزمة cloud_functions (تخفيفاً للبناء على جهاز محدود الموارد).
Uri callableUrl(String name) => Uri.parse(
    'https://$kFunctionsRegion-$kFirebaseProjectId.cloudfunctions.net/$name');
