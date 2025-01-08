import 'package:flutter/material.dart';

class FaceRecognitionGuideScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            children: [
              SizedBox(height: 90),
              Icon(Icons.face, size: 80, color: Colors.black54),
              SizedBox(height: 10),
              Text(
                "얼굴인식",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 80),
              Text(
                "· 사진은 2초 간격으로 총 10장이 촬영됩니다.\n\n"
                    "· 얼굴을 등록할때는 전체가 잘 보이도록 해주세요.\n\n "
                    "· 마스크, 선글라스, 모자와 같이 얼굴을 가리는 소품을 벗고 등록해 주세요\n\n"
                    "· 안경, 수염, 특수 화장 등으로 기존에 등록했던 얼굴과 특징이 달라지면 잘 인식되지 않을 수 있습니다",
                style: TextStyle(fontSize: 15),
                textAlign: TextAlign.left,
              ),
              Spacer(), // Add this to push the button to the bottom
              ElevatedButton(
                onPressed: () {
                  // Implement face recognition logic here
                },
                child: Text(
                  "얼굴인식 시작하기",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFEB9A1F),
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
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
