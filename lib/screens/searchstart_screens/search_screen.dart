import 'package:flutter/material.dart';

import '../start_screens/spotify_service.dart';
import '../start_screens/spotify_web_login_screen.dart';

class SearchScreen extends StatefulWidget {
  final Map<String, String>? tokens;

  SearchScreen({this.tokens});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final SpotifyService _spotifyService = SpotifyService();
  bool _isConnected = false;
  String _currentTrack = '재생 중인 곡 없음';
  String _artistName = '알 수 없는 아티스트';
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeSpotify();
  }

  Future<void> _initializeSpotify() async {
    if (widget.tokens != null) {
      await _spotifyService.setTokens(widget.tokens!);
      setState(() {
        _isConnected = true;
      });
      _updateCurrentTrack();
    }
  }

  Future<void> _updateCurrentTrack() async {
    final trackInfo = await _spotifyService.getCurrentTrackInfo();
    setState(() {
      _currentTrack = trackInfo['name'] ?? '재생 중인 곡 없음';
      _artistName = trackInfo['artist'] ?? '알 수 없는 아티스트';
      _isPlaying = trackInfo['isPlaying'] ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Spotify 홈')),
      body: _isConnected ? _buildConnectedBody() : _buildDisconnectedBody(),
    );
  }

  Widget _buildConnectedBody() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('현재 재생 중:', style: TextStyle(fontSize: 18)),
        Text(_currentTrack, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(_artistName, style: TextStyle(fontSize: 18)),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.skip_previous),
              onPressed: () async {
                await _spotifyService.playPreviousTrack();
                _updateCurrentTrack();
              },
            ),
            ElevatedButton(
              onPressed: () async {
                await _spotifyService.togglePlayPause();
                _updateCurrentTrack();
              },
              child: Text(_isPlaying ? '일시정지' : '재생'),
            ),
            IconButton(
              icon: Icon(Icons.skip_next),
              onPressed: () async {
                await _spotifyService.playNextTrack();
                _updateCurrentTrack();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDisconnectedBody() {
    return Center(
      child: ElevatedButton(
        onPressed: _authenticate,
        child: Text('Spotify로 로그인'),
      ),
    );
  }

  void _authenticate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SpotifyWebLoginScreen(
          authUrl: _spotifyService.getAuthUrl(),
          redirectUri: _spotifyService.redirectUri,
        ),
      ),
    );

    if (result != null && result is Map<String, String>) {
      await _spotifyService.setTokens(result);
      setState(() {
        _isConnected = true;
      });
      _updateCurrentTrack();
    }
  }
}
