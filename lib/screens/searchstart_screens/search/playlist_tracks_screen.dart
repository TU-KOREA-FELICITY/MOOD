// 검색 홈 (내 플레이리스트 탭에서 플레이리스트 클릭 시)

import 'package:flutter/material.dart';
import '../service/spotify_service.dart';

class PlaylistTracksScreen extends StatefulWidget {
  final SpotifyService spotifyService;
  final String playlistId;
  String playlistName;
  final bool isEmotionPlaylist;
  final Function(String, int) onPlaylistUpdated;
  bool _isEditing = false;
  Set<String> _selectedTracks = {};

  PlaylistTracksScreen({
    super.key,
    required this.spotifyService,
    required this.playlistId,
    required this.playlistName,
    required this.isEmotionPlaylist,
    required this.onPlaylistUpdated,
  });

  @override
  _PlaylistTracksScreenState createState() => _PlaylistTracksScreenState();
}

class _PlaylistTracksScreenState extends State<PlaylistTracksScreen> {
  final List<String> _emotionCategories = ['행복', '슬픔', '분노', '놀람', '혐오', '공포', '평온', '혼란'];
  List<dynamic> _tracks = [];
  bool _isLoading = true;

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

  Future<void> _deleteSelectedTracks(PlaylistTracksScreen widget) async {
    try {
      for (String trackId in widget._selectedTracks) {
        final trackUri = 'spotify:track:$trackId';
        await widget.spotifyService
            .deleteTrackFromPlaylist(widget.playlistId, trackUri);
      }
      await _loadTracks();
      setState(() {
        widget._selectedTracks.clear();
        widget._isEditing = false;
      });
      widget.onPlaylistUpdated(widget.playlistId, _tracks.length);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('선택한 곡이 삭제되었습니다.')),
      );
    } catch (e) {
      print('곡 삭제 오류: $e');
      rethrow;
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

  //정렬 A~하 순서대로 //
  void _sortTracks(String sortOption) {
    setState(() {
      if (sortOption == 'ABC') {
        _tracks.sort((a, b) => a['track']['name']
            .toString()
            .toLowerCase()
            .compareTo(b['track']['name'].toString().toLowerCase()));
      } else if (sortOption == '아티스트') {
        _tracks.sort((a, b) {
          int artistComparison = a['track']['artists'][0]['name']
              .toString()
              .toLowerCase()
              .compareTo(
              b['track']['artists'][0]['name'].toString().toLowerCase());
          if (artistComparison == 0) {
            return a['track']['name']
                .toString()
                .toLowerCase()
                .compareTo(b['track']['name'].toString().toLowerCase());
          }
          return artistComparison;
        });
      }
    });
  }

  void _showSortDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '정렬 방식을 선택하세요',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _sortTracks('ABC');
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF8C88D5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text('가나다 순',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _sortTracks('아티스트');
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF8C88D5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text('아티스트 순',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),),
                    ),
                  ),],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPlaylistOptions(dynamic track, String option) async {
    final playlists = await _getPlaylists();
    final List<Map<String, dynamic>> typedPlaylists =
    List<Map<String, dynamic>>.from(playlists);
    final filteredPlaylists =
    filterPlaylists(typedPlaylists, option == '감정 카테고리');

    final selectedPlaylist = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
                maxHeight: MediaQuery.of(context).size.height * 0.7,
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
                    padding: EdgeInsets.symmetric(vertical: 16),
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
                              color: Color(0xFF8C88D5), size: 30),
                          title: Text(
                            playlist['name'] ?? '알 수 없는 플레이리스트',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          contentPadding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          onTap: () => Navigator.pop(context, playlist),
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

    if (selectedPlaylist == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('플레이리스트를 선택하지 않았습니다.')),
      );
      return;
    }

    try {
      if (widget._selectedTracks.isEmpty) {
        if (track != null) {
          String trackUri = track['uri'] ?? 'spotify:track:${track['id']}';
          Navigator.of(context).pop();
          setState(() => widget._isEditing = false);
          await widget.spotifyService
              .addTrackToPlaylist(selectedPlaylist['id'], [trackUri]);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('곡이 플레이리스트에 추가되었습니다.')),
          );
        }
      } else {
        // 여러 곡 추가
        Navigator.of(context).pop();
        setState(() => widget._isEditing = false);
        List<String> trackUris = widget._selectedTracks
            .map((trackId) => 'spotify:track:$trackId').toList();

        await widget.spotifyService.addTrackToPlaylist(
          selectedPlaylist['id'],
          trackUris,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('선택한 곡들이 플레이리스트에 추가되었습니다.')),
        );
        await _loadTracks();
        widget.onPlaylistUpdated(widget.playlistId, _tracks.length);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('곡 추가 실패: ${e.toString()}')),
      );
    }
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
                onPressed: () => _showPlaylistOptions(null, '감정 카테고리'),
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
                onPressed: () => _showPlaylistOptions(null, '내 플레이리스트'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFECEBFF),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.playlistName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.sort),
            onPressed: _showSortDialog,
          ),
          TextButton(
            onPressed: () {
              setState(() {
                widget._isEditing = !widget._isEditing;
                widget._selectedTracks.clear();
              });
            },
            child: Text(widget._isEditing ? '완료' : '선택',
              style: TextStyle(color: widget._isEditing ? Colors.black : Color(0xFF6A698C),
                  fontWeight: FontWeight.bold),),
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('전체 (${_tracks.length}곡)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),
                    if (widget._isEditing)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (widget._selectedTracks.length ==
                                _tracks.length) {
                              widget._selectedTracks.clear();
                            } else {
                              widget._selectedTracks = _tracks
                                  .map((t) => t['track']['id'] as String)
                                  .toSet();
                            }
                          });
                        },
                        child: Text(
                          widget._selectedTracks.length == _tracks.length
                              ? '전체선택해제'
                              : '전체 선택',
                          style: TextStyle(color: widget._selectedTracks.length == _tracks.length
                              ? Colors.black45 : Colors.black),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _tracks.length,
                  itemBuilder: (context, index) {
                    final track = _tracks[index]['track'];
                    final trackId = track['id'] as String;
                    return Column(
                      children: [
                        Padding(
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
                              ],
                            ),
                            child: Row(
                              children: [
                                if (widget._isEditing)
                                  Padding(
                                    padding: EdgeInsets.only(left: 5),
                                    child: Checkbox(
                                      value: widget._selectedTracks
                                          .contains(trackId),
                                      onChanged: (bool? value) {
                                        setState(() {
                                          if (value == true) {
                                            widget._selectedTracks
                                                .add(trackId);
                                          } else {
                                            widget._selectedTracks
                                                .remove(trackId);
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
                                    title: Text(
                                      track['name'],
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle:
                                    Text(track['artists'][0]['name']),
                                    onTap: widget._isEditing
                                        ? () {
                                      setState(() {
                                        if (widget._selectedTracks
                                            .contains(trackId)) {
                                          widget._selectedTracks
                                              .remove(trackId);
                                        } else {
                                          widget._selectedTracks
                                              .add(trackId);
                                        }
                                      });
                                    }
                                        : () => widget.spotifyService
                                        .playTrack(track['uri']),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          if (widget._isEditing && widget._selectedTracks.isNotEmpty)
            Positioned(
              left: 15,
              right: 15,
              bottom: 35,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showAddDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF8C88D5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: Size(double.infinity, 50),
                      ),
                      child: Text('추가', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SizedBox(width: 13),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _deleteSelectedTracks(widget),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: Size(double.infinity, 50),
                      ),
                      child: Text('삭제', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
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