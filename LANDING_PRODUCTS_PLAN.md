# خطة منتجات نبضة المتقدّمة (صفحة منتج / صفحة هبوط COD) — لتنفيذ Antigravity

> **الموديل:** Claude Opus 4.6 — **المجلد:** `C:\nabda_app` — **عربي RTL، لا تترجم النصوص.**
> **القاعدة:** Firebase مصدر الحقيقة. كل الحقول الجديدة **اختيارية ومتوافقة مع المنتجات القديمة** (لا تكسر منتجًا موجودًا).
> **الهدف:** محاكاة لوحة منتجات منصّة Dukan: كل منتج إمّا «صفحة منتج عادية» أو «صفحة هبوط» بنموذج طلب مباشر (تخطّي السلة)، مع خيارات/ألوان، خيارات ثانوية (مقاسات)، عروض كمية، ومراجعات.

## المراجع في الكود الحالي
- محرّر المنتج: `lib/screens/admin/admin_panel_screen.dart` → `_AddProductScreen` (~السطر 1118) و`_AddProductScreenState` (~1126). نمط رفع الصور `_uploadImage` (~1188).
- شاشة المنتج للمستخدِمة + المتجر: `lib/screens/shop/shop_page.dart`.
- إنشاء الطلب: `lib/services/cart_service.dart` (~225) ونموذج `OrderModel`.
- حقول العنوان (ولاية/بلدية) للدول: `lib/services/country_currency_service.dart`.

---

## النموذج البياني الجديد لوثيقة `products` (أضِف الحقول، أبقِ القديمة)
```jsonc
{
  // الحالية: name, price, oldPrice, description, emoji, category, imageUrl, imageUrls[], descImages[], rating
  "shortName": "حذاء Adidas",
  "shortDescription": "جودة عالية",
  "weight": 1000,                 // غرام
  "costPrice": "",                // سعر التكلفة (للأدمن فقط، لا يظهر للمستخدِمة)
  "coverImage": "",               // صورة الغلاف الرئيسية (الأولوية على imageUrls[0])
  "displayType": "product",       // "product" | "landing"
  "stock": 0,                     // المخزون الكلي (إن لم تُستعمل خيارات)
  "settings": {
    "skipCart": false,            // طلب مباشر بلا سلة
    "allowBackorder": false,      // السماح بالطلب عند نفاد المخزون
    "hideRelated": false,         // إخفاء المنتجات ذات الصلة
    "strictOptions": false,       // الوضع الصارم: كل الخيارات مطلوبة
    "customThankYou": false,
    "thankYouText": ""
  },
  "shipping": {
    "freeShipping": false,
    "freeShippingPickupOnly": false,
    "customShipping": false,      "customShippingPrice": 0,
    "customShippingPickup": false,"customShippingPickupPrice": 0
  },
  "variants": [                   // الخيارات الرئيسية والألوان
    { "title": "أحمر", "colorHex": "FF0000", "image": "", "sku": "", "stock": 0, "enabled": true }
  ],
  "secondaryOptions": [           // الخيارات الثانوية (مثل المقاسات)
    { "title": "المقاس", "values": ["S","M","L"] }
  ],
  "offers": [                     // عروض الكمية
    { "title": "قطعة واحدة", "quantity": 1, "pricePerPiece": 1000, "freeShipping": false, "isBest": false, "isDefault": true, "image": "" }
  ],
  "reviews": [                    // مراجعات يدويّة (تُعرض كاجتماعي proof)
    { "name": "أمينة", "gender": "female", "rating": 5, "image": "", "text": "منتج رائع" }
  ]
}
```
> **خارج النطاق:** تكامل Google Sheets (الطلبات تذهب إلى Firestore + لوحة الأدمن وهي أفضل). و«Pro Stock» نكتفي منه بمخزون لكل variant.

---

## المرحلة 1 — محرّر المنتج في لوحة الأدمن (`_AddProductScreen`)
أعِد تنظيم الشاشة إلى أقسام قابلة للطيّ (ExpansionTile أو عناوين)، تطابق صور Dukan:

1. **معلومات المنتج:** name، shortName، shortDescription، weight.
2. **وصف المنتج:** الوصف الحالي + صور الوصف (موجودة).
3. **تسعيرات المنتج:** price، oldPrice (سعر قديم)، costPrice (سعر التكلفة).
4. **صور المنتج:** coverImage (صورة الغلاف) + معرض `imageUrls` (موجود). نوصِ بأبعاد 800×800، أقصى 5MB.
5. **الإعدادات العامة:** مفاتيح (Switch) لكل حقول `settings` أعلاه + **مبدّل نوع العرض** (`displayType`: صفحة منتج / صفحة هبوط).
6. **الشحن:** مفاتيح + حقول أسعار حقول `shipping` أعلاه.
7. **الخيارات الرئيسية والألوان:** محرّر قائمة `variants` — لكل عنصر: الاسم، منتقي لون (colorHex)، صورة، SKU، المخزون، تفعيل/تعطيل، حذف. زرّ «إضافة خيار/لون».
8. **الخيارات الثانوية:** محرّر `secondaryOptions` — لكل مجموعة عنوان + قائمة قيم (مقاسات). زرّ «إضافة خيار».
9. **العروض (الكمية):** محرّر `offers` — لكل عرض: العنوان، الكمية، السعر للقطعة، شحن مجاني؟، أفضل عرض؟، العرض الافتراضي؟، صورة. زرّ «إضافة عرض».
10. **المراجعات:** محرّر `reviews` — لكل مراجعة: الاسم، الجنس، التقييم/5، صورة، النص.

**الحفظ:** وسّع خريطة `data` في `_save()` (~السطر 1257) لتشمل كل الحقول الجديدة (مع رفع صور الغلاف/الخيارات/العروض عبر `_uploadImage`). حافظ على `imageUrl`/`imageUrls` للتوافق.

**التحقّق:** `flutter analyze lib/screens/admin/admin_panel_screen.dart` = 0 errors.

---

## المرحلة 2 — صفحة الهبوط للمستخدِمة + الطلب المباشر
أنشئ `lib/screens/shop/landing_product_screen.dart` (StatefulWidget يأخذ بيانات المنتج). يُفتح عندما `displayType == 'landing'`.

تخطيط صفحة الهبوط (تمرير رأسي واحد):
- **هيرو:** coverImage + معرض صور.
- العنوان، السعر (مع oldPrice مشطوب)، shortDescription.
- **اختيار الـ variant/اللون** (شرائح ملوّنة) + **الخيارات الثانوية** (مقاسات).
- **عروض الكمية:** بطاقات تُبرز «أفضل عرض» و«الافتراضي»، تحدّث السعر الإجمالي.
- **قسم المراجعات** (نجوم + اسم + صورة + نص).
- **نموذج الطلب المباشر (ثابت أسفل الشاشة):** الاسم، الهاتف، الولاية/البلدية (من `country_currency_service`), الكمية، ملخّص السعر + الشحن. زرّ **«اطلبي الآن»**.

**منطق الطلب (تخطّي السلة):** ابنِ خريطة طلب بنفس مخطّط `OrderModel` (customerName, phone, address, country, paymentMethod='cod', items=[عنصر واحد يحوي productId/name/price/variant/option/offerTitle/quantity], subtotal, shipping, totalAmount). احسب الشحن حسب `shipping` (مجاني/مخصّص/نقطة استلام) وحسب `offer.freeShipping`. اكتب إلى `orders` + `users/{uid}/orders/{id}` (نفس نمط `cart_service`). ثم اعرض **صفحة الشكر** (مخصّصة إن `customThankYou`).

**الوضع الصارم:** إن `settings.strictOptions` فكل الخيارات إلزامية قبل تفعيل زرّ الطلب.
**المخزون:** إن نفد و`allowBackorder=false` عطّل الطلب واعرض «نفد المخزون».

**التحقّق:** analyze نظيف + تجربة طلب فعلي يظهر في لوحة الأدمن (الطلبات).

---

## المرحلة 3 — تحسين صفحة المنتج العادية + ربط الطلب
- في `shop_page.dart`: عند `displayType == 'product'` اعرض صفحة المنتج العادية لكن مع دعم **الخيارات/الألوان والعروض والمراجعات** إن وُجدت، وأضِف الاختيار إلى عنصر السلة.
- وسّع عنصر الطلب (`items[]`) ليحمل `variant`/`option`/`offerTitle` حتى تظهر في تفاصيل الطلب بلوحة الأدمن (المرحلة 1 من خطة الويب لاحقًا).
- احترم `settings.hideRelated` لإخفاء المنتجات ذات الصلة.

---

## التحقّق والبناء والرفع (بعد كل مرحلة)
```bash
flutter analyze            # 0 errors
flutter build apk --release && copy build\app\outputs\flutter-apk\app-release.apk nabda.apk
git add -A
git commit -m "feat(shop): <وصف المرحلة>"
git push origin main
```

## اختبارات القبول
1. إنشاء منتج بنوع «صفحة هبوط» مع لونين، مقاسين، 3 عروض كمية، ومراجعتين → يُحفظ كاملًا في Firestore.
2. فتحه في التطبيق يعرض صفحة هبوط بنموذج طلب مباشر؛ الطلب يُنشئ وثيقة في `orders` ويظهر في لوحة الأدمن.
3. منتج بنوع «صفحة منتج» يعمل كالمعتاد عبر السلة، مع ظهور الخيارات/العروض إن وُجدت.
4. منتج قديم (بلا الحقول الجديدة) لا يتعطّل ويُعرض كصفحة منتج عادية.
5. قواعد الشحن (مجاني/مخصّص/نقطة استلام) تنعكس في إجمالي الطلب.

## قيود
- توافق رجعي صارم: الحقول الجديدة اختيارية، والمنتجات القديمة تُعامَل كـ `displayType='product'`.
- لا تكسر مسار السلة الحالي ولا مخطّط `OrderModel`؛ وسّعه فقط.
- أعِد استخدام `_uploadImage` ونمط الصور الحالي (bytes → putData).
- بعد كل مرحلة: analyze نظيف ثم بناء APK ونسخه إلى `nabda.apk` ورفع Git.
```
