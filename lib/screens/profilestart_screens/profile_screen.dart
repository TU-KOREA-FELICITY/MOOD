import 'package:flutter/material.dart';
import 'package:mood/screens/profilestart_screens/edit_profile_screen.dart';
import 'package:mood/screens/profilestart_screens/emotion_record_screen.dart';
import 'package:mood/screens/profilestart_screens/warning_record_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'delete_account_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final storage = FlutterSecureStorage();
  Map<String, dynamic>? userInfo;
  Map<String, dynamic>? _profileData;
  String _status = '프로필 데이터를 불러오는 중...';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    String? userInfoString = await storage.read(key: 'userInfo');
    if (userInfoString != null) {
      setState(() {
        userInfo = json.decode(userInfoString);
      });
      _fetchProfileData();
    }
  }

  Future<void> _fetchProfileData() async {
    final token = await storage.read(key: 'token');
    final url = Uri.parse('http://10.0.2.2:3000/profile');
    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
      });
      if (response.statusCode == 200) {
        setState(() {
          _profileData = json.decode(response.body);
          _status = '프로필 데이터 불러오기 완료';
        });
      } else {
        setState(() {
          _status = '프로필 데이터 불러오기 실패: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _status = '프로필 데이터 불러오기 중 오류 발생: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: userInfo == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 10),
                  Icon(Icons.sentiment_satisfied_alt,
                      size: 90, color: Colors.black),
                  SizedBox(height: 5),
                  Text("이름 : ${userInfo!['user_name']}",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                  SizedBox(height: 10),
                  Divider(color: Colors.grey),
                  ListTile(
                    title: Text('모니터링',
                        style: TextStyle(
                            fontSize: 20,
                            color: Colors.black,
                            fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 10),
                        TextButton(
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  color: Colors.black, size: 20),
                              SizedBox(width: 10),
                              Text('날짜별 감정기록',
                                  style: TextStyle(
                                      fontSize: 17, color: Colors.black)),
                            ],
                          ),
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        EmotionRecordScreen()));
                          },
                        ),
                        TextButton(
                          child: Row(
                            children: [
                              Icon(Icons.warning,
                                  color: Colors.black, size: 20),
                              SizedBox(width: 10),
                              Text('주행 중 경고기록',
                                  style: TextStyle(
                                      fontSize: 17, color: Colors.black)),
                            ],
                          ),
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        WarningRecordScreen()));
                          },
                        ),
                      ],
                    ),
                  ),
                  Divider(color: Colors.grey),
                  ListTile(
                    title: Text('설정',
                        style: TextStyle(
                            fontSize: 20,
                            color: Colors.black,
                            fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 10),
                        TextButton(
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Colors.black, size: 20),
                              SizedBox(width: 10),
                              Text('운전자 정보 수정',
                                  style: TextStyle(
                                      fontSize: 17, color: Colors.black)),
                            ],
                          ),
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => EditProfileScreen()));
                          },
                        ),
                        TextButton(
                          child: Row(
                            children: [
                              Icon(Icons.logout, color: Colors.black, size: 20),
                              SizedBox(width: 10),
                              Text('로그아웃',
                                  style: TextStyle(
                                      fontSize: 17, color: Colors.black)),
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('로그아웃',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
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
                                      onPressed: () async {
                                        await storage.deleteAll();
                                        Navigator.of(context)
                                            .pushNamedAndRemoveUntil(
                                                '/login',
                                                (Route<dynamic> route) =>
                                                    false);
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
                              Text('회원탈퇴',
                                  style: TextStyle(
                                      fontSize: 17, color: Colors.black)),
                            ],
                          ),
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        DeleteAccountScreen()));
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
                          onPressed: () {},
                          child: Row(
                            children: [
                              Icon(Icons.announcement,
                                  color: Colors.black, size: 20),
                              SizedBox(width: 10),
                              Text('공지사항',
                                  style: TextStyle(
                                      fontSize: 17, color: Colors.black)),
                            ],
                          ),
                        ),
                        TextButton(
                          child: Row(
                            children: [
                              Icon(Icons.question_answer,
                                  color: Colors.black, size: 20),
                              SizedBox(width: 10),
                              Text('1:1 문의',
                                  style: TextStyle(
                                      fontSize: 17, color: Colors.black)),
                            ],
                          ),
                          onPressed: () {
                            // 문의 페이지로 이동
                          },
                        ),
                        TextButton(
                          child: Row(
                            children: [
                              Icon(Icons.info, color: Colors.black, size: 20),
                              SizedBox(width: 10),
                              Text('버전정보',
                                  style: TextStyle(
                                      fontSize: 17, color: Colors.black)),
                              Spacer(),
                              Text('1.0',
                                  style: TextStyle(
                                      fontSize: 17, color: Colors.grey)),
                            ],
                          ),
                          onPressed: () {
                            // 버전 정보 페이지로 이동
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
