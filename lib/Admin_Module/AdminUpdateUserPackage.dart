import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:nikah_blessing/Notifications/NotificationPage.dart';

class UserPackage {
  int _safeInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value.trim()) ?? fallback;
    }
    return fallback;
  }

  String _normalizePackageToken(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _resolvePackageDocument(
    FirebaseFirestore db,
    String packageIdentifier,
  ) async {
    final packagesRef = db.collection('packages');
    final rawIdentifier = packageIdentifier.trim();

    if (rawIdentifier.isEmpty) {
      return null;
    }

    final byId = await packagesRef.doc(rawIdentifier).get();
    if (byId.exists) {
      return byId;
    }

    final byName = await packagesRef
        .where('name', isEqualTo: rawIdentifier)
        .limit(1)
        .get();
    if (byName.docs.isNotEmpty) {
      return byName.docs.first;
    }

    final target = _normalizePackageToken(rawIdentifier);
    if (target.isEmpty) {
      return null;
    }

    final allPackages = await packagesRef.get();
    for (final packageDoc in allPackages.docs) {
      final packageData = packageDoc.data();
      final packageName = (packageData['name'] ?? packageDoc.id).toString();

      if (_normalizePackageToken(packageName) == target ||
          _normalizePackageToken(packageDoc.id) == target) {
        return packageDoc;
      }
    }

    return null;
  }

  DateTime _calculatePackageExpiry(dynamic daysValue) {
    final normalizedValue = daysValue?.toString().trim().toLowerCase() ?? '';

    if (normalizedValue == 'unlimited') {
      return DateTime(2039, 12, 31);
    }

    final parsedDays = _safeInt(daysValue);
    if (parsedDays <= 0) {
      return DateTime(2039, 12, 31);
    }

    return DateTime.now().add(Duration(days: parsedDays));
  }

  Future<void> addPackagesToFirestore() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference packagesRef = firestore.collection('packages');

    Map<String, Map<String, dynamic>> packages = {
      "Free": {
        "name": "Free",
        "ChatCredit": 1,
        "DailyProfiles": 5,
        "days": "unlimited",
        "price": 0
      },
      "Premium": {
        "name": "Premium",
        "ChatCredit": 5,
        "DailyProfiles": 20,
        "days": 30,
        "price": 5500
      },
      "DisablePackage": {
        "name": "DisablePackage",
        "ChatCredit": 3,
        "DailyProfiles": 10,
        "days": 30,
        "price": 1500
      },
      "FemalePackage": {
        "name": "FemalePackage",
        "ChatCredit": 20,
        "DailyProfiles": 15,
        "days": 30,
        "price": 1500
      },
    };

    for (String key in packages.keys) {
      await packagesRef.doc(key).set(packages[key]!);
    }
  }

  Future<bool> updateUserPackage(String uid, String pkgName) async {
    try {
      FirebaseFirestore db = FirebaseFirestore.instance;
      DocumentReference docRef = db.collection('users').doc(uid);
      DocumentSnapshot docSnapshot = await docRef.get();
      final pkgDocSnapshot =
          await _resolvePackageDocument(db, pkgName.toString());

      if (!docSnapshot.exists) {
        debugPrint('User not found');
        return false;
      }

      if (pkgDocSnapshot == null || !pkgDocSnapshot.exists) {
        debugPrint('Package not found for identifier: $pkgName');
        return false;
      }

      Map<String, dynamic>? userData =
          docSnapshot.data() as Map<String, dynamic>?;
      final pkgData = pkgDocSnapshot.data();

      if (userData == null || pkgData == null) {
        debugPrint('Missing user or package data');
        return false;
      }

      final updatedPackageName =
          (pkgData["name"] ?? pkgDocSnapshot.id).toString();
      final updatedChatCredit =
          _safeInt(userData["ChatCredit"]) + _safeInt(pkgData["ChatCredit"]);
      final updatedDailyProfiles = _safeInt(userData["DailyProfiles"]) +
          _safeInt(pkgData["DailyProfiles"]);
      final futureDate = _calculatePackageExpiry(pkgData["days"]);

      final packageUpdateData = {
        'PackageSubscribed': updatedPackageName,
        'ChatCredit': updatedChatCredit,
        'DailyProfiles': updatedDailyProfiles,
        'PackageExpiry': futureDate.toIso8601String(),
      };

      await docRef.update(packageUpdateData);

      await FirebaseFirestore.instance
          .collection('proposals')
          .doc(userData['JobCountry'])
          .collection(userData['Gender'])
          .doc(userData['uid'])
          .set(packageUpdateData, SetOptions(merge: true));

      NotificationPage notificationService = NotificationPage();
      notificationService.sendNotification("Package Approved",
          "Your Package Successfully Subscribed", "imgurl", userData['uid']);

      debugPrint("Package Subscribes");

      return true;
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      return false;
    }
  }

  Future<bool> updateUserFilter(
    int partnerAgeMin,
    int partnerAgeMax,
    String partnerSect,
    List<String> partnerCountries,
    List<String> partnerMartialStatus,
  ) async {
    try {
      FirebaseFirestore db = FirebaseFirestore.instance;
      DocumentReference docRef = db
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid.toString());
      DocumentSnapshot docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        Map<String, dynamic>? userData =
            docSnapshot.data() as Map<String, dynamic>?;

        await docRef.update({
          'PartnerMinAge ': partnerAgeMin,
          'PartnerMaxAge ': partnerAgeMax,
          'PartnerCountry ': partnerCountries,
          'PartnerSect ': partnerSect,
          'PartnerCast ': FieldValue.delete(),
          'PartnerMartialStatus ': partnerMartialStatus,
        });

        await FirebaseFirestore.instance
            .collection('proposals')
            .doc(userData?['JobCountry'])
            .collection(userData?['Gender'])
            .doc(userData?['uid'])
            .update({
          'PartnerMinAge ': partnerAgeMin,
          'PartnerMaxAge ': partnerAgeMax,
          'PartnerCountry ': partnerCountries,
          'PartnerSect ': partnerSect,
          'PartnerCast ': FieldValue.delete(),
          'PartnerMartialStatus ': partnerMartialStatus,
        });

        debugPrint("Package Subscribes");

        return true;
      } else {
        debugPrint('User not found');
        return false;
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      return false;
    }
  }
}
