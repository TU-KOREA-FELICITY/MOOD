import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mood/screens/homestart_screens/home_screen.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:typed_data';
import 'dart:convert';
import '../bottom_navigation_widget.dart';
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
      socket = IO.io('http://192.168.189.219:3000', <String, dynamic>{
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
      socket!.onError((err) => print('에러 발생: \n$err'));

      socket!.connect();
    } catch (e) {
      print('서버 연결 중 오류 발생: \n$e');
    }
  }

  void _login() async {
    setState(() {
      _status = '마스크 또는 선글라스를 벗고\n카메라를 응시해주세요.';
    });
    try {
      await http.post(Uri.parse('http://192.168.189.219:3000/login'));
      _checkAuthStatus();
    } catch (e) {
      setState(() {
        _status = '로그인 오류';
      });
    }
  }

  void _checkAuthStatus() async {
    try {
      final response =
      await http.get(Uri.parse('http://192.168.189.219:3000/check_auth'));
      final result = json.decode(response.body);

      if (!mounted) return;
      if (result != null && result['authenticated'] == true) {
        try {
          final loginResult = await _loginComplete(result['user_id']);

          if (loginResult['success']) {
            setState(() {
              _status = '인증에 성공했습니다.\n사용자 이름: ${loginResult['user_name']}';
            });
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    WelcomeScreen(userInfo: loginResult['user']),
              ),
            );
          } else {
            setState(() {
              _status = '인증 실패! \n${loginResult['message']}';
              _authNotComplete = false;
            });
          }
        } catch (e) {
          setState(() {
            _status = '로그인 완료 중 오류';
            _authNotComplete = false;
          });
        }
      } else {
        if (mounted) {
          Future.delayed(Duration(seconds: 2), _checkAuthStatus);
          setState(() {
            _status = '인증에 실패했습니다.\n다시 시도해주세요.';
            _authNotComplete = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = '인증 상태 확인 오류';
          _authNotComplete = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>> _loginComplete(String userAwsId) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.189.219:3000/login_complete'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_aws_id': userAwsId}),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success']) {
          return {
            'success': true,
            'user': result['user'],
          };
        } else {
          return {
            'success': false,
            'message': result['message'] ?? '알 수 없는 오류가 발생했습니다.',
          };
        }
      } else {
        return {
          'success': false,
          'message': '서버 오류: \n${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '로그인 완료 중 오류 발생',
      };
    }
  }

  Future<void> _saveUserInfoAndNavigate() async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.189.219:3000/register_complete'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_aws_id': 'sun2',
          'username': '장인선',
          'car_type': 'bmw',
          'fav_genre': '국내 발라드',
          'fav_artist': '아이유',
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        var user_id = responseBody['user_id'];

        final userInfo = {
          'user_id': user_id,
          'user_aws_id': 'sun2',
          'user_name': '장인선',
          'car_type': 'bmw',
          'fav_genre': '국내 발라드',
          'fav_artist': '아이유',
        };

        // BottomNavigationWidget으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BottomNavigationWidget(userInfo: userInfo),
          ),
        );
      } else {
        setState(() {
          _status = '사용자 정보 삽입 오류';
        });
      }
    } catch (e) {
      setState(() {
        _status = '사용자 정보 삽입 오류';
      });
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '로그인',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        titleSpacing: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 40),
                Padding(
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
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 40),
                      GestureDetector(
                        // 임시 로그인 경로
                        onTap: () {
                          _saveUserInfoAndNavigate();
                        },
                        child: SizedBox(
                          width: 260,
                          height: 260,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFF6F5FF),
                              border: Border.all(color: Color(0xFF8C88D5), width: 6),
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
                                      strokeWidth: 6,
                                      color: Color(0xFF8C88D5),
                                    ),
                                  ),
                                  Icon(
                                    Icons.person,
                                    size: 170,
                                    color: Color(0xFF6A698C),
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
                          Expanded(
                            child: Text(
                              _status,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6A698C),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 40),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 50.0, bottom: 150.0),
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
                          fontSize: 20,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 30),
              ],
            ),
          ),
          if (!_authNotComplete)
            Positioned(
              left: 0,
              right: 0,
              bottom: 80,
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _status = '다시 시도 중...';
                        _authNotComplete = true;
                      });
                      _login();
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Color(0xFF8C88D5)),
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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