import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/services.dart';
import 'package:nikah_blessing/DataClass/UserData.dart';
import 'package:nikah_blessing/Email_Authentication/generate_otp_and_send_mail.dart';

import 'package:nikah_blessing/theme/app_alert.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:slider_button/slider_button.dart';
import 'package:email_validator/email_validator.dart';

import '../Make_Profile/Profile_Questionnaire_main.dart';
import '../User_Home_Pages/user_main.dart';
import 'apple_signin.dart';
import 'createUserInFireStore.dart';
import 'google_signin.dart';
import 'ios_login_blob_decoration.dart';

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

class _EmailSignIn_PageState extends State<EmailSignIn_Page>
    with SingleTickerProviderStateMixin {
  static const _maximumTextScale = 1.2;

  GoogleSignInService googleSignInService = GoogleSignInService();
  AppleSignInService appleSignInService = AppleSignInService();

  late final AnimationController _loginAnimationController;
  late final Animation<double> _loginOpacity;
  late final Animation<Offset> _loginOffset;

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
    FocusManager.instance.primaryFocus?.unfocus();
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
    showAppAlert(
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
        acceptedTerms: widget.otpService.hasAcceptedTerms,
        name: googleResult.displayName,
        email: googleResult.email,
        uid: user.uid,
      );

      if (mounted) Navigator.pop(context);

      showAppAlert(
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

      showAppAlert(
        title: "An Error Occurred",
        text: "Try again later network error ",
        context: context,
        type: QuickAlertType.error,
        barrierDismissible: true,
      );
    }
  }

  Future<void> signInThroughApple() async {
    showAppAlert(
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
        acceptedTerms: widget.otpService.hasAcceptedTerms,
        name: appleResult.displayName,
        email: appleResult.email,
        uid: user.uid,
      );

      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      showAppAlert(
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

      showAppAlert(
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

  bool get _isIOS => !kIsWeb && Platform.isIOS;

  String? _signingInProvider;

  @override
  void initState() {
    super.initState();
    if (!_isIOS) return;

    _loginAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loginOpacity = CurvedAnimation(
      parent: _loginAnimationController,
      curve: Curves.easeOut,
    );
    _loginOffset = Tween<Offset>(
      begin: const Offset(0, 0.035),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _loginAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _loginAnimationController.forward();
  }

  @override
  void dispose() {
    if (_isIOS) _loginAnimationController.dispose();
    EmailtextEditingController.dispose();
    NameTextEditingController.dispose();
    super.dispose();
  }

  Future<void> _signInOnIOS({required bool useApple}) async {
    if (_signingInProvider != null) return;
    await HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() => _signingInProvider = useApple ? 'apple' : 'google');

    try {
      late final User user;
      String? name;
      String? email;

      if (useApple) {
        final result = await appleSignInService.signInWithApple();
        user = result.user;
        name = result.displayName;
        email = result.email;
      } else {
        final result = await googleSignInService.signInWithGoogleForIOS();
        user = result.user;
        name = result.displayName;
        email = result.email;
      }

      final created = await _firestoreService.createUserIfAbsent(
        acceptedTerms: widget.otpService.hasAcceptedTerms,
        name: name,
        email: email,
        uid: user.uid,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              created ? Profile_Questionnaire_main() : UserMain(),
        ),
      );
    } on FirebaseAuthException catch (error) {
      debugPrint('iOS social sign-in failed: ${error.code}');
      if (error.code == 'canceled' ||
          error.code == 'web-context-cancelled' ||
          error.code == 'popup-closed-by-user') {
        return;
      } else if (error.code == 'account-exists-with-different-credential') {
        _showIOSSignInMessage(
          'An account already exists with this email. Please continue with the provider you used originally.',
        );
      } else if (error.code == 'network-request-failed') {
        _showIOSSignInMessage(
          'Please check your internet connection and try again.',
        );
      } else {
        _showIOSSignInMessage(
          'We could not complete sign-in. Please try again.',
        );
      }
    } on SignInWithAppleAuthorizationException catch (error) {
      debugPrint('Apple authorization failed: ${error.code}');
      if (error.code != AuthorizationErrorCode.canceled) {
        _showIOSSignInMessage(
          'We could not complete sign-in. Please try again.',
        );
      }
    } catch (error) {
      debugPrint('iOS social sign-in failed: $error');
      final errorMessage = error.toString().toLowerCase();
      if (!errorMessage.contains('cancelled by user') &&
          !errorMessage.contains('canceled by user')) {
        _showIOSSignInMessage(
          'We could not complete sign-in. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _signingInProvider = null);
    }
  }

  void _showIOSSignInMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Widget _buildIOSLoginScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.textScalerOf(context)
                .clamp(maxScaleFactor: _maximumTextScale),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              fit: StackFit.expand,
              children: [
                const IOSLoginBlobDecoration(),
                SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: FadeTransition(
                            opacity: _loginOpacity,
                            child: SlideTransition(
                              position: _loginOffset,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/images/icon.png',
                                    width: 96,
                                    height: 96,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(height: 22),
                                  const Text(
                                    'Sign in to Nikah Blessing',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Continue with your Apple or Google account. It only takes a moment.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF6B6B6B),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  Semantics(
                                    button: true,
                                    label: 'Sign in with Apple',
                                    enabled: _signingInProvider == null,
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 54,
                                      child: ElevatedButton(
                                        onPressed: _signingInProvider == null
                                            ? () => _signInOnIOS(
                                                  useApple: true,
                                                )
                                            : null,
                                        style: ElevatedButton.styleFrom(
                                          elevation: 1,
                                          shadowColor:
                                              const Color(0x1F000000),
                                          backgroundColor: Colors.black,
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor: Colors.black,
                                          disabledForegroundColor:
                                              Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                        ),
                                        child:
                                            _signingInProvider == 'apple'
                                                ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : const Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.apple,
                                                        size: 22,
                                                      ),
                                                      SizedBox(width: 10),
                                                      Text(
                                                        'Continue with Apple',
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Semantics(
                                    button: true,
                                    label: 'Sign in with Google',
                                    enabled: _signingInProvider == null,
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 54,
                                      child: OutlinedButton(
                                        onPressed: _signingInProvider == null
                                            ? () => _signInOnIOS(
                                                  useApple: false,
                                                )
                                            : null,
                                        style: OutlinedButton.styleFrom(
                                          elevation: 1,
                                          shadowColor:
                                              const Color(0x14000000),
                                          backgroundColor: Colors.white,
                                          foregroundColor:
                                              const Color(0xFF292929),
                                          side: const BorderSide(
                                            color: Color(0xFFD8D8D8),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                        ),
                                        child:
                                            _signingInProvider == 'google'
                                                ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Color(0xFF5F6368),
                                                    ),
                                                  )
                                                : Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Image.asset(
                                                        'assets/google.png',
                                                        width: 22,
                                                        height: 22,
                                                      ),
                                                      const SizedBox(
                                                          width: 10),
                                                      const Text(
                                                        'Continue with Google',
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'New here? Your account is created automatically. Already registered? You will go straight to your account.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.45,
                                      color: Color(0xFF777777),
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.lock_outline,
                                        size: 14,
                                        color: Color(0xFF777777),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Secure sign in',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF777777),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isIOS) return _buildIOSLoginScreen();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
              const SizedBox(height: 0),
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
                          if (value == null || value.trim().isEmpty) {
                            return "Please enter your full name before requesting a code";
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
                          if (value == null || value.trim().isEmpty) {
                            return "Please enter a valid email";
                          } else if (!EmailValidator.validate(value.trim())) {
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
                              showAppAlert(
                                title: "Sending Verification ",
                                text:
                                    "Please wait while we send you verification mail",
                                context: context,
                                type: QuickAlertType.loading,
                                barrierDismissible: false,
                              ); // That's it to display an alert, use other properties to customize.

                              try {
                                final email =
                                    EmailtextEditingController.text.trim();
                                final result =
                                    await widget.otpService.sendMail(email);
                                if (!mounted) return;
                                Navigator.pop(context);
                                if (result != 'true') {
                                  showAppAlert(
                                    title: 'Unable to send verification code',
                                    text: result,
                                    context: context,
                                    type: QuickAlertType.error,
                                  );
                                  return;
                                }

                                UserData.Name =
                                    NameTextEditingController.text.trim();
                                UserData.Email = email;
                                widget.navigateToNextPage();
                              } catch (error) {
                                if (!mounted) return;
                                Navigator.pop(context);
                                showAppAlert(
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
