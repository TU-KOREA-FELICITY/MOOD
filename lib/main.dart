import 'package:flutter/material.dart';
import 'package:mood/screens/start_screens/auth_choice_screen.dart';
import 'screens/bottom_navigation_widget.dart';
import 'screens/start_screens/face_recognition_screen.dart';
import 'screens/start_screens/splash_screen.dart';
import 'screens/start_screens/login_screen.dart';
import 'screens/start_screens/spotify_login_screen.dart';
import 'screens/start_screens/welcome_screen.dart';
import 'screens/start_screens/signup_screen.dart';
import 'screens/start_screens/music_preference_screen.dart';
import 'screens/profilestart_screens/profile_screen.dart';

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
          titleTextStyle: TextStyle(
              fontFamily: "Pretendard", color: Colors.black, fontSize: 30),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        // '/': (context) => BottomNavigationWidget(),
        '/auth_choice': (context) => AuthChoiceScreen(),
        '/login': (context) => LoginScreen(),
        '/welcome': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
          as Map<String, dynamic>?;
          return WelcomeScreen(userInfo: args ?? {});
        },
        '/signup': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as String?;
          return SignupScreen(userId: args ?? '');
        },
        '/face_recognition': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as String?;
          return FaceRecognitionScreen(userId: args ?? '');
        },
        '/music_preference': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
          as Map<String, dynamic>?;
          return MusicPreferenceScreen(userInfo: args ?? {});
        },
        '/spotify_login': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
          as Map<String, dynamic>?;
          return SpotifyLoginScreen(userInfo: args ?? {});
        },
        '/home': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
          as Map<String, dynamic>?;
          return BottomNavigationWidget(userInfo: args ?? {});
        },
        '/profile': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
          as Map<String, dynamic>?;
          return ProfileScreen(userInfo: args ?? {});
        },
      },
    );
  }
}