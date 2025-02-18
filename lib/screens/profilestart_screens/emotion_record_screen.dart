import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';
import 'dart:convert';

class EmotionRecordScreen extends StatefulWidget {
  final Map<String, dynamic> userInfo;

  EmotionRecordScreen({required this.userInfo});

  @override
  _EmotionRecordScreenState createState() => _EmotionRecordScreenState();
}

class _EmotionRecordScreenState extends State<EmotionRecordScreen> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  Map<DateTime, String> _dailyEmotions = {};
  Map<DateTime, Map<int, String>> _dailyHourlyEmotions = {};
  Map<int, String> _selectedDayEmotions = {};

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
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = _selectedDay;
    _loadEmotionData();
  }

  void _loadEmotionData() async {
    final result = await getEmotions(widget.userInfo['user_aws_id']);
    if (result['success']) {
      final processedData = _processEmotionData(result['emotions']);
      setState(() {
        _dailyEmotions = processedData['dailyEmotions'];
        _dailyHourlyEmotions = processedData['dailyHourlyEmotions'];
        _selectedDayEmotions = _dailyHourlyEmotions[_selectedDay] ?? {};
      });
    }
  }

  Future<Map<String, dynamic>> getEmotions(String userAwsId) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/get_emotions'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_aws_id': userAwsId}),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success']) {
          return {
            'success': true,
            'emotions': result['emotions'],
          };
        } else {
          return {
            'success': false,
            'message': result['message'] ?? '알 수 없는 오류가 발생했습니다.',
          };
        }
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': '사용자의 감정 데이터를 찾을 수 없습니다.',
        };
      } else {
        return {
          'success': false,
          'message': '서버 오류: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '감정 데이터 조회 중 오류 발생: $e',
      };
    }
  }

  Map _processEmotionData(List emotions) {
    Map<DateTime, Map<int, Map<String, int>>> dailyHourlyEmotionCounts = {};
    Map<DateTime, Map<String, int>> dailyEmotionCounts = {};

    for (var emotion in emotions) {
      DateTime date = DateTime.parse(emotion['detected_at']).toLocal();
      String firstEmotion = emotion['detected_emotion'].split(',')[0];
      int hour = date.hour;
      DateTime dateKey = DateTime(date.year, date.month, date.day);

      // 날짜별 시간대 감정 데이터 업데이트
      if (!dailyHourlyEmotionCounts.containsKey(dateKey)) {
        dailyHourlyEmotionCounts[dateKey] = {};
      }
      if (!dailyHourlyEmotionCounts[dateKey]!.containsKey(hour)) {
        dailyHourlyEmotionCounts[dateKey]![hour] = {};
      }
      dailyHourlyEmotionCounts[dateKey]![hour]![firstEmotion] =
          (dailyHourlyEmotionCounts[dateKey]![hour]![firstEmotion] ?? 0) + 1;

      // 날짜별 감정 데이터 업데이트
      if (!dailyEmotionCounts.containsKey(dateKey)) {
        dailyEmotionCounts[dateKey] = {};
      }
      dailyEmotionCounts[dateKey]![firstEmotion] =
          (dailyEmotionCounts[dateKey]![firstEmotion] ?? 0) + 1;
    }

    // 각 날짜의 각 시간대에서 가장 빈도 높은 감정을 선택
    Map<DateTime, Map<int, String>> dailyHourlyEmotions = {};
    dailyHourlyEmotionCounts.forEach((date, hourlyData) {
      dailyHourlyEmotions[date] = {};
      hourlyData.forEach((hour, counts) {
        if (counts.isNotEmpty) {
          String mostFrequentEmotion =
              counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
          dailyHourlyEmotions[date]![hour] = mostFrequentEmotion;
        }
      });
    });

    // 각 날짜에서 가장 빈도 높은 감정을 선택
    Map<DateTime, String> dailyEmotions = {};
    dailyEmotionCounts.forEach((date, counts) {
      if (counts.isNotEmpty) {
        String mostFrequentEmotion =
            counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
        dailyEmotions[date] = mostFrequentEmotion;
      }
    });

    return {
      'dailyHourlyEmotions': dailyHourlyEmotions,
      'dailyEmotions': dailyEmotions,
    };
  }

  void _showEmotionDialog(DateTime date) {
    String emotion = _dailyEmotions[date] ?? '기록 없음';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${date.year}년 ${date.month}월 ${date.day}일의 감정'),
          content: Text('가장 빈도가 높은 감정: $emotion'),
          actions: <Widget>[
            TextButton(
              child: Text('확인'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

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
                  _selectedDay = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
                  _focusedDay = focusedDay;
                  _selectedDayEmotions = _dailyHourlyEmotions[_selectedDay] ?? {};
                });
                _showEmotionDialog(_selectedDay!);
              },
              headerStyle: HeaderStyle(
                titleTextStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
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
            Text(
              '시간대별 가장 빈도 높은 감정',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Container(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 24,
                itemBuilder: (context, index) {
                  return Card(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${index}시'),
                          Text(_selectedDayEmotions[index] ?? '데이터 없음'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
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