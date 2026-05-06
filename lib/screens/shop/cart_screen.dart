import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/cart_service.dart';
import '../../services/country_currency_service.dart';
import '../../services/payment_service.dart';
import '../../services/notification_service.dart';

// ─── Theme ───
const Color _bg = Color(0xFFFFF5F7);
const Color _card = Colors.white;
const Color _teal = Color(0xFF00897B);
const Color _pink = Color(0xFFE91E63);
const Color _text1 = Color(0xFF2D2D3A);
const Color _text2 = Color(0xFF6B7280);

// ═══════════════════════════════════════════════
//  CART SCREEN
// ═══════════════════════════════════════════════
class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _cart = CartService();
  final _currency = CountryCurrencyService();

  @override
  void initState() {
    super.initState();
    _cart.addListener(_refresh);
  }

  @override
  void dispose() {
    _cart.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  String _fmtPrice(double price) {
    final country = _currency.currentCountry;
    final converted = price * (_currency.exchangeRate ?? 1.0);
    final formatted = converted.toStringAsFixed(converted.truncateToDouble() == converted ? 0 : 2);
    // Add thousand separators
    final parts = formatted.split('.');
    final intPart = parts[0].replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    final result = parts.length > 1 ? '$intPart.${parts[1]}' : intPart;
    return '$result ${country.currencySymbol}';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          centerTitle: true,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('سلة المشتريات', style: TextStyle(fontWeight: FontWeight.bold, color: _text1, fontSize: 18)),
              if (_cart.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: _pink, borderRadius: BorderRadius.circular(10)),
                  child: Text('${_cart.itemCount}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
          backgroundColor: _card,
          foregroundColor: _teal,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          actions: [
            if (_cart.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
                onPressed: () => _showClearConfirm(),
              ),
          ],
        ),
        body: _cart.isEmpty ? _emptyCart() : _cartContent(),
        bottomNavigationBar: _cart.isNotEmpty ? _bottomBar() : null,
      ),
    );
  }

  Widget _emptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(color: _teal.withOpacity(0.08), shape: BoxShape.circle),
            child: const Center(child: Text('🛒', style: TextStyle(fontSize: 50))),
          ),
          const SizedBox(height: 20),
          const Text('سلتك فارغة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _text1)),
          const SizedBox(height: 8),
          Text('تصفحي المتجر وأضيفي منتجات لسلتك', style: TextStyle(fontSize: 14, color: _text2)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.storefront),
            label: const Text('تصفح المتجر', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _teal, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartContent() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cart.items.length + 1, // +1 for coupon section
      itemBuilder: (_, i) {
        if (i < _cart.items.length) {
          return _cartItemCard(_cart.items[i]);
        }
        // Order summary at the bottom
        return _orderSummary();
      },
    );
  }

  Widget _cartItemCard(CartItem item) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(16)),
        child: Icon(Icons.delete, color: Colors.red.shade400, size: 28),
      ),
      onDismissed: (_) => _cart.removeItem(item.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        ),
        child: Row(
          children: [
            // Product emoji
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(color: item.color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
              child: Center(child: Text(item.emoji, style: const TextStyle(fontSize: 28))),
            ),
            const SizedBox(width: 12),
            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _text1), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(_fmtPrice(item.priceValue), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _teal)),
                ],
              ),
            ),
            // Quantity controls
            Container(
              decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _qtyButton(Icons.remove, () => _cart.updateQuantity(item.id, item.quantity - 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _text1)),
                  ),
                  _qtyButton(Icons.add, () => _cart.updateQuantity(item.id, item.quantity + 1)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: icon == Icons.add ? _teal : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: icon == Icons.add ? Colors.white : _text2),
      ),
    );
  }

  Widget _orderSummary() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        children: [
          _summaryRow('المنتجات (${_cart.itemCount})', _fmtPrice(_cart.subtotal)),
          const SizedBox(height: 8),
          _summaryRow('التوصيل', 'مجاني'),
          const Divider(height: 24),
          _summaryRow('المجموع', _fmtPrice(_cart.subtotal), isBold: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isBold ? 16 : 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isBold ? _text1 : _text2)),
        Text(value, style: TextStyle(fontSize: isBold ? 18 : 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isBold ? _teal : _text1)),
      ],
    );
  }

  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Total
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('المجموع', style: TextStyle(fontSize: 12, color: _text2)),
                  Text(_fmtPrice(_cart.subtotal), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _teal)),
                ],
              ),
            ),
            // Checkout button
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const CartCheckoutScreen(),
                  ));
                },
                icon: const Icon(Icons.shopping_cart_checkout, size: 20),
                label: const Text('إتمام الشراء', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearConfirm() {
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('إفراغ السلة', textAlign: TextAlign.center),
          content: const Text('هل تريدين حذف جميع المنتجات من السلة؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () { _cart.clear(); Navigator.pop(context); },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('إفراغ'),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  CHECKOUT SCREEN (From Cart)
// ═══════════════════════════════════════════════
class CartCheckoutScreen extends StatefulWidget {
  const CartCheckoutScreen({Key? key}) : super(key: key);
  @override
  State<CartCheckoutScreen> createState() => _CartCheckoutScreenState();
}

class _CartCheckoutScreenState extends State<CartCheckoutScreen> {
  final _cart = CartService();
  final _currency = CountryCurrencyService();
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _phoneC = TextEditingController();
  final Map<String, TextEditingController> _addressControllers = {};
  String? _selectedPayment;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currency.addListener(_refresh);
    _initAddressFields();
  }

  void _initAddressFields() {
    for (final c in _addressControllers.values) c.dispose();
    _addressControllers.clear();
    for (final field in _currency.currentCountry.addressFields) {
      _addressControllers[field.key] = TextEditingController();
    }
    final methods = _currency.currentCountry.paymentMethods;
    _selectedPayment = methods.isNotEmpty ? methods.first.id : null;
  }

  @override
  void dispose() {
    _currency.removeListener(_refresh);
    _nameC.dispose();
    _phoneC.dispose();
    for (final c in _addressControllers.values) c.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  String _fmtPrice(double price) {
    final country = _currency.currentCountry;
    final converted = price * (_currency.exchangeRate ?? 1.0);
    final formatted = converted.toStringAsFixed(converted.truncateToDouble() == converted ? 0 : 2);
    final parts = formatted.split('.');
    final intPart = parts[0].replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    final result = parts.length > 1 ? '$intPart.${parts[1]}' : intPart;
    return '$result ${country.currencySymbol}';
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;

    // 1. Process payment first
    final paymentResult = await PaymentService().processPayment(
      paymentMethod: _selectedPayment ?? 'cod',
      amount: _cart.subtotal,
      currency: _currency.currentCountry.currencyCode,
      customerName: _nameC.text,
      customerEmail: user?.email ?? '',
      orderId: DateTime.now().millisecondsSinceEpoch.toString(),
    );

    if (!paymentResult.success) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(paymentResult.message), backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        );
      }
      return;
    }

    // 2. Build address string
    final addressParts = <String>[];
    for (final field in _currency.currentCountry.addressFields) {
      final val = _addressControllers[field.key]?.text ?? '';
      if (val.isNotEmpty) addressParts.add('${field.labelAr}: $val');
    }

    // 3. Save order to Firestore
    final orderId = await _cart.placeOrder(
      customerName: _nameC.text,
      phone: _phoneC.text,
      address: addressParts.join(' | '),
      country: _currency.currentCountry.nameAr,
      paymentMethod: paymentResult.paymentMethod ?? _selectedPayment ?? 'cod',
      totalDisplay: _fmtPrice(_cart.subtotal),
    );

    // 4. Create notification for user
    if (orderId != null && user != null) {
      await NotificationService().createOrderNotification(
        userId: user.uid,
        orderId: orderId,
        newStatus: 'pending',
        productName: 'طلبك',
      );
    }

    setState(() => _isLoading = false);

    if (orderId != null && mounted) {
      final needsConfirmation = paymentResult.requiresManualConfirmation;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: (needsConfirmation ? Colors.orange : Colors.green).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    needsConfirmation ? Icons.hourglass_top : Icons.check_circle,
                    color: needsConfirmation ? Colors.orange : Colors.green,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  needsConfirmation ? 'في انتظار التأكيد' : 'تم تأكيد طلبك!',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _text1),
                ),
                const SizedBox(height: 8),
                Text('رقم الطلب: #${orderId.substring(0, 8)}', style: TextStyle(fontSize: 14, color: _text2)),
                const SizedBox(height: 4),
                Text(
                  needsConfirmation
                    ? paymentResult.message
                    : 'سنتواصل معك قريباً لتأكيد التوصيل',
                  style: TextStyle(fontSize: 13, color: _text2),
                  textAlign: TextAlign.center,
                ),
                if (paymentResult.transactionId != null) ...[
                  const SizedBox(height: 8),
                  Text('رقم العملية: ${paymentResult.transactionId}', style: TextStyle(fontSize: 11, color: _text2)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // dialog
                      Navigator.pop(context); // checkout
                      Navigator.pop(context); // cart
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: const Text('متابعة التسوق', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final country = _currency.currentCountry;
    final fields = country.addressFields;
    final payments = country.paymentMethods;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          centerTitle: true,
          title: const Text('إتمام الطلب', style: TextStyle(fontWeight: FontWeight.bold, color: _text1, fontSize: 18)),
          backgroundColor: _card, foregroundColor: _teal, elevation: 0, surfaceTintColor: Colors.transparent,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Items summary ───
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('المنتجات (${_cart.itemCount})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _text1)),
                      const SizedBox(height: 10),
                      ..._cart.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Text(item.emoji, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Expanded(child: Text(item.name, style: const TextStyle(fontSize: 13, color: _text1), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            Text('×${item.quantity}', style: TextStyle(fontSize: 12, color: _text2)),
                            const SizedBox(width: 8),
                            Text(_fmtPrice(item.total), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _teal)),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ─── Personal info ───
                const Text('معلومات الطلب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _text1)),
                const SizedBox(height: 12),
                _buildField(_nameC, 'الاسم الكامل', Icons.person),
                _buildField(_phoneC, 'رقم الهاتف', Icons.phone, type: TextInputType.phone),
                const SizedBox(height: 8),

                // ─── Country ───
                GestureDetector(
                  onTap: () => _showCountryPicker(),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: _teal.withOpacity(0.06), borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _teal.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Text(country.flag, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('التوصيل إلى: ${country.nameAr}', style: const TextStyle(fontWeight: FontWeight.bold, color: _text1, fontSize: 14)),
                          Text('العملة: ${country.currencyNameAr} (${country.currencySymbol})', style: TextStyle(fontSize: 12, color: _text2)),
                        ])),
                        Icon(Icons.edit, color: _teal, size: 18),
                      ],
                    ),
                  ),
                ),

                // ─── Address ───
                const Text('عنوان التوصيل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _text1)),
                const SizedBox(height: 12),
                ...fields.map((field) {
                  if (!_addressControllers.containsKey(field.key)) {
                    _addressControllers[field.key] = TextEditingController();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: _addressControllers[field.key],
                      decoration: InputDecoration(
                        labelText: field.labelAr,
                        filled: true, fillColor: _card,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _teal, width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: field.required ? (v) => (v == null || v.isEmpty) ? 'هذا الحقل مطلوب' : null : null,
                    ),
                  );
                }),
                const SizedBox(height: 16),

                // ─── Payment ───
                const Text('طريقة الدفع', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _text1)),
                const SizedBox(height: 12),
                ...payments.map((pm) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPayment = pm.id),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _selectedPayment == pm.id ? _teal.withOpacity(0.06) : _card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _selectedPayment == pm.id ? _teal : Colors.grey[200]!, width: _selectedPayment == pm.id ? 1.5 : 1),
                      ),
                      child: Row(
                        children: [
                          Text(pm.icon, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 12),
                          Text(pm.nameAr, style: TextStyle(fontWeight: FontWeight.bold, color: _selectedPayment == pm.id ? _teal : _text1, fontSize: 14)),
                          const Spacer(),
                          if (_selectedPayment == pm.id) const Icon(Icons.check_circle, color: _teal, size: 22),
                        ],
                      ),
                    ),
                  ),
                )),
                const SizedBox(height: 24),

                // ─── Total ───
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                  child: Column(
                    children: [
                      _summaryRow('المنتجات', _fmtPrice(_cart.subtotal)),
                      const SizedBox(height: 8),
                      _summaryRow('التوصيل', 'مجاني'),
                      const Divider(height: 20),
                      _summaryRow('المجموع الكلي', _fmtPrice(_cart.subtotal), isBold: true),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ─── Confirm ───
                SizedBox(
                  width: double.infinity, height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _placeOrder,
                    icon: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_outline),
                    label: Text(_isLoading ? 'جاري إرسال الطلب...' : 'تأكيد الطلب', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _teal, foregroundColor: Colors.white, elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController c, String label, IconData icon, {TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label, prefixIcon: Icon(icon, color: _teal),
          filled: true, fillColor: _card,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _teal, width: 1.5)),
        ),
        validator: (v) => (v == null || v.isEmpty) ? 'هذا الحقل مطلوب' : null,
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isBold ? 16 : 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isBold ? _text1 : _text2)),
        Text(value, style: TextStyle(fontSize: isBold ? 18 : 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isBold ? _teal : _text1)),
      ],
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CountryPickerSheet(
        currentCode: _currency.currentCountry.code,
        onSelect: (code) {
          _currency.setCountry(code);
          Navigator.pop(context);
          _initAddressFields();
          setState(() {});
        },
      ),
    );
  }
}

// ─── Country Picker (reused) ───
class _CountryPickerSheet extends StatefulWidget {
  final String currentCode;
  final ValueChanged<String> onSelect;
  const _CountryPickerSheet({Key? key, required this.currentCode, required this.onSelect}) : super(key: key);

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = supportedCountries.where((c) =>
      c.nameAr.contains(_search) || c.nameEn.toLowerCase().contains(_search.toLowerCase())
    ).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('اختاري بلدك', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'ابحثي عن بلد...',
                  prefixIcon: const Icon(Icons.search, color: _teal),
                  filled: true, fillColor: _bg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final c = filtered[i];
                  final isSelected = c.code == widget.currentCode;
                  return ListTile(
                    onTap: () => widget.onSelect(c.code),
                    leading: Text(c.flag, style: const TextStyle(fontSize: 28)),
                    title: Text(c.nameAr, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? _teal : _text1)),
                    subtitle: Text('${c.currencyNameAr} (${c.currencySymbol})', style: TextStyle(fontSize: 12, color: _text2)),
                    trailing: isSelected ? const Icon(Icons.check_circle, color: _teal) : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
