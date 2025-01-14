import 'package:flutter/material.dart';

class WarningRecordScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('주행 중 경고기록'),
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.0,
        ),
        itemCount: 10, // 예시로 10개의 아이템을 표시
        itemBuilder: (context, index) {
          return Card(
            child: Center(child: Text('경고 ${index + 1}')),
          );
        },
      ),
    );
  }
}
