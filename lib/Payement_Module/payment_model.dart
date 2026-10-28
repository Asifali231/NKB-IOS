// payment_model.dart
class PaymentModel {
  final String orderId;
  final double amount;
  final String status;
  final String? transactionId;
  final DateTime timestamp;

  PaymentModel({
    required this.orderId,
    required this.amount,
    required this.status,
    this.transactionId,
    required this.timestamp,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      orderId: json['orderRefNum'],
      amount: double.parse(json['amount'].toString()),
      status: json['status'],
      transactionId: json['transactionId'],
      timestamp: DateTime.parse(json['transactionDateTime']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderRefNum': orderId,
      'amount': amount,
      'status': status,
      'transactionId': transactionId,
      'transactionDateTime': timestamp.toIso8601String(),
    };
  }
}