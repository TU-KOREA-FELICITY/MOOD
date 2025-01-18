import 'package:flutter/material.dart';
import 'welcome_screen.dart';
import 'login_failed_screen.dart'; // Import the LoginFailedScreen
import 'package:http/http.dart' as http;

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _status = '준비 중...';

  @override
  void initState() {
    super.initState();
    print('initState called'); // initState 호출 확인
    _login();
  }

  void _login() async {
    print('Login method started'); // _login 메서드 호출 확인
    setState(() {
      _status = '얼굴 인증 중...';
    });
    try {
      final response = await http.post(Uri.parse('http://10.0.2.2:3000/login'));
      print('HTTP Response: ${response.statusCode}'); // HTTP 응답 상태 코드 확인
      print('Response Body: ${response.body}'); // 응답 본문 출력

      if (response.statusCode == 200) {
        final result = response.body; // 서버에서 반환된 응답 처리
        if (result.contains('authenticated: false') || result.contains('There are no faces in the image')) {
          Navigator.pushReplacementNamed(context, '/login_failed');
        } else {
          _checkAuthStatus();
        }
      } else {
        Navigator.pushReplacementNamed(context, '/login_failed');
      }
    } catch (e) {
      print('Error: $e'); // 에러 출력
      setState(() {
        _status = '인증 시작 오류: $e';
      });
      Navigator.pushReplacementNamed(context, '/login_failed');
    }
  }

  void _checkAuthStatus() {
    // 인증 성공 시 WelcomeScreen으로 이동
    Navigator.pushReplacementNamed(context, '/welcome');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: EdgeInsets.only(left: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.login),
              SizedBox(width: 8),
              Text(
                '로그인',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '운전자 인식중',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 10),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF014FFA)),
                    strokeWidth: 3.5,
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WelcomeScreen()),
                );
              },
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFF014FFA), width: 3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text('카메라 화면 영역'),
                  ),
                ),
              ),
            ),
            SizedBox(height: 100),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 30.0, bottom: 200.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/signup');
                  },
                  child: Text(
                    '회원가입',
                    style: TextStyle(
                      fontSize: 18.0,
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