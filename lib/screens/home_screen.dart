import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
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
  WebSocketChannel? _channel;
  WebSocketChannel? _warningChannel;
  String _concentrationResult = '결과 없음';
  Uint8List? _imageData;
  String _warningMessage = '';

  @override
  void initState() {
    super.initState();
    _startConcentrationMonitoring();
    _connectWarningWebSocket();
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
      }, onDone: () {
        print('WebSocket connection closed');
        _updateConcentrationResult('연결 종료');
      });
    } catch (e) {
      print('WebSocket connection error: $e');
      _updateConcentrationResult('연결 실패');
    }
  }

  void _connectWarningWebSocket() {
    try {
      print('Attempting to connect to warning WebSocket...');
      _warningChannel = WebSocketChannel.connect(Uri.parse('ws://10.0.2.2:3002'));
      _warningChannel!.stream.listen((message) {
        _handleWarningWebSocketMessage(message);
      }, onError: (error) {
        print('Warning WebSocket error: $error');
      }, onDone: () {
        print('Warning WebSocket connection closed');
      });
    } catch (e) {
      print('Warning WebSocket connection error: $e');
    }
  }

  void _handleWebSocketMessage(dynamic message) {
    print('Received message: $message');
    if (message is String && message.startsWith('data:image/jpeg;base64,')) {
      final base64String = message.split(',')[1];
      setState(() {
        _imageData = base64Decode(base64String);
      });
    } else if (message is String) {
      _updateConcentrationResult(message);
    }
  }

  void _handleWarningWebSocketMessage(dynamic message) {
    print('Received warning message: $message');
    final decodedMessage = jsonDecode(message);
    if (decodedMessage['level'] != null) {
      setState(() {
        _warningMessage = 'Warning: ${decodedMessage['level']} ${decodedMessage['axis']} error ${decodedMessage['error']}';
      });
    }
  }

  void _updateConcentrationResult(String result) {
    if (mounted) {
      setState(() {
        _concentrationResult = result;
      });
    }
  }

  @override
  void dispose() {
    _channel?.sink.close(status.goingAway);
    _warningChannel?.sink.close(status.goingAway);
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
    return Column(
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
                  ? Image.memory(_imageData!)
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
        Expanded(
          child: Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: EdgeInsets.only(right: 60, bottom: 200),
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
        ),
      ],
    );
  }
}