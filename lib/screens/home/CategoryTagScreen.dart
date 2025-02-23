// 검색 홈 (감정 카테고리 & 내 플레이리스트 탭)
//블루 0xFF265F0

import 'package:flutter/material.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import '../../services/spotify_service.dart';
import 'playlist_tracks_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryTagScreen extends StatefulWidget {
  final SpotifyService spotifyService;

  const CategoryTagScreen({Key ? key, required this.spotifyService})
  : super(key: key);

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
  bool _isReordering = false;
  String? _selectedPlaylistId;
  String _mode = 'normal';
  String? _currentPlaylistId;


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
      final index = _playlists.indexWhere((playlist) =>
      playlist['id'] == playlistId);
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
            PlaylistTracksView(
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
      for (String emotion in _emotionCategories) {
        bool playlistExists = playlists.any((playlist) =>
        playlist['name'] == emotion);

        if (!playlistExists) {
          // 해당 감정의 플레이리스트가 없으면 새로 생성
          String newPlaylistId = await widget.spotifyService.createPlaylist(
              emotion);
          playlists.add({'name': emotion, 'id': newPlaylistId});
        }
      }

      for (var playlist in playlists) {
        int trackCount = await widget.spotifyService.updatePlaylistInfo(
            playlist['id']);
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

      setState(() {
        _playlists = playlists;
      });
    } catch (e) {
      print('플레이리스트 로딩 중 오류 발생: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  //플레이리스트 순서 저장
  Future<void> _savePlaylistsOrder() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> playlistIds =
    _playlists.map((playlist) => playlist['id'] as String).toList();
    await prefs.setStringList('playlistOrder', playlistIds);
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

  Future<bool> _deletePlaylist(String playlistId) async {
    bool result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('플레이리스트 삭제'),
          content: Text('플레이리스트를 삭제하시겠습니까?'),
          actions: <Widget>[
            TextButton(
              child: Text('취소'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('확인'),
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
        child: Stack(
          children: [
            Padding(
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
          ],
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
              itemCount: _emotionCategories.length,
              itemBuilder: (context, index) {
                final emotion = _emotionCategories[index];
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
                  onTap: () => _showPlaylistTracks(playlist['id'], playlist['name']),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getColorForEmotion(emotion),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Stack(
                        children: [
                          Column(
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
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: IconButton(
                              icon: Icon(Icons.play_arrow, color: Colors.black),
                              onPressed: () async {
                                await SpotifySdk.play(spotifyUri: playlist['uri']);
                              },
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
    final myPlaylists = _playlists
        .where((playlist) => !_emotionCategories.contains(playlist['name']))
        .toList();
    return Column(
      children: [
        SizedBox(height: 7),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _mode = (_mode == 'edit') ? 'normal' : 'edit';
                  _selectedPlaylistId = null;
                });
              },
            ),
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: _mode == 'normal'
                    ? ElevatedButton(
                  onPressed: () => _showCreatePlaylistDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2265F0),
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
                    backgroundColor: Colors.blue,
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
          ],
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
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 20.0),
                        color: Colors.red,
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        bool? result = await _deletePlaylist(playlist['id']);
                        return result ?? false;
                      },
                      onDismissed: (direction){
                      },
                      child : Container(
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
                            icon: Icon(Icons.play_arrow, color: Colors.black),
                            onPressed: () async {
                              await SpotifySdk.play(
                                  spotifyUri: playlist['uri']);
                            },
                          ),
                          trailing: Icon(Icons.drag_handle),
                          onTap: () {
                            _showPlaylistTracks(
                                playlist['id'], playlist['name']);
                          },
                        ),
                      ),
                    )
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
          );
        },
      );
    }
  }
