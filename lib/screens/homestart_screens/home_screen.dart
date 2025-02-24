import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:fl_chart/fl_chart.dart';
import 'package:audioplayers/audioplayers.dart';
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
  final EmotionAnalysisService _emotionAnalysisService = EmotionAnalysisService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isDialogShowing = false;
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
    String dialogTitle = '';
    String dialogContent = '';
    String soundAsset = '';

    if (warningMessage.contains('안전')) {
      warningLevel = 0;
      if (_isDialogShowing) {
        Navigator.of(context).pop();
        _isDialogShowing = false;
        _audioPlayer.stop();
      }
    } else if (warningMessage.contains('경고')) {
      warningLevel = 1;
      dialogTitle = '경고';
      dialogContent = '경고 상태입니다! 주의해주세요\n안정된 상태로 전환 시 자동으로 팝업이 종료됩니다.';
      soundAsset = 'warning_sound.mp3';
    } else if (warningMessage.contains('주의')) {
      warningLevel = 2;
      dialogTitle = '주의';
      dialogContent = '주의 상태입니다! 집중해주세요\nn안정된 상태로 전환 시 자동으로 팝업이 종료됩니다.';
      soundAsset = 'caution_sound.mp3';
    } else if (warningMessage.contains('위험')) {
      warningLevel = 3;
      dialogTitle = '위험';
      dialogContent = '위험 상태입니다! 즉시 조치를 취해주세요\n안정된 상태로 전환 시 자동으로 팝업이 종료됩니다.';
      soundAsset = 'danger_sound.mp3';
    }

    DateTime now = DateTime.now();
    warningData.add(FlSpot(now.millisecondsSinceEpoch.toDouble(), warningLevel));

    double tenMinutesAgo = now.millisecondsSinceEpoch.toDouble() - (30 * 60 * 1000);
    warningData.removeWhere((spot) => spot.x < tenMinutesAgo);

    if (warningLevel > 0 && !_isDialogShowing) {
      _showWarningDialog(dialogTitle, dialogContent);
      _playWarningSound(soundAsset);
    }

    setState(() {});
  }

  void _showWarningDialog(String title, String content) {
    _isDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
            child: Container(
              width: 400,
              height: 600,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: EdgeInsets.all(20),
          title: Row(
            children: [
              Icon(
                Icons.warning,
                color: Colors.red,
                size: 40,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                content,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                '확인',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0126FA),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _isDialogShowing = false;
              },
            ),
          ],
        ),
            ),
        );
      },
    );
  }

  void _playWarningSound(String assetPath) async {
    await _audioPlayer.play(AssetSource(assetPath));
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
        '${widget.userInfo['user_name']}님의 감정/집중도 인식 중',
        style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildWebcamView() {
    return Center(
      child: Container(
        width: 350,
        height: 200,
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              _imageData != null
                  ? Image.memory(
                _imageData!,
                width: 350,
                height: 200,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              )
                  : Center(child: Text('카메라 화면이 여기에 표시됩니다')),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  color: Colors.black.withOpacity(0.5),
                  child: Text(
                    _warningMessage,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildAnalysisButtons() {
    return Padding(
      padding: EdgeInsets.only(top: 10, bottom: 10, left: 40, right: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _restartRecognition,
            child: Icon(
              Icons.refresh,
              color: Colors.black,
              size: 24,
            ),
          ),
          GestureDetector(
            onTap: _runEmotionAnalysis,
            child: Text(
              '감정 분석하기',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConcentrationChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10),
        Padding(
          padding: EdgeInsets.only(left: 20),
          child: Text(
          "나의 집중도",
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          ),
        ),
        SizedBox(height: 10),
        Stack(
          children: [
            Container(
              height: 200,
              width: 350,
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
                    Text('위험', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Text('주의', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Text('경고', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Text('안전', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                        6,
                            (index) {
                          final minutes = index;
                          return Text(
                            '${minutes}분 전',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                      gridData: FlGridData(show: true,
                        drawVerticalLine: true,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withValues(alpha: 0.25),
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withValues(alpha: 0.25),
                            strokeWidth: 1,
                          );
                        },
                        verticalInterval: 30000,
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: DateTime.now().millisecondsSinceEpoch.toDouble() - (5 * 60 * 1000),
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
                            color: Color(0xFF0126FA).withValues(alpha: 0.1),
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
        ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.only(left: 40),
            child: Text(
              '감정 분석 결과',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
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
                    padding: EdgeInsets.symmetric(vertical: 9),
                    child: Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withAlpha(128),
                              blurRadius: 5,
                              spreadRadius: 2,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          '$emotion: $confidence',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,),
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
          SizedBox(height: 10),
        ],
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
