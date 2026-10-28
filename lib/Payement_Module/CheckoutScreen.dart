import 'package:flutter/material.dart';
import '../JazzCash_PayementModules/jazz_cash_payment_screen.dart';
import '../JazzCash_PayementModules/jazz_cash_service.dart';

class CheckoutPage extends StatelessWidget {
  final double amount;
  final String description;
  final String orderId;

  const CheckoutPage({
    Key? key,
    required this.amount,
    required this.description,
    required this.orderId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order ID: $orderId',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Description: $description',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 10),
            Text(
              'Amount: PKR ${amount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _initiateJazzCashPayment(context),
              child: const Text('Pay Now'),
            ),
          ],
        ),
      ),
    );
  }

  void _initiateJazzCashPayment(BuildContext context) async {

    final service = JazzCashService();
    final params = service.prepareSubmissionData(5250.0 , "MPAY", "", "");


    print("params.toString()");
    print(params.toString().trim());




    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JazzCashPaymentScreen(paymentParams: params),
      ),
    );

    if (result != null) {
      if (result['success']) {
        // Handle successful payment
        print('Payment successful!');
        print('Transaction Reference: ${result['transactionRef']}');
        print('Amount: ${result['amount']}');

        // Add your success logic here
      } else {
        // Handle failed payment
        print('Payment failed: ${result['responseMessage']}');

        // Add your failure logic here
      }
    }
  }




}
