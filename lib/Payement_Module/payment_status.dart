// lib/models/payment_status.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentStatus {
  final String status;
  final String? description;
  final double? amount;
  final DateTime? createdAt;
  final DateTime? completedAt;

  PaymentStatus({
    required this.status,
    this.description,
    this.amount,
    this.createdAt,
    this.completedAt,
  });

  factory PaymentStatus.fromMap(Map<String, dynamic> map) {
    return PaymentStatus(
      status: map['status'] ?? 'UNKNOWN',
      description: map['description'],
      amount: map['amount']?.toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
    );
  }
}

