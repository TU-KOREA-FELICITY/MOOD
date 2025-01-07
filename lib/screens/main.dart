import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'login_screen.dart';
import 'welcome_screen.dart';
import 'login_failed_screen.dart';
import 'signup_screen.dart';
import 'music_preference_screen.dart';
import 'main_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MOOD Driver App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/welcome': (context) => WelcomeScreen(),
        '/login_failed': (context) => LoginFailedScreen(),
        '/signup': (context) => SignupScreen(),
        '/music_preference': (context) => MusicPreferenceScreen(),
        '/main': (context) => MainScreen(),
      },
    );
  }
}
