import 'package:flutter/material.dart';

class AuthChoiceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 180),
            Center(
              child: Image.asset(
                'assets/logo/MOOD_logo_head.png',
                height: 190,
              ),
            ),

            SizedBox(height: 220),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF8C88D5),
                  padding: EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  '기존 유저 로그인',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                  ),
                ),
              ),
            ),

            SizedBox(height: 15),

            SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: OutlinedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        insetPadding: EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        title: Text("공지사항",
                          style: TextStyle(fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        content: Container(
                          height: 55,
                          width: MediaQuery.of(context).size.width * 0.9,
                          child: Text("MOOD는 SPOTIFY를 기반으로 실행됩니다.\n스포티파이 어플이 설치된 상태에서 회원가입을 진행해 주세요",
                            style: TextStyle(
                              fontSize: 13,
                            ),
                          ),
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: Text("확인",
                              style: TextStyle(
                                color: Color(0xFF8C88D5),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.pushNamed(context, '/signup');
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey, width: 2),
                  padding: EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  '신규 회원가입',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}