import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nikah_blessing/Payement_Module/in_app_purchase_service.dart';

class PaymentVisibilityService {
  static final DocumentReference<Map<String, dynamic>> _settingsDoc =
      FirebaseFirestore.instance.collection('setting').doc('EnablePayments');

  static bool _isHiddenFromData(Map<String, dynamic>? data) {
    if (data == null) return false;

    final isHidden = data['isHidden'] == true;
    final isEnabled = data['isEnabled'];
    return isHidden || (isEnabled is bool && !isEnabled);
  }

  static Stream<bool> paymentsHiddenStream() {
    return _settingsDoc.snapshots().map(
          (snapshot) => _isHiddenFromData(snapshot.data()),
        );
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
    if (!Platform.isIOS) return paymentsHiddenStream();

    return Stream<bool>.multi((controller) {
      final entitlement = InAppPurchaseService.instance.iosEntitlementActive;
      void emitStatus() => controller.add(entitlement.value);
      entitlement.addListener(emitStatus);
      emitStatus();
      controller.onCancel = () {
        entitlement.removeListener(emitStatus);
      };
    });
  }

  static Future<bool> arePremiumFeaturesUnlocked() async {
    if (!Platform.isIOS) return arePaymentsHidden();
    await InAppPurchaseService.instance.refreshEntitlement();
    return InAppPurchaseService.instance.iosEntitlementActive.value;
  }
}
