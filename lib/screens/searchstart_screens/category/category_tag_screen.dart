// 검색 홈 (감정 카테고리 & 내 플레이리스트 탭)
//블루 0xFF265F0

import 'package:flutter/material.dart';
import '../search/playlist_tracks_screen.dart';
import '../service/spotify_service.dart';

class CategoryTagScreen extends StatefulWidget {
  final SpotifyService spotifyService;
  final Map<String, dynamic> userInfo;
  final List<Map<String, dynamic>> emotionInfo;

  const CategoryTagScreen({
    super.key,
    required this.spotifyService,
    required this.userInfo,
    required this.emotionInfo,
  });

  @override
  _CategoryTagScreenState createState() => _CategoryTagScreenState();
}

class _CategoryTagScreenState extends State<CategoryTagScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _playlists = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPlaylists();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updatePlaylistTrackCount(String playlistId, int newCount) {
    setState(() {
      final index =
          _playlists.indexWhere((playlist) => playlist['id'] == playlistId);
      if (index != -1) {
        _playlists[index]['tracks']['total'] = newCount;
      }
    });
  }

  //플레이리스트 내 트랙
  void _showPlaylistTracks(String playlistId, String playlistName) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistTracksScreen(
          spotifyService: widget.spotifyService,
          playlistId: playlistId,
          playlistName: playlistName,
          isEmotionPlaylist: true,
          onPlaylistUpdated: _updatePlaylistTrackCount,
        ),
      ),
    );
    await _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    setState(() {
      _isLoading = true; // 로딩 시작
    });
    try {
      List<dynamic> playlists = await widget.spotifyService.getPlaylists();
      List<String> emotionNames = widget.emotionInfo
          .map((emotion) => emotion['emotion'] as String)
          .toList();

      for (String emotion in emotionNames) {
        bool playlistExists =
        playlists.any((playlist) => playlist['name'] == emotion);
        if (!playlistExists) {
          // 해당 감정의 플레이리스트가 없으면 새로 생성
          String newPlaylistId =
          await widget.spotifyService.createPlaylist(emotion);
          playlists.add({'name': emotion, 'id': newPlaylistId, 'tracks': {'total': 0}}); // tracks 초기화
        }
      }

      // 기존 플레이리스트 정보 업데이트
      for (var playlist in playlists) {
        int trackCount =
        await widget.spotifyService.updatePlaylistInfo(playlist['id']);
        playlist['tracks'] = {'total': trackCount};
      }

      setState(() {
        _playlists = playlists;
      });
    } catch (e) {
      print('플레이리스트 로딩 중 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('플레이리스트 로딩 실패: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getColorForEmotion(String emotion) {
    switch (emotion) {
      case '행복':
        return Colors.yellow[300]!;
      case '슬픔':
        return Colors.blue[300]!;
      case '분노':
        return Colors.red[300]!;
      case '놀람':
        return Colors.purple[300]!;
      case '혐오':
        return Colors.green[300]!;
      case '공포':
        return Colors.black54;
      case '평온':
        return Colors.grey[300]!;
      case '혼란':
        return Colors.orange[300]!;
      default:
        return Colors.grey[300]!;
    }
  }

  Future<void> _deletePlaylist(String playlistId) async {
    try {
      await widget.spotifyService.deletePlaylist(playlistId);
      await _loadPlaylists();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('플레이리스트가 삭제되었습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('플레이리스트 삭제 실패: $e')),
      );
    }
  }

  Future<void> _addTracksToEmotionPlaylist(
      String emotion, String playlistId, String emotionTag) async {
    try {
      // 1. 태그로 플레이리스트 검색
      Map searchResults = await widget.spotifyService.searchPlaylists(emotionTag);

      // 검색 결과가 있는지 확인
      if (searchResults['playlists'] != null &&
          searchResults['playlists'].isNotEmpty) {
        List<dynamic> playlists = searchResults['playlists'];
        // 검색된 플레이리스트를 순회하며 트랙을 추가 시도
        for (int i = 0; i < playlists.length; i++) {
          String sourcePlaylistId = playlists[i]['id'];
          try {
            // 2. 플레이리스트의 트랙 가져오기 (최대 20개)
            List tracks =
            await widget.spotifyService.getPlaylistTracks(sourcePlaylistId);
            List<String> trackUrisToAdd = tracks
                .take(20)
                .map((track) => track['track']['uri'] as String)
                .where((uri) => uri.startsWith('spotify:track:'))
                .toList();

            // 3. 현재 감정 카테고리 플레이리스트에 트랙 추가
            if (trackUrisToAdd.isNotEmpty) {
              // 플레이리스트 ID 유효성 검사
              if (playlistId.length != 22 ||
                  !RegExp(r'^[a-zA-Z0-9]+$').hasMatch(playlistId)) {
                throw Exception('Invalid playlist ID');
              }

              // 트랙 URI 배치 처리
              for (int j = 0; j < trackUrisToAdd.length; j += 100) {
                int end = (j + 100 < trackUrisToAdd.length)
                    ? j + 100
                    : trackUrisToAdd.length;
                await widget.spotifyService.addTracksToPlaylist(
                    playlistId, trackUrisToAdd.sublist(j, end));
              }

              // 플레이리스트 트랙 수 업데이트
              int newTrackCount =
              await widget.spotifyService.updatePlaylistInfo(playlistId);
              _updatePlaylistTrackCount(playlistId, newTrackCount);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$emotion 플레이리스트에 트랙을 추가했습니다.')),
              );
              // 트랙 추가에 성공했으므로 순회를 종료
              return;
            } else {
              print(
                  '$emotion: ${playlists[i]['name']}에서 유효한 트랙을 찾을 수 없습니다.');
            }
          } catch (e) {
            print('$emotion: ${playlists[i]['name']}에서 트랙 추가 중 오류 발생: $e');
          }
        }
        // 모든 플레이리스트에서 트랙을 추가하지 못한 경우
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$emotion 태그로 검색된 플레이리스트에서 \n유효한 트랙을 찾을 수 없습니다.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$emotion 태그로 검색된 플레이리스트가 없습니다.')),
        );
      }
    } catch (e) {
      print('트랙 추가 중 오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('트랙 추가 실패: $e')),
      );
    }
  }

  void _showEditPlaylistNameDialog(String playlistId, String currentName) {
    TextEditingController _playlistNameController =
        TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('플레이리스트 이름 수정'),
          content: TextField(
            controller: _playlistNameController,
            decoration: InputDecoration(hintText: "새 플레이리스트 이름"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                '취소',
                style: TextStyle(color: Colors.blueAccent),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                '수정',
                style: TextStyle(color: Colors.blueAccent),
              ),
              onPressed: () async {
                if (_playlistNameController.text.isNotEmpty) {
                  try {
                    String newName = _playlistNameController.text;
                    await widget.spotifyService.updatePlaylistDetails(
                        playlistId: playlistId, name: newName);
                    setState(() {
                      final index = _playlists.indexWhere(
                          (playlist) => playlist['id'] == playlistId);
                      if (index != -1) {
                        _playlists[index]['name'] = newName;
                      }
                    });
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('플레이리스트 이름이 수정되었습니다.')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('플레이리스트 이름 수정 실패: $e')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TabBar(
                labelColor: Color(0xFF2265F0),
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color(0xFF2265F0),
                controller: _tabController,
                tabs: [
                  Tab(text: '감정 카테고리'),
                  Tab(text: '내 플레이리스트'),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEmotionCategories(),
                    _buildMyPlaylist(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmotionCategories() {
    return Column(
      children: [
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: widget.emotionInfo.length,
                  itemBuilder: (context, index) {
                    final emotionInfoItem = widget.emotionInfo[index];
                    final emotion = emotionInfoItem['emotion'];
                    final playlist = _playlists.firstWhere(
                      (p) => p['name'] == emotion,
                      orElse: () => {
                        'name': emotion,
                        'id': 'new_${emotion}_id',
                        'tracks': {'total': 0}
                      },
                    );
                    return GestureDetector(
                      onTap: () async {
                        String emotionTag = emotionInfoItem['tag'].split(',').first;
                        await _addTracksToEmotionPlaylist(
                            emotion, playlist['id'], emotionTag);
                        _showPlaylistTracks(playlist['id'], playlist['name']);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _getColorForEmotion(emotion),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Playlist',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                emotion,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${playlist['tracks']['total']}곡',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMyPlaylist() {
    return Column(
      children: [
        SizedBox(height: 7),
        ElevatedButton(
          onPressed: () => _showCreatePlaylistDialog(),
          style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2265F0),
              foregroundColor: Colors.white,
              minimumSize: Size(200, 45),
              side: BorderSide(color: Colors.blue),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15))),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add,
                size: 25,
                color: Colors.white,
              ),
              SizedBox(width: 8), //아이콘 텍스트 간격
              Text(
                '새 플레이리스트',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    color: Colors.blue,
                    backgroundColor: Colors.white,
                    strokeWidth: 3.0,
                    onRefresh: _loadPlaylists,
                    child: ListView.builder(
                      itemCount: _playlists
                          .where((playlist) =>
                      !widget.emotionInfo.map((e) => e['emotion']).contains(playlist['name']))
                          .length,
                      itemBuilder: (context, index) {
                        final playlist = _playlists
                            .where((playlist) =>
                        !widget.emotionInfo.map((e) => e['emotion']).contains(playlist['name']))
                            .toList()[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              title: Text(
                                playlist['name'],
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('${playlist['tracks']['total']}곡'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit),
                                    onPressed: () =>
                                        _showEditPlaylistNameDialog(
                                            playlist['id'], playlist['name']),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.close),
                                    onPressed: () =>
                                        _deletePlaylist(playlist['id']),
                                  ),
                                ],
                              ),
                              onTap: () => _showPlaylistTracks(
                                  playlist['id'], playlist['name']),
                            ),
                          ),
                        );
                      },
                    ),
                  )),
      ],
    );
  }

  void _showCreatePlaylistDialog() {
    TextEditingController _playlistNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('새 플레이리스트 생성'),
          content: TextField(
            controller: _playlistNameController,
            decoration: InputDecoration(hintText: "플레이리스트 이름"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                '취소',
                style: TextStyle(color: Colors.blueAccent),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                '생성',
                style: TextStyle(color: Colors.blueAccent),
              ),
              onPressed: () async {
                if (_playlistNameController.text.isNotEmpty) {
                  try {
                    await widget.spotifyService
                        .createPlaylist(_playlistNameController.text);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('플레이리스트가 생성되었습니다.')),
                    );
                    await _loadPlaylists();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('플레이리스트 생성 실패: $e')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}
