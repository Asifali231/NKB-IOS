import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../DataClass/UserData.dart';

class FirestoreService {
  String? _userDeviceToken;

  FirestoreService() {
    _getDeviceToken();
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

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Retrieve the device token
        String? token = await messaging.getToken();
        _userDeviceToken = token;
        print('Device token: $_userDeviceToken');
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
  }) async {
    await _getDeviceToken();

    final String deviceToken = _userDeviceToken ?? '';
    if (_userDeviceToken == null) {
      print(
          'Warning: Device token not available; saving user without FCM token');
    }

    try {
      CollectionReference users =
          FirebaseFirestore.instance.collection('users');

      // Check if user already exists
      DocumentSnapshot docSnapshot = await users.doc(uid).get();

      if (docSnapshot.exists) {
        // If user already exists, update the record
        await users.doc(uid).update({
          'name': name,
          'email': email,
          'fcmToken': deviceToken,
          'userDeviceToken': deviceToken,
          'updatedAt': FieldValue.serverTimestamp(), // Timestamp of last update
        });
        print('User data updated successfully.');
      } else {
        // If user doesn't exist, create a new record
        await users.doc(uid).set({
          'name': name,
          'email': email,
          'uid': uid,
          'fcmToken': deviceToken,
          'userDeviceToken': deviceToken,
          'createdAt':
              FieldValue.serverTimestamp(), // Timestamp of record creation
          'friends': [], // Timestamp of record creation
          'friendsRequests': [], // Timestamp of record creation
          'blockUsers': [], // Timestamp of record creation
          'savedProposal': [], // Timestamp of record creation
        });
        print('User data added successfully.');
      }

      // Store user data in UserData
      UserData.Name = name;
      UserData.Email = email;
      UserData.userID = uid;
      UserData.userDeviceToken = deviceToken;
    } catch (e) {
      print('Error saving or updating user data: $e');
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
