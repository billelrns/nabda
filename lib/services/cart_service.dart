import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─── Cart Item Model ───
class CartItem {
  final String id; // unique key = productName hash
  final String name;
  final String emoji;
  final String category;
  final double priceValue; // numeric price in DZD
  final String priceDisplay; // formatted price string
  final Color color;
  int quantity;

  CartItem({
    required this.id,
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
    'name': name,
    'emoji': emoji,
    'category': category,
    'priceValue': priceValue,
    'priceDisplay': priceDisplay,
    'quantity': quantity,
  };
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
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<CartItem> _items = [];

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
  }) {
    final id = name.hashCode.toString();
    final existing = _items.indexWhere((i) => i.id == id);

    if (existing >= 0) {
      _items[existing].quantity += quantity;
    } else {
      _items.add(CartItem(
        id: id,
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
  }

  // ─── Remove item ───
  void removeItem(String id) {
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
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
    }
  }

  // ─── Clear cart ───
  void clear() {
    _items.clear();
    notifyListeners();
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
