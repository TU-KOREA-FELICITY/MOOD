import 'package:flutter/material.dart';
import 'spotify_service.dart';

class PlaylistView extends StatefulWidget {
  final SpotifyService spotifyService;

  PlaylistView({required this.spotifyService});

  @override
  _PlaylistViewState createState() => _PlaylistViewState();
}

class _PlaylistViewState extends State<PlaylistView> {
  List<dynamic> _playlists = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    setState(() => _isLoading = true);
    try {
      final playlists = await widget.spotifyService.getPlaylists();
      setState(() {
        _playlists = playlists;
        _isLoading = false;
      });
    } catch (e) {
      print('플레이리스트 로딩 중 오류 발생: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : ListView.builder(
      itemCount: _playlists.length,
      itemBuilder: (context, index) {
        final playlist = _playlists[index];
        return ListTile(
          title: Text(playlist['name']),
          subtitle: Text('${playlist['tracks']['total']} 트랙'),
          onTap: () => _showPlaylistTracks(playlist['id'], playlist['name']),
        );
      },
    );
  }

  void _showPlaylistTracks(String playlistId, String playlistName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistTracksView(
          spotifyService: widget.spotifyService,
          playlistId: playlistId,
          playlistName: playlistName,
        ),
      ),
    );
  }
}

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
            onTap: () => widget.spotifyService.playTrack(track['uri']),
          );
        },
      ),
    );
  }
}
