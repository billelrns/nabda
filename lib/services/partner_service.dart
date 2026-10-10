import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pregnancy_dates_service.dart';

/// ═══════════════════════════════════════════════════════════════════
///  وضع الأب — اقتران الزوجين ومزامنة اللقطة المشتركة
///
///  🔒 مبدأ الخصوصية (مهم جداً عند أي تعديل مستقبلي):
///  الزوج **لا يقرأ أبداً** من `users/{uid}` الخاصّة بالزوجة — قواعد
///  Firestore تمنع ذلك مطلقاً. تطبيق الزوجة هو من يدفع **لقطة منقّاة**
///  إلى `couples/{id}/shared/pregnancy` و`.../shared/baby`.
///  ❌ لا تُنسخ بيانات الدورة الشهرية إلى هذه اللقطة إطلاقاً.
///
///  شجرة البيانات:
///    couples/{CODE}
///      motherUid, motherName, partnerUid, partnerName,
///      status: 'pending' | 'linked', createdAt, expiresAt, linkedAt
///      shared/pregnancy  { dueDate, lmp, week, daysLeft, updatedAt }
///      shared/baby       { babyName, birthDate, last7: {...}, updatedAt }
///      lists/{listId}    { type, items[] }
///      names/{nameId}    { name, gender, motherLike, partnerLike }
/// ═══════════════════════════════════════════════════════════════════
class PartnerService {
  PartnerService._();

  static const String roleMother = 'mother';
  static const String rolePartner = 'partner';

  /// مدّة صلاحية كود الدعوة
  static const Duration codeTtl = Duration(hours: 48);

  /// أحرف الكود: بلا O/0/I/1 لتفادي الخلط عند النطق أو الكتابة
  static const String _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static CollectionReference<Map<String, dynamic>> get _couples =>
      _db.collection('couples');

  // ══════════════════════════════════════════════════════════
  //  الدور المحلّي (يُقرأ قبل أول بناء للواجهة)
  // ══════════════════════════════════════════════════════════

  static const String _kRoleKey = 'user_role';
  static const String _kCoupleKey = 'couple_id';

  static Future<String> localRole() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kRoleKey) ?? roleMother;
  }

  static Future<void> setLocalRole(String role) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kRoleKey, role);
  }

  static Future<String?> localCoupleId() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kCoupleKey);
  }

  static Future<void> _cacheCoupleId(String? id) async {
    final p = await SharedPreferences.getInstance();
    if (id == null) {
      await p.remove(_kCoupleKey);
    } else {
      await p.setString(_kCoupleKey, id);
    }
  }

  /// يمسح أثر الاقتران والدور عند تسجيل الخروج
  static Future<void> clearLocal() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kRoleKey);
    await p.remove(_kCoupleKey);
  }

  // ══════════════════════════════════════════════════════════
  //  إنشاء الدعوة (من طرف الزوجة)
  // ══════════════════════════════════════════════════════════

  static String _newCode() {
    final r = Random.secure();
    return List.generate(6, (_) => _alphabet[r.nextInt(_alphabet.length)]).join();
  }

  /// تُنشئ كود دعوة جديداً وتُلغي أيّ دعوة معلّقة سابقة لنفس الزوجة.
  /// تُعيد الكود، أو رسالة الخطأ الحقيقية عند الفشل.
  static Future<({String? code, String? error})> createInvite(
      {required String motherName}) async {
    final uid = _uid;
    if (uid == null) return (code: null, error: 'سجّلي الدخول أولاً');

    // ألغِ الدعوة المعلّقة السابقة حتى لا تبقى أكواد سارية متعدّدة
    final existing = await currentCoupleId();
    if (existing != null) {
      try {
        final snap = await _couples.doc(existing).get();
        if ((snap.data()?['status'] as String?) == 'pending') {
          await _couples.doc(existing).delete();
        }
      } catch (_) {/* تجاهل */}
    }

    // محاولات قليلة لتفادي تصادم نادر في الكود.
    //
    // ⚠️ لا تُضف فحصاً مسبقاً بـ `ref.get()` هنا: القراءة على وثيقة غير
    //    موجودة تجعل `resource` يساوي null فتفشل قاعدة الأمان وتُرجع
    //    PERMISSION_DENIED، فيستحيل إنشاء أي كود إطلاقاً.
    //    التصادم (1 من مليار) تمنعه القواعد نفسها: الكتابة فوق دعوة
    //    قائمة تُعدّ `update` وتُرفض، فننتقل تلقائياً إلى كود آخر.
    String? lastError;
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = _newCode();
      final ref = _couples.doc(code);
      try {
        await ref.set({
          'motherUid': uid,
          'motherName': motherName,
          'partnerUid': null,
          'partnerName': null,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'expiresAt': Timestamp.fromDate(DateTime.now().add(codeTtl)),
        });
        await _db.collection('users').doc(uid).set({
          'coupleId': code,
          'role': roleMother,
        }, SetOptions(merge: true));
        await _cacheCoupleId(code);
        await setLocalRole(roleMother);
        return (code: code, error: null);
      } on FirebaseException catch (e) {
        lastError = e.code == 'permission-denied'
            ? 'القواعد ترفض الإنشاء — انشري firestore.rules'
            : 'خطأ Firestore: ${e.code}';
        debugPrint('createInvite [$attempt] ${e.code}: ${e.message}');
        // permission-denied لن يُحلّ بإعادة المحاولة
        if (e.code == 'permission-denied') break;
      } catch (e) {
        lastError = 'تعذّر الاتصال';
        debugPrint('createInvite [$attempt] $e');
      }
    }
    return (code: null, error: lastError ?? 'تعذّر إنشاء الكود');
  }

  // ══════════════════════════════════════════════════════════
  //  استرداد الدعوة (من طرف الزوج)
  // ══════════════════════════════════════════════════════════

  /// يقرأ الدعوة للتحقّق قبل القبول — يُعيد اسم الزوجة أو رسالة خطأ.
  static Future<({bool ok, String message, String? motherName})> previewInvite(
      String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    if (code.length != 6) {
      return (ok: false, message: 'الكود يتكوّن من 6 خانات', motherName: null);
    }
    try {
      final snap = await _couples.doc(code).get();
      final d = snap.data();
      if (!snap.exists || d == null) {
        return (ok: false, message: 'كود غير صحيح', motherName: null);
      }
      if (d['status'] != 'pending') {
        return (ok: false, message: 'هذا الكود مُستعمل من قبل', motherName: null);
      }
      final exp = (d['expiresAt'] as Timestamp?)?.toDate();
      if (exp != null && exp.isBefore(DateTime.now())) {
        return (ok: false, message: 'انتهت صلاحية الكود — اطلب كوداً جديداً', motherName: null);
      }
      if (d['motherUid'] == _uid) {
        return (ok: false, message: 'هذا كودك أنت', motherName: null);
      }
      return (ok: true, message: '', motherName: d['motherName'] as String?);
    } catch (_) {
      return (ok: false, message: 'تعذّر التحقّق — تأكّد من الاتصال', motherName: null);
    }
  }

  /// يقبل الدعوة ويربط الحسابين.
  static Future<({bool ok, String message})> acceptInvite(
    String rawCode, {
    required String partnerName,
  }) async {
    final uid = _uid;
    if (uid == null) return (ok: false, message: 'سجّل الدخول أولاً');

    final code = rawCode.trim().toUpperCase();
    final check = await previewInvite(code);
    if (!check.ok) return (ok: false, message: check.message);

    try {
      await _couples.doc(code).update({
        'partnerUid': uid,
        'partnerName': partnerName,
        'status': 'linked',
        'linkedAt': FieldValue.serverTimestamp(),
      });
      await _db.collection('users').doc(uid).set({
        'coupleId': code,
        'role': rolePartner,
      }, SetOptions(merge: true));
      await _cacheCoupleId(code);
      await setLocalRole(rolePartner);
      return (ok: true, message: 'تم الربط بنجاح');
    } catch (_) {
      return (ok: false, message: 'تعذّر الربط — ربما قُبلت الدعوة للتو');
    }
  }

  // ══════════════════════════════════════════════════════════
  //  حالة الاقتران
  // ══════════════════════════════════════════════════════════

  static Future<String?> currentCoupleId() async {
    final cached = await localCoupleId();
    if (cached != null) return cached;
    final uid = _uid;
    if (uid == null) return null;
    try {
      final snap = await _db.collection('users').doc(uid).get();
      final id = snap.data()?['coupleId'] as String?;
      if (id != null) await _cacheCoupleId(id);
      return id;
    } catch (_) {
      return null;
    }
  }

  /// بثّ مباشر لوثيقة الاقتران (لإظهار «بانتظار القبول» ثم «مرتبطان»).
  static Stream<CoupleLink?> watchCouple(String coupleId) =>
      _couples.doc(coupleId).snapshots().map((s) {
        final d = s.data();
        if (!s.exists || d == null) return null;
        return CoupleLink.fromMap(coupleId, d);
      });

  /// فكّ الارتباط نهائياً — يحذف اللقطة والقوائم والأسماء **قبل** الوثيقة الأمّ.
  ///
  /// ⚠️ ترتيب الحذف مقصود: قواعد الأمان للمجموعات الفرعية تعتمد على
  /// `get()` للوثيقة الأمّ، فلو حُذفت أوّلاً لأصبحت البيانات الفرعية
  /// غير قابلة للحذف وبقيت يتيمة في قاعدة البيانات إلى الأبد.
  static Future<void> unlink(String coupleId) async {
    final uid = _uid;
    final root = _couples.doc(coupleId);

    try {
      final batch = _db.batch();
      batch.delete(root.collection('shared').doc('pregnancy'));
      batch.delete(root.collection('shared').doc('baby'));
      batch.delete(root.collection('lists').doc('hospital_bag'));
      batch.delete(root.collection('lists').doc('baby_prep'));
      await batch.commit();
    } catch (_) {/* أفضل-جهد */}

    // الأسماء قد تكون كثيرة — تُحذف على دفعات
    try {
      final names = await root.collection('names').limit(400).get();
      for (var i = 0; i < names.docs.length; i += 400) {
        final b = _db.batch();
        for (final d in names.docs.skip(i).take(400)) {
          b.delete(d.reference);
        }
        await b.commit();
      }
    } catch (_) {/* أفضل-جهد */}

    try {
      await root.delete();
    } catch (_) {/* قد يكون محذوفاً مسبقاً */}
    if (uid != null) {
      try {
        await _db.collection('users').doc(uid).set({
          'coupleId': FieldValue.delete(),
        }, SetOptions(merge: true));
      } catch (_) {/* تجاهل */}
    }
    await _cacheCoupleId(null);
  }

  // ══════════════════════════════════════════════════════════
  //  مزامنة اللقطة — يستدعيها تطبيق الزوجة فقط
  // ══════════════════════════════════════════════════════════

  /// يدفع لقطة الحمل المنقّاة. آمن للاستدعاء المتكرّر (عند فتح التطبيق
  /// وبعد كل تعديل لتاريخ الولادة).
  ///
  /// ⚠️ لا تُضف هنا أيّ حقل من بيانات الدورة الشهرية.
  static Future<void> pushPregnancySnapshot() async {
    final uid = _uid;
    if (uid == null) return;
    final coupleId = await currentCoupleId();
    if (coupleId == null) return;

    try {
      final userSnap = await _db.collection('users').doc(uid).get();
      final data = userSnap.data() ?? {};
      final dates = PregnancyDates.fromUserData(data);
      if (!dates.isActive) return;

      await _couples.doc(coupleId).collection('shared').doc('pregnancy').set({
        'week': dates.week,
        'dayOfWeek': dates.dayOfWeek,
        'daysLeft': dates.daysLeft,
        'trimester': dates.trimester,
        'dueDate': dates.effectiveDueDate == null
            ? null
            : Timestamp.fromDate(dates.effectiveDueDate!),
        // ⛔ لا تُضف `startDate` هنا: بداية الحمل هي تاريخ آخر دورة (LMP)
        //    أي أنها بيانات دورة شهرية صريحة. الأسبوع وتاريخ الولادة
        //    يكفيان الزوج تماماً دون كشف ذلك.
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {/* المزامنة أفضل-جهد ولا تُعطّل التطبيق */}
  }

  /// يدفع لقطة الطفل: الاسم وتاريخ الميلاد وسجلّ آخر 7 أيام.
  static Future<void> pushBabySnapshot() async {
    final uid = _uid;
    if (uid == null) return;
    final coupleId = await currentCoupleId();
    if (coupleId == null) return;

    try {
      final userRef = _db.collection('users').doc(uid);
      final userSnap = await userRef.get();
      final data = userSnap.data() ?? {};

      final today = DateTime.now();
      final wanted = List.generate(
          7, (i) => DateTime(today.year, today.month, today.day - (6 - i)));
      // بعد الترحيل يصبح المصدر هو ملكية الزوجين لا ملكية الزوجة
      final logsCol = coupleBabyLogs(coupleId);
      final logs = await Future.wait(
        wanted.map((d) => logsCol.doc(_dateKey(d)).get()),
      );

      final last7 = <String, dynamic>{};
      for (var i = 0; i < wanted.length; i++) {
        final l = logs[i].data() ?? {};
        last7[_dateKey(wanted[i])] = {
          'feeding': (l['feeding'] as num?)?.toInt() ?? 0,
          'sleep': (l['sleep'] as num?)?.toInt() ?? 0,
          'diaper': (l['diaper'] as num?)?.toInt() ?? 0,
        };
      }

      final birth = data['babyBirthDate'];
      await _couples.doc(coupleId).collection('shared').doc('baby').set({
        'babyName': data['babyName'] ?? '',
        'birthDate': birth is Timestamp ? birth : null,
        'last7': last7,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {/* أفضل-جهد */}
  }

  /// يدفع كل اللقطات — نقطة الاستدعاء الموصى بها عند فتح التطبيق.
  static Future<void> syncAll() async {
    final coupleId = await currentCoupleId();
    if (coupleId != null) {
      await migrateBabyLogsToCouple(coupleId);
      await migrateBabiesToCouple(coupleId);
    }
    await pushUserDocMirror();
    await pushPregnancySnapshot();
    await pushBabySnapshot();
    await pushProfileSnapshot();
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ══════════════════════════════════════════════════════════
  //  قراءة اللقطة — يستدعيها تطبيق الزوج
  // ══════════════════════════════════════════════════════════

  static Stream<SharedPregnancy?> watchPregnancy(String coupleId) => _couples
      .doc(coupleId)
      .collection('shared')
      .doc('pregnancy')
      .snapshots()
      .map((s) => s.exists ? SharedPregnancy.fromMap(s.data()!) : null);

  static Stream<SharedBaby?> watchBaby(String coupleId) => _couples
      .doc(coupleId)
      .collection('shared')
      .doc('baby')
      .snapshots()
      .map((s) => s.exists ? SharedBaby.fromMap(s.data()!) : null);

  // ══════════════════════════════════════════════════════════
  //  لقطة الملف الشخصي — الشارات والإنجازات (يدفعها تطبيق الزوجة)
  // ══════════════════════════════════════════════════════════

  static Future<void> pushProfileSnapshot() async {
    final uid = _uid;
    if (uid == null) return;
    final coupleId = await currentCoupleId();
    if (coupleId == null) return;
    try {
      final d = (await _db.collection('users').doc(uid).get()).data() ?? {};
      await _couples.doc(coupleId).collection('shared').doc('profile').set({
        'name': d['displayName'] ?? d['name'] ?? '',
        'photoUrl': d['photoUrl'] ?? '',
        'badges': d['badges'] ?? <String>[],
        'points': (d['points'] as num?)?.toInt() ?? 0,
        'postsCount': (d['postsCount'] as num?)?.toInt() ?? 0,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {/* أفضل-جهد */}
  }

  /// ══════════════════════════════════════════════════════════
  ///  مرآة وثيقة المستخدمة — تجعل صفحتَي الحمل والطفل تعملان عند
  ///  الأب بالكامل (كل المقالات والأدوات والوزن والطول) دون أن
  ///  يصل إلى `users/{الزوجة}` التي تمنعها القواعد منعاً مطلقاً.
  ///
  ///  ⛔ قائمة الحقول أدناه **بيضاء** عمداً: أيّ حقل غير مذكور هنا
  ///     لا يصل الأب إليه. لا تُضف أيّ حقل دورة شهرية
  ///     (cycleLength، lastPeriodStart، periodLogs، الأعراض، المزاج).
  /// ══════════════════════════════════════════════════════════
  static const List<String> _mirroredFields = [
    'pregnancyStartDate',
    'dueDate',
    'dueDateSource',
    'postTermAck',
    'babyName',
    'babyBirthDate',
    'babyGender',
    'displayName',
    'name',
    'photoUrl',
  ];

  static Future<void> pushUserDocMirror() async {
    final uid = _uid;
    if (uid == null) return;
    final coupleId = await currentCoupleId();
    if (coupleId == null) return;
    try {
      final d = (await _db.collection('users').doc(uid).get()).data() ?? {};
      final safe = <String, dynamic>{};
      for (final f in _mirroredFields) {
        if (d.containsKey(f)) safe[f] = d[f];
      }
      safe['mirroredAt'] = FieldValue.serverTimestamp();
      await _couples
          .doc(coupleId)
          .collection('shared')
          .doc('userdoc')
          .set(safe, SetOptions(merge: true));
    } catch (_) {/* أفضل-جهد */}
  }

  /// ══════════════════════════════════════════════════════════
  ///  إصلاح ذاتي للمرآة — يُستدعى من **تطبيق الأب** عند الإقلاع.
  ///
  ///  المرآة يكتبها تطبيق الزوجة عادةً. لكن إن لم يُفتح تطبيقها بعد
  ///  (أو كان الاقتران أحدث من المرآة) تبقى `shared/userdoc` فارغة
  ///  فتطلب صفحةُ الحمل عند الأب «تحديد تاريخ آخر دورة» — وهو طلب
  ///  لا معنى له في حسابه. هنا نشتقّ التواريخ من `shared/pregnancy`
  ///  التي تُكتب منذ أول مزامنة، فتعمل الصفحة فوراً.
  /// ══════════════════════════════════════════════════════════
  static Future<void> healMirrorFromSnapshot(String coupleId) async {
    try {
      final mirrorRef =
          _couples.doc(coupleId).collection('shared').doc('userdoc');
      final mirror = (await mirrorRef.get()).data() ?? {};
      if (mirror['dueDate'] != null || mirror['pregnancyStartDate'] != null) {
        return; // المرآة سليمة
      }

      final snap = (await _couples
                  .doc(coupleId)
                  .collection('shared')
                  .doc('pregnancy')
                  .get())
              .data() ??
          {};
      final due = (snap['dueDate'] as Timestamp?)?.toDate();
      if (due == null) return;

      await mirrorRef.set({
        'dueDate': Timestamp.fromDate(due),
        'pregnancyStartDate': Timestamp.fromDate(
            due.subtract(const Duration(days: PregnancyDates.totalDays))),
        'healedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // الطفل أيضاً إن كان مولوداً
      final baby = (await _couples
                  .doc(coupleId)
                  .collection('shared')
                  .doc('baby')
                  .get())
              .data() ??
          {};
      final birth = baby['birthDate'];
      if (birth is Timestamp) {
        await mirrorRef.set({
          'babyBirthDate': birth,
          'babyName': baby['babyName'] ?? '',
        }, SetOptions(merge: true));
      }
    } catch (_) {/* أفضل-جهد */}
  }

  /// يُرحّل قائمة الأطفال إلى ملكية الزوجين (مرّة واحدة لكل اقتران).
  static Future<void> migrateBabiesToCouple(String coupleId) async {
    final uid = _uid;
    if (uid == null) return;
    final flagRef = _couples.doc(coupleId).collection('shared').doc('meta');
    try {
      if (((await flagRef.get()).data()?['babiesMigrated']) == true) return;
      final src = await _db
          .collection('users')
          .doc(uid)
          .collection('babies')
          .limit(50)
          .get();
      if (src.docs.isNotEmpty) {
        final batch = _db.batch();
        for (final d in src.docs) {
          batch.set(_couples.doc(coupleId).collection('babies').doc(d.id),
              d.data(), SetOptions(merge: true));
        }
        await batch.commit();
      }
      await flagRef.set({'babiesMigrated': true}, SetOptions(merge: true));
    } catch (_) {/* أفضل-جهد */}
  }

  static Stream<SharedProfile?> watchProfile(String coupleId) => _couples
      .doc(coupleId)
      .collection('shared')
      .doc('profile')
      .snapshots()
      .map((s) => s.exists ? SharedProfile.fromMap(s.data()!) : null);

  // ══════════════════════════════════════════════════════════
  //  سجلّ الطفل المشترك — ملكية الزوجين، يكتب عليه الطرفان
  // ══════════════════════════════════════════════════════════

  static CollectionReference<Map<String, dynamic>> coupleBabyLogs(
          String coupleId) =>
      _couples.doc(coupleId).collection('baby_logs');

  static String dateKey(DateTime d) => _dateKey(d);

  /// يُرحّل سجلّات الطفل من `users/{uid}/baby_logs` إلى ملكية الزوجين،
  /// مرّة واحدة فقط لكل اقتران. يُستدعى من تطبيق الزوجة بعد الربط.
  static Future<void> migrateBabyLogsToCouple(String coupleId) async {
    final uid = _uid;
    if (uid == null) return;
    final flagRef = _couples.doc(coupleId).collection('shared').doc('meta');
    try {
      if (((await flagRef.get()).data()?['babyLogsMigrated']) == true) return;

      final src = await _db
          .collection('users')
          .doc(uid)
          .collection('baby_logs')
          .limit(400)
          .get();

      if (src.docs.isNotEmpty) {
        final batch = _db.batch();
        for (final d in src.docs) {
          // merge: لا نطمس ما سجّله الزوج قبل اكتمال الترحيل
          batch.set(coupleBabyLogs(coupleId).doc(d.id), d.data(),
              SetOptions(merge: true));
        }
        await batch.commit();
      }
      await flagRef.set({
        'babyLogsMigrated': true,
        'migratedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {/* أفضل-جهد — يُعاد في الإقلاع التالي */}
  }

  /// يزيد عدّاد نشاط الطفل لليوم. يكتب في ملكية الزوجين عند الاقتران،
  /// وإلا في ملكية المستخدمة وحدها — فيعمل في الحالتين.
  static Future<void> bumpBabyLog(String metric, {int by = 1}) async {
    final uid = _uid;
    if (uid == null) return;
    final coupleId = await currentCoupleId();
    final key = _dateKey(DateTime.now());
    final ref = coupleId != null
        ? coupleBabyLogs(coupleId).doc(key)
        : _db.collection('users').doc(uid).collection('baby_logs').doc(key);
    try {
      await ref.set({
        metric: FieldValue.increment(by),
        'updatedBy': uid,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {/* أفضل-جهد */}
  }

  // ══════════════════════════════════════════════════════════
  //  مركز التنبيهات المشترك (بلا خادم — Firestore فقط)
  // ══════════════════════════════════════════════════════════

  /// يُسجّل حدثاً يراه الطرف الآخر. آمن إن لم يكن هناك اقتران.
  static Future<void> notify({
    required String type,
    required String title,
    required String body,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    final coupleId = await currentCoupleId();
    if (coupleId == null) return;
    try {
      await _couples.doc(coupleId).collection('notifications').add({
        'type': type,
        'title': title,
        'body': body,
        'byUid': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'readBy': <String>[],
      });
    } catch (_) {/* أفضل-جهد */}
  }

  /// تنبيهات الطرف الآخر فقط (لا يرى المستخدم ما كتبه بنفسه).
  static Stream<List<PartnerNotification>> watchNotifications(String coupleId) {
    final me = _uid;
    return _couples
        .doc(coupleId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((q) => q.docs
            .map((d) => PartnerNotification.fromDoc(d.id, d.data()))
            .where((n) => n.byUid != me)
            .toList());
  }

  static Future<void> markNotificationRead(String coupleId, String id) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _couples.doc(coupleId).collection('notifications').doc(id).update({
        'readBy': FieldValue.arrayUnion([uid]),
      });
    } catch (_) {/* أفضل-جهد */}
  }
}

// ══════════════════════════════════════════════════════════════
//  النماذج
// ══════════════════════════════════════════════════════════════

class CoupleLink {
  final String id;
  final String motherUid;
  final String motherName;
  final String? partnerUid;
  final String? partnerName;
  final String status;
  final DateTime? expiresAt;

  const CoupleLink({
    required this.id,
    required this.motherUid,
    required this.motherName,
    required this.status,
    this.partnerUid,
    this.partnerName,
    this.expiresAt,
  });

  bool get isLinked => status == 'linked' && partnerUid != null;
  bool get isPending => status == 'pending';
  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now()) && isPending;

  factory CoupleLink.fromMap(String id, Map<String, dynamic> m) => CoupleLink(
        id: id,
        motherUid: m['motherUid'] as String? ?? '',
        motherName: m['motherName'] as String? ?? '',
        partnerUid: m['partnerUid'] as String?,
        partnerName: m['partnerName'] as String?,
        status: m['status'] as String? ?? 'pending',
        expiresAt: (m['expiresAt'] as Timestamp?)?.toDate(),
      );
}

class SharedPregnancy {
  final int week;
  final int dayOfWeek;
  final int daysLeft;
  final int trimester;
  final DateTime? dueDate;
  final DateTime? updatedAt;

  const SharedPregnancy({
    required this.week,
    required this.dayOfWeek,
    required this.daysLeft,
    required this.trimester,
    this.dueDate,
    this.updatedAt,
  });

  double get progress => (week / 40).clamp(0.0, 1.0);

  factory SharedPregnancy.fromMap(Map<String, dynamic> m) => SharedPregnancy(
        week: (m['week'] as num?)?.toInt() ?? 0,
        dayOfWeek: (m['dayOfWeek'] as num?)?.toInt() ?? 0,
        daysLeft: (m['daysLeft'] as num?)?.toInt() ?? 0,
        trimester: (m['trimester'] as num?)?.toInt() ?? 1,
        dueDate: (m['dueDate'] as Timestamp?)?.toDate(),
        updatedAt: (m['updatedAt'] as Timestamp?)?.toDate(),
      );
}

class SharedProfile {
  final String name;
  final String photoUrl;
  final List<String> badges;
  final int points;
  final int postsCount;

  const SharedProfile({
    required this.name,
    required this.photoUrl,
    required this.badges,
    required this.points,
    required this.postsCount,
  });

  factory SharedProfile.fromMap(Map<String, dynamic> m) => SharedProfile(
        name: m['name'] as String? ?? '',
        photoUrl: m['photoUrl'] as String? ?? '',
        badges: ((m['badges'] as List?) ?? []).map((e) => '$e').toList(),
        points: (m['points'] as num?)?.toInt() ?? 0,
        postsCount: (m['postsCount'] as num?)?.toInt() ?? 0,
      );
}

class PartnerNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final String byUid;
  final DateTime? createdAt;
  final List<String> readBy;

  const PartnerNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.byUid,
    required this.readBy,
    this.createdAt,
  });

  factory PartnerNotification.fromDoc(String id, Map<String, dynamic> m) =>
      PartnerNotification(
        id: id,
        type: m['type'] as String? ?? '',
        title: m['title'] as String? ?? '',
        body: m['body'] as String? ?? '',
        byUid: m['byUid'] as String? ?? '',
        createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
        readBy: ((m['readBy'] as List?) ?? []).map((e) => '$e').toList(),
      );
}

class SharedBaby {
  final String babyName;
  final DateTime? birthDate;

  /// مفتاح yyyy-MM-dd → { feeding, sleep, diaper }
  final Map<String, Map<String, int>> last7;
  final DateTime? updatedAt;

  const SharedBaby({
    required this.babyName,
    required this.last7,
    this.birthDate,
    this.updatedAt,
  });

  int get ageInDays =>
      birthDate == null ? 0 : DateTime.now().difference(birthDate!).inDays;

  factory SharedBaby.fromMap(Map<String, dynamic> m) {
    final raw = (m['last7'] as Map?) ?? {};
    final parsed = <String, Map<String, int>>{};
    raw.forEach((k, v) {
      final mv = (v as Map?) ?? {};
      parsed[k.toString()] = {
        'feeding': (mv['feeding'] as num?)?.toInt() ?? 0,
        'sleep': (mv['sleep'] as num?)?.toInt() ?? 0,
        'diaper': (mv['diaper'] as num?)?.toInt() ?? 0,
      };
    });
    return SharedBaby(
      babyName: m['babyName'] as String? ?? '',
      birthDate: (m['birthDate'] as Timestamp?)?.toDate(),
      last7: parsed,
      updatedAt: (m['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
