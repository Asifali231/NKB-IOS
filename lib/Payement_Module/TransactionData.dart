import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionData {




  Future<void> addTransaction({
    required String transactionID,
    required double amount,
    required String transactionType,

    required String status,
    required String packageSubscribed,
    required String userId,
    required String phoneNumber,
    required String accountNumber,
  }) async {

    try {

      CollectionReference transactions = FirebaseFirestore.instance.collection('transactions');

      DateTime currentDateTime = DateTime.now();

      await transactions.doc(transactionID).set({
        'transactionID': transactionID,
        'amount': amount,
        'transactionType': transactionType,
        'transactionDate': currentDateTime.toIso8601String(),
        'status': status,
        'packageSubscribed': packageSubscribed,
        'userId': userId,
        'phoneNumber': phoneNumber,
        'accountNumber': accountNumber,
      });


      print('Transaction added successfully.');
    }

    catch (e) {

      print('Failed to add transaction: $e');
      rethrow;

    }
  }
}
