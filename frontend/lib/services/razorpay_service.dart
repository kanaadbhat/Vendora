import 'package:razorpay_web/razorpay_web.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';

class RazorpayService {
  late Razorpay _razorpay;

  RazorpayService() {
    debugPrint('[RAZORPAY] Initializing Razorpay instance');
    _razorpay = Razorpay();
  }

  void registerEventHandlers({
    required void Function(PaymentSuccessResponse) onSuccess,
    required void Function(PaymentFailureResponse) onError,
    required void Function(ExternalWalletResponse) onExternalWallet,
  }) {
    debugPrint('[RAZORPAY] Registering event handlers');
    _razorpay.on('payment.success', onSuccess);
    _razorpay.on('payment.error', onError);
    _razorpay.on('external_wallet', onExternalWallet);
  }

  Future<void> createOrderAndPay({
    required int amount,
    required String currency,
    required String receipt,
    required String name,
    required String description,
    required String prefillContact,
    required String prefillEmail,
    required String razorpayKey,
  }) async {
    debugPrint('[RAZORPAY] Creating order via backend');
    // 1. Call backend to create order
    final api = ApiService();
    final response = await api.post(
      '/pay/create-order',
      data: {"amount": amount, "currency": currency, "receipt": receipt},
    );

    final data = response.data['details'];
    final orderId = data['orderId'];

    // 2. Open Razorpay checkout
    var options = {
      'key': razorpayKey,
      'amount': data['amount'],
      'currency': data['currency'],
      'name': name,
      'description': description,
      'order_id': orderId,
      'prefill': {'contact': prefillContact, 'email': prefillEmail},
    };

    debugPrint(
      '[RAZORPAY] Opening checkout with options: ' + options.toString(),
    );
    _razorpay.open(options);
  }

  Future<bool> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    final api = ApiService();
    final response = await api.post(
      '/pay/verify-payment',
      data: {
        "razorpay_order_id": orderId,
        "razorpay_payment_id": paymentId,
        "razorpay_signature": signature,
      },
    );
    return response.data['success'] == true;
  }

  void clear() {
    _razorpay.clear();
  }
}
