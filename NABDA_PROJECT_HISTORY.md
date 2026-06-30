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

### المرحلة 13: موقع الأخبار (nabda.online) + لوحة التحكم + نظام الإعلانات (2-5 يونيو 2026)

#### 36. موقع nabda.online (WordPress + Bimber)
- الدومين مسجّل في **Namecheap**، موجّه إلى **Hostinger** (خطة Business) عبر خوادم الأسماء `hermes.dns-parking.com` و`artemis.dns-parking.com`. ثُبّت WordPress كموقع ثانٍ بجانب piecety.com.
- ثيم **Bimber** (مجلة فيروسية) — **أُزيل من ThemeForest** وخادم تسجيله `api.bringthepixel.com` يرجع 404، لذلك يعمل **بدون تسجيل** (لا تحديثات/دعم/Snax). فوقه **ثيم فرعي `nabda-child`** (RTL، خط Almarai، ألوان فيروزي/وردي) — ملفاته في `nabda_website/`.
- **إضافة المزامنة `nabda-app-sync` (v1.1.0):** عند نشر/تعديل مقال على الموقع تُرسله إلى Firestore `dynamic_articles` (معرّف ثابت `wp_<postID>`، `section=news`)، وتحذفه عند حذف المقال. تسجّل الدخول عبر Firebase Auth بحساب `billel@nabda.com` (staff) للحصول على idToken لأن قواعد Firestore تسمح بالكتابة للموظّفين فقط.

#### 37. لوحة تحكم الأخبار (ملف `nabda_news_dashboard.html`)
- صفحة HTML واحدة تُفتح بالمتصفح: تسجيل دخول بحساب إداري، **جلب أحدث المواضيع** عبر Gemini 2.5-flash مع بحث Google، **صور حقيقية من Pexels** (صورتان لكل مقال)، مراجعة وتعديل، ثم **نشر مباشر إلى `dynamic_articles`** فيظهر في «آخر الأخبار» بالتطبيق.
- المفاتيح داخل الملف: Firebase web key، مفتاح Gemini الجديد، مفتاح Pexels.

#### 38. إصلاحات Firestore الحاسمة
- **فهرس مركّب مفقود** على `dynamic_articles` (الحقول: `section` تصاعدي، `createdAt` تنازلي) — كان غيابه يمنع ظهور **كل المحتوى الديناميكي** في التطبيق (home/baby/cycle/pregnancy/news). أُنشئ الفهرس.
- قاعدة جديدة لمجموعة **`ads`** (قراءة للمسجّلين، كتابة للموظّفين) أُضيفت إلى `firestore.rules` ونُشرت في الكونسول.
- ملاحظة وصول: مشروع Firebase `nabda-app-ca864` مملوك لحساب Google مختلف عن `billelnoui19@gmail.com` (الأخير يعطي 403 في الكونسول).

#### 39. تحسين عرض المقالات
- مقالات أطول (٥-٧ فقرات)، **صورة ثانية `image2`** تظهر قبل الفقرة الأخيرة، و**حُذف كاروسيل المنتجات** التلقائي في آخر المقال.
- أُضيف `image2` إلى `DynamicContentService.docToArticle` و`_NewsDetailPage` في `news_section.dart`.

#### 40. نظام الإعلانات (إعلانات Google + إعلانات خاصة + منتج من المتجر)
- **ودجت `NabdaAd`** (في `news_section.dart`): يمزج في أماكن الإعلانات بين **إعلاناتك الخاصة** (مجموعة `ads`، active==true) و**منتج بارز من المتجر** (`dynamic_products`)، مع علَم `kAdmobReady=false` يحجز خانة **Google AdMob** للتفعيل لاحقاً (يحتاج حساب AdMob + حزمة google_mobile_ads). الضغط على الإعلان الخاص يفتح رابطه عبر `url_launcher`، والمنتج يفتح صفحة المتجر.
- **مدير إعلانات داخل التطبيق** (`_AdsManagementScreen` في لوحة الأدمن) — بطاقة «📢 إدارة الإعلانات» تظهر **للمالك/المشرف فقط** (صلاحية `manageCoupons`): إضافة إعلان (عنوان + رابط + **رفع صورة من الجهاز** إلى Storage أو رابط)، تفعيل/إيقاف، حذف. مكتوب فيها **المقاس الأفضل: 1200×628 بكسل (1.91:1)**.
- لوحة الويب أيضاً تدير الإعلانات (القسم ④) مع رفع صورة (Firebase Storage) وزر Pexels وهامش المقاس.
- في `main.dart` استُبدل مكان «Google AdMob» الثابت في صفحة تفاصيل المقال بودجت `NabdaAd` (أُضيف import لـ `widgets/news_section.dart`). ملاحظة: توجد صفحتا مقالات أخريان فيهما نفس المكان الثابت (`discover_articles_screen.dart`، `pregnancy_weeks_screen.dart`) لم تُحوّل بعد.

#### 41. تبعيات ومتأثرات
- أُضيف **`url_launcher: ^6.3.1`** إلى `pubspec.yaml`، وكتلة `<queries>` (https) إلى `AndroidManifest.xml` (تُعدّلان يدوياً في `C:\nabda_app`).
- صار `copy_to_nabda.bat` ينسخ: main.dart، medication_tracker_screen.dart، medication_model.dart، health_tracking_service.dart، admin_panel_screen.dart، weight_tracker_screen.dart، **news_section.dart**، **dynamic_content_service.dart** (+ هذا الملف).
- **مفتاح Gemini القديم في `main.dart` عُطّل من Google (تسريب)** → مساعد الذكاء الاصطناعي في التطبيق يحتاج مفتاحاً جديداً من aistudio.google.com.
- **تنبيه بناء:** مزامنة مجلد OneDrive تقتطع الملفات أحياناً عند الكتابة عبر أدوات التحرير المباشرة — الحل المعتمد: بناء الملف كاملاً في `/tmp` ثم نسخه (`cp`) إلى المجلد.

---

### المرحلة 14: منظومة الإعلانات المتقدمة + قسم رحلة الخصوبة (5-6 يونيو 2026)

#### 42. محرّك إعلانات NabdaAds (في `lib/widgets/news_section.dart`)
- مجموعة Firestore **`ads`**: `{title, link, image, active, priority, target, startAt, endAt, impressions, clicks, source}`.
- ميزات المحرّك: **أولوية موزونة** (اختيار عشوائي مرجّح)، **جدولة** (startAt/endAt)، **استهداف** عبر `target` (قيم: '' أو all/news/pregnancy/cycle/baby/home/fertility)، **منع تكرار** داخل نفس المقال (ترتيب موزون مخزّن لكل `groupId|place`)، **عدّادات** ظهور/نقر.
- ودجت `NabdaAd(slot, groupId, place, color)`؛ عند غياب إعلانات مؤهّلة يعرض **منتجاً من `dynamic_products`** (fallback)، وعلَم `kAdmobReady=false` محجوز لإعلانات Google AdMob مستقبلاً.
- أماكن الإعلانات: صفحة الأخبار (3 - main.dart `_NewsSection` detail عبر slot/place)، main.dart news detail، `discover_articles_screen.dart`، `pregnancy_weeks_screen.dart` (مكانان)، الرئيسية + صفحة الطفل (واحد لكلٍّ)، وصفحة الخصوبة (2) + صفحة مقال الخصوبة (3).
- **قاعدة Firestore لـ `ads`**: قراءة لأي مستخدم مسجّل؛ create/delete للموظّفين؛ update للموظّف، أو لأي مستخدم مسجّل **لزيادة `impressions`/`clicks` فقط** (عبر `affectedKeys().hasOnly`). نُشرت في الكونسول.

#### 43. واجهات إدارة الإعلانات
- **لوحة الويب** `nabda_news_dashboard.html` (القسم ④): إضافة/تفعيل/حذف + رفع صورة (Firebase Storage) + Pexels + حقول الأولوية/الاستهداف/الجدولة + عرض الإحصائيات + هامش المقاس 1200×628.
- **داخل التطبيق**: `_AdsManagementScreen` في `admin_panel_screen.dart`، بطاقة «📢 إدارة الإعلانات» تظهر **للمالك/المشرف فقط** (صلاحية `manageCoupons`)، برفع صورة من الجهاز + أولوية + استهداف + جدولة + إحصائيات.

#### 44. قسم رحلة الخصوبة (TTC) — `lib/screens/fertility/fertility_screen.dart`
- حقل `goal=='trying'` في وثيقة المستخدمة يبدّل تبويب الحمل (عند `pregnancyStartDate==null`) إلى `FertilityScreen`. بطاقة CTA «🌱 أحاول الحمل» تضبط goal، وزر «أكّدي حملك» يضبط `pregnancyStartDate` + `goal=null` فيعود لمتتبّع الحمل.
- يحسب نافذة الخصوبة من `lastPeriodStart`+`cycleLength`-`lutealPhase`. تصميم فاخر (هيرو + خط زمني للأيام بحالات + بطاقات + مقالات مفيدة + قصص ملهمة + إعلانات + استبيان توجيه ضعف الخصوبة). تذكير التوقيت عبر `AppNotifs._scheduleFertility()` (معرّفات 1400-1419، alarmClock) داخل `scheduleAll()`.

---

### المرحلة 15: شاشات التعريف + الشعار + شاشة البداية المتحركة + إصلاح الشاشة السوداء (6-7 يونيو 2026)

#### 45. شاشات التعريف (Onboarding intro) — `lib/screens/intro_screen.dart`
- 3 شرائح ترحيبية (ترحيب+شعار / دليلكِ في كل مرحلة / الخصوصية + «ابدئي رحلتك»). مسار `/intro` في `routes.dart`. `splash` يعرضها أول تشغيل عبر علم `intro_seen` ثم يقود إلى `/onboarding` (إعداد الحساب الأصلي 7 خطوات الموجود مسبقاً).
- ملاحظة: يوجد فرق بين **intro** (تعريف) و**onboarding** (إعداد بيانات المستخدمة) — لا تخلط بينهما.

#### 46. الشعار + شاشة البداية المتحركة
- الشعار في `assets/images/logo_nabda.png` (يُستخدم في intro + splash). **أيقونة التطبيق (launcher) لم تُضبط بعد** — تحتاج `flutter_launcher_icons` + نسخة مربّعة مبسّطة من الشعار.
- `splash_screen.dart` أُعيد تصميمها: ظهور (scale elasticOut + fade) + **نبض قلب متكرّر** على الشعار + مؤشّر تحميل. (جُرّبت نسخة بـ Stack/ظل متحرّك ثم بُسّطت لودجت قياسية لتفادي مشاكل الرسم.)

#### 47. ⚠️ إصلاح حاسم: الشاشة السوداء عند الإقلاع (السبب والحل)
- **العَرَض:** شاشة سوداء تماماً عند فتح التطبيق على الهاتف (Samsung A50)، والسجل يُظهر `Unable to resolve host firestore.googleapis.com` (الهاتف بلا إنترنت) + `Width is zero` + Impeller.
- **التشخيص الخاطئ أولاً:** ظُنّ أنه Impeller (لم يكن السبب) ثم شاشة البداية (لم تكن السبب).
- **السبب الحقيقي:** `main()` كان ينفّذ `await NotificationService().initialize();` وهذه تنتظر `FirebaseMessaging.getToken()` الذي **يحتاج شبكة**؛ فعند انقطاع إنترنت الهاتف **يعلّق قبل `runApp()`** → لا تُرسم أي واجهة → شاشة سوداء. (كان يعمل سابقاً لأن الهاتف كان متصلاً.)
- **الحل:** في `main.dart` أُزيل `await` (تهيئة الإشعارات صارت غير حاجبة)، وفي `lib/services/notification_service.dart` صار `getToken()` بمهلة 6 ثوانٍ وغير حاجب (`.timeout(...).then(saveFCMToken)`)، وأُصلح `debugPrint` الذي كان يشير لمتغيّر `token` محذوف.
- **الدرس للمستقبل (مهم لـ Claude Code):** لا تنتظر (`await`) أي نداء شبكة (FCM getToken، قراءات Firestore) **قبل `runApp()`**؛ يجب أن يُقلع التطبيق ويُرسم حتى دون إنترنت. النتيجة: التطبيق الآن يُقلع ويعرض الواجهات أوفلاين (المحتوى فقط يحتاج شبكة).

#### 48. ملاحظات للعمل عبر Claude Code في Antigravity
- **مشروع البناء الحقيقي** هو `C:\nabda_app` (مجلد OneDrive `nabda_app_backup` هو نسخة تحرير/احتياطية). مع Claude Code يمكنك **التحرير مباشرة في `C:\nabda_app`** والاستغناء عن `copy_to_nabda.bat`.
- `pubspec.yaml` و`android/app/src/main/AndroidManifest.xml` تُحرَّر مباشرة في `C:\nabda_app`. الأصول في `assets/images/` (مسجّلة في pubspec).
- التشغيل على الهاتف: تفعيل «تصحيح USB»، ثم `flutter run`. على Samsung A50 الإشعارات المجدولة تحتاج `AndroidScheduleMode.alarmClock` (راجع AppNotifs/NotifService).
- مفاتيح: Firebase web key في firebase_options + main.dart؛ **مفتاح Gemini القديم سُرّب وعُطّل واستُبدل بجديد** (في main.dart). قواعد Firestore + الفهرس المركّب لـ `dynamic_articles` (section ASC, createdAt DESC) منشورة. مجموعات: users, dynamic_articles, dynamic_products, ads, staff, products, orders, community_posts, coupons.
- حساب إداري للنشر/المزامنة: `billel@nabda.com` (في staff، owner). الموقع: nabda.online (WordPress+Bimber) يزامن مقالاته إلى `dynamic_articles` عبر إضافة `nabda-app-sync`.

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
- [x] إنشاء موقع ويب للتطبيق (nabda.online — WordPress/Bimber + مزامنة تلقائية)
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

## المرحلة 16: إعادة هيكلة الـ Onboarding + تخصيص المحتوى + تقويم دورة تفاعلي (9-10 يونيو 2026)

#### 47. إصلاح تدفّق الإقلاع وشاشات التعريف
- كان التطبيق يفتح مباشرة على شاشة تسجيل الدخول متخطّيًا شاشة البداية وشاشات التعريف، لأن `main.dart` يستخدم `home: AuthGate()` بينما splash/intro كانتا موصولتين بـ GoRouter ميّت (`routes.dart` غير مستورَد في أي ملف).
- أُضيف `RootGate` (في `main.dart`) يدير التسلسل: **Splash → (أول تشغيل) Intro → AuthGate**. شاشتا splash/intro حُوّلتا من `context.go` إلى نمط `onDone`.
- أُصلحت علامات تعارض Git merge غير محلولة في `routes.dart`.

#### 48. نقل الـ Onboarding إلى ما بعد تسجيل الدخول + إزالة التكرار
- التدفّق الجديد: **تعريف → إنشاء حساب/دخول → سؤال المرحلة (onboarding)**.
- `AuthGate` صار StreamBuilder متداخلًا: عند الدخول يقرأ وثيقة المستخدمة؛ إن لم يكتمل `onboardingDone` (أو غاب `lifeStage`) يعرض `OnboardingScreen` تفاعليًا، وإلا `MainNav`.
- حُذفت خطوتا الاسم والشروط من الـ onboarding (تُؤخذ من التسجيل). التسجيل يحفظ `displayName` + `termsAccepted`.
- `LoginPage` يبدأ بوضع **إنشاء حساب** لأول استخدام (علم `has_account` في prefs)، والعائدات يَرَيْن تسجيل الدخول.

#### 49. استبيانات لكل مرحلة + ربط الخصوبة
- استبيان مخصّص لكل مرحلة يُحفظ في وثيقة المستخدمة:
  - **حامل:** `pregnancyProfile{firstPregnancy, babies, age, condition}` + `pregnancyStartDate`.
  - **طفل:** `babyProfile{gender, feeding, firstChild}` + `babyGender` + `babyBirthDate`/`babyName`.
  - **أخطط للحمل:** `goal:'trying'` + `lastPeriodStart` + `cycleLength` + `fertilityProfile{tryMonths, age, regular, condition}`.
  - **دورة:** `lastPeriodStart` + `cycleLength` + `cycleProfile{periodLength, regular, trackingGoal}`.
- اختيار «أخطط للحمل» يوجّه تلقائيًا إلى `FertilityScreen` (عبر `goal=='trying'` في تبويب الحمل)، وتهبط المستخدمة على تبويب مرحلتها (`_applyInitialTab`).

#### 50. تخصيص المحتوى حسب البيانات المجموعة
- **`lib/widgets/personalized_tips.dart`** (`PersonalizedTipsCard`): بطاقة نصائح مخصّصة أعلى كل تبويب حسب الملف الشخصي.
- **`lib/widgets/conditional_content.dart`** (`ConditionalContentSection`): مقالات/أقسام مشروطة (توأم، سكري حمل، ارتفاع ضغط، رضاعة صناعية/مختلطة، دورة غير منتظمة).
- تلوين واجهة تبويب الطفل حسب `babyGender` (أزرق/وردي) في البطاقة الرئيسية والأفاتار وشريحة اختيار الطفل.

#### 51. تقويم الدورة التفاعلي
- **`lib/widgets/cycle_calendar.dart`** (`CycleCalendarCard`): تقويم شهري (سابق/قادم) يلوّن أيام الحيض 🩸 والخصوبة 🌱 والإباضة 🥚 مع إيموجي، محسوبة من `lastPeriodStart`+`cycleLength`+`periodLength`.
- **تفاعلي:** الضغط على أي يوم يفتح نافذة لتسجيل الحيض وشدّته (خفيف/متوسط/غزير) واضطراب (تأخّر/تبكير/نزيف غزير/تنقيط/ألم شديد/غياب) وملاحظة، تُحفظ في `cycle_logs` (جاهزة للتحليل لاحقًا)، مع زر «تعيين كبداية دورة جديدة» يحدّث `lastPeriodStart`. الاضطرابات تظهر بعلامة ⚠️.

#### 52. تصحيح بيانات الحمل (أحجام/أوزان/أسماء الفواكه)
- جدول دقيق لطول ووزن الجنين أسبوعيًا (4-41) في `models/pregnancy_week_articles.dart`.
- استبدال `_fruitData` (في `pregnancy_weeks_screen.dart`) بأسماء فواكه/خضار **مألوفة جزائريًا/عربيًا** مع إيموجي مطابق (تصحيح أخطاء فجّة مثل «برنامج»، «🍕 ذرة»، «🍯 عسل»، «رومaine»).
- توحيد جملة مقارنة الحجم داخل نصوص `fetalDevAr` مع `babySizeAr` الجديد لكل أسبوع.

#### 53. منهجية العمل والـ Git
- **معظم التعديلات نُفّذت عبر وكيل Antigravity/Gemini** (لتوفير استهلاك Claude)، و**Claude Code (Opus 4.8)** تولّى التصميم والمراجعة والتحقق (`flutter analyze` بصفر أخطاء في كل خطوة).
- **ملاحظة بيئة:** الوكلاء المُطلَقون داخل Antigravity (أداة Agent / TeamCreate) **بلا صلاحية كتابة على الملفات** — التنفيذ يكون عبر وكيل Antigravity الخارجي أو الجلسة الرئيسية.
- **Git:** فرع `feat/onboarding-personalization`، commit `2f53d20` (75 ملفًا، +24708/−2874) — يضمّ أيضًا أعمال المراحل 11-15 التي لم تكن محفوظة سابقًا في git. لم يُرفع (push) بعد.
- ملفات جديدة: `widgets/personalized_tips.dart`، `widgets/conditional_content.dart`، `widgets/cycle_calendar.dart`، `screens/intro_screen.dart`.

#### 54. المقالات المتخصّصة + ترحيلها إلى Firestore + لوحة الأدمن
- مكتبة **66 مقالًا متخصّصًا** (11 موضوعًا × 6، كلّها ≥300 كلمة) في `lib/data/specialized_articles.dart`: توأم، سكري حمل، ارتفاع ضغط، رضاعة صناعية/مختلطة، دورة غير منتظمة، غثيان، حمل أول، طفل أول، تكيّس مبايض، غدة درقية.
- ترحيلها إلى Firestore (`specialized_articles`) عبر `SpecializedArticlesService` (streamByTopic/streamAll/seedFromHardcoded) — يديرها الأدمن من تبويب «متخصّصة» (CRUD + رفع صور). النسخة المكتوبة احتياط في التطبيق فقط.
- **ملاحظة تشغيل:** لظهور المقالات في الأدمن يلزم نشر `firestore.rules` + ضغط زر «استيراد المقالات الأساسية (66)».

#### 55. إصلاح بلاغات العرض الثلاثة + قواعد المجموعات الفرعية
- **حارس المرحلة:** `ConditionalContentSection` و`PersonalizedTipsCard` أخذا `stage` وحارس `d['lifeStage'] != stage` فلا يظهر محتوى مرحلة في تبويب أخرى.
- **تنسيق المقال** أُعيد ليطابق `_NewsDetailPage`: رأس صورة + `NabdaAd` (إعلان/منتج قريب) موزّعة.
- خريطة شاشات الحمل: `WeekDetailScreen` = تبويب الحمل (الجنين/الحجم)؛ `PregnancyWeeksScreen` بلا أسبوع = قائمة الأثلاث. أُدرج المحتوى المخصّص في `WeekDetailScreen` قبل المقالات العامة، ثم حُوّل لكاروسال أفقي تحت معلومات الحجم/الوزن.
- **إصلاح `permission-denied`:** أُضيفت قاعدة `match /users/{userId}/{sub=**}` للمجموعات الفرعية (babies/baby_logs/cycle_logs/weight_tracker/vaccines/logs) — كانت قاعدة الرفض الأخيرة تلتقطها.

#### 56. منتجات بنمط Dukan — المرحلة 1: محرّر المنتج المتقدّم
- إعادة بناء `_AddProductScreen` إلى **10 أقسام قابلة للطي**: معلومات، وصف، تسعيرات (سعر/قديم/تكلفة)، صور (غلاف + معرض)، إعدادات عامة (`displayType` صفحة منتج/هبوط + تخطّي السلة + وضع صارم + …)، شحن (مجاني/مخصّص/نقطة استلام)، خيارات وألوان (`variants`)، خيارات ثانوية (`secondaryOptions`/مقاسات)، عروض كمية (`offers`)، مراجعات (`reviews`).
- توافق رجعي كامل + رفع صور الغلاف/الخيارات/العروض/المراجعات كروابط قبل الكتابة. (commit `8ac6fe4`)

#### 57. المرحلة 2: صفحة الهبوط + الدفع المباشر COD
- `lib/screens/shop/landing_product_screen.dart`: تُفتح عند `displayType=='landing'` من `shop_page.dart`. هيرو + اختيار لون/مقاس + عروض كمية + مراجعات + **نموذج طلب مباشر** (تخطّي السلة) يكتب في `orders` + `users/{uid}/orders/{id}` بمخطّط `OrderModel` + صفحة شكر. (commit `5788def`)

#### 58. إصلاح ثغرتي صفحة الهبوط
- **حارس تسجيل الدخول:** إزالة `?? 'guest'` المُضلِّل (قواعد Firestore تشترط مصادقة) ورسالة «سجّلي الدخول».
- **منع البيع الزائد:** فحص مخزون قبل إنشاء الطلب (المنتج مُتتبَّع عندما `stock>0`؛ `stock==0`=غير محدود) فلا يُقبل طلب أكبر من المتاح، دون تعطيل المنتجات غير المُتتبَّعة. (commit `d6a3d7f`)

#### 59. تحديث الولايات (69) + البلديات المنسدلة (تقسيم 2025)
- **الجزائر أصبحت 69 ولاية منذ 16 نوفمبر 2025** (تُرقّى 11 مقاطعة إدارية: 59–69). أُضيفت إلى قائمة الولايات في صفحة الهبوط. (كان التطبيق يحوي 58 فقط.)
- **بلديات منسدلة مرتبطة بالولاية:** بيانات 69 ولاية / 1541 بلدية في `assets/data/algeria_cities.json` تُحمَّل عبر `lib/data/algeria_locations.dart`؛ اختيار الولاية يُصفّي بلدياتها. المصدر: مجموعة بيانات تقسيم 2025 (قابلة للاستبدال بقائمة شركة التوصيل ZR Express لاحقًا بتبديل ملف JSON).
- جملة إرشادية «(يمكنكِ كتابة اسم زوجكِ)» تحت حقل اسم المستلم. (commit `ae2597d`, `9f6e612`)

#### 60. خطط موثّقة (لم تُنفَّذ بعد) ومنهجية
- ملفات خطط في جذر المشروع: `WEB_ADMIN_PLAN.md` (لوحة تحكم ويب عبر Flutter Web على Firebase، النطاق `admin.nabda.online`، Bimber يبقى واجهة عامة)، `AUTH_HYBRID_PLAN.md` (مصادقة هجينة هاتف-أو-بريد + كلمة مرور بلا OTP عبر بريد اصطناعي — صفر تكلفة SMS)، `LANDING_PRODUCTS_PLAN.md` (مراحل منتجات Dukan).
- استمرار النمط: التصميم/المراجعة/التحقّق في Claude (Opus 4.8) والتنفيذ غالبًا عبر Antigravity؛ `flutter analyze` بصفر أخطاء وبناء `nabda.apk` ورفع Git بعد كل مرحلة.

---

## المرحلة 17: مسار المال (COD) + إنهاء/فقدان الحمل الرحيم + الولادة المبكرة (15-16 يونيو 2026)

#### 61. التحقّق من مسار الدفع عند الاستلام (COD) + إصلاح إنقاص المخزون
- **تدقيق حقل-بحقل** لمسار صفحة الهبوط → لوحة الأدمن: الطلب يظهر صحيحًا (`status`, `productName`, `customerName`, `phone`, `total`, `userId`)، «تغيير الحالة» وإشعار العميلة يعملان، وحساب الشحن سليم (مجاني → 0، مخصّص، بيت 500 / مكتب 300 د.ج).
- **خطأ مكتشَف:** كتلة إنقاص المخزون كانت تفشل صامتًا — قاعدة `products` تشترط `isActiveStaff` للتعديل، فيُرفَض تحديث العميلة ويُبتلَع داخل try/catch → المخزون لا يَنقُص أبدًا على طلبات العميلات (بيع زائد ممكن عبر عدّة طلبات).
- **الإصلاح:** قاعدة ضيّقة في `firestore.rules` تسمح لأي مستخدمة مصادَقة بتعديل حقل `stock` **فقط ونحو الأسفل** و`>= 0` (تطابق كتلة الإنقاص تمامًا). الأنظف لاحقًا = Cloud Function. (commit `815847e`)
- **إصلاح النشر:** `firebase.json` كان يحوي `hosting` فقط بلا قسم `firestore`، فأمر `firebase deploy --only firestore:rules` لا يجد هدفًا. أُضيف قسم `firestore.rules` (لا يوجد ملف فهارس). (commit `3048e36`)
- **خطوة يدوية إلزامية:** `firebase deploy --only firestore:rules` لتفعيل القاعدة على الخادم (لا حاجة لإعادة بناء APK — القواعد إعداد خادم).

#### 62. شاشة إنهاء/فقدان الحمل الرحيمة
- **الدافع:** لم تكن هناك وسيلة لطيفة لإيقاف متابعة الحمل عند الفقدان/الإجهاض المبكر — كانت المستخدمة تبقى ترى محتوى الحمل وحجم الجنين والتذكيرات (مؤلم). الطريقة الوحيدة كانت تنبيه ما بعد الأسبوع 42.
- **`lib/screens/pregnancy/end_pregnancy_screen.dart`** (جديد): مدخل غير مُلفِت (⋮ «تحديث حالة الحمل») في `WeekDetailScreen` → ثلاثة خيارات: **«وضعتُ مولودي»** (→ رعاية الطفل) · **«توقّف الحمل»** (المسار الرحيم) · **«أفضّل عدم التحديد»** (→ الدورة).
- **مسار الفقدان:** رسالة دافئة «نحن معكِ 🤍» **بلا تهنئة ولا إيموجي احتفالي**، + مقال دعم «التعافي بعد فقدان الحمل»، + سؤالها كيف تتابع — بلا أي اقتراح للحمل مجددًا.
- **العودة للدورة:** ضبط `lifeStage='cycle'` ومسح `pregnancyStartDate` **دون تعيين `lastPeriodStart`** (تسجّلها هي عند عودة دورتها — التنبؤ التلقائي بعد الفقدان خاطئ ومؤلم).
- **أرشفة صامتة** (لا حذف) في `users/{uid}/pregnancyHistory` مع `outcome` (birth/loss/unspecified).
- **إصلاح التنقّل:** بعد الإنهاء تُضبط `life_stage` في prefs وتُدفَع `MainNav` جديدة فتهبط على التبويب الصحيح (الدورة للفقدان، الطفل للولادة) بدل البقاء على تبويب الحمل الفارغ.
- **إصلاح `_confirmBirth`** (في `main.dart`): الولادة بعد الأسبوع 42 تذهب الآن لرعاية الطفل + أرشفة، بدل العودة للدورة. (commits `dc96f27`, `da57cea` — تعديل main.dart محلي بعدُ، انظر #64)
- التوثيق المرجعي: `PREGNANCY_LOSS_PLAN.md` في جذر المشروع.

#### 63. رصد الولادة المبكرة + محتوى الطفل الخديج
- عند «وضعتُ مولودي» يُحسب أسبوع الحمل من `pregnancyStartDate` (نفس اصطلاح التطبيق: الأيام ÷ 7). إن كان **< 37 أسبوعًا** تُضبط `pretermBirth: true` + `birthWeek` في وثيقة المستخدمة وفي أرشيف `pregnancyHistory`.
- **`conditional_content.dart`:** في مرحلة `baby` يظهر موضوع «العناية بالطفل الخديج» (مفتاح `preterm`) تلقائيًا عندما `pretermBirth == true` — نفس آلية المحتوى المشروط.
- **6 مقالات خديج** في `specialized_articles.dart` (مفتاح `preterm`): معنى الولادة المبكرة ودرجاتها، الحاضنة/NICU، تغذية الخديج والرضاعة، العمر المصحّح ومتابعة النمو، العناية في المنزل بعد الخروج، الدعم النفسي للأم.
- أُضيف `preterm` لقائمة مواضيع الأدمن (`_specTopicKeys`/`_specTopicLabels` في `admin_panel_screen.dart`) — يظهر للمستخدمة فورًا عبر النسخة المكتوبة الاحتياطية دون استيراد. (commit `7c7c8c7` للملفات المعزولة؛ تعديل admin_panel محلي، انظر #64)

#### 64. تنسيق معلّق مع جلسة المصادقة (غير محسوم)
- **عمل مصادقة هجين** (هاتف/بريد + استرجاع كلمة المرور، ~745 سطرًا عبر `auth_service`/`auth_bloc`/login/register/validators/admin_panel/firestore.rules) من جلسة موازية **غير مرفوع بعد**، ويُصرَّف نظيفًا بلا علامات نقص.
- تعديلات هذه المرحلة على **`main.dart` (`_confirmBirth`)** و**`admin_panel_screen.dart` (موضوع preterm)** **متشابكة في نفس الملفّات** مع عمل المصادقة، فلا يمكن فصلها/رفعها وحدها.
- **قرار المستخدِمة (16 يونيو 2026):** المصادقة غير جاهزة → **لا رفع ولا بناء APK**. تبقى التعديلات محلية حتى تكتمل المصادقة، ثم يُبنى APK موحّد يضمّ كل شيء.
- ملاحظة جانبية: `lib/screens/pregnancy/pregnancy_news_articles.dart` شظيّة بيانات بامتداد `.dart` خطأً (109 أخطاء analyze وهمية) — غير مستورَدة فلا تكسر البناء؛ تُركت دون مساس.

---

## المرحلة 18: دعم الولادة القيصرية (16 يونيو 2026)

#### 65. التقاط نوع الولادة (طبيعية/قيصرية) من ثلاث نقاط
- حقل `birthType` ('vaginal' | 'cesarean') على وثيقة المستخدمة + في أرشيف `pregnancyHistory`.
- **(أ) الشهر الثامن (أسبوع ≥ 32):** بطاقة «خطّة الولادة» `_BirthPlanPrompt` في `WeekDetailScreen` (`pregnancy_weeks_screen.dart`) تدعوها لتسجيل النوع المتوقّع **بعد استشارة الطبيبة** (اختياري، StreamBuilder يُخفيها تلقائيًا متى سُجّل النوع).
- **(ب) لحظة الولادة:** عند «وضعتُ مولودي» في `end_pregnancy_screen.dart` مسار جديد `_buildBirthTypePath` يسأل «كيف وضعتِ مولودكِ؟» (طبيعية/قيصرية/أفضّل عدم التحديد) ويؤكّد/يحدّث `birthType`.
- **(ج) onboarding الطفل:** حقل «نوع الولادة» في `_babyProfileStep` (`onboarding_screen.dart`) يُكتب في `babyProfile.birthType` + `birthType` لمن تدخل مرحلة الطفل مباشرة.

#### 66. محتوى مشروط: استعداد في الحمل + تعافٍ في رعاية الطفل
- **`conditional_content.dart`:** في مرحلة `pregnant` يظهر «الاستعداد للولادة القيصرية» (مفتاح `cesareanPrep`) عند `birthType=='cesarean'`؛ وفي مرحلة `baby` يظهر «التعافي بعد الولادة القيصرية» (مفتاح `cesarean`). نفس آلية المحتوى المشروط (الخديج/التوأم…).
- **12 مقالًا** في `specialized_articles.dart`: `cesareanPrep` (6: ما القيصرية ومتى، المخطّطة مقابل الطارئة، التحضير قبل العملية، يوم العملية والتخدير، أسئلة للطبيبة، طمأنينة نفسية) + `cesarean` (6: التعافي في الأيام الأولى، العناية بالجرح والوقاية من الالتهاب، إدارة الألم والحركة، الرضاعة بعد القيصرية، علامات الخطر، الحمل القادم وVBAC).
- أُضيف `cesareanPrep` و`cesarean` لقائمة مواضيع الأدمن (`admin_panel_screen.dart`) — يظهران فورًا عبر النسخة المكتوبة الاحتياطية دون استيراد.
- **الرفع:** commit `88c3b87` للملفات الخمسة المعزولة (المقالات + المحتوى المشروط + شاشة الإنهاء + بطاقة الشهر الثامن + onboarding). تعديل `admin_panel_screen.dart` يبقى محليًّا مع عمل المصادقة (انظر #64). البناء/الرفع الموحّد مؤجّل حتى جاهزية المصادقة.

---

## المرحلة 19: عرض الشهر الموافق للأسبوع + إزالة تكرار «الأسبوع» (16 يونيو 2026)

#### 67. إظهار شهر الحمل (اصطلاح الجزائر يحسب بالشهر لا بالأسبوع)
- دوال جديدة في `models/pregnancy_week_articles.dart`: `getMonth()`/`getMonthAr()` على الكائن + `pregnancyMonthForWeek(week)`/`pregnancyMonthArForWeek(week)` مستقلّتان. الخريطة: ش1 (1–4)، ش2 (5–8)، ش3 (9–13)، ش4 (14–17)، ش5 (18–22)، ش6 (23–27)، ش7 (28–31)، ش8 (32–35)، ش9 (36+).
- **`WeekDetailScreen`:** بطاقة التقدّم الخضراء تعرض «${الشهر} · {ن} يوم متبقي» تحت رقم الأسبوع.
- **`main.dart` (بطاقة الحمل في الرئيسية):** شريحة المرحلة صارت «الأسبوع N · الشهر X». (تعديل main.dart محلي مع المصادقة — انظر #64.)

#### 68. إزالة تكرار «الأسبوع» الثلاثي في ترويسة WeekDetailScreen
- في الشاشة كانت كلمة «الأسبوع N» تظهر ثلاث مرّات في نفس المكان: شارة الصورة + عنوان `FlexibleSpaceBar` (النص الكبير المكرّر) + بطاقة التقدّم.
- حُوّل **عنوان `FlexibleSpaceBar`** (النص المكرّر المحدّد من المستخدمة) من «الأسبوع N» إلى **«الشهر X»** — فأُزيل التكرار ووُضع الشهر مكانه (يخدم الطلبين معًا). تبقى الشارة على الصورة + بطاقة التقدّم تعرضان الأسبوع.
- **الرفع:** commit `f4b4305` للملفّين المعزولين (النموذج + الشاشة).

#### 69. توسيع عرض الشهر: تقويم الحمل + شاشة حجم الجنين
- **`pregnancy_calendar_screen.dart`:** ترويسة التقويم تعرض «{الشهر} · الثلث X» تحت رقم الأسبوع الكبير؛ وشريحة اليوم المحدّد صارت «الأسبوع N · {الشهر}».
- **`fetus_size_screen.dart`:** شريحة الثلث صارت «الثلث X · {الشهر}» بجانب شريحة «الأسبوع N» (حُوّل الصفّ إلى `Wrap` لمنع الفيض على الشاشات الضيّقة). الأسبوع محفوظ في الحالتين.
- **الرفع:** commit `6428870` (الملفّان معزولان ونظيفان).

---

## المرحلة 20: نسخة الويب الكاملة (17–19 يونيو 2026)

> **الرابط الحيّ:** https://nabda-app-ca864.web.app — Flutter Web على Firebase Hosting، نفس مشروع Firebase ونفس الحساب عبر كل المنصّات.
> **أدوات:** firebase-tools v15.20.0 (npm)، تسجيل دخول CLI بحساب `billelnoui19@gmail.com`.
> **ملاحظة هامّة:** معظم عمل الويب **منشور عبر Firebase Hosting لكنّه غير مرفوع لـ Git بعد** (تعديلات محلية على `main.dart` متشابكة مع عمل المصادقة المعلّق #64).

#### 70. أساس الويب + لوحة أدمن ويب
- `lib/main_web.dart` (جديد): نقطة دخول أدمن خلف حارس طاقم (`AdminService.isAdmin` + `staff/{uid}.isActive`) ثم `AdminPanelScreen`.
- `firebase.json` + `.firebaserc` (المشروع `nabda-app-ca864`، SPA rewrites)، و`web/index.html` (lang=ar + dir=rtl + عنوان عربي). إصلاح ca9 على الويب (`persistenceEnabled:false`).

#### 71. قرار المصادقة: إلغاء الهاتف + بريد/Google/Facebook/Apple
- **`AUTH_SOCIAL_PLAN.md`** (جديد) يحلّ محلّ `AUTH_HYBRID_PLAN.md` ويُلغيه. **رُفض Clerk/أي طرف ثالث** (يكسر فهرسة `users/{uid}` وقواعد Firestore).
- **`auth_service.dart` أُعيد كتابته:** حذف منطق الهاتف/واتساب/البريد الاصطناعي؛ بريد + كلمة مرور؛ دوال `signInWithGoogle/Facebook/Apple` عبر `signInWithPopup` (ويب) و`signInWithProvider` (موبايل) **بلا حزم إضافية**؛ `_ensureUserDoc`؛ معالجة `account-exists-with-different-credential`.
- **`LoginPage` في `main.dart`:** حقل بريد فقط، أزرار اجتماعية، «نسيت كلمة المرور» بالبريد فقط.
- **TikTok/Instagram خارج النطاق.** المزوّدون يحتاجون تفعيلًا في لوحات Firebase/Meta/Apple ليعملوا فعليًا (الأزرار تظهر لكن تتطلّب الإعداد). القرار محفوظ في ذاكرة Claude.

#### 72. إصلاح تراجع ترقية الأدمن (مشكلة حقيقية)
- **السبب:** `firestore.rules` سمحت للأدمن بقراءة `users` لكن لا بتعديلها لغيره → الكتابة المتفائلة تظهر لحظيًا ثم يرفضها الخادم فتتراجع بعد ثوانٍ.
- **الحل:** `allow update: if isAppOwner();` تحت `users` + تحصين كود الترقية في `admin_panel_screen.dart` (كتابة `staff/` أولًا ثم `users.role` داخل try/catch). **نُشرت القواعد** (`firebase deploy --only firestore:rules`).

#### 73. إطلاق تطبيق المستخدمات على الويب
- بناء `main.dart` للويب (`flutter build web --release -t lib/main.dart`) ونشره — كل ميزات التطبيق تعمل في المتصفّح بنفس الحساب (Firebase موحّد). عنوان الويب وصورة index صارت موجّهة للمستخدمات.

#### 74. قشرة متجاوبة (الويب فقط)
- `MainNav`: `LayoutBuilder` + `kIsWeb` → على ≥900px **شريط جانبي يسار** (أيقونات إيموجي ملوّنة كالتصميم، بطاقة حساب تعرض الاسم/المرحلة، عناصر: الرئيسية/المجتمع/المتجر/الدعم/الحمل/الدورة/الطفل/الخصوبة/الأطباء/صحتي/الحساب/الإعدادات)؛ وعلى الموبايل/الضيّق **التنقّل السفلي** كما هو. **الموبايل ونسخة APK دون أي مساس** (مقيّد بـ `kIsWeb`).

#### 75. تصاميم ويب مخصّصة مطابقة لتصميم claude design
- `lib/web/web_home.dart`: لوحة رئيسية (Hero بحجم الطفل + **صورة الحامل `mom.png`** المجلوبة من مشروع claude design عبر الموصل ومحفوظة في `assets/images/` + شريط علوي + إجراءات سريعة + نصائح + حلقة دورة مصغّرة).
- `lib/web/web_pregnancy.dart`: صفحة حمل (**صورة الجنين لكل أسبوع** من `assets/images/fetus/` + شريط تقدّم بالنسبة + الحجم/الوزن/الطول من جدول بيانات التطبيق + تطوّر الجنين + الجدول الزمني).

#### 76. النموذج الهجين (قرار المستخدِمة)
- الرئيسية والحمل بالتصميم المخصّص؛ **الدورة/الطفل/المتجر = شاشات التطبيق الحقيقية كاملة** داخل الشريط الجانبي → يظهر كل المحتوى بنفس ترابط `lifeStage`. (بُنيت أيضًا `web_cycle.dart`/`web_baby.dart` ثم استُبدلتا بالشاشات الحقيقية حسب اختيار المستخدِمة، وتبقيان كملفّات احتياطية.)

#### 77. دمج المقالات الحقيقية في التصميم الجديد
- الرئيسية: قسم المقالات الحقيقي `_HomeArticlesSection` (ثابت + `dynamic_articles`) + **آخر الأخبار** `_NewsSection`.
- الحمل: **المقالات المخصّصة** `ConditionalContentSection(stage:'pregnant')` (حسب استبيان الدخول: توأم/سكري/خديج/قيصرية) + المقالات العامة. تُمرّر هذه الودجتات الحقيقية كـ `articlesSection` بدل إعادة بنائها، فتظهر كل مقالات الموبايل قابلةً للضغط.

#### 78. صفحة رئيسية عامّة للزوّار (أسلوب babycenter/whattoexpect)
- `lib/web/web_public_home.dart` (جديد): رأس (شعار + روابط الأقسام + «تسجيل الدخول»/«حساب جديد») + Hero + شريط استكشاف + قسم مقالات (المحتوى التحريري الثابت يظهر للزوّار) + شريط دعوة + تذييل.
- **`AuthGate`:** على الويب غير المسجّل → `WebPublicHome`؛ بعد الدخول → الداشبورد المخصّص. تخطّي شاشات التعريف على الويب. `_LoginThenPop` يفتح شاشة الدخول من الصفحة العامّة ويُغلق نفسه تلقائيًا بعد نجاح الدخول.

#### 79. فتح المقالات والمتجر للعموم — **قيد الإنجاز (بناء فاشل، غير منشور)**
- **`firestore.rules`:** قراءة عامّة (`if true`) لـ `articles`/`dynamic_articles`/`specialized_articles`/`products`/`dynamic_products` (**نُشرت**). المجتمع وكل البيانات الشخصية (users/cycles/babies/orders…) تبقى مقفلة بالمصادقة.
- روابط الأقسام في الصفحة العامّة تفتح `WebPublicSection`: الحمل/الطفل/الدورة (ودجتات مقالات معاد استخدامها) + المتجر (`_PublicShop` شبكة منتجات قراءة‑فقط) + المجتمع (دعوة دخول لحماية الخصوصية).
- ⚠️ **`flutter build web` فشل بعد هذه الخطوة** (خطأ تجميع خاص بالويب قيد التشخيص — التحليل `flutter analyze` نظيف 0 أخطاء، لكنّ dart2js يفشل). **لم يُنشر؛ آخر نسخة حيّة هي #78.** الخطوة التالية: تشخيص خطأ التجميع وإصلاحه ثم النشر.

### المتبقّي على الويب
- إصلاح بناء #79 ونشره · ربط `app.nabda.online` (نطاق فرعي عبر Firebase + DNS على Hostinger) · إضافة `admin.nabda.online`/الويب في Firebase Auth → Authorized domains · تفعيل مزوّدي Google/Facebook/Apple · ربط الخصوبة/الأطباء.

---

---

## المرحلة 21: إعلانات الفيديو في الخلاصة + تصميم موقع نبضة الإلكتروني (15–27 يونيو 2026)

### 80. إعلانات الفيديو في الخلاصة (In-Feed Video Ads)

#### التبعيات المضافة (`pubspec.yaml`)
- `video_player: ^2.9.2` — مشغل فيديو HLS/MP4
- `visibility_detector: ^0.4.0+2` — كشف ظهور/اختفاء العنصر في الشاشة

#### ودجت `lib/widgets/feed_video_ad.dart` (FeedVideoAd)
- بطاقة فيديو إعلانية تعمل بنمط إعلانات فيسبوك/إنستا/تيك توك
- **التشغيل التلقائي الصامت:** يبدأ التشغيل (muted + looping) عند ظهور ≥60% من البطاقة، ويوقف عند الاختفاء — عبر `VisibilityDetector`
- **تهيئة كسولة:** `VideoPlayerController` لا يُنشأ حتى يظهر الإعلان لأول مرة (توفيراً للبيانات)
- **تشغيل واحد فقط:** `static ValueNotifier<String?> activeAdIdNotifier` يضمن تشغيل إعلان واحد فقط في آن واحد
- **تجاوز YouTube:** إذا كان `videoType=='youtube'` أو الرابط يحتوي youtube/youtu.be → `SizedBox.shrink()` (حتى تُضاف حزمة youtube_player_flutter لاحقاً)
- **Poster:** يعرض `videoThumbnail` أو أول صورة منتج حتى يجهز الفيديو
- **التراكب (Overlay):**
  - أعلى يسار: زر تخطي ✕ (dismiss)
  - أعلى يمين: شارة «إعلان مميز» وردية
  - أسفل: اسم المنتج + السعر + زر «اطلبي الآن» (تيل) + زر كتم/صوت 🔊/🔇
- **النقر:** يفتح صفحة المنتج عبر `_showFirestoreProductDetail` (يحترم `displayType`)
- **التصميم:** بطاقة بيضاء بزوايا 20px + ظل وردي + تدرج gradient overlay للنص

#### حقول Firestore الجديدة في `products`
```jsonc
{
  "videoUrl": "",              // رابط HLS (.m3u8) أو MP4
  "videoType": "auto",         // "hls" | "mp4" (auto: .m3u8→hls, غيره→mp4)
  "videoThumbnail": "",        // صورة مصغرة (poster)
  "showVideoInFeed": false     // إظهار كإعلان في الخلاصة
}
```

#### لوحة الأدمن — قسم الفيديو الإعلاني (`admin_panel_screen.dart`)
- `ExpansionTile` «فيديو إعلاني» في محرر المنتج
- حقل نص `videoUrl` + قائمة `videoType` (تحديد تلقائي / hls / mp4) — بدون youtube
- رفع `videoThumbnail` (نفس نمط `_uploadImage`)
- مفتاح `showVideoInFeed` (SwitchListTile)
- الاستنتاج التلقائي في `_save()`: `.m3u8` → hls، غيره → mp4

#### الدمج في المتجر (`shop_page.dart`)
- `StreamBuilder` يستعلم `products` حيث `showVideoInFeed==true`
- ترشيح على العميل: `videoUrl` غير فارغ + غير مُستبعد (`_dismissedAdIds`)
- إدراج `FeedVideoAd` بعد كل 3 أقسام في `CustomScrollView`
- `onDismiss`: يضيف للمجموعة المحلية فلا يعود يظهر في الجلسة
- `onTap`: `_showFirestoreProductDetail(context, adProduct)`

#### تحديثات التبعيات (`pubspec.yaml`)
- `google_fonts: ^6.2.1 → ^8.1.0` (API متوافق، تحسينات أداء)
- `sqflite: ^2.4.2 → ^2.4.3` (patch)
- `timezone: ^0.10.0 → ^0.10.1` (patch)
- `image_picker: ^1.1.2 → ^1.2.2` (patch)

### 81. تصميم موقع نبضة الإلكتروني (مواصفات كاملة)

#### مواصفات الموقع المقترح
- **التقنيات:** Next.js 15 (App Router) + TypeScript + Tailwind CSS v4
- **Firebase مشترك:** نفس مشروع `nabda-app-ca864` — نفس الحسابات والبيانات
- **المصادقة المشتركة:** نفس منطق `toAuthEmail` و`normalizePhone` للتوافق بين الويب والتطبيق
- **15 صفحة/قسم:** Landing, Auth, Onboarding (7 خطوات), Dashboard, Pregnancy (14 شاشة فرعية), Cycle, Fertility, Baby, Shop, Community, AI Chat, Doctors, Health, Profile, Admin
- **التصميم:** RTL أولاً + Responsive (sidebar للديسكتوب، bottom nav للموبايل) + Dark Mode + Almarai font + pill buttons + glassmorphism
- **3 لغات:** عربي (افتراضي) / فرنسي / إنجليزي

### 82. صور سلايدر الموقع (6 صور 16:9)

تم إنشاء 6 صور سلايدر احترافية بألوان هوية نبضة (Teal + Pink + Purple):
1. **Hero** — الصفحة الرئيسية (حامل بتدرج أخضر-وردي)
2. **متابعة الحمل** أسبوعاً بأسبوع
3. **مجتمع الأمهات** والدعم
4. **رعاية الطفل** والمولود
5. **الصحة والعافية** وتتبع الدورة
6. **المتجر** — منتجات الأمومة

النصوص المقترحة للسلايدر:
| # | النص | زر CTA |
|---|------|--------|
| 1 | **نبضة** — رفيقتك في رحلة الأمومة | ابدأي الآن |
| 2 | تابعي حملك **أسبوعاً بأسبوع** | اكتشفي المزيد |
| 3 | **مجتمع الأمهات** — شاركي تجربتك | انضمي الآن |
| 4 | **رعاية طفلك** من اليوم الأول | ابدأي التتبع |
| 5 | اعتني بصحتك مع **نبضة** | تعرفي على المميزات |
| 6 | **متجر نبضة** — كل ما تحتاجينه | تسوقي الآن |

### 83. مقالات الوحم للمرأة الحامل (10 مقالات مفيدة ومتنوعة)

تمت كتابة 10 مقالات تفصيلية (أكثر من 300 كلمة لكل مقال) حول الوحم، كره الأطعمة، متلازمة البيكا، وحساسية الروائح، والبدائل الصحية، والجانب النفسي للوحم. المقالات مصممة لتتوافق مع معايير الـ SEO وتصدر محركات البحث، وتم دمجها مباشرة في فئة جديدة باسم `الوحم وأعراضه` في `discover_articles_screen.dart`:
1. **ما هو الوحم علمياً وأسبابه الحقيقية؟** (اقتباس من Mayo Clinic)
2. **اشتهاء الحامض والمالح والحلو: الحقائق والخرافات** (اقتباس من Healthline)
3. **وحم المواد غير الغذائية (متلازمة البيكا) ومخاطرها** (اقتباس من ACOG)
4. **التعامل مع كره الأطعمة والنفور الغذائي أثناء الحمل** (اقتباس من NHS)
5. **الوحم والغثيان الصباحي: كيف تؤثر شهيتك على صحتك؟** (اقتباس من What to Expect)
6. **الوحم النفسي والعاطفي: هل هو مجرد دلع؟** (اقتباس من BabyCenter)
7. **لغة الجسد: هل يعكس الوحم نقصاً في الفيتامينات؟** (اقتباس من Medical News Today)
8. **دليلك للبدائل الصحية لأطعمة الوحم الضارة** (اقتباس من Parents)
9. **وحم الروائح أثناء الحمل: الأسباب وطرق التغلب عليه** (اقتباس من Verywell Family)
10. **متى ينتهي الوحم؟ الجدول الزمني لشهية الحامل ونفورها** (اقتباس من Today's Parent)

### 84. تنفيذ نوادي الولادة والرسائل المباشرة في المجتمع

تمت إضافة البنية التحتية البرمجية والواجهات الكاملة لنظام أندية أشهر الولادة (Birth Clubs) والرسائل المباشرة (Direct Messaging) بين الأمهات:
- **فوج أشهر الولادة (`due_YYYY_MM` و `born_YYYY_MM`)**: نظام حساب آلي وحفظ متزامن وآمن (Firestore Transactions) لزيادة وإنقاص عداد أعضاء كل فوج بمجرد انضمام مستخدمة أو تغيير حالتها.
- **تبويب «ناديي»**: تبويب جديد مدمج بالكامل في شاشة المجتمع الرئيسية لعرض منشورات النادي الخاص للمستخدمة بشكل منفصل ومحمي من النشر العام.
- **إرسال الرسائل المباشرة**: بناء `MessagingService` للرسائل ثنائية الأطراف وتتبع الرسائل غير المقروءة لكل مستخدمة، وتحديث آخر رسالة ووقتها.
- **حارس الحظر والبلاغات**: نظام تأمين يمنع إرسال رسائل إذا كانت المحادثة محظورة من أحد الطرفين، مع إتاحة إمكانية الإبلاغ عن إساءة أو إزعاج للإشراف العام.
- **شاشة قائمة الدردشات وغرف المحادثة**: واجهات RTL مخصصة بتصميم جذاب وثيم التطبيق (Teal + Pink) لعرض قائمة الدردشات الجارية وحوار الدردشة الفورية.
- **قواعد الحماية ومسارات GoRouter**: تأمين الرسائل والمحافظة على خصوصية بيانات الدردشة بملف `firestore.rules` وتسجيل مسارات التوجيه في `routes.dart`.

### 85. مقالات العناية بالطفل لكل فئة عمرية (150 مقالاً متوافقاً مع الـ SEO)

تم إنشاء وتضمين 150 مقالاً تفصيلياً (300+ كلمة لكل مقال) في قسم العناية بالطفل، موزعة على شهور السنة الأولى ثم سنوياً حتى عمر 18 سنة:
- **سكريبت البايثون لتوليد المحتوى (`generate_baby_articles.py`)**: سكريبت مخصص لتوليد مقالات كاملة وغنية بالمعلومات الطبية والتربوية (النمو البدني، التغذية، النوم، الذكاء، والسلامة) باللغة العربية.
- **التصفية الذكية بحسب العمر**: تعديل شاشة مقالات الأطفال في `main.dart` واستيراد `baby_care_age_articles.dart` لتصفية وعرض المقالات بناءً على عمر الطفل الحالي بالأيام (`ageDays`) وتوزيعها تلقائياً على الشهور والسنوات المناسبة.

### المتبقّي
- إصلاح بناء الويب #79 ونشره
- بناء موقع نبضة الإلكتروني (Next.js) حسب المواصفات
- إصلاح `_dismissedAdIds` غير المعرّف في `shop_page.dart`
- اختبار إعلانات الفيديو بفيديو حقيقي (Bunny HLS أو MP4)
- إضافة youtube_player_flutter لدعم YouTube

---

*آخر تحديث: 30 يونيو 2026*
*إعداد: Claude AI / Gemini بناءً على جلسات العمل مع Billel*
