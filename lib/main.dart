import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nikah_blessing/User_Home_Pages/user_main.dart';
import 'package:nikah_blessing/onBoardingScreens.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class KeyboardGuardObserver extends NavigatorObserver {
  void _close() => FocusManager.instance.primaryFocus?.unfocus();
  void _guard() {
    _close();
    WidgetsBinding.instance.addPostFrameCallback((_) => _close());
    Future.delayed(const Duration(milliseconds: 350), _close);
    Future.delayed(const Duration(milliseconds: 500), _close);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _guard();
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _guard();
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => _guard();
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => _guard();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> isUserLoggedIn() async {
    return FirebaseAuth.instance.currentUser != null;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.dark,
    ));

    return MaterialApp(
      title: 'Nikah Blessing',
      navigatorObservers: [KeyboardGuardObserver()],
      builder: (context, child) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: child,
        );
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: FutureBuilder<bool>(
        future: isUserLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasData && snapshot.data == true) {
            return UserMain();
          } else {
            return onBoardingScreens();
          }
        },
      ),
    );
  }
}