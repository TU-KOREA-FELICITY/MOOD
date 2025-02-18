import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SignUpCompletionScreen extends StatelessWidget {
  final Map<String, Object?> authData;
  final Map<String, dynamic> userInfo;

  const SignUpCompletionScreen(
      {Key? key, required this.authData, required this.userInfo})
      : super(key: key);

  Future<void> _completeSignUp(BuildContext context) async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/register_complete'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'user_aws_id': userInfo['userId'],
          'username': userInfo['name'],
          'car_type': userInfo['carModel'],
          'fav_genre': userInfo['selectedGenres']?.join(', ') ?? '',
          'fav_artist': userInfo['selectedArtists']?.join(', ') ?? '',
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);

        if (result['success']) {
          await storage.write(key: 'token', value: result['token']);
          await storage.write(key: 'userInfo', value: json.encode(userInfo));

          Navigator.pushNamed(context, '/home');
        } else {
          _showErrorDialog(
              context, 'Failed to complete sign up. Please try again.');
        }
      } else {
        _showErrorDialog(
            context, 'Failed to complete sign up: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog(
          context, 'An unexpected error occurred. Please try again.');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 120),
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
                Icons.check_circle,
                color: Colors.black,
                size: 100,
              ),
              const SizedBox(height: 20),
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
              SizedBox(height: 300),
              Container(
                width: MediaQuery.of(context).size.width * 0.7,
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
