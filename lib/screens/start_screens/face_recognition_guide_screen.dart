import 'package:flutter/material.dart';
import 'face_recognition_screen.dart';

class FaceRecognitionGuideScreen extends StatelessWidget {
  final String userId;

  const FaceRecognitionGuideScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(30.0),
          child: Column(
            children: [
              SizedBox(height: 90),
              Icon(Icons.sentiment_satisfied_alt,
                  size: 90, color: Colors.black87),
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
                      Text("• ",
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF707070),
                          )),
                      SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          "사진은 버튼을 누르고 3초 뒤에 1장이 촬영됩니다.",
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
                      Text("• ",
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF707070),
                          )),
                      SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          "얼굴을 등록할 때는 전체가 잘 보이도록 해주세요.",
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
                      Text("• ",
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF707070),
                          )),
                      SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          "안경, 수염, 특수 화장 등으로 기존에 등록했던 얼굴과 특징이 달라지면 잘 인식되지 않을 수 있습니다.",
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            FaceRecognitionScreen(userId: userId),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0126FA),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    "FACE ID 등록 시작",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
