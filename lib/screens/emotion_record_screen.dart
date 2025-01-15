import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';


class EmotionRecordScreen extends StatefulWidget {
  @override
  _EmotionRecordScreenState createState() => _EmotionRecordScreenState();
}
class _EmotionRecordScreenState extends State<EmotionRecordScreen> {
  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now();
  final List<Map<String, dynamic>> emotions = [
    {'emotion': '행복', 'color': Color(0xFFFFD1DC)},
    {'emotion': '슬픔', 'color': Color(0xFFADD8E6)},
    {'emotion': '분노', 'color': Color(0xFFFFCCCB)},
    {'emotion': '평온', 'color': Color(0xFFCCFFCC)},
    {'emotion': '놀람', 'color': Color(0xFFFFFACD)},
    {'emotion': '혐오', 'color': Color(0xFFFFDab9)},
    {'emotion': '공포', 'color': Color(0xFFADD8E6)},
    {'emotion': '혼란', 'color': Color(0xFFE6E6FA)},
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        centerTitle: false,
        title: Text(
        '날짜별 감정 기록',
        style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 20,
    ),
        ),
        ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2021, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              headerStyle: HeaderStyle(
                titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                titleCentered: true,
                formatButtonVisible: false,
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(color: Colors.black),
                selectedDecoration: BoxDecoration(
                  color: Color(0xFF95AFF0),
                  shape: BoxShape.circle,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  if (day.weekday == DateTime.saturday) {
                    return Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(color: Colors.blue),
                      ),
                    );
                  } else if (day.weekday == DateTime.sunday) {
                    return Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  }
                },
                dowBuilder: (context, day) {
                  if (day.weekday == DateTime.saturday) {
                    return Center(
                      child: Text(
                        'Sat',
                        style: TextStyle(color: Colors.blue),
                      ),
                    );
                  } else if (day.weekday == DateTime.sunday) {
                    return Center(
                      child: Text(
                        'Sun',
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  final weekdayString = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  return Center(
                    child: Text(
                      weekdayString[day.weekday - 1],
                      style: TextStyle(color: Colors.black),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            Divider(color: Colors.grey),
            SizedBox(height: 30),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: emotions.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      if (_selectedDay != null) {
                        // 감정 기록 로직 추가
                        print('${emotions[index]['emotion']} selected for $_selectedDay');
                      }
                    },
                    child: Card(
                      color: emotions[index]['color'],
                      child: Center(
                        child: Text(
                          emotions[index]['emotion'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}