import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:nikah_blessing/Email_Authentication/EmailSignIn_Page.dart';
import 'package:nikah_blessing/Email_Authentication/OTP_Verification_Page.dart';
import 'package:nikah_blessing/Email_Authentication/generate_otp_and_send_mail.dart';

class EmailAuth_Main extends StatefulWidget {
  const EmailAuth_Main({super.key});

  @override
  State<EmailAuth_Main> createState() => _EmailAuth_MainState();
}

class _EmailAuth_MainState extends State<EmailAuth_Main> {
  final PageController _pageController = PageController(initialPage: 0);
  final GenerateOtpAndSendMail _otpService = GenerateOtpAndSendMail();

  void navigateToNextPage() {
    int nextPage = _pageController.page!.toInt() + 1;
    if (nextPage < 2) {
      _pageController.animateToPage(nextPage,
          duration: Duration(milliseconds: 500), curve: Curves.ease);
    }
  }

  void navigateToPrevPage() {
    int nextPage = _pageController.page!.toInt() - 1;
    if (nextPage < 2) {
      _pageController.animateToPage(nextPage,
          duration: Duration(milliseconds: 500), curve: Curves.ease);
    }
  }

  TextEditingController NameTextEditingController = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: PageView(
          physics: NeverScrollableScrollPhysics(), // Disable manual scrolling
          controller: _pageController,
          children: <Widget>[
            EmailSignIn_Page(
                navigateToNextPage: navigateToNextPage,
                navigateToPrevPage: navigateToPrevPage,
                otpService: _otpService),
            OTP_Verification_Page(
                navigateToNextPage: navigateToNextPage,
                navigateToPrevPage: navigateToPrevPage,
                otpService: _otpService),
          ],
        ),
      ),
    );
  }
}
