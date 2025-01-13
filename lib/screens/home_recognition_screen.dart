import 'package:flutter/material.dart';
import 'bottom_navigation_widget.dart';

class HomeRecognitionScreen extends StatefulWidget {
  @override
  _HomeRecognitionScreenState createState() => _HomeRecognitionScreenState();
}

class _HomeRecognitionScreenState extends State<HomeRecognitionScreen> {
  int _currentIndex = 0;

  final List<String> emotions = [
    'SURPRISED', 'HAPPY', 'FEAR', 'DISGUSTED',
    'ANGRY', 'CONFUSED', 'SAD', 'CALM'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(30, 40, 30, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '실시간 얼굴 인식 중',
                        style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      width: 100,
                      height: 70,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                      ),
                      child: Center(child: Text('카메라')),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                Text(
                  '나의 집중도',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: Center(child: Text('차트 그래프')),
                ),
                SizedBox(height: 30),
                Text(
                  '현재의 감정',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Column(
                  children: emotions.map((emotion) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 7),
                    child: Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          emotion,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationWidget(
        onTabChange: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
