import 'package:flutter/material.dart';

class MusicPreferenceScreen extends StatefulWidget {
  @override
  _MusicPreferenceScreenState createState() => _MusicPreferenceScreenState();
}

class _MusicPreferenceScreenState extends State<MusicPreferenceScreen> {
  final List<String> genres = [
    '국내발라드', '국내 댄스와 일렉', '국내 힙합', '해외 알앤비', 'OST/BGM', '국내 인디',
    '해외팝', '국내 알랜비', '트로트', '해외 힙합', '키즈', '클래식', '재즈',
    '국내 포크/블루스', '해외 일레트로닉', '해외 메탈', '맘/태교', '월드뮤직',
    '종교음악', '뉴에이지', '국내 팝/어쿠스틱', '국내 록/메탈', '해외 록', 'J-POP',
    'CCM', '국악'
  ];

  List<String> selectedGenres = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('음악 취향 선택'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '선호하는 음악 취향을 모두 선택하세요',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: genres.length,
              itemBuilder: (context, index) {
                final genre = genres[index];
                return CheckboxListTile(
                  title: Text(genre),
                  value: selectedGenres.contains(genre),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value!) {
                        selectedGenres.add(genre);
                      } else {
                        selectedGenres.remove(genre);
                      }
                    });
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: selectedGenres.isNotEmpty
                  ? () {
                // 회원가입 완료 로직 구현
                Navigator.pushReplacementNamed(context, '/main');
              }
                  : null,
              child: Text('회원가입 완료'),
            ),
          ),
        ],
      ),
    );
  }
}
