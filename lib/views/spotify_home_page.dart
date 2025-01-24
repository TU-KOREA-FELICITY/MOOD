import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mood/views/search_view.dart';
import '../services/spotify_service.dart';
import '../widgets/spotify_auth_webview.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import '../ui/Miniplayer.dart';

class SpotifyHomePage extends StatefulWidget {
  @override
  _SpotifyHomePageState createState() => _SpotifyHomePageState();
}

class _SpotifyHomePageState extends State<SpotifyHomePage>
    with SingleTickerProviderStateMixin {
  final SpotifyService _spotifyService = SpotifyService();
  bool _isConnected = false;
  bool _isPlaying = false;
  String _currentTrack = 'No track playing';
  String _artistName = 'Unknown artist';
  late TabController _tabController;

  Timer? _updateTimer;
  bool _isLiked = false;
  double _sliderValue = 0.0;
  double _duration = 1.0;
  String _currentTrackImageUri = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeApp();
    _startPeriodicUpdate();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await _spotifyService.initialize();
    setState(() {
      _isConnected = _spotifyService.isConnected;
    });
    if (_isConnected) {
      _updateCurrentTrack();
    }
  }

  void _startPeriodicUpdate() {
    _updateTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_isConnected) {
        _updateCurrentTrack();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
            icon: Icon(Icons.keyboard_arrow_down_outlined, color: Colors.black),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchView(spotifyService: _spotifyService),
                  ));
            }),
        actions: [
          if (_isConnected)
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: _logout,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_isConnected) {
      return Center(
        child: ElevatedButton(
          onPressed: _authenticate,
          child: Text('로그인'),
        ),
      );
    }

    return SafeArea(
      child: Column(
        children: [
          SizedBox(height: 10),
          _buildMiniPlayer(),
        ],
      ),
    );
  }

  Widget _buildMiniPlayer() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Container(
        height: 100,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // 곡 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentTrack,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _artistName,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // 재생 컨트롤
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.skip_previous,
                          color: Colors.black, size: 24),
                      onPressed: _playPreviousTrack,
                    ),
                    IconButton(
                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.black, size: 32),
                      onPressed: _togglePlayPause,
                    ),
                    IconButton(
                      icon:
                          Icon(Icons.skip_next, color: Colors.black, size: 24),
                      onPressed: _playNextTrack,
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 4),
            // 재생 바
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: Colors.blue,
                inactiveTrackColor: Colors.grey[300],
                thumbColor: Colors.blue,
                trackHeight: 2.0,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.0),
                overlayShape: RoundSliderOverlayShape(overlayRadius: 14.0),
              ),
              child: Slider(
                value: _sliderValue,
                onChanged: (value) {
                  setState(() {
                    _sliderValue = value;
                  });
                },
                onChangeEnd: (value) async {
                  try {
                    await SpotifySdk.seekTo(
                        positionedMilliseconds: (value * _duration).toInt());
                  } catch (e) {
                    print('Failed to seek: $e');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }



  String _formatDuration(double milliseconds) {
    final Duration duration = Duration(milliseconds: milliseconds.toInt());
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _authenticate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SpotifyAuthWebView(
          authUrl: _spotifyService.getAuthUrl(),
          redirectUri: _spotifyService.redirectUri,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      await _spotifyService.setTokens(result);
      setState(() {
        _isConnected = true;
      });
      _updateCurrentTrack();
    }
  }

  Future<void> _logout() async {
    await _spotifyService.logout();
    setState(() {
      _isConnected = false;
      _currentTrack = 'No track playing';
      _artistName = 'Unknown artist';
      _isPlaying = false;
      _currentTrackImageUri = '';
    });
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await SpotifySdk.pause();
      } else {
        await SpotifySdk.resume();
      }
      _updateCurrentTrack();
    } catch (e) {
      print('Failed to toggle play/pause: $e');
    }
  }

  Future<void> _playNextTrack() async {
    try {
      await SpotifySdk.skipNext();
      _updateCurrentTrack();
    } catch (e) {
      print('Failed to play next track: $e');
    }
  }

  Future<void> _playPreviousTrack() async {
    try {
      await SpotifySdk.skipPrevious();
      _updateCurrentTrack();
    } catch (e) {
      print('Failed to play previous track: $e');
    }
  }



  Future<void> _updateCurrentTrack() async {
    try {
      final playerState = await SpotifySdk.getPlayerState();
      if (playerState != null && playerState.track != null) {
        setState(() {
          _currentTrack = playerState.track!.name;
          _artistName = playerState.track!.artist.name!;
          _isPlaying =
              playerState.isPaused != null ? !playerState.isPaused! : false;
          _duration = playerState.track!.duration.toDouble();
          _sliderValue = playerState.playbackPosition / _duration;
          _currentTrackImageUri = playerState.track!.imageUri.raw;
        });
      }
    } catch (e) {
      print('Failed to get player state: $e');
    }
  }
}

