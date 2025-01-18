import 'package:flutter/material.dart';
import 'package:jsg/screens/warning_record_screen.dart';
import 'delete_account_screen.dart';
import 'edit_profile_screen.dart';
import 'emotion_record_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String userName = "NAME : IN SUN";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 10),
            Icon(Icons.sentiment_satisfied_alt, size: 90, color: Colors.black),
            SizedBox(height: 5),
            Text(userName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
            SizedBox(height: 10),
            Divider(color: Colors.grey),
            ListTile(
              title: Text('모니터링', style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10),
                  TextButton(
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.black, size: 20),
                        SizedBox(width: 10),
                        Text('날짜별 감정기록', style: TextStyle(fontSize: 17, color: Colors.black)),
                      ],
                    ),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(
                          builder: (context) => EmotionRecordScreen()
                      ));
                    },
                  ),
                  TextButton(
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.black, size: 20),
                        SizedBox(width: 10),
                        Text('주행 중 경고기록', style: TextStyle(fontSize: 17, color: Colors.black)),
                      ],
                    ),
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
              title: Text('설정', style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10),
                  TextButton(
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.black, size: 20),
                        SizedBox(width: 10),
                        Text('운전자 정보 수정', style: TextStyle(fontSize: 17, color: Colors.black)),
                      ],
                    ),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(
                          builder: (context) => EditProfileScreen()
                      ));
                    },
                  ),
                  TextButton(
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.black, size: 20),
                        SizedBox(width: 10),
                        Text('로그아웃', style: TextStyle(fontSize: 17, color: Colors.black)),
                      ],
                    ),
                    onPressed: () {
                      // 로그아웃 로직
                    },
                  ),
                  TextButton(
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.black, size: 20),
                        SizedBox(width: 10),
                        Text('회원탈퇴', style: TextStyle(fontSize: 17, color: Colors.black)),
                      ],
                    ),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(
                          builder: (context) => DeleteAccountScreen()
                      ));
                    },
                  ),
                ],
              ),
            ),
            Divider(color: Colors.grey),
            ListTile(
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10),
                  TextButton(
                    child: Row(
                      children: [
                        Icon(Icons.announcement, color: Colors.black, size: 20),
                        SizedBox(width: 10),
                        Text('공지사항', style: TextStyle(fontSize: 17, color: Colors.black)),
                      ],
                    ),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(
                          builder: (context) => EditProfileScreen()
                      ));
                    },
                  ),
                  TextButton(
                    child: Row(
                      children: [
                        Icon(Icons.question_answer, color: Colors.black, size: 20),
                        SizedBox(width: 10),
                        Text('1:1 문의', style: TextStyle(fontSize: 17, color: Colors.black)),
                      ],
                    ),
                    onPressed: () {
                      // 문의 로직
                    },
                  ),
                  TextButton(
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.black, size: 20),
                        SizedBox(width: 10),
                        Text('버전정보', style: TextStyle(fontSize: 17, color: Colors.black)),
                      ],
                    ),
                    onPressed: () {
                      // 버전 정보 로직
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
