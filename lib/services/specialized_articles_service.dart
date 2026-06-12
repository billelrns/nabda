import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/specialized_articles.dart';

/// إدارة المقالات المتخصّصة في Firestore (مجموعة specialized_articles).
class SpecializedArticlesService {
  static final col =
      FirebaseFirestore.instance.collection('specialized_articles');

  /// كل مقالات موضوع معيّن (بلا orderBy لتجنّب الفهرس المركّب — نرتّب في العميل).
  static Stream<QuerySnapshot> streamByTopic(String topic) =>
      col.where('topic', isEqualTo: topic).snapshots();

  static Stream<QuerySnapshot> streamAll() => col.snapshots();

  static Future<void> add({
    required String topic,
    required String title,
    required String body,
    String image = '',
    int order = 0,
  }) =>
      col.add({
        'topic': topic,
        'title': title,
        'body': body,
        'image': image,
        'order': order,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  static Future<void> update(String id, Map<String, dynamic> data) {
    data['updatedAt'] = FieldValue.serverTimestamp();
    return col.doc(id).update(data);
  }

  static Future<void> delete(String id) => col.doc(id).delete();

  /// بذر المقالات الثابتة مرّة واحدة (فقط إذا كانت المجموعة فارغة).
  static Future<int> seedFromHardcoded() async {
    final existing = await col.limit(1).get();
    if (existing.docs.isNotEmpty) return 0;
    final batch = FirebaseFirestore.instance.batch();
    int n = 0;
    specializedArticles.forEach((topic, list) {
      for (int i = 0; i < list.length; i++) {
        batch.set(col.doc(), {
          'topic': topic,
          'title': list[i].title,
          'body': list[i].body,
          'image': '',
          'order': i,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        n++;
      }
    });
    await batch.commit();
    return n;
  }
}
