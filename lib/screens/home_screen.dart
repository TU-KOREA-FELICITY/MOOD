import 'package:flutter/material.dart';
import 'package:mood/screens/bottom_navigation_widget.dart';
import 'package:mood/screens/home_recognition_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Padding(
          padding: EdgeInsets.only(left: 20),
          child: Row(
            children: [
              Icon(Icons.home),
              SizedBox(width: 8),
              Text(
                '홈',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: _getBody(),
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

  Widget _getBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return Center(child: Text('검색 화면', style: TextStyle(fontSize: 24)));
      case 2:
        return Center(child: Text('프로필 화면', style: TextStyle(fontSize: 24)));
      default:
        return _buildHomeContent();
    }
  }

  void _restartRecognition() {
    setState(() {
      // 화면을 다시 시작하는 로직을 여기에 구현합니다.
    });
  }

  Widget _buildHomeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 55, top: 60, bottom: 20),
          child: Row(
            children: [
              Text(
                '감정/집중도 인식중',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 10),
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF014FFA)),
                  strokeWidth: 3.5,
                ),
              ),
            ],
          ),
        ),
        Center(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomeRecognitionScreen()),
              );
            },
            child: Container(
              width: 300,
              height: 400,
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xFF014FFA), width: 3),
              ),
              child: Center(
                child: Text('카메라 화면이 여기에 표시됩니다'),
              ),
            ),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: EdgeInsets.only(right: 60, bottom: 200),
              child: GestureDetector(
                onTap: _restartRecognition,
                child: Text(
                  '다시시도하기',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}