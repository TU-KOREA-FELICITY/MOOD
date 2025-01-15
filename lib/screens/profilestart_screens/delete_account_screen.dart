import 'package:flutter/material.dart';
import 'package:mood/screens/start_screens/login_screen.dart';

class DeleteAccountScreen extends StatelessWidget {
  final String userName = 'IN SUN';
  final String carModel = 'Mercedes-Benz AMG G63';

  @override
  Widget build(BuildContext context) {
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('차종 : $carModel',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 300),
            Text('회원을 탈퇴 하시겠습니까?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                    // 회원 탈퇴 로직
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                          (route) => false,
                    );
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
