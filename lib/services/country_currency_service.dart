import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ─── Address Field Model ───
class AddressField {
  final String key;
  final String labelAr;
  final String labelEn;
  final bool required;
  const AddressField({required this.key, required this.labelAr, required this.labelEn, this.required = true});
}

// ─── Payment Method Model ───
class PaymentMethod {
  final String id;
  final String nameAr;
  final String nameEn;
  final String icon;
  final bool isDefault;
  const PaymentMethod({required this.id, required this.nameAr, required this.nameEn, required this.icon, this.isDefault = false});
}

// ─── Country Data Model ───
class CountryData {
  final String code;       // ISO 3166-1 alpha-2
  final String nameAr;
  final String nameEn;
  final String flag;       // emoji flag
  final String currencyCode; // ISO 4217
  final String currencyNameAr;
  final String currencyNameEn;
  final String currencySymbol;
  final String phonePrefix;
  final List<AddressField> addressFields;
  final List<PaymentMethod> paymentMethods;
  final int decimalPlaces;

  const CountryData({
    required this.code,
    required this.nameAr,
    required this.nameEn,
    required this.flag,
    required this.currencyCode,
    required this.currencyNameAr,
    required this.currencyNameEn,
    required this.currencySymbol,
    required this.phonePrefix,
    required this.addressFields,
    required this.paymentMethods,
    this.decimalPlaces = 2,
  });
}

// ─── Standard Address Fields ───
const _nameField = AddressField(key: 'name', labelAr: 'الاسم الكامل', labelEn: 'Full Name');
const _phoneField = AddressField(key: 'phone', labelAr: 'رقم الهاتف', labelEn: 'Phone');
const _streetField = AddressField(key: 'street', labelAr: 'العنوان / الشارع', labelEn: 'Street Address');
const _cityField = AddressField(key: 'city', labelAr: 'المدينة', labelEn: 'City');
const _stateField = AddressField(key: 'state', labelAr: 'الولاية', labelEn: 'State/Province');
const _zipField = AddressField(key: 'zip', labelAr: 'الرمز البريدي', labelEn: 'Postal Code', required: false);
const _notesField = AddressField(key: 'notes', labelAr: 'ملاحظات التوصيل', labelEn: 'Delivery Notes', required: false);

// Algeria-specific
const _communeField = AddressField(key: 'commune', labelAr: 'البلدية', labelEn: 'Commune');
const _wilayaField = AddressField(key: 'wilaya', labelAr: 'الولاية', labelEn: 'Wilaya');

// Saudi-specific
const _districtField = AddressField(key: 'district', labelAr: 'الحي', labelEn: 'District');
const _buildingField = AddressField(key: 'building', labelAr: 'رقم المبنى', labelEn: 'Building Number', required: false);

// Egypt-specific
const _governorateField = AddressField(key: 'governorate', labelAr: 'المحافظة', labelEn: 'Governorate');
const _landmarkField = AddressField(key: 'landmark', labelAr: 'علامة مميزة', labelEn: 'Landmark', required: false);

// ─── Standard Payment Methods ───
const _cod = PaymentMethod(id: 'cod', nameAr: 'الدفع عند الاستلام', nameEn: 'Cash on Delivery', icon: '💵', isDefault: true);
const _visa = PaymentMethod(id: 'visa', nameAr: 'فيزا', nameEn: 'Visa', icon: '💳');
const _mastercard = PaymentMethod(id: 'mastercard', nameAr: 'ماستركارد', nameEn: 'Mastercard', icon: '💳');
const _ccp = PaymentMethod(id: 'ccp', nameAr: 'بريد الجزائر CCP', nameEn: 'Algerie Poste CCP', icon: '🏦');
const _baridimob = PaymentMethod(id: 'baridimob', nameAr: 'بريدي موب', nameEn: 'BaridiMob', icon: '📱');
const _dahabia = PaymentMethod(id: 'dahabia', nameAr: 'بطاقة الذهبية', nameEn: 'Dahabia Card', icon: '💳');
const _mada = PaymentMethod(id: 'mada', nameAr: 'مدى', nameEn: 'Mada', icon: '💳');
const _stcPay = PaymentMethod(id: 'stc_pay', nameAr: 'STC Pay', nameEn: 'STC Pay', icon: '📱');
const _applePay = PaymentMethod(id: 'apple_pay', nameAr: 'Apple Pay', nameEn: 'Apple Pay', icon: '🍎');
const _vodafoneCash = PaymentMethod(id: 'vodafone_cash', nameAr: 'فودافون كاش', nameEn: 'Vodafone Cash', icon: '📱');
const _fawry = PaymentMethod(id: 'fawry', nameAr: 'فوري', nameEn: 'Fawry', icon: '🏪');
const _instaPay = PaymentMethod(id: 'instapay', nameAr: 'إنستاباي', nameEn: 'InstaPay', icon: '📱');

// ─── All Supported Countries ───
final List<CountryData> supportedCountries = [
  // 🇩🇿 Algeria
  CountryData(
    code: 'DZ', nameAr: 'الجزائر', nameEn: 'Algeria', flag: '🇩🇿',
    currencyCode: 'DZD', currencyNameAr: 'دينار جزائري', currencyNameEn: 'Algerian Dinar',
    currencySymbol: 'د.ج', phonePrefix: '+213', decimalPlaces: 2,
    addressFields: [_nameField, _phoneField, _streetField, _communeField, _wilayaField, _zipField, _notesField],
    paymentMethods: [_cod, _dahabia, _ccp, _baridimob],
  ),
  // 🇸🇦 Saudi Arabia
  CountryData(
    code: 'SA', nameAr: 'السعودية', nameEn: 'Saudi Arabia', flag: '🇸🇦',
    currencyCode: 'SAR', currencyNameAr: 'ريال سعودي', currencyNameEn: 'Saudi Riyal',
    currencySymbol: 'ر.س', phonePrefix: '+966', decimalPlaces: 2,
    addressFields: [_nameField, _phoneField, _streetField, _districtField, _cityField, _buildingField, _zipField, _notesField],
    paymentMethods: [_mada, _stcPay, _applePay, _visa, _mastercard, _cod],
  ),
  // 🇪🇬 Egypt
  CountryData(
    code: 'EG', nameAr: 'مصر', nameEn: 'Egypt', flag: '🇪🇬',
    currencyCode: 'EGP', currencyNameAr: 'جنيه مصري', currencyNameEn: 'Egyptian Pound',
    currencySymbol: 'ج.م', phonePrefix: '+20', decimalPlaces: 2,
    addressFields: [_nameField, _phoneField, _streetField, _governorateField, _cityField, _landmarkField, _zipField, _notesField],
    paymentMethods: [_cod, _vodafoneCash, _fawry, _instaPay, _visa, _mastercard],
  ),
  // 🇲🇦 Morocco
  CountryData(
    code: 'MA', nameAr: 'المغرب', nameEn: 'Morocco', flag: '🇲🇦',
    currencyCode: 'MAD', currencyNameAr: 'درهم مغربي', currencyNameEn: 'Moroccan Dirham',
    currencySymbol: 'د.م', phonePrefix: '+212', decimalPlaces: 2,
    addressFields: [_nameField, _phoneField, _streetField, _cityField, _stateField, _zipField, _notesField],
    paymentMethods: [_cod, _visa, _mastercard],
  ),
  // 🇹🇳 Tunisia
  CountryData(
    code: 'TN', nameAr: 'تونس', nameEn: 'Tunisia', flag: '🇹🇳',
    currencyCode: 'TND', currencyNameAr: 'دينار تونسي', currencyNameEn: 'Tunisian Dinar',
    currencySymbol: 'د.ت', phonePrefix: '+216', decimalPlaces: 3,
    addressFields: [_nameField, _phoneField, _streetField, _cityField, _stateField, _zipField, _notesField],
    paymentMethods: [_cod, _visa, _mastercard],
  ),
  // 🇦🇪 UAE
  CountryData(
    code: 'AE', nameAr: 'الإمارات', nameEn: 'UAE', flag: '🇦🇪',
    currencyCode: 'AED', currencyNameAr: 'درهم إماراتي', currencyNameEn: 'UAE Dirham',
    currencySymbol: 'د.إ', phonePrefix: '+971', decimalPlaces: 2,
    addressFields: [_nameField, _phoneField, _streetField, _districtField, _cityField, _buildingField, _notesField],
    paymentMethods: [_applePay, _visa, _mastercard, _cod],
  ),
  // 🇰🇼 Kuwait
  CountryData(
    code: 'KW', nameAr: 'الكويت', nameEn: 'Kuwait', flag: '🇰🇼',
    currencyCode: 'KWD', currencyNameAr: 'دينار كويتي', currencyNameEn: 'Kuwaiti Dinar',
    currencySymbol: 'د.ك', phonePrefix: '+965', decimalPlaces: 3,
    addressFields: [_nameField, _phoneField, _streetField, _districtField, _cityField, _notesField],
    paymentMethods: [_visa, _mastercard, _applePay, _cod],
  ),
  // 🇶🇦 Qatar
  CountryData(
    code: 'QA', nameAr: 'قطر', nameEn: 'Qatar', flag: '🇶🇦',
    currencyCode: 'QAR', currencyNameAr: 'ريال قطري', currencyNameEn: 'Qatari Riyal',
    currencySymbol: 'ر.ق', phonePrefix: '+974', decimalPlaces: 2,
    addressFields: [_nameField, _phoneField, _streetField, _districtField, _cityField, _buildingField, _notesField],
    paymentMethods: [_visa, _mastercard, _applePay, _cod],
  ),
  // 🇧🇭 Bahrain
  CountryData(
    code: 'BH', nameAr: 'البحرين', nameEn: 'Bahrain', flag: '🇧🇭',
    currencyCode: 'BHD', currencyNameAr: 'دينار بحريني', currencyNameEn: 'Bahraini Dinar',
    currencySymbol: 'د.ب', phonePrefix: '+973', decimalPlaces: 3,
    addressFields: [_nameField, _phoneField, _streetField, _districtField, _cityField, _buildingField, _notesField],
    paymentMethods: [_visa, _mastercard, _applePay, _cod],
  ),
  // 🇴🇲 Oman
  CountryData(
    code: 'OM', nameAr: 'عُمان', nameEn: 'Oman', flag: '🇴🇲',
    currencyCode: 'OMR', currencyNameAr: 'ريال عماني', currencyNameEn: 'Omani Rial',
    currencySymbol: 'ر.ع', phonePrefix: '+968', decimalPlaces: 3,
    addressFields: [_nameField, _phoneField, _streetField, _cityField, _stateField, _zipField, _notesField],
    paymentMethods: [_visa, _mastercard, _cod],
  ),
  // 🇯🇴 Jordan
  CountryData(
    code: 'JO', nameAr: 'الأردن', nameEn: 'Jordan', flag: '🇯🇴',
    currencyCode: 'JOD', currencyNameAr: 'دينار أردني', currencyNameEn: 'Jordanian Dinar',
    currencySymbol: 'د.أ', phonePrefix: '+962', decimalPlaces: 3,
    addressFields: [_nameField, _phoneField, _streetField, _cityField, _stateField, _zipField, _notesField],
    paymentMethods: [_cod, _visa, _mastercard],
  ),
  // 🇮🇶 Iraq
  CountryData(
    code: 'IQ', nameAr: 'العراق', nameEn: 'Iraq', flag: '🇮🇶',
    currencyCode: 'IQD', currencyNameAr: 'دينار عراقي', currencyNameEn: 'Iraqi Dinar',
    currencySymbol: 'د.ع', phonePrefix: '+964', decimalPlaces: 0,
    addressFields: [_nameField, _phoneField, _streetField, _cityField, _stateField, _notesField],
    paymentMethods: [_cod, _visa, _mastercard],
  ),
  // 🇱🇾 Libya
  CountryData(
    code: 'LY', nameAr: 'ليبيا', nameEn: 'Libya', flag: '🇱🇾',
    currencyCode: 'LYD', currencyNameAr: 'دينار ليبي', currencyNameEn: 'Libyan Dinar',
    currencySymbol: 'د.ل', phonePrefix: '+218', decimalPlaces: 3,
    addressFields: [_nameField, _phoneField, _streetField, _cityField, _stateField, _notesField],
    paymentMethods: [_cod],
  ),
  // 🇸🇩 Sudan
  CountryData(
    code: 'SD', nameAr: 'السودان', nameEn: 'Sudan', flag: '🇸🇩',
    currencyCode: 'SDG', currencyNameAr: 'جنيه سوداني', currencyNameEn: 'Sudanese Pound',
    currencySymbol: 'ج.س', phonePrefix: '+249', decimalPlaces: 2,
    addressFields: [_nameField, _phoneField, _streetField, _cityField, _stateField, _notesField],
    paymentMethods: [_cod],
  ),
  // 🇾🇪 Yemen
  CountryData(
    code: 'YE', nameAr: 'اليمن', nameEn: 'Yemen', flag: '🇾🇪',
    currencyCode: 'YER', currencyNameAr: 'ريال يمني', currencyNameEn: 'Yemeni Rial',
    currencySymbol: 'ر.ي', phonePrefix: '+967', decimalPlaces: 0,
    addressFields: [_nameField, _phoneField, _streetField, _cityField, _stateField, _notesField],
    paymentMethods: [_cod],
  ),
  // 🇱🇧 Lebanon
  CountryData(
    code: 'LB', nameAr: 'لبنان', nameEn: 'Lebanon', flag: '🇱🇧',
    currencyCode: 'USD', currencyNameAr: 'دولار أمريكي', currencyNameEn: 'US Dollar',
    currencySymbol: '\$', phonePrefix: '+961', decimalPlaces: 2,
    addressFields: [_nameField, _phoneField, _streetField, _cityField, _stateField, _zipField, _notesField],
    paymentMethods: [_cod, _visa, _mastercard],
  ),
  // 🇸🇾 Syria
  CountryData(
    code: 'SY', nameAr: 'سوريا', nameEn: 'Syria', flag: '🇸🇾',
    currencyCode: 'SYP', currencyNameAr: 'ليرة سورية', currencyNameEn: 'Syrian Pound',
    currencySymbol: 'ل.س', phonePrefix: '+963', decimalPlaces: 0,
    addressFields: [_nameField, _phoneField, _streetField, _cityField, _stateField, _notesField],
    paymentMethods: [_cod],
  ),
  // 🇵🇸 Palestine
  CountryData(
    code: 'PS', nameAr: 'فلسطين', nameEn: 'Palestine', flag: '🇵🇸',
    currencyCode: 'ILS', currencyNameAr: 'شيكل', currencyNameEn: 'Israeli Shekel',
    currencySymbol: '₪', phonePrefix: '+970', decimalPlaces: 2,
    addressFields: [_nameField, _phoneField, _streetField, _cityField, _stateField, _notesField],
    paymentMethods: [_cod, _visa, _mastercard],
  ),
  // 🇲🇷 Mauritania
  CountryData(
    code: 'MR', nameAr: 'موريتانيا', nameEn: 'Mauritania', flag: '🇲🇷',
    currencyCode: 'MRU', currencyNameAr: 'أوقية موريتانية', currencyNameEn: 'Mauritanian Ouguiya',
    currencySymbol: 'أ.م', phonePrefix: '+222', decimalPlaces: 2,
    addressFields: [_nameField, _phoneField, _streetField, _cityField, _stateField, _notesField],
    paymentMethods: [_cod],
  ),
  // 🇩🇯 Djibouti
  CountryData(
    code: 'DJ', nameAr: 'جيبوتي', nameEn: 'Djibouti', flag: '🇩🇯',
    currencyCode: 'DJF', currencyNameAr: 'فرنك جيبوتي', currencyNameEn: 'Djiboutian Franc',
    currencySymbol: 'Fdj', phonePrefix: '+253', decimalPlaces: 0,
    addressFields: [_nameField, _phoneField, _streetField, _cityField, _notesField],
    paymentMethods: [_cod],
  ),
  // 🇸🇴 Somalia
  CountryData(
    code: 'SO', nameAr: 'الصومال', nameEn: 'Somalia', flag: '🇸🇴',
    currencyCode: 'SOS', currencyNameAr: 'شلن صومالي', currencyNameEn: 'Somali Shilling',
    currencySymbol: 'Sh', phonePrefix: '+252', decimalPlaces: 0,
    addressFields: [_nameField, _phoneField, _streetField, _cityField, _stateField, _notesField],
    paymentMethods: [_cod],
  ),
  // 🇰🇲 Comoros
  CountryData(
    code: 'KM', nameAr: 'جزر القمر', nameEn: 'Comoros', flag: '🇰🇲',
    currencyCode: 'KMF', currencyNameAr: 'فرنك قمري', currencyNameEn: 'Comorian Franc',
    currencySymbol: 'CF', phonePrefix: '+269', decimalPlaces: 0,
    addressFields: [_nameField, _phoneField, _streetField, _cityField, _notesField],
    paymentMethods: [_cod],
  ),
  // 🇫🇷 France (diaspora)
  CountryData(
    code: 'FR', nameAr: 'فرنسا', nameEn: 'France', flag: '🇫🇷',
    currencyCode: 'EUR', currencyNameAr: 'يورو', currencyNameEn: 'Euro',
    currencySymbol: '€', phonePrefix: '+33', decimalPlaces: 2,
    addressFields: [_nameField, _phoneField, _streetField, _cityField, _zipField, _notesField],
    paymentMethods: [_visa, _mastercard, _applePay],
  ),
];

// ─── Country Currency Service (Singleton) ───
class CountryCurrencyService extends ChangeNotifier {
  static final CountryCurrencyService _instance = CountryCurrencyService._internal();
  factory CountryCurrencyService() => _instance;
  CountryCurrencyService._internal();

  CountryData? _currentCountry;
  Map<String, double> _exchangeRates = {};
  bool _isLoading = false;
  DateTime? _ratesLastUpdated;

  // Base currency for stored prices (DZD since products are in DZD)
  static const String baseCurrency = 'DZD';

  CountryData get currentCountry => _currentCountry ?? supportedCountries.first; // default Algeria
  bool get isLoading => _isLoading;
  Map<String, double> get exchangeRates => _exchangeRates;

  // ─── Initialize: detect country or load saved preference ───
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString('selected_country');

    if (savedCode != null) {
      _currentCountry = supportedCountries.firstWhere(
        (c) => c.code == savedCode,
        orElse: () => supportedCountries.first,
      );
    } else {
      // Try auto-detection via IP
      await _detectCountryByIP();
    }

    // Load cached exchange rates
    final cachedRates = prefs.getString('exchange_rates');
    final cachedTime = prefs.getInt('exchange_rates_time');
    if (cachedRates != null && cachedTime != null) {
      _exchangeRates = Map<String, double>.from(json.decode(cachedRates));
      _ratesLastUpdated = DateTime.fromMillisecondsSinceEpoch(cachedTime);
    }

    // Refresh rates if older than 6 hours or empty
    if (_exchangeRates.isEmpty ||
        _ratesLastUpdated == null ||
        DateTime.now().difference(_ratesLastUpdated!).inHours > 6) {
      await fetchExchangeRates();
    }

    notifyListeners();
  }

  // ─── Auto-detect country from IP ───
  Future<void> _detectCountryByIP() async {
    try {
      final response = await http.get(
        Uri.parse('http://ip-api.com/json/?fields=countryCode'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final detectedCode = data['countryCode'] as String?;
        if (detectedCode != null) {
          _currentCountry = supportedCountries.firstWhere(
            (c) => c.code == detectedCode,
            orElse: () => supportedCountries.first, // fallback to Algeria
          );
        }
      }
    } catch (_) {
      // Silently fallback to Algeria
      _currentCountry = supportedCountries.first;
    }
  }

  // ─── Set country manually ───
  Future<void> setCountry(String countryCode) async {
    _currentCountry = supportedCountries.firstWhere(
      (c) => c.code == countryCode,
      orElse: () => supportedCountries.first,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_country', countryCode);
    notifyListeners();
  }

  // ─── Fetch exchange rates from API ───
  Future<void> fetchExchangeRates() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Using exchangerate-api.com free tier (1500 requests/month)
      final response = await http.get(
        Uri.parse('https://open.er-api.com/v6/latest/$baseCurrency'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] == 'success') {
          final rates = data['rates'] as Map<String, dynamic>;
          _exchangeRates = rates.map((k, v) => MapEntry(k, (v as num).toDouble()));
          _ratesLastUpdated = DateTime.now();

          // Cache rates
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('exchange_rates', json.encode(_exchangeRates));
          await prefs.setInt('exchange_rates_time', _ratesLastUpdated!.millisecondsSinceEpoch);
        }
      }
    } catch (_) {
      // Use fallback hardcoded rates if API fails
      _exchangeRates = _fallbackRates;
    }

    _isLoading = false;
    notifyListeners();
  }

  // ─── Convert price from DZD to current country's currency ───
  double convertPrice(double priceDZD) {
    final targetCurrency = currentCountry.currencyCode;
    if (targetCurrency == baseCurrency) return priceDZD;

    final rate = _exchangeRates[targetCurrency];
    if (rate == null) {
      // Use fallback
      final fallback = _fallbackRates[targetCurrency];
      if (fallback != null) return priceDZD * fallback;
      return priceDZD; // can't convert, show in DZD
    }
    return priceDZD * rate;
  }

  // ─── Format price with currency symbol ───
  String formatPrice(double priceDZD) {
    final converted = convertPrice(priceDZD);
    final country = currentCountry;
    final formatted = _formatNumber(converted, country.decimalPlaces);
    return '$formatted ${country.currencySymbol}';
  }

  // ─── Parse DZD price from string like "2,500 د.ج" ───
  static double parseDZDPrice(String priceStr) {
    final cleaned = priceStr
        .replaceAll('د.ج', '')
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .trim();
    return double.tryParse(cleaned) ?? 0;
  }

  // ─── Format number with thousand separators ───
  String _formatNumber(double value, int decimals) {
    if (decimals == 0) {
      final intVal = value.round();
      return _addThousandSeparator(intVal.toString());
    }
    final parts = value.toStringAsFixed(decimals).split('.');
    return '${_addThousandSeparator(parts[0])}.${parts[1]}';
  }

  String _addThousandSeparator(String number) {
    final result = StringBuffer();
    int count = 0;
    for (int i = number.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0 && number[i] != '-') {
        result.write(',');
      }
      result.write(number[i]);
      count++;
    }
    return result.toString().split('').reversed.join();
  }

  // ─── Get country by code ───
  CountryData? getCountry(String code) {
    try {
      return supportedCountries.firstWhere((c) => c.code == code);
    } catch (_) {
      return null;
    }
  }

  // ─── Fallback exchange rates (approximate, updated periodically) ───
  static const Map<String, double> _fallbackRates = {
    'DZD': 1.0,
    'SAR': 0.0278,  // 1 DZD ≈ 0.028 SAR
    'EGP': 0.3620,  // 1 DZD ≈ 0.36 EGP
    'MAD': 0.0740,  // 1 DZD ≈ 0.074 MAD
    'TND': 0.0231,  // 1 DZD ≈ 0.023 TND
    'AED': 0.0272,  // 1 DZD ≈ 0.027 AED
    'KWD': 0.0023,  // 1 DZD ≈ 0.0023 KWD
    'QAR': 0.0270,  // 1 DZD ≈ 0.027 QAR
    'BHD': 0.0028,  // 1 DZD ≈ 0.0028 BHD
    'OMR': 0.0029,  // 1 DZD ≈ 0.0029 OMR
    'JOD': 0.0053,  // 1 DZD ≈ 0.005 JOD
    'IQD': 9.7200,  // 1 DZD ≈ 9.72 IQD
    'LYD': 0.0358,  // 1 DZD ≈ 0.036 LYD
    'SDG': 4.4600,  // 1 DZD ≈ 4.46 SDG
    'YER': 1.8560,  // 1 DZD ≈ 1.86 YER
    'USD': 0.0074,  // 1 DZD ≈ 0.0074 USD
    'SYP': 96.500,  // 1 DZD ≈ 96.5 SYP
    'ILS': 0.0270,  // 1 DZD ≈ 0.027 ILS
    'MRU': 0.2940,  // 1 DZD ≈ 0.294 MRU
    'DJF': 1.3200,  // 1 DZD ≈ 1.32 DJF
    'SOS': 4.2300,  // 1 DZD ≈ 4.23 SOS
    'KMF': 3.2500,  // 1 DZD ≈ 3.25 KMF
    'EUR': 0.0068,  // 1 DZD ≈ 0.0068 EUR
  };
}
