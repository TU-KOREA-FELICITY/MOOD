import 'package:flutter/material.dart';

class MusicPreferenceScreen extends StatefulWidget {
  final Map<String, dynamic> userInfo;

  const MusicPreferenceScreen({Key? key, required this.userInfo})
      : super(key: key);

  @override
  _MusicPreferenceScreenState createState() => _MusicPreferenceScreenState();
}

class _MusicPreferenceScreenState extends State<MusicPreferenceScreen> {
  final List<String> categories = ['아티스트', '장르'];
  String selectedCategory = '아티스트';
  Set<String> selectedGenres = {};
  Set<String> selectedArtists = {};

  final Map<String, List<Map<String, String>>> genreArtists = {
    '국내 발라드': [
      {'name': '아이유 (IU)'},
      {'name': '멜로망스'},
      {'name': '다비치'},
      {'name': '폴킴'},
      {'name': '박효신'},
      {'name': '성시경'},
    ],
    '국내 댄스/일렉': [
      {'name': 'NewJeans'},
      {'name': 'BABYMONSTER'},
      {'name': 'ITZY (있지)'},
      {'name': 'RIIZE'},
      {'name': 'SHINee (샤이니)'},
      {'name': '2NE1'},
    ],
    '해외 팝': [
      {'name': 'Sabrina'},
      {'name': 'Charlie Puth'},
      {'name': 'Taylor Swift'},
      {'name': 'Billie Eilish'},
      {'name': 'Meghan Trainor'},
      {'name': 'Ed Sheeran'},
    ],
    '국내 힙합': [
      {'name': 'G-DRAGON'},
      {'name': '박재범'},
      {'name': '릴러말즈 (Leellamarz)'},
      {'name': '다이나믹 듀오'},
      {'name': 'CAMO'},
      {'name': 'Ash-B (애쉬비)'},
    ],
    '해외 힙합': [
      {'name': 'The Kid LAROI'},
      {'name': 'Doja Cat'},
      {'name': 'Drake'},
      {'name': 'Kendrick Lamar'},
      {'name': 'Cardi B'},
      {'name': 'Central Cee'},
    ],
    '국내 알앤비': [
      {'name': 'Crush'},
      {'name': '딘 (DEAN)'},
      {'name': 'SOLE(쏠)'},
      {'name': 'SUMIN(수민)'},
      {'name': '죠지'},
    ],
    '해외 알앤비': [
      {'name': 'The Weeknd'},
      {'name': 'SZA'},
      {'name': 'Bruno Mars'},
      {'name': 'Pink SweatS'},
      {'name': 'MAX'},
      {'name': 'Giveon'},
    ],
    '해외 일렉트로닉': [
      {'name': 'Peggy Gou'},
      {'name': 'Martin Garrix'},
      {'name': 'Galantis'},
      {'name': 'Sigala'},
      {'name': 'Daft Punk'},
      {'name': 'KSHMR'},
    ],
    '국내 록/메탈': [
      {'name': '나상현씨밴드'},
      {'name': 'LUCY'},
      {'name': '잔나비'},
      {'name': '검정치마'},
      {'name': '산울림'},
      {'name': '전인권'},
    ],
    '해외 메탈': [
      {'name': 'Metallica'},
      {'name': 'Linkin Park'},
      {'name': 'Rage Against The Machine'},
      {'name': 'Scorpions'},
      {'name': 'AC/DC'},
      {'name': 'Bon Jovi'},
    ],
    '해외 록': [
      {'name': 'Oasis'},
      {'name': 'Avril Lavigne'},
      {'name': 'Maroon 5'},
      {'name': 'Panic! At The Disco'},
      {'name': 'Nirvana'},
      {'name': 'The 1975'},
    ],
    '재즈': [
      {'name': '윤석철트리오'},
      {'name': 'Eddie Higgins Trio'},
      {'name': 'Bill Evans Trio'},
      {'name': 'Jamiroquai'},
      {'name': 'Keith Jarrett'},
      {'name': 'Nat King Cole'},
    ],
    'OST/BGM': [
      {'name': '이동준'},
      {'name': '이병우'},
      {'name': 'Hans Zimmer'},
    ],
    '클래식': [
      {'name': '조성진'},
      {'name': '손열음'},
      {'name': '대니 구'},
      {'name': 'Johann Sebastian Bach'},
      {'name': 'Erik Satie'},
    ],
    '국내 포크/블루스': [
      {'name': '김사월'},
      {'name': '옥상달빛'},
      {'name': '김현창'},
      {'name': '이문세'},
      {'name': '장필순'},
    ],
    '트로트': [
      {'name': '임영웅'},
      {'name': '나훈아'},
      {'name': '영탁'},
      {'name': '이찬원'},
      {'name': '송가인'},
      {'name': '양지은'},
    ],
  };

  final List<String> genres = [
    '국내 발라드',
    '국내 댄스/일렉',
    '해외 팝',
    '국내 힙합',
    '해외 힙합',
    '국내 알앤비',
    '해외 알앤비',
    '해외 일렉트로닉',
    '국내 록/메탈',
    '해외 록',
    '재즈',
    '해외 메탈',
    '국내 인디',
    '국내 포크/블루스',
    '클래식',
    '트로트',
    '뉴에이지',
    'CCM',
    'OST/BGM'
  ];

  void toggleGenre(String genre) {
    setState(() {
      if (selectedGenres.contains(genre)) {
        selectedGenres.remove(genre);
      } else {
        selectedGenres.add(genre);
      }
    });
  }

  void toggleArtist(String artist) {
    setState(() {
      if (selectedArtists.contains(artist)) {
        selectedArtists.remove(artist);
      } else {
        selectedArtists.add(artist);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '선호 장르 선택',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        titleSpacing: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(height: 15),
                Text(
                  '어떤 음악을 좋아하세요?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '취향을 선택하고 나에게 맞는 추천을 받아보세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: categories
                .map((category) => _buildFilterButton(
                      category,
                      category == selectedCategory,
                      () => setState(() => selectedCategory = category),
                    ))
                .toList(),
          ),
          SizedBox(height: 20),
          Expanded(
            child: selectedCategory == '장르'
                ? _buildGenreList()
                : _buildArtistList(),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 32.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: selectedCategory.isNotEmpty
                      ? () {
                          Navigator.pushReplacementNamed(
                            context,
                            '/spotify_login',
                            arguments: {
                              ...widget.userInfo,
                              'selectedGenres': selectedGenres.toList(),
                              'selectedArtists': selectedArtists.toList(),
                            },
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0126FA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('다음으로',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(
      String text, bool isSelected, VoidCallback onPressed) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Color(0xFF4B48FF) : Colors.grey[200],
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildGenreList() {
    return ListView.builder(
      itemCount: (genres.length / 3).ceil(),
      itemBuilder: (context, index) {
        int startIndex = index * 3;
        int endIndex =
            (startIndex + 3 < genres.length) ? startIndex + 3 : genres.length;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: genres
                .sublist(startIndex, endIndex)
                .map((genre) => _buildGenreCircleItem(genre))
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildGenreCircleItem(String genre) {
    bool isSelected = selectedGenres.contains(genre);
    return GestureDetector(
      onTap: () => toggleGenre(genre),
      child: Container(
        width: 100,
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? Color(0xFF4B48FF)
                    : Color(0xFF4B48FF).withOpacity(0.1),
              ),
              child: Center(
                child: Icon(
                  Icons.music_note,
                  color: isSelected ? Colors.white : Color(0xFF4B48FF),
                  size: 30,
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              genre,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Color(0xFF4B48FF) : Colors.black,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistList() {
    return ListView.builder(
      itemCount: genreArtists.length,
      itemBuilder: (context, index) {
        String genre = genreArtists.keys.elementAt(index);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                genre,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: genreArtists[genre]!
                  .map((artist) => _buildArtistItem(artist))
                  .toList(),
            ),
            SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildArtistItem(Map<String, String> artist) {
    bool isSelected = selectedArtists.contains(artist['name']);
    return GestureDetector(
      onTap: () => toggleArtist(artist['name']!),
      child: Container(
        width: 100,
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? Color(0xFF4B48FF)
                    : Color(0xFF4B48FF).withOpacity(0.1),
              ),
              child: Icon(
                Icons.person,
                color: isSelected ? Colors.white : Color(0xFF4B48FF),
                size: 30,
              ),
            ),
            SizedBox(height: 8),
            Text(
              artist['name']!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Color(0xFF4B48FF) : Colors.black,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
