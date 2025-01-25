// 검색페이지 내 플레이리스트

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
      final tracks = await widget.spotifyService.getPlaylistTracks(widget.playlistId);
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
        return SimpleDialog(
          title: Text('플레이리스트 선택'),
          children: playlists.map((playlist) {
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, playlist);
              },
              child: Text(playlist['name'] ?? '알 수 없는 플레이리스트'),
            );
          }).toList(),
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
      appBar: AppBar(title: Text(widget.playlistName)),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _tracks.length,
        itemBuilder: (context, index) {
          final track = _tracks[index]['track'];
          return ListTile(
            title: Text(track['name']),
            subtitle: Text(track['artists'][0]['name']),
            trailing: IconButton(
              icon: Icon(Icons.playlist_add),
              onPressed: () => _addTrackToPlaylist(track['uri']),
            ),
            onTap: () => widget.spotifyService.playTrack(track['uri']),
          );
        },
      ),
    );
  }
}