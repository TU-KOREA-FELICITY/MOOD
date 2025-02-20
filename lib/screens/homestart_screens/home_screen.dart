import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:fl_chart/fl_chart.dart';
import '../searchstart_screens/service/spotify_service.dart';
import 'emotion_analysis_service.dart';
import '../searchstart_screens/widget/miniplayer.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> userInfo;

  HomeScreen({required this.userInfo});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SpotifyService _spotifyService = SpotifyService();
  final EmotionAnalysisService _emotionAnalysisService =
      EmotionAnalysisService();
  bool _isLoggedIn = false;
  bool _isMinimized = false;
  double _boxWidth = 320;
  double _boxHeight = 240;
  double _boxTop = 20;
  double _boxLeft = 20;
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

  List<FlSpot> generateRandomData(int count) {
    final random = Random();
    return List.generate(
      count,
      (index) => FlSpot(index.toDouble(), random.nextInt(4).toDouble()),
    );
  }

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _startEstimator();
    connectToServer();
    _emotionAnalysisService.setUserInfo(widget.userInfo['user_id']);
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
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userInfo': widget.userInfo}),
      );
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
    final result = await _emotionAnalysisService.runEmotionAnalysis();
    setState(() {
      _emotionResult = result['result'] ?? '';
      _status = result['status'];
    });
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

  void _toggleMinimize() {
    setState(() {
      _isMinimized = !_isMinimized;
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
          padding: EdgeInsets.only(top: 20, bottom: 20),
          child: Text(
            '${widget.userInfo['user_name']}님의 감정/집중도 인식중',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
        ),
        AnimatedPositioned(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: _isMinimized
                ? 15
                : (MediaQuery.of(context).size.height - _boxHeight) / 2,
            left: _isMinimized
                ? 15
                : (MediaQuery.of(context).size.width - _boxWidth) / 2,
            child: GestureDetector(
                onTap: _toggleMinimize,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: _isMinimized ? 100 : _boxWidth,
                  height: _isMinimized
                      ? 100 * (_boxHeight / _boxWidth)
                      : _boxHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(_isMinimized ? 5 : 10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withAlpha(128),
                        spreadRadius: _isMinimized ? 2 : 5,
                        blurRadius: _isMinimized ? 3 : 7,
                        offset: Offset(0, _isMinimized ? 1 : 3),
                      ),
                    ],
                  ),
                  child: ClipRect(
                    child: Align(
                      alignment: Alignment.center,
                      widthFactor: 1.0,
                      heightFactor: 1.0,
                      child: AspectRatio(
                        aspectRatio: _boxWidth / _boxHeight,
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
                ))),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _runEmotionAnalysis,
              child: Text('감정 분석'),
            ),
            SizedBox(width: 16),
            ElevatedButton(
              onPressed: _restartRecognition,
              child: Text('다시 시도하기'),
            ),
          ],
        ),
        SizedBox(height: 20),
        Text(
          '나의 집중도',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        Container(
          height: 200,
          width: 300,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(128),
                blurRadius: 10,
                spreadRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                drawVerticalLine: true,
                horizontalInterval: 0.25,
                verticalInterval: 0.25,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.shade300,
                  strokeWidth: 1,
                ),
                getDrawingVerticalLine: (value) => FlLine(
                  color: Colors.grey.shade300,
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      String text;
                      switch (value.toInt()) {
                        case 0:
                          text = '안전';
                          break;
                        case 1:
                          text = '경고';
                          break;
                        case 2:
                          text = '주의';
                          break;
                        case 3:
                          text = '위험';
                          break;
                        default:
                          return Container();
                      }
                      return Text(
                        text,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      );
                    },
                    reservedSize: 40,
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.black),
              ),
              minX: 0,
              maxX: 6,
              minY: 0,
              maxY: 3,
              lineBarsData: [
                LineChartBarData(
                  spots: generateRandomData(7),
                  isCurved: true,
                  color: Color(0xFF0126FA),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Color(0xFF0126FA).withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_emotionResult.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                Text(
                  '감정 분석 결과',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
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
              ],
            ),
          ),
        Offstage(
          offstage: true, // 항상 숨김 상태로 설정
          child: Miniplayer(
            spotifyService: _spotifyService,
            onTrackFinished: _runEmotionAnalysis,
          ),
        ),
      ],
    );
  }
}
