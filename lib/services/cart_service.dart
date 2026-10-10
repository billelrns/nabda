import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'partner_service.dart';

// ─── Cart Item Model ───
class CartItem {
  final String id; // unique key = productName hash
  /// معرّف المنتج في Firestore. فارغ للمنتجات القديمة المضافة قبل
  /// إضافة هذا الحقل — يُستعمل لفحص التوفّر عند الدفع.
  final String productId;
  final String name;
  final String emoji;
  final String category;
  final double priceValue; // numeric price in DZD
  final String priceDisplay; // formatted price string
  final Color color;
  int quantity;

  CartItem({
    required this.id,
    this.productId = '',
    required this.name,
    required this.emoji,
    required this.category,
    required this.priceValue,
    required this.priceDisplay,
    required this.color,
    this.quantity = 1,
  });

  double get total => priceValue * quantity;

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'name': name,
    'emoji': emoji,
    'category': category,
    'priceValue': priceValue,
    'priceDisplay': priceDisplay,
    'quantity': quantity,
  };

  /// للسلّة المشتركة بين الزوجين — يحفظ اللون أيضاً ليبقى العرض متطابقاً
  Map<String, dynamic> toSharedMap() => {
        ...toMap(),
        'id': id,
        'color': color.value,
      };

  factory CartItem.fromSharedMap(Map<String, dynamic> m) => CartItem(
        id: m['id'] as String? ?? '${m['name']}'.hashCode.toString(),
        productId: m['productId'] as String? ?? '',
        name: m['name'] as String? ?? '',
        emoji: m['emoji'] as String? ?? '🛍️',
        category: m['category'] as String? ?? '',
        priceValue: (m['priceValue'] as num?)?.toDouble() ?? 0,
        priceDisplay: m['priceDisplay'] as String? ?? '',
        color: Color((m['color'] as num?)?.toInt() ?? 0xFFE0195B),
        quantity: (m['quantity'] as num?)?.toInt() ?? 1,
      );
}

// ─── Order Model ───
class OrderModel {
  final String id;
  final String userId;
  final String customerName;
  final String phone;
  final String address;
  final String country;
  final String paymentMethod;
  final List<Map<String, dynamic>> items;
  final double subtotal;
  final double shipping;
  final double totalAmount;
  final String totalDisplay;
  final String status;
  final DateTime createdAt;
  final String? couponCode;
  final double discount;

  OrderModel({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.country,
    required this.paymentMethod,
    required this.items,
    required this.subtotal,
    required this.shipping,
    required this.totalAmount,
    required this.totalDisplay,
    this.status = 'pending',
    required this.createdAt,
    this.couponCode,
    this.discount = 0,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      userId: d['userId'] ?? '',
      customerName: d['customerName'] ?? '',
      phone: d['phone'] ?? '',
      address: d['address'] ?? '',
      country: d['country'] ?? '',
      paymentMethod: d['paymentMethod'] ?? '',
      items: List<Map<String, dynamic>>.from(d['items'] ?? []),
      subtotal: (d['subtotal'] ?? 0).toDouble(),
      shipping: (d['shipping'] ?? 0).toDouble(),
      totalAmount: (d['totalAmount'] ?? 0).toDouble(),
      totalDisplay: d['totalDisplay'] ?? '',
      status: d['status'] ?? 'pending',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      couponCode: d['couponCode'],
      discount: (d['discount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'customerName': customerName,
    'phone': phone,
    'address': address,
    'country': country,
    'paymentMethod': paymentMethod,
    'items': items,
    'subtotal': subtotal,
    'shipping': shipping,
    'totalAmount': totalAmount,
    'totalDisplay': totalDisplay,
    'status': status,
    'createdAt': Timestamp.fromDate(createdAt),
    'couponCode': couponCode,
    'discount': discount,
    // For admin panel display compatibility
    'productName': items.length == 1 ? items.first['name'] : '${items.length} منتجات',
    'total': totalDisplay,
  };
}

// ─── Cart Service (Singleton) ───
class CartService extends ChangeNotifier {
  /// أسعار التوصيل الافتراضية بالدينار (تُحوَّل للعملة المحلية عند العرض).
  /// المصدر الوحيد: صفحة المنتج والسلّة تقرآن من هنا.
  static const double kHomeDeliveryDzd = 500.0;
  static const double kOfficePickupDzd = 300.0;

  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<CartItem> _items = [];

  // ══════════════════════════════════════════════════════════
  //  السلّة المشتركة بين الزوجين (couples/{id}/cart/current)
  //  عند الاقتران تصبح السلّة واحدة: ما تضيفه الزوجة يظهر عند الزوج
  //  فوراً، ويمكنه هو إتمام الطلب والدفع عنها.
  // ══════════════════════════════════════════════════════════
  String? _coupleId;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  /// لمنع حلقة الصدى: نتجاهل اللقطة الناتجة عن كتابتنا نحن.
  bool _applyingRemote = false;

  bool get isShared => _coupleId != null;

  DocumentReference<Map<String, dynamic>>? get _cartRef => _coupleId == null
      ? null
      : FirebaseFirestore.instance
          .collection('couples')
          .doc(_coupleId)
          .collection('cart')
          .doc('current');

  /// يُفعّل المزامنة المشتركة. آمن للاستدعاء المتكرّر — يُستدعى من
  /// الهيكل عند الإقلاع **ومن شاشة السلّة والمتجر عند الفتح**، لأن
  /// الاعتماد على نقطة واحدة جعل السلّة تبدو فارغة إن سبق فتحُها
  /// انتهاءَ الاشتراك.
  Future<void> enableCoupleSync(String coupleId) async {
    final sameLink = _coupleId == coupleId && _sub != null;
    _coupleId = coupleId;

    // ① سحب فوري: لا ننتظر أوّل لقطة من البثّ
    try {
      final snap = await _cartRef?.get();
      final d = snap?.data();
      if (d != null) {
        final raw = (d['items'] as List?) ?? [];
        final remote = raw
            .map((e) => CartItem.fromSharedMap(Map<String, dynamic>.from(e as Map)))
            .toList();
        _mergeRemote(remote);
      }
    } catch (e) {
      debugPrint('cart sync pull: $e');
    }

    // ② ادفع ما لدينا محلياً (قد يكون فيه ما ليس عندهم)
    if (_items.isNotEmpty) await _pushRemote();

    if (sameLink) return; // البثّ قائم بالفعل

    await _sub?.cancel();
    _sub = _cartRef?.snapshots().listen((snap) {
      final me = FirebaseAuth.instance.currentUser?.uid;
      final d = snap.data();
      if (d == null) return;
      if (d['updatedBy'] == me) return; // كتابتنا نحن — لا تُعِد تطبيقها
      final raw = (d['items'] as List?) ?? [];
      _applyingRemote = true;
      _items
        ..clear()
        ..addAll(raw.map((e) =>
            CartItem.fromSharedMap(Map<String, dynamic>.from(e as Map))));
      _applyingRemote = false;
      debugPrint('cart sync: applied ${_items.length} remote items');
      notifyListeners();
    }, onError: (e) => debugPrint('cart sync stream: $e'));
  }

  /// يدمج السلّة البعيدة مع المحلية (اتّحاد بأكبر كمية) حتى لا يفقد
  /// أيّ طرف ما أضافه قبل اكتمال الربط.
  void _mergeRemote(List<CartItem> remote) {
    for (final r in remote) {
      final i = _items.indexWhere((x) => x.id == r.id);
      if (i < 0) {
        _items.add(r);
      } else if (r.quantity > _items[i].quantity) {
        _items[i].quantity = r.quantity;
      }
    }
    notifyListeners();
  }

  Future<void> disableCoupleSync() async {
    await _sub?.cancel();
    _sub = null;
    _coupleId = null;
  }

  Future<void> _pushRemote({bool silent = false}) async {
    final ref = _cartRef;
    if (ref == null || _applyingRemote) return;
    try {
      await ref.set({
        'items': _items.map((i) => i.toSharedMap()).toList(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('cart sync: pushed ${_items.length} items');
    } catch (e) {
      debugPrint('cart sync push: $e');
    }
  }

  /// يُفعّل المزامنة إن كان الحساب مرتبطاً — تُستدعى من أي شاشة سلّة/متجر.
  Future<void> ensureCoupleSync() async {
    final id = await PartnerService.currentCoupleId();
    if (id != null) await enableCoupleSync(id);
  }

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  double get subtotal => _items.fold(0, (sum, item) => sum + item.total);

  // ─── Add item to cart ───
  void addItem({
    required String name,
    required String emoji,
    required String category,
    required double priceValue,
    required String priceDisplay,
    required Color color,
    int quantity = 1,
    String productId = '',
  }) {
    final id = name.hashCode.toString();
    final existing = _items.indexWhere((i) => i.id == id);

    if (existing >= 0) {
      _items[existing].quantity += quantity;
    } else {
      _items.add(CartItem(
        id: id,
        productId: productId,
        name: name,
        emoji: emoji,
        category: category,
        priceValue: priceValue,
        priceDisplay: priceDisplay,
        color: color,
        quantity: quantity,
      ));
    }
    notifyListeners();
    _pushRemote();
    // نبّه الطرف الآخر أنّ منتجاً أُضيف إلى سلّتهما المشتركة
    if (isShared) {
      PartnerService.notify(
        type: 'cart_add',
        title: 'أُضيف إلى سلّتكما',
        body: '$name — $priceDisplay',
      );
    }
  }

  // ─── Remove item ───
  void removeItem(String id) {
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
    _pushRemote();
  }

  // ─── Update quantity ───
  void updateQuantity(String id, int newQty) {
    if (newQty <= 0) {
      removeItem(id);
      return;
    }
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx >= 0) {
      _items[idx].quantity = newQty;
      notifyListeners();
      _pushRemote();
    }
  }

  // ─── Clear cart ───
  void clear() {
    _items.clear();
    notifyListeners();
    _pushRemote();
  }

  // ─── Place order → Firestore ───
  Future<String?> placeOrder({
    required String customerName,
    required String phone,
    required String address,
    required String country,
    required String paymentMethod,
    required String totalDisplay,
    double shipping = 0,
    String? couponCode,
    double discount = 0,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _items.isEmpty) return null;

    try {
      final order = OrderModel(
        id: '',
        userId: user.uid,
        customerName: customerName,
        phone: phone,
        address: address,
        country: country,
        paymentMethod: paymentMethod,
        items: _items.map((i) => i.toMap()).toList(),
        subtotal: subtotal,
        shipping: shipping,
        totalAmount: subtotal + shipping - discount,
        totalDisplay: totalDisplay,
        createdAt: DateTime.now(),
        couponCode: couponCode,
        discount: discount,
      );

      final docRef = await FirebaseFirestore.instance
          .collection('orders')
          .add(order.toMap());

      // Save to user's orders subcollection too
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .doc(docRef.id)
          .set(order.toMap());

      // ── الطلب المشترك: يظهر للطرف الآخر مع اسم من أتمّه ──
      if (isShared) {
        final byPartner =
            await PartnerService.localRole() == PartnerService.rolePartner;
        try {
          await FirebaseFirestore.instance
              .collection('couples')
              .doc(_coupleId)
              .collection('orders')
              .doc(docRef.id)
              .set({
            'orderId': docRef.id,
            'placedBy': user.uid,
            'placedByRole': byPartner ? 'partner' : 'mother',
            'customerName': customerName,
            'totalDisplay': totalDisplay,
            'itemCount': itemCount,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } catch (_) {/* أفضل-جهد */}

        await PartnerService.notify(
          type: 'order_placed',
          title: byPartner ? 'زوجك أتمّ الطلب ✅' : 'زوجتك أتمّت الطلب ✅',
          body: '$totalDisplay — الدفع عند الاستلام',
        );
      }

      clear();
      return docRef.id;
    } catch (e) {
      debugPrint('Error placing order: $e');
      return null;
    }
  }

  // ─── Get user's orders stream ───
  Stream<List<OrderModel>> getUserOrders() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => OrderModel.fromFirestore(d)).toList());
  }

  // ─── Parse price string to double ───
  static double parsePrice(String priceStr) {
    // Remove currency symbols and non-numeric chars except comma/dot
    final cleaned = priceStr
        .replaceAll(RegExp(r'[^\d,.]'), '')
        .replaceAll(',', '');
    return double.tryParse(cleaned) ?? 0;
  }
}
