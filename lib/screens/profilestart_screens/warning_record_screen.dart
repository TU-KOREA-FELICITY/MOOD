import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WarningRecordScreen extends StatefulWidget {
  @override
  _WarningRecordScreenState createState() => _WarningRecordScreenState();
}

class _WarningRecordScreenState extends State<WarningRecordScreen> {
  final storage = FlutterSecureStorage();
  List<dynamic>? _warningRecords;
  String _status = '경고 기록을 불러오는 중...';

  @override
  void initState() {
    super.initState();
    _fetchWarningRecords();
  }

  Future<void> _fetchWarningRecords() async {
    final token = await storage.read(key: 'token');
    final url = Uri.parse('http://10.0.2.2:3000/warning_records');
    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
      });
      if (response.statusCode == 200) {
        setState(() {
          _warningRecords = json.decode(response.body);
          _status = '경고 기록 불러오기 완료';
        });
      } else {
        setState(() {
          _status = '경고 기록 불러오기 실패: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _status = '경고 기록 불러오기 중 오류 발생: $e';
      });
    }
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
            fontSize: 20,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(13.0),
        child: ListView.separated(
          clipBehavior: Clip.none,
          itemCount: _warningRecords?.length ?? 0,
          separatorBuilder: (context, index) => SizedBox(height: 16),
          itemBuilder: (context, index) {
            final record = _warningRecords![index];
            return Container(
              constraints: BoxConstraints(
                minHeight: 120, // 최소 높이 설정
                maxHeight: 140,
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
                  vertical: 10.0,
                  horizontal: 13.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red, size: 24),
                        SizedBox(width: 8),
                        Text(
                          '주의',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      record['date'],
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      record['duration'],
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
