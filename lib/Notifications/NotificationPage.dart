import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  Future<void> sendNotification(
    String title,
    String body,
    String imageUrl,
    String uid,
  ) async {
    try {
      final response = await FirebaseFunctions.instance
          .httpsCallable('sendNotification')
          .call<Map<String, dynamic>>({
        'uid': uid,
        'title': title,
        'body': body,
        'imageUrl': imageUrl,
      });

      if (response.data['success'] != true) {
        debugPrint('Notification was not delivered to user $uid.');
      }
    } on FirebaseFunctionsException catch (error) {
      debugPrint(
        'Notification send failed for user $uid: ${error.code} ${error.message}',
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Notification send failed for user $uid: $error\n$stackTrace',
      );
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
            await sendNotification(
                "Profile Verified",
                "Hi your profile has been successfully verified ",
                "https://th.bing.com/th/id/OIP.odKDxcjwIWSoA4fLV3P1VQHaHa?rs=1&pid=ImgDetMain",
                "");
          },
          child: Text('Send Notification'),
        ),
      ),
    );
  }
}
