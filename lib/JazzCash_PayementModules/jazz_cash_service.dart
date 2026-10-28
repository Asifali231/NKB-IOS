import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';



class JazzCashService {
  // Configuration Constants

  //
  // static const String _merchantId = "MC142126";
  // static const String _password = "hb7x50d0c2";
  // static const String _integritySalt = "xx3dg1d4s2";
  // //

  static const String _merchantId = "56988979"; // Replace with your merchant ID
  static const String _password = "39z338x731"; // Replace with your password
  static const String _integritySalt = "82y8yx6485"; // Replace with your integrity salt


  // static const String returnUrlSandbox = "https://us-central1-nikahblessingapp-org.cloudfunctions.net/jazzCashReturnUrl";
  // static const String baseUrlSandbox = "https://sandbox.jazzcash.com.pk/CustomerPortal/transactionmanagement/merchantform/";

  static const String returnUrlProduction = "https://us-central1-nikahblessingapp-org.cloudfunctions.net/jazzCashReturnUrl";
  static const String baseUrlProduction = "https://onlinepayments.jazzcash.com.pk/payment-orchestrator/CustomerPortal/transactionmanagement/merchantform";


  // Generate Payment Parameters
  Map<String, String> generatePaymentParameters({
    required double amount,
    required String txnType,
    required String uid,
    required String pkgName,
    // String environment = 'sandbox',
    String description = 'Product Purchase',
    String billReference = '98765432145678',
    String language = 'EN',
    String? subMerchantId,
    String? bankId,
    String? productId,
    List<String?>? customFields, // Custom fields ppmpf_1 to ppmpf_5
  }) {
    // Validate inputs
    if (amount <= 0) {
      throw ArgumentError("Amount must be greater than 0");
    }

    final DateTime now = DateTime.now().toUtc().add( Duration(hours: 5)); // Adjust to PST (GMT+5)

    // Prepare parameters
     var params = <String, String>{
       'pp_Amount': _formatAmount(amount),
       'pp_BillReference': billReference,
       'pp_Description': description,
       'pp_Language': language,
       'pp_MerchantID': _merchantId,
       'pp_Password': _password,
       'pp_ReturnURL': returnUrlProduction,
       'pp_TxnCurrency': 'PKR',
       'pp_TxnDateTime': _formatDateTime(now),
       'pp_TxnExpiryDateTime': _formatDateTime(now.add(const Duration(days: 3))),
       'pp_TxnRefNo': _generateTransactionReference(now),
       'pp_TxnType': txnType,
       'pp_Version': '1.1',

       'pp_ProductID':'',
       'pp_SubMerchantID':'',
        'pp_BankID':'',
       'ppmpf_1': uid,
       'ppmpf_2': pkgName,
       'ppmpf_3':'',
       'ppmpf_4':'',
       'ppmpf_5':'',


    };

    // Generate Secure Hash
    params['pp_SecureHash'] =  generateSecureHash(params , _integritySalt);

    print("params" + params.toString());

    return params;
  }

  // Generate Unique Transaction Reference
  String _generateTransactionReference(DateTime timestamp) {
    final uuid = Uuid();
    return 'T${DateFormat('yyyyMMddHHmmss').format(timestamp)}${uuid.v4().substring(0, 5)}';
  }

  // Format Amount (Multiply by 100 for decimal representation)
  String _formatAmount(double amount) {
    return (amount * 100).toInt().toString();
  }

  // Format DateTime in YYYYMMDDHHMMSS
  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyyMMddHHmmss').format(dateTime);
  }


  String generateSecureHash(Map<String, String> params, String integritySalt) {
    // Define the ordered fields
    final orderedFields = [
      'pp_Amount',
      'pp_BankID',
      'pp_BillReference',
      'pp_Description',

      'pp_Language',
      'pp_MerchantID',
      'pp_Password',

      'pp_ProductID',
      'pp_ReturnURL',
      'pp_TxnCurrency',
      'pp_TxnDateTime',

      'pp_TxnExpiryDateTime',
      'pp_TxnRefNo',
      'pp_TxnType',

      'pp_Version',

      'ppmpf_1',
      'ppmpf_2',
    ];

    // Step 1: Build the formatted string
    final formattedString = orderedFields
        .where((field) => params[field]?.isNotEmpty ?? false) // Check if field exists and is not empty
        .map((field) => params[field]) // Map to field values
        .join('&'); // Join with '&'

    // Step 2: Prepend the integrity salt
    final stringToHash = '$integritySalt&$formattedString';

    // Step 3: Generate HMAC SHA-256 hash
    final hmacSha256 = Hmac(sha256, utf8.encode(integritySalt)); // Use salt as the key
    final digest = hmacSha256.convert(utf8.encode(stringToHash));

    print("Generated Secure Hash ");


    // Step 4: Convert hash to uppercase hexadecimal string
    return digest.bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
  }

  // Method to prepare form data for submission
  Map<String, String> prepareSubmissionData(double amount, String txtType, String uid , String pkgName) {



    return generatePaymentParameters(amount: amount, txnType: txtType , uid: uid , pkgName: pkgName);

  }


}