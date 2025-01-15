import 'package:flutter/material.dart';
import 'package:mood/screens/edit_profile_screen.dart';
import 'package:mood/screens/emotion_record_screen.dart';
import 'package:mood/screens/warning_record_screen.dart';
import 'delete_account_screen.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('프로필'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/profile_image.png'),
            ),
            SizedBox(height: 10),
            Text('사용자 이름', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('사용자 차종'),
            Divider(color: Colors.grey),
            ListTile(
              title: Text('모니터링'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton(
                    child: Text('날짜별 감정기록'),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(
                          builder: (context) => EmotionRecordScreen()
                      ));
                    },
                  ),
                  TextButton(
                    child: Text('주행 중 경고기록'),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(
                          builder: (context) => WarningRecordScreen()
                      ));
                    },
                  ),
                ],
              ),
            ),
            Divider(color: Colors.grey),
            ListTile(
              title: Text('설정'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton(
                    child: Text('운전자 정보 수정'),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(
                          builder: (context) => EditProfileScreen()
                      ));
                    },
                  ),
                  TextButton(
                    child: Text('로그아웃'),
                    onPressed: () {
                      // 로그아웃 로직
                    },
                  ),
                  TextButton(
                    child: Text('회원탈퇴'),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(
                          builder: (context) => DeleteAccountScreen()
                      ));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
