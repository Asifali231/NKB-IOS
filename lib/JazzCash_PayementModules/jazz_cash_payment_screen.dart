// jazz_cash_payment_screen.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:developer' as developer;

import 'jazz_cash_service.dart';

class JazzCashPaymentScreen extends StatefulWidget {
  final Map<String, String> paymentParams;

  const JazzCashPaymentScreen({
    Key? key,
    required this.paymentParams
  }) : super(key: key);

  @override
  _JazzCashPaymentScreenState createState() => _JazzCashPaymentScreenState();
}

class _JazzCashPaymentScreenState extends State<JazzCashPaymentScreen> {
  bool _isLoading = true;
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            developer.log('Page started loading: $url');
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
            developer.log('Page finished loading: $url');
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith(JazzCashService.returnUrlProduction)) {
              _handlePaymentResponse(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            developer.log('WebView error: ${error.description}');
            // _showError('Payment Error', error.description);
          },
        ),
      )
      ..loadHtmlString(_generateHtmlForm());
  }

  String _generateHtmlForm() {


    String formFields = '';


    widget.paymentParams.forEach((key, value) {
      formFields += '<input type="hidden" name="$key" value="$value">\n';
    });

    // Splitting the formFields into two halves
    int mid = (formFields.length / 2).ceil();

    String firstHalf = formFields.substring(0, mid);
    String secondHalf = formFields.substring(mid);

    print("First Half:");
    print(firstHalf);

    print("Second Half:");
    print(secondHalf);

    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>JazzCash Payment</title>
        <style>
          body { 
            display: flex; 
            justify-content: center; 
            align-items: center; 
            height: 100vh; 
            margin: 0; 
            background-color: #f0f0f0;
            font-family: Arial, sans-serif;
          }
          .loader {
            border: 4px solid #f3f3f3;
            border-radius: 50%;
            border-top: 4px solid #E40520;
            width: 50px;
            height: 50px;
            animation: spin 1s linear infinite;
          }
          @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
          }
          .payment-form {
            display: none;
          }
          .loading-text {
            margin-top: 20px;
            color: #666;
          }
        </style>
      </head>
      <body>
        <div id="loader-container">
          <div class="loader"></div>
          <div class="loading-text">Connecting to JazzCash...</div>
        </div>
        <form id="paymentForm" class="payment-form" method="post" action="https://onlinepayments.jazzcash.com.pk/payment-orchestrator/CustomerPortal/transactionmanagement/merchantform">
             $formFields
        </form>
        <script>
          document.addEventListener('DOMContentLoaded', function() {
            setTimeout(function() {
              document.getElementById('paymentForm').submit();
            }, 1500);
          });
        </script>
      </body>
      </html>
    ''';
  }

  void _handlePaymentResponse(String url) {
    try {
      final uri = Uri.parse(url);
      final queryParams = uri.queryParameters;

      developer.log('Payment response received: $queryParams');

      final responseCode = queryParams['pp_ResponseCode'];
      final responseMessage = queryParams['pp_ResponseMessage'] ?? 'Unknown response';

      Map<String, dynamic> result = {
        'success': responseCode == '000',
        'responseCode': responseCode,
        'responseMessage': responseMessage,
        'transactionRef': queryParams['pp_ReturnRefNo'],
        'amount': queryParams['pp_Amount'],
        'billReference': queryParams['pp_BillReference'],
        'rawResponse': queryParams
      };

      if (responseCode == '000') {
        _showSuccess(responseMessage);
      } else {
        _showError('Payment Failed', responseMessage);
      }

      Future.delayed(const Duration(seconds: 2), () {
        Navigator.of(context).pop(result);
      });

    } catch (e) {
      developer.log('Error handling payment response', error: e);
      _showError('Error', 'Failed to process payment response');
      Navigator.of(context).pop({
        'success': false,
        'error': e.toString()
      });
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title: $message'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool shouldPop = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cancel Payment?'),
            content: const Text('Are you sure you want to cancel this payment?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('NO'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                  Navigator.of(context).pop({'success': false, 'error': 'Payment cancelled'});
                },
                child: const Text('YES'),
              ),
            ],
          ),
        ) ?? false;
        return shouldPop;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text('Process Payment'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.of(context).pop({
                'success': false,
                'error': 'Payment cancelled by user'
              });
            },
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              Container(
                color: Colors.white,
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE40520)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}