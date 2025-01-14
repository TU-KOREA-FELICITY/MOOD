import 'package:flutter/material.dart';

class EditProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('운전자 정보 수정'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(decoration: InputDecoration(labelText: '이름')),
            TextField(decoration: InputDecoration(labelText: '차종')),
            // 추가 필드들...
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('완료'),
              onPressed: () {
                // 정보 저장 로직
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
