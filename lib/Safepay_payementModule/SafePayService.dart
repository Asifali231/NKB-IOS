// lib/services/safepay_service.dart

import 'safepay_config.dart';

class SafePayService {
  final SafePayConfig config;

  SafePayService(this.config);

  String createCheckoutUrl({
    required double amount,
    required String orderId,
    required String currency,
    String? customerEmail,
    String? cancelUrl,
    String? redirectUrl,
  }) {
    final baseUrl = config.baseUrl;

    final params = {
      'env': config.isSandbox ? 'sandbox' : 'production',
      'public_key': config.publicKey,
      'order_id': orderId,
      'amount': amount.toString(),
      'currency': currency,
      if (customerEmail != null) 'customer_email': customerEmail,
      if (cancelUrl != null) 'cancel_url': cancelUrl,
      if (redirectUrl != null) 'redirect_url': redirectUrl,
    };

    final queryString = Uri(queryParameters: params).query;
    return '$baseUrl/checkout/v1/init?$queryString';
  }

  /// Verify payment response (implement as needed)
  Future<bool> verifyPayment(String token) async {
    // Implement payment verification using secret key
    // This would typically involve making an API call to SafePay
    return true;
  }
}