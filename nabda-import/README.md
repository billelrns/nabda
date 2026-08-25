# استيراد منتجات المتاجر إلى نبضة (Firestore)

هذا السكريبت يجلب **كل المنتجات** من:
1. **El Baraa** — `elbaraa.myshopify.com` (Shopify)
2. **Le coin des accessoires** — `lecoindesaccessoires.flexdz.store` (FlexDZ)
3. **Firas Jeux** — `firasjeux.com`

ثم يحوّلها لصيغة نبضة ويرفعها إلى مجموعة **`products`** في Firestore. السعر يبقى **كما في المتجر الأصلي**.

---

## الخطوات

### 1) ثبّت Node.js
حمّل من https://nodejs.org (نسخة 18 أو أحدث).

### 2) افتح موجّه الأوامر داخل مجلد `nabda-import` ثم:
```
npm install
```

### 3) معاينة بدون رفع (اختياري لكن مُوصى به أولاً)
```
node import.js --dry
```
سيُنشئ ملف `nabda-products.json` — افتحه وتأكد أن المنتجات صحيحة.

### 4) احصل على مفتاح Firebase
- Firebase Console → ⚙️ إعدادات المشروع → **حسابات الخدمة (Service accounts)**
- اضغط **Generate new private key** → يُنزّل ملف JSON
- أعد تسميته إلى **`serviceAccount.json`** وضعه داخل مجلد `nabda-import`
- ⚠️ لا تشارك هذا الملف مع أحد ولا ترفعه على الإنترنت — إنه مفتاح متجرك.

### 5) الرفع إلى نبضة
```
node import.js
```
سيرفع كل المنتجات إلى مجموعة `products` في Firestore. ستظهر مباشرة في تطبيق وموقع نبضة (إن كان العرض يقرأ من هذه المجموعة).

---

## ملاحظات

- **الفئة** تُخمَّن تلقائياً (الرضاعة والأم / الرضيع والبيبي / الأطفال الصغار / الحمل والعناية) — يمكنك تعديلها لاحقاً في Firestore.
- **الصور** تبقى صور المتجر الأصلي. الحقل `imagesRegenerated:false` يذكّرك بالمنتجات التي لم تُعِد إنشاء صورها بعد.
  - ⚠️ **حقوق النشر:** استخدام صور المتاجر مباشرة قد يكون مخالفاً. استخدم «استوديو التنسيق» لإعادة إنشاء صور المنتجات المهمة بهوية نبضة قبل النشر للجمهور.
- إعادة التشغيل آمنة: يستخدم `merge` مع مُعرّف ثابت (slug) فلا يُكرّر المنتجات.
- تعديل المتاجر: غيّر مصفوفة `STORES` في أعلى `import.js`.

## صيغة المنتج في Firestore (مطابِقة لمخطط تطبيق نبضة الفعلي)
تمّت مطابقة السكريبت على مستند منتج حقيقي في مجموعة `products`:
```json
{
  "name": "...", "shortName": "...", "category": "عناية بالحامل",
  "description": "...", "shortDescription": "...",
  "price": "2800", "oldPrice": "", "costPrice": "",
  "imageUrl": "https://...", "imageUrls": ["https://..."],
  "coverImage": "https://...", "descImages": [],
  "emoji": "🍼", "displayType": "card", "stock": 50, "weight": 0,
  "rating": 5, "reviews": [], "variants": [], "secondaryOptions": [],
  "offers": [{ "title": "قطعة واحدة", "quantity": 1, "pricePerPiece": 2800, "isDefault": true, "isBest": false, "freeShipping": false, "image": "" }],
  "settings": { "skipCart": true, "hideRelated": false, "...": "..." },
  "shipping": { "freeShippingPickupOnly": true, "...": "..." },
  "createdBy": "zG9jnOX9U3eXs2r3t5ENO8v2HH52",
  "createdAt": "<serverTimestamp>", "updatedAt": "<serverTimestamp>"
}
```

### نقاط مهمة
- **الصور روابط (URL) وليست ملفات** — التطبيق يعرض أي رابط، لذا يستخدم السكريبت روابط صور المتاجر مباشرة (لا حاجة لرفع ملفات). للمنتجات المهمة استبدل الروابط بصور نبضة المولّدة.
- **createdBy** مضبوط على UID مالك متجرك (من مستند موجود). غيّره في أعلى `import.js` إن لزم.
- **التصنيفات** تُطابق فئات متجرك: عناية بالحامل، ملابس الحمل، لوازم الرضيع، الرضاعة والتغذية، الحفاضات والنظافة، ملابس المولود، فيتامينات ومكملات، حقيبة الولادة.
- الحقول التي تبدأ بـ `_` (مثل `_sourceStore`) للتتبع فقط ولا يستعملها التطبيق.
