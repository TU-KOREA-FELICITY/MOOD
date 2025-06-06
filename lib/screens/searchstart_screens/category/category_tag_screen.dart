// 검색 홈 (감정 카테고리 & 내 플레이리스트 탭)
//블루 0xFF265F0

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import '../../homestart_screens/emotion_analysis_service.dart';
import '../search/playlist_tracks_screen.dart';
import '../service/spotify_service.dart';

class CategoryTagScreen extends StatefulWidget {
  final SpotifyService spotifyService;
  final Map<String, dynamic> userInfo;
  final List<Map<String, dynamic>> emotionInfo;
  final EmotionAnalysisService emotionAnalysisService;

  const CategoryTagScreen({
    super.key,
    required this.spotifyService,
    required this.userInfo,
    required this.emotionInfo,
    required this.emotionAnalysisService,
  });

  @override
  _CategoryTagScreenState createState() => _CategoryTagScreenState();
}

class _CategoryTagScreenState extends State<CategoryTagScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _emotionCategories = [
    '행복',
    '슬픔',
    '분노',
    '놀람',
    '혐오',
    '공포',
    '평온',
    '혼란'
  ];
  List<dynamic> _playlists = [];
  bool _isLoading = false;
  bool _isAddingTracks = false;
  String? _selectedPlaylistId;
  String _mode = 'normal';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPlaylists();
    widget.emotionAnalysisService.onTagsResultReceived = _handleTagsResult;
  }

  void _handleTagsResult(Map<String, dynamic> tagsResult) {
    if (!mounted) return;
    _showLoadingDialogAndAddTracks(tagsResult);
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
        builder: (context) =>
            PlaylistTracksScreen(
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
      _isLoading = true;
    });

    try {
      List playlists = await widget.spotifyService.getPlaylists();
      List<String> emotionNames = widget.emotionInfo
          .map((emotion) => emotion['emotion'] as String)
          .toList();

      // 현재 존재하는 플레이리스트 이름 목록 생성
      Set<String> existingPlaylistNames =
      playlists.map((playlist) => playlist['name'] as String).toSet();

      // 생성해야 할 감정 플레이리스트 목록
      List<String> playlistsToCreate = emotionNames
          .where((emotion) => !existingPlaylistNames.contains(emotion))
          .toList();

      // 필요한 플레이리스트만 생성
      for (String emotion in playlistsToCreate) {
        String newPlaylistId =
        await widget.spotifyService.createPlaylist(emotion);
        playlists.add({
          'name': emotion,
          'id': newPlaylistId,
          'tracks': {'total': 0}
        });
      }

      // 모든 플레이리스트의 트랙 수 업데이트
      for (var playlist in playlists) {
        int trackCount =
        await widget.spotifyService.updatePlaylistInfo(playlist['id']);
        playlist['tracks'] = {'total': trackCount};
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String>? orderedIds = prefs.getStringList('playlistOrder');

      if (orderedIds != null && orderedIds.isNotEmpty) {
        List orderedPlaylists = [];
        for (String id in orderedIds) {
          var matchingPlaylist = playlists.firstWhere(
                (p) => p['id'] == id,
            orElse: () => null,
          );
          if (matchingPlaylist != null) {
            orderedPlaylists.add(matchingPlaylist);
            playlists.remove(matchingPlaylist);
          }
        }
        orderedPlaylists.addAll(playlists);
        playlists = orderedPlaylists;
      }

      if (mounted) {
        setState(() {
          _playlists = playlists;
        });
      }
    } catch (e) {
      print('플레이리스트 로딩 중 오류: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _savePlaylistsOrder() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> playlistIds =
    _playlists.map((playlist) => playlist['id'] as String).toList();
    await prefs.setStringList('playlistOrder', playlistIds);
  }

  Color _getColorForEmotion(String emotion) {
    switch (emotion) {
      case '행복':
        return Color(0xFFFFF09A)!;
      case '슬픔':
        return Color(0xFFC9E4F1)!;
      case '분노':
        return Color(0xFFFFBDBD)!;
      case '놀람':
        return Color(0xFFFFCDB6)!;
      case '혐오':
        return Color(0xFFE3C4E5)!;
      case '공포':
        return Color(0xFFEBEBEB);
      case '평온':
        return Color(0xFFE1F0A0)!;
      case '혼란':
        return Color(0xFFCBEBE0)!;
      default:
        return Colors.grey[300]!;
    }
  }

  Future<bool> _deletePlaylist(String playlistId) async {
    bool result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          title: Text(
            '플레이리스트 삭제', style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(
            '플레이리스트를 삭제하시겠습니까?', style: TextStyle(fontWeight: FontWeight.w600),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('취소', style: TextStyle(
                  fontWeight: FontWeight.w800, color: Colors.black38),
              ),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('확인', style: TextStyle(
                  fontWeight: FontWeight.w800, color: Color(0xFF6A698C))),
              onPressed: () async {
                try {
                  await widget.spotifyService.deletePlaylist(playlistId);
                  setState(() {
                    _playlists.removeWhere(
                            (playlist) => playlist['id'] == playlistId);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('플레이리스트가 삭제되었습니다.')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('플레이리스트 삭제 실패: $e')),
                  );
                  Navigator.of(context).pop(false);
                }
              },
            ),
          ],
        );
      },
    );
    _selectedPlaylistId = null;
    return result ?? false;
  }

  Future<void> _addInitialTracks(String emotion, String playlistId,
      List<String> emotionTags) async {
    try {
      // 태그 중 랜덤으로 하나 선택
      final random = Random();
      String selectedTag = emotionTags[random.nextInt(emotionTags.length)];

      // 태그로 플레이리스트 검색
      Map searchResults =
      await widget.spotifyService.searchPlaylists(selectedTag);

      // 검색 결과가 있는지 확인
      if (searchResults['playlists'] != null &&
          searchResults['playlists'].isNotEmpty) {
        List<dynamic> playlists = searchResults['playlists'];
        // 검색된 플레이리스트를 순회하며 트랙을 추가 시도
        for (int i = 0; i < playlists.length; i++) {
          String sourcePlaylistId = playlists[i]['id'];
          try {
            // 플레이리스트의 트랙 가져오기 (최대 20개)
            List tracks =
            await widget.spotifyService.getPlaylistTracks(sourcePlaylistId);
            List<String> trackUrisToAdd = tracks
                .take(20)
                .map((track) => track['track']['uri'] as String)
                .where((uri) => uri.startsWith('spotify:track:'))
                .toList();

            // 현재 감정 카테고리 플레이리스트에 트랙 추가
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
              print('$emotion: ${playlists[i]['name']}에서 유효한 트랙을 찾을 수 없습니다.');
            }
          } catch (e) {
            print('$emotion: ${playlists[i]['name']}에서 트랙 추가 중 오류 발생: $e');
          }
        }
        // 모든 플레이리스트에서 트랙을 추가하지 못한 경우
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('$emotion 태그로 검색된 플레이리스트에서 \n유효한 트랙을 찾을 수 없습니다.')),
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

  Future<void> _addTracksByDetectedEmotion(
      Map<String, dynamic> tagsResult) async {
    if (!tagsResult['success']) {
      print('태그 결과 오류: ${tagsResult['message']}');
      return;
    }

    for (var emotionTag in tagsResult['tags']) {
      String emotion = emotionTag['emotion'];
      List<String> tags = (emotionTag['tags'] as List<dynamic>).cast<String>();

      // 랜덤 태그 선택
      String randomTag = tags[Random().nextInt(tags.length)];

      // 감정에 해당하는 플레이리스트 찾기
      var playlist = _playlists.firstWhere((p) => p['name'] == emotion,
          orElse: () => null);

      if (playlist == null) {
        print('$emotion에 해당하는 플레이리스트를 찾을 수 없습니다.');
        continue;
      }

      try {
        // 태그로 플레이리스트 검색
        Map searchResults =
        await widget.spotifyService.searchPlaylists(randomTag);

        if (searchResults['playlists'] == null ||
            searchResults['playlists'].isEmpty) {
          print('$randomTag 태그로 검색된 플레이리스트가 없습니다.');
          continue;
        }

        // 검색된 플레이리스트 중 랜덤 선택
        var randomPlaylist = searchResults['playlists']
        [Random().nextInt(searchResults['playlists'].length)];

        // 선택된 플레이리스트에서 트랙 가져오기
        List tracks =
        await widget.spotifyService.getPlaylistTracks(randomPlaylist['id']);

        // 최대 5개 트랙 랜덤 선택
        tracks.shuffle();
        List selectedTracks = tracks.take(5).toList();

        // 선택된 트랙을 감정 카테고리 플레이리스트에 추가
        List<String> trackUris = selectedTracks
            .map((track) => track['track']['uri'] as String)
            .toList();
        await widget.spotifyService
            .addTracksToPlaylist(playlist['id'], trackUris);

        // 플레이리스트 트랙 수 업데이트
        int newTrackCount =
        await widget.spotifyService.updatePlaylistInfo(playlist['id']);
        _updatePlaylistTrackCount(playlist['id'], newTrackCount);

        print('$emotion 플레이리스트에 ${trackUris.length}개의 트랙을 추가했습니다.');

        // 태그 리스트의 첫 번째 감정에 해당하는 플레이리스트 실행
        if (tagsResult['tags'].isNotEmpty) {
          String firstEmotion = tagsResult['tags'][0]['emotion'];
          var playlist = _playlists.firstWhere(
                (p) => p['name'] == firstEmotion,
            orElse: () => null,
          );

          if (playlist != null) {
            try {
              List tracks = await widget.spotifyService.getPlaylistTracks(
                  playlist['id']);
              tracks.shuffle();
              List<String> shuffledTrackUris = tracks.map((
                  track) => track['track']['uri'] as String).toList();
              await widget.spotifyService.playTracks(shuffledTrackUris);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$firstEmotion 플레이리스트를 셔플 재생합니다.')),
              );
            } catch (e) {
              print('$firstEmotion 플레이리스트 셔플 재생 중 오류 발생: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('플레이리스트 재생 중 오류가 발생했습니다.')),
              );
            }
          } else {
            print('$firstEmotion에 해당하는 플레이리스트를 찾을 수 없습니다.');
          }
        }
      } catch (e) {
        print('$emotion 플레이리스트에 트랙 추가 중 오류 발생: $e');
      }
    }
  }

  Future _showLoadingDialogAndAddTracks(Map<String, dynamic> tagsResult) async {
    if (!mounted) return;
    if (!mounted) return;
    setState(() {
      _isAddingTracks = true;
    },
    );
    await Future.delayed(Duration(seconds: 2));
    await _addTracksByDetectedEmotion(tagsResult);
    if (mounted) {
      setState(() {
        _isAddingTracks = false;
      });
    }
  }

  void _showEditPlaylistNameDialog(String playlistId, String currentName) {
    TextEditingController _playlistNameController =
    TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          title: Text(
            '플레이리스트 이름 수정', style: TextStyle(fontWeight: FontWeight.w800),),
          content: TextField(
            controller: _playlistNameController,
            decoration: InputDecoration(hintText: "새 플레이리스트 이름",
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF8C88D5), width: 2.0),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF8C88D5), width: 2.0),
                )
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                '취소',
                style: TextStyle(
                    color: Colors.black54, fontWeight: FontWeight.w800),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                '수정',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.w800),
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
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TabBar(
                    labelColor: Color(0xFF8C88D5),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Color(0xFF8C88D5),
                    controller: _tabController,
                    labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.normal,
                    ),
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
        ),
        if (_isAddingTracks)
          Container(
            color: Colors.black.withOpacity(0.4),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    '감정에 맞는 트랙을 추가하고 있습니다',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
      ],
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
                orElse: () =>
                {
                  'name': emotion,
                  'id': 'new_${emotion}_id',
                  'tracks': {'total': 0}
                },
              );
              return GestureDetector(
                onTap: () =>
                    _showPlaylistTracks(playlist['id'], playlist['name']),
                child: Container(
                  decoration: BoxDecoration(
                    color: _getColorForEmotion(emotion),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 11.0, left: 20.0, right: 8.0, bottom: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(height: 3),
                            Text(
                              emotion,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 0.5),
                            Text(
                              '${playlist['tracks']['total']}곡',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: IconButton(
                          icon: Icon(Icons.add,
                              color: Colors.grey[700], size: 17),
                          onPressed: () async {
                            List<String> emotionTags = emotionInfoItem['tag'].split(',');
                            bool? confirmed = await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  title: Text('랜덤 추천 트랙 추가', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black)),
                                  content: Text('이 감정에 대한 트랙을 추가하시겠습니까?', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
                                  actions: <Widget>[
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        TextButton(
                                          child: Text('취소', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black38)),
                                          onPressed: () {
                                            Navigator.of(context).pop(false);
                                          },
                                        ),
                                        TextButton(
                                          child: Text('확인', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black)),
                                          onPressed: () {
                                            Navigator.of(context).pop(true);
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            );
                            if (confirmed == true) {
                              setState(() {
                                _isAddingTracks = true;
                              });
                              await _addInitialTracks(emotion, playlist['id'], emotionTags);
                              setState(() {
                                _isAddingTracks = false;
                              });
                            }
                          },
                        ),
                      ),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: IconButton(
                          icon: Icon(
                              Icons.play_arrow, color: Colors.black, size: 30),
                          onPressed: () async {
                            await SpotifySdk.play(spotifyUri: playlist['uri']);
                          },
                        ),
                      ),
                    ],
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
    final myPlaylists = _playlists
        .where((playlist) => !_emotionCategories.contains(playlist['name']))
        .toList();
    return Column(
      children: [
        SizedBox(height: 7),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: _mode == 'normal'
                    ? ElevatedButton(
                  onPressed: () => _showCreatePlaylistDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF8C88D5),
                    foregroundColor: Colors.white,
                    minimumSize: Size(250, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add,
                        size: 25,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '새 플레이리스트',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2),
                      ),
                    ],
                  ),
                )
                    : ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _mode = 'normal';
                      _selectedPlaylistId = null;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF8C88D5),
                    foregroundColor: Colors.white,
                    minimumSize: Size(250, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    '완료',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2),
                  ),
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_horiz),
              offset: Offset(10, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              onSelected: (String result) {
                if (result == 'edit') {
                  setState(() {
                    _mode = 'edit';
                  });
                }
              },
              color: Color(0xFFF1F0FD),
              itemBuilder: (BuildContext context) =>
              <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'edit',
                  height: 20,
                  padding: EdgeInsets.all(3),
                  child: Center(
                    child: Text('수정하기',
                      style: TextStyle(color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],),
          ],
        ),
        SizedBox(height: 16),
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : RefreshIndicator(
            color: Color(0xFF8C88D5),
            backgroundColor: Colors.white,
            strokeWidth: 3.0,
            onRefresh: _loadPlaylists,
            child: ReorderableListView.builder(
              itemCount: myPlaylists.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final item = myPlaylists.removeAt(oldIndex);
                  myPlaylists.insert(newIndex, item);
                  _playlists = myPlaylists;
                  _savePlaylistsOrder();
                });
              },
              itemBuilder: (context, index) {
                final playlist = myPlaylists[index];
                return Padding(
                  key: Key(playlist['id']),
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 8.0),
                  child: Dismissible(
                    key: Key(playlist['id']),
                    direction: DismissDirection.endToStart,
                    dismissThresholds: {DismissDirection.endToStart: 0.7},
                    background: Container(),
                    secondaryBackground: Container(
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: 20.0),
                      color: Colors.red,
                      child: Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      bool? result = await _deletePlaylist(playlist['id']);
                      return false;
                    },
                    onDismissed: (direction) {},
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
                        leading: IconButton(
                          icon: Icon(
                            Icons.play_circle_fill, color: Color(0xFF6A698C),
                            size: 30,),
                          onPressed: () async {
                            await SpotifySdk.play(
                                spotifyUri: playlist['uri']);
                          },
                        ),
                        trailing: _mode == 'edit'
                            ? ElevatedButton(onPressed: () =>
                            _showEditPlaylistNameDialog(
                                playlist['id'], playlist['name']),
                          child: Text('수정', style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w700),),
                          style: ElevatedButton.styleFrom(
                              minimumSize: Size(60, 36),
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              backgroundColor: Colors.white60
                          ),
                        )
                            : Listener(
                          child: Icon(Icons.drag_handle),
                          onPointerDown: (PointerDownEvent event) {},
                        ),
                        onTap: () {
                          _showPlaylistTracks(
                              playlist['id'], playlist['name']);
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showCreatePlaylistDialog() {
    TextEditingController _playlistNameController = TextEditingController();
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            title: Text('새 플레이리스트 생성',
              style: TextStyle(fontWeight: FontWeight.w800),),
            content: TextField(
              controller: _playlistNameController,
              decoration: InputDecoration(hintText: "플레이리스트 이름",
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF8C88D5), width: 2.0),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF8C88D5), width: 2.0),
                ),
              ),
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton(
                    child: Text(
                      '취소',
                      style: TextStyle(
                          color: Colors.black38, fontWeight: FontWeight.w800),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: Text(
                      '생성',
                      style: TextStyle(
                          color: Color(0xFF6A698C), fontWeight: FontWeight.w800),
                    ),
                    onPressed: () async {
                      if (_playlistNameController.text.isNotEmpty) {
                        try {
                          String newPlaylistId = await widget.spotifyService
                              .createPlaylist(_playlistNameController.text);
                          var newPlaylist = {
                            'name': _playlistNameController.text,
                            'id': newPlaylistId,
                            'tracks': {'total': 0}
                          };
                          setState(() {
                            _playlists.insert(0, newPlaylist);
                          });
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('플레이리스트가 생성되었습니다.')),
                          );
                          await _savePlaylistsOrder();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('플레이리스트 생성 실패: $e')),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          );
        }
    );
  }
}