import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../homestart_screens/home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final storage = FlutterSecureStorage();
  Map<String, dynamic>? userInfo;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    String? userInfoString = await storage.read(key: 'userInfo');
    if (userInfoString != null) {
      setState(() {
        userInfo = json.decode(userInfoString);
      });
      Timer(Duration(seconds: 4), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '로그인',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: userInfo == null
              ? Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 90),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: Colors.black,
                        ),
                        children: <TextSpan>[
                          TextSpan(text: 'Welcome to '),
                          TextSpan(
                            text: 'MOOD',
                            style: TextStyle(color: Color(0xFF0126FA)),
                          ),
                          TextSpan(text: '!'),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    Center(
                      child: Text(
                        '${userInfo!['user_name']}님 어서오세요',
                        style: TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 100),
                    Icon(
                      Icons.directions_car,
                      size: 150,
                      color: Color(0xFF423EFF),
                    ),
                    SizedBox(height: 100),
                    Center(
                      child: Text(
                        '이름 : ${userInfo!['user_name']}',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 10),
                    Center(
                      child: Text(
                        '차종 : ${userInfo!['car_type']}',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
