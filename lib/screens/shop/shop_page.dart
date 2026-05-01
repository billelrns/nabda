import 'package:flutter/material.dart';

// ─── Theme Colors ───
const Color _bgColor = Color(0xFFFFF5F7);
const Color _cardColor = Colors.white;
const Color _teal = Color(0xFF00897B);
const Color _pink = Color(0xFFE91E63);
const Color _softPink = Color(0xFFFFE8EC);
const Color _textPrimary = Color(0xFF2D2D3A);
const Color _textSecondary = Color(0xFF6B7280);

// ─── Product Model ───
class _Product {
  final String name;
  final String emoji;
  final String price;
  final String oldPrice;
  final double rating;
  final Color color;
  final String desc;
  const _Product({required this.name, required this.emoji, required this.price, this.oldPrice = '', this.rating = 4.5, required this.color, this.desc = ''});
}

// ─── Category Model ───
class _ShopCategory {
  final String name;
  final String emoji;
  final Color color;
  final List<_Product> products;
  const _ShopCategory({required this.name, required this.emoji, required this.color, required this.products});
}

// ─── 15 Categories with 20+ Products Each ───
final List<_ShopCategory> _shopCategories = [
  // 1. ملابس الحمل
  _ShopCategory(name: 'ملابس الحمل', emoji: '👗', color: const Color(0xFFE91E63), products: [
    _Product(name: 'فستان حمل قطني مريح', emoji: '👗', price: '2,500 د.ج', oldPrice: '3,200 د.ج', rating: 4.8, color: const Color(0xFFE91E63)),
    _Product(name: 'بنطلون حمل مطاطي', emoji: '👖', price: '1,800 د.ج', rating: 4.6, color: const Color(0xFF5C6BC0)),
    _Product(name: 'تيشيرت حمل واسع', emoji: '👚', price: '1,200 د.ج', rating: 4.5, color: const Color(0xFF26A69A)),
    _Product(name: 'جاكيت حمل شتوي', emoji: '🧥', price: '4,500 د.ج', oldPrice: '5,800 د.ج', rating: 4.7, color: const Color(0xFF8D6E63)),
    _Product(name: 'بيجامة حمل ناعمة', emoji: '🩱', price: '2,200 د.ج', rating: 4.9, color: const Color(0xFFAB47BC)),
    _Product(name: 'حزام دعم البطن', emoji: '🎀', price: '1,500 د.ج', rating: 4.8, color: const Color(0xFFFF7043)),
    _Product(name: 'ليقنز حمل أسود', emoji: '👖', price: '1,400 د.ج', rating: 4.6, color: const Color(0xFF424242)),
    _Product(name: 'قميص نوم للحامل', emoji: '👘', price: '1,800 د.ج', rating: 4.5, color: const Color(0xFFEC407A)),
    _Product(name: 'تنورة حمل مريحة', emoji: '👗', price: '1,600 د.ج', rating: 4.4, color: const Color(0xFF66BB6A)),
    _Product(name: 'صدرية حمل داعمة', emoji: '👙', price: '900 د.ج', oldPrice: '1,300 د.ج', rating: 4.7, color: const Color(0xFFEF5350)),
    _Product(name: 'فستان سهرة للحامل', emoji: '👗', price: '5,500 د.ج', rating: 4.8, color: const Color(0xFF7E57C2)),
    _Product(name: 'معطف حمل أنيق', emoji: '🧥', price: '6,000 د.ج', rating: 4.6, color: const Color(0xFF5D4037)),
    _Product(name: 'شورت حمل صيفي', emoji: '🩳', price: '1,100 د.ج', rating: 4.3, color: const Color(0xFF29B6F6)),
    _Product(name: 'بلوزة حمل رسمية', emoji: '👚', price: '2,000 د.ج', rating: 4.5, color: const Color(0xFF26A69A)),
    _Product(name: 'فستان حمل كاجوال', emoji: '👗', price: '2,800 د.ج', rating: 4.7, color: const Color(0xFFFF8F00)),
    _Product(name: 'سروال رياضي للحامل', emoji: '👖', price: '1,600 د.ج', rating: 4.4, color: const Color(0xFF78909C)),
    _Product(name: 'كارديجان حمل صوف', emoji: '🧶', price: '3,200 د.ج', rating: 4.6, color: const Color(0xFFBCAAA4)),
    _Product(name: 'حمالة صدر رياضية', emoji: '👙', price: '1,000 د.ج', rating: 4.5, color: const Color(0xFF424242)),
    _Product(name: 'فستان حمل مخطط', emoji: '👗', price: '2,300 د.ج', rating: 4.6, color: const Color(0xFF1565C0)),
    _Product(name: 'طقم بيجامة قطنية', emoji: '🩱', price: '2,800 د.ج', oldPrice: '3,500 د.ج', rating: 4.8, color: const Color(0xFFEC407A)),
  ]),

  // 2. لوازم الرضيع
  _ShopCategory(name: 'لوازم الرضيع', emoji: '👶', color: const Color(0xFF42A5F5), products: [
    _Product(name: 'سرير أطفال خشبي', emoji: '🛏️', price: '15,000 د.ج', oldPrice: '18,000 د.ج', rating: 4.9, color: const Color(0xFF8D6E63)),
    _Product(name: 'عربة أطفال قابلة للطي', emoji: '🚼', price: '12,000 د.ج', rating: 4.8, color: const Color(0xFF42A5F5)),
    _Product(name: 'كرسي سيارة للرضع', emoji: '🚗', price: '8,500 د.ج', rating: 4.9, color: const Color(0xFF424242)),
    _Product(name: 'حاملة أطفال كانغارو', emoji: '🦘', price: '3,500 د.ج', rating: 4.7, color: const Color(0xFF66BB6A)),
    _Product(name: 'سجادة لعب ملونة', emoji: '🧸', price: '4,200 د.ج', rating: 4.6, color: const Color(0xFFFF7043)),
    _Product(name: 'مقعد هزاز كهربائي', emoji: '💺', price: '9,800 د.ج', oldPrice: '12,000 د.ج', rating: 4.8, color: const Color(0xFF7E57C2)),
    _Product(name: 'حوض استحمام للرضع', emoji: '🛁', price: '2,500 د.ج', rating: 4.5, color: const Color(0xFF29B6F6)),
    _Product(name: 'مرتبة سرير أطفال', emoji: '🛏️', price: '3,800 د.ج', rating: 4.7, color: const Color(0xFFBCAAA4)),
    _Product(name: 'ناموسية سرير', emoji: '🪟', price: '1,800 د.ج', rating: 4.4, color: const Color(0xFFE0E0E0)),
    _Product(name: 'طاولة تغيير حفاضات', emoji: '🪑', price: '7,500 د.ج', rating: 4.6, color: const Color(0xFF8D6E63)),
    _Product(name: 'مشاية أطفال', emoji: '🚶', price: '5,200 د.ج', rating: 4.3, color: const Color(0xFF66BB6A)),
    _Product(name: 'كاميرا مراقبة الطفل', emoji: '📹', price: '6,800 د.ج', rating: 4.8, color: const Color(0xFF424242)),
    _Product(name: 'مصباح ليلي هادئ', emoji: '🌙', price: '1,500 د.ج', rating: 4.5, color: const Color(0xFFFFB300)),
    _Product(name: 'جهاز صوت أبيض', emoji: '🔊', price: '2,200 د.ج', rating: 4.7, color: const Color(0xFF78909C)),
    _Product(name: 'سلة ملابس أطفال', emoji: '🧺', price: '1,200 د.ج', rating: 4.3, color: const Color(0xFFBCAAA4)),
    _Product(name: 'حامل زجاجات', emoji: '🍼', price: '800 د.ج', rating: 4.2, color: const Color(0xFF26A69A)),
    _Product(name: 'وسادة إرضاع', emoji: '🛋️', price: '2,800 د.ج', oldPrice: '3,500 د.ج', rating: 4.8, color: const Color(0xFFEC407A)),
    _Product(name: 'ميزان أطفال رقمي', emoji: '⚖️', price: '3,200 د.ج', rating: 4.6, color: const Color(0xFF42A5F5)),
    _Product(name: 'مجموعة أمان المنزل', emoji: '🔒', price: '1,800 د.ج', rating: 4.5, color: const Color(0xFFEF5350)),
    _Product(name: 'صندوق تخزين ألعاب', emoji: '📦', price: '2,000 د.ج', rating: 4.4, color: const Color(0xFFFF7043)),
  ]),

  // 3. ملابس المولود
  _ShopCategory(name: 'ملابس المولود', emoji: '🍼', color: const Color(0xFFEC407A), products: [
    _Product(name: 'طقم مولود جديد 5 قطع', emoji: '👶', price: '3,500 د.ج', oldPrice: '4,500 د.ج', rating: 4.9, color: const Color(0xFFEC407A)),
    _Product(name: 'بدلة نوم قطنية', emoji: '🩱', price: '800 د.ج', rating: 4.7, color: const Color(0xFF29B6F6)),
    _Product(name: 'قبعة مولود صوف', emoji: '🧢', price: '400 د.ج', rating: 4.5, color: const Color(0xFFFFB300)),
    _Product(name: 'جوارب مولود 6 أزواج', emoji: '🧦', price: '600 د.ج', rating: 4.6, color: const Color(0xFF66BB6A)),
    _Product(name: 'قفازات مولود ناعمة', emoji: '🧤', price: '350 د.ج', rating: 4.4, color: const Color(0xFFE0E0E0)),
    _Product(name: 'بطانية أطفال فليس', emoji: '🧣', price: '1,800 د.ج', rating: 4.8, color: const Color(0xFF7E57C2)),
    _Product(name: 'لفافة مولود (سوادل)', emoji: '🎁', price: '1,200 د.ج', rating: 4.7, color: const Color(0xFFE91E63)),
    _Product(name: 'فستان بنت مولودة', emoji: '👗', price: '1,500 د.ج', rating: 4.6, color: const Color(0xFFEC407A)),
    _Product(name: 'بدلة خروج مولود', emoji: '🤵', price: '2,800 د.ج', rating: 4.7, color: const Color(0xFF5C6BC0)),
    _Product(name: 'حذاء مولود ناعم', emoji: '👟', price: '500 د.ج', rating: 4.3, color: const Color(0xFFBCAAA4)),
    _Product(name: 'مريلة طعام 5 قطع', emoji: '🧷', price: '700 د.ج', rating: 4.5, color: const Color(0xFF26A69A)),
    _Product(name: 'بربتيوز قطني', emoji: '👕', price: '600 د.ج', rating: 4.6, color: const Color(0xFFFF7043)),
    _Product(name: 'طقم شتوي مبطن', emoji: '🧥', price: '3,200 د.ج', rating: 4.8, color: const Color(0xFF8D6E63)),
    _Product(name: 'بدلة سباحة للرضع', emoji: '🩱', price: '1,400 د.ج', rating: 4.3, color: const Color(0xFF29B6F6)),
    _Product(name: 'فوطة حمام بغطاء رأس', emoji: '🛁', price: '1,100 د.ج', rating: 4.7, color: const Color(0xFFFFB300)),
    _Product(name: 'طقم قطن عضوي', emoji: '🌿', price: '2,500 د.ج', rating: 4.9, color: const Color(0xFF66BB6A)),
    _Product(name: 'سالوبيت أطفال', emoji: '👶', price: '1,300 د.ج', rating: 4.5, color: const Color(0xFF42A5F5)),
    _Product(name: 'بودي سوت 3 قطع', emoji: '👕', price: '1,500 د.ج', rating: 4.6, color: const Color(0xFFE0E0E0)),
    _Product(name: 'طقم هدايا مولود', emoji: '🎁', price: '5,000 د.ج', oldPrice: '6,500 د.ج', rating: 4.9, color: const Color(0xFF7E57C2)),
    _Product(name: 'بطانية تريكو يدوية', emoji: '🧶', price: '2,200 د.ج', rating: 4.8, color: const Color(0xFFBCAAA4)),
  ]),

  // 4. الرضاعة
  _ShopCategory(name: 'الرضاعة والتغذية', emoji: '🤱', color: const Color(0xFFFF7043), products: [
    _Product(name: 'مضخة حليب كهربائية', emoji: '🍼', price: '8,500 د.ج', oldPrice: '10,000 د.ج', rating: 4.8, color: const Color(0xFF7E57C2)),
    _Product(name: 'زجاجات رضاعة مضادة للمغص', emoji: '🍼', price: '1,200 د.ج', rating: 4.7, color: const Color(0xFF42A5F5)),
    _Product(name: 'معقم زجاجات كهربائي', emoji: '♨️', price: '4,500 د.ج', rating: 4.8, color: const Color(0xFF78909C)),
    _Product(name: 'وسادة رضاعة مريحة', emoji: '🛋️', price: '2,800 د.ج', rating: 4.9, color: const Color(0xFFEC407A)),
    _Product(name: 'كريم حلمات لانولين', emoji: '🧴', price: '1,500 د.ج', rating: 4.7, color: const Color(0xFFFF7043)),
    _Product(name: 'أكياس تخزين الحليب', emoji: '🥛', price: '800 د.ج', rating: 4.5, color: const Color(0xFF29B6F6)),
    _Product(name: 'حمالة صدر رضاعة', emoji: '👙', price: '1,200 د.ج', rating: 4.6, color: const Color(0xFF424242)),
    _Product(name: 'غطاء رضاعة خارجي', emoji: '🧣', price: '900 د.ج', rating: 4.4, color: const Color(0xFF8D6E63)),
    _Product(name: 'خلاط طعام أطفال', emoji: '🥄', price: '3,500 د.ج', rating: 4.7, color: const Color(0xFF66BB6A)),
    _Product(name: 'كرسي طعام مرتفع', emoji: '🪑', price: '6,200 د.ج', oldPrice: '7,500 د.ج', rating: 4.8, color: const Color(0xFF8D6E63)),
    _Product(name: 'أطباق سيليكون مانعة للانزلاق', emoji: '🍽️', price: '1,100 د.ج', rating: 4.6, color: const Color(0xFF26A69A)),
    _Product(name: 'ملاعق سيليكون ناعمة', emoji: '🥄', price: '500 د.ج', rating: 4.5, color: const Color(0xFFFF7043)),
    _Product(name: 'كوب تعليم الشرب', emoji: '🥤', price: '700 د.ج', rating: 4.4, color: const Color(0xFF42A5F5)),
    _Product(name: 'سخان زجاجات', emoji: '🔥', price: '2,800 د.ج', rating: 4.6, color: const Color(0xFFEF5350)),
    _Product(name: 'فرشاة تنظيف زجاجات', emoji: '🧹', price: '400 د.ج', rating: 4.3, color: const Color(0xFF78909C)),
    _Product(name: 'حلمات بديلة 4 قطع', emoji: '🍼', price: '600 د.ج', rating: 4.5, color: const Color(0xFFE0E0E0)),
    _Product(name: 'حقيبة تبريد الحليب', emoji: '❄️', price: '1,800 د.ج', rating: 4.7, color: const Color(0xFF5C6BC0)),
    _Product(name: 'مريلة سيليكون بجيب', emoji: '🧷', price: '650 د.ج', rating: 4.5, color: const Color(0xFF66BB6A)),
    _Product(name: 'ضاغط حلمات سيليكون', emoji: '🤱', price: '500 د.ج', rating: 4.3, color: const Color(0xFFEC407A)),
    _Product(name: 'طقم أدوات تغذية كامل', emoji: '🍽️', price: '3,200 د.ج', oldPrice: '4,000 د.ج', rating: 4.8, color: const Color(0xFFFFB300)),
  ]),

  // 5. الحفاضات والنظافة
  _ShopCategory(name: 'الحفاضات والنظافة', emoji: '🧷', color: const Color(0xFF26A69A), products: [
    _Product(name: 'حفاضات حديثي الولادة 80 قطعة', emoji: '🧒', price: '1,800 د.ج', rating: 4.7, color: const Color(0xFF42A5F5)),
    _Product(name: 'مناديل مبللة 3 عبوات', emoji: '🧻', price: '700 د.ج', rating: 4.6, color: const Color(0xFF29B6F6)),
    _Product(name: 'كريم طفح الحفاض', emoji: '🧴', price: '900 د.ج', rating: 4.8, color: const Color(0xFFFF7043)),
    _Product(name: 'حفاضات قماش قابلة للغسل', emoji: '♻️', price: '4,500 د.ج', oldPrice: '5,500 د.ج', rating: 4.5, color: const Color(0xFF66BB6A)),
    _Product(name: 'سلة حفاضات مغلقة', emoji: '🗑️', price: '3,200 د.ج', rating: 4.7, color: const Color(0xFF78909C)),
    _Product(name: 'بودرة أطفال طبيعية', emoji: '✨', price: '600 د.ج', rating: 4.4, color: const Color(0xFFE0E0E0)),
    _Product(name: 'شامبو أطفال بدون دموع', emoji: '🧴', price: '800 د.ج', rating: 4.8, color: const Color(0xFF42A5F5)),
    _Product(name: 'صابون أطفال طبيعي', emoji: '🧼', price: '500 د.ج', rating: 4.6, color: const Color(0xFF66BB6A)),
    _Product(name: 'زيت أطفال مرطب', emoji: '💧', price: '700 د.ج', rating: 4.5, color: const Color(0xFFFFB300)),
    _Product(name: 'مقص أظافر أطفال آمن', emoji: '✂️', price: '400 د.ج', rating: 4.3, color: const Color(0xFF78909C)),
    _Product(name: 'فرشاة شعر أطفال', emoji: '💆', price: '350 د.ج', rating: 4.4, color: const Color(0xFFEC407A)),
    _Product(name: 'ميزان حرارة رقمي', emoji: '🌡️', price: '1,200 د.ج', rating: 4.7, color: const Color(0xFFEF5350)),
    _Product(name: 'شفاطة أنف للرضع', emoji: '💨', price: '600 د.ج', rating: 4.5, color: const Color(0xFF29B6F6)),
    _Product(name: 'حقيبة حفاضات أنيقة', emoji: '👜', price: '3,800 د.ج', oldPrice: '4,500 د.ج', rating: 4.8, color: const Color(0xFF8D6E63)),
    _Product(name: 'مشط تدليك فروة الرأس', emoji: '🧽', price: '300 د.ج', rating: 4.2, color: const Color(0xFFBCAAA4)),
    _Product(name: 'مجموعة عناية الأظافر', emoji: '💅', price: '800 د.ج', rating: 4.6, color: const Color(0xFFAB47BC)),
    _Product(name: 'كرسي حمام أطفال', emoji: '🪑', price: '2,200 د.ج', rating: 4.5, color: const Color(0xFF26A69A)),
    _Product(name: 'منشفة قطن عضوي', emoji: '🧽', price: '1,000 د.ج', rating: 4.7, color: const Color(0xFFE0E0E0)),
    _Product(name: 'لوشن أطفال مرطب', emoji: '🧴', price: '750 د.ج', rating: 4.6, color: const Color(0xFFEC407A)),
    _Product(name: 'طقم استحمام كامل', emoji: '🛁', price: '4,000 د.ج', oldPrice: '5,000 د.ج', rating: 4.9, color: const Color(0xFF42A5F5)),
  ]),

  // 6. مستحضرات العناية بالحامل
  _ShopCategory(name: 'عناية بالحامل', emoji: '💆‍♀️', color: const Color(0xFFAB47BC), products: [
    _Product(name: 'كريم منع علامات التمدد', emoji: '🧴', price: '2,500 د.ج', oldPrice: '3,200 د.ج', rating: 4.9, color: const Color(0xFFEC407A)),
    _Product(name: 'زيت اللوز للبشرة', emoji: '💧', price: '1,200 د.ج', rating: 4.7, color: const Color(0xFFFFB300)),
    _Product(name: 'زبدة الشيا الطبيعية', emoji: '🥜', price: '1,500 د.ج', rating: 4.8, color: const Color(0xFF8D6E63)),
    _Product(name: 'واقي شمس SPF50 للحامل', emoji: '☀️', price: '1,800 د.ج', rating: 4.6, color: const Color(0xFFFF7043)),
    _Product(name: 'مرطب وجه طبيعي', emoji: '✨', price: '2,000 د.ج', rating: 4.7, color: const Color(0xFF26A69A)),
    _Product(name: 'زيت جوز الهند عضوي', emoji: '🥥', price: '1,000 د.ج', rating: 4.5, color: const Color(0xFF66BB6A)),
    _Product(name: 'ماسك وجه مغذي', emoji: '🎭', price: '800 د.ج', rating: 4.4, color: const Color(0xFF7E57C2)),
    _Product(name: 'كريم ترطيب البطن', emoji: '🧴', price: '1,800 د.ج', rating: 4.8, color: const Color(0xFFE91E63)),
    _Product(name: 'سيروم فيتامين C', emoji: '🍊', price: '2,200 د.ج', rating: 4.6, color: const Color(0xFFFF7043)),
    _Product(name: 'جل ألوفيرا طبيعي', emoji: '🌿', price: '700 د.ج', rating: 4.5, color: const Color(0xFF66BB6A)),
    _Product(name: 'كريم قدمين مريح', emoji: '🦶', price: '900 د.ج', rating: 4.4, color: const Color(0xFF26A69A)),
    _Product(name: 'زيت تدليك الحمل', emoji: '💆', price: '1,400 د.ج', rating: 4.7, color: const Color(0xFFAB47BC)),
    _Product(name: 'مزيل عرق طبيعي', emoji: '🌸', price: '600 د.ج', rating: 4.3, color: const Color(0xFFEC407A)),
    _Product(name: 'بلسم شفاه مرطب', emoji: '💋', price: '350 د.ج', rating: 4.5, color: const Color(0xFFEF5350)),
    _Product(name: 'شامبو بدون كبريتات', emoji: '🧴', price: '1,100 د.ج', rating: 4.6, color: const Color(0xFF42A5F5)),
    _Product(name: 'ماء ميسيلار منظف', emoji: '💧', price: '900 د.ج', rating: 4.5, color: const Color(0xFF29B6F6)),
    _Product(name: 'كريم يدين مغذي', emoji: '🤲', price: '500 د.ج', rating: 4.4, color: const Color(0xFFBCAAA4)),
    _Product(name: 'زيت الأرغان للشعر', emoji: '💇', price: '1,600 د.ج', rating: 4.7, color: const Color(0xFF8D6E63)),
    _Product(name: 'مجموعة عناية كاملة', emoji: '🎁', price: '6,500 د.ج', oldPrice: '8,000 د.ج', rating: 4.9, color: const Color(0xFF7E57C2)),
    _Product(name: 'حناء طبيعية للشعر', emoji: '🌿', price: '800 د.ج', rating: 4.4, color: const Color(0xFF66BB6A)),
  ]),

  // 7. الفيتامينات والمكملات
  _ShopCategory(name: 'فيتامينات ومكملات', emoji: '💊', color: const Color(0xFFFF8F00), products: [
    _Product(name: 'حمض الفوليك 400mcg', emoji: '💊', price: '800 د.ج', rating: 4.9, color: const Color(0xFF66BB6A)),
    _Product(name: 'حديد + فيتامين C', emoji: '💪', price: '1,200 د.ج', rating: 4.7, color: const Color(0xFFEF5350)),
    _Product(name: 'أوميغا 3 DHA للحامل', emoji: '🐟', price: '2,500 د.ج', rating: 4.8, color: const Color(0xFF29B6F6)),
    _Product(name: 'كالسيوم + فيتامين D', emoji: '🦴', price: '1,500 د.ج', rating: 4.7, color: const Color(0xFFE0E0E0)),
    _Product(name: 'فيتامين حمل شامل', emoji: '✨', price: '3,000 د.ج', oldPrice: '3,800 د.ج', rating: 4.9, color: const Color(0xFFFF8F00)),
    _Product(name: 'مغنيسيوم للتشنجات', emoji: '⚡', price: '1,000 د.ج', rating: 4.6, color: const Color(0xFF7E57C2)),
    _Product(name: 'بروبيوتيك للحامل', emoji: '🦠', price: '1,800 د.ج', rating: 4.5, color: const Color(0xFF26A69A)),
    _Product(name: 'فيتامين B12', emoji: '💊', price: '900 د.ج', rating: 4.4, color: const Color(0xFFEF5350)),
    _Product(name: 'زنك للمناعة', emoji: '🛡️', price: '800 د.ج', rating: 4.5, color: const Color(0xFF42A5F5)),
    _Product(name: 'فيتامين E كبسولات', emoji: '💊', price: '700 د.ج', rating: 4.3, color: const Color(0xFF66BB6A)),
    _Product(name: 'شاي أوراق التوت الأحمر', emoji: '🍵', price: '600 د.ج', rating: 4.6, color: const Color(0xFFEF5350)),
    _Product(name: 'مشروب زنجبيل للغثيان', emoji: '🫚', price: '500 د.ج', rating: 4.7, color: const Color(0xFFFF8F00)),
    _Product(name: 'كولاجين آمن للحامل', emoji: '✨', price: '2,800 د.ج', rating: 4.5, color: const Color(0xFFEC407A)),
    _Product(name: 'فيتامين A بيتا كاروتين', emoji: '🥕', price: '900 د.ج', rating: 4.4, color: const Color(0xFFFF7043)),
    _Product(name: 'يود للغدة الدرقية', emoji: '💊', price: '700 د.ج', rating: 4.3, color: const Color(0xFF5C6BC0)),
    _Product(name: 'تمر عجوة ممتاز 500g', emoji: '🌴', price: '1,500 د.ج', rating: 4.8, color: const Color(0xFF8D6E63)),
    _Product(name: 'عسل طبيعي 500g', emoji: '🍯', price: '2,000 د.ج', rating: 4.7, color: const Color(0xFFFFB300)),
    _Product(name: 'حبة البركة مطحونة', emoji: '🌰', price: '800 د.ج', rating: 4.5, color: const Color(0xFF424242)),
    _Product(name: 'بذور الشيا العضوية', emoji: '🌱', price: '1,200 د.ج', rating: 4.6, color: const Color(0xFF66BB6A)),
    _Product(name: 'طقم فيتامينات الحمل الكامل', emoji: '🎁', price: '5,500 د.ج', oldPrice: '7,000 د.ج', rating: 4.9, color: const Color(0xFF7E57C2)),
  ]),

  // 8. حقيبة الولادة
  _ShopCategory(name: 'حقيبة الولادة', emoji: '🧳', color: const Color(0xFF5C6BC0), products: [
    _Product(name: 'حقيبة ولادة جاهزة كاملة', emoji: '🧳', price: '8,000 د.ج', oldPrice: '10,000 د.ج', rating: 4.9, color: const Color(0xFF5C6BC0)),
    _Product(name: 'فوط نفاس عالية الامتصاص', emoji: '🩹', price: '900 د.ج', rating: 4.7, color: const Color(0xFFE0E0E0)),
    _Product(name: 'ملابس داخلية قطنية واسعة', emoji: '👙', price: '600 د.ج', rating: 4.5, color: const Color(0xFFEC407A)),
    _Product(name: 'روب حمام مريح', emoji: '🧖', price: '2,500 د.ج', rating: 4.6, color: const Color(0xFF7E57C2)),
    _Product(name: 'شبشب مستشفى مريح', emoji: '🩴', price: '500 د.ج', rating: 4.4, color: const Color(0xFF26A69A)),
    _Product(name: 'طقم مولود خروج', emoji: '👶', price: '3,200 د.ج', rating: 4.8, color: const Color(0xFFFF7043)),
    _Product(name: 'حفاضات مولود 30 قطعة', emoji: '🧒', price: '800 د.ج', rating: 4.6, color: const Color(0xFF42A5F5)),
    _Product(name: 'بطانية مولود ناعمة', emoji: '🧣', price: '1,500 د.ج', rating: 4.7, color: const Color(0xFFFFB300)),
    _Product(name: 'مستلزمات نظافة شخصية', emoji: '🧴', price: '1,200 د.ج', rating: 4.5, color: const Color(0xFF78909C)),
    _Product(name: 'كمادات ثدي قطنية', emoji: '🩹', price: '500 د.ج', rating: 4.4, color: const Color(0xFFE0E0E0)),
    _Product(name: 'مناديل مبللة للأم', emoji: '🧻', price: '400 د.ج', rating: 4.5, color: const Color(0xFF29B6F6)),
    _Product(name: 'شريط مطاطي للشعر', emoji: '💇', price: '200 د.ج', rating: 4.2, color: const Color(0xFF424242)),
    _Product(name: 'زجاجة مياه كبيرة', emoji: '🧊', price: '600 د.ج', rating: 4.4, color: const Color(0xFF42A5F5)),
    _Product(name: 'وجبات خفيفة صحية', emoji: '🥜', price: '1,000 د.ج', rating: 4.5, color: const Color(0xFF66BB6A)),
    _Product(name: 'شاحن هاتف محمول', emoji: '🔋', price: '800 د.ج', rating: 4.3, color: const Color(0xFF424242)),
    _Product(name: 'قميص رضاعة مستشفى', emoji: '👚', price: '1,500 د.ج', rating: 4.6, color: const Color(0xFFEC407A)),
    _Product(name: 'كيس ملابس متسخة', emoji: '🧺', price: '300 د.ج', rating: 4.2, color: const Color(0xFF78909C)),
    _Product(name: 'مجموعة عناية المولود', emoji: '🧸', price: '2,500 د.ج', rating: 4.7, color: const Color(0xFF26A69A)),
    _Product(name: 'دفتر ملاحظات صغير', emoji: '📝', price: '250 د.ج', rating: 4.1, color: const Color(0xFFBCAAA4)),
    _Product(name: 'حقيبة ولادة ديلوكس', emoji: '💎', price: '12,000 د.ج', oldPrice: '15,000 د.ج', rating: 4.9, color: const Color(0xFF7E57C2)),
  ]),

  // 9. ألعاب وتحفيز
  _ShopCategory(name: 'ألعاب وتحفيز', emoji: '🧸', color: const Color(0xFFFFB300), products: [
    _Product(name: 'خشخيشة ملونة', emoji: '🎵', price: '400 د.ج', rating: 4.5, color: const Color(0xFFEF5350)),
    _Product(name: 'لعبة تعليق سرير موسيقية', emoji: '🎶', price: '2,500 د.ج', rating: 4.8, color: const Color(0xFF42A5F5)),
    _Product(name: 'كتاب قماش ملون', emoji: '📖', price: '800 د.ج', rating: 4.6, color: const Color(0xFF66BB6A)),
    _Product(name: 'حلقات تسنين سيليكون', emoji: '🦷', price: '500 د.ج', rating: 4.7, color: const Color(0xFF29B6F6)),
    _Product(name: 'دمية قطنية ناعمة', emoji: '🧸', price: '1,200 د.ج', rating: 4.5, color: const Color(0xFFBCAAA4)),
    _Product(name: 'مرآة أطفال آمنة', emoji: '🪞', price: '700 د.ج', rating: 4.4, color: const Color(0xFFE0E0E0)),
    _Product(name: 'كرات حسية ملونة', emoji: '🔴', price: '900 د.ج', rating: 4.6, color: const Color(0xFFFF7043)),
    _Product(name: 'بطاقات أبيض وأسود', emoji: '🃏', price: '600 د.ج', rating: 4.7, color: const Color(0xFF424242)),
    _Product(name: 'لعبة مكعبات ناعمة', emoji: '🧊', price: '1,000 د.ج', rating: 4.5, color: const Color(0xFF7E57C2)),
    _Product(name: 'سجادة أنشطة تفاعلية', emoji: '🎪', price: '4,500 د.ج', oldPrice: '5,500 د.ج', rating: 4.8, color: const Color(0xFFFFB300)),
    _Product(name: 'لعبة حمام عائمة', emoji: '🦆', price: '500 د.ج', rating: 4.4, color: const Color(0xFFFFB300)),
    _Product(name: 'كرة موسيقية متدحرجة', emoji: '⚽', price: '800 د.ج', rating: 4.5, color: const Color(0xFF66BB6A)),
    _Product(name: 'لعبة أصابع يدوية', emoji: '🤚', price: '600 د.ج', rating: 4.3, color: const Color(0xFFEC407A)),
    _Product(name: 'حلقات تكديس', emoji: '🔵', price: '700 د.ج', rating: 4.6, color: const Color(0xFF42A5F5)),
    _Product(name: 'لعبة ضوئية دوارة', emoji: '🌟', price: '1,500 د.ج', rating: 4.5, color: const Color(0xFF5C6BC0)),
    _Product(name: 'كتاب حمام مقاوم للماء', emoji: '📚', price: '500 د.ج', rating: 4.4, color: const Color(0xFF29B6F6)),
    _Product(name: 'لعبة مفاتيح ملونة', emoji: '🔑', price: '400 د.ج', rating: 4.3, color: const Color(0xFFFF8F00)),
    _Product(name: 'أرنب نوم مع موسيقى', emoji: '🐰', price: '2,200 د.ج', rating: 4.8, color: const Color(0xFFBCAAA4)),
    _Product(name: 'لعبة شد وسحب', emoji: '🎈', price: '600 د.ج', rating: 4.4, color: const Color(0xFFEF5350)),
    _Product(name: 'طقم ألعاب حسية كامل', emoji: '🎁', price: '3,800 د.ج', oldPrice: '4,500 د.ج', rating: 4.9, color: const Color(0xFF7E57C2)),
  ]),

  // 10. راحة الأم
  _ShopCategory(name: 'راحة الأم', emoji: '🛋️', color: const Color(0xFF78909C), products: [
    _Product(name: 'وسادة حمل U-Shape', emoji: '🛋️', price: '5,500 د.ج', oldPrice: '7,000 د.ج', rating: 4.9, color: const Color(0xFF7E57C2)),
    _Product(name: 'وسادة حمل C-Shape', emoji: '🌙', price: '4,200 د.ج', rating: 4.8, color: const Color(0xFF5C6BC0)),
    _Product(name: 'جوارب ضغط طبية', emoji: '🧦', price: '1,800 د.ج', rating: 4.7, color: const Color(0xFF424242)),
    _Product(name: 'حذاء مريح مسطح', emoji: '👟', price: '2,500 د.ج', rating: 4.6, color: const Color(0xFF8D6E63)),
    _Product(name: 'كرة تمارين الحمل', emoji: '🏐', price: '3,000 د.ج', rating: 4.8, color: const Color(0xFFEC407A)),
    _Product(name: 'حزام ظهر داعم', emoji: '🎗️', price: '2,200 د.ج', rating: 4.7, color: const Color(0xFF424242)),
    _Product(name: 'مسند قدمين مريح', emoji: '🦶', price: '1,800 د.ج', rating: 4.5, color: const Color(0xFF8D6E63)),
    _Product(name: 'زيت تدليك لافندر', emoji: '💜', price: '1,000 د.ج', rating: 4.6, color: const Color(0xFFAB47BC)),
    _Product(name: 'كمادة حرارية للظهر', emoji: '🔥', price: '1,500 د.ج', rating: 4.7, color: const Color(0xFFEF5350)),
    _Product(name: 'مشد بطن بعد الولادة', emoji: '🎀', price: '2,800 د.ج', rating: 4.6, color: const Color(0xFFE91E63)),
    _Product(name: 'نعل طبي للحامل', emoji: '👣', price: '1,200 د.ج', rating: 4.5, color: const Color(0xFF26A69A)),
    _Product(name: 'وسادة جلوس مريحة', emoji: '💺', price: '2,000 د.ج', rating: 4.4, color: const Color(0xFF78909C)),
    _Product(name: 'غطاء عين نوم حريري', emoji: '😴', price: '500 د.ج', rating: 4.5, color: const Color(0xFF5C6BC0)),
    _Product(name: 'سماعات نوم مريحة', emoji: '🎧', price: '1,800 د.ج', rating: 4.4, color: const Color(0xFF424242)),
    _Product(name: 'مجموعة حمام استرخاء', emoji: '🛁', price: '2,500 د.ج', rating: 4.7, color: const Color(0xFFAB47BC)),
    _Product(name: 'شاي أعشاب مهدئ', emoji: '🍵', price: '600 د.ج', rating: 4.5, color: const Color(0xFF66BB6A)),
    _Product(name: 'رول تدليك خشبي', emoji: '🪵', price: '800 د.ج', rating: 4.3, color: const Color(0xFF8D6E63)),
    _Product(name: 'بخاخ وسادة لافندر', emoji: '🌿', price: '700 د.ج', rating: 4.6, color: const Color(0xFFAB47BC)),
    _Product(name: 'جهاز تدليك قدمين', emoji: '🦶', price: '6,500 د.ج', oldPrice: '8,000 د.ج', rating: 4.8, color: const Color(0xFF78909C)),
    _Product(name: 'طقم استرخاء كامل', emoji: '🎁', price: '8,000 د.ج', oldPrice: '10,000 د.ج', rating: 4.9, color: const Color(0xFF7E57C2)),
  ]),

  // 11. كتب وأدلة
  _ShopCategory(name: 'كتب وأدلة', emoji: '📚', color: const Color(0xFF66BB6A), products: [
    _Product(name: 'كتاب ماذا تتوقعين عندما تنتظرين', emoji: '📖', price: '2,000 د.ج', rating: 4.9, color: const Color(0xFF42A5F5)),
    _Product(name: 'دليل التغذية للحامل', emoji: '🥗', price: '1,500 د.ج', rating: 4.7, color: const Color(0xFF66BB6A)),
    _Product(name: 'كتاب تربية الأطفال', emoji: '👶', price: '1,800 د.ج', rating: 4.6, color: const Color(0xFFEC407A)),
    _Product(name: 'دفتر متابعة الحمل', emoji: '📔', price: '1,200 د.ج', rating: 4.8, color: const Color(0xFF7E57C2)),
    _Product(name: 'كتاب الرضاعة الطبيعية', emoji: '🤱', price: '1,500 د.ج', rating: 4.7, color: const Color(0xFFFF7043)),
    _Product(name: 'دليل الولادة الطبيعية', emoji: '🏥', price: '1,800 د.ج', rating: 4.5, color: const Color(0xFF26A69A)),
    _Product(name: 'كتاب نوم الرضيع', emoji: '😴', price: '1,200 د.ج', rating: 4.6, color: const Color(0xFF5C6BC0)),
    _Product(name: 'يوميات أمي الأولى', emoji: '📝', price: '900 د.ج', rating: 4.8, color: const Color(0xFFEC407A)),
    _Product(name: 'كتاب يوغا الحمل', emoji: '🧘', price: '1,500 د.ج', rating: 4.5, color: const Color(0xFFAB47BC)),
    _Product(name: 'دليل السنة الأولى', emoji: '🎂', price: '2,000 د.ج', rating: 4.7, color: const Color(0xFFFFB300)),
    _Product(name: 'ألبوم ذكريات الحمل', emoji: '📸', price: '2,500 د.ج', oldPrice: '3,200 د.ج', rating: 4.9, color: const Color(0xFFE91E63)),
    _Product(name: 'كتاب أسماء المواليد', emoji: '✍️', price: '800 د.ج', rating: 4.4, color: const Color(0xFF78909C)),
    _Product(name: 'دليل الإسعافات الأولية', emoji: '⛑️', price: '1,200 د.ج', rating: 4.7, color: const Color(0xFFEF5350)),
    _Product(name: 'كتاب تعليم الطفل القرآن', emoji: '📖', price: '1,000 د.ج', rating: 4.8, color: const Color(0xFF66BB6A)),
    _Product(name: 'ألبوم بصمة يد ورجل', emoji: '🐾', price: '1,500 د.ج', rating: 4.6, color: const Color(0xFF42A5F5)),
    _Product(name: 'كتاب طبخ صحي للحامل', emoji: '🍳', price: '1,800 د.ج', rating: 4.5, color: const Color(0xFFFF8F00)),
    _Product(name: 'دليل العودة للعمل', emoji: '💼', price: '1,000 د.ج', rating: 4.3, color: const Color(0xFF5C6BC0)),
    _Product(name: 'كتاب أدعية الحمل', emoji: '🤲', price: '600 د.ج', rating: 4.9, color: const Color(0xFF26A69A)),
    _Product(name: 'ملصقات شهور الطفل', emoji: '🏷️', price: '500 د.ج', rating: 4.5, color: const Color(0xFFEC407A)),
    _Product(name: 'طقم كتب أمومة كامل', emoji: '📚', price: '6,000 د.ج', oldPrice: '8,000 د.ج', rating: 4.9, color: const Color(0xFF7E57C2)),
  ]),

  // 12. أجهزة طبية
  _ShopCategory(name: 'أجهزة طبية', emoji: '🩺', color: const Color(0xFFEF5350), products: [
    _Product(name: 'جهاز دوبلر لسماع نبض الجنين', emoji: '💗', price: '6,500 د.ج', oldPrice: '8,000 د.ج', rating: 4.8, color: const Color(0xFFEF5350)),
    _Product(name: 'جهاز قياس ضغط الدم', emoji: '🩺', price: '4,500 د.ج', rating: 4.7, color: const Color(0xFF424242)),
    _Product(name: 'ميزان ذكي للوزن', emoji: '⚖️', price: '3,800 د.ج', rating: 4.6, color: const Color(0xFF78909C)),
    _Product(name: 'جهاز قياس السكر', emoji: '🩸', price: '3,200 د.ج', rating: 4.7, color: const Color(0xFF42A5F5)),
    _Product(name: 'ميزان حرارة ذكي', emoji: '🌡️', price: '2,000 د.ج', rating: 4.5, color: const Color(0xFFFF7043)),
    _Product(name: 'جهاز TENS لألم المخاض', emoji: '⚡', price: '5,500 د.ج', rating: 4.8, color: const Color(0xFF7E57C2)),
    _Product(name: 'مقياس أكسجين النبض', emoji: '❤️', price: '2,500 د.ج', rating: 4.6, color: const Color(0xFFEF5350)),
    _Product(name: 'شريط قياس البطن', emoji: '📏', price: '300 د.ج', rating: 4.4, color: const Color(0xFFFFB300)),
    _Product(name: 'اختبار حمل منزلي 3 قطع', emoji: '🧪', price: '500 د.ج', rating: 4.5, color: const Color(0xFF29B6F6)),
    _Product(name: 'شرائط قياس البول', emoji: '🧪', price: '700 د.ج', rating: 4.3, color: const Color(0xFF66BB6A)),
    _Product(name: 'ساعة ذكية للصحة', emoji: '⌚', price: '8,000 د.ج', rating: 4.7, color: const Color(0xFF424242)),
    _Product(name: 'جهاز ترطيب الهواء', emoji: '💨', price: '4,000 د.ج', rating: 4.6, color: const Color(0xFF42A5F5)),
    _Product(name: 'مقياس درجة حرارة الغرفة', emoji: '🏠', price: '800 د.ج', rating: 4.4, color: const Color(0xFF78909C)),
    _Product(name: 'جهاز شفط الحليب يدوي', emoji: '🍼', price: '2,500 د.ج', rating: 4.5, color: const Color(0xFFEC407A)),
    _Product(name: 'ضمادات جل باردة', emoji: '🧊', price: '600 د.ج', rating: 4.4, color: const Color(0xFF29B6F6)),
    _Product(name: 'ميزان حرارة أذن', emoji: '👂', price: '2,800 د.ج', rating: 4.7, color: const Color(0xFF5C6BC0)),
    _Product(name: 'قفازات طبية 100 قطعة', emoji: '🧤', price: '500 د.ج', rating: 4.3, color: const Color(0xFF26A69A)),
    _Product(name: 'معقم يدين طبي 500ml', emoji: '🧴', price: '400 د.ج', rating: 4.5, color: const Color(0xFF42A5F5)),
    _Product(name: 'كمامات طبية 50 قطعة', emoji: '😷', price: '600 د.ج', rating: 4.4, color: const Color(0xFF29B6F6)),
    _Product(name: 'حقيبة إسعافات أولية', emoji: '🩹', price: '2,200 د.ج', oldPrice: '2,800 د.ج', rating: 4.8, color: const Color(0xFFEF5350)),
  ]),

  // 13. تذكارات وهدايا
  _ShopCategory(name: 'تذكارات وهدايا', emoji: '🎁', color: const Color(0xFF7E57C2), products: [
    _Product(name: 'صندوق ذكريات الحمل', emoji: '📦', price: '3,500 د.ج', oldPrice: '4,500 د.ج', rating: 4.9, color: const Color(0xFF7E57C2)),
    _Product(name: 'قالب بصمة يد ورجل', emoji: '🐾', price: '2,000 د.ج', rating: 4.8, color: const Color(0xFFBCAAA4)),
    _Product(name: 'إطار صورة أول سونار', emoji: '🖼️', price: '1,200 د.ج', rating: 4.6, color: const Color(0xFF8D6E63)),
    _Product(name: 'سلسلة مفاتيح بصمة', emoji: '🔑', price: '800 د.ج', rating: 4.5, color: const Color(0xFFE0E0E0)),
    _Product(name: 'لوحة اسم المولود خشبية', emoji: '🪵', price: '1,500 د.ج', rating: 4.7, color: const Color(0xFF8D6E63)),
    _Product(name: 'قلادة أمي الذهبية', emoji: '📿', price: '4,000 د.ج', rating: 4.8, color: const Color(0xFFFFB300)),
    _Product(name: 'كوب حامل مميز', emoji: '☕', price: '700 د.ج', rating: 4.4, color: const Color(0xFFEC407A)),
    _Product(name: 'تيشيرت أنا حامل', emoji: '👕', price: '1,200 د.ج', rating: 4.3, color: const Color(0xFFE91E63)),
    _Product(name: 'بطاقات مراحل الحمل', emoji: '🃏', price: '900 د.ج', rating: 4.6, color: const Color(0xFF42A5F5)),
    _Product(name: 'صندوق شعر أول قصة', emoji: '💇', price: '600 د.ج', rating: 4.5, color: const Color(0xFFBCAAA4)),
    _Product(name: 'كتاب ضيوف حفل المولود', emoji: '📖', price: '1,800 د.ج', rating: 4.7, color: const Color(0xFF66BB6A)),
    _Product(name: 'سوار أم وطفل مطابق', emoji: '📿', price: '1,500 د.ج', rating: 4.6, color: const Color(0xFFEC407A)),
    _Product(name: 'لوحة عد تنازلي للولادة', emoji: '📅', price: '1,000 د.ج', rating: 4.4, color: const Color(0xFF5C6BC0)),
    _Product(name: 'بالونات إعلان الجنس', emoji: '🎈', price: '1,200 د.ج', rating: 4.7, color: const Color(0xFFFF7043)),
    _Product(name: 'كيك توبر بيبي شاور', emoji: '🎂', price: '500 د.ج', rating: 4.5, color: const Color(0xFFFFB300)),
    _Product(name: 'زينة حفل استقبال مولود', emoji: '🎊', price: '2,500 د.ج', rating: 4.6, color: const Color(0xFF26A69A)),
    _Product(name: 'إطار صور 12 شهر', emoji: '🖼️', price: '2,000 د.ج', rating: 4.7, color: const Color(0xFF42A5F5)),
    _Product(name: 'وسادة تاريخ الميلاد', emoji: '🛋️', price: '1,500 د.ج', rating: 4.5, color: const Color(0xFF78909C)),
    _Product(name: 'شمعة معطرة للأم', emoji: '🕯️', price: '900 د.ج', rating: 4.6, color: const Color(0xFFAB47BC)),
    _Product(name: 'طقم هدايا أم جديدة', emoji: '🎁', price: '7,000 د.ج', oldPrice: '9,000 د.ج', rating: 4.9, color: const Color(0xFF7E57C2)),
  ]),

  // 14. سفر وتنقل
  _ShopCategory(name: 'سفر وتنقل', emoji: '✈️', color: const Color(0xFF29B6F6), products: [
    _Product(name: 'حقيبة ظهر حفاضات أنيقة', emoji: '🎒', price: '4,500 د.ج', oldPrice: '5,500 د.ج', rating: 4.8, color: const Color(0xFF424242)),
    _Product(name: 'سرير سفر قابل للطي', emoji: '🛏️', price: '7,500 د.ج', rating: 4.7, color: const Color(0xFF42A5F5)),
    _Product(name: 'كرسي سيارة محمول', emoji: '🚗', price: '9,000 د.ج', rating: 4.8, color: const Color(0xFF424242)),
    _Product(name: 'عربة سفر خفيفة', emoji: '🚼', price: '10,000 د.ج', oldPrice: '13,000 د.ج', rating: 4.9, color: const Color(0xFF78909C)),
    _Product(name: 'حقيبة تبريد حليب', emoji: '❄️', price: '1,800 د.ج', rating: 4.6, color: const Color(0xFF29B6F6)),
    _Product(name: 'واقي شمس عربة', emoji: '☀️', price: '800 د.ج', rating: 4.4, color: const Color(0xFFFFB300)),
    _Product(name: 'ستارة سيارة للأطفال', emoji: '🚙', price: '600 د.ج', rating: 4.3, color: const Color(0xFF424242)),
    _Product(name: 'حامل زجاجة للعربة', emoji: '🍼', price: '400 د.ج', rating: 4.2, color: const Color(0xFF78909C)),
    _Product(name: 'مرآة مراقبة الطفل للسيارة', emoji: '🪞', price: '1,200 د.ج', rating: 4.6, color: const Color(0xFF424242)),
    _Product(name: 'حقيبة تنظيم عربة', emoji: '👜', price: '1,000 د.ج', rating: 4.5, color: const Color(0xFF8D6E63)),
    _Product(name: 'غطاء مطر للعربة', emoji: '🌧️', price: '700 د.ج', rating: 4.4, color: const Color(0xFFE0E0E0)),
    _Product(name: 'حقيبة يد أم متعددة', emoji: '👜', price: '3,200 د.ج', rating: 4.7, color: const Color(0xFFEC407A)),
    _Product(name: 'ملاءة سرير سفر', emoji: '🛏️', price: '900 د.ج', rating: 4.3, color: const Color(0xFFE0E0E0)),
    _Product(name: 'وسادة رقبة للسفر', emoji: '🛫', price: '1,200 د.ج', rating: 4.5, color: const Color(0xFF5C6BC0)),
    _Product(name: 'مجموعة أدوات سفر مصغرة', emoji: '🧳', price: '1,500 د.ج', rating: 4.6, color: const Color(0xFF26A69A)),
    _Product(name: 'حامل لاب توب متنقل', emoji: '💻', price: '2,000 د.ج', rating: 4.4, color: const Color(0xFF78909C)),
    _Product(name: 'شاحن USB للسيارة', emoji: '🔌', price: '500 د.ج', rating: 4.3, color: const Color(0xFF424242)),
    _Product(name: 'حقيبة أحذية سفر', emoji: '👟', price: '600 د.ج', rating: 4.2, color: const Color(0xFF8D6E63)),
    _Product(name: 'بطانية سفر خفيفة', emoji: '🧣', price: '1,400 د.ج', rating: 4.5, color: const Color(0xFF7E57C2)),
    _Product(name: 'طقم سفر كامل للأم والطفل', emoji: '✈️', price: '12,000 د.ج', oldPrice: '15,000 د.ج', rating: 4.9, color: const Color(0xFF29B6F6)),
  ]),

  // 15. ديكور غرفة الطفل
  _ShopCategory(name: 'ديكور غرفة الطفل', emoji: '🏠', color: const Color(0xFF8D6E63), products: [
    _Product(name: 'ملصقات حائط حيوانات', emoji: '🦁', price: '1,500 د.ج', rating: 4.7, color: const Color(0xFF66BB6A)),
    _Product(name: 'سلة تخزين قماشية', emoji: '🧺', price: '1,200 د.ج', rating: 4.5, color: const Color(0xFFBCAAA4)),
    _Product(name: 'ستائر غرفة أطفال', emoji: '🪟', price: '3,500 د.ج', rating: 4.6, color: const Color(0xFF42A5F5)),
    _Product(name: 'سجادة أرضية ناعمة', emoji: '🧶', price: '4,000 د.ج', oldPrice: '5,000 د.ج', rating: 4.8, color: const Color(0xFFEC407A)),
    _Product(name: 'رف كتب خشبي للأطفال', emoji: '📚', price: '3,000 د.ج', rating: 4.7, color: const Color(0xFF8D6E63)),
    _Product(name: 'مصباح أرنب ليلي', emoji: '🐰', price: '1,800 د.ج', rating: 4.8, color: const Color(0xFFFFB300)),
    _Product(name: 'حروف اسم خشبية', emoji: '🔤', price: '2,500 د.ج', rating: 4.6, color: const Color(0xFF7E57C2)),
    _Product(name: 'ساعة حائط أطفال', emoji: '🕐', price: '1,500 د.ج', rating: 4.4, color: const Color(0xFF29B6F6)),
    _Product(name: 'لوحة قماش بالاسم', emoji: '🎨', price: '2,000 د.ج', rating: 4.7, color: const Color(0xFFEC407A)),
    _Product(name: 'علاقة ملابس أطفال 10 قطع', emoji: '🪝', price: '600 د.ج', rating: 4.3, color: const Color(0xFFE0E0E0)),
    _Product(name: 'صندوق تخزين ألعاب كبير', emoji: '📦', price: '2,800 د.ج', rating: 4.6, color: const Color(0xFF66BB6A)),
    _Product(name: 'بساط لعب فوم 9 قطع', emoji: '🧩', price: '3,200 د.ج', rating: 4.7, color: const Color(0xFFFF7043)),
    _Product(name: 'خيمة أطفال داخلية', emoji: '⛺', price: '4,500 د.ج', rating: 4.8, color: const Color(0xFFE91E63)),
    _Product(name: 'إطار صور حائط 6 قطع', emoji: '🖼️', price: '2,200 د.ج', rating: 4.5, color: const Color(0xFF424242)),
    _Product(name: 'سلة غسيل أطفال', emoji: '🧺', price: '900 د.ج', rating: 4.3, color: const Color(0xFF78909C)),
    _Product(name: 'نجوم مضيئة لاصقة', emoji: '⭐', price: '500 د.ج', rating: 4.6, color: const Color(0xFFFFB300)),
    _Product(name: 'مرآة حائط شكل غيمة', emoji: '☁️', price: '1,800 د.ج', rating: 4.5, color: const Color(0xFF29B6F6)),
    _Product(name: 'وسائد زينة أطفال', emoji: '🛋️', price: '1,200 د.ج', rating: 4.4, color: const Color(0xFFAB47BC)),
    _Product(name: 'جيرلاند خشبية ملونة', emoji: '🎏', price: '800 د.ج', rating: 4.5, color: const Color(0xFFFF8F00)),
    _Product(name: 'طقم ديكور غرفة كامل', emoji: '🏠', price: '15,000 د.ج', oldPrice: '19,000 د.ج', rating: 4.9, color: const Color(0xFF8D6E63)),
  ]),
];

// ─── Shop Page Widget ───
class ShopPage extends StatelessWidget {
  const ShopPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bgColor,
        body: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              backgroundColor: _teal,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: const Text(
                  '🛍️ المتجر',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_teal, _teal.withOpacity(0.85)],
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 30),
                      child: Icon(Icons.store, size: 50, color: Colors.white.withOpacity(0.2)),
                    ),
                  ),
                ),
              ),
            ),

            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      Icon(Icons.search, color: _textSecondary.withOpacity(0.5), size: 22),
                      const SizedBox(width: 10),
                      Text('ابحثي عن منتج...', style: TextStyle(color: _textSecondary.withOpacity(0.5), fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),

            // Category icons row
            SliverToBoxAdapter(
              child: SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: _shopCategories.length,
                  itemBuilder: (context, i) {
                    final cat = _shopCategories[i];
                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => _CategoryProductsScreen(category: cat),
                      )),
                      child: Container(
                        width: 75,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: cat.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(child: Text(cat.emoji, style: const TextStyle(fontSize: 26))),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              cat.name,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _textPrimary),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // All category carousels
            ..._shopCategories.map((cat) {
              return SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 22,
                            decoration: BoxDecoration(color: cat.color, borderRadius: BorderRadius.circular(2)),
                          ),
                          const SizedBox(width: 8),
                          Text(cat.emoji, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              cat.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textPrimary),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => _CategoryProductsScreen(category: cat),
                            )),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('عرض الكل', style: TextStyle(color: _teal, fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_back_ios, size: 12, color: _teal),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Product carousel
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: cat.products.length > 8 ? 8 : cat.products.length,
                        itemBuilder: (context, i) {
                          final p = cat.products[i];
                          return GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => _ProductDetailScreen(product: p, categoryName: cat.name),
                            )),
                            child: Container(
                              width: 160,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: _cardColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Product image area
                                  Container(
                                    height: 110,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: p.color.withOpacity(0.08),
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(16),
                                        topLeft: Radius.circular(16),
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        Center(child: Text(p.emoji, style: const TextStyle(fontSize: 45))),
                                        if (p.oldPrice.isNotEmpty)
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: _pink,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text('تخفيض', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  // Product info
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.name,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textPrimary),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Text(p.price, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _teal)),
                                            if (p.oldPrice.isNotEmpty) ...[
                                              const SizedBox(width: 6),
                                              Text(p.oldPrice, style: TextStyle(fontSize: 10, color: _textSecondary, decoration: TextDecoration.lineThrough)),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.star, size: 13, color: Colors.amber[700]),
                                            const SizedBox(width: 2),
                                            Text('${p.rating}', style: TextStyle(fontSize: 11, color: _textSecondary)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }
}

// ─── Category Products Screen ───
class _CategoryProductsScreen extends StatelessWidget {
  final _ShopCategory category;
  const _CategoryProductsScreen({Key? key, required this.category}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bgColor,
        appBar: AppBar(
          title: Text('${category.emoji} ${category.name}', style: const TextStyle(fontWeight: FontWeight.bold, color: _textPrimary, fontSize: 18)),
          backgroundColor: Colors.white,
          foregroundColor: _teal,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: category.products.length,
          itemBuilder: (context, i) {
            final p = category.products[i];
            return GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => _ProductDetailScreen(product: p, categoryName: category.name),
              )),
              child: Container(
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: p.color.withOpacity(0.08),
                          borderRadius: const BorderRadius.only(topRight: Radius.circular(16), topLeft: Radius.circular(16)),
                        ),
                        child: Stack(
                          children: [
                            Center(child: Text(p.emoji, style: const TextStyle(fontSize: 45))),
                            if (p.oldPrice.isNotEmpty)
                              Positioned(
                                top: 8, right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(color: _pink, borderRadius: BorderRadius.circular(6)),
                                  child: const Text('تخفيض', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const Spacer(),
                            Text(p.price, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _teal)),
                            if (p.oldPrice.isNotEmpty) Text(p.oldPrice, style: TextStyle(fontSize: 10, color: _textSecondary, decoration: TextDecoration.lineThrough)),
                            Row(children: [
                              Icon(Icons.star, size: 13, color: Colors.amber[700]),
                              const SizedBox(width: 2),
                              Text('${p.rating}', style: TextStyle(fontSize: 11, color: _textSecondary)),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Product Detail Screen ───
class _ProductDetailScreen extends StatelessWidget {
  final _Product product;
  final String categoryName;
  const _ProductDetailScreen({Key? key, required this.product, required this.categoryName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bgColor,
        appBar: AppBar(
          title: Text(categoryName, style: const TextStyle(fontWeight: FontWeight.bold, color: _textPrimary)),
          backgroundColor: Colors.white,
          foregroundColor: _teal,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              Container(
                height: 280,
                width: double.infinity,
                color: product.color.withOpacity(0.08),
                child: Center(child: Text(product.emoji, style: const TextStyle(fontSize: 100))),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: product.color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(categoryName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: product.color)),
                    ),
                    const SizedBox(height: 12),
                    // Name
                    Text(product.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textPrimary)),
                    const SizedBox(height: 12),
                    // Rating
                    Row(
                      children: [
                        ...List.generate(5, (i) => Icon(
                          i < product.rating.floor() ? Icons.star : (i < product.rating ? Icons.star_half : Icons.star_border),
                          color: Colors.amber[700], size: 20,
                        )),
                        const SizedBox(width: 8),
                        Text('${product.rating}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Price
                    Row(
                      children: [
                        Text(product.price, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _teal)),
                        if (product.oldPrice.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Text(product.oldPrice, style: TextStyle(fontSize: 16, color: _textSecondary, decoration: TextDecoration.lineThrough)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: _pink, borderRadius: BorderRadius.circular(6)),
                            child: const Text('تخفيض', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Info cards
                    Row(
                      children: [
                        _infoTag(Icons.local_shipping, 'توصيل مجاني'),
                        const SizedBox(width: 8),
                        _infoTag(Icons.verified, 'منتج أصلي'),
                        const SizedBox(width: 8),
                        _infoTag(Icons.replay, 'إرجاع مجاني'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Add to cart button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('تمت إضافة "${product.name}" للسلة'),
                              backgroundColor: _teal,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        },
                        icon: const Icon(Icons.shopping_cart_outlined),
                        label: const Text('أضيفي للسلة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _teal,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Buy now button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.flash_on),
                        label: const Text('اشتري الآن', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _pink,
                          side: BorderSide(color: _pink.withOpacity(0.3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTag(IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
        ),
        child: Column(
          children: [
            Icon(icon, color: _teal, size: 20),
            const SizedBox(height: 4),
            Text(text, style: const TextStyle(fontSize: 10, color: _textSecondary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
