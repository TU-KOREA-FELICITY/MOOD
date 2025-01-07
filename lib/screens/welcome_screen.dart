import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  final String userName = 'John Doe'; // 이 부분은 실제 인식된 사용자 이름으로 대체
  final String carModel = 'Tesla Model 3'; // 이 부분은 실제 등록된 차종으로 대체

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Welcome!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            '$userName님 어서오세요',
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 20),
          Text('이름: $userName'),
          Text('차종: $carModel'),
          Expanded(child: SizedBox()),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/signup');
                },
                child: Text(
                  '회원가입',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
