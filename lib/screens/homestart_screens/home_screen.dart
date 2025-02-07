import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:mood/screens/homestart_screens/home_recognition_screen.dart';
import 'package:mood/screens/searchstart_screens/spotify_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SpotifyService _spotifyService = SpotifyService();
  bool _isLoggedIn = false;
  int _currentIndex = 0;
  IO.Socket? socket;
  Uint8List? _imageData;
  String _warningMessage = '';
  String _emotionResult = '';
  String _status = '';

  final List<Map<String, dynamic>> emotions = [
    {'name': 'ANGRY', 'color': Color(0xFFFFDBD6)},
    {'name': 'HAPPY', 'color': Color(0xFFFEEFF2)},
    {'name': 'SURPRISED', 'color': Color(0xFFFFFAD7)},
    {'name': 'DISGUSTED', 'color': Color(0xFFFFFBF4)},
    {'name': 'CALM', 'color': Color(0xFFE0F0E2)},
    {'name': 'SAD', 'color': Color(0xFFE9F5FD)},
    {'name': 'CONFUSED', 'color': Color(0xFFFBF4FB)},
    {'name': 'FEAR', 'color': Color(0xFFEFEFEF)},
  ];

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _startEstimator();
    connectToServer();
  }

  void connectToServer() {
    try {
      socket = IO.io('http://10.0.2.2:3000', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
      });

      socket!.onConnect((_) {
        print('서버에 연결되었습니다.');
      });

      socket!.on('webcam_stream', (data) {
        if (data != null) {
          setState(() {
            _imageData = base64Decode(data);
          });
        }
      });

      socket!.on('warning', (data) {
        setState(() {
          _warningMessage =
              'Warning: ${data['level']} ${data['axis']} error ${data['error']}';
        });
      });

      socket!.onDisconnect((_) => print('서버와 연결이 끊어졌습니다.'));
      socket!.onError((err) => print('에러 발생: $err'));

      socket!.connect();
    } catch (e) {
      print('서버 연결 중 오류 발생: $e');
    }
  }

  Future<void> _checkLoginStatus() async {
    bool isLoggedIn = await _spotifyService.isLoggedIn();
    setState(() {
      _isLoggedIn = isLoggedIn;
    });
  }

  Future<void> _startEstimator() async {
    final url = Uri.parse('http://10.0.2.2:3000/start_estimator');
    try {
      final response = await http.post(url);
      if (response.statusCode == 200) {
        print('estimator.py가 성공적으로 시작되었습니다.');
      } else {
        print('estimator.py 시작 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('estimator.py 시작 중 오류 발생: $e');
    }
  }

  Future<void> _runEmotionAnalysis() async {
    setState(() {
      _status = '감정 분석 중...';
    });
    final url = Uri.parse('http://10.0.2.2:3000/analyze_emotion');
    try {
      final response = await http.post(url);
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        setState(() {
          _emotionResult = result['result'] ?? '';
          _status = '감정 분석 완료';
        });
      } else {
        print('aws-face-reg.py 실행 실패: ${response.statusCode}');
        print('서버 응답: ${response.body}');
        setState(() {
          _status = '감정 분석 실패';
        });
      }
    } catch (e) {
      print('aws-face-reg.py 실행 중 오류 발생: $e');
      setState(() {
        _status = '서버 연결 오류: $e';
      });
    }
  }

  void _restartRecognition() {
    setState(() {
      _imageData = null;
      _warningMessage = '';
      _emotionResult = '';
      _status = '';
      _startEstimator();
    });
  }

  @override
  void dispose() {
    socket?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: _getBody(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Padding(
        padding: EdgeInsets.only(left: 20),
        child: _getAppBarTitle(),
      ),
      titleSpacing: 0,
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
    );
  }

  Widget _getAppBarTitle() {
    IconData icon;
    String title;

    switch (_currentIndex) {
      case 0:
        icon = Icons.home;
        title = '홈';
        break;
      case 1:
        icon = Icons.search;
        title = '검색';
        break;
      case 2:
        icon = Icons.person;
        title = '프로필';
        break;
      default:
        return Container();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.black, size: 32),
        SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ],
    );
  }

  Widget _getBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 60, bottom: 20),
          child: Text(
            '감정/집중도 인식중',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
        ),
        Center(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => HomeRecognitionScreen()),
              );
            },
            child: Container(
              width: 300,
              height: 400,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(128),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: _imageData != null
                  ? Image.memory(
                      _imageData!,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    )
                  : Center(child: Text('카메라 화면이 여기에 표시됩니다')),
            ),
          ),
        ),
        if (_warningMessage.isNotEmpty)
          Center(
            child: Text(
              _warningMessage,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
        ElevatedButton(
          onPressed: _runEmotionAnalysis,
          child: Text('감정 분석'),
        ),
        if (_emotionResult.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '감정 분석 결과',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Column(
                  children: _emotionResult
                      .split('\n')
                      .where((line) => line.contains(':'))
                      .map((line) {
                    final parts = line.split(': ');
                    if (parts.length < 2) {
                      return Container(); // 잘못된 데이터 처리
                    }
                    final emotion = parts[0].trim();
                    final confidence = parts[1].trim();
                    final color = emotions.firstWhere(
                        (e) => e['name'] == emotion,
                        orElse: () => {'color': Colors.white})['color'];
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 7),
                      child: Center(
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.9,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withAlpha(128),
                                blurRadius: 5,
                                spreadRadius: 1,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '$emotion: $confidence',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 10),
                Text(
                  '상태: $_status',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ElevatedButton(
          onPressed: _restartRecognition,
          child: Text('다시시도하기'),
        ),
      ],
    );
  }
}
