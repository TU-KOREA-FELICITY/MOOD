import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:mood/screens/bottom_navigation_widget.dart';
import 'package:mood/screens/homestart_screens/home_recognition_screen.dart';
import 'package:mood/screens/profilestart_screens/profile_screen.dart';
import 'package:mood/screens/searchstart_screens/search_screen.dart';
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
      _emotionResult = '감정 분석 중...';
    });
    final url = Uri.parse('http://10.0.2.2:3000/analyze_emotion');
    try {
      final response = await http.post(url);
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body)['result'];
        setState(() {
          _emotionResult = result;
        });
      } else {
        print('aws-face-reg.py 실행 실패: ${response.statusCode}');
        print('서버 응답: ${response.body}');
        setState(() {
          _emotionResult = '감정 분석 실패';
        });
      }
    } catch (e) {
      print('aws-face-reg.py 실행 중 오류 발생: $e');
      setState(() {
        _emotionResult = '서버 연결 오류: $e';
      });
    }
  }

  void _restartRecognition() {
    setState(() {
      _imageData = null;
      _warningMessage = '';
      _emotionResult = '';
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
            child: Text(
              '감정 분석 결과: $_emotionResult',
              style: TextStyle(fontSize: 16),
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
