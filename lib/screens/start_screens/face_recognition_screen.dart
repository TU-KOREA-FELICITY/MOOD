import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:typed_data';
import 'dart:convert';

class FaceRecognitionScreen extends StatefulWidget {
  @override
  State<FaceRecognitionScreen> createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _regComplete = false;
  String? userId;
  String _status = '';
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
      _register();
    });
  }

  @override
  void dispose() {
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

  void _register() async {
    final TextEditingController controller = TextEditingController();
    final username = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('사용자 아이디 입력'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: "사용자 아이디를 입력하세요"),
        ),
        actions: [
          TextButton(
            child: Text('확인'),
            onPressed: () => Navigator.of(context).pop(controller.text),
          ),
        ],
      ),
    );

    if (username != null && username.isNotEmpty) {
      setState(() {
        _status = '얼굴 등록 중...';
      });
      try {
        final response = await http.post(
          Uri.parse('http://10.0.2.2:3000/register'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'username': username}),
        );
        _checkRegistrationStatus();
      } catch (e) {
        setState(() {
          _status = '등록 시작 오류: $e';
        });
      }
    }
  }

  void _checkRegistrationStatus() async {
    try {
      final response =
          await http.get(Uri.parse('http://10.0.2.2:3000/check_registration'));
      final result = json.decode(response.body);
      if (result['registered'] == true) {
        setState(() {
          _status = '등록 성공! 사용자 ID: ${result['user_id']}';
          _regComplete = true;
          userId = result['user_id'];
        });
      } else {
        Future.delayed(Duration(seconds: 2), _checkRegistrationStatus);
      }
    } catch (e) {
      setState(() {
        _status = '등록 상태 확인 오류: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: 100),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '얼굴등록을 시작합니다.',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 40),
                  GestureDetector(
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
                              : Icon(
                                  Icons.person,
                                  size: 170,
                                  color: Colors.black,
                                ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
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
                  SizedBox(height: 20),
                  if (_regComplete)
                    Container(
                      width: MediaQuery.of(context).size.width * 0.7,
                      child: ElevatedButton(
                        onPressed: () {
                          // 변경: 회원가입 화면으로 이동하는 로직 수정
                          Navigator.pushNamed(
                            context,
                            '/signup',
                            arguments: userId,
                          );
                        },
                        style: ButtonStyle(
                          backgroundColor:
                              WidgetStateProperty.all(Color(0xFF0126FA)),
                          foregroundColor:
                              WidgetStateProperty.all(Colors.white),
                          padding: WidgetStateProperty.all(
                              EdgeInsets.symmetric(vertical: 12)),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        child: Text(
                          '얼굴 등록 완료',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
