import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FreeChatMessageService {
  static const int freeMessageLimit = 1;
  static const String _messageCountField = 'freeChatMessagesSent';

  static Future<bool> hasUsedFreeMessage() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw StateError('Sign in before checking free messaging access.');
    }

    final user =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return _messageCount(user.data()?[_messageCountField]) >= freeMessageLimit;
  }

  static Future<bool> sendFirstMessage({
    required DocumentReference<Map<String, dynamic>> userReference,
    required DocumentReference<Map<String, dynamic>> chatReference,
    required DocumentReference<Map<String, dynamic>> messageReference,
    required Map<String, dynamic> messageData,
    required Map<String, dynamic> chatUpdate,
  }) {
    return FirebaseFirestore.instance.runTransaction<bool>((transaction) async {
      final userSnapshot = await transaction.get(userReference);
      if (!userSnapshot.exists) {
        throw StateError('Your user profile could not be found.');
      }

      final sentCount = _messageCount(userSnapshot.data()?[_messageCountField]);
      if (sentCount >= freeMessageLimit) return false;

      transaction.update(userReference, {
        _messageCountField: sentCount + 1,
      });
      transaction.set(messageReference, messageData);
      transaction.update(chatReference, chatUpdate);
      return true;
    });
  }

  static int _messageCount(Object? value) {
    final count = value is num ? value.toInt() : int.tryParse('$value') ?? 0;
    return count < 0 ? 0 : count;
  }
}
