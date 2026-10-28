import 'dart:convert';
import 'package:http/http.dart' as http;

class JazzCashApiService {
  static const String firebaseFunctionUrl =
      'https://us-central1-nikahblessingapp-org.cloudfunctions.net/initiateJazzCashPayment';

  static Future<Map<String, dynamic>> initiatePaymentOnServer({
    required String mobileNumber,
    required String cnic,
    required int amount,
    required String description,
    required String uid,
    required String pkgName,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'mobileNumber': mobileNumber,
        'cnic': cnic,
        'amount': amount,
        'description': description,
        'uid': uid,
        'pkgName': pkgName,
      };

      final response = await http.post(
        Uri.parse(firebaseFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('JazzCash Server Response: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('Error during JazzCash server call: $e');
      return {'error': e.toString()};
    }
  }
}
