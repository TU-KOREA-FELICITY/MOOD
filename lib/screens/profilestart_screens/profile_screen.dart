import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mood/screens/profilestart_screens/edit_profile_screen.dart';
import 'package:mood/screens/profilestart_screens/emotion_record_screen.dart';
import 'package:mood/screens/profilestart_screens/warning_record_screen.dart';
import 'delete_account_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userInfo;

  ProfileScreen({required this.userInfo});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Map<String, dynamic> userInfo;

  @override
  void initState() {
    super.initState();
    userInfo = Map<String, dynamic>.from(widget.userInfo);
  }

  Future<Map<String, dynamic>> _getUserInfo(String userAwsId) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.189.219:3000/login_complete'),
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

  Future<void> _refreshUserInfo() async {
    final userAwsId = userInfo['user_aws_id'];
    if (userAwsId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('user_aws_id 정보가 없습니다.')),
      );
      return;
    }

    final result = await _getUserInfo(userAwsId);

    if (result['success'] == true && result['user'] != null) {
      setState(() {
        userInfo = Map<String, dynamic>.from(result['user']);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('운전자 정보가 새로고침되었습니다.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? '정보 갱신에 실패했습니다.')),
      );
    }
  }

  Widget _buildInfoChip(String text, BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: children.length,
            itemBuilder: (context, index) => children[index],
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey[300],
              indent: 46,
              endIndent: 16,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String userName = "${userInfo['user_name'] ?? '사용자 이름'}";
    final String carType = "${userInfo['car_type'] ?? '차량 정보'}";

    return Scaffold(
      backgroundColor: Color(0xFFF6F6F6),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFFF6F6F6),
        elevation: 0,
        title: Row(
          children: [
            Text(
              '프로필',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Spacer(),
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.black),
              onPressed: _refreshUserInfo,
              tooltip: '운전자 정보 새로고침',
            ),
          ],
        ),
        titleSpacing: 20,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshUserInfo,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '내 프로필',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 12),
                            _buildInfoChip(userName, context),
                            SizedBox(height: 8),
                            _buildInfoChip(carType, context),
                          ],
                        ),
                      ),
                      SizedBox(width: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/mooding/mooding_main.png',
                          width: 75,
                          height: 75,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                _buildSectionCard(
                  context: context,
                  title: '모니터링',
                  children: [
                    ListTile(
                      leading:
                          Icon(Icons.calendar_today, color: Color(0xffE989B3)),
                      title: Text('날짜별 감정기록',
                          style: TextStyle(fontSize: 16, color: Colors.black)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 0),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    EmotionRecordScreen(userInfo: userInfo)));
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.warning, color: Color(0xffEE9666)),
                      title: Text('주행 중 경고기록',
                          style: TextStyle(fontSize: 16, color: Colors.black)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 0),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    WarningRecordScreen(userInfo: userInfo)));
                      },
                    ),
                  ],
                ),
                _buildSectionCard(
                  context: context,
                  title: '설정',
                  children: [
                    ListTile(
                      leading: Icon(Icons.edit, color: Color(0xffF5B949)),
                      title: Text('운전자 정보 수정',
                          style: TextStyle(fontSize: 16, color: Colors.black)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 0),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    EditProfileScreen(userInfo: userInfo)));
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.logout, color: Color(0xff70B9AE)),
                      title: Text('로그아웃',
                          style: TextStyle(fontSize: 16, color: Colors.black)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 0),
                      onTap: () {
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
                                  child: Text('NO',
                                      style: TextStyle(
                                          color:
                                              Theme.of(context).primaryColor)),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                TextButton(
                                  child: Text('YES',
                                      style: TextStyle(
                                          color:
                                              Theme.of(context).primaryColor)),
                                  onPressed: () {
                                    Navigator.of(context)
                                        .pushNamedAndRemoveUntil('/auth_choice',
                                            (Route<dynamic> route) => false);
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
                      contentPadding: EdgeInsets.symmetric(horizontal: 0),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    DeleteAccountScreen(userInfo: userInfo)));
                      },
                    ),
                  ],
                ),
                _buildSectionCard(
                  context: context,
                  title: '더보기',
                  children: [
                    ListTile(
                      leading:
                          Icon(Icons.announcement, color: Color(0xff6A71F6)),
                      title: Text('공지사항',
                          style: TextStyle(fontSize: 16, color: Colors.black)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 0),
                      onTap: () {},
                    ),
                    ListTile(
                      leading:
                          Icon(Icons.question_answer, color: Color(0xffC293F7)),
                      title: Text('1:1 문의',
                          style: TextStyle(fontSize: 16, color: Colors.black)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 0),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: Icon(Icons.info, color: Color(0xff6EA2E8)),
                      title: Row(
                        children: [
                          Text('버전정보',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.black)),
                          Spacer(),
                          Text('1.0',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey)),
                        ],
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 0),
                      onTap: () {},
                    ),
                  ],
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
