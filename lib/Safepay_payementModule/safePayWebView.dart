// lib/widgets/safepay_checkout.dart

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SafePayCheckout extends StatefulWidget {
  final String checkoutUrl;
  final Function(String status, Map<String, dynamic>? data) onComplete;

  const SafePayCheckout({
    Key? key,
    required this.checkoutUrl,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<SafePayCheckout> createState() => _SafePayCheckoutState();
}

class _SafePayCheckoutState extends State<SafePayCheckout> {
  late final WebViewController _controller;

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
          onUrlChange: _handleUrlChange,
          onPageFinished: (String url) {
            // Handle page finished loading if needed
          },
          onWebResourceError: (WebResourceError error) {
            widget.onComplete('error', {'message': error.description});
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  void _handleUrlChange(UrlChange change) {
    final String currentUrl = change.url ?? '';

    // Handle Hosted Checkout Success
    if (currentUrl.contains('/external/mobile')) {
      final uri = Uri.parse(currentUrl);
      final action = uri.queryParameters['action'];

      if (action == 'complete') {
        widget.onComplete('success', {
          'tracker': uri.queryParameters['tracker'],
          'beacon': uri.queryParameters['beacon'],
        });
        Navigator.pop(context);
      } else if (action == 'cancelled') {
        widget.onComplete('cancelled', null);
        Navigator.pop(context);
      }
    }

    // Handle Hosted Checkout Error
    if (currentUrl.contains('/external/error')) {
      final uri = Uri.parse(currentUrl);
      widget.onComplete('error', {
        'error': uri.queryParameters['error'],
      });
      Navigator.pop(context);
    }

    // Handle Embedded Checkout Success
    if (currentUrl.contains('/external/complete')) {
      final uri = Uri.parse(currentUrl);
      widget.onComplete('success', {
        'tracker': uri.queryParameters['tracker'],
        'message': uri.queryParameters['finalizer_message'],
      });
      Navigator.pop(context);
    }

    // Handle Embedded Checkout Error
    if (currentUrl.contains('/embedded/external/error')) {
      final uri = Uri.parse(currentUrl);
      widget.onComplete('error', {
        'message': uri.queryParameters['finalizer_message'],
        'tracker': uri.queryParameters['tracker'],
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SafePay Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            widget.onComplete('cancelled', null);
            Navigator.pop(context);
          },
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}