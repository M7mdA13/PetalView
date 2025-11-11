import 'package:flutter/material.dart';
import 'package:petalview/home/tabs/account.dart';
import 'package:petalview/home/tabs/community.dart';
import 'auth/introduction.dart';
import 'auth/login.dart';
import 'auth/signup.dart';
import 'home/home_screen.dart';
import 'home/tabs/explor.dart';
import 'home/tabs/map.dart';
import 'home/tabs/predection.dart';
import 'onbording/onbording.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 1. Show a loading spinner while we check
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // 2. If snapshot HAS DATA, the user is logged in
          if (snapshot.hasData) {
            // Go straight to the home screen
            return HomeScreen();
          }

          // 3. If snapshot has NO data, the user is logged out
          // Show the onboarding screen
          return OnbordingScreen();
        },
      ),
      routes: {
        OnbordingScreen.routeName: (context) => OnbordingScreen(),
        Introduction.routeName: (context) => Introduction(),
        Signup.routeName: (context) => Signup(),
        Login.routeName: (context) => Login(),
        HomeScreen.routeName: (context) => HomeScreen(),

        AccountScreen.routeName: (context) => AccountScreen(),
        CommunityScreen.routeName: (context) => CommunityScreen(),
        ExploreScreen.routeName: (context) => ExploreScreen(),
        PredectionScreen.routeName: (context) => PredectionScreen(),
        MapScreen.routeName: (context) => MapScreen(),
      },
    );
  }
}
