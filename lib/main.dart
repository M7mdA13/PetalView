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

void main() async {
 runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OnbordingScreen(),
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
