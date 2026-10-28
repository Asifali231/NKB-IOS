import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:nikah_blessing/DataClass/UserData.dart';
import 'package:nikah_blessing/Email_Authentication/generate_otp_and_send_mail.dart';

import 'package:quickalert/quickalert.dart';
import 'package:slider_button/slider_button.dart';
import 'package:email_validator/email_validator.dart';

import '../Make_Profile/Profile_Questionnaire_main.dart';
import '../User_Home_Pages/user_main.dart';
import 'apple_signin.dart';
import 'createUserInFireStore.dart';
import 'google_signin.dart';

class EmailSignIn_Page extends StatefulWidget {
  final VoidCallback navigateToNextPage, navigateToPrevPage;
  final GenerateOtpAndSendMail otpService;

  EmailSignIn_Page(
      {required this.navigateToNextPage,
      required this.navigateToPrevPage,
      required this.otpService});

  @override
  State<EmailSignIn_Page> createState() => _EmailSignIn_PageState();
}

class _EmailSignIn_PageState extends State<EmailSignIn_Page> {
  GoogleSignInService googleSignInService = GoogleSignInService();
  AppleSignInService appleSignInService = AppleSignInService();

  final _formKey = GlobalKey<FormState>();

  TextEditingController EmailtextEditingController = TextEditingController();
  TextEditingController NameTextEditingController = TextEditingController();

  final FirestoreService _firestoreService = FirestoreService();

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

  navigateToMainScreen(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Handle not logged-in user
      return;
    }

    final uid = user.uid;
    final docRef = FirebaseFirestore.instance.collection('users').doc(uid);

    try {
      final docSnapshot = await docRef.get();
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
      print('Error fetching user data: $e');
      // You can show a snackbar or fallback screen here
    }
  }

  void signInThroughGoogle() async {
    QuickAlert.show(
      title: "Signing You In",
      text: "Please wait while we sign you in",
      context: context,
      type: QuickAlertType.loading,
      barrierDismissible: false,
    ); // That's it to display an alert, use other properties to customize.

    try {
      final googleResult = await googleSignInService.signInWithGoogle();
      final user = googleResult.user;
      print("User signed in: ${googleResult.displayName}");
      print("User signed in: ${googleResult.email}");
      print("User signed in: ${user.uid}");
      print("User signed in: ${user.phoneNumber}");
      print("User signed in: ${user.photoURL}");

      await _firestoreService.saveUserToFirestore(
        name: googleResult.displayName,
        email: googleResult.email,
        uid: user.uid,
      );

      if (mounted) Navigator.pop(context);

      QuickAlert.show(
        title: "Successfully SignedIn",
        context: context,
        type: QuickAlertType.success,
        onConfirmBtnTap: () {
          navigateToMainScreen(context);
        },
      );
    } catch (e) {
      print("Sign-in failed: $e");
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      QuickAlert.show(
        title: "An Error Occurred",
        text: "Try again later network error ",
        context: context,
        type: QuickAlertType.error,
        barrierDismissible: true,
      );
    }
  }

  Future<void> signInThroughApple() async {
    QuickAlert.show(
      title: "Signing You In",
      text: "Please wait while we sign you in",
      context: context,
      type: QuickAlertType.loading,
      barrierDismissible: false,
    );

    try {
      final appleResult = await appleSignInService.signInWithApple();
      final user = appleResult.user;

      await _firestoreService.saveUserToFirestore(
        name: appleResult.displayName,
        email: appleResult.email,
        uid: user.uid,
      );

      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      QuickAlert.show(
        title: "Successfully SignedIn",
        context: context,
        type: QuickAlertType.success,
        onConfirmBtnTap: () {
          navigateToMainScreen(context);
        },
      );
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      QuickAlert.show(
        title: "An Error Occurred",
        text: e.toString().replaceFirst('Exception: ', ''),
        context: context,
        type: QuickAlertType.error,
        barrierDismissible: true,
      );
    }
  }

  bool get _shouldShowAppleSignIn =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset('assets/phone_auth_anim.json',
                  width: 150, height: 150),
              SizedBox(height: 10),
              Text(
                'Email Verification',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'We need to register you before getting started',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 0),
              Padding(
                padding: EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    children: <Widget>[
                      Container(
                        width: MediaQuery.of(context).size.width,
                        child: Text(
                          ' Full Name',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      TextFormField(
                        controller: NameTextEditingController,
                        decoration: InputDecoration(
                          suffixIcon: Icon(Icons.person_2_outlined),
                          contentPadding: EdgeInsets.only(left: 10),
                          border: OutlineInputBorder(),
                          hintText: "Muhammad Ali Afzal",
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter your name";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 10),
                      Container(
                        width: MediaQuery.of(context).size.width,
                        child: Text(
                          ' Email Address',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      TextFormField(
                        controller: EmailtextEditingController,
                        decoration: InputDecoration(
                          suffixIcon: Icon(CupertinoIcons.mail),
                          contentPadding: EdgeInsets.only(left: 10),
                          border: OutlineInputBorder(),
                          hintText: "AliAfzal_456@gmail.com",
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter a valid email";
                          } else if (!EmailValidator.validate(value)) {
                            return "Please enter a valid email";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      Container(
                        height: 50,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              QuickAlert.show(
                                title: "Sending Verification ",
                                text:
                                    "Please wait while we send you verification mail",
                                context: context,
                                type: QuickAlertType.loading,
                                barrierDismissible: false,
                              ); // That's it to display an alert, use other properties to customize.

                              try {
                                final result = await widget.otpService.sendMail(
                                  EmailtextEditingController.text.trim(),
                                );
                                if (!mounted) return;
                                Navigator.pop(context);
                                if (result != 'true') {
                                  QuickAlert.show(
                                    title: 'Unable to send verification code',
                                    text: result,
                                    context: context,
                                    type: QuickAlertType.error,
                                  );
                                  return;
                                }

                                UserData.Email =
                                    EmailtextEditingController.text.trim();
                                widget.navigateToNextPage();
                              } catch (error) {
                                if (!mounted) return;
                                Navigator.pop(context);
                                QuickAlert.show(
                                  title: 'Unable to send verification code',
                                  text: error.toString(),
                                  context: context,
                                  type: QuickAlertType.error,
                                );
                              }
                            }
                          },
                          child: Text(
                            'Send Verification code',
                            style: TextStyle(color: Colors.white, fontSize: 15),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 0),
              Text(
                'Or Continue with',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              Container(
                margin: EdgeInsets.all(20),
                width: MediaQuery.of(context).size.width - 40,
                child: SliderButton(
                  height: 60,
                  buttonSize: 60,
                  buttonColor: Colors.white70,
                  action: () async {
                    ///Do something here OnSlide

                    signInThroughGoogle();
                    return false;
                  },
                  label: Center(
                    child: Text(
                      "    Slide to signup with google",
                      style: TextStyle(
                        color: Color(0xff4a4a4a),
                        fontWeight: FontWeight.w500,
                        fontSize: 17,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  icon: Image.asset(
                    "assets/google.png",
                    width: 50,
                    height: 50,
                  ),
                ),
              ),
              if (_shouldShowAppleSignIn)
                Container(
                  margin: const EdgeInsets.only(left: 20, right: 20, bottom: 8),
                  width: MediaQuery.of(context).size.width - 40,
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: signInThroughApple,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.apple, size: 22),
                          SizedBox(width: 10),
                          Text(
                            'Continue with Apple',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
