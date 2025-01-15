import 'package:flutter/material.dart';

class MusicPreferenceScreen extends StatefulWidget {
  @override
  _MusicPreferenceScreenState createState() => _MusicPreferenceScreenState();
}

class _MusicPreferenceScreenState extends State<MusicPreferenceScreen> {
  final List<String> genres = [
    '국내 발라드', '국내 댄스/일렉', '국내 힙합', '국내 알앤비', '국내 인디', 'OST/BGM',
    '해외 팝', '해외 알앤비', '해외 힙합', '트로트', '키즈', '클래식', '재즈','맘/태교',
    '종교 음악', '뉴에이지', '국내 팝/어쿠스틱', '록/메탈', 'J-POP', '국악'
  ];

  List<String> selectedGenres = [];

  final List<Color> buttonColors = [
    Color(0xFFF2FAFE)!, Color(0xFFF2FAFE)!, Color(0xFFF2FAFE)!, Color(0xFFF2FAFE)!,
    Color(0xFFF2FAFE)!, Color(0xFFF2FAFE)!, Color(0xFFF2FAFE)!, Color(0xFFF2FAFE)!,
    Color(0xFFF2FAFE)!, Color(0xFFF2FAFE)!, Color(0xFFF2FAFE)!, Color(0xFFF2FAFE)!,
    Color(0xFFF2FAFE)!, Color(0xFFF2FAFE)!, Color(0xFFF2FAFE)!, Color(0xFFF2FAFE)!,
    Color(0xFFF2FAFE)!, Color(0xFFF2FAFE)!, Color(0xFFF2FAFE)!, Color(0xFFF2FAFE)!,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '선호하는 장르 선택',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        titleSpacing: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 0, 16.0, 16.0),
            child: Text(
              '선호하는 음악 장르를 모두 선택하시오',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20.0,
                  mainAxisSpacing: 20.0,
                  childAspectRatio: 3.0,
                ),
                itemCount: genres.length,
                itemBuilder: (context, index) {
                  final genre = genres[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (selectedGenres.contains(genre)) {
                          selectedGenres.remove(genre);
                        } else {
                          selectedGenres.add(genre);
                        }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: selectedGenres.contains(genre)
                            ? Colors.indigo[300]
                            : buttonColors[index % buttonColors.length],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        genre,
                        style: TextStyle(
                          color: selectedGenres.contains(genre) ? Colors.white : Colors.black,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 32.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: selectedGenres.isNotEmpty
                      ? () {
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0126FA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('회원가입 완료', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                    color: Colors.white,)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
