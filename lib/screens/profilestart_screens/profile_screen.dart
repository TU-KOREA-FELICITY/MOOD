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
    final String carType = "${userInfo['car_type'] ?? null}";

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Text(
              '프로필',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        titleSpacing: 16,
      ),
      body: SingleChildScrollView(
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
        // 1. 내 프로필/로고/유저정보 섹션
        Container(
        decoration: BoxDecoration(
        color: Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 로고 이미지
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/mooding/mooding_main.png', // 실제 로고 이미지 경로
              width: 70,
              height: 70,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 20),
          // 유저 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('내 프로필',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
                SizedBox(height: 8),
                Text(userName,
                    style: TextStyle(
                        fontSize: 16, color: Colors.grey[800])),
                SizedBox(height: 2),
                Text(carType,
                    style: TextStyle(
                        fontSize: 15, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    ),
    SizedBox(height: 28),
              // 2. 모니터링 섹션
              Text('모니터링',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
              SizedBox(height: 8),
              ListTile(
                leading: Icon(Icons.calendar_today, color: Color(0xffE989B3)),
                title: Text('날짜별 감정기록',
                    style: TextStyle(fontSize: 16, color: Colors.black)),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => EmotionRecordScreen(userInfo: userInfo)));
                },
              ),
              ListTile(
                leading: Icon(Icons.warning, color: Color(0xffEE9666)),
                title: Text('주행 중 경고기록',
                    style: TextStyle(fontSize: 16, color: Colors.black)),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => WarningRecordScreen(userInfo: userInfo)));
                },
              ),
              Divider(height: 32, color: Colors.grey[300]),

              // 3. 설정 섹션
              Text('설정',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
              SizedBox(height: 8),
              ListTile(
                leading: Icon(Icons.edit, color: Color(0xffF5B949)),
                title: Text('운전자 정보 수정',
                    style: TextStyle(fontSize: 16, color: Colors.black)),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => EditProfileScreen(userInfo: userInfo)));
                },
              ),
              ListTile(
                leading: Icon(Icons.logout, color: Color(0xff70B9AE)),
                title: Text('로그아웃',
                    style: TextStyle(fontSize: 16, color: Colors.black)),
                onTap: () {
                  // 로그아웃 다이얼로그
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
              ListTile(
                leading: Icon(Icons.delete, color: Color(0xff76BD84)),
                title: Text('회원탈퇴',
                    style: TextStyle(fontSize: 16, color: Colors.black)),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => DeleteAccountScreen(userInfo: userInfo)));
                },
              ),
              Divider(height: 32, color: Colors.grey[300]),

              // 4. 더보기 섹션
              Text('더보기',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
              SizedBox(height: 8),
              ListTile(
                leading: Icon(Icons.announcement, color: Color(0xff6A71F6)),
                title: Text('공지사항',
                    style: TextStyle(fontSize: 16, color: Colors.black)),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(Icons.question_answer, color: Color(0xffC293F7)),
                title: Text('1:1 문의',
                    style: TextStyle(fontSize: 16, color: Colors.black)),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(Icons.info, color: Color(0xff6EA2E8)),
                title: Row(
                  children: [
                    Text('버전정보',
                        style: TextStyle(fontSize: 16, color: Colors.black)),
                    Spacer(),
                    Text('1.0', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  ],
                ),
                onTap: () {},
              ),
            ],
        ),
      ),
    ),
    );
  }
}