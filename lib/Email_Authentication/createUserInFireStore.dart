import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../DataClass/UserData.dart';

class FirestoreService {
  String? _userDeviceToken;

  Future<bool> createUserIfAbsent({
    required String? name,
    required String? email,
    required String uid,
    required bool acceptedTerms,
  }) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    if ((await userRef.get()).exists) return false;

    await _getDeviceToken();

    final suppliedName = name?.trim();
    final savedName =
        suppliedName == null || suppliedName.isEmpty ? 'User' : suppliedName;
    final savedEmail = email?.trim() ?? '';
    final deviceToken = _userDeviceToken;
    final termsData = acceptedTerms
        ? {
            'termsAccepted': true,
            'termsAcceptedAt': FieldValue.serverTimestamp(),
            'termsVersion': '1.0',
          }
        : <String, dynamic>{};

    final created = await FirebaseFirestore.instance.runTransaction<bool>(
      (transaction) async {
        final snapshot = await transaction.get(userRef);
        if (snapshot.exists) return false;

        transaction.set(userRef, {
          'name': savedName,
          'email': savedEmail,
          'uid': uid,
          if (deviceToken != null && deviceToken.isNotEmpty) ...{
            'fcmToken': deviceToken,
            'userDeviceToken': deviceToken,
          },
          'createdAt': FieldValue.serverTimestamp(),
          'friends': [],
          'friendsRequests': [],
          'blockUsers': [],
          'savedProposal': [],
          ...termsData,
        });
        return true;
      },
    );

    if (created) {
      UserData.Name = savedName;
      UserData.Email = savedEmail;
      UserData.userID = uid;
      UserData.userDeviceToken = deviceToken ?? '';
    }

    return created;
  }

  // Get the device token from Firebase Messaging
  Future<void> _getDeviceToken() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      // Request permission for notifications
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Retrieve the device token
        String? token = await messaging.getToken();
        _userDeviceToken = token;
        print(
            'Push notification token ${token == null ? 'unavailable' : 'registered'}.');
      } else {
        print('User declined or has not accepted notification permissions');
      }
    } catch (e) {
      print('Error retrieving device token: $e');
    }
  }

  // Save or update user data in Firestore
  Future<void> saveUserToFirestore({
    required String name,
    required String email,
    required String uid,
    required bool acceptedTerms,
  }) async {
    await _getDeviceToken();

    final String? deviceToken = _userDeviceToken;
    if (deviceToken == null || deviceToken.isEmpty) {
      print(
          'Warning: Device token not available; preserving any existing FCM token');
    }

    try {
      CollectionReference users =
          FirebaseFirestore.instance.collection('users');

      // Check if user already exists
      DocumentSnapshot docSnapshot = await users.doc(uid).get();
      final termsData = acceptedTerms
          ? {
              'termsAccepted': true,
              'termsAcceptedAt': FieldValue.serverTimestamp(),
              'termsVersion': '1.0',
            }
          : <String, dynamic>{};

      if (docSnapshot.exists) {
        final existingName =
            (docSnapshot.data() as Map<String, dynamic>?)?['name']?.toString();
        final savedName = name.trim().isEmpty || name.trim() == 'Not Set'
            ? (existingName?.trim().isNotEmpty == true ? existingName : name)
            : name;
        // If user already exists, update the record
        await users.doc(uid).update({
          'name': savedName,
          'email': email,
          if (deviceToken != null && deviceToken.isNotEmpty) ...{
            'fcmToken': deviceToken,
            'userDeviceToken': deviceToken,
          },
          ...termsData,
          'updatedAt': FieldValue.serverTimestamp(), // Timestamp of last update
        });
        print('User data updated successfully.');
      } else {
        // If user doesn't exist, create a new record
        await users.doc(uid).set({
          'name': name,
          'email': email,
          'uid': uid,
          if (deviceToken != null && deviceToken.isNotEmpty) ...{
            'fcmToken': deviceToken,
            'userDeviceToken': deviceToken,
          },
          'createdAt':
              FieldValue.serverTimestamp(), // Timestamp of record creation
          'friends': [], // Timestamp of record creation
          'friendsRequests': [], // Timestamp of record creation
          'blockUsers': [], // Timestamp of record creation
          'savedProposal': [], // Timestamp of record creation
          ...termsData,
        });
        print('User data added successfully.');
      }

      // Store user data in UserData
      UserData.Name = name;
      UserData.Email = email;
      UserData.userID = uid;
      UserData.userDeviceToken = deviceToken ?? '';
    } catch (e) {
      print('Error saving or updating user data: $e');
      rethrow;
    }
  }

  //
  // final FirebaseAuth _auth = FirebaseAuth.instance;
  //
  // Future<void> signInWithEmail(String email, String password) async {
  //   try {
  //     UserCredential userCredential = await _auth.signInWithEmailAndPassword(
  //       email: email,
  //       password: password,
  //     );
  //
  //     User? user = userCredential.user;
  //
  //     if (user != null) {
  //       print("✅ Signed in as: ${user.email}");
  //       print("🔑 User ID: ${user.uid}");
  //     }
  //   } on FirebaseAuthException catch (e) {
  //     if (e.code == 'user-not-found') {
  //       print('❌ No user found for that email.');
  //     } else if (e.code == 'wrong-password') {
  //       print('❌ Wrong password provided.');
  //     } else {
  //       print('❌ Error: ${e.message}');
  //     }
  //   }
  // }
}
