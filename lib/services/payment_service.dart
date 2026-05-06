import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Payment Gateway Service
/// Supports multiple payment providers based on country:
/// - Stripe: International cards (Visa, Mastercard)
/// - Tap Payments: Middle East & North Africa (mada, STC Pay, Apple Pay)
/// - COD: Cash on delivery (all countries)
/// - Local methods: CCP, Baridimob (Algeria), Vodafone Cash (Egypt), etc.
///
/// Setup:
/// 1. Add your Stripe/Tap API keys below
/// 2. For production, move keys to environment variables or Firebase Remote Config
/// 3. Add stripe_sdk or tap_payment packages to pubspec.yaml
class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  // ─── API Keys (move to env variables in production!) ───
  // Stripe Test Keys
  static const String _stripePublishableKey = 'pk_test_YOUR_STRIPE_KEY';
  static const String _stripeSecretKey = 'sk_test_YOUR_STRIPE_SECRET';

  // Tap Payments Test Keys (for MENA region)
  static const String _tapSecretKey = 'sk_test_YOUR_TAP_KEY';

  // ─── Payment Method Types ───
  static const String methodCOD = 'cod';
  static const String methodCard = 'card';
  static const String methodMada = 'mada';
  static const String methodSTCPay = 'stc_pay';
  static const String methodApplePay = 'apple_pay';
  static const String methodGoldCard = 'gold_card'; // Algeria
  static const String methodCCP = 'ccp';
  static const String methodBaridiMob = 'baridimob';
  static const String methodVodafoneCash = 'vodafone_cash';
  static const String methodFawry = 'fawry';
  static const String methodInstaPay = 'instapay';

  // ─── Process Payment ───
  Future<PaymentResult> processPayment({
    required String paymentMethod,
    required double amount,
    required String currency,
    required String customerName,
    required String customerEmail,
    required String orderId,
    String? cardToken,
  }) async {
    switch (paymentMethod) {
      case methodCOD:
        return _processCOD(orderId);

      case methodCard:
        return _processStripePayment(
          amount: amount,
          currency: currency,
          customerEmail: customerEmail,
          orderId: orderId,
          cardToken: cardToken,
        );

      case methodMada:
      case methodSTCPay:
      case methodApplePay:
        return _processTapPayment(
          amount: amount,
          currency: currency,
          customerName: customerName,
          customerEmail: customerEmail,
          orderId: orderId,
          paymentMethod: paymentMethod,
        );

      case methodGoldCard:
      case methodCCP:
      case methodBaridiMob:
        return _processAlgerianPayment(paymentMethod, orderId);

      case methodVodafoneCash:
      case methodFawry:
      case methodInstaPay:
        return _processEgyptianPayment(paymentMethod, orderId);

      default:
        return PaymentResult(
          success: false,
          message: 'طريقة الدفع غير مدعومة',
        );
    }
  }

  // ─── Cash on Delivery ───
  PaymentResult _processCOD(String orderId) {
    return PaymentResult(
      success: true,
      message: 'تم تأكيد الطلب - الدفع عند الاستلام',
      transactionId: 'COD_$orderId',
      paymentMethod: 'الدفع عند الاستلام',
    );
  }

  // ─── Stripe Payment ───
  Future<PaymentResult> _processStripePayment({
    required double amount,
    required String currency,
    required String customerEmail,
    required String orderId,
    String? cardToken,
  }) async {
    try {
      // In production, this should call your backend server
      // which then calls Stripe's API with the secret key.
      // Never expose secret keys in the client app.

      // Placeholder for Stripe integration:
      // 1. Create PaymentIntent on your backend
      // 2. Confirm payment with card details on client
      // 3. Handle 3D Secure if required

      // For now, simulate success for testing
      await Future.delayed(const Duration(seconds: 2));

      return PaymentResult(
        success: true,
        message: 'تم الدفع بنجاح عبر البطاقة',
        transactionId: 'stripe_${DateTime.now().millisecondsSinceEpoch}',
        paymentMethod: 'بطاقة ائتمان',
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        message: 'فشل الدفع: $e',
      );
    }
  }

  // ─── Tap Payments (MENA) ───
  Future<PaymentResult> _processTapPayment({
    required double amount,
    required String currency,
    required String customerName,
    required String customerEmail,
    required String orderId,
    required String paymentMethod,
  }) async {
    try {
      // Tap Payments API integration
      // In production, create a charge via your backend:
      //
      // POST https://api.tap.company/v2/charges
      // {
      //   "amount": amount,
      //   "currency": currency,
      //   "source": { "id": "src_card" },
      //   "customer": { "first_name": customerName, "email": customerEmail },
      //   "redirect": { "url": "your_app://payment_callback" }
      // }

      await Future.delayed(const Duration(seconds: 2));

      final methodNames = {
        methodMada: 'مدى',
        methodSTCPay: 'STC Pay',
        methodApplePay: 'Apple Pay',
      };

      return PaymentResult(
        success: true,
        message: 'تم الدفع بنجاح عبر ${methodNames[paymentMethod] ?? paymentMethod}',
        transactionId: 'tap_${DateTime.now().millisecondsSinceEpoch}',
        paymentMethod: methodNames[paymentMethod] ?? paymentMethod,
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        message: 'فشل الدفع: $e',
      );
    }
  }

  // ─── Algerian Payment Methods ───
  PaymentResult _processAlgerianPayment(String method, String orderId) {
    final methodNames = {
      methodGoldCard: 'بطاقة الذهبية',
      methodCCP: 'CCP',
      methodBaridiMob: 'بريدي موب',
    };

    // These are typically manual transfer methods
    // User transfers money and provides receipt
    return PaymentResult(
      success: true,
      message: 'يرجى التحويل عبر ${methodNames[method]} - سيتم تأكيد الطلب بعد التحقق',
      transactionId: '${method}_$orderId',
      paymentMethod: methodNames[method] ?? method,
      requiresManualConfirmation: true,
    );
  }

  // ─── Egyptian Payment Methods ───
  PaymentResult _processEgyptianPayment(String method, String orderId) {
    final methodNames = {
      methodVodafoneCash: 'فودافون كاش',
      methodFawry: 'فوري',
      methodInstaPay: 'إنستاباي',
    };

    return PaymentResult(
      success: true,
      message: 'يرجى الدفع عبر ${methodNames[method]} - سيتم تأكيد الطلب بعد التحقق',
      transactionId: '${method}_$orderId',
      paymentMethod: methodNames[method] ?? method,
      requiresManualConfirmation: true,
    );
  }
}

// ─── Payment Result Model ───
class PaymentResult {
  final bool success;
  final String message;
  final String? transactionId;
  final String? paymentMethod;
  final bool requiresManualConfirmation;

  PaymentResult({
    required this.success,
    required this.message,
    this.transactionId,
    this.paymentMethod,
    this.requiresManualConfirmation = false,
  });
}
