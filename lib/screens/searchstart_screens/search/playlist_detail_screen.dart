// 검색 -> 플레이리스트 탭 -> 플레이리스트 내 트랙

import 'package:flutter/material.dart';
import '../service/spotify_service.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final SpotifyService spotifyService;
  final String playlistId;
  final String playlistName;
  final Function(String, int) onPlaylistUpdated;

  const PlaylistDetailScreen({
    required this.spotifyService,
    required this.playlistId,
    required this.playlistName,
    required this.onPlaylistUpdated,
  });

  @override
  _PlaylistDetailScreenState createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  bool _isLoading = false;
  bool _isEditing = false;
  Set<String> _selectedTracks = {};
  bool _selectionMode = false;
  List<dynamic> _tracks = [];
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

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    setState(() => _isLoading = true);
    try {
      final tracks =
          await widget.spotifyService.getPlaylistTracks(widget.playlistId);
      setState(() {
        _tracks = tracks;
        _isLoading = false;
      });
    } catch (e) {
      print('트랙 로딩 중 오류 발생: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<List<dynamic>> _getPlaylists() async {
    try {
      final playlists = await widget.spotifyService.getPlaylists();
      return List<Map<String, dynamic>>.from(playlists);
    } catch (e) {
      print('플레이리스트 가져오기 오류: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> filterPlaylists(
      List<Map<String, dynamic>> playlists, bool isEmotionCategory) {
    return playlists.where((playlist) {
      String name = playlist['name'].toLowerCase();
      bool isEmotionPlaylist = _emotionCategories
          .any((category) => name.contains(category.toLowerCase()));
      return isEmotionCategory ? isEmotionPlaylist : !isEmotionPlaylist;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.playlistName, style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 24)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                _selectedTracks.clear();
              });
            },
            child: Text(_isEditing ? '완료' : '선택',
                style: TextStyle(color: _isEditing ? Colors.black : Color(0xFF8C88D5), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: FutureBuilder(
        future: widget.spotifyService.getPlaylistTracks(widget.playlistId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('플레이리스트 로드 실패: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final tracks = snapshot.data as List<dynamic>;
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '전체 (${tracks.length})곡',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      if (_isEditing)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (_selectedTracks.length == tracks.length) {
                                _selectedTracks.clear();
                              } else {
                                _selectedTracks = Set.from(tracks
                                    .map((track) => track['track']['uri']));
                              }
                            });
                          },
                          child: Text(
                            _selectedTracks.length == tracks.length
                                ? '전체선택해제'
                                : '전체선택',
                            style: TextStyle(color: _selectedTracks.length == _tracks.length
                                ? Colors.black45 : Colors.black),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                  ListView.builder(
                    itemCount: tracks.length,
                    itemBuilder: (context, index) {
                      final track = tracks[index]['track'];
                      final trackUri = track['uri'] as String;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
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
                              ]),
                          child: Row(
                            children: [
                              if (_isEditing)
                                Padding(
                                  padding: EdgeInsets.only(left: 5),
                                  child: Checkbox(
                                    value: _selectedTracks.contains(trackUri),
                                    onChanged: (bool? value) {
                                      setState(() {
                                        if (value == true) {
                                          _selectedTracks.add(trackUri);
                                        } else {
                                          _selectedTracks.remove(trackUri);
                                        }
                                      });
                                    },
                                    activeColor: Color(0xFF8C88D5),
                                    checkColor: Colors.white,
                                  ),
                                ),
                              Expanded(
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  leading: _buildAlbumCover(track),
                                  title: Text(track['name'],
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Text(track['artists'][0]['name']),
                                  onTap: _isEditing
                                      ? () {
                                          setState(() {
                                            if (_selectedTracks
                                                .contains(trackUri)) {
                                              _selectedTracks.remove(trackUri);
                                            } else {
                                              _selectedTracks.add(trackUri);
                                            }
                                          });
                                        }
                                      : () => widget.spotifyService
                                          .playTrack(trackUri),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                if (_selectedTracks.isNotEmpty && _isEditing)
                  Positioned(
                    bottom: 25.0,
                    left: 30.0,
                    right: 30.0,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => _showAddDialog(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF8C88D5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: Text('선택한 곡 추가',
                            style: TextStyle(color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  )],
                  ))]);
          }
          return Center(child: Text('플레이리스트가 비어 있습니다.'));
        },
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            '플레이리스트 선택',
            style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 15),
              ElevatedButton(
                onPressed: () => _showPlaylistOptions(_selectedTracks.toList(), '감정 카테고리'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFECEBFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: Size(double.infinity, 50,)
                ),
                child: Text('감정 카테고리',style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),),
              ),
              SizedBox(height: 25),
              ElevatedButton(
                onPressed: () => _showPlaylistOptions(_selectedTracks.toList(), '내 플레이리스트'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFD2D0FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text('내 플레이리스트', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPlaylistOptions(List<String> trackUris, String option) async {
    final playlists = await _getPlaylists();
    final List<Map<String, dynamic>> typedPlaylists =
    List<Map<String, dynamic>>.from(playlists);
    final filteredPlaylists =
    filterPlaylists(typedPlaylists, option == '감정 카테고리');

    final selectedPlaylist = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            child: Container(
              color: Colors.white,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 헤더 부분
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Color(0xFF8C88D5),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  Expanded(
                    child: ListView.separated(
                      itemCount: filteredPlaylists.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey[300],
                        indent: 16,
                        endIndent: 16,
                      ),
                      itemBuilder: (context, index) {
                        final playlist = filteredPlaylists[index];
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.0),
                          ),
                          leading: Icon(Icons.playlist_play,
                              color: Color(0xFF8C88D5)),
                          title: Text(
                            playlist['name'] ?? '알 수 없는 플레이리스트',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context, playlist);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (selectedPlaylist != null) {
      try {
        const batchSize = 100;
        for (var i = 0; i < trackUris.length; i += batchSize) {
          final batch = trackUris.toList().sublist(
              i,
              i + batchSize > trackUris.length
                  ? trackUris.length
                  : i + batchSize);
          await widget.spotifyService
              .addTrackToPlaylist(selectedPlaylist['id'], batch);
        }
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('선택한 곡이 플레이리스트에 추가되었습니다.')),
        );
        setState(() {
          _selectedTracks.clear();
          _selectionMode = false;
          _isEditing = false;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('곡 추가에 실패했습니다: $e')),
        );
      }
    }
  }



  Widget _buildAlbumCover(dynamic track) {
    final images = track['album']?['images'] as List?;
    final imageUrl =
        images?.isNotEmpty == true ? images?.first['url'] as String? : null;
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                      child: Icon(Icons.music_note, color: Colors.grey[600]));
                },
              ),
            )
          : Center(child: Icon(Icons.music_note, color: Colors.grey[600])),
    );
  }
}
