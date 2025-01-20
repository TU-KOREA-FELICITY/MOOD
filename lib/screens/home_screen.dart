import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'bottom_navigation_widget.dart';
import 'home_recognition_screen.dart';
import 'package:jsg/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  IO.Socket? socket;
  WebSocketChannel? _channel;
  String _concentrationResult = '결과 없음';
  Uint8List? _imageData;
  String _warningMessage = '';
  String _emotionResult = '감정 분석 결과 없음';

  @override
  void initState() {
    super.initState();
    connectToServer();
    _startConcentrationMonitoring();
  }

  void connectToServer() {
    try {
      socket = IO.io('http://10.0.2.2:3001', <String, dynamic>{
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
          _warningMessage = 'Warning: ${data['level']} ${data['axis']} error ${data['error']}';
        });
      });

      socket!.onDisconnect((_) => print('서버와 연결이 끊어졌습니다.'));
      socket!.onError((err) => print('에러 발생: $err'));

      socket!.connect();
    } catch (e) {
      print('서버 연결 중 오류 발생: $e');
    }
  }

  Future<void> _startConcentrationMonitoring() async {
    try {
      print('Attempting to connect to WebSocket...');
      _channel = WebSocketChannel.connect(Uri.parse('ws://10.0.2.2:5000'));
      _channel!.stream.listen((message) {
        _handleWebSocketMessage(message);
      }, onError: (error) {
        print('WebSocket error: $error');
        _updateConcentrationResult('연결 오류');
        _retryWebSocketConnection();
      }, onDone: () {
        print('WebSocket connection closed');
        _updateConcentrationResult('연결 종료');
        _retryWebSocketConnection();
      });
    } catch (e) {
      print('WebSocket connection error: $e');
      _updateConcentrationResult('연결 실패');
      _retryWebSocketConnection();
    }
  }

  void _retryWebSocketConnection() {
    Future.delayed(Duration(seconds: 5), () {
      _startConcentrationMonitoring();
    });
  }

  void _handleWebSocketMessage(dynamic message) {
    print('Received message: $message');
    if (message is String) {
      _updateConcentrationResult(message);
    }
  }

  void _updateConcentrationResult(String result) {
    if (mounted) {
      setState(() {
        _concentrationResult = result;
      });
    }
  }

  Future<void> _analyzeEmotion() async {
    try {
      // 감정 분석 시작 요청을 서버로 보냄
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/analyze_emotion'), // 감정 분석 서버는 포트 3000
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(utf8.decode(response.bodyBytes)); // UTF-8로 디코딩
        setState(() {
          _emotionResult = _formatEmotionResult(result['result']);
        });
      } else {
        setState(() {
          _emotionResult = '감정 분석 실패';
        });
      }
    } catch (e) {
      setState(() {
        _emotionResult = '서버 연결 오류';
      });
    }
  }

  String _formatEmotionResult(dynamic result) {
    if (result is Map) {
      return result.entries.map((entry) => '${entry.key}: ${entry.value.toStringAsFixed(2)}%').join('\n');
    }
    return result.toString();
  }

  @override
  void dispose() {
    _channel?.sink.close(status.goingAway);
    socket?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(
        child: _getBody(),
      ),
      bottomNavigationBar: BottomNavigationWidget(
        onTabChange: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
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
        Icon(icon, color: Colors.black),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ],
    );
  }

  Widget _getBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return Center(child: Text('검색 화면', style: TextStyle(fontSize: 24)));
      case 2:
        return ProfileScreen();
      default:
        return _buildHomeContent();
    }
  }

  void _restartRecognition() {
    setState(() {
      // 화면을 다시 시작하는 로직을 여기에 구현합니다.
    });
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 55, top: 60, bottom: 20),
            child: Row(
              children: [
                Text(
                  '감정/집중도 인식중',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 10),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF014FFA)),
                    strokeWidth: 3.5,
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomeRecognitionScreen()),
                );
              },
              child: Container(
                width: 300,
                height: 400,
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFF014FFA), width: 3),
                ),
                child: _imageData != null
                    ? Image.memory(
                  _imageData!,
                  gaplessPlayback: true,
                )
                    : Center(
                  child: Text('카메라 화면이 여기에 표시됩니다'),
                ),
              ),
            ),
          ),
          if (_warningMessage.isNotEmpty)
            Center(
              child: Text(
                _warningMessage,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ),
          Center(
            child: Text(
              '집중도 인식 결과: $_concentrationResult',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: ElevatedButton(
              onPressed: _analyzeEmotion,
              child: Text('감정 분석 시작'),
            ),
          ),
          Center(
            child: Text(
              _emotionResult,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 60, bottom: 20),
            child: Align(
              alignment: Alignment.bottomRight,
              child: GestureDetector(
                onTap: _restartRecognition,
                child: Text(
                  '다시시도하기',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}