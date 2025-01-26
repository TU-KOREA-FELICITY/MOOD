import 'package:flutter/material.dart';
import 'package:mood/screens/start_screens/face_recognition_screen.dart';
import 'package:mood/screens/start_screens/spotify_login_screen.dart';
import 'searchstart_screens/search_screen.dart';
import 'start_screens/splash_screen.dart';
import 'start_screens/login_screen.dart';
import 'start_screens/welcome_screen.dart';
import 'start_screens/login_failed_screen.dart';
import 'start_screens/signup_screen.dart';
import 'start_screens/music_preference_screen.dart';
import 'homestart_screens/home_screen.dart';
import 'profilestart_screens/profile_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MOOD Driver App',
      theme: ThemeData(
        fontFamily: "Pretendard",
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          color: Colors.white,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(fontFamily: "Pretendard",color: Colors.black, fontSize: 30),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/welcome': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          return WelcomeScreen(userId: args is String ? args : '');
        },
        '/login_failed': (context) => LoginFailedScreen(),
        '/signup': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          return SignupScreen(userId: args is String ? args : '');
        },
        '/face_recognition': (context) => FaceRecognitionScreen(),
        '/music_preference': (context) => MusicPreferenceScreen(),
        '/spotify_login': (context) => SpotifyLoginScreen(),
        '/home': (context) => HomeScreen(),
        '/profile': (context) => ProfileScreen(),
      },
    );
  }
}