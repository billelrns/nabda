import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for managing dynamic articles and products from Firestore.
/// These appear BEFORE hardcoded content in the app.
class DynamicContentService {
  static final _firestore = FirebaseFirestore.instance;

  // ── Articles ──
  static CollectionReference get articlesRef => _firestore.collection('dynamic_articles');

  static Stream<QuerySnapshot> getArticles({required String section}) {
    return articlesRef
        .where('section', isEqualTo: section)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<void> addArticle({
    required String title,
    required String content,
    required String image,
    required String category,
    required String section,
  }) async {
    await articlesRef.add({
      'title': title,
      'content': content,
      'image': image,
      'category': category,
      'section': section,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateArticle(String docId, Map<String, dynamic> data) async {
    await articlesRef.doc(docId).update(data);
  }

  static Future<void> deleteArticle(String docId) async {
    await articlesRef.doc(docId).delete();
  }

  // ── Products ──
  static CollectionReference get productsRef => _firestore.collection('dynamic_products');

  static Stream<QuerySnapshot> getProducts({required String section}) {
    return productsRef
        .where('section', isEqualTo: section)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<void> addProduct({
    required String name,
    required String image,
    required String price,
    required String category,
    required String section,
    String? link,
  }) async {
    await productsRef.add({
      'name': name,
      'image': image,
      'price': price,
      'category': category,
      'section': section,
      'link': link ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateProduct(String docId, Map<String, dynamic> data) async {
    await productsRef.doc(docId).update(data);
  }

  static Future<void> deleteProduct(String docId) async {
    await productsRef.doc(docId).delete();
  }

  /// Helper: Convert Firestore doc to article map
  static Map<String, String> docToArticle(QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return {
      'title': (d['title'] ?? '') as String,
      'content': (d['content'] ?? '') as String,
      'image': (d['image'] ?? '') as String,
      'image2': (d['image2'] ?? '') as String,
      'category': (d['category'] ?? '') as String,
      'section': (d['section'] ?? '') as String,
      'docId': doc.id,
      'isDynamic': 'true',
    };
  }

  /// Helper: Convert Firestore doc to product map
  static Map<String, String> docToProduct(QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return {
      'name': (d['name'] ?? '') as String,
      'image': (d['image'] ?? '') as String,
      'price': (d['price'] ?? '') as String,
      'category': (d['category'] ?? '') as String,
      'link': (d['link'] ?? '') as String,
      'docId': doc.id,
      'isDynamic': 'true',
    };
  }
}
