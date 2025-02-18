import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mood/screens/start_screens/login_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class DeleteAccountScreen extends StatelessWidget {
  final storage = FlutterSecureStorage();

  Future<void> _deleteAccount(BuildContext context) async {
    final token = await storage.read(key: 'token');
    final userInfoString = await storage.read(key: 'userInfo');
    if (userInfoString == null) {
      print('Failed to read user info from storage');
      return;
    }
    final userInfo = json.decode(userInfoString);
    final url = Uri.parse('http://10.0.2.2:3000/delete_account');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'user_id': userInfo['user_id']}),
      );

      if (response.statusCode == 200) {
        await storage.deleteAll();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      } else {
        print('Failed to delete account: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting account: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: storage
          .read(key: 'userInfo')
          .then((value) => value != null ? json.decode(value) : null),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final String userName = snapshot.data!['user_name'];
        final String carModel = snapshot.data!['car_type'];

        return Scaffold(
          appBar: AppBar(
            centerTitle: false,
            title: Text(
              '회원탈퇴',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
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
                Text('이름 : $userName',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text('차종 : $carModel',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 300),
                Text('회원을 탈퇴 하시겠습니까?',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      width: 110,
                      height: 50,
                      child: ElevatedButton(
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
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
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
                        onPressed: () => _deleteAccount(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF0126FA),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
