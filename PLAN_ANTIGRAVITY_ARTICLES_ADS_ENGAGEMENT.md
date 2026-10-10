# خطة تنفيذ لـ Antigravity — تدقيق المقالات + مواضع الإعلانات + أزرار الإعجاب والمشاركة

**المشروع:** `C:\nabda_app` — تطبيق نبضة (Flutter + Firebase، عربي RTL)
**الهدف:** ثلاث مهام مترابطة يجب تنفيذها بالترتيب.

> ⚠️ **قواعد إلزامية قبل البدء**
> 1. **لا تعدّل** `lib/utils/article_images.dart` ولا `lib/utils/article_image_map.g.dart` ولا `assets/data/news_images.json` — نظام الصور مكتمل ومضبوط، وأي تعديل سيكسر ربط 400+ صورة.
> 2. **لا تنشئ ملفات `.bat` بترميز عربي** — cmd على هذا الجهاز يفشل مع `chcp 65001` + نص عربي. اكتب سكربتات بالإنجليزية فقط.
> 3. الجهاز 7 غيغا رام — **لا تشغّل `flutter build` مع فتح متصفّح**. إعدادات Gradle مضبوطة في `android/gradle.properties` (لا تغيّرها).
> 4. بعد كل مهمة: `flutter analyze` ويجب ألا تزيد الأخطاء عن الحالة الأساسية.

---

# المهمة ١ — جرد شامل لكل شاشات المقالات

## المطلوب
أنشئ ملف `AUDIT_ARTICLES.md` في جذر المشروع يحوي جدولاً بكل شاشة تعرض مقالاً، بالأعمدة:

| الملف | السطر | اسم الكلاس | مصدر المحتوى | صورة الرأس | عدد مواضع الإعلان | زر إعجاب | زر مشاركة |

## الشاشات المعروفة (تحقّق منها وأضف ما تجده غيرها)

| # | الكلاس | الملف | السطر تقريباً | الحالة المرصودة |
|---|---|---|---|---|
| 1 | `_ArticleDetailPage` | `lib/main.dart` | 6833 | ✅ 3 مواضع إعلان (`_adSlot`) — ❌ بلا إعجاب/مشاركة |
| 2 | `NameArticleDetailScreen` | `lib/widgets/names_articles_carousel.dart` | 326 | ❌ **بلا إعلانات إطلاقاً** — ❌ بلا إعجاب/مشاركة |
| 3 | `BabyNameArticleDetailScreen` | `lib/screens/baby_names/baby_names_screen.dart` | 1062 | ❌ **بلا إعلانات** — ❌ بلا إعجاب/مشاركة |
| 4 | `_DiscoverDetailScreen` | `lib/screens/pregnancy/pregnancy_weeks_screen.dart` | 2907 | ❌ بلا إعلانات داخل النص |
| 5 | `_ArticleDetailScreen` | `lib/screens/pregnancy/pregnancy_weeks_screen.dart` | 2209 | ❌ بلا إعلانات داخل النص |
| 6 | `_DiscoverArticleDetailScreen` | `lib/screens/pregnancy/discover_articles_screen.dart` | 779 | ❌ إعلان واحد خارج النص فقط (سطر 1018) |
| 7 | `WeekDetailScreen` | `lib/screens/pregnancy/pregnancy_weeks_screen.dart` | 502 | ❌ بلا إعلانات — البطاقات منسدلة |
| 8 | `_LossSupportArticleScreen` | `lib/screens/pregnancy/end_pregnancy_screen.dart` | 362 | ⚠️ **استثناء — ممنوع وضع إعلانات** (محتوى فقدان الحمل) |
| 9 | شاشة مقال داخل `news_section.dart` | `lib/widgets/news_section.dart` | ~440 | ✅ 3 مواضع — ❌ بلا إعجاب/مشاركة |
| 10 | `conditional_content.dart` (المقالات المتخصّصة) | `lib/widgets/conditional_content.dart` | ~404 | ✅ 3 مواضع — ❌ بلا إعجاب/مشاركة |

## طريقة البحث
```
grep -rn "class .*Detail.*Screen\|class .*ArticleDetail" lib/
grep -rn "NabdaAd(\|NabdaArticleAd(\|_adSlot(" lib/
```

---

# المهمة ٢ — توحيد مواضع الإعلانات في كل المقالات

## الويدجت الجاهزة (لا تنشئ بديلاً)
`lib/widgets/nabda_article_ad.dart` → `NabdaArticleAd`

```dart
NabdaArticleAd(
  slot: 0,                    // 0 أو 1 أو 2 — يمنع تكرار نفس الإعلان
  articleId: <معرّف فريد للمقال>,
  section: 'pregnancy',       // home / pregnancy / baby / cycle / news
  articleTitle: <العنوان>,
  articleBody: <النص الكامل>, // ضروري لمطابقة المنتج بموضوع المقال
  color: <لون الشاشة>,
)
```

سلوكها: AdMob (معطّل حالياً) ← إعلان نبضة من Firestore ← منتج مطابق للموضوع ← **تختفي تماماً** إن لم يوجد شيء. لا تضف شارة «إعلان» يدوياً — الويدجت تعرضها بنفسها.

## قاعدة التوزيع الموحّدة (طبّقها في كل شاشة)

| الموضع | المكان | الشرط |
|---|---|---|
| `slot: 0` | بعد الفقرة الثانية | عدد الفقرات > 3 |
| `slot: 1` | منتصف المقال | عدد الفقرات > 5 |
| `slot: 2` | نهاية المقال قبل قسم المنتجات | دائماً |

مرجع التنفيذ الصحيح: `lib/main.dart` داخل `_ArticleDetailPage` (ابحث عن `_adSlot(0)`).

## المطلوب لكل شاشة من ١ إلى ٧ و٩ و١٠
1. استورد `package:nabda_app/widgets/nabda_article_ad.dart`
2. قسّم النص إلى فقرات بـ `body.split('\n\n')` — إن لم يحوِ النص فواصل مزدوجة استخدم التقسيم الذكي بالجُمل الموجود في `_ArticleDetailPage`
3. أدرج المواضع الثلاثة حسب الجدول
4. **`articleId` يجب أن يكون فريداً وثابتاً** لكل مقال (استخدم العنوان نفسه إن لم يوجد معرّف)

### تنبيه خاص — مقالات دليل الأسماء (الشاشتان ٢ و٣)
هاتان أكثر الشاشات زيارةً وبلا إعلانات إطلاقاً. `NameArticleDetailScreen` يعرض الفقرات في حلقة `for (final p in paras)` — حوّلها إلى حلقة مفهرسة `for (int i = 0; i < paras.length; i++)` وأدرج المواضع.

### استثناء إلزامي
`_LossSupportArticleScreen` (فقدان الحمل) — **ممنوع منعاً باتاً وضع أي إعلان أو منتج فيها**. أضف تعليقاً في الكود يوضّح السبب.

---

# المهمة ٣ — أزرار الإعجاب والمشاركة في كل المقالات

## ٣-أ إضافة حزمة المشاركة
في `pubspec.yaml` تحت `dependencies:`
```yaml
  share_plus: ^10.1.4
```
ثم `flutter pub get`.

## ٣-ب أنشئ ويدجت موحّدة جديدة
**ملف جديد:** `lib/widgets/article_engagement_bar.dart`

### المتطلبات
```dart
class ArticleEngagementBar extends StatefulWidget {
  final String articleId;      // معرّف ثابت وفريد
  final String articleTitle;
  final String section;
  final Color color;
}
```

### السلوك
- **زر الإعجاب:** قلب ممتلئ/مفرّغ + عدّاد. عند الضغط:
  - يبدّل الحالة **فوراً في الواجهة** (تفاؤلياً) ثم يكتب إلى Firestore
  - المسار: `users/{uid}/liked_articles/{articleId}` → `{likedAt, title, section}`
  - العدّاد العام: `article_stats/{articleId}` → `{likes: FieldValue.increment(±1), title, section}`
  - **معاملة (transaction) أو increment ذرّي** لتفادي تضارب العدّاد
  - إن كانت المستخدمة غير مسجّلة الدخول: أظهري SnackBar «سجّلي الدخول لحفظ إعجابك» ولا تكتبي شيئاً
- **زر المشاركة:** `Share.share('$articleTitle\n\nاقرئي المقال في تطبيق نبضة 💗\nhttps://nabda.online')`
  - سجّلي الحدث: `article_stats/{articleId}` → `{shares: FieldValue.increment(1)}`
- **زر الحفظ (اختياري لكن مستحسن):** أيقونة إشارة مرجعية → `users/{uid}/saved_articles/{articleId}`

### التصميم
- صف أفقي، خلفية بيضاء، حواف 16، حدّ رفيع بلون الشاشة بشفافية 0.15
- RTL، خط Almarai (موروث من الثيم)
- الحالة الأولية تُقرأ مرّة واحدة في `initState` بـ `FutureBuilder` أو `didChangeDependencies`
- ارتفاع ~56، هوامش رأسية 12

## ٣-ج الإدراج
أضف `ArticleEngagementBar` في **كل الشاشات من ١ إلى ١٠ بلا استثناء** (نعم بما فيها شاشة فقدان الحمل — الإعجاب والمشاركة مسموحان، الممنوع هو الإعلانات فقط).

**الموضع:** بعد نهاية نص المقال ومباشرة **قبل** `slot: 2` الإعلاني.

## ٣-د شاشة «مقالاتي المحفوظة» (اختياري — نفّذها إن بقي وقت)
شاشة تقرأ `users/{uid}/liked_articles` و`saved_articles` وتعرضها ببطاقات تستعمل `ArticleImage`.
اربطها من تبويب «حسابي».

---

# قواعد Firestore المطلوبة

أضف إلى `firestore.rules`:
```
match /article_stats/{articleId} {
  allow read: if true;
  allow write: if request.auth != null;
}
match /users/{uid}/liked_articles/{articleId} {
  allow read, write: if request.auth != null && request.auth.uid == uid;
}
match /users/{uid}/saved_articles/{articleId} {
  allow read, write: if request.auth != null && request.auth.uid == uid;
}
```

---

# معايير القبول

- [ ] `AUDIT_ARTICLES.md` منشأ ويحوي كل الشاشات مع أرقام أسطر صحيحة
- [ ] كل شاشة مقال (عدا شاشة فقدان الحمل) فيها **3 مواضع إعلانية** موزّعة حسب القاعدة
- [ ] مقالات دليل الأسماء (الشاشتان ٢ و٣) صار فيها إعلانات — **هذا هو أهم بند**
- [ ] `ArticleEngagementBar` موجودة في **كل** شاشات المقالات
- [ ] الإعجاب يعمل بلا اتصال ويتزامن لاحقاً (تفاؤلي)
- [ ] المشاركة تفتح ورقة المشاركة الأصلية للنظام
- [ ] `flutter analyze` بلا أخطاء جديدة
- [ ] التطبيق يبني ويعمل: `flutter run`
- [ ] لم يُمسّ أي ملف من ملفات نظام الصور المذكورة في القواعد الإلزامية

---

# ملاحظات معمارية مهمة

1. **يوجد `_NewsSection` مكرّر:** واحد في `lib/main.dart` (~8591) وآخر في `lib/widgets/news_section.dart`. إصلاح أحدهما لا يصلح الآخر — عدّل الاثنين.
2. **نظام الصور يعمل بالعنوان لا بالرابط:** لا تمرّر روابط صور يدوياً، استعمل `ArticleImage(title: ..., section: ...)`.
3. **تواريخ الحمل موحّدة** في `lib/services/pregnancy_dates_service.dart` — لا تقرأ `pregnancyWeek` أو `lastPeriodDate` (حقول ملغاة).
4. **حجم الجنين والفاكهة** من `lib/utils/fetus_size.dart` حصراً.
5. AdMob جاهز ومعطّل بمفتاح `AdMobService.enabled = false` — لا تفعّله، المستخدم سيفعّله بنفسه.
