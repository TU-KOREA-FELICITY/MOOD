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

  List<FlSpot> warningData = [];
  int maxDataPoints = 60;

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
          updateWarningData(_warningMessage);
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
    if (mounted) {
      setState(() {
        _emotionResult = result['result'] ?? '';
        _status = result['status'];
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

  void updateWarningData(String warningMessage) {
    double warningLevel = 0;
    if (warningMessage.contains('안전'))
      warningLevel = 0;
    else if (warningMessage.contains('경고'))
      warningLevel = 1;
    else if (warningMessage.contains('주의'))
      warningLevel = 2;
    else if (warningMessage.contains('위험'))
      warningLevel = 3;

    DateTime now = DateTime.now();
    warningData.add(FlSpot(now.millisecondsSinceEpoch.toDouble(), warningLevel));

    double tenMinutesAgo = now.millisecondsSinceEpoch.toDouble() - (30 * 60 * 1000);
    warningData.removeWhere((spot) => spot.x < tenMinutesAgo);

    setState(() {});
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildHeader(),
          _buildWebcamView(),
          _buildWarningMessage(),
          _buildAnalysisButtons(),
          _buildConcentrationChart(),
          _buildEmotionAnalysisResult(),
          _buildHiddenMiniplayer(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.only(top: 20, bottom: 20),
      child: Text(
        '${widget.userInfo['user_name']}님의 감정/집중도 인식중',
        style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildWebcamView() {
    return Column(
      children: [
        Center(
          child: GestureDetector(
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
      ],
    );
  }

  Widget _buildWarningMessage() {
    return _warningMessage.isNotEmpty
        ? Center(
            child: Text(
              _warningMessage,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          )
        : SizedBox.shrink();
  }

  Widget _buildAnalysisButtons() {
    return Row(
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
    );
  }

  Widget _buildConcentrationChart() {
    return Column(
      children: [
        SizedBox(height: 20),
        Stack(
          children: [
            Container(
              height: 200,
              width: 300,
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
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 20,
              width: 60,
              child: Container(
                padding: EdgeInsets.only(top: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('위험', style: TextStyle(fontSize: 12)),
                    Text('주의', style: TextStyle(fontSize: 12)),
                    Text('경고', style: TextStyle(fontSize: 12)),
                    Text('안전', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 40,
              right: 0,
              bottom: 0,
              height: 20,
              child: StreamBuilder(
                stream: Stream.periodic(Duration(seconds: 1), (i) => DateTime.now()),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Container();
                  final now = snapshot.data!;
                  return Container(
                    padding: EdgeInsets.only(left: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        7,
                            (index) {
                          final minutes = index * 5;
                          return Text(
                            '${minutes}분 전',
                            style: TextStyle(fontSize: 10),
                          );
                        },
                      ).reversed.toList(),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              left: 0,
              top: 10,
              right: 10,
              bottom: 25,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: true),
                      minX: DateTime.now().millisecondsSinceEpoch.toDouble() - (30 * 60 * 1000),
                      maxX: DateTime.now().millisecondsSinceEpoch.toDouble(),
                      minY: 0,
                      maxY: 3,
                      lineBarsData: [
                        LineChartBarData(
                          spots: warningData.isNotEmpty
                              ? warningData
                              : [FlSpot(0, 0)],
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
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildEmotionAnalysisResult() {
    return _emotionResult.isNotEmpty
        ? Padding(
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
          )
        : SizedBox.shrink();
  }

  Widget _buildHiddenMiniplayer() {
    return Offstage(
      offstage: true,
      child: Miniplayer(
        spotifyService: _spotifyService,
        onTrackFinished: _runEmotionAnalysis,
      ),
    );
  }
}
