// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:quickalert/models/quickalert_type.dart';
// import 'package:quickalert/widgets/quickalert_dialog.dart';
// import '../DataClass/UserData.dart';
// import '../Make_Profile/Profile_Questionnaire_main.dart';
// import '../User_Home_Pages/user_main.dart';
// import 'createUserInFireStore.dart';
//
//
// class OTP_Verification_Page extends StatefulWidget {
//   const OTP_Verification_Page({super.key});
//
//   @override
//   State<OTP_Verification_Page> createState() => _OTP_Verification_PageState();
// }
//
// class _OTP_Verification_PageState extends State<OTP_Verification_Page> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirestoreService firestoreService = FirestoreService();
//   String? _userDeviceToken = "some-device-token"; // Assume this is set elsewhere
//
//   Future<void> saveUserToFirestore({
//     required String name,
//     required String email,
//     required String uid,
//   }) async {
//     if (_userDeviceToken == null) {
//       throw Exception('Device token is not available');
//     }
//
//     try {
//       CollectionReference users = FirebaseFirestore.instance.collection('users');
//
//       DocumentSnapshot docSnapshot = await users.doc(uid).get();
//
//       if (docSnapshot.exists) {
//         await users.doc(uid).update({
//           'name': name,
//           'email': email,
//           'userDeviceToken': _userDeviceToken,
//           'updatedAt': FieldValue.serverTimestamp(),
//         });
//         print('User data updated successfully.');
//       } else {
//         await users.doc(uid).set({
//           'name': name,
//           'email': email,
//           'uid': uid,
//           'userDeviceToken': _userDeviceToken,
//           'createdAt': FieldValue.serverTimestamp(),
//           'friends': [],
//           'friendsRequests': [],
//           'blockUsers': [],
//           'savedProposal': [],
//         });
//         print('User data added successfully.');
//       }
//
//       UserData.Name = name;
//       UserData.Email = email;
//       UserData.userID = uid;
//       UserData.userDeviceToken = _userDeviceToken!;
//     } catch (e) {
//       print('Error saving or updating user data: $e');
//       throw e;
//     }
//   }
//
//   Future<void> signInWithEmail(String email, String password) async {
//     if (email.isEmpty || password.isEmpty) {
//       throw Exception("Email or password is empty.");
//     }
//
//     try {
//       UserCredential userCredential = await _auth.signInWithEmailAndPassword(
//         email: email.trim(),
//         password: password,
//       );
//
//       await saveUserToFirestore(
//         name: "Not Set",
//         email: email.trim(),
//         uid: userCredential.user!.uid,
//       );
//
//       print("✅ Signed in as: ${userCredential.user?.email}");
//       print("🔑 User ID: ${userCredential.user?.uid}");
//     } on FirebaseAuthException catch (e) {
//       if (e.code == 'user-not-found') {
//         UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
//           email: email.trim(),
//           password: password,
//         );
//
//         await saveUserToFirestore(
//           name: "Not Set",
//           email: email.trim(),
//           uid: userCredential.user!.uid,
//         );
//
//         print("✅ Account created & signed in as: ${userCredential.user?.email}");
//         print("🔑 User ID: ${userCredential.user?.uid}");
//       } else {
//         throw e;
//       }
//     }
//   }
//
//   Future<void> navigateToMainScreen(BuildContext context) async {
//     QuickAlert.show(
//       context: context,
//       type: QuickAlertType.loading,
//       title: "Loading",
//       text: "Please wait while we verify you",
//       barrierDismissible: false,
//     );
//
//     try {
//       await signInWithEmail(UserData.Email, UserData.Email);
//
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) {
//         throw Exception("User not authenticated.");
//       }
//
//       final uid = user.uid;
//       final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
//       final docSnapshot = await docRef.get();
//
//       Navigator.pop(context);
//
//       if (docSnapshot.exists) {
//         final data = docSnapshot.data();
//         final profileImageUrls = data?['ProfileImageUrls'] as List<dynamic>?;
//
//         if (profileImageUrls == null) {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (context) => Profile_Questionnaire_main()),
//           );
//         } else {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (context) => UserMain()),
//           );
//         }
//       } else {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => Profile_Questionnaire_main()),
//         );
//       }
//     } catch (e) {
//       Navigator.pop(context);
//       Fluttertoast.showToast(msg: "Error: ${e.toString()}");
//       print('Error in navigateToMainScreen: $e');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     TextEditingController otpController = TextEditingController();
//     String correctOtp = "8789798797"; // Example OTP, replace with actual logic
//
//     return Scaffold(
//       appBar: AppBar(title: Text("OTP Verification")),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             TextField(
//               controller: otpController,
//               decoration: InputDecoration(labelText: "Enter OTP"),
//               keyboardType: TextInputType.number,
//             ),
//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () async {
//                 if (otpController.text == correctOtp) {
//                   await navigateToMainScreen(context);
//                 } else {
//                   Fluttertoast.showToast(msg: "Incorrect OTP");
//                 }
//               },
//               child: Text("Verify Code"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nikah_blessing/DataClass/UserData.dart';
import 'package:nikah_blessing/Email_Authentication/createUserInFireStore.dart';
import 'package:nikah_blessing/Email_Authentication/generate_otp_and_send_mail.dart';
import 'package:nikah_blessing/Make_Profile/Profile_Questionnaire_main.dart';
import 'package:nikah_blessing/User_Home_Pages/user_main.dart';
import 'package:pinput/pinput.dart';
import 'package:quickalert/quickalert.dart';

class OTP_Verification_Page extends StatefulWidget {
  final VoidCallback navigateToNextPage, navigateToPrevPage;
  final GenerateOtpAndSendMail otpService;

  OTP_Verification_Page(
      {required this.navigateToNextPage,
      required this.navigateToPrevPage,
      required this.otpService});

  @override
  State<OTP_Verification_Page> createState() => _OTP_Verification_PageState();
}

class _OTP_Verification_PageState extends State<OTP_Verification_Page> {
  FirestoreService firestoreService = new FirestoreService();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _hasExistingProfile(Map<String, dynamic>? data) {
    if (data == null) {
      return false;
    }

    final profileImageUrls = data['ProfileImageUrls'];
    final hasProfileImages =
        profileImageUrls is List && profileImageUrls.isNotEmpty;
    final verificationStatus =
        (data['VerificationStatus'] ?? '').toString().trim();

    return hasProfileImages || verificationStatus.isNotEmpty;
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      print("❌ Email or password is empty.");
      return null;
    }

    debugPrint('Attempting email sign-in for $email');

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        await firestoreService.saveUserToFirestore(
          name: "Not Set",
          email: email.trim(),
          uid: userCredential.user!.uid,
        );
      }

      print("✅ Signed in as: ${userCredential.user?.email}");
      print("🔑 User ID: ${userCredential.user?.uid}");

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        try {
          UserCredential userCredential =
              await _auth.createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );

          await firestoreService.saveUserToFirestore(
            name: "Not Set",
            email: email.trim(),
            uid: userCredential.user!.uid,
          );

          print(
              "✅ Account created & signed in as: ${userCredential.user?.email}");
          print("🔑 User ID: ${userCredential.user?.uid}");

          return userCredential;
        } on FirebaseAuthException catch (createError) {
          print('❌ Error creating user: ${createError.message}');
          return null;
        }
      } else if (e.code == 'wrong-password') {
        print('❌ Wrong password provided for existing user.');
        return null;
      } else {
        print('❌ Sign-in error: ${e.message}');
        return null;
      }
    }
  }

  navigateToMainScreen(BuildContext context) async {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.loading,
      title: "Loading ",
      text: "Please wait while we verify you",
      barrierDismissible: false,
    );

    final userCredential =
        await signInWithEmail(UserData.Email, UserData.Email);
    final user = userCredential?.user ?? FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      Fluttertoast.showToast(msg: "Unable to sign in. Please try again.");
      return;
    }

    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    try {
      final docSnapshot = await docRef.get();

      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (docSnapshot.exists) {
        final data = docSnapshot.data();

        if (_hasExistingProfile(data)) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => UserMain()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => Profile_Questionnaire_main()),
          );
        }
      } else {
        // User document not found
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Profile_Questionnaire_main()),
        );
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      print('Error fetching user data: $e');
      Fluttertoast.showToast(msg: 'Error fetching user data');
    }
  }

  TextEditingController OTPtextEditingController = new TextEditingController();

  String _enteredOtp = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/otp.png', width: 250, height: 250),
              const SizedBox(height: 10),
              const Text('Email Verification',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text(
                'Please Check Your Email & Enter 6-digit Verification Code',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 20,
              ),
              Container(
                margin: EdgeInsets.only(left: 10, right: 10),
                child: Pinput(
                  length: 6,
                  showCursor: true,
                  onChanged: (value) {
                    _enteredOtp = value;
                  },
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Container(
                height: 50,
                width: double.infinity,
                margin: EdgeInsets.only(right: 20, left: 20, top: 10),
                child: ElevatedButton(
                  onPressed: () {
                    if (widget.otpService.verifyOtp(_enteredOtp)) {
                      navigateToMainScreen(context);
                    } else {
                      Fluttertoast.showToast(
                        msg: 'The code is incorrect or has expired.',
                      );
                    }
                  },
                  child: Text(
                    'Verify Code',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  TextButton(
                      onPressed: () {
                        widget.navigateToPrevPage();
                      },
                      child: const Text(
                        'Edit email address',
                        style: TextStyle(color: Colors.black),
                      )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
