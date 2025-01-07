import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _carModel = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('회원가입'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: [
            Text(
              'Welcome to MOOD!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // 사진 등록 로직 구현
              },
              child: Text('사진 등록'),
            ),
            Text(
              '얼굴을 가리지 않는 사진을 5장 이상 등록해주세요',
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            TextFormField(
              decoration: InputDecoration(labelText: '이름'),
              onSaved: (value) => _name = value!,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '이름을 입력해주세요';
                }
                return null;
              },
            ),
            TextFormField(
              decoration: InputDecoration(labelText: '차종'),
              onSaved: (value) => _carModel = value!,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '차종을 입력해주세요';
                }
                return null;
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  Navigator.pushNamed(context, '/music_preference');
                }
              },
              child: Text('선호 취향 등록'),
            ),
          ],
        ),
      ),
    );
  }
}
