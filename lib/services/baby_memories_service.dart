import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'partner_service.dart';

/// ═══════════════════════════════════════════════════════════════════
///  دفتر ذكريات الطفل — أول ابتسامة، أول سنّ، أول خطوة…
///
///  المسار: {DB.babies}/{babyId}/memories/{memoryId}
///    • الطفل في حاوية الزوجين عند الاقتران ← الذكريات مشتركة لحظياً مع الزوج
///    • وعند فكّ الارتباط تُسترجع مع الطفل (PartnerService._reclaimToMother)
///
///  الصور: Storage → baby_memories/{motherUid}/{babyId}/{memoryId}.jpg
///    دائماً باسم الأم (لا باسم حاوية الزوجين) حتى تبقى ملكها بعد أي فكّ
///    ارتباط؛ وقاعدة Storage تسمح للزوج المرتبط بها فقط.
///
///  ⚠️ امتثال Google Play: دفتر ذكريات لا متابعة نموّ طبّية. لا تُضف
///     «أعماراً طبيعية» للمعالم ولا تنبيهات «تأخّر» — ذلك تقييم نموّ طبّي.
/// ═══════════════════════════════════════════════════════════════════

class MilestoneType {
  final String id;
  final String title;
  final String emoji;
  const MilestoneType(this.id, this.title, this.emoji);
}

/// المعالم الجاهزة — بترتيب حدوثها المعتاد تقريباً (للعرض فقط، لا تقييم)
const List<MilestoneType> kMilestones = [
  MilestoneType('first_smile', 'أول ابتسامة', '😊'),
  MilestoneType('first_laugh', 'أول ضحكة', '😂'),
  MilestoneType('first_rollover', 'أول تقلّب', '🔄'),
  MilestoneType('first_tooth', 'أول سنّ', '🦷'),
  MilestoneType('first_food', 'أول طعام صلب', '🥣'),
  MilestoneType('first_sit', 'أول جلوس', '🪑'),
  MilestoneType('first_crawl', 'أول حبو', '🧸'),
  MilestoneType('first_word', 'أول كلمة', '💬'),
  MilestoneType('first_step', 'أول خطوة', '👣'),
  MilestoneType('first_haircut', 'أول قصّة شعر', '✂️'),
  MilestoneType('first_eid', 'أول عيد', '🌙'),
  MilestoneType('first_trip', 'أول سفر', '✈️'),
  MilestoneType('first_birthday', 'أول عيد ميلاد', '🎂'),
];

const MilestoneType kCustomMemory = MilestoneType('custom', 'ذكرى خاصّة', '💗');

MilestoneType milestoneById(String id) =>
    kMilestones.firstWhere((m) => m.id == id, orElse: () => kCustomMemory);

class BabyMemory {
  final String id;
  final String type;
  final String title;
  final String emoji;
  final DateTime date;
  final String note;
  final String? photoUrl;
  final String? photoPath;
  final String? createdBy;

  const BabyMemory({
    required this.id,
    required this.type,
    required this.title,
    required this.emoji,
    required this.date,
    this.note = '',
    this.photoUrl,
    this.photoPath,
    this.createdBy,
  });

  bool get isCustom => type == 'custom';

  factory BabyMemory.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    final t = milestoneById((m['type'] ?? 'custom').toString());
    return BabyMemory(
      id: d.id,
      type: (m['type'] ?? 'custom').toString(),
      title: (m['title'] ?? t.title).toString(),
      emoji: (m['emoji'] ?? t.emoji).toString(),
      date: (m['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: (m['note'] ?? '').toString(),
      photoUrl: (m['photoUrl'] as String?)?.isNotEmpty == true ? m['photoUrl'] as String : null,
      photoPath: m['photoPath'] as String?,
      createdBy: m['createdBy'] as String?,
    );
  }
}

class BabyMemoriesService {
  BabyMemoriesService._();

  static CollectionReference<Map<String, dynamic>> col(
          DocumentReference babyRef) =>
      babyRef.collection('memories');

  static Stream<List<BabyMemory>> watch(DocumentReference babyRef) =>
      col(babyRef)
          .orderBy('date', descending: true)
          .snapshots()
          .map((q) => q.docs.map(BabyMemory.fromDoc).toList());

  /// صاحبة الصور في Storage: الأم دائماً (انظر رأس الملف).
  static Future<String?> _photoOwnerUid() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    if (await PartnerService.localRole() != PartnerService.rolePartner) return uid;
    final coupleId = await PartnerService.currentCoupleId();
    if (coupleId == null) return null;
    try {
      final c = await FirebaseFirestore.instance.collection('couples').doc(coupleId).get();
      return c.data()?['motherUid'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// يحفظ ذكرى جديدة أو يعدّل موجودة، مع رفع الصورة إن وُجدت.
  /// [photoBytes] صورة جديدة (JPEG)، [removePhoto] حذف الصورة الحالية.
  static Future<String?> save({
    required DocumentReference babyRef,
    required String babyId,
    required MilestoneType type,
    required String title,
    required DateTime date,
    String note = '',
    String? existingId,
    BabyMemory? existing,
    Uint8List? photoBytes,
    bool removePhoto = false,
    String babyName = '',
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 'سجّلي الدخول أولاً';

    final ref = existingId != null ? col(babyRef).doc(existingId) : col(babyRef).doc();
    String? photoUrl = existing?.photoUrl;
    String? photoPath = existing?.photoPath;

    try {
      // الصورة أوّلاً — إن فشل رفعها لا نحفظ ذكرى ناقصة بصمت
      if (photoBytes != null) {
        final owner = await _photoOwnerUid();
        if (owner == null) return 'تعذّر تحديد مكان حفظ الصورة';
        final newPath = 'baby_memories/$owner/$babyId/${ref.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final task = await FirebaseStorage.instance.ref(newPath).putData(
              photoBytes,
              SettableMetadata(contentType: 'image/jpeg'),
            );
        final newUrl = await task.ref.getDownloadURL();
        // احذف الصورة القديمة بعد نجاح الجديدة
        if (photoPath != null) _deleteFile(photoPath);
        photoUrl = newUrl;
        photoPath = newPath;
      } else if (removePhoto && photoPath != null) {
        _deleteFile(photoPath);
        photoUrl = null;
        photoPath = null;
      }

      await ref.set({
        'type': type.id,
        'title': title.trim().isEmpty ? type.title : title.trim(),
        'emoji': type.emoji,
        'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day, 12)),
        'note': note.trim(),
        'photoUrl': photoUrl,
        'photoPath': photoPath,
        if (existingId == null) 'createdBy': uid,
        if (existingId == null) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // ذكرى جديدة ← تنبيه للطرف الآخر من الزوجين (مع الصورة إن وُجدت)
      if (existingId == null) {
        PartnerService.notify(
          type: 'memory',
          title: 'ذكرى جديدة 💗',
          body: '${type.emoji} ${title.trim().isEmpty ? type.title : title.trim()}'
              '${babyName.isNotEmpty ? ' — $babyName' : ''}',
          imageUrl: photoUrl,
        );
      }
      return null;
    } catch (e) {
      debugPrint('BabyMemoriesService.save: $e');
      return 'تعذّر الحفظ — تحقّقي من الاتصال';
    }
  }

  static Future<void> delete(DocumentReference babyRef, BabyMemory m) async {
    await col(babyRef).doc(m.id).delete();
    if (m.photoPath != null) _deleteFile(m.photoPath!);
  }

  static void _deleteFile(String path) {
    FirebaseStorage.instance.ref(path).delete().catchError((_) {});
  }

  // ── عرض التاريخ والعمر ─────────────────────────────────────────
  static const _months = [
    'جانفي', 'فيفري', 'مارس', 'أفريل', 'ماي', 'جوان',
    'جويلية', 'أوت', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];

  static String formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  /// «في عمر 7 أشهر و12 يوماً» — عمر الطفل يوم الذكرى
  static String ageAt(DateTime? birth, DateTime date) {
    if (birth == null) return '';
    // UTC لتفادي فروق التوقيت الصيفي في عدّ الأيام
    final b = DateTime.utc(birth.year, birth.month, birth.day);
    final d = DateTime.utc(date.year, date.month, date.day);
    if (d.isBefore(b)) return '';
    final days = d.difference(b).inDays;
    if (days == 0) return 'في يومه الأول';
    if (days < 31) return 'في عمر ${_n(days, 'يوم', 'يومين', 'أيام', 'يوماً')}';

    // «ذكرى الشهر» بعد m شهراً من الولادة — مع قصّ اليوم لآخر الشهر.
    // (طريقة «استلاف أيام الشهر السابق» تُعطي أياماً سالبة لمولود يوم 31:
    //  مولود 31 جانفي وذكرى 1 مارس.)
    DateTime anchor(int m) {
      final total = b.month - 1 + m;
      final y = b.year + total ~/ 12;
      final mo = total % 12 + 1;
      final last = DateTime.utc(y, mo + 1, 0).day;
      return DateTime.utc(y, mo, b.day > last ? last : b.day);
    }

    var months = (d.year - b.year) * 12 + (d.month - b.month);
    if (anchor(months).isAfter(d)) months -= 1;
    final rem = d.difference(anchor(months)).inDays;
    if (months <= 0) return 'في عمر ${_n(days, 'يوم', 'يومين', 'أيام', 'يوماً')}';
    if (months < 24) {
      final m = _n(months, 'شهر', 'شهرين', 'أشهر', 'شهراً');
      return rem > 0 ? 'في عمر $m و${_n(rem, 'يوم', 'يومين', 'أيام', 'يوماً')}' : 'في عمر $m';
    }
    final years = months ~/ 12;
    final mm = months % 12;
    final y = _n(years, 'سنة', 'سنتين', 'سنوات', 'سنة');
    return mm > 0 ? 'في عمر $y و${_n(mm, 'شهر', 'شهرين', 'أشهر', 'شهراً')}' : 'في عمر $y';
  }

  /// صيغ العدد العربية: 1 مفرد، 2 مثنّى، 3–10 جمع، 11+ تمييز مفرد
  static String _n(int n, String one, String two, String few, String many) {
    if (n == 1) return one;
    if (n == 2) return two;
    if (n >= 3 && n <= 10) return '$n $few';
    return '$n $many';
  }
}
