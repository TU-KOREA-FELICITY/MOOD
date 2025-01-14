import 'package:flutter/material.dart';
import 'face_recognition_guide_screen.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _carModel = '';
  bool _isNameValid = false;
  bool _isCarModelValid = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          '운전자 정보 수정',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: [
            SizedBox(height: 70),
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300]
                ),
                child: IconButton(
                  icon: Icon(Icons.center_focus_weak, color: Colors.black54, size: 50),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => FaceRecognitionGuideScreen()),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              '얼굴 인식 다시하기',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 50),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 25.0),
          child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: '이름 수정하기',
                      labelStyle: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _isNameValid = value.isNotEmpty;
                      });
                    },
                    onSaved: (value) => _name = value!,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '이름을 수정해주세요';
                      }
                      return null;
                    },
                  ),
                ),
                Icon(
                  Icons.check_circle,
                  color: _isNameValid ? Color(0xFF014FFA) : Colors.grey,
                ),
              ],
            ),
        ),
            SizedBox(height: 20),
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 25.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: '차종 수정하기',
                      labelStyle: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _isCarModelValid = value.isNotEmpty;
                      });
                    },
                    onSaved: (value) => _carModel = value!,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '차종을 수정해주세요';
                      }
                      return null;
                    },
                  ),
                ),
                Icon(
                  Icons.check_circle,
                  color: _isCarModelValid ? Color(0xFF014FFA) : Colors.grey,
                ),
              ],
            ),
        ),
            SizedBox(height: 250),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.0), // 버튼의 좌우 여백 추가
              child: SizedBox(
                width: double.infinity, // 버튼의 너비를 최대로 설정
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      // 정보 저장 로직
                      // 로그인 화면으로 돌아가기
                      Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
                    }
                  },
                  child: Text(
                    '완료',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0126FA),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
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
