import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignUpCompletionScreen extends StatelessWidget {
  final Map<String, Object?> authData;
  final Map<String, dynamic> userInfo;

  const SignUpCompletionScreen(
      {Key? key, required this.authData, required this.userInfo})
      : super(key: key);

  Future _completeSignUp(BuildContext context) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/register_complete'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_aws_id': userInfo['userId'],
          'username': userInfo['name'],
          'car_type': userInfo['carModel'],
          'fav_genre': userInfo['selectedGenres']?.join(', ') ?? '',
          'fav_artist': userInfo['selectedArtists']?.join(', ') ?? '',
        }),
      );

      if (response.statusCode == 200) {
        final loginResult = await _loginComplete(userInfo['userId']);
        if (loginResult['success']) {
          Navigator.pushNamed(
            context,
            '/home',
            arguments: loginResult['user'],
          );
        } else {
          throw Exception(loginResult['message']);
        }
      } else {
        throw Exception('Failed to complete sign up: \n${response.statusCode}');
      }
    } catch (e) {
      print('Error: \n$e');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('오류'),
          content: Text('예기치 못한 오류가 발생했습니다. 다시 시도해 주세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('확인'),
            ),
          ],
        ),
      );
    }
  }

  Future<Map<String, dynamic>> _loginComplete(String userAwsId) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/login_complete'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_aws_id': userAwsId}),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success']) {
          return {
            'success': true,
            'user': result['user'],
          };
        } else {
          return {
            'success': false,
            'message': result['message'] ?? '알 수 없는 오류가 발생했습니다.',
          };
        }
      } else {
        return {
          'success': false,
          'message': '서버 오류: \n${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '로그인 완료 중 오류 발생: \n$e',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 150),
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
              const SizedBox(height: 50),
              const Icon(
                Icons.verified,
                color: Color(0xFF0126FA),
                size: 100,
              ),
              const SizedBox(height: 50),
              const Text(
                '회원가입 완료',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              Text(
                '${userInfo['name']}님의 회원가입이\n성공적으로 완료되었습니다.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              SizedBox(height: 230),
              Container(
                width: MediaQuery.of(context).size.width * 0.8,
                child: ElevatedButton(
                  onPressed: () => _completeSignUp(context),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Color(0xFF0126FA),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    '시작하기',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
