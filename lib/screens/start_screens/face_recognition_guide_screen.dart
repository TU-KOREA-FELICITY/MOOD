import 'package:flutter/material.dart';

class FaceRecognitionGuideScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(30.0),
          child: Column(
            children: [
              SizedBox(height: 90),
              Icon(Icons.sentiment_satisfied_alt, size: 90, color: Colors.black87),
              SizedBox(height: 5),
              Text(
                "얼굴 인식",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 90),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("• ", style: TextStyle(
                          fontSize: 16,
                        color: Color(0xFF707070),
                      )),
                      SizedBox(width: 5),
                      Expanded(
                        child: Text(
                            "사진은 버튼을 누르는 즉시 1장이 촬영됩니다.",
                            style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF707070),
                            ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("• ", style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF707070),
                      )),
                      SizedBox(width: 5),
                      Expanded(
                        child: Text("얼굴을 등록할 때는 전체가 잘 보이도록 해주세요.",
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF707070),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("• ", style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF707070),
                      )),
                      SizedBox(width: 5),
                      Expanded(
                        child: Text("안경, 수염, 특수 화장 등으로 기존에 등록했던 얼굴과 특징이 달라지면 잘 인식되지 않을 수 있습니다.",
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF707070),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          SizedBox(height: 250),
          Container(
            width: MediaQuery.of(context).size.width * 0.8,
            child: ElevatedButton(
              onPressed: () {
                //네비게이션 기능 작성
              },
                child: Text(
                  "얼굴 등록 시작",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Color(0xFF0126FA)),
                  foregroundColor: WidgetStateProperty.all(Colors.white),
                  padding: WidgetStateProperty.all(EdgeInsets.symmetric(vertical: 12)),
                  shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(20),
                  ),
                  ),
                ),
              ),
          ),
            ],
          ),
        ),
      ),
    );
  }
}
