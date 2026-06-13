# خطة لوحة تحكم الويب لنبضة (NABDA.ONLINE) — لتنفيذ Antigravity

> **الموديل المقترح:** Claude Opus 4.6 — **المجلد:** `C:\nabda_app`
> **اللغة:** عربي RTL — لا تترجم أي نص عربي موجود.
> **القاعدة الذهبية:** Firebase هو مصدر الحقيقة الوحيد. لا تنشئ قاعدة بيانات أخرى ولا جسر مزامنة.

## القرار المعماري (مُعتمَد)
- **Firebase يبقى مصدر الحقيقة.** لوحة التحكم = **تجميع لوحة الأدمن Flutter الحالية إلى Flutter Web** وتشغيلها في المتصفّح. نفس الكود، نفس قاعدة البيانات.
- **التوزيع:** `admin.nabda.online` (نطاق فرعي) → Firebase Hosting للوحة التحكم. الجذر `nabda.online` يبقى WordPress/Bimber (مدوّنة عامة + SEO).
- **المرحلة الأولى = المتجر فقط (منتجات + طلبات).** باقي الأقسام (مقالات/مستخدمون/مجتمع) موجودة في الكود أصلًا وتظهر تلقائيًا في الويب، لكن التحسين في هذه المرحلة يركّز على المتجر.

---

## المرحلة 0 — أساس الويب (إعداد لمرّة واحدة)

1. **تأكّد من تفعيل الويب:**
   ```bash
   cd C:\nabda_app
   flutter config --enable-web
   flutter devices   # يجب أن يظهر Chrome / Web Server
   ```
   مجلد `web/` موجود مسبقًا.

2. **تحقّق من إعداد Firebase للويب:** افتح `lib/firebase_options.dart` وتأكّد أن `currentPlatform` يُعيد `web` عند `kIsWeb` (أضِف `if (kIsWeb) return web;` في أول `currentPlatform` إن لم يكن موجودًا). وتأكّد أن تطبيق ويب مُسجَّل في مشروع Firebase (Console → Project settings → Your apps → Web). إن لم يكن، شغّل `flutterfire configure` وأضِف منصّة Web.

3. **أنشئ نقطة دخول ويب للأدمن فقط:** ملف جديد `lib/main_web.dart` يُهيّئ Firebase ثم يفتح **مباشرة** شاشة دخول الطاقم (Staff login) ثم `AdminPanelScreen` — يتجاوز تطبيق المستخدِمة. أعد استخدام نفس تهيئة Firebase الموجودة في `lib/main.dart`. مثال الهيكل:
   ```dart
   import 'package:flutter/material.dart';
   import 'package:firebase_core/firebase_core.dart';
   import 'firebase_options.dart';
   // استورد شاشة دخول الطاقم/الأدمن الموجودة
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
     runApp(const NabdaAdminWebApp()); // MaterialApp(home: <شاشة دخول الطاقم>) مع RTL ودعم العربية
   }
   ```
   ابحث عن شاشة تسجيل دخول الطاقم الحالية (staff login) في الكود واستعملها كـ home؛ إن لم توجد، اعرض `AdminPanelScreen` خلف حارس `FirebaseAuth` + تحقّق من وثيقة `staff/{uid}.isActive`.

4. **ابنِ نسخة الويب:**
   ```bash
   flutter build web --release -t lib/main_web.dart
   ```
   الناتج في `build/web`.

5. **Firebase Hosting:**
   ```bash
   firebase init hosting     # public = build/web ، SPA: نعم (rewrite الكل إلى /index.html)
   firebase deploy --only hosting
   ```

6. **ربط النطاق الفرعي:** في Firebase Console → Hosting → Add custom domain → `admin.nabda.online`، وأضِف سجلّات DNS المطلوبة في إعدادات نطاق nabda.online. أبقِ الجذر nabda.online على WordPress. ثم في Firebase Auth → Settings → Authorized domains أضِف `admin.nabda.online`.

7. **الأمان (حرج):** قواعد `firestore.rules` تحمي الكتابة بـ `isActiveStaff` بالفعل — لا تُضعِفها. تأكّد أن الويب لا يعرض أي شاشة إدارة قبل تسجيل دخول طاقم نشط.

---

## المرحلة 1 — تحسين لوحة المتجر (منتجات + طلبات)

> الملفات المرجعية في `lib/screens/admin/admin_panel_screen.dart`:
> - `_OrdersManagementScreen` (~السطر 415)
> - `_ProductsManagementScreen` (~508) + `_AddProductScreen` (~1118)
> - `_DashboardScreen` (~289)
> المجموعات: `orders`, `products`, `dynamic_products`, `coupons`, `delivery_pricing`.

### 1-أ: قشرة متجاوبة للويب (Responsive shell) — مهم
لوحة مصمَّمة للهاتف تبدو ضيّقة في المتصفّح. أضِف `LayoutBuilder` بنقطة فصل (مثلاً `> 900px`):
- شاشة عريضة: **شريط جانبي (NavigationRail/Drawer ثابت)** يمين الشاشة بدل التنقّل السفلي، ومحتوى بعرض أقصى ~1200px موسَّط.
- شاشة ضيّقة: السلوك الحالي للهاتف.
أنشئ ودجت `AdminShell` تغلّف الأقسام وتبدّل بين الشكلين.

### 1-ب: إدارة الطلبات (`_OrdersManagementScreen`)
- **فلترة بالحالة:** قيد الانتظار/مؤكّد/قيد الشحن/تم التسليم/ملغى (شرائح Chips أعلى القائمة).
- **بحث** باسم العميلة أو رقم الهاتف.
- **شاشة تفاصيل الطلب:** المنتجات والكميات، المجموع، عنوان التوصيل، الكوبون المطبَّق، رسوم التوصيل، بيانات العميلة.
- **تحديث الحالة بنقرة** مع تسجيل وقت كل تغيير (timeline)، وكتابة الحقل في `orders/{id}.status` + `statusHistory`.
- عدّاد لكل حالة في الأعلى. (الكتابة مسموحة للطاقم عبر قاعدة orders update الحالية.)

### 1-ج: إدارة المنتجات (`_ProductsManagementScreen` / `_AddProductScreen`)
- **بحث + فلترة بالتصنيف** في تبويب «منتجات المتجر».
- **إدارة المخزون:** حقل `stock`، وشارة «مخزون منخفض» عند `stock <= 5`، وخيار «نفد المخزون».
- **تبديل ظهور المنتج** (`isActive`/`hidden`) بسرعة دون حذف.
- **السعر والخصم:** `price`, `oldPrice`/`discountPercent` مع عرض السعر النهائي.
- صور متعدّدة (موجودة) — تأكّد من عملها على الويب (رفع عبر bytes كما في النمط الحالي `putData`).
- فرز (الأحدث/السعر/الأكثر مبيعًا إن توفّر).

### 1-د: لوحة معلومات المتجر (`_DashboardScreen`)
- بطاقات: مبيعات اليوم، الطلبات قيد الانتظار، إجمالي الإيراد، عدد المنتجات، تنبيه المخزون المنخفض.
- قائمة آخر 10 طلبات (موجودة) — اجعلها قابلة للنقر تفتح تفاصيل الطلب.
- (اختياري) رسم بياني بسيط للمبيعات آخر 7 أيام عبر `fl_chart`.

### 1-هـ: الكوبونات ورسوم التوصيل
- شاشتا إدارة بسيطتان لـ `coupons` (كود/نسبة/تاريخ انتهاء/تفعيل) و`delivery_pricing` (المنطقة/السعر). CRUD كامل (القواعد تسمح للطاقم/المشرف).

### التحقّق والرفع (إلزامي بعد كل مرحلة)
```bash
flutter analyze            # يجب 0 errors
flutter build web --release -t lib/main_web.dart
firebase deploy --only hosting
git add -A
git commit -m "feat(web): <وصف ما أُنجز>"
git push origin main
```

---

## المراحل اللاحقة (للعلم فقط — لا تنفّذها الآن)
- **المرحلة 2:** تحسين إدارة المقالات (عامة + متخصّصة) للويب.
- **المرحلة 3:** المستخدمون والبروفايلات (موجودة كـ `_UsersManagementScreen`/`_UserProfileAdminScreen`).
- **المرحلة 4:** إشراف المجتمع (`community_posts`): حذف/إخفاء/حظر.
- **المرحلة 5:** إحصاءات متقدّمة.
- **المرحلة 6 (اختياري):** مزامنة أحادية الاتجاه للمقالات المنشورة من Firestore إلى Bimber/WordPress عبر REST API لأغراض SEO فقط (Firestore يبقى المصدر).

## قيود صارمة
- لا تُنشئ قاعدة بيانات ثانية ولا تكتب منطق مزامنة ثنائية.
- لا تُضعِف `firestore.rules`؛ كل كتابة إدارية تمرّ بـ `isActiveStaff`.
- أعِد استخدام الشاشات والخدمات الموجودة قدر الإمكان بدل إعادة الكتابة.
- بعد كل مرحلة: `flutter analyze` نظيف ثم بناء ونشر ورفع Git.
