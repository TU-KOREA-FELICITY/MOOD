import 'package:flutter/material.dart';
import 'face_recognition_guide_screen.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _carModel = '';
  bool _isNameValid = false;
  bool _isCarModelValid = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '회원가입',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        titleSpacing: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(40.0),
          children: [
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  color: Colors.black,
                ),
                children: <TextSpan>[
                  TextSpan(text: 'Welcome to '),
                  TextSpan(
                    text: 'MOOD',
                    style: TextStyle(color: Color(0xFF0126FA)),
                  ),
                  TextSpan(text: '!'),
                ],
              ),
            ),
            SizedBox(height: 40),
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
                    // 사진 등록 로직 구현
                  },
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              '얼굴인식 시작하기',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 50),
        Row(
          children: [
        Expanded(
        child: TextFormField(
        decoration: InputDecoration(
          labelText: '이름',
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
              return '이름을 입력해주세요';
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
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: '차종',
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
                        return '차종을 입력해주세요';
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
            SizedBox(height: 250),
            Container(
              width: MediaQuery.of(context).size.width * 0.25,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    Navigator.pushNamed(context, '/music_preference');
                  }
                },
                child: Text(
                  '선호 취향 등록',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Color(0xFF0126FA)),
                  foregroundColor: WidgetStateProperty.all(Colors.white),
                  padding: WidgetStateProperty.all(EdgeInsets.symmetric(vertical: 12)),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
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