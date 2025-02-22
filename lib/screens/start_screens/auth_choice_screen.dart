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
            SizedBox(height: 220),
            Center(
              child: Image.asset(
                'assets/MOOD_logo_blue.png',
                height: 100,
              ),
            ),

            SizedBox(height: 280),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0126FA),
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
                    fontSize: 20,
                  ),
                ),
              ),
            ),

            SizedBox(height: 15),

            SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: OutlinedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: Colors.white,
                        title: Text("공지사항",
                          style: TextStyle(fontWeight: FontWeight.bold,
                            fontSize: 26,
                          ),
                        ),
                        content: Container(
                          width: MediaQuery.of(context).size.width * 0.9,
                          child: Text("MOOD는 SPOTIFY를 기반으로 실행됩니다.\n스포티파이 어플이 설치된 상태에서 회원가입을 진행해 주세요",
                            style: TextStyle(
                              fontSize: 15,
                            ),
                          ),
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: Text("확인",
                              style: TextStyle(
                                color: Color(0xFF0126FA),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
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
                    fontSize: 20,
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