import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mood/ui/PlaylistScreen.dart';
import 'spotify_service.dart';
import 'spotify_auth_webview.dart';
import 'playlist_view.dart';
import 'search_view.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:spotify_sdk/models/image_uri.dart';



class SpotifyHomePage extends StatefulWidget {
  @override
  _SpotifyHomePageState createState() => _SpotifyHomePageState();
}

class _SpotifyHomePageState extends State<SpotifyHomePage> with SingleTickerProviderStateMixin {
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
            icon: Icon(Icons.keyboard_arrow_down_outlined,
                color: Colors.black),
            onPressed: () {}
        ),
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
          _buildCurrentTrackInfo(),
          _buildAlbumArt(),
          _buildPlaybackControls(),
        ],
      ),
    );
  }

  Widget _buildCurrentTrackInfo() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              _isLiked ? Icons.favorite : Icons.favorite_border_outlined,
              color: Colors.red,
              size: 30,
            ),
            onPressed: () {
              setState(() {
                _isLiked = !_isLiked;
              });
            },
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  _currentTrack,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                Text(
                  _artistName,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.playlist_play_rounded,
              color: Colors.black,
              size: 35,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PlaylistView(spotifyService: _spotifyService,)),
              );
              // Navigate to PlaylistScreen
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: _currentTrackImageUri.isNotEmpty
                ? Image.network(
              _currentTrackImageUri,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholderAlbumArt();
              },
            )
                : _buildPlaceholderAlbumArt(),
          ),
        ),
      ),
    );
  }


  Widget _buildPlaceholderAlbumArt() {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(13),
      ),
      child: Center(
        child: Text(
          '앨범표지',
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 16,
          ),
        ),
      ),
    );
  }


  Widget _buildPlaybackControls() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Colors.blue,
              inactiveTrackColor: Colors.grey[300],
              thumbColor: Colors.blue,
              trackHeight: 2.0,
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
                  await
                  SpotifySdk.seekTo(
                      positionedMilliseconds: (value * _duration).toInt());
                }
                catch (e) {
                  print('Failed to seek: $e');
                }
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_sliderValue * _duration),
                  style: TextStyle(color: Colors.grey[700]),
                ),
                Text(
                  _formatDuration(_duration),
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(Icons.shuffle, color: Colors.grey[700]),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.skip_previous, color: Colors.black, size: 35),
                onPressed: _playPreviousTrack,
              ),
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.black, size: 45),
                onPressed: _togglePlayPause,
              ),
              IconButton(
                icon: Icon(Icons.skip_next, color: Colors.black, size: 35),
                onPressed: _playNextTrack,
              ),
              IconButton(
                icon: Icon(Icons.repeat, color: Colors.blue),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(double milliseconds) {
    final Duration duration = Duration(milliseconds: milliseconds.toInt());
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(
        2, '0')}';
  }

  Future<void> _authenticate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SpotifyAuthWebView(
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