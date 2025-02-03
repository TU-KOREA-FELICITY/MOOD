// 검색페이지 (내 플레이리스트)

import 'package:flutter/material.dart';
import '../services/spotify_service.dart';
import 'package:spotify_sdk/spotify_sdk.dart';


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
  Map<String, bool> _showButtons = {};

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


  void _showPlaylistOptions(dynamic track, String option) async {
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
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16.0),
                        topRight: Radius.circular(16.0),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Flexible(
                    child: ListView.builder(
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = playlists[index];
                        return ListTile(
                          leading: Icon(Icons.playlist_play, color: Colors.blueAccent),
                          title: Text(
                            playlist['name'] ?? '알 수 없는 플레이리스트',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
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
        await widget.spotifyService.addTrackToPlaylist(
          selectedPlaylist['id'],
          track['uri'],
        );
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
                      onPressed: () {
                        setState(() {
                          _showButtons[trackId] = !(_showButtons[trackId] ?? false);
                        });
                      },
                    ),
                    onTap: () => widget.spotifyService.playTrack(track['uri']),
                  ),
                ),
              ),
              if (_showButtons[trackId] ?? false)
                Container(
                  margin: EdgeInsets.only(bottom: 8.0),
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        child: Text('감정 카테고리',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 2,
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onPressed: () => _showPlaylistOptions(track, '카테고리'),
                      ),
                      ElevatedButton(
                        child: Text('내 플레이리스트',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 2,
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onPressed: () => _showPlaylistOptions(track, '내 플레이리스트'),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
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
}