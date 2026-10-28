// lib/screens/payment_screen.dart

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'easypaisa_service.dart';

class PaymentScreen extends StatefulWidget {
  final double amount;
  final String orderRefNum;

  const PaymentScreen({
    Key? key,
    required this.amount,
    required this.orderRefNum,
  }) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final EasypaisaService _paymentService = EasypaisaService();
  bool _isLoading = false;
  String? _error;
  final FirebaseFunctions functions = FirebaseFunctions.instance;



  Future<String> _getCallbackUrl() async {
    try {
      print('Requesting callback URL from Firebase...');

      final result = await functions
          .httpsCallable('getEasypaisaCallback')
          .call({
        'orderId': widget.orderRefNum,
        'amount': widget.amount,
      });

      print('Received response from Firebase: ${result.data}');

      if (result.data == null || result.data['url'] == null) {
        throw Exception('Invalid response from Firebase function');
      }

      return result.data['url'];
    } catch (e) {
      print('Error getting callback URL: $e');
      if (e is FirebaseFunctionsException) {
        print('Firebase Functions Error Code: ${e.code}');
        print('Firebase Functions Error Details: ${e.details}');
        print('Firebase Functions Error Message: ${e.message}');
      }
      throw e;
    }
  }

  // Start payment process
  Future<void> _startPayment({String? paymentMethod}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get callback URL from Firebase
      final callbackUrl = await _getCallbackUrl();
      print('Got callback URL: $callbackUrl');

      // Initiate payment
      final response = await _paymentService.initiatePayment(
        amount: widget.amount,
        orderRefNum: widget.orderRefNum,
        postBackURL: callbackUrl,
        paymentMethod: paymentMethod,
      );

      // Handle the auth token
      final authToken = response['auth_token'];
      if (authToken != null) {
        await _confirmPayment(authToken);
      } else {
        throw Exception('No auth token received');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      _showErrorDialog();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Confirm payment with auth token
  Future<void> _confirmPayment(String authToken) async {
    try {
      final callbackUrl = await _getCallbackUrl();
      final response = await _paymentService.confirmPayment(
        authToken: authToken,
        postBackURL: callbackUrl,
      );

      if (response['status'] == 'Success') {
        _showSuccessDialog();
      } else {
        throw Exception(response['desc'] ?? 'Payment failed');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      _showErrorDialog();
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Error'),
        content: Text(_error ?? 'An unknown error occurred'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Successful'),
        content: const Text('Your payment has been processed successfully.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Return success to previous screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Easypaisa Payment'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amount: PKR ${widget.amount.toStringAsFixed(2)}',

                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Order #${widget.orderRefNum}',

                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _startPayment(
                    paymentMethod: 'MA_PAYMENT_METHOD',
                  ),
                  child: const Text('Pay with Easypaisa Mobile Account'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _startPayment(
                    paymentMethod: 'CC_PAYMENT_METHOD',
                  ),
                  child: const Text('Pay with Credit/Debit Card'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _startPayment(
                    paymentMethod: 'OTC_PAYMENT_METHOD',
                  ),
                  child: const Text('Pay at Easypaisa Shop'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
