import 'package:flutter/material.dart';
import 'package:mood/screens/profilestart_screens/edit_profile_screen.dart';
import 'package:mood/screens/profilestart_screens/emotion_record_screen.dart';
import 'package:mood/screens/profilestart_screens/warning_record_screen.dart';
import 'delete_account_screen.dart';

class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic> userInfo;

  ProfileScreen({required this.userInfo});

  @override
  Widget build(BuildContext context) {
    final String userName = "${userInfo['user_name'] ?? null}";
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
                          builder: (context) => EmotionRecordScreen(userInfo: userInfo)
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
                          builder: (context) => EditProfileScreen(userInfo: userInfo)
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
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.grey),
                            ),
                            backgroundColor: Colors.white,
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('로그아웃', style: TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: Icon(Icons.close),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            ),
                            content: Text('로그아웃 하시겠습니까?',
                                style: TextStyle(fontSize: 16)),
                            actions: <Widget>[
                              TextButton(
                                child: Text('NO'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              TextButton(
                                child: Text('YES'),
                                onPressed: () {
                                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
                                },
                              ),
                            ],
                          );
                        },
                      );
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
                          builder: (context) => DeleteAccountScreen(userInfo: userInfo),
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
                    onPressed: () {  },
                    child: Row(
                      children: [
                        Icon(Icons.announcement, color: Colors.black, size: 20),
                        SizedBox(width: 10),
                        Text('공지사항', style: TextStyle(fontSize: 17, color: Colors.black)),
                      ],
                    ),
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
                      // 臾몄쓽 濡쒖쭅
                    },
                  ),
                  TextButton(
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.black, size: 20),
                        SizedBox(width: 10),
                        Text('버전정보', style: TextStyle(fontSize: 17, color: Colors.black)),
                        Spacer(),
                        Text('1.0', style: TextStyle(fontSize: 17, color: Colors.grey)),
                      ],
                    ),
                    onPressed: () {
                      // 踰꾩쟾 �뺣낫 濡쒖쭅
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