import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nikah_blessing/Make_Profile/Profile_Questionnaire_main.dart';
import 'package:nikah_blessing/User_Home_Pages/user_main.dart';
import 'package:nikah_blessing/onBoardingScreens.dart';

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({Key? key}) : super(key: key);

  Future<Map<String, dynamic>> _checkAuthAndProfileStatus() async {
    // Get current user
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return {
        'isAuthenticated': false,

      };
    }else {
      return {
        'isAuthenticated': true,

      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
        future: _checkAuthAndProfileStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final authStatus = snapshot.data;

          if (authStatus == null || !authStatus['isAuthenticated']) {
            return const onBoardingScreens(); // Navigate to your email authentication page
          }

          return const UserMain(); // Navigate to main app
        }
    );
  }
}