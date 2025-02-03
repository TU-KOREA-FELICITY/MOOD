// 검색페이지 (내 플레이리스트)

import 'package:flutter/material.dart';
import '../services/spotify_service.dart';

class PlaylistTracksView extends StatefulWidget {
  final SpotifyService spotifyService;
  final String playlistId;
  final String playlistName;

  PlaylistTracksView({
    required this.spotifyService,
    required this.playlistId,
    required this.playlistName,
  });

  @override
  _PlaylistTracksViewState createState() => _PlaylistTracksViewState();
}

class _PlaylistTracksViewState extends State<PlaylistTracksView> {
  List<dynamic> _tracks = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    setState(() => _isLoading = true);
    try {
      final tracks = await widget.spotifyService.getPlaylistTracks(
          widget.playlistId);
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
      return await widget.spotifyService.getPlaylists();
    } catch (e) {
      print('플레이리스트 가져오기 오류: $e');
      return [];
    }
  }

  void _addTrackToPlaylist(String trackUri) async {
    final playlists = await _getPlaylists();

    final selectedPlaylist = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.55,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.blue[800],
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16.0),
                        topRight: Radius.circular(16.0),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      '플레이리스트 선택',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: playlists.map((playlist) {
                            return Column(
                              children: [
                                ListTile(
                                  leading: Icon(Icons.add, color: Colors.blueAccent),
                                  title: Text(
                                    playlist['name'] ?? '알 수 없는 플레이리스트',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.pop(context, playlist);
                                  },
                                ),
                                if (playlist != playlists.last)
                                  Divider(
                                    height: 7,
                                    indent: 16, //구분선 좌우 여백
                                    endIndent: 16,
                                  ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
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
        await widget.spotifyService.addTrackToPlaylist(
          selectedPlaylist['id'],
          trackUri,
        );
        selectedPlaylist['tracks']['total']++;
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('곡이 플레이리스트에 추가되었습니다.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('곡 추가에 실패했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.playlistName),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _tracks.length,
        itemBuilder: (context, index) {
          final track = _tracks[index]['track'];
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
                ],
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                leading: _buildAlbumCover(track),
                title: Text(
                  track['name'],
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(track['artists'][0]['name']),
                trailing: IconButton(
                  icon: Icon(Icons.playlist_add),
                  onPressed: () => _addTrackToPlaylist(track['uri']),
                ),
                onTap: () => widget.spotifyService.playTrack(track['uri'],

                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

Widget _buildAlbumCover(dynamic track) {
  final images = track['album']?['images'] as List?;
  final imageUrl = images?.isNotEmpty == true ? images?.first['url'] as String? : null;

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
          return Center(child: Icon(Icons.music_note, color: Colors.grey[600]));
        },
      ),
    )
        : Center(child: Icon(Icons.music_note, color: Colors.grey[600])),
  );
}
