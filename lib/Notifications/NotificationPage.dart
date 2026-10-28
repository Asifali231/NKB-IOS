import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {

  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  Future<void> sendNotification(String title, String body, String imageUrl ,String Uid) async {
    try {

      FirebaseFirestore db = FirebaseFirestore.instance;
      // Reference the specific user document in the "users" collection
      DocumentReference docRef = db.collection('users').doc(Uid);
      // Fetch the document
      DocumentSnapshot docSnapshot = await docRef.get();

      Map<String, dynamic>? userData;


      // Check if the document exists
      if (docSnapshot.exists) {
        // Retrieve the document data as a Map

        userData =
        docSnapshot.data() as Map<String, dynamic>?;
      }


        final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('sendNotification');



      // Create a JSON object with the notification data

      Map<String, dynamic> person = {

        'token': userData?["userDeviceToken"],
        'title': title.toString(),
        'body': body.toString(),
        'imageUrl': imageUrl.toString(),
      };

      print(person);
      // Call the Cloud Function to send the notification
      final response = await callable.call(person);

      if (response.data['success']) {
        print('Notification sent successfully: ${response.data['response']}');
      } else {
        print('Failed to send notification: ${response.data['error']}');
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Send Notification'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await sendNotification("Profile Verified", "Hi your profile has been successfully verified ", "https://th.bing.com/th/id/OIP.odKDxcjwIWSoA4fLV3P1VQHaHa?rs=1&pid=ImgDetMain","");
          },
          child: Text('Send Notification'),
        ),
      ),
    );
  }
}