import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentVisibilityService {
  static final DocumentReference<Map<String, dynamic>> _settingsDoc =
      FirebaseFirestore.instance
          .collection('setting')
          .doc('EnablePayments');

  static bool _isHiddenFromData(Map<String, dynamic>? data) {
    if (data == null) {
      return false;
    }

    final isHidden = data['isHidden'] == true;
    final isEnabled = data['isEnabled'];
    final isDisabled = isEnabled is bool && isEnabled == false;

    return isHidden || isDisabled;
  }

  static Stream<bool> paymentsHiddenStream() {
    return _settingsDoc.snapshots().map((snapshot) {
      return _isHiddenFromData(snapshot.data());
    });
  }

  static Future<bool> arePaymentsHidden() async {
    try {
      final snapshot = await _settingsDoc.get();
      return _isHiddenFromData(snapshot.data());
    } catch (_) {
      return false;
    }
  }

  static Stream<bool> premiumFeaturesUnlockedStream() {
    return paymentsHiddenStream();
  }

  static Future<bool> arePremiumFeaturesUnlocked() async {
    return arePaymentsHidden();
  }
}
