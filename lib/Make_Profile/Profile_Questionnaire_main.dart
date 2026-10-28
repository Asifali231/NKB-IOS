import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nikah_blessing/Make_Profile/Any_Disability_Page.dart';
import 'package:nikah_blessing/Make_Profile/Apperance.dart';
import 'package:nikah_blessing/Make_Profile/Ask_FindingFor.dart';
import 'package:nikah_blessing/Make_Profile/Ask_Gender.dart';
import 'package:nikah_blessing/Make_Profile/DOB_Page.dart';
import 'package:nikah_blessing/Make_Profile/Documentation_Verification.dart';
import 'package:nikah_blessing/Make_Profile/Education_Page.dart';
import 'package:nikah_blessing/Make_Profile/Family_Background_Page.dart';
import 'package:nikah_blessing/Make_Profile/Martial_Status_Page.dart';
import 'package:nikah_blessing/Make_Profile/Name_Phone_Page.dart';
import 'package:nikah_blessing/Make_Profile/Orgin_Country_Page.dart';
import 'package:nikah_blessing/Make_Profile/Personality_Chips_Page.dart';
import 'package:nikah_blessing/Make_Profile/Profession_Page.dart';
import 'package:nikah_blessing/Make_Profile/Profile_Pictures_Page.dart';
import 'package:nikah_blessing/Make_Profile/FaceVerificationPage.dart';
import 'package:nikah_blessing/Make_Profile/lifePartnerExceptation.dart';

class Profile_Questionnaire_main extends StatefulWidget {
  const Profile_Questionnaire_main({super.key});

  @override
  State<Profile_Questionnaire_main> createState() =>
      _Profile_Questionnaire_mainState();
}

class _Profile_Questionnaire_mainState
    extends State<Profile_Questionnaire_main> {
  static const int _stepCount = 16;
  int currentStep = 1;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_updateCurrentStep);
  }

  void _updateCurrentStep() {
    final newPage = (_pageController.page?.round() ?? 0) + 1;
    if (newPage != currentStep && mounted) {
      setState(() {
        currentStep = newPage;
      });
    }
  }

  void navigateToNextPage() {
    final currentPage = _pageController.page?.round() ?? 0;
    final nextPage = currentPage + 1;
    if (nextPage < _stepCount) {
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.ease,
      );
    }
  }

  void navigateToPrevPage() {
    final currentPage = _pageController.page?.round() ?? 0;
    final previousPage = currentPage - 1;
    if (previousPage >= 0) {
      _pageController.animateToPage(
        previousPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.ease,
      );
    }
  }

  @override
  void dispose() {
    _pageController
      ..removeListener(_updateCurrentStep)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: navigateToPrevPage,
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/QAbg.png',
              fit: BoxFit.cover,
            ),
          ),
          PageView(
            physics: const NeverScrollableScrollPhysics(),
            controller: _pageController,
            children: [
              Ask_FindingFor(
                navigateToNextPage: navigateToNextPage,
                navigateToPrevPage: navigateToPrevPage,
              ),
              Ask_Gender(
                navigateToNextPage: navigateToNextPage,
                navigateToPrevPage: navigateToPrevPage,
              ),
              Name_Phone_Page(
                navigateToNextPage: navigateToNextPage,
                navigateToPrevPage: navigateToPrevPage,
              ),
              DOB_Page(
                navigateToNextPage: navigateToNextPage,
                navigateToPrevPage: navigateToPrevPage,
              ),
              Orgin_Country_Page(
                navigateToNextPage: navigateToNextPage,
                navigateToPrevPage: navigateToPrevPage,
              ),
              Education_Page(
                navigateToNextPage: navigateToNextPage,
                navigateToPrevPage: navigateToPrevPage,
              ),
              Profession_Page(
                navigateToNextPage: navigateToNextPage,
                navigateToPrevPage: navigateToPrevPage,
              ),
              Family_Background_Page(
                navigateToNextPage: navigateToNextPage,
                navigateToPrevPage: navigateToPrevPage,
              ),
              MartialStatusPage(
                navigateToNextPage: navigateToNextPage,
                navigateToPrevPage: navigateToPrevPage,
              ),
              Any_Disability_Page(
                navigateToNextPage: navigateToNextPage,
                navigateToPrevPage: navigateToPrevPage,
              ),
              Profile_Pictures_Page(
                navigateToNextPage: navigateToNextPage,
                navigateToPrevPage: navigateToPrevPage,
              ),
              FaceVerificationPage(
                navigateToNextPage: navigateToNextPage,
                navigateToPrevPage: navigateToPrevPage,
              ),
              Documentation_Verification(
                navigateToNextPage: navigateToNextPage,
                navigateToPrevPage: navigateToPrevPage,
              ),
              Apperance(
                navigateToNextPage: navigateToNextPage,
                navigateToPrevPage: navigateToPrevPage,
              ),
              Personality_Chips_Page(
                navigateToNextPage: navigateToNextPage,
                navigateToPrevPage: navigateToPrevPage,
              ),
              lifePartnerExceptation(
                navigateToNextPage: navigateToNextPage,
                navigateToPrevPage: navigateToPrevPage,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
