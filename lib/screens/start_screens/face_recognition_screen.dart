import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:typed_data';
import 'dart:convert';

class FaceRecognitionScreen extends StatefulWidget {
  final String userId;

  const FaceRecognitionScreen({super.key, required this.userId});

  @override
  State<FaceRecognitionScreen> createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  bool _regNotComplete = true;
  bool _buttonShow = false;
  String? userId;
  String _status = '';
  IO.Socket? socket;
  Uint8List? imageBytes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    setState(() {
      _status = '마스크 또는 선글라스를 벗고\n카메라를 응시해주세요.';
    });
    connectToServer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptForUserId();
    });
  }

  @override
  void dispose() {
    socket?.dispose();
    super.dispose();
  }

  void connectToServer() {
    try {
      socket = IO.io('http://192.168.60.219:3000', <String, dynamic>{
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

  Future<Map<String, dynamic>> _checkIdDuplicate(String userAwsId) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.60.219:3000/check_id_duplicate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_aws_id': userAwsId}),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return {
          'success': result['success'],
          'message': result['message'],
          'isDuplicate': result['isDuplicate'],
          'user_aws_id': result['user_aws_id'],
        };
      } else {
        return {
          'success': false,
          'message': '서버 오류: \n${response.statusCode}',
          'isDuplicate': null,
          'user_aws_id': userAwsId,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'FACE ID 중복 확인 중 오류 발생: \n$e',
        'isDuplicate': null,
        'user_aws_id': userAwsId,
      };
    }
  }

  void _promptForUserId() async {
    final TextEditingController controller = TextEditingController();
    final username = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        title: Text('FACE ID 이름 설정하기'),
        content: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: 50,
          child: TextField(
          controller: controller,
          autofocus: true,
            decoration: InputDecoration(hintText: "영문으로 입력해 주세요"),
          ),
        ),
        actions: [
          TextButton(
            child: Text('다음', style: TextStyle(color: Color(0xFF0126FA))),
            onPressed: () => Navigator.of(context).pop(controller.text),
          ),
        ],
      ),
    );

    if (username == null || username.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'FACE ID 중복 확인 중...';
    });

    final result = await _checkIdDuplicate(username);

    if (result['success'] && !result['isDuplicate']) {
      setState(() {
        userId = username;
        _status = 'FACE ID를 등록 중 입니다.\n잠시만 기다려 주세요!';
        _isLoading = false;
      });
      _register(username);
      return;
    } else if (result['isDuplicate']) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('중복된 ID'),
          content: Text('이미 사용 중인 ID입니다.\n다른 ID를 입력해주세요.'),
          actions: [
            TextButton(
              child: Text('확인'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
      setState(() {
        _isLoading = true;
        _status = 'FACE ID를 등록 중 입니다.\n잠시만 기다려 주세요!';
      });
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('오류'),
          content: Text(result['message']),
          actions: [
            TextButton(
              child: Text('확인'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _register(String username) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.60.219:3000/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username}),
      );

      final responseData = json.decode(response.body);

      if (responseData['success'] == true) {
        _checkRegistrationStatus(username);
      } else {
        setState(() {
          _status = 'FACE ID 등록을 다시 시도해주세요.';
          _buttonShow = true;
        });
      }
    } catch (e) {
      setState(() {
        _status = '등록 시작 오류: \n$e';
      });
    }
  }

  void _checkRegistrationStatus(String username) async {
    try {
      final response =
          await http.get(Uri.parse('http://192.168.60.219:3000/check_registration'));
      final result = json.decode(response.body);

      if (result != null && result['registered'] == true) {
        setState(() {
          _status = '${result['user_id']} ID로 얼굴 등록에 성공했습니다.';
          _regNotComplete = false;
          userId = username;
          _buttonShow = false;
        });
      } else {
        Future.delayed(
            Duration(seconds: 2), () => _checkRegistrationStatus(username));
      }
    } catch (e) {
      setState(() {
        _status = 'FACE ID 등록에 실패했습니다.';
        _buttonShow = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(height: 120),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'FACE ID 등록을 시작합니다',
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
                                border: Border.all(
                                    color: Color(0xFF0126FA), width: 6),
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
                                              color: Color(0xFF0126FA),
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
                              textAlign: TextAlign.center,
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
                  alignment: Alignment(0, 0.8),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 80.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_regNotComplete && !_buttonShow)
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.7,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _status = 'FACE ID를 등록 중 입니다.\n잠시만 기다려 주세요!';
                                });
                                _promptForUserId();
                              },
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all(
                                    const Color(0xFF0126FA)),
                                foregroundColor:
                                    WidgetStateProperty.all(Colors.white),
                                padding: WidgetStateProperty.all(
                                    const EdgeInsets.symmetric(vertical: 12)),
                                shape: WidgetStateProperty.all(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                              child: const Text(
                                'FACE ID 등록하기',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        if (!_regNotComplete && !_buttonShow)
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.7,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/signup',
                                  arguments: userId,
                                );
                              },
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all(
                                    const Color(0xFF0126FA)),
                                foregroundColor:
                                    WidgetStateProperty.all(Colors.white),
                                padding: WidgetStateProperty.all(
                                    const EdgeInsets.symmetric(vertical: 12)),
                                shape: WidgetStateProperty.all(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                              child: const Text(
                                'FACE ID 등록 완료',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        if (_regNotComplete && _buttonShow)
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.7,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _status = 'FACE ID를 등록 중 입니다.\n잠시만 기다려 주세요!';
                                });
                                _promptForUserId();
                              },
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all(
                                    const Color(0xFF0126FA)),
                                foregroundColor:
                                    WidgetStateProperty.all(Colors.white),
                                padding: WidgetStateProperty.all(
                                    const EdgeInsets.symmetric(vertical: 12)),
                                shape: WidgetStateProperty.all(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                              child: const Text(
                                'FACE ID 다시 만들기',
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
