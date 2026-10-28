// lib/screens/payment_screen.dart

import 'package:flutter/material.dart';
import 'package:nikah_blessing/Safepay_payementModule/SafePayService.dart';
import 'package:nikah_blessing/Safepay_payementModule/safePayWebView.dart';
import 'package:nikah_blessing/Safepay_payementModule/safepay_config.dart';

class PaymentScreen extends StatelessWidget {
  PaymentScreen({Key? key}) : super(key: key);

  // Initialize SafePay configuration
  final safePayConfig = const SafePayConfig(
    publicKey: 'YOUR_PUBLIC_KEY',  // Replace with your public key
    secretKey: 'YOUR_SECRET_KEY',  // Replace with your secret key
    isSandbox: true,  // Set to false for production
  );

  void _handlePaymentComplete(BuildContext context, String status, Map<String, dynamic>? data) {
    // Handle different payment statuses
    switch (status) {
      case 'success':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment successful!')),
        );
        break;
      case 'error':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: ${data?['message'] ?? 'Unknown error'}')),
        );
        break;
      case 'cancelled':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment cancelled')),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final safePayService = SafePayService(safePayConfig);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Total Amount: PKR 1,000',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Create checkout URL with order details
                final checkoutUrl = safePayService.createCheckoutUrl(
                  amount: 1000.0,
                  orderId: 'ORDER_${DateTime.now().millisecondsSinceEpoch}',
                  currency: 'PKR',
                  customerEmail: 'customer@example.com',
                  redirectUrl: 'https://your-app.com/success',
                  cancelUrl: 'https://your-app.com/cancel',
                );

                // Launch SafePay checkout
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SafePayCheckout(
                      checkoutUrl: checkoutUrl,
                      onComplete: (status, data) => _handlePaymentComplete(context, status, data),
                    ),
                  ),
                );
              },
              child: const Text('Pay with SafePay'),
            ),
          ],
        ),
      ),
    );
  }
}