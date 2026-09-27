/// إعدادات عرض المتجر.
///
/// بقرار المالك (27 سبتمبر 2026): لا يبيع متجر نبضة الفيتامينات والمكملات
/// الغذائية ولا الأجهزة الطبية. تُخفى هذه المنتجات من كل مكان تُعرض فيه
/// (المتجر، المنتجات المقترحة داخل المقالات، بطاقات الرئيسية) حتى لو بقيت
/// محفوظة في Firestore.
library;

/// أقسام المتجر المحذوفة.
const Set<String> kHiddenShopCategories = {
  'فيتامينات ومكملات',
  'مكملات غذائية',
  'مكملات طبيعية',
  'أطعمة ومكملات',
  'أجهزة طبية',
};

/// كلمات في اسم المنتج تدل على مكمّل غذائي حتى لو صُنّف في قسم آخر.
const List<String> _supplementNameWords = [
  'مكمل', 'مكمّل', 'فيتامينات', 'حمض الفوليك', 'أوميغا', 'حديد +', 'كالسيوم +',
];

/// هل يُخفى هذا المنتج؟ يقبل وثيقة Firestore أو خريطة منتج ثابتة.
bool isHiddenProduct(Map<dynamic, dynamic>? product) {
  if (product == null) return false;
  final category = (product['category'] ?? '').toString().trim();
  if (kHiddenShopCategories.contains(category)) return true;
  final name = (product['name'] ?? product['title'] ?? '').toString();
  return _supplementNameWords.any(name.contains);
}
