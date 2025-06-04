import 'package:flutter/material.dart';
import 'package:mood/screens/profilestart_screens/edit_profile_screen.dart';
import 'package:mood/screens/profilestart_screens/emotion_record_screen.dart';
import 'package:mood/screens/profilestart_screens/warning_record_screen.dart';
import 'delete_account_screen.dart'; // 이 파일이 올바른 위치에 있다고 가정합니다.

class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic> userInfo;

  ProfileScreen({required this.userInfo});

  // 1. 사용자 이름, 차종 정보를 위한 둥근 사각형 위젯 (헬퍼 위젯)
  Widget _buildInfoChip(String text, BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white, // 칩 배경 흰색
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!, width: 1), // 옅은 회색 테두리
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 15, color: Colors.grey[700]),
      ),
    );
  }

  // 2. 각 섹션 카드(모니터링, 설정, 더보기)를 만들기 위한 헬퍼 위젯
  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16), // 카드 사이의 간격
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white, // 카드 배경 흰색
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 8.0), // 제목 패딩 조정
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
            shrinkWrap: true, // Column 내부 ListView에 중요
            physics: NeverScrollableScrollPhysics(), // 이 ListView의 스크롤 비활성화
            itemCount: children.length,
            itemBuilder: (context, index) => children[index],
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey[300],
              indent: 56, // 아이콘 공간 이후부터 구분선 시작 (대략 16+24+16)
              endIndent: 16, // 카드 가장자리 전에 구분선 종료
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String userName = "${userInfo['user_name'] ?? '사용자 이름'}"; // null일 경우 기본값
    final String carType = "${userInfo['car_type'] ?? '차량 정보'}";   // null일 경우 기본값

    return Scaffold(
      backgroundColor: Color(0xFFF0F0F0), // 1. 전체 배경색을 회색으로 변경
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFFF0F0F0), // AppBar 배경도 회색으로 통일
        elevation: 0, // AppBar 그림자 제거
        title: Row(
          children: [
            Text(
              '프로필',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: Colors.black, // 제목 텍스트 색상 확인
              ),
            ),
          ],
        ),
        titleSpacing: 20, // 가로 패딩과 일치시킴 (기존 24에서 조정 가능)
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // 수직 패딩 감소
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 2. 내 프로필 섹션 (수정됨)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white, // 프로필 박스 배경을 흰색으로
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 유저 정보 (텍스트 왼쪽)
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
                          // 3. 사용자 이름과 차종을 위한 둥근 사각형 컨테이너
                          _buildInfoChip(userName, context),
                          SizedBox(height: 8),
                          _buildInfoChip(carType, context),
                        ],
                      ),
                    ),
                    SizedBox(width: 20),
                    // 로고 이미지 (이미지 오른쪽)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/mooding/mooding_main.png', // 실제 로고 이미지 경로
                        width: 80, // 목표 이미지와 유사하게 약간 크게
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24), // 프로필 카드 다음 간격

              // 4 & 5. 모니터링 박스
              _buildSectionCard(
                context: context,
                title: '모니터링',
                children: [
                  ListTile(
                    leading: Icon(Icons.calendar_today, color: Color(0xffE989B3)),
                    title: Text('날짜별 감정기록', style: TextStyle(fontSize: 16, color: Colors.black)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 0), // indent와 정렬되도록 패딩 조정
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

              // 4 & 5. 설정 박스
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
                                  // MaterialApp에 '/login' 라우트가 정의되어 있는지 확인하세요.
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

              // 4 & 5. 더보기 박스
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
              SizedBox(height: 20), // 하단 추가 여백
            ],
          ),
        ),
      ),
    );
  }
}