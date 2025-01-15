import 'package:flutter/material.dart';

class LoginFailedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '운전자 인식 실패',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              '정면을 응시해주세요',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: Text('다시 시도하기'),
            ),
            SizedBox(height: 10),
        Spacer(),
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 30.0),
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/signup');
                },
              child: Text(
                '신규 운전자 등록하기',
                style: TextStyle(
                  fontSize: 18,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ),
          ],
        ),
      ),
    );
  }
}
