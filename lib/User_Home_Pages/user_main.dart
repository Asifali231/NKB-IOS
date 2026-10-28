import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nikah_blessing/Admin_Module/AdminUpdateUserPackage.dart';
import 'package:nikah_blessing/Chat_Module/User_Chat_Page.dart';
import 'package:nikah_blessing/DataClass/MyData_Class.dart';
import 'package:nikah_blessing/Make_Profile/Profile_Questionnaire_main.dart';
import 'package:nikah_blessing/NotificationService.dart';
import 'package:nikah_blessing/User_Home_Pages/AccountModule/Account_Setting.dart';
import 'package:nikah_blessing/User_Home_Pages/savedProposalModule/SavedProposals.dart';
import 'package:nikah_blessing/SharedPrefrences/SaveUserDataLocally.dart';
import 'package:nikah_blessing/User_Home_Pages/ProposalModule/proposalMainController.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:stylish_bottom_bar/stylish_bottom_bar.dart';
import '../Email_Authentication/EmailAuth_Main.dart';
import '../FirebaseOperation/OnlineStatusService.dart';
import 'FriendsModule/FriendRequestsPage.dart';

// Custom PageView that disables horizontal scrolling
class NoScrollPageView extends StatelessWidget {
  final PageController controller;
  final List<Widget> children;

  const NoScrollPageView({
    super.key,
    required this.controller,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: controller,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }
}

class UserMain extends StatefulWidget {
  const UserMain({super.key});

  @override
  State<UserMain> createState() => _UserMainState();
}

class _UserMainState extends State<UserMain> {
  final NotificationService notificationService = NotificationService();
  final UserPackage userPackage = UserPackage();
  Map<String, dynamic>? userData;

  Future<void> getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => EmailAuth_Main()),
      );
      return;
    }

    await _initializeData();
    if (!mounted) return;

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!mounted) return;

      final data = docSnapshot.data();
      if (!docSnapshot.exists || data == null) {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const Profile_Questionnaire_main(),
          ),
        );
        return;
      }

      setState(() {
        userData = data;
        MyData_Class.MyMapData = data;
      });

      if (data['VerificationStatus'] == 'Rejected') {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'Unverified Profile',
          text: 'Your profile was rejected. Please update your profile.',
          barrierDismissible: false,
          confirmBtnText: 'Update Profile',
          onConfirmBtnTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const Profile_Questionnaire_main(),
              ),
            );
          },
          onCancelBtnTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const Profile_Questionnaire_main(),
              ),
            );
          },
        );
      } else if (!data.containsKey('VerificationStatus')) {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const Profile_Questionnaire_main(),
          ),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to load user profile: $error\n$stackTrace');
      if (!mounted) return;
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Unable to load profile',
        text: 'Please check your connection and try again.',
      );
    }
  }

  @override
  void initState() {
    super.initState();

    getUserData();
    _initializeNotifications();

    // Set status bar to transparent
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Make status bar transparent
      statusBarIconBrightness: Brightness.dark, // Change icons color to dark
    ));

    OnlineStatusService().setOnlineStatus();
// Call the async function to initialize data
  }

  Future<void> _initializeNotifications() async {
    try {
      await notificationService.initialize();
      await notificationService.getToken();
    } catch (error, stackTrace) {
      debugPrint('Failed to initialize notifications: $error\n$stackTrace');
    }
  }

  // Initialize user data
  Future<void> _initializeData() async {
    final saveUserDataLocally = SaveUserDataLocally();
    try {
      final data = await saveUserDataLocally.retrieveData() ??
          await saveUserDataLocally.getUserDataFromFirestoreAndSave();
      if (data != null) {
        MyData_Class.MyMapData = data;
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to initialize cached user data: $error\n$stackTrace');
    }
  }

  int selected = 0;
  final controller = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true, // To make floating action button notch transparent

      bottomNavigationBar: StylishBottomBar(
        option: AnimatedBarOptions(
          barAnimation: BarAnimation.blink,
          iconStyle: IconStyle.animated,
        ),
        hasNotch: true,
        items: [
          BottomBarItem(
            icon: Image.asset('assets/Profile_View_Icons/rings.png',
                width: 25, height: 25),
            selectedIcon: const Icon(Icons.house_rounded),
            selectedColor: Color(0xFFCE9334),
            unSelectedColor: Colors.grey,
            title: const Text('Explore'),
            badgePadding: const EdgeInsets.only(left: 4, right: 4),
          ),
          BottomBarItem(
            icon: Image.asset('assets/Profile_View_Icons/requests.png',
                width: 25, height: 25),
            selectedIcon: const Icon(Icons.star_rounded),
            selectedColor: Colors.green,
            title: const Text('Requests'),
          ),
          BottomBarItem(
            icon: Image.asset('assets/Profile_View_Icons/saved.png',
                width: 25, height: 25),
            selectedIcon: const Icon(Icons.style),
            selectedColor: Colors.deepOrangeAccent,
            title: const Text('Saved'),
          ),
          BottomBarItem(
            icon: Image.asset('assets/Profile_View_Icons/chat.png',
                width: 25, height: 25),
            selectedIcon: const Icon(Icons.chat),
            selectedColor: Colors.deepPurple,
            title: const Text('Chats'),
          ),
          BottomBarItem(
            icon: Image.asset('assets/Profile_View_Icons/user.png',
                width: 25, height: 25),
            selectedIcon: const Icon(Icons.person),
            selectedColor: Colors.deepPurple,
            title: const Text('Profile'),
          ),
        ],
        currentIndex: selected,
        notchStyle: NotchStyle.circle,
        onTap: (index) {
          if (index == selected) return;
          controller.jumpToPage(index);
          setState(() {
            selected = index;
          });
        },
      ),

      body: SafeArea(
        child: NoScrollPageView(
          controller: controller,
          children: [
            const ProposalMainController(),
            const FriendRequestsPage(),
            const SavedProposals(),
            const User_Chat_Page(),
            Account_Setting(),
          ],
        ),
      ),
    );
  }
}
