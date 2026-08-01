# nabda-import — خط أنابيب استيراد المنتجات

يجلب منتجات المتاجر (Shopify / FlexDZ / Firas / WooCommerce / مخصص)، يحوّلها إلى صيغة نبضة،
ويرفعها إلى Firestore، ثم ينقل الصور إلى Firebase Storage.

## المتطلبات
- Node.js 18 أو أحدث (fetch مدمج)
- مفتاح حساب خدمة Firebase (`serviceAccountKey.json`)

## الإعداد (مرة واحدة)
1. من Firebase Console → ⚙ Project Settings → **Service Accounts** → **Generate new private key**.
   ضَع الملف هنا باسم `serviceAccountKey.json` (مستثنى من git تلقائياً).
2. افتح `config.js` وعدّل:
   - `ownerUid` → UID مالك المتجر (نفس القيمة المستخدمة سابقاً في createdBy).
   - `stores[]` → ضع **رابط كل متجر** و `type` الصحيح:
     - `shopify` → متجر Shopify (يجلب عبر `/products.json`).
     - `generic` → FlexDZ / Firas / WooCommerce / مخصص (يجلب عبر WooCommerce API أو sitemap + JSON-LD).
   - `markup` → 0 لنفس السعر الأصلي (نموذج الوسيط)، أو مثلاً 0.10 لزيادة 10%.
3. ثبّت التبعيات:
   ```
   npm install
   ```

## التشغيل
```
npm run fetch     # 1) يجلب كل المتاجر → nabda-products.json  (راجع الملف)
npm run upload    # 2) يرفع إلى Firestore (يحدّث الموجود عبر slug، يضيف الجديد)
npm run images    # 3) ينقل الصور إلى Firebase Storage
```
أو الكل دفعة واحدة:
```
npm run all
```

## ملاحظة مهمة حول FlexDZ / Firas
هاتان المنصّتان قد تُصيّران المحتوى عبر JavaScript وتمنعان الجلب البسيط.
- الجالب العام يجرّب أولاً **WooCommerce Store API**، ثم **sitemap.xml + JSON-LD** (يعمل مع أغلب المنصات).
- إذا أعاد **0 منتج** لأحد المتجرين، فذلك يعني أن المنصة لا تكشف بياناتها عبر HTTP بسيط،
  وتحتاج جلباً عبر متصفح حقيقي. في هذه الحالة أخبرني بالرابط وسأجلبها عبر أداة المتصفح (Chrome)
  ثم أصدّرها إلى `nabda-products.json` لترفعها بـ `npm run upload`.

## كيف يتجنّب التكرار
- الرفع يطابق حسب `slug`؛ إعادة التشغيل تُحدّث المنتج بدل تكراره.
- الجلب يزيل التكرار داخل نفس المتجر حسب معرّف المصدر.

## مخطّط المنتج (Firestore `products`)
يطابق ما يقرأه التطبيق والموقع: `name, price, oldPrice, description, category, slug,
imageUrl, imageUrls, stock, costPrice, coverImage, rating, createdBy, createdAt` وغيرها.
الفئة تُستنتج تلقائياً من اسم/وصف المنتج (عربي/فرنسي/إنجليزي) ضمن فئات نبضة الرسمية.
