import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WarningRecordScreen extends StatefulWidget {
  final Map<String, dynamic> userInfo;

  WarningRecordScreen({required this.userInfo});

  @override
  _WarningRecordScreenState createState() => _WarningRecordScreenState();
}

class _WarningRecordScreenState extends State<WarningRecordScreen> {
  List<dynamic> warnings = [];

  @override
  void initState() {
    super.initState();
    fetchWarnings();
  }

  Future<void> fetchWarnings() async {
    final response = await http.post(
      Uri.parse('http://192.168.189.219:3000/get_warning'),
      body: jsonEncode({'user_id': widget.userInfo['user_id']}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      setState(() {
        warnings = json.decode(response.body)['warnings'];
      });
    } else {
      print('Failed to load warnings');
    }
  }

  String formatTimestamp(String timestamp) {
    DateTime dateTime = DateTime.parse(timestamp).toLocal();
    return '${dateTime.year}년 ${dateTime.month}월 ${dateTime.day}일 ${dateTime.hour}시 ${dateTime.minute}분 ${dateTime.second}초';
  }

  String calculateDuration(String startTimestamp, String endTimestamp) {
    DateTime start = DateTime.parse(startTimestamp);
    DateTime end = DateTime.parse(endTimestamp);
    Duration duration = end.difference(start).abs(); // ⬅️ 음수 방지

    int minutes = duration.inMinutes;
    int seconds = duration.inSeconds % 60;

    return '${minutes}분 ${seconds}초간 지속';
  }

  String getDurationForAxis(String axis, int index) {
    DateTime startTimestamp = DateTime.parse(warnings[index]['timestamp']);
    for (int i = index + 1; i < warnings.length; i++) {
      if (warnings[i]['axis'] == axis &&
          warnings[i]['level'] != warnings[index]['level']) {
        DateTime endTimestamp = DateTime.parse(warnings[i]['timestamp']);
        return calculateDuration(
            startTimestamp.toIso8601String(), endTimestamp.toIso8601String());
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          '주행 중 경고기록',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 23,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(13.0),
        child: warnings.isEmpty
            ? Center(
          child: Text(
            '경고기록이 없습니다.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        )
            : ListView.separated(
          padding: EdgeInsets.zero,
          clipBehavior: Clip.none,
          itemCount: warnings.length,
          separatorBuilder: (context, index) => SizedBox(height: 16),
          itemBuilder: (context, index) {
            var warning = warnings[index];
            if (warning['level'] == '안전') {
              return SizedBox.shrink(); // '안전' 단계는 출력하지 않음
            }

            String duration = '';
            for (int i = index + 1; i < warnings.length; i++) {
              if (warnings[i]['axis'] == warning['axis'] &&
                  warnings[i]['level'] != warning['level']) {
                duration = calculateDuration(
                    warning['timestamp'], warnings[i]['timestamp']);
                break;
              }
            }

            return Container(
              constraints: BoxConstraints(
                minHeight: 100,
                maxHeight: 150,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 15.0,
                  horizontal: 15.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning,
                              color: warning['level'] == '위험'
                                  ? Colors.red
                                  : warning['level'] == '경고'
                                  ? Colors.yellow
                                  : warning['level'] == '주의'
                                  ? Colors.orange
                                  : Colors.green,
                              size: 26,
                            ),
                            SizedBox(width: 15),
                            Text(
                              warning['level'],
                              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              warning['axis'],
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      formatTimestamp(warning['timestamp']),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    if (duration.isNotEmpty)
                      Text(
                        duration,
                        style: TextStyle(fontSize: 16),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
