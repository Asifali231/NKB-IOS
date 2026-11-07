import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class GenerateOtpAndSendMail {
  static const String _sendOtpFunctionName = 'requestEmailOtp';
  static const String _functionsRegion = 'us-central1';
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: _functionsRegion);
  bool hasAcceptedTerms = false;

  String _maskEmail(String email) {
    final separator = email.indexOf('@');
    if (separator <= 0) return '<invalid email>';
    final localPart = email.substring(0, separator);
    final visiblePrefix = localPart.length == 1 ? localPart : localPart[0];
    return '$visiblePrefix***${email.substring(separator)}';
  }

  Future<String> sendMail(String recipientEmail) async {
    final email = recipientEmail.trim();
    final request = {'email': email};
    final maskedRequest = {'email': _maskEmail(email)};
    debugPrint(
      'Calling Firebase callable "$_sendOtpFunctionName" '
      'in $_functionsRegion with request=$maskedRequest',
    );
    try {
      final result = await _functions
          .httpsCallable(_sendOtpFunctionName)
          .call<Map<String, dynamic>>(request);
      debugPrint(
        'Firebase callable "$_sendOtpFunctionName" response=${result.data}',
      );
      return result.data['sent'] == true
          ? 'true'
          : 'Unable to send the verification code. Please try again.';
    } on FirebaseFunctionsException catch (error) {
      debugPrint(
        'Firebase callable "$_sendOtpFunctionName" failed for '
        'request=$maskedRequest; response={code: ${error.code}, '
        'message: ${error.message ?? 'no message'}}',
      );
      return '${error.code}: ${error.message ?? 'Unable to send the verification code. Please try again.'}';
    } catch (error, stackTrace) {
      debugPrint(
        'Firebase callable "$_sendOtpFunctionName" failed for '
        'request=$maskedRequest: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<String?> verifyOtp(String email, String candidate) async {
    try {
      final result = await _functions
          .httpsCallable('verifyEmailOtp')
          .call<Map<String, dynamic>>({
        'email': email.trim(),
        'code': candidate.trim(),
      });
      final verificationToken = result.data['verificationToken'];
      return result.data['verified'] == true &&
              verificationToken is String &&
              verificationToken.isNotEmpty
          ? verificationToken
          : null;
    } on FirebaseFunctionsException catch (error) {
      if (error.code == 'invalid-argument' || error.code == 'not-found') {
        return null;
      }
      rethrow;
    }
  }

  Future<String> completeEmailSignIn(
    String email,
    String verificationToken,
  ) async {
    final result = await _functions
        .httpsCallable('completeEmailOtpSignIn')
        .call<Map<String, dynamic>>({
      'email': email.trim(),
      'verificationToken': verificationToken,
    });
    final customToken = result.data['customToken'];
    if (customToken is! String || customToken.isEmpty) {
      throw StateError('The sign-in service returned an invalid response.');
    }
    return customToken;
  }
}
