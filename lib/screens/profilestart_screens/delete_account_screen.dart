import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mood/screens/start_screens/login_screen.dart';

class DeleteAccountScreen extends StatelessWidget {
  final Map<String, dynamic> userInfo;

  DeleteAccountScreen({required this.userInfo});

  Future<void> deleteAccount(BuildContext context) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.60.219:3000/delete_complete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_aws_id': userInfo['user_aws_id']}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('회원 탈퇴가 완료되었습니다.')),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'] ?? '회원 탈퇴에 실패했습니다.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('서버 오류가 발생했습니다. 다시 시도해주세요.')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('네트워크 오류가 발생했습니다. 다시 시도해주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          '회원탈퇴',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 23,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 150),
            Icon(Icons.delete_outline, size: 100),
            SizedBox(height: 20),
            Text('얼굴 ID : ${userInfo['user_aws_id']}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('이름 : ${userInfo['user_name']}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('차종 : ${userInfo['car_type']}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 200),
            Text('회원을 탈퇴 하시겠습니까?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: 110,
                  height: 50,
                  child: OutlinedButton(
                    child: Text(
                      'NO',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey, width: 3),
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                ),
                ),
                SizedBox(
                  width: 110,
                  height: 50,
                  child: ElevatedButton(
                    child: Text(
                      'YES',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  onPressed: () {
                    deleteAccount(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0126FA),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
