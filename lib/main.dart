import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '얼굴 인증 및 감정 분석',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AuthPage(),
    );
  }
}

class AuthPage extends StatefulWidget {
  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isAuthenticating = false;
  String _authStatus = '';
  String _emotionResult = '';

  void _startAuthentication() async {
    setState(() {
      _isAuthenticating = true;
      _authStatus = '인증 시작 중...';
    });
    try {
      await http.post(Uri.parse('http://10.0.2.2:3000/start_auth'));
      _checkAuthStatus();
    } catch (e) {
      setState(() {
        _isAuthenticating = false;
        _authStatus = '인증 시작 오류: $e';
      });
    }
  }

  void _checkAuthStatus() async {
    if (!_isAuthenticating) return;
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/check_auth'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 10));
      final result = json.decode(response.body);
      if (result['authenticated'] == true) {
        setState(() {
          _isAuthenticating = false;
          _authStatus = '인증 성공! 사용자 ID: ${result['user_id']}';
        });
      } else {
        Future.delayed(Duration(seconds: 2), _checkAuthStatus);
      }
    } catch (e) {
      setState(() {
        _isAuthenticating = false;
        _authStatus = '인증 상태 확인 오류: $e';
      });
    }
  }

  void _getEmotionResult() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:3000/get_emotions'));
      final result = json.decode(response.body);
      setState(() {
        _emotionResult = result.toString();
      });
    } catch (e) {
      setState(() {
        _emotionResult = '감정 데이터 가져오기 오류: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('얼굴 인증 및 감정 분석'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _isAuthenticating ? null : _startAuthentication,
              child: Text('인증 시작'),
            ),
            SizedBox(height: 20),
            Text(_authStatus),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _getEmotionResult,
              child: Text('감정 결과 가져오기'),
            ),
            SizedBox(height: 20),
            Text('감정 결과: $_emotionResult'),
          ],
        ),
      ),
    );
  }
}
