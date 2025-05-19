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
  final EmotionAnalysisService _emotionAnalysisService =
  EmotionAnalysisService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _wasMusicPlaying = false;
  bool _isDialogShowing = false;
  bool _isLoggedIn = false;
  int _currentIndex = 0;
  IO.Socket? socket;
  Uint8List? _imageData;
  String _warningMessage = '';
  String _emotionResult = '';
  String _status = '';

  final List<Map<String, dynamic>> emotions = [
    {'name': 'ANGRY', 'color': Color(0xFFFFBDBD)},
    {'name': 'HAPPY', 'color': Color(0xFFFFF09A)},
    {'name': 'SURPRISED', 'color': Color(0xFFFFCDB6)},
    {'name': 'DISGUSTED', 'color': Color(0xFFE3C4E5)},
    {'name': 'CALM', 'color': Color(0xFFE1F0A0)},
    {'name': 'SAD', 'color': Color(0xFFC9E4F1)},
    {'name': 'CONFUSED', 'color': Color(0xFFCBEBE0)},
    {'name': 'FEAR', 'color': Color(0xFFEBEBEB)},
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
          'Warning: ${data['level']} ${data['axis']} error \n${data['error']}';
          updateWarningData(_warningMessage);
        });
      });

      socket!.onDisconnect((_) => print('서버와 연결이 끊어졌습니다.'));
      socket!.onError((err) => print('에러 발생: \n$err'));

      socket!.connect();
    } catch (e) {
      print('서버 연결 중 오류 발생: \n$e');
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
      print('estimator.py 시작 중 오류 발생: \n$e');
    }
  }

  Future<void> _stopEstimator() async {
    final url = Uri.parse('http://10.0.2.2:3000/stop_estimator');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        print('estimator.py가 성공적으로 종료되었습니다.');
      } else {
        print('estimator.py 종료 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('estimator.py 종료 중 오류 발생: \n$e');
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
        if (_wasMusicPlaying) {
          _spotifyService.resumePlayback();
        }
      }
    } else if (warningMessage.contains('경고')) {
      warningLevel = 1;
      dialogTitle = '경고';
      dialogContent = '경고 상태입니다! 주의해주세요\n안정된 상태로 전환 시 자동으로 팝업이 종료됩니다.';
      soundAsset = 'warning_sound.mp3';
    } else if (warningMessage.contains('주의')) {
      warningLevel = 2;
      dialogTitle = '주의';
      dialogContent = '주의 상태입니다! 집중해주세요\n안정된 상태로 전환 시 자동으로 팝업이 종료됩니다.';
      soundAsset = 'caution_sound.mp3';
    } else if (warningMessage.contains('위험')) {
      warningLevel = 3;
      dialogTitle = '위험';
      dialogContent = '위험 상태입니다! 즉시 조치를 취해주세요\n안정된 상태로 전환 시 자동으로 팝업이 종료됩니다.';
      soundAsset = 'danger_sound.mp3';
    }

    DateTime now = DateTime.now();
    warningData
        .add(FlSpot(now.millisecondsSinceEpoch.toDouble(), warningLevel));

    double tenMinutesAgo =
        now.millisecondsSinceEpoch.toDouble() - (30 * 60 * 1000);
    warningData.removeWhere((spot) => spot.x < tenMinutesAgo);

    if (warningLevel > 0 && !_isDialogShowing) {
      _showWarningDialog(dialogTitle, dialogContent);
      _playWarningSound(soundAsset);
    }

    setState(() {});
  }

  void _showWarningDialog(String title, String content) {
    _isDialogShowing = true;

    Color _getIconColor(String title) {
      if (title.contains('위험')) return Colors.red;
      if (title.contains('주의')) return Colors.orange;
      if (title.contains('경고')) return Colors.yellow[700]!;
      return Colors.red;
    }

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
                    color: _getIconColor(title),
                    size: 40,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 24,
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
                      fontSize: 15,
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8C88D5),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _isDialogShowing = false;
                    _audioPlayer.stop();
                    if (_wasMusicPlaying) {
                      _spotifyService.resumePlayback();
                    }
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
    _wasMusicPlaying = await _spotifyService.isPlaying();
    if (_wasMusicPlaying) {
      await _spotifyService.pausePlayback();
    }
    await _audioPlayer.play(AssetSource(assetPath));
  }

  @override
  void dispose() {
    _stopEstimator();
    print('estimator.py 종료됨');
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
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Image.asset(
          'assets/logo/MOOD_logo_8C88D5.png',
          height: 32,
          fit: BoxFit.contain,
        ),
      ),
      title: null,
      centerTitle: false,
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
        Icon(icon, color: Colors.black, size: 30),
        SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
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
          _buildEmotionAnalysisResult(),
          _buildConcentrationChart(),
          _buildHiddenMiniplayer(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.only(top: 5, bottom: 20),
      child: Text(
        '${widget.userInfo['user_name']}님의 감정/집중도 인식 중',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildWebcamView() {
    return Center(
      child: Container(
        width: 350,
        height: 150,
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
                height: 150,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              )
                  : Center(child: Text('카메라 화면이 여기에 표시됩니다', style: TextStyle(
                fontSize: 12,),),),
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
              size: 17,
            ),
          ),
          GestureDetector(
            onTap: _runEmotionAnalysis,
            child: Text(
              '감정 분석하기',
              style: TextStyle(
                fontSize: 12,
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
          padding: EdgeInsets.only(left: 10),
          child: Text(
            "나의 집중도",
            style: TextStyle(
              fontSize: 20,
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
              padding: EdgeInsets.only(top: 24, bottom: 36, left: 70, right: 16),
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
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.25),
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.25),
                        strokeWidth: 1,
                      );
                    },
                    verticalInterval: 30000,
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: DateTime.now().millisecondsSinceEpoch.toDouble() -
                      (5 * 60 * 1000),
                  maxX: DateTime.now().millisecondsSinceEpoch.toDouble(),
                  minY: 0,
                  maxY: 3,
                  lineBarsData: [
                    LineChartBarData(
                      spots: warningData.isNotEmpty
                          ? warningData
                          : [FlSpot(0, 0)],
                      isCurved: true,
                      color: Color(0xFF8C88D5),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Color(0xFF8C88D5).withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 왼쪽
            Positioned(
              left: 0,
              top: 24,
              bottom: 36,
              width: 70,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('위험',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('주의',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('경고',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('안전',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            // 하단 시간
            Positioned(
              left: 70,
              right: 0,
              bottom: 0,
              height: 20,
              child: StreamBuilder(
                stream: Stream.periodic(
                    Duration(seconds: 1), (i) => DateTime.now()),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Container();
                  final now = snapshot.data!;
                  return Container(
                    padding: EdgeInsets.only(left: 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        6,
                            (index) {
                          final minutes = index;
                          return Text(
                            '${minutes}분 전',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          );
                        },
                      ).reversed.toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildEmotionAnalysisResult() {
    Map<String, double> emotionValues = {};

    bool hasAnalysisData = _emotionResult.isNotEmpty;

    if (hasAnalysisData) {
      _emotionResult.split('\n').where((line) => line.contains(':')).forEach((line) {
        final parts = line.split(': ');
        if (parts.length >= 2) {
          final emotion = parts[0].trim();
          final confidenceStr = parts[1].trim().replaceAll('%', '');
          final confidence = double.tryParse(confidenceStr) ?? 0.0;
          emotionValues[emotion] = confidence;
        }
      });
    }

    final emotionOrder = [
      'CALM',     // 평온
      'HAPPY',    // 기쁨
      'SAD',      // 슬픔
      'ANGRY',    // 분노
      'DISGUSTED',// 혐오
      'SURPRISED',// 놀람
      'FEAR',     // 두려움
      'CONFUSED'  // 혼란
    ];

    final emotionLabels = {
      'CALM': '평온',
      'HAPPY': '기쁨',
      'SAD': '슬픔',
      'ANGRY': '분노',
      'DISGUSTED': '혐오',
      'SURPRISED': '놀람',
      'FEAR': '두려움',
      'CONFUSED': '혼란'
    };

    final emotionImages = {
      'CALM': 'assets/mooding/mooding_calm.png',
      'HAPPY': 'assets/mooding/mooding_happy.png',
      'SAD': 'assets/mooding/mooding_sad.png',
      'ANGRY': 'assets/mooding/mooding_angry.png',
      'DISGUSTED': 'assets/mooding/mooding_disgusted.png',
      'SURPRISED': 'assets/mooding/mooding_surprised.png',
      'FEAR': 'assets/mooding/mooding_fear.png',
      'CONFUSED': 'assets/mooding/mooding_confused.png'
    };

    // 막대 차트 데이터
    List<Map<String, dynamic>> chartData = [];
    double total = emotionValues.values.fold(0, (a, b) => a + b);

    if (hasAnalysisData && total > 0) {
      for (var emotion in emotionOrder) {
        double value = (emotionValues[emotion] ?? 0.0) / total * 100;
        if (value > 0) {
          chartData.add({
            'name': emotion,
            'value': value,
            'color': emotions.firstWhere(
                    (e) => e['name'] == emotion,
                orElse: () => {'color': Colors.grey})['color']
          });
        }
      }
    } else {
      // 데이터가 없을 때
      chartData.add({
        'name': 'NO_DATA',
        'value': 100,
        'color': Colors.grey[300]!
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Padding(
          padding: EdgeInsets.only(left: 30),
          child: Text(
            '감정 분석 결과',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        SizedBox(height: 10),

        // 첫 번째 줄
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: emotionOrder.sublist(0,4).map((emotion) {

              double percentage = 0;
              if (hasAnalysisData && total > 0) {
                percentage = (emotionValues[emotion] ?? 0.0) / total * 100;
              }

              return Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 2,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Image.asset(
                        emotionImages[emotion]!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.error_outline),
                      ),
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    '${emotionLabels[emotion]} (${percentage.round()}%)', // 감정이름과 퍼센트
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 20),

        // 두 번째 줄
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: emotionOrder.sublist(4).map((emotion) {

              double percentage = 0;
              if (hasAnalysisData && total > 0) {
                percentage = (emotionValues[emotion] ?? 0.0) / total * 100;
              }

              return Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 2,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Image.asset(
                        emotionImages[emotion]!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.error_outline),
                      ),
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    '${emotionLabels[emotion]} (${percentage.round()}%)', // 감정이름과 퍼센트
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 20),

        // 100% 누적 막대 차트
        Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: 40,
          margin: EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(128),
                blurRadius: 5,
                spreadRadius: 2,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: chartData.map((data) {
                return Flexible(
                  flex: data['value'].round(),
                  child: Container(
                    color: data['color'],
                    child: Center(
                      child: data['value'] >= 5
                          ? Text(
                        '${data['value'].round()}%',
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      )
                          : SizedBox.shrink(),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        SizedBox(height: 20),
      ],
    );
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