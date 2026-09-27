/// إعدادات الامتثال لسياسة Google Play.
///
/// الحساب الحالي على Google Play **شخصي**، والسياسة تمنع الحسابات الشخصية
/// من نشر «تطبيقات طبية» (Play Console Requirements §1.2). لذلك تُخفى هنا
/// الميزات والمحتوى الطبي عن الواجهة دون حذف الكود، ليُعاد تفعيلها بتغيير
/// سطر واحد عند الانتقال إلى حساب منظّمة (Organization).
///
/// رُفض الإصدار 1.0.0+2 بسبب ذلك في 27 سبتمبر 2026.
library;

/// `true` = نسخة الحساب الشخصي (بلا ميزات طبية).
/// `false` = نسخة كاملة (تتطلّب حساب منظّمة على Google Play).
const bool kHideMedicalFeatures = true;

/// تصنيفات الموسوعة الفرعية ذات الطابع الطبي (أمراض، فحوصات، علاج، تطعيمات).
const Set<String> kMedicalSubcategories = {
  'health_diseases_prevention', // الأمراض النسائية وصحة الثدي
  'preg_health_tests',          // الفحوصات والسونار وعلاج المتاعب
  'fert_pcos_hormones',         // تكيس المبايض واضطرابات الهرمونات
  'fert_ivf_medical',           // الحقن المجهري والتلقيح
  'baby_health_care',           // صحة الرضيع والتطعيمات
};

/// هل يُخفى هذا التصنيف الفرعي في النسخة الحالية؟
bool isHiddenSubcategory(String? subcategoryId) =>
    kHideMedicalFeatures &&
    subcategoryId != null &&
    kMedicalSubcategories.contains(subcategoryId);

/// مقالات ثابتة داخل التبويبات (خارج الموسوعة) موضوعها مرض وعلاجه.
const Set<String> kMedicalArticleTitles = {
  'متلازمة تكيس المبايض',
  'الدورة غير المنتظمة: الأسباب والعلاج',
  'الحمى عند الرضع: متى تقلقين',
  'الأمراض الشائعة عند الأطفال وعلاجها',
  'اليرقان عند حديثي الولادة',
};

bool isHiddenArticleTitle(String? title) =>
    kHideMedicalFeatures && title != null && kMedicalArticleTitles.contains(title);

/// مبدّل اللغة مخفي حتى تكتمل ترجمة الإنجليزية والفرنسية
/// (حاليًا لا تتغيّر إلا بعض عناوين الإعدادات).
const bool kShowLanguagePicker = false;

/// اسم الكاتب الموحّد لكل المقالات. لا يوجد فريق طبي ولا أطباء مراجِعون،
/// فلا يُنسب أي محتوى إلى طبيب أو «فريق طبي».
const String kEditorialAuthor = 'فريق تحرير نبضة';
