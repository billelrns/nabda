# خطة إعلانات الفيديو في الخلاصة (In-Feed Video Ads) — لتنفيذ Antigravity

> **الموديل:** Claude Opus 4.6 — **المجلد:** `C:\nabda_app` — **عربي RTL، لا تترجم النصوص.**
> **القاعدة:** Firebase مصدر الحقيقة. الحقول الجديدة اختيارية ومتوافقة رجعيًا.
> **الاستضافة مؤجَّلة:** البنية مرنة عبر حقل `videoUrl` عام يدعم **HLS (.m3u8) أو MP4 أو YouTube** — تُختار الاستضافة لاحقًا بتغيير الرابط فقط.

## الفكرة (نمط الإعلان الأصلي في الخلاصة)
أثناء تصفّح المتجر تظهر **بطاقة فيديو إعلانية** لمنتج: تعمل تلقائيًا **صامتة** عند ظهورها، فيها زرّ **تخطّي ✕**، وزرّ كتم/صوت 🔊، و**النقر عليها يفتح صفحة المنتج** (هبوط أو عادية حسب `displayType`). تُحاكي إعلانات فيس/إنستا/تيك توك.

## المراجع في الكود
- محرّر المنتج: `lib/screens/admin/admin_panel_screen.dart` → `_AddProductScreen` (~1126). نمط رفع الصور `_uploadImage`.
- المتجر وفتح المنتج: `lib/screens/shop/shop_page.dart` → `_showFirestoreProductDetail` (يوجّه لـ `LandingProductScreen` عند `displayType=='landing'`). قائمة المنتجات في باني `ListView/Grid`.
- المجموعة: `products`.

---

## الحقول الجديدة في وثيقة `products`
```jsonc
{
  "videoUrl": "",            // رابط الفيديو: HLS (.m3u8) أو MP4 مباشر أو رابط YouTube
  "videoType": "hls",        // "hls" | "mp4" | "youtube" (افتراضي hls/mp4 حسب الرابط)
  "videoThumbnail": "",       // صورة مصغّرة (poster) تُعرض قبل التشغيل — اختيارية
  "showVideoInFeed": false   // إظهار هذا الفيديو كإعلان في الخلاصة؟
}
```

---

## المرحلة 1 — محرّر الأدمن (`_AddProductScreen`)
أضِف قسمًا قابلًا للطي **«فيديو إعلاني»** يحوي:
- حقل نصّي `videoUrl` (لصق رابط الفيديو) + تلميح «الصق رابط Bunny HLS أو MP4 أو YouTube».
- قائمة `videoType` (hls/mp4/youtube) — أو استنتاجها تلقائيًا: يحوي `youtube`/`youtu.be` → youtube؛ ينتهي بـ `.m3u8` → hls؛ غير ذلك → mp4.
- رفع `videoThumbnail` (صورة، عبر `_uploadImage` نفس النمط) — اختياري.
- مفتاح `showVideoInFeed`.
- اكتب الحقول الأربعة في خريطة `data` في `_save()` مع باقي الحقول.

**تحقّق:** `flutter analyze` = 0 errors.

---

## المرحلة 2 — مشغّل الفيديو وبطاقة الإعلان (المستخدِمة)
### التبعيات (`pubspec.yaml`)
```yaml
  video_player: ^2.9.2
  visibility_detector: ^0.4.0+2
  # عند اختيار YouTube لاحقًا: youtube_player_flutter (مسار اختياري)
```
ثم `flutter pub get`.

### الودجت `lib/widgets/feed_video_ad.dart` → `FeedVideoAd`
- يأخذ `Map<String,dynamic> product` (يحوي videoUrl/videoType/videoThumbnail + بيانات المنتج).
- بطاقة عمودية (9:16 أو 16:9 حسب الفيديو) داخل المتجر.
- **التشغيل التلقائي بالظهور:** غلّف بـ `VisibilityDetector`؛ شغّل (muted, looping) عند ظهور ≥60%، وأوقف عند الاختفاء — توفيرًا للبيانات والأداء.
- اعرض `videoThumbnail` (أو أول صورة منتج) كـ poster حتى يجهز التشغيل.
- للمسار العام (hls/mp4): استعمل `VideoPlayerController.networkUrl` (يدعم HLS على أندرويد/iOS). لمسار youtube لاحقًا: فرع منفصل بـ `youtube_player_flutter`.
- **التراكب (Overlay):**
  - أعلى يمين: زرّ **تخطّي ✕** → يستدعي callback لإخفاء هذا الإعلان (أضِفه إلى مجموعة `dismissed` في حالة الشاشة فلا يعود أثناء الجلسة).
  - أسفل يمين: زرّ **🔊/🔇** لكتم/إلغاء كتم الصوت.
  - شارة «إعلان» صغيرة + اسم المنتج وسعره + زرّ **«اطلبي الآن»**.
  - **النقر على البطاقة أو الزرّ** → افتح المنتج بنفس منطق `_showFirestoreProductDetail` (يحترم `displayType`: هبوط/عادية). مرّر `product` كاملًا مع `id`.

### الإدراج في الخلاصة (`shop_page.dart`)
- استعلم عن المنتجات حيث `showVideoInFeed == true && videoUrl != ''` (أو رشّحها على العميل من قائمة المنتجات الحالية).
- أدرِج بطاقة `FeedVideoAd` في قائمة المتجر **بعد كل ~6 منتجات** (أو شريطًا أعلى القائمة)، مع تخطّي الإعلانات المُستبعَدة (`dismissed`).
- شغّل **فيديو واحد فقط في الوقت ذاته** (أوقف البقية) لتفادي تعدّد التشغيل.

**تحقّق:** analyze نظيف + تجربة بطاقة فيديو تعمل صامتة، تتخطّى، وتفتح صفحة المنتج.

---

## المرحلة 3 (اختيارية لاحقًا)
- فيديو في **رأس صفحة الهبوط/المنتج** (تشغيل تلقائي صامت + نقرة لإلغاء الكتم).
- إعداد **«موفّر البيانات»**: تعطيل التشغيل التلقائي على بيانات الهاتف.
- مسار YouTube الكامل عند اختيار تلك الاستضافة.

---

## التحقّق والبناء والرفع (بعد كل مرحلة)
```bash
flutter analyze            # 0 errors
flutter build apk --release && copy build\app\outputs\flutter-apk\app-release.apk nabda.apk
git add -A && git commit -m "feat(ads): <وصف المرحلة>" && git push origin main
```

## خطوات يدوية (بعد اختيار الاستضافة)
- **Bunny:** أنشئي Video Library، ارفعي الفيديو، انسخي رابط `.../playlist.m3u8`، الصقيه في حقل `videoUrl` بالأدمن.
- **YouTube:** ارفعي الفيديو unlisted، الصقي الرابط (يتطلّب لاحقًا حزمة youtube_player_flutter).
- **Firebase Storage:** ارفعي MP4، الصقي رابط التنزيل (الأبسط للتجربة، الأغلى للتوسّع).

## قيود
- توافق رجعي: الحقول اختيارية؛ المنتجات بلا فيديو لا تتأثّر.
- فيديو صامت افتراضيًا، poster قبل التشغيل، تشغيل واحد فقط في آن، إيقاف عند الاختفاء.
- لا تكسر منطق `_showFirestoreProductDetail` ولا توجيه `displayType`؛ أعِد استخدامه.
- بعد كل مرحلة: analyze نظيف ثم بناء APK ونسخه إلى `nabda.apk` ورفع Git.
