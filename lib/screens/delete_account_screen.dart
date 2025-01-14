import 'package:flutter/material.dart';
import 'package:mood/screens/login_screen.dart';

class DeleteAccountScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('회원탈퇴'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sentiment_dissatisfied, size: 100),
            SizedBox(height: 20),
            Text('사용자 이름', style: TextStyle(fontSize: 24)),
            Text('사용자 차종'),
            SizedBox(height: 40),
            ElevatedButton(
              child: Text('회원 탈퇴하기'),
              onPressed: () {
                // 회원 탈퇴 로직
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                      (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
