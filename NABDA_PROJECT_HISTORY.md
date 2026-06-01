# تاريخ تطوير تطبيق نبضة (Nabda App) - الملخص الشامل
## جميع جلسات العمل - مايو 2026

---

## معلومات المشروع الأساسية

| العنصر | القيمة |
|--------|--------|
| **المستودع** | https://github.com/billelrns/nabda.git |
| **التقنية** | Flutter + Firebase (Firestore + Auth + Storage) |
| **اللغة** | العربية (RTL) - مع دعم إنجليزي وفرنسي |
| **الثيم** | Material 3 - تيل `#00897B` + وردي `#E91E63` + خط Almarai |
| **Firebase** | nabda-app-ca864 |
| **الحالة** | تطبيق متكامل جاهز للنشر |

---

## الهيكل المعماري

```
lib/
├── main.dart              # نقطة الدخول + ترجمات + LoginPage + ProfilePage (~2800 سطر)
├── firebase_options.dart  # إعدادات Firebase
├── config/                # Theme (Material 3) + GoRouter (17 مسار)
├── models/                # نماذج البيانات (user, cycle, pregnancy, baby, community, doctor)
├── services/              # Firebase + APIs (auth, firestore, notifications, AI, admin, community)
├── blocs/                 # BLoC (auth + cycle فقط)
├── screens/               # شاشات مقسمة بالميزات
│   ├── admin/             # لوحة التحكم (10 وحدات، 4040 سطر)
│   ├── ai_chat/           # مساعد ذكي (Gemini API)
│   ├── community/         # المجتمع (منشورات، تعليقات، ترتيب، بروفايل)
│   ├── pregnancy/         # الحمل (أسابيع، إنجازات، مشاركة، تمارين، تغذية)
│   └── shop/              # المتجر (300+ منتج، سلة، checkout)
├── widgets/               # مكونات قابلة لإعادة الاستخدام
├── utils/                 # ثوابت ومساعدات
└── l10n/                  # ملفات ARB
```

---

## المراحل الرئيسية للتطوير

---

### المرحلة 1: البنية الأساسية والحمل

#### 1. إعادة تصميم شاشة الحمل (WeekDetailScreen)
- ثيم فاتح أنثوي عصري
- معلومات مفصلة لكل أسبوع (1-41) عن الجنين والأم
- مقارنة حجم الجنين بالفواكه

#### 2. صور الجنين الحقيقية لكل أسبوع
- **المصدر:** `OneDrive\Image pour claude\week by week`
- 38 صورة ثلاثية الأبعاد (PNG + JPG) للأسابيع 4-41
- دالة `_fetusImagePath()` مع fallback لأقرب أسبوع
- مجلد `assets/images/fetus/` مسجل في pubspec.yaml

#### 3. المهام الطبية المفصلة
- مهام مقسمة حسب الثلث (الأول، الثاني، الثالث)
- قوائم فحوصات وتحاليل لكل مرحلة

#### 4. مقالات صحية متنوعة
- أقسام: تغذية، رياضة، صحة نفسية، نوم، جمال
- كاروسيل أفقي + صفحة اكتشاف بأقسام متعددة
- كل مقال 300+ كلمة

#### 5. شاشات إضافية للحمل
- **العد التنازلي** (`due_date_countdown_screen.dart`): الأيام المتبقية مع رسوم متحركة
- **التغذية** (`nutrition_screen.dart`): نصائح حسب الثلث + أطعمة موصى بها/محظورة
- **التمارين** (`exercises_screen.dart`): تمارين آمنة مصنفة مع تحذيرات
- **تقويم الحمل**: عرض تفاعلي لـ 40 أسبوع
- **يوميات الحمل**: تسجيل مشاعر وذكريات + صور
- **حقيبة الولادة**: قائمة شاملة (للأم، للمولود، مستندات)

---

### المرحلة 2: المتجر ونظام الطلبات

#### 6. صفحة المتجر (`shop_page.dart`)
- **15 قسم × 20+ منتج = 300+ منتج**
- الأقسام: ملابس حمل، لوازم رضيع، ملابس مولود، رضاعة وتغذية، حفاضات ونظافة، عناية بالحامل، فيتامينات، حقيبة ولادة، ألعاب، راحة الأم، كتب، أجهزة طبية، تذكارات، سفر، ديكور
- SliverAppBar مع تدرج + بحث + أيقونات أفقية
- صفحة تفاصيل المنتج مع PageView.builder slider + تقييم

#### 7. نظام البلدان والعملات (`country_currency_service.dart`)
- **22 دولة عربية + فرنسا** مع كشف تلقائي عبر IP
- تحويل عملات عبر Exchange Rate API + كاش 6 ساعات + أسعار احتياطية
- نماذج عنوان مخصصة: الجزائر (ولاية+بلدية)، مصر (محافظة+علامة)، السعودية (حي+مبنى)
- طرق دفع خاصة: الجزائر (COD، ذهبية، CCP، بريدي موب)، السعودية (مدى، STC Pay)، مصر (فودافون كاش، فوري)

#### 8. سلة المشتريات و Checkout
- `cart_service.dart` + `cart_screen.dart`
- صفحة Checkout ديناميكية حسب البلد
- إرسال الطلبات إلى Firestore

---

### المرحلة 3: لوحة التحكم والإدارة

#### 9. نظام الأدوار والصلاحيات (`admin_service.dart`)
- 4 أدوار: مالك (owner)، مشرف (supervisor)، موظف (employee)، مستخدم (user)
- 18 صلاحية مختلفة
- Singleton + ChangeNotifier + Firestore serialization

#### 10. لوحة تحكم المشرف (`admin_panel_screen.dart` - 4040 سطر)
- **10 وحدات إدارية:**
  1. 📊 لوحة الإحصائيات (مستخدمات، طلبات، إيرادات)
  2. 📦 إدارة الطلبات (5 حالات + إشعارات)
  3. 🛍️ إدارة المنتجات (إضافة/تعديل/حذف + 15 قسم + صور متعددة)
  4. 📝 إدارة المقالات (نشر/تعديل/حذف + 8 أقسام + رفع صور)
  5. 🆕 المحتوى الجديد (مقالات ومنتجات Firestore ديناميكية)
  6. 👥 إدارة المستخدمات (بروفايل + نشاط + حظر + ترقية أدوار)
  7. 🎟️ الكوبونات والعروض (إنشاء/تفعيل/حذف)
  8. 👔 إدارة الموظفين (ترقية/تخفيض/تعطيل - المالك فقط)
  9. 🚚 أسعار التوصيل (16 دولة مع تفعيل/تعطيل)
  10. 💬 تنشيط المجتمع (سؤال اليوم، نصائح، ترحيب، ترويج)

#### 11. نظام المحتوى الهجين (Hybrid Content)
- مقالات مدمجة في الكود + مقالات جديدة من Firestore
- Collection `dynamic_articles` + `dynamic_products`
- المقالات الجديدة تظهر أولاً ثم المدمجة
- شاشة إدارة خاصة للمحتوى الديناميكي

---

### المرحلة 4: المجتمع والتفاعل

#### 12. نظام المجتمع الأساسي
- `community_screen.dart`: فلترة بالفئات (حمل، طفل، دورة، عام)
- `create_post_screen.dart`: إنشاء منشور مع صورة
- `post_detail_screen.dart`: عرض المنشور + تعليقات + إعجابات
- نظام النقاط: نشر +3، تعليق +2، إعجاب +1

#### 13. نظام Leaderboard + بروفايل
- `leaderboard_screen.dart` (~310 سطر): منصة ثلاث أوائل (ذهب/فضة/برونز)
- ترتيب حسب: النقاط / المنشورات / الإعجابات / التعليقات
- تبويبات: الكل / الجدد (آخر 30 يوم)
- `user_profile_screen.dart` (~350 سطر): متابعة / حظر / إبلاغ
- Leaderboard مدمج كتبويب داخل شاشة المجتمع

#### 14. نظام تنشيط المجتمع (`community_engagement_service.dart`)
- **حساب "فريق نبضة" الرسمي** (userId: `nabda_team_official`)
- شارة تحقق ✓ + تصميم مميز (تدرج أخضر + قلب + إطار)
- **20 موضوع نقاش** مقسمة: حمل (6)، دورة (4)، طفل (5)، عام (5)
- **6 نصائح صحية** طبية مفيدة
- **3 منشورات ترويجية** لمنتجات نبضة
- **5 رسائل ترحيب** للأعضاء الجدد (أول منشور)
- نظام تجنب التكرار (يتحقق من آخر 10 منشورات)
- **نظام الشارات التلقائي:**
  - نشطة (20 نقطة)
  - مفيدة (50 نقطة)
  - خبيرة (100 نقطة)
  - أفضل مساهمة (200 نقطة)
- **لوحة تحكم تنشيط المجتمع** في الأدمن:
  - إحصائيات (منشورات/إعجابات/تعليقات)
  - أزرار سريعة (سؤال اليوم، نصيحة، ترويج، ترحيب)
  - نشر حسب الفئة
  - نموذج منشور مخصص

---

### المرحلة 5: التصميم والواجهات

#### 15. تصميم Claude Design Premium
- خلفية دافئة `#FFF8FB`
- ظلال بتدرج وردي
- أزرار بشكل حبة (pill) بنصف قطر 999
- بطاقات بزوايا 20-24px
- تدرج لوني للهيدر (وردي→أبيض→تيل)
- ألوان نص أدفأ (`#1F1A20` و `#4A434B`)
- الوضع الداكن: خلفية `#18121A` (warm dark)

#### 16. إعادة تصميم الصفحة الرئيسية
- Floating glassmorphic TopBar مع gradient logo
- Hero section مع صورة حمل وchips ترحيبية
- Pregnancy Tracker ring مع baby emoji متحرك
- Quick Access grid (4 بطاقات: حمل، دورة، وزن، عد تنازلي)
- AI Assistant card بتدرج داكن وorb متوهج
- Daily Tips أفقي مع progress bars
- Explore grid (6 أدوات) + Chip row (8 أدوات سريعة)
- Shop banner مع تدرج وصور منتجات

#### 17. إعادة تصميم صفحة الدورة (CyclePage)
- تصميم Claude Design Premium كامل
- تقويم دورة تفاعلي مع ألوان مميزة

#### 18. إعادة تصميم صفحة الطفل (BabyPage)
- تصميم Claude Design Premium
- بطاقات insight قابلة للنقر مع BottomSheet تفصيلي

#### 19. إعادة تصميم صفحة تسجيل الدخول
- `_AuthBgPainter` CustomPainter مع دوائر عائمة وموجة
- 7 أنيميشن متتالية (logoScale، titleSlide، formFade، fields...)
- مقياس قوة كلمة المرور (5 مستويات)
- نسيت كلمة المرور (BottomSheet + Firebase reset)
- checkbox شروط الاستخدام مع AnimatedContainer

---

### المرحلة 6: الإنجازات واللعبة

#### 20. نظام الإنجازات والشارات (`achievements_screen.dart`)
- **4 فئات:** رعاية ذاتية، تغذية وصحة، متابعة حمل، مشاركة مجتمعية
- **24 إنجاز** بنقاط مختلفة (5-50 نقطة)
- **6 مستويات:** جديدة → مبتدئة → نشيطة → متقدمة → خبيرة → ملكة نبضة
- شارات ذهبية متدرجة + مسار مستويات أفقي + سهم متحرك
- كشف تلقائي من Firestore

#### 21. مشاركة تقدم الحمل (`share_progress_screen.dart`)
- 5 قوالب: بطاقة الأسبوع، عد تنازلي، حجم الطفل، إنجازات، تقدم كلي
- `_ProgressCirclePainter` CustomPainter + نص مشاركة عربي

---

### المرحلة 7: المقالات والمحتوى

#### 22. توسيع المقالات (300+ كلمة لكل مقال)
- 41 مقال أسبوعي للحمل (150+ كلمة لكل حقل)
- 36 مقال اكتشاف (300+ كلمة)
- 10 مقالات الصفحة الرئيسية (300+ كلمة)
- 8 مقالات حمل رئيسية (300+ كلمة)
- 30 مقال أخبار حمل جديدة
- 30 مقال طفل حسب العمر
- 15 مقال دورة شهرية
- 19 مقال إضافي للصفحة الرئيسية

#### 23. تحسين تصميم المقالات
- فقرات منفصلة بمسافات
- مكان إعلان وسط المقال
- صور Unsplash ذكية حسب الكلمات المفتاحية
- كاروسال منتجات أسفل كل مقال مرتبط بالموضوع
- استبدال الإيموجي بصور حقيقية في البطاقات

#### 24. نظام تعديل المقالات من الأدمن
- زر تعديل داخل المقال (يظهر للأدمن فقط)
- رفع صور من الجهاز (Firebase Storage)
- حفظ التعديلات في Firestore
- المقالات المعدلة تتجاوز المدمجة

---

### المرحلة 8: إصلاحات وتحسينات

#### 25. إصلاحات عامة
- تغيير الأرقام العربية-الهندية إلى غربية في كل التقويمات
- توسيع نطاق سنوات اختيار عمر الطفل إلى 2000
- تثبيت البار السفلي في أقسام الحمل والدورة والطفل
- إصلاح Scaffolds متداخلة
- إصلاح أزرار/أقسام لا تفتح عند الضغط
- إصلاح 0 أخطاء بعد flutter analyze

#### 26. إصلاحات تقنية
- إصلاح اقتطاع الملفات الكبيرة (main.dart، admin_panel)
- إصلاح Firebase Storage CORS
- إصلاح Git index corruption
- إصلاح نشر المقالات وعرض الصور

---

### المرحلة 9: دعم أطفال متعددين

#### 27. نظام أطفال متعددين
- شاشة اختيار طفل مع إمكانية إضافة أطفال جدد
- بروفايل لكل طفل (اسم، تاريخ ميلاد، صورة)
- ربط سجل اللقاحات بكل طفل على حدة (subcollection)
- تتبع نمو مخصص لكل طفل

---

### المرحلة 10: تنظيم الأصول

#### 28. تحليل وتسمية 82 صورة للمقالات
- تحليل جميع الصور في `OneDrive\Image pour claude\image for articles\`
- تقسيم إلى 6 مجلدات: maternity-photoshoot (19)، pregnancy (24)، baby (13)، newborn (10)، twins (6)، family (3)
- إنشاء كاتالوج Excel مع وصف عربي ومواضيع مقترحة لكل صورة
- حذف 2 مكررة + 5 تالفة

---

### المرحلة 11: تتبع الأدوية والإشعارات المجدولة (1 يونيو 2026)

#### 29. إصلاح حفظ الأدوية وخانة "لمن هذا الدواء"
- **المشكلة:** فشل حفظ الأدوية على الويب بخطأ `FIRESTORE INTERNAL ASSERTION FAILED (ca9)`، وعدم ظهور بيانات المريض.
- **السبب 1 (Firestore على الويب):** تعارض IndexedDB عند فتح عدة تبويبات. **الحل:** `FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false)` في `main()` + استخدام تبويب واحد.
- **السبب 2 (خطأ برمجي):** `setState(() => _medsFuture = _service.getUserMedicationsFuture())` كان يُرجع Future داخل setState فيرمي استثناءً *بعد* نجاح الحفظ، فتظهر رسالة خطأ مضلّلة. **الحل:** تغليف الإسناد في جسم بأقواس `{ }`.
- النتيجة: الحفظ يعمل، وخانة "لمن هذا الدواء" تعرض الأم وكل الأطفال بشكل صحيح.

#### 30. إشعارات أدوية حقيقية مجدولة (تعمل والتطبيق مغلق)
- كل دواء محفوظ يُجدول إشعار نظام يومي متكرر في وقت التذكير، يُلغى عند الحذف، ويُعاد جدولة الأدوية القديمة عند فتح الشاشة.
- **ثلاثة عناصر كانت كلها ضرورية لإطلاق الإشعار على Samsung (Android 11):**
  1. تهيئة المنطقة الزمنية في `main()`: `tzdata.initializeTimeZones()` + `tz.setLocalLocation(tz.getLocation('Africa/Algiers'))`.
  2. `zonedSchedule` بوضع `AndroidScheduleMode.alarmClock` (الأوضاع `exact`/`inexact` لم تُطلق الإشعار على هذا الجهاز؛ `alarmClock` يُعامَل كمنبّه حقيقي ويتجاوز إدارة بطارية Samsung) مع `uiLocalNotificationDateInterpretation` و`matchDateTimeComponents: DateTimeComponents.time`.
  3. **السبب الخفي الحاسم:** إضافة مُستقبِلات الإضافة إلى `AndroidManifest.xml` (`ScheduledNotificationReceiver` و`ScheduledNotificationBootReceiver`). بدونها كانت الجدولة تنجح (pendingNotificationRequests يزيد) لكن لا شيء يُطلق — الإشعار الفوري `show()` يعمل، والمجدول لا يعمل.
- أُضيفت أذونات `SCHEDULE_EXACT_ALARM` + `USE_EXACT_ALARM` للمانيفست، وضُبط الهاتف: بطارية «بلا قيود» + «لا ينام أبداً» + «غير مُحسّن».

#### 31. أدوات وملفات متأثرة
- **الكود:** `lib/main.dart` (تهيئة tz + دوال `NotifService`: `scheduleMedDaily`، `cancelMedReminder`، `ensureMedSetup`، `showInstant`)، `lib/screens/health/medication_tracker_screen.dart` (ربط الجدولة بالحفظ/الحذف).
- **خارج الـ bat (تُعدّل يدوياً في `C:\nabda_app`):** `pubspec.yaml` (flutter_local_notifications، timezone) و`AndroidManifest.xml`.
- **ملاحظة:** الإشعارات تعمل على أندرويد فقط (لا الويب). لتشغيلها تم تثبيت Android Studio + Android SDK وربط هاتف Samsung A50 عبر USB.

---

### المرحلة 12: أوقات متعددة + منظومة إشعارات كاملة للتطبيق (1 يونيو 2026)

#### 32. تذكير الأدوية بأوقات متعددة
- كل دواء يقبل عدة أوقات تذكير (حتى 10) عبر واجهة «أوقات التذكير» (إضافة/تعديل/حذف)، وكل وقت يُجدول كإشعار مستقل بمعرّف فريد (`medSlotId = ('$medId#$i').hashCode`).
- الحذف يلغي كل الأوقات؛ البطاقة تعرض الأوقات مفصولة بنقاط؛ الأدوية القديمة (وقت واحد) تعمل دون تغيير عبر منطق `_effTimes` (يعتمد `times` إن تعددت، وإلا `reminderTime`).

#### 33. إشعارات مجدولة لكل التطبيق (فئة `AppNotifs` في main.dart)
- تُجدول مركزياً عند فتح التطبيق بعد تسجيل الدخول (من `AuthGate`)، وكلها بوضع `AndroidScheduleMode.alarmClock` الموثوق على Samsung.
- **شرب الماء:** مرتين يومياً (10:00 و18:00).
- **نصائح يومية:** 4 نصائح كل يومين الساعة 7م، تتدوّر من قائمة 14 نصيحة صحية.
- **متابعة الحمل/الدورة:** يقرأ وثيقة المستخدمة — حمل (`pregnancyStart`) → تذكير أسبوعي للأسابيع الأربعة القادمة؛ دورة (`lastPeriodStart`+`cycleLength`) → تذكير قبل يومين ويوم الدورة.
- **عروض المتجر:** مرتين يومياً (11:00 و19:00) من مجموعة Firestore `products` (اسم + سعر + دعوة للتسوّق)، مع رسالة عامة احتياطية إن لم توجد منتجات.

#### 34. لوحة تحكم الإشعارات (للأدمن)
- كُيّفت شاشة «الإشعارات الجماعية» (`_NotificationsScreen`) بإضافة 4 مفاتيح تشغيل/إيقاف (ماء، نصائح، حمل/دورة، منتجات) تكتب في مستند Firestore `app_config/notifications`.
- التطبيق يقرأ هذه المفاتيح (`AppNotifs._loadFlags`) عند الجدولة فيحترم اختيار الأدمن (الأثر يسري عند فتح المستخدمة للتطبيق). ميزة البثّ اليدوي القديمة بقيت كما هي.
- أُضيف `lib/screens/admin/admin_panel_screen.dart` إلى `copy_to_nabda.bat` (صار ينسخ 5 ملفات).

#### 35. أفكار ترويج المنتجات داخل التطبيق (مقترحة)
- الأقوى: ربط المنتجات بمرحلة المستخدمة (أسبوع الحمل/عمر الطفل). إضافة: عرض/منتج اليوم، تخفيضات سريعة، تذكير السلة المتروكة، بيع مكمّل بعد الشراء، خصم أول طلب، توقيت ذكي. وداخل التطبيق: بانر عروض، كاروسيل «موصى لكِ»، ذكر منتجات في نهاية المقالات، شارة عروض على أيقونة المتجر.

---

## الملفات الرئيسية

### الشاشات (Screens)

| الملف | الأسطر | الوصف |
|--------|---------|-------|
| `screens/admin/admin_panel_screen.dart` | ~4040 | لوحة التحكم (10 وحدات) |
| `screens/pregnancy/pregnancy_weeks_screen.dart` | ~2800 | شاشة الحمل الرئيسية |
| `screens/shop/shop_page.dart` | ~1657 | المتجر + تفاصيل + Checkout |
| `screens/community/community_screen.dart` | ~442 | شاشة المجتمع |
| `screens/community/post_detail_screen.dart` | ~500 | تفاصيل المنشور |
| `screens/community/leaderboard_screen.dart` | ~310 | ترتيب المستخدمات |
| `screens/community/user_profile_screen.dart` | ~350 | بروفايل المستخدمة |
| `screens/pregnancy/achievements_screen.dart` | ~400 | الإنجازات والشارات |
| `screens/pregnancy/share_progress_screen.dart` | ~300 | مشاركة التقدم |
| `screens/pregnancy/due_date_countdown_screen.dart` | - | عداد تنازلي |
| `screens/pregnancy/nutrition_screen.dart` | - | نصائح تغذية |
| `screens/pregnancy/exercises_screen.dart` | - | تمارين آمنة |

### الخدمات (Services)

| الملف | الأسطر | الوصف |
|--------|---------|-------|
| `services/admin_service.dart` | 284 | أدوار وصلاحيات |
| `services/country_currency_service.dart` | 488 | عملات وبلدان |
| `services/community_engagement_service.dart` | 327 | تنشيط المجتمع |
| `services/firestore_service.dart` | - | CRUD للبيانات |
| `services/auth_service.dart` | - | Firebase Auth |
| `services/ai_service.dart` | - | Gemini API |
| `services/cart_service.dart` | - | السلة والطلبات |
| `services/notification_service.dart` | - | الإشعارات |
| `services/dynamic_content_service.dart` | - | المحتوى الديناميكي |

### ملفات أخرى مهمة

| الملف | الوصف |
|--------|-------|
| `main.dart` (~2800 سطر) | نقطة الدخول + ترجمات + LoginPage + ProfilePage |
| `models/community_post_model.dart` | نموذج المنشور |
| `models/pregnancy_week_articles.dart` (~670 سطر) | مقالات الأسابيع |
| `config/theme.dart` | Material 3 theme |
| `config/routes.dart` | GoRouter (17 مسار) |

---

## Firebase Setup

| العنصر | القيمة |
|--------|--------|
| **المشروع** | nabda-app-ca864 |
| **Storage bucket** | nabda-app-ca864.firebasestorage.app |
| **CORS** | مفعّل (origin: *) |
| **Storage Rules** | قراءة عامة + كتابة للمسجلين |
| **Auth** | Email/Password |

### Firestore Collections
- `users` - بيانات المستخدمات + نقاط + شارات + متابعات
- `community_posts` - منشورات المجتمع
- `orders` - الطلبات
- `products` - المنتجات (من الأدمن)
- `dynamic_articles` - المقالات الديناميكية
- `dynamic_products` - المنتجات الديناميكية
- `staff` - الموظفين وأدوارهم
- `coupons` - الكوبونات
- `notifications` - سجل الإشعارات
- `settings` - إعدادات التطبيق

---

## Git Commits (60 commit)

```
20bfafd - Initial commit: NABDA app
94779da - Arabic UI, Firestore, AI Assistant with smart fallback
6e8ea6b - Add community feature: posts feed, create post, likes, comments
f893e33 - feat: pregnancy screen opens directly to current week detail
0176a0b - feat: dark theme pregnancy screen with fruit comparison, progress ring
cb73e6e - fix: close truncated brackets
b6040df - feat: light theme pregnancy screen with real fetus images, 41 weeks
76b8b70 - feat: add shop page with 15 categories and 300+ products
01ecba1 - feat: integrate shop page into main navigation
d30f1f3 - feat: add multi-currency system with 22 Arab countries support
d5c1894 - feat: add health trackers page with 7 trackers
9d74f9f - fix: move profile button to right side and center all page titles
c88b651 - fix: remove duplicate centerTitle and null bytes
35094aa - إعادة بناء لوحة التحكم + دعم صور متعددة للمنتجات
050812d - feat: apply Claude Design improvements + fix all analyzer errors
092fa28 - add new screens, achievements, auth improvements
703590e - feat: redesign HomePage with Claude Design Premium
3d6b963 - feat: redesign CyclePage with Claude Design Premium
4f5800f - feat: redesign BabyPage with Claude Design Premium
0cc3dbc - fix: add tap functionality to baby insight cards
ff34cb0 - feat: replace Arabic digits with Western + expand articles to 300+ words
59f53bf - feat: add smart Unsplash images for all articles
8203e6e - feat: expand all 36 discover articles to 300+ words
5e10bc6 - fix: replace Firestore articles with hardcoded content
2c3ad46 - Replace Firestore-dependent Cycle/Baby article sections with hardcoded
97920f4 - Expand 41 weekly pregnancy articles to ~330 Arabic words
42cfdc1 - Add unique header images to all 36 discover articles
bd16163 - Expand all Home, Cycle, and Baby articles to 300+ words
7a06f11 - Expand 33 discover articles in pregnancy_weeks_screen to 300+ words
446ea19 - Fix: join multi-line Dart strings into single lines
c88cc9e - Fix: remove trailing null bytes
c075745 - Improve article layout: paragraphs + ad space + clickable insight cards
39f57ce - Apply paragraph layout + ad space to all article detail screens
327f2db - feat: multi-baby support with selector UI and per-baby tracking
763a580 - fix: restore truncated methods + multi-baby support
5569b5e - feat: link vaccine records to individual babies via subcollection
1f3cbeb - fix: restore truncated _typingIndicator method ending
0b0b38f - feat: add 30 baby articles by age group + per-baby vaccines + fix AI chat
e2756ca - style: apply paragraph splitting to pregnancy and discover articles
8bbae6d - feat: add 30 pregnancy news articles with local + Unsplash images
3842fe5 - fix: restore truncated RealisticFetusIllustration class
86d6779 - fix: restore main.dart from clean commit
e0cafce - fix: add missing Padding wrapper and restore truncated file ending
f4f0cbb - fix: remove nested Scaffolds so bottom nav bar stays visible
1a6bc2e - feat: replace emojis with Unsplash images in discover cards
7c4c782 - feat: add discover articles carousel to home page
7e01fe3 - fix: compilation errors - borderRadius syntax
f61d376 - feat: add more articles to cycle (15) and home (19)
ff84a37 - fix: use Western numerals in all date pickers + extend year range
9aca624 - feat: add Latest News section with 30 amazing articles
7764386 - feat: admin article editing + improved article management
157d427 - fix: add section parameter to all _ArticleDetailPage call sites
eaa34ff - feat: apply Firestore overrides to news section
bac0ff2 - fix: repair truncated _AIChatPageState
e30d4fa - feat: add content image editing with device upload
1b59a9a - feat: add products carousel at bottom of articles
3d9934f - fix: move products carousel to correct position
5c940fd - feat: hybrid content system + dynamic content admin panel
aabc7c2 - feat: improved products & users management with profiles & role promotion
453daa8 - feat: community engagement system - official team account, auto-welcome, admin panel
```

---

## ملاحظات تقنية مهمة

1. **مفتاح Gemini API** مضمن في `main.dart` (~سطر 2142) — يجب نقله لمتغير بيئة
2. **الملفات الكبيرة** (>1000 سطر): أداة Edit قد تقتطع المحتوى. الحل: Python scripts عبر bash
3. **Git push من Sandbox**: يفشل بخطأ 403. الحل: git push من CMD المحلي
4. **Firebase Storage CORS**: يجب تطبيقه عبر `gsutil cors set cors.json gs://nabda-app-ca864.firebasestorage.app`
5. **FutureBuilder مع صور**: تخزين bytes مسبقاً في state لتجنب إعادة القراءة عند كل setState
6. **LoginPage**: موجودة في `main.dart` وليس في ملف منفصل (AuthGate pattern)

---

## المهام المعلقة (TODO)

- [ ] إضافة firebase_messaging لإشعارات push حقيقية
- [ ] نقل مفاتيح API إلى متغيرات بيئة (.env)
- [ ] إنشاء موقع ويب للتطبيق
- [ ] رفع التحديثات إلى GitHub (git push origin main)
- [ ] إضافة unit tests للخدمات الأساسية
- [ ] تحسين أداء التطبيق (lazy loading للصور)
- [ ] إضافة dark mode كامل

---

## إحصائيات المشروع

| المقياس | القيمة |
|---------|--------|
| **عدد الـ Commits** | 60 |
| **عدد الملفات** | 50+ ملف Dart |
| **أكبر ملف** | admin_panel_screen.dart (~4040 سطر) |
| **عدد المقالات** | 200+ مقال عربي |
| **عدد المنتجات** | 300+ منتج |
| **عدد الشاشات** | 25+ شاشة |
| **عدد الخدمات** | 10+ خدمة |
| **الدول المدعومة** | 23 دولة (22 عربية + فرنسا) |
| **اللغات** | 3 (عربي، إنجليزي، فرنسي) |

---

*آخر تحديث: 1 يونيو 2026*
*إعداد: Claude AI بناءً على جلسات العمل مع Billel*
