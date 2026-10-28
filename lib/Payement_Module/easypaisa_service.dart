// lib/services/easypaisa_service.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_functions/cloud_functions.dart';

class EasypaisaService {
  static const String baseUrl = 'https://easypay.easypaisa.com.pk/easypay';
  static const String storeId = '677118'; // Replace with your store ID
  static const String merchantKey = '5YV3OK6AL6RSZG3W'; // Replace with your merchant key

  // Calculate order hash using merchant key
  String _calculateHash(Map<String, String> params) {
    // Sort parameters alphabetically
    final sortedParams = Map.fromEntries(
        params.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
    );

    // Create string to hash
    final valueToHash = sortedParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');

    print('Value to hash: $valueToHash');

    // Generate hash using merchant key
    final key = utf8.encode(merchantKey);
    final bytes = utf8.encode(valueToHash);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);

    return base64.encode(digest.bytes);
  }

  // Initialize payment transaction
  Future<Map<String, dynamic>> initiatePayment({
    required double amount,
    required String orderRefNum,
    required String postBackURL,
    String? paymentMethod,
    String? emailAddr,
    String? mobileNum,
  }) async {
    try {
      print('Initiating payment for order: $orderRefNum');

      // Prepare request parameters
      final params = {
        'storeId': storeId,
        'amount': "1500.0",
        'orderRefNum': "1733041380931",
        'postBackURL': "http://us-central1-nikahblessingapp-org.cloudfunctions.net/easypaisaCallback",
        'autoRedirect': '1',
      };

      // Add optional parameters if provided
      // if (paymentMethod != null) params['paymentMethod'] = paymentMethod;
      // if (emailAddr != null) params['emailAddr'] = emailAddr;
      // if (mobileNum != null) params['mobileNum'] = mobileNum;

      // Calculate hash
      //  params['merchantHashedReq'] = "wxRQLCijoGPQy11hJ3zVyimArfpOV4aclAPKrpaQr41nhrAhwBW6A7RFmf3AV5Ac/LzIBvPslCvEygdqe02MnB5ujXSrS/Ou+Qbq9oomHHOJ77gTir1o03OvDXbL40Xah6Zn84QTlTnrninNbHcA8e+jBaUi6WEHIyX3Mc7BiZSb0Nz+7s3+UU0YwnBwjU2EZySm1Fq7bYcpqyi84FWXgA==";

      print('Sending payment request with params: $params');
      print('Sending payment request to: $baseUrl/Index.jsf');


      // Make API request
      final response = await http.post(
        Uri.parse('$baseUrl/Index.jsf'),
        body: params,
      );



      print('Payment initiation response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      print('Response header: ${response.headers}');
      print('Response isRedirected: ${response.isRedirect}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Payment initiation failed with status ${response.statusCode}');
      }
    } catch (e) {
      print('Error initiating payment: $e');
      rethrow;
    }
  }

  // Confirm payment with auth token
  Future<Map<String, dynamic>> confirmPayment({
    required String authToken,
    required String postBackURL,
  }) async {
    try {
      print('Confirming payment with token: $authToken');

      final response = await http.post(
        Uri.parse('$baseUrl/Confirm.jsf'),
        body: {
          'auth_token': authToken,
          'postBackURL': postBackURL,
        },
      );

      print('Payment confirmation response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Payment confirmation failed with status ${response.statusCode}');
      }
    } catch (e) {
      print('Error confirming payment: $e');
      rethrow;
    }
  }
}
