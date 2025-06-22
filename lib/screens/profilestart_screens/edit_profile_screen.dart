import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../start_screens/face_recognition_guide_screen.dart';

class EditProfileScreen extends StatefulWidget {
  final Map userInfo;

  EditProfileScreen({required this.userInfo});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _carModel;
  bool _isNameChanged = false;
  bool _isCarModelChanged = false;

  @override
  void initState() {
    super.initState();
    _name = widget.userInfo['username'] ?? '';
    _carModel = widget.userInfo['carModel'] ?? '';
  }

  Future<void> _updateUserInfo(BuildContext context) async {
    try {
      Map<String, dynamic> updateData = {
        'user_aws_id': widget.userInfo['user_aws_id'],
      };

      if (_isNameChanged) {
        updateData['username'] = _name;
      }

      if (_isCarModelChanged) {
        updateData['car_type'] = _carModel;
      }

      if (updateData.length == 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('변경된 정보가 없습니다.')),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('http://192.168.189.219:3000/user_info_update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updateData),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사용자 정보가 성공적으로 업데이트되었습니다.')),
        );
        Navigator.pop(context);
      } else {
        String errorMessage =
            responseData['message'] ?? '사용자 정보 업데이트에 실패했습니다. 다시 시도해주세요.';
        _showErrorDialog(context, errorMessage);
      }
    } catch (e) {
      print('Error: $e');
      _showErrorDialog(context, '예기치 않은 오류가 발생했습니다. 다시 시도해주세요.');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          '운전자 정보 수정',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 23,
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
                  color: Colors.grey[300],
                ),
                child: IconButton(
                  icon: Icon(Icons.center_focus_weak,
                      color: Colors.black54, size: 50),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FaceRecognitionGuideScreen(
                          userId: widget.userInfo['userId'] ?? '',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'FACE ID 다시 등록하기',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 50),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 25.0),
              child: TextFormField(
                initialValue: _name,
                decoration: InputDecoration(
                  labelText: '이름 수정하기',
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                  suffixIcon: Icon(
                    Icons.check_circle,
                    color: _isNameChanged ? Color(0xFF6A698C) : Colors.grey,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _name = value;
                    _isNameChanged = value != widget.userInfo['username'];
                  });
                },
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 25.0),
              child: TextFormField(
                initialValue: _carModel,
                decoration: InputDecoration(
                  labelText: '차종 수정하기',
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                  suffixIcon: Icon(
                    Icons.check_circle,
                    color: _isCarModelChanged ? Color(0xFF6A698C) : Colors.grey,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _carModel = value;
                    _isCarModelChanged = value != widget.userInfo['carModel'];
                  });
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(20.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _updateUserInfo(context);
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
              '정보 수정 완료',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
