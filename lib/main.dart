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
      title: '얼굴 등록 및 인증',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _status = '';

  void _register() async {
    final TextEditingController controller = TextEditingController();
    final username = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('사용자 이름 입력'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: "사용자 이름을 입력하세요"),
        ),
        actions: [
          TextButton(
            child: Text('확인'),
            onPressed: () => Navigator.of(context).pop(controller.text),
          ),
        ],
      ),
    );

    if (username != null && username.isNotEmpty) {
      setState(() {
        _status = '얼굴 등록 중...';
      });
      try {
        final response = await http.post(
          Uri.parse('http://10.0.2.2:3000/register'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'username': username}),
        );
        _checkRegistrationStatus();
      } catch (e) {
        setState(() {
          _status = '등록 시작 오류: $e';
        });
      }
    }
  }

  void _login() async {
    setState(() {
      _status = '얼굴 인증 중...';
    });
    try {
      await http.post(Uri.parse('http://10.0.2.2:3000/login'));
      _checkAuthStatus();
    } catch (e) {
      setState(() {
        _status = '인증 시작 오류: $e';
      });
    }
  }

  void _checkRegistrationStatus() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:3000/check_registration'));
      final result = json.decode(response.body);
      if (result['registered'] == true) {
        setState(() {
          _status = '등록 성공! 사용자 ID: ${result['user_id']}';
        });
      } else {
        Future.delayed(Duration(seconds: 2), _checkRegistrationStatus);
      }
    } catch (e) {
      setState(() {
        _status = '등록 상태 확인 오류: $e';
      });
    }
  }

  void _checkAuthStatus() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:3000/check_auth'));
      final result = json.decode(response.body);
      if (result['authenticated'] == true) {
        setState(() {
          _status = '인증 성공! 사용자 ID: ${result['user_id']}';
        });
      } else {
        Future.delayed(Duration(seconds: 2), _checkAuthStatus);
      }
    } catch (e) {
      setState(() {
        _status = '인증 상태 확인 오류: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('얼굴 등록 및 인증'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _register,
              child: Text('회원가입'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: Text('로그인'),
            ),
            SizedBox(height: 20),
            Text(_status),
          ],
        ),
      ),
    );
  }
}
