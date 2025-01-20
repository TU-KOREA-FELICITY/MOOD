import 'package:flutter/material.dart';

class SignUpCompletionScreen extends StatelessWidget {
  final Map<String, Object?> authData;
  final String userName = 'IN SUN';

  const SignUpCompletionScreen({Key? key, required this.authData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
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
              const SizedBox(height: 40),
              const Icon(
                Icons.check_circle,
                color: Colors.black,
                size: 100,
              ),
              const SizedBox(height: 20),
              const Text(
                '회원가입 완료',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text(
                '$userName님의 회원가입이\n성공적으로 완료되었습니다.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/home');
                },
                child: const Text('시작하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
