import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class EmotionRecordScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('날짜별 감정 기록'),
      ),
      body: TableCalendar(
        firstDay: DateTime.utc(2021, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: DateTime.now(),
      ),
    );
  }
}
