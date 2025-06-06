import 'package:flutter/material.dart';
import 'dart:async';

class WelcomeScreen extends StatefulWidget {
  final Map<String, dynamic> userInfo;

  WelcomeScreen({required this.userInfo});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {

  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 4), () {
      Navigator.of(context).pushReplacementNamed('/home', arguments: widget.userInfo);
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
              fontSize: 23,
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
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    color: Colors.black,
                  ),
                  children: <TextSpan>[
                    TextSpan(text: 'Welcome to '),
                    TextSpan(
                      text: 'MOOD',
                      style: TextStyle(color: Color(0xFF8C88D5)),
                    ),
                    TextSpan(text: '!'),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: Text(
                  '${widget.userInfo['user_name']}님 어서오세요',
                  style: TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 80),
              Image.asset(
                'assets/mooding/mooding_main.png',
                width: 190,
                height: 190,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 80),
              Center(
                child: Text(
                  '이름 : ${widget.userInfo['user_name']}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 10),
              Center(
                child: Text(
                  '차종 : ${widget.userInfo['car_type']}',
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
