import 'package:flutter/material.dart';
import 'dart:async';

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final String userName = 'IN SUN'; // 이 부분은 실제 인식된 사용자 이름으로 대체
  final String carModel = 'Mercedes-Benz AMG G63'; // 이 부분은 실제 등록된 차종으로 대체

  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 4), () {
      Navigator.of(context).pushReplacementNamed('/home');
    });
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
          child: Column(
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
                  '$userName님 어서오세요',
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
                  '이름 : $userName',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 10),
              Center(
                child: Text(
                  '차종 : $carModel',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
