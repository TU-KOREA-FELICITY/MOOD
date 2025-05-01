import 'package:flutter/material.dart';
import 'face_recognition_guide_screen.dart';

class SignupScreen extends StatefulWidget {
  final String userId;

  const SignupScreen({super.key, required this.userId});

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
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        titleSpacing: 0,
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.all(40.0),
              children: [
                SizedBox(height: 10),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      color: Colors.black,
                    ),
                    children: <TextSpan>[
                      TextSpan(text: 'Welcome to '),
                      TextSpan(
                        text: 'MOOD',
                        style: TextStyle(color: Color(0xFF8C88D5)),
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
                        shape: BoxShape.circle, color: Colors.grey[300]),
                    child: IconButton(
                      icon: Icon(Icons.center_focus_weak,
                          color: Colors.black54, size: 50),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => FaceRecognitionGuideScreen(
                                  userId: widget.userId)),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  '1. FACE ID 등록을 먼저 진행해주세요',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 50),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: '2. 이름',
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
                      color: _isNameValid ? Color(0xFF6A698C) : Colors.grey,
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: '3. 차종',
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
                      color: _isCarModelValid ? Color(0xFF6A698C) : Colors.grey,
                    ),
                  ],
                ),
                SizedBox(height: 50),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 80,
            child: Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                child: ElevatedButton(
                  onPressed: () {
                    // Form 검증 및 저장
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      Navigator.pushNamed(
                        context,
                        '/music_preference',
                        arguments: {
                          'userId': widget.userId,
                          'name': _name,
                          'carModel': _carModel,
                        },
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF8C88D5),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    '선호 취향 등록',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
