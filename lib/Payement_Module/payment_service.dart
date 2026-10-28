import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:nikah_blessing/Payement_Module/payment_exception.dart';
import 'package:nikah_blessing/Payement_Module/payment_status.dart';

class PaymentService {
  static const String storeId = '677118';
  static const String secretKey = '5YV3OK6AL6RSZG3W';

  // Production URLs
  static const String baseUrl = 'https://easypay.easypaisa.com.pk/easypay';
  static const String postBackURL = 'https://us-central1-nikahblessingapp-org.cloudfunctions.net/handlePaymentStatus';
  static const String finalPostBackURL = 'https://us-central1-nikahblessingapp-org.cloudfunctions.net/handleFinalPaymentStatus';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<Map<String, dynamic>> initiatePayment({
    required double amount,
    required String orderRefNum,
    String? paymentMethod,
    String? emailAddr,
    String? mobileNum,
  }) async {
    try {

      print('Initiating Payment ....');
      print('Initiating Payment ....');
      print('Initiating Payment ....');
      print('Initiating Payment ....');
      print('Initiating Payment ....');

      // Get FCM token for notifications
      final fcmToken = await _messaging.getToken();

      // Store initial payment info
      await _firestore.collection('payments').doc(orderRefNum).set({
        'amount': amount,
        'status': 'INITIATED',
        'fcmToken': fcmToken,
        'createdAt': FieldValue.serverTimestamp(),
      });


      print('Data saved ....');
      print('Data saved ....');
      print('Data saved ....');

      final response = await http.post(
        Uri.parse('https://easypay.easypaisa.com.pk/easypay/Index.jsf'),
        body: {
          'storeId': storeId,
          'amount': 15.0,
          'postBackURL': postBackURL,
          'orderRefNum': orderRefNum,
          'merchantHashedReq': generateHash({
            'amount': 15.0.toString(),
            // 'autoRedirect': '1',
            'orderRefNum': orderRefNum,
            'postBackURL': postBackURL,
            'storeId': storeId,
          }),
           'autoRedirect': '1',
          if (paymentMethod != null) 'paymentMethod': paymentMethod,
          if (emailAddr != null) 'emailAddr': emailAddr,
          if (mobileNum != null) 'mobileNum': mobileNum,

        },
      );

      print("This is the response : ${response.statusCode}");

      if (response.statusCode == 200) {

        print("This is the response : ${response.body}");

        return jsonDecode(response.body);


      } else {

        print("This is the response body: ${response.body}");
        print("This is the response headers: ${response.headers}");
        print("This is the response redirect: ${response.isRedirect}");
        print("This is the response stcde: ${response.statusCode}");


        throw PaymentException('Failed to initiate payment: ${response.statusCode}');
      }



    } catch (e) {
      throw PaymentException('Payment initialization error: $e');
    }
  }

  Future<Map<String, dynamic>> confirmPayment({
    required String authToken,
    required String orderRefNum,
  }) async {
    try {
      await _firestore.collection('payments').doc(orderRefNum).update({
        'authToken': authToken,
        'status': 'CONFIRMING',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final response = await http.post(
        Uri.parse('$baseUrl/Confirm.jsf'),
        body: {
          'auth_token': authToken,
          'postBackURL': finalPostBackURL,
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw PaymentException('Failed to confirm payment: ${response.statusCode}');
      }
    } catch (e) {
      throw PaymentException('Payment confirmation error: $e');
    }
  }

  Stream<PaymentStatus> listenToPaymentStatus(String orderRefNum) {
    return _firestore
        .collection('payments')
        .doc(orderRefNum)
        .snapshots()
        .map((snapshot) => PaymentStatus.fromMap(snapshot.data()!));
  }

  String generateHash(Map<String, String> params) {

    print('Generating Hash .......');
    print('Generating Hash .......');
    print('Generating Hash .......');

    print('with params .... ${params.toString()}');

    final sortedParams = Map.fromEntries(
        params.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
    );

    final valueToHash = sortedParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');

    print('Value to hash ....... ${valueToHash.toString()}');

    final key = utf8.encode(secretKey);
    final bytes = utf8.encode(valueToHash);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);

    print('Generated Hash ....... ${base64.encode(digest.bytes).toString()}');

    return base64.encode(digest.bytes);
  }
}
