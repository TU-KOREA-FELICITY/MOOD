import 'package:flutter/material.dart';
import 'package:mood/screens/profilestart_screens/edit_profile_screen.dart';
import 'package:mood/screens/profilestart_screens/emotion_record_screen.dart';
import 'package:mood/screens/profilestart_screens/warning_record_screen.dart';
import 'delete_account_screen.dart';

class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic> userInfo;

  ProfileScreen({required this.userInfo});
  Widget _buildInfoChip(String text, BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 15, color: Colors.grey[700]),
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
              indent: 56,
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
      backgroundColor: Color(0xFFF0F0F0),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFFF0F0F0),
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
          ],
        ),
        titleSpacing: 20,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // 수직 패딩 감소
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
                        width: 80,
                        height: 80,
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
                    leading: Icon(Icons.calendar_today, color: Color(0xffE989B3)),
                    title: Text('날짜별 감정기록', style: TextStyle(fontSize: 16, color: Colors.black)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 0),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                          builder: (context) => EmotionRecordScreen(userInfo: userInfo)));
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.warning, color: Color(0xffEE9666)),
                    title: Text('주행 중 경고기록', style: TextStyle(fontSize: 16, color: Colors.black)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 0),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                          builder: (context) => WarningRecordScreen(userInfo: userInfo)));
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
                    title: Text('운전자 정보 수정', style: TextStyle(fontSize: 16, color: Colors.black)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 0),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                          builder: (context) => EditProfileScreen(userInfo: userInfo)));
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.logout, color: Color(0xff70B9AE)),
                    title: Text('로그아웃', style: TextStyle(fontSize: 16, color: Colors.black)),
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
                            content: Text('로그아웃 하시겠습니까?', style: TextStyle(fontSize: 16)),
                            actions: <Widget>[
                              TextButton(
                                child: Text('NO', style: TextStyle(color: Theme.of(context).primaryColor)),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              TextButton(
                                child: Text('YES', style: TextStyle(color: Theme.of(context).primaryColor)),
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
                    title: Text('회원탈퇴', style: TextStyle(fontSize: 16, color: Colors.black)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 0),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                          builder: (context) => DeleteAccountScreen(userInfo: userInfo)));
                    },
                  ),
                ],
              ),

              _buildSectionCard(
                context: context,
                title: '더보기',
                children: [
                  ListTile(
                    leading: Icon(Icons.announcement, color: Color(0xff6A71F6)),
                    title: Text('공지사항', style: TextStyle(fontSize: 16, color: Colors.black)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 0),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: Icon(Icons.question_answer, color: Color(0xffC293F7)),
                    title: Text('1:1 문의', style: TextStyle(fontSize: 16, color: Colors.black)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 0),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: Icon(Icons.info, color: Color(0xff6EA2E8)),
                    title: Row(
                      children: [
                        Text('버전정보', style: TextStyle(fontSize: 16, color: Colors.black)),
                        Spacer(),
                        Text('1.0', style: TextStyle(fontSize: 16, color: Colors.grey)),
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
    );
  }
}