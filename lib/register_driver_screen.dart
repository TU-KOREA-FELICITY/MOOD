import 'package:flutter/material.dart';

void main() => run

class RegisterDriverScreen extends StatefulWidget {
  @override
  _RegisterDriverScreenState createState() => _RegisterDriverScreenState();
}

class _RegisterDriverScreenState extends State<RegisterDriverScreen> {
  String? _selectedImage; // 사진 경로
  String? _driverName; // 사용자 이름
  String? _carModel; // 차종
  List<String> _selectedGenres = []; // 선택한 음악 취향

  // 음악 장르 목록
  final List<String> _musicGenres = [
    '국내발라드',
    '국내 댄스와 일렉',
    '국내 힙합',
    '해외 알앤비',
    'OST/BGM',
    '국내 인디',
    '해외팝',
    '국내 알랜비',
    '트로트',
    '해외 힙합',
    '키즈',
    '클래식',
    '재즈',
    '국내 포크/블루스',
    '해외 일레트로닉',
    '해외 메탈',
    '맘/태교',
    '월드뮤직',
    '종교음악',
    '뉴에이지',
    '국내 팝/어쿠스틱',
    '국내 록/메탈',
    '해외 록',
    'J-POP',
    'CCM',
    '국악',
  ];

  // 사진 선택 (임시 모달)
  void _pickImage() {
    // 이 코드는 실제 이미지 선택 로직과 연결해야 함
    setState(() {
      _selectedImage = 'assets/sample_image.jpg'; // 샘플 경로
    });
  }

  // 저장 버튼 클릭 시 처리
  void _saveDriver() {
    if (_driverName == null || _carModel == null || _selectedGenres.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('모든 정보를 입력해주세요!')),
      );
      return;
    }

    // 저장 로직 추가 필요
    print('운전자 등록 완료:');
    print('이름: $_driverName');
    print('차종: $_carModel');
    print('선호 음악 장르: $_selectedGenres');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('운전자 등록'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 사진 선택
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: _selectedImage != null
                        ? AssetImage(_selectedImage!)
                        : null,
                    child: _selectedImage == null
                        ? Icon(Icons.camera_alt, size: 40)
                        : null,
                  ),
                ),
              ),
              SizedBox(height: 20),

              // 이름 입력
              TextField(
                decoration: InputDecoration(
                  labelText: '이름 입력',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _driverName = value;
                },
              ),
              SizedBox(height: 20),

              // 차종 입력
              TextField(
                decoration: InputDecoration(
                  labelText: '차종 입력',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _carModel = value;
                },
              ),
              SizedBox(height: 20),

              // 음악 취향 선택
              Text(
                '선호 음악 장르 선택:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _musicGenres.map((genre) {
                  final isSelected = _selectedGenres.contains(genre);
                  return ChoiceChip(
                    label: Text(genre),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedGenres.add(genre);
                        } else {
                          _selectedGenres.remove(genre);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 20),

              // 저장 버튼
              Center(
                child: ElevatedButton(
                  onPressed: _saveDriver,
                  child: Text('운전자 등록'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
