import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:typed_data';
import 'dart:convert';
import '../homestart_screens/home_screen.dart';
import 'welcome_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _status = '';
  String? userId;
  late bool _authNotComplete = true;
  IO.Socket? socket;
  Uint8List? imageBytes;

  @override
  void initState() {
    super.initState();
    setState(() {
      _status = '마스크 또는 선글라스를 벗고\n카메라를 응시해주세요.';
    });
    connectToServer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _login();
    });
  }

  @override
  void dispose() {
    _authNotComplete = false;
    socket?.dispose();
    super.dispose();
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
            if (data is String) {
              imageBytes = Uint8List.fromList(base64Decode(data));
            } else if (data is List<int>) {
              imageBytes = Uint8List.fromList(data);
            }
          });
        }
      });

      socket!.onDisconnect((_) => print('서버와 연결이 끊어졌습니다.'));
      socket!.onError((err) => print('에러 발생: $err'));

      socket!.connect();
    } catch (e) {
      print('서버 연결 중 오류 발생: $e');
    }
  }

  void _login() async {
    setState(() {
      _status = '얼굴 인증 중...';
    });
    try {
      await http.post(Uri.parse('http://10.0.2.2:3000/login'));
      _checkAuthStatus();
    } catch (e) {
      setState(() {
        _status = '인증 시작 오류: $e';
      });
    }
  }

  void _checkAuthStatus() async {
    try {
      final response =
          await http.get(Uri.parse('http://10.0.2.2:3000/check_auth'));
      final result = json.decode(response.body);
      if (!mounted) return;
      if (result['authenticated'] == true) {
        setState(() {
          _status = '인증 성공! 사용자 ID: ${result['user_id']}';
          userId = result['user_id'];
        });
        // 인증 성공 시 WelcomeScreen으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WelcomeScreen(userId: result['user_id']),
          ),
        );
      } else {
        if (mounted) {
          Future.delayed(Duration(seconds: 2), _checkAuthStatus);
          setState(() {
            _status = '인증 실패! 사용자 ID: null';
            userId = null;
            _authNotComplete = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = '인증 상태 확인 오류: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: EdgeInsets.only(left: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.login),
              SizedBox(width: 8),
              Text(
                '로그인',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '얼굴인식을 진행합니다.',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 40),
                  GestureDetector(
                    // 임시 로그인 경로
                    onTap: () {
                      Navigator.of(context).pushReplacementNamed('/home');
                    },
                    child: SizedBox(
                      width: 260,
                      height: 260,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFF2F2F1),
                          border:
                              Border.all(color: Color(0xFF2265F0), width: 6),
                        ),
                        child: ClipOval(
                          child: imageBytes != null
                              ? Image.memory(
                                  imageBytes!,
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                )
                              : Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 260,
                                      height: 260,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 10,
                                        color: Color(0xFF2265F0),
                                      ),
                                    ),
                                    Icon(
                                      Icons.person,
                                      size: 170,
                                      color: Colors.black,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _status,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF97BCF3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 50.0, bottom: 200.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/signup',
                    arguments: userId,
                  );
                },
                child: Text(
                  '회원가입',
                  style: TextStyle(
                    fontSize: 19.0,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ),
          if (!_authNotComplete)
            Container(
              width: MediaQuery.of(context).size.width * 0.7,
              child: ElevatedButton(
                onPressed: () {
                  _login();
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Color(0xFF0126FA)),
                  foregroundColor: WidgetStateProperty.all(Colors.white),
                  padding: WidgetStateProperty.all(
                      EdgeInsets.symmetric(vertical: 12)),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                child: Text(
                  '다시 시도하기',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
