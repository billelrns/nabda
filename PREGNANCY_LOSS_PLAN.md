# خطة: إنهاء/فقدان الحمل والعودة لتتبّع الدورة — لتنفيذ Antigravity

> **الموديل:** Claude Opus 4.6 — **المجلد:** `C:\nabda_app` — **عربي RTL، لا تترجم.**
> **حسّاسية قصوى:** هذه ميزة تمسّ لحظة مؤلمة. **استعمل النصوص العربية الواردة هنا حرفيًا** ولا تُولّد صياغة بديلة. نبرة دافئة، بلا تهنئة في مسار الفقدان، تحكّم كامل للمستخدمة، خصوصية تامّة.
> **القاعدة:** Firebase مصدر الحقيقة. أرشفة بصمت (لا حذف). توافق رجعي.

## الثغرة الحالية
لا توجد وسيلة لإنهاء الحمل إلا تنبيه ما بعد الأسبوع 42 (`_confirmBirth` برسالة «مبروك 🎉») أو تغيير التاريخ. من تفقد حملها مبكرًا تبقى ترى محتوى الحمل — يجب إضافة مسار لطيف متاح دائمًا.

## المراجع في الكود
- تبويب الحمل النشط = `WeekDetailScreen` في `lib/screens/pregnancy/pregnancy_weeks_screen.dart` — له `SliverAppBar` فيه `actions:` (~السطر 537، أيقونتا list_alt و date_range).
- إنهاء الحمل الحالي: `_PregnancyPageState._confirmBirth()` في `lib/main.dart` (~3731) — يمسح `pregnancyStartDate`/`postTermAck` ويعيد للدورة برسالة تهنئة.
- تبويب الدورة يتعامل مع `lastPeriodStart == null` بحالة فارغة (main.dart ~2503 `hasCycle`) — فالعودة للدورة بلا تاريخ آمنة.
- حقول المستخدمة: `lifeStage` ('pregnant'/'baby'/'cycle'/'planning')، `pregnancyStartDate`، `postTermAck`، `lastPeriodStart`، `babyBirthDate`/`babyProfile`.

---

## الخطوة 1: نقطة دخول غير مُلفِتة
في `WeekDetailScreen` ضمن `actions:` (~537) أضِف زرًّا ثالثًا:
```dart
IconButton(
  tooltip: 'تحديث حالة الحمل',
  icon: Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
    child: const Icon(Icons.more_horiz, size: 20),
  ),
  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EndPregnancyScreen())),
),
```

## الخطوة 2: شاشة `EndPregnancyScreen`
ملف جديد `lib/screens/pregnancy/end_pregnancy_screen.dart` (StatefulWidget). RTL، عنوان محايد **«تحديث حالة الحمل»**. ثلاث بطاقات اختيار لطيفة:

1. **«وضعتُ مولودي 🤍»** → `_finish(outcome: 'birth')` ثم الانتقال لرعاية الطفل.
2. **«توقّف الحمل»** → يفتح **مسار الفقدان** (الخطوة 3).
3. **«أفضّل عدم التحديد»** → `_finish(outcome: 'unspecified')` ثم العودة للدورة.

نصّ تمهيدي أعلى الشاشة (حرفيًا):
> «حدّثي حالة حملكِ متى شئتِ. كل خياراتكِ خاصّة بكِ.»

## الخطوة 3: مسار الفقدان (شاشة/بطاقة رحيمة)
عند اختيار «توقّف الحمل» اعرض محتوى دافئًا (بلا تهنئة، بلا إيموجي احتفالي):
- عنوان: **«نحن معكِ 🤍»**
- نص (حرفيًا): «نُؤسفنا لما تمرّين به. خذي وقتكِ في الراحة والتعافي، ولا تترددي في طلب الدعم ممّن تثقين بهم أو من مختصّة. أنتِ لستِ وحدكِ.»
- بطاقة مصدر دعم: زرّ «اقرئي عن التعافي بعد فقدان الحمل» يفتح مقال الدعم (الخطوة 6).
- ثم سؤال **«كيف تحبّين المتابعة؟»** بخيارين (بلا أي اقتراح للحمل مجددًا):
  - **«العودة لتتبّع الدورة»** → `_finish(outcome: 'loss', nextStage: 'cycle')`.
  - **«إيقاف المتابعة مؤقّتًا»** → `_finish(outcome: 'loss', nextStage: 'cycle')` نفسها (تبقى على الدورة بحالتها الفارغة الهادئة؛ لا ضغط).

## الخطوة 4: منطق `_finish` (الأرشفة الصامتة + التحويل)
```dart
Future<void> _finish({required String outcome, String nextStage = 'cycle'}) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;
  final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
  final snap = await userRef.get();
  final d = snap.data() ?? {};
  // أرشفة صامتة (لا حذف)
  await userRef.collection('pregnancyHistory').add({
    'startDate': d['pregnancyStartDate'],
    'endDate': FieldValue.serverTimestamp(),
    'outcome': outcome, // 'birth' | 'loss' | 'unspecified'
    'archivedAt': FieldValue.serverTimestamp(),
  });
  // المرحلة التالية
  final stage = outcome == 'birth' ? 'baby' : nextStage; // الفقدان/غير المحدّد → cycle
  final update = <String, dynamic>{
    'pregnancyStartDate': null,
    'postTermAck': null,
    'lifeStage': stage,
  };
  if (outcome == 'birth') {
    update['babyBirthDate'] = FieldValue.serverTimestamp(); // قابل للتعديل لاحقًا
  }
  // ملاحظة: لا تضبط lastPeriodStart عند الفقدان — تُسجّلها المستخدمة عند عودة دورتها.
  await userRef.set(update, SetOptions(merge: true));
}
```
بعد الحفظ:
- **الفقدان/غير محدّد:** انتقل لتبويب الدورة، واعرض SnackBar لطيف: «سجّلي بداية دورتكِ عندما تعود 🤍».
- **الولادة:** انتقل لرعاية الطفل برسالة تهنئة لطيفة.

> إيقاف محتوى الحمل يحدث تلقائيًا لأن `PregnancyPage` يتحقّق من `pregnancyStartDate != null`. لا حاجة لإجراء إضافي.

## الخطوة 5: إصلاح جانبي لـ `_confirmBirth`
حاليًا `_confirmBirth` (تنبيه ما بعد 42 أسبوعًا) يعيد للدورة. الأصحّ: الولادة → رعاية الطفل (`lifeStage='baby'` + `babyBirthDate=now` + أرشفة كـ outcome 'birth'). وحّد منطقه مع `_finish` أعلاه إن أمكن.

## الخطوة 6: مقال دعم
أضِف مقالًا لطيفًا (≥300 كلمة، عربي، مع تنويه أنه ليس بديلًا عن استشارة مختصّة) بعنوان «التعافي بعد فقدان الحمل: جسديًا ونفسيًا» في `lib/data/specialized_articles.dart` تحت موضوع جديد `loss`، أو كمقال مستقل يُفتح من مسار الفقدان. يشمل: طبيعية مشاعر الحزن، طلب الدعم، متى تُراجع الطبيبة، وأن عودة الدورة تختلف من امرأة لأخرى (غالبًا 4–6 أسابيع).

---

## التحقّق والبناء والرفع
```bash
flutter analyze            # 0 errors
flutter build apk --release && copy build\app\outputs\flutter-apk\app-release.apk nabda.apk
git add -A && git commit -m "feat(pregnancy): مسار إنهاء/فقدان الحمل الرحيم + العودة لتتبّع الدورة" && git push origin main
```

## اختبارات القبول
1. تبويب الحمل → ⋮ «تحديث حالة الحمل» → «توقّف الحمل» → تظهر الرسالة الرحيمة (بلا تهنئة) + مصدر الدعم.
2. «العودة لتتبّع الدورة» → التطبيق ينتقل لتبويب الدورة بحالته الفارغة («سجّلي دورتكِ»)، ويختفي كل محتوى الحمل فورًا، **بلا تنبؤات دورة خاطئة** (lastPeriodStart يبقى فارغًا).
3. وثيقة أُضيفت في `users/{uid}/pregnancyHistory` بـ outcome صحيح (الأرشفة الصامتة).
4. «وضعتُ مولودي» → ينتقل لرعاية الطفل (لا للدورة).
5. منتج الحمل القديم بلا الحقول الجديدة لا يتعطّل.

## قيود ونبرة
- **النصوص الرحيمة حرفيًا كما هنا**؛ لا تهنئة ولا إيموجي احتفالي في مسار الفقدان.
- لا تُجبر المستخدمة على ذكر السبب ولا على تاريخ.
- أرشفة لا حذف؛ لا تمسح `pregnancyHistory`.
- لا تقترح «المحاولة مجددًا» في لحظة الفقدان إطلاقًا.
- بعد كل عمل: analyze نظيف ثم بناء APK ونسخه إلى `nabda.apk` ورفع Git.
