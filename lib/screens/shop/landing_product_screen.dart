import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nabda_app/services/country_currency_service.dart';
import 'package:nabda_app/services/cart_service.dart';

class LandingProductScreen extends StatefulWidget {
  final Map<String, dynamic> productData;
  const LandingProductScreen({Key? key, required this.productData}) : super(key: key);

  @override
  State<LandingProductScreen> createState() => _LandingProductScreenState();
}

class _LandingProductScreenState extends State<LandingProductScreen> {
  final _currencySvc = CountryCurrencyService();
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final _nameC = TextEditingController();
  final _phoneC = TextEditingController();
  final _communeC = TextEditingController();
  final _stateC = TextEditingController(); // For other countries

  // State selections
  String? _selectedWilaya; // For Algeria dropdown
  String _shippingMethod = 'home'; // 'home' or 'pickup'
  int _quantity = 1;
  Map<String, dynamic>? _selectedOffer;
  Map<String, dynamic>? _selectedVariant;
  final Map<String, String> _selectedSecondaryOptions = {};

  bool _isOrdering = false;
  int _currentImageIndex = 0;

  // Static list of Algerian Wilayas
  final List<String> _wilayas = [
    '01- أدرار', '02- الشلف', '03- الأغواط', '04- أم البواقي', '05- باتنة',
    '06- بجاية', '07- بسكرة', '08- بشار', '09- البليدة', '10- البويرة',
    '11- تمنراست', '12- تبسة', '13- تلمسان', '14- تيارت', '15- تيزي وزو',
    '16- الجزائر', '17- الجلفة', '18- جيجل', '19- سطيف', '20- سعيدة',
    '21- سكيكدة', '22- سيدي بلعباس', '23- عنابة', '24- قالمة', '25- قسنطينة',
    '26- المدية', '27- مستغانم', '28- المسيلة', '29- معسكر', '30- ورقلة',
    '31- وهران', '32- البيض', '33- إليزي', '34- برج بوعريريج', '35- بومرداس',
    '36- الطارف', '37- تندوف', '38- تسمسيلت', '39- الوادي', '40- خنشلة',
    '41- سوق أهراس', '42- تيبازة', '43- ميلة', '44- عين الدفلى', '45- النعامة',
    '46- عين تموشنت', '47- غرداية', '48- غليزان', '49- تيميمون', '50- برج باجي مختار',
    '51- أولاد جلال', '52- بني عباس', '53- عين صالح', '54- عين قزام', '55- تقرت',
    '56- جانت', '57- المغير', '58- المنيعة'
  ];

  @override
  void initState() {
    super.initState();
    _currencySvc.addListener(_onCurrencyChange);
    
    // Auto-select default offer if exists
    final offers = widget.productData['offers'] as List<dynamic>? ?? [];
    if (offers.isNotEmpty) {
      final defOffer = offers.firstWhere((o) => o['isDefault'] == true, orElse: () => offers.first);
      _selectedOffer = Map<String, dynamic>.from(defOffer);
      _quantity = _selectedOffer!['quantity'] ?? 1;
    }

    // Auto-select first variant if exists
    final variants = widget.productData['variants'] as List<dynamic>? ?? [];
    if (variants.isNotEmpty) {
      final firstEnabled = variants.firstWhere((v) => v['enabled'] == true, orElse: () => variants.first);
      _selectedVariant = Map<String, dynamic>.from(firstEnabled);
    }
  }

  @override
  void dispose() {
    _currencySvc.removeListener(_onCurrencyChange);
    _nameC.dispose();
    _phoneC.dispose();
    _communeC.dispose();
    _stateC.dispose();
    super.dispose();
  }

  void _onCurrencyChange() {
    if (mounted) setState(() {});
  }

  // Calculate prices based on selection (offer vs standard price)
  double get _unitPrice {
    if (_selectedOffer != null) {
      return (_selectedOffer!['pricePerPiece'] ?? 0.0).toDouble();
    }
    final priceStr = widget.productData['price'] ?? '0';
    return CountryCurrencyService.parseDZDPrice(priceStr);
  }

  double get _subtotal {
    return _unitPrice * _quantity;
  }

  double get _shippingCost {
    final sh = widget.productData['shipping'] as Map<String, dynamic>? ?? {};
    
    // Check if selected offer grants free shipping
    if (_selectedOffer != null && (_selectedOffer!['freeShipping'] ?? false) == true) {
      return 0.0;
    }

    // Check general shipping settings
    final freeShipping = sh['freeShipping'] ?? false;
    final freeShippingPickupOnly = sh['freeShippingPickupOnly'] ?? false;
    final customShipping = sh['customShipping'] ?? false;
    final customShippingPrice = (sh['customShippingPrice'] ?? 0.0).toDouble();
    final customShippingPickup = sh['customShippingPickup'] ?? false;
    final customShippingPickupPrice = (sh['customShippingPickupPrice'] ?? 0.0).toDouble();

    if (_shippingMethod == 'home') {
      if (freeShipping) return 0.0;
      if (customShipping) return customShippingPrice;
      return 500.0; // standard Home Delivery DZD
    } else {
      if (freeShipping || freeShippingPickupOnly) return 0.0;
      if (customShippingPickup) return customShippingPickupPrice;
      return 300.0; // standard Pickup DZD
    }
  }

  double get _totalAmount {
    return _subtotal + _shippingCost;
  }

  // Theme Colors
  static const Color _teal = Color(0xFF009688);
  static const Color _lightTeal = Color(0xFFE0F2F1);
  static const Color _bg = Color(0xFFF9F9F9);
  static const Color _card = Colors.white;
  static const Color _textPrimary = Color(0xFF2D2D3A);
  static const Color _textSecondary = Color(0xFF6B7280);

  // Helper formatting DZD to local currency
  String _formatPrice(double dzdPrice) {
    return _currencySvc.formatPrice(dzdPrice);
  }

  // Validate strict options
  bool _validateOptions() {
    final settings = widget.productData['settings'] as Map<String, dynamic>? ?? {};
    final strictOptions = settings['strictOptions'] ?? false;

    if (!strictOptions) return true;

    final variants = widget.productData['variants'] as List<dynamic>? ?? [];
    if (variants.isNotEmpty && _selectedVariant == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('يرجى تحديد خيار اللون أولاً 🎨'),
        backgroundColor: Colors.orange,
      ));
      return false;
    }

    final secOpts = widget.productData['secondaryOptions'] as List<dynamic>? ?? [];
    for (final opt in secOpts) {
      final title = opt['title'] ?? '';
      if (!_selectedSecondaryOptions.containsKey(title) || _selectedSecondaryOptions[title]!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('يرجى اختيار $title أولاً 📏'),
          backgroundColor: Colors.orange,
        ));
        return false;
      }
    }
    return true;
  }

  // Create order in Firestore
  Future<void> _placeDirectOrder() async {
    if (!_validateOptions()) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isOrdering = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
      final country = _currencySvc.currentCountry;

      // Address construction
      String address = '';
      if (country.code == 'DZ') {
        final wil = _selectedWilaya ?? '';
        final com = _communeC.text.trim();
        address = 'الولاية: $wil - البلدية: $com';
      } else {
        final state = _stateC.text.trim();
        final com = _communeC.text.trim();
        address = 'الولاية/المحافظة: $state - المدينة: $com';
      }
      
      final deliveryTypeLabel = _shippingMethod == 'home' ? 'توصيل للبيت' : 'استلام من المكتب';
      address += ' ($deliveryTypeLabel)';

      final productName = widget.productData['name'] ?? '';
      final productEmoji = widget.productData['emoji'] ?? '🛍️';
      final productCategory = widget.productData['category'] ?? 'عام';
      final productId = widget.productData['id'] ?? '';

      final variantTitle = _selectedVariant != null ? _selectedVariant!['title'] : '';
      
      // Build selected secondary options list summary
      final List<String> optSummary = [];
      _selectedSecondaryOptions.forEach((k, v) => optSummary.add('$k: $v'));
      final optionValue = optSummary.join(', ');

      final offerTitle = _selectedOffer != null ? _selectedOffer!['title'] : '';

      final orderMap = <String, dynamic>{
        'userId': uid,
        'customerName': _nameC.text.trim(),
        'phone': _phoneC.text.trim(),
        'address': address,
        'country': country.code,
        'paymentMethod': 'cod',
        'items': [
          {
            'name': productName,
            'emoji': productEmoji,
            'category': productCategory,
            'priceValue': _unitPrice,
            'priceDisplay': _formatPrice(_unitPrice),
            'quantity': _quantity,
            'variant': variantTitle,
            'option': optionValue,
            'offerTitle': offerTitle,
            'productId': productId,
          }
        ],
        'subtotal': _subtotal,
        'shipping': _shippingCost,
        'totalAmount': _totalAmount,
        'totalDisplay': _formatPrice(_totalAmount),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'couponCode': null,
        'discount': 0.0,
        // For admin panel compatibility
        'productName': productName,
        'total': _formatPrice(_totalAmount),
      };

      // 1. Write to general orders collection
      final docRef = await FirebaseFirestore.instance.collection('orders').add(orderMap);

      // 2. Write to user's orders subcollection if logged in
      if (uid != 'guest') {
        // Prepare local timestamp version for set call (since FieldValue isn't supported in set options sometimes or for local safety)
        final localOrderMap = Map<String, dynamic>.from(orderMap);
        localOrderMap['createdAt'] = Timestamp.now();
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('orders')
            .doc(docRef.id)
            .set(localOrderMap);
      }

      // Decrement stock if stock management is set
      try {
        final productRef = FirebaseFirestore.instance.collection('products').doc(productId);
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final freshSnap = await transaction.get(productRef);
          if (freshSnap.exists) {
            final freshData = freshSnap.data() as Map<String, dynamic>;
            final stock = freshData['stock'] as int? ?? 0;
            final settings = freshData['settings'] as Map<String, dynamic>? ?? {};
            final allowBackorder = settings['allowBackorder'] ?? false;
            
            if (stock > 0 && !allowBackorder) {
              final newStock = stock - _quantity >= 0 ? stock - _quantity : 0;
              transaction.update(productRef, {'stock': newStock});
            }
          }
        });
      } catch (e) {
        debugPrint('Stock decrement error: $e');
      }

      // Navigate to Thank You screen
      if (mounted) {
        final settings = widget.productData['settings'] as Map<String, dynamic>? ?? {};
        final thankYouText = settings['customThankYou'] == true ? (settings['thankYouText'] as String? ?? '') : '';
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => _ThankYouScreen(
              orderId: docRef.id,
              totalDisplay: _formatPrice(_totalAmount),
              customMessage: thankYouText,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('COD Order Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('خطأ في إرسال الطلب: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isOrdering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final country = _currencySvc.currentCountry;
    final d = widget.productData;

    // Build image list: priority coverImage, then imageUrls, then fallback imageUrl
    final List<String> images = [];
    final cov = d['coverImage'] as String?;
    if (cov != null && cov.trim().isNotEmpty) images.add(cov);
    
    final imageUrls = d['imageUrls'] as List<dynamic>? ?? [];
    for (final url in imageUrls) {
      final s = url.toString().trim();
      if (s.isNotEmpty && !images.contains(s)) images.add(s);
    }
    if (images.isEmpty) {
      final single = d['imageUrl'] as String?;
      if (single != null && single.trim().isNotEmpty) images.add(single);
    }

    final variants = d['variants'] as List<dynamic>? ?? [];
    final secondaryOptions = d['secondaryOptions'] as List<dynamic>? ?? [];
    final offers = d['offers'] as List<dynamic>? ?? [];
    final reviews = d['reviews'] as List<dynamic>? ?? [];
    final shortDesc = d['shortDescription'] as String? ?? '';
    final descImages = d['descImages'] as List<dynamic>? ?? [];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: Text(d['name'] ?? 'تفاصيل المنتج', style: const TextStyle(fontWeight: FontWeight.bold, color: _textPrimary, fontSize: 16)),
          backgroundColor: Colors.white,
          foregroundColor: _teal,
          elevation: 0.5,
          surfaceTintColor: Colors.transparent,
        ),
        body: _isOrdering
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: _teal),
                    SizedBox(height: 16),
                    Text('جاري تسجيل طلبك المباشر...', style: TextStyle(fontWeight: FontWeight.bold, color: _textPrimary)),
                    SizedBox(height: 6),
                    Text('يرجى عدم مغادرة الصفحة', style: TextStyle(color: _textSecondary, fontSize: 13)),
                  ],
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Hero Gallery
                    if (images.isNotEmpty)
                      Stack(
                        children: [
                          SizedBox(
                            height: 320,
                            width: double.infinity,
                            child: PageView.builder(
                              itemCount: images.length,
                              onPageChanged: (idx) => setState(() => _currentImageIndex = idx),
                              itemBuilder: (context, idx) {
                                return Image.network(images[idx], fit: BoxFit.cover, errorBuilder: (_, __, ___) {
                                  return Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, size: 60, color: Colors.grey));
                                });
                              },
                            ),
                          ),
                          // Indicators
                          if (images.length > 1)
                            Positioned(
                              bottom: 12,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: images.asMap().entries.map((e) {
                                  return Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _currentImageIndex == e.key ? _teal : Colors.white.withOpacity(0.6),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      )
                    else
                      Container(
                        height: 200,
                        color: _lightTeal.withOpacity(0.3),
                        child: Center(child: Text(d['emoji'] ?? '🛍️', style: const TextStyle(fontSize: 80))),
                      ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category badge & rating
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: _teal.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                                child: Text(d['category'] ?? 'عام', style: const TextStyle(fontSize: 12, color: _teal, fontWeight: FontWeight.bold)),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 18),
                                  const SizedBox(width: 4),
                                  Text((d['rating'] ?? 4.5).toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Product Name
                          Text(d['name'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textPrimary)),
                          const SizedBox(height: 6),

                          // Short Description
                          if (shortDesc.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(shortDesc, style: const TextStyle(fontSize: 14, color: _textSecondary, height: 1.5)),
                            ),

                          // Pricing
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                _formatPrice(_unitPrice),
                                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _teal),
                              ),
                              const SizedBox(width: 12),
                              if (d['oldPrice'] != null && (d['oldPrice'] as String).trim().isNotEmpty)
                                Text(
                                  d['oldPrice'],
                                  style: const TextStyle(fontSize: 16, color: Colors.red, decoration: TextDecoration.lineThrough),
                                ),
                            ],
                          ),
                          const Divider(height: 30),

                          // 2. Main Options / Colors
                          if (variants.isNotEmpty) ...[
                            const Text('اختر اللون / الخيار 🎨', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textPrimary)),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 62,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: variants.length,
                                itemBuilder: (context, idx) {
                                  final v = variants[idx];
                                  final isEnabled = v['enabled'] ?? true;
                                  if (!isEnabled) return const SizedBox.shrink();

                                  final title = v['title'] ?? '';
                                  final hex = (v['colorHex'] ?? 'FFFFFF').replaceAll('#', '');
                                  final isSelected = _selectedVariant != null && _selectedVariant!['title'] == title;

                                  Color col = Colors.white;
                                  try { col = Color(int.parse('FF$hex', radix: 16)); } catch (_) {}

                                  return GestureDetector(
                                    onTap: () => setState(() => _selectedVariant = v),
                                    child: Container(
                                      margin: const EdgeInsets.only(left: 10),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected ? _lightTeal : Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: isSelected ? _teal : Colors.grey[200]!, width: isSelected ? 2 : 1),
                                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 18, height: 18,
                                            decoration: BoxDecoration(
                                              color: col,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.grey[300]!),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: _textPrimary)),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // 3. Secondary Options (e.g. Sizes)
                          if (secondaryOptions.isNotEmpty) ...[
                            ...secondaryOptions.map((opt) {
                              final title = opt['title'] ?? '';
                              final List<dynamic> vals = opt['values'] ?? [];
                              if (vals.isEmpty) return const SizedBox.shrink();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('اختر $title 📏', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textPrimary)),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    height: 44,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: vals.length,
                                      itemBuilder: (context, idx) {
                                        final valStr = vals[idx].toString();
                                        final isSelected = _selectedSecondaryOptions[title] == valStr;

                                        return GestureDetector(
                                          onTap: () => setState(() => _selectedSecondaryOptions[title] = valStr),
                                          child: Container(
                                            margin: const EdgeInsets.only(left: 8),
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: isSelected ? _teal : Colors.white,
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: isSelected ? _teal : Colors.grey[200]!),
                                            ),
                                            child: Center(
                                              child: Text(
                                                valStr,
                                                style: TextStyle(
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                  color: isSelected ? Colors.white : _textPrimary,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              );
                            }),
                          ],

                          // 4. Quantity Offers (Offers)
                          if (offers.isNotEmpty) ...[
                            const Text('العروض الخاصة والتخفيضات 🎁', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: _textPrimary)),
                            const SizedBox(height: 10),
                            ...offers.map((offer) {
                              final title = offer['title'] ?? '';
                              final qty = offer['quantity'] ?? 1;
                              final pricePerUnit = (offer['pricePerPiece'] ?? 0.0).toDouble();
                              final freeSh = offer['freeShipping'] ?? false;
                              final isBest = offer['isBest'] ?? false;
                              
                              final isSelected = _selectedOffer != null && _selectedOffer!['title'] == title;

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedOffer = offer;
                                    _quantity = qty;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isSelected ? _lightTeal.withOpacity(0.4) : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: isSelected ? _teal : Colors.grey[200]!, width: isSelected ? 2 : 1),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)],
                                  ),
                                  child: Stack(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            isSelected ? Icons.check_circle : Icons.radio_button_off,
                                            color: isSelected ? _teal : Colors.grey[400],
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _textPrimary)),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Text(
                                                      '${_formatPrice(pricePerUnit)} للقطعة',
                                                      style: const TextStyle(color: _teal, fontSize: 13, fontWeight: FontWeight.bold),
                                                    ),
                                                    if (freeSh) ...[
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(6)),
                                                        child: const Text('شحن مجاني', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Grand Total for this tier
                                          Text(
                                            _formatPrice(pricePerUnit * qty),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textPrimary),
                                          ),
                                        ],
                                      ),
                                      if (isBest)
                                        Positioned(
                                          top: -4,
                                          left: 0,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.red[400], borderRadius: BorderRadius.circular(6)),
                                            child: const Text('أفضل توفير ⭐', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                            const SizedBox(height: 12),
                          ] else ...[
                            // Standard Quantity selector if no offers
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('الكمية المطلوبة 🔢', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textPrimary)),
                                Container(
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove, size: 20),
                                        onPressed: () {
                                          if (_quantity > 1) setState(() => _quantity--);
                                        },
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 14),
                                        child: Text(_quantity.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add, size: 20),
                                        onPressed: () {
                                          setState(() => _quantity++);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Description
                          if ((d['description'] as String? ?? '').trim().isNotEmpty) ...[
                            const Text('وصف وتفاصيل المنتج 📋', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: _textPrimary)),
                            const SizedBox(height: 8),
                            Text(d['description'], style: const TextStyle(fontSize: 14, color: _textPrimary, height: 1.6)),
                            const SizedBox(height: 12),
                          ],

                          // Description Images
                          if (descImages.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            ...descImages.map((url) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.network(url.toString(), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                                ),
                              );
                            }),
                          ],

                          // 5. Social Proof Reviews Section
                          if (reviews.isNotEmpty) ...[
                            const Divider(height: 40),
                            Row(
                              children: [
                                const Text('مراجعات وآراء الأمهات 💬', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _textPrimary)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(10)),
                                  child: Text('${reviews.length} تقييمات', style: const TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: reviews.length,
                              itemBuilder: (context, idx) {
                                final r = reviews[idx];
                                final rName = r['name'] ?? 'مستخدمة';
                                final rGender = r['gender'] ?? 'female';
                                final rRating = (r['rating'] ?? 5.0).toDouble();
                                final rText = r['text'] ?? '';
                                final rUrl = r['image'] as String?;

                                final defaultAvatar = Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: rGender == 'female' ? const Color(0xFFFCE4EC) : const Color(0xFFE3F2FD),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    rGender == 'female' ? Icons.face_retouching_natural : Icons.face,
                                    color: rGender == 'female' ? Colors.pink : Colors.blue,
                                    size: 24,
                                  ),
                                );

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[100]!)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          rUrl != null && rUrl.isNotEmpty
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(22),
                                                  child: Image.network(rUrl, width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (_, __, ___) => defaultAvatar),
                                                )
                                              : defaultAvatar,
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(rName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _textPrimary)),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: List.generate(5, (sIdx) {
                                                    return Icon(
                                                      sIdx < rRating ? Icons.star : Icons.star_border,
                                                      color: Colors.amber,
                                                      size: 14,
                                                    );
                                                  }),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (rText.isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        Text(rText, style: const TextStyle(fontSize: 13, height: 1.5, color: _textPrimary)),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],

                          const Divider(height: 50),

                          // 6. Direct COD Checkout Form
                          Container(
                            key: const ValueKey('checkout_form'),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _teal.withOpacity(0.3), width: 1.5),
                              boxShadow: [BoxShadow(color: _teal.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(color: _teal.withOpacity(0.1), shape: BoxShape.circle),
                                        child: const Icon(Icons.flash_on, color: _teal, size: 20),
                                      ),
                                      const SizedBox(width: 10),
                                      const Text('طلب سريع (الدفع عند الاستلام)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: _textPrimary)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Name Field
                                  TextFormField(
                                    controller: _nameC,
                                    decoration: InputDecoration(
                                      labelText: 'الاسم الكامل للمستلم',
                                      prefixIcon: const Icon(Icons.person_outline, color: _teal),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    ),
                                    validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى كتابة الاسم الكامل' : null,
                                  ),
                                  const SizedBox(height: 12),

                                  // Phone Field
                                  TextFormField(
                                    controller: _phoneC,
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      labelText: 'رقم الهاتف (الرجاء التأكد منه)',
                                      prefixIcon: const Icon(Icons.phone_outlined, color: _teal),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    ),
                                    validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى كتابة رقم الهاتف للاتصال' : null,
                                  ),
                                  const SizedBox(height: 16),

                                  // Shipping choice
                                  const Text('طريقة الشحن والتوصيل 🚚', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _textPrimary)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ChoiceChip(
                                          label: const Center(child: Text('توصيل للمنزل')),
                                          selected: _shippingMethod == 'home',
                                          selectedColor: _teal.withOpacity(0.12),
                                          onSelected: (selected) {
                                            if (selected) setState(() => _shippingMethod = 'home');
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: ChoiceChip(
                                          label: const Center(child: Text('استلام من المكتب')),
                                          selected: _shippingMethod == 'pickup',
                                          selectedColor: _teal.withOpacity(0.12),
                                          onSelected: (selected) {
                                            if (selected) setState(() => _shippingMethod = 'pickup');
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Dynamic Location picker: Algeria vs others
                                  if (country.code == 'DZ') ...[
                                    // Algeria: Wilaya dropdown
                                    DropdownButtonFormField<String>(
                                      value: _selectedWilaya,
                                      decoration: InputDecoration(
                                        labelText: 'الولاية',
                                        prefixIcon: const Icon(Icons.map_outlined, color: _teal),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      ),
                                      items: _wilayas.map((w) {
                                        return DropdownMenuItem(value: w, child: Text(w));
                                      }).toList(),
                                      onChanged: (val) => setState(() => _selectedWilaya = val),
                                      validator: (v) => v == null ? 'يرجى اختيار الولاية' : null,
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Commune text field
                                    TextFormField(
                                      controller: _communeC,
                                      decoration: InputDecoration(
                                        labelText: 'البلدية',
                                        prefixIcon: const Icon(Icons.location_city_outlined, color: _teal),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      ),
                                      validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى كتابة اسم البلدية' : null,
                                    ),
                                  ] else ...[
                                    // Other countries: State Text field
                                    TextFormField(
                                      controller: _stateC,
                                      decoration: InputDecoration(
                                        labelText: 'المحافظة / الولاية',
                                        prefixIcon: const Icon(Icons.map_outlined, color: _teal),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      ),
                                      validator: (v) => (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Commune/City Text field
                                    TextFormField(
                                      controller: _communeC,
                                      decoration: InputDecoration(
                                        labelText: 'المدينة / المنطقة',
                                        prefixIcon: const Icon(Icons.location_city_outlined, color: _teal),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      ),
                                      validator: (v) => (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
                                    ),
                                  ],
                                  
                                  const Divider(height: 40),

                                  // Invoice summary
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('المجموع الفرعي:', style: TextStyle(color: _textSecondary)),
                                      Text(_formatPrice(_subtotal), style: const TextStyle(fontWeight: FontWeight.bold, color: _textPrimary)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('مصاريف التوصيل:', style: TextStyle(color: _textSecondary)),
                                      Text(
                                        _shippingCost == 0.0 ? 'مجاني' : _formatPrice(_shippingCost),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _shippingCost == 0.0 ? Colors.green : _textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('المجموع الإجمالي:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary)),
                                      Text(
                                        _formatPrice(_totalAmount),
                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _teal),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // Submit button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: ElevatedButton.icon(
                                      onPressed: _placeDirectOrder,
                                      icon: const Icon(Icons.flash_on),
                                      label: const Text('اطلبي الآن (الدفع عند الاستلام)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _teal,
                                        foregroundColor: Colors.white,
                                        elevation: 4,
                                        shadowColor: _teal.withOpacity(0.4),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// ─── Thank You screen ───
class _ThankYouScreen extends StatelessWidget {
  final String orderId;
  final String totalDisplay;
  final String customMessage;

  const _ThankYouScreen({
    Key? key,
    required this.orderId,
    required this.totalDisplay,
    required this.customMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success Badge with Pulse Effect
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.green, size: 80),
                ),
                const SizedBox(height: 24),

                const Text(
                  'شكراً لكِ! تم تسجيل طلبكِ بنجاح 🎉',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D2D3A)),
                ),
                const SizedBox(height: 12),

                Text(
                  'رقم الطلب الخاص بكِ هو: #$orderId',
                  style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                // Order details box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('المبلغ الإجمالي عند الاستلام:', style: TextStyle(color: Colors.grey)),
                          Text(totalDisplay, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF009688))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('حالة الطلب:', style: TextStyle(color: Colors.grey)),
                          Text('قيد المراجعة الهاتفية', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Custom Thank You Message
                if (customMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      customMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF2D2D3A), fontWeight: FontWeight.w500),
                    ),
                  )
                else
                  const Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      'سيتصل بكِ فريق العمل الخاص بنا لتأكيد الطلب الهاتفي وشحن المنتج إليكِ في أقرب وقت ممكن.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, height: 1.6, color: Colors.grey),
                    ),
                  ),

                // Home button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF009688),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('العودة للمتجر الرئيسي', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
