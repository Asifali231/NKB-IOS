// lib/models/payment_exception.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentException implements Exception {
  final String message;
  final String? code;

  PaymentException(this.message, {this.code});

  @override
  String toString() => 'PaymentException: $message${code != null ? ' (Code: $code)' : ''}';
}

// Add to PaymentService
void _handleError(dynamic error) {
  if (error is PaymentException) {
    throw error;
  } else if (error is FirebaseException) {
    throw PaymentException('Firebase error: ${error.message}', code: error.code);
  } else if (error is SocketException) {
    throw PaymentException('Network error: Please check your internet connection');
  } else {
    throw PaymentException('An unexpected error occurred: $error');
  }
}