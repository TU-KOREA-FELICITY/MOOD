import 'dart:async';
import 'package:flutter/material.dart';

import 'spotify_playlist_screen.dart';
import 'spotify_search_screen.dart';
import 'spotify_service.dart';
import '../start_screens/spotify_web_login_screen.dart';

class SearchScreen extends StatefulWidget {
  final SpotifyService spotifyService;

  SearchScreen({required this.spotifyService});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  late SpotifyService _spotifyService;
  bool _isConnected = false;
  bool _isPlaying = false;
  String _currentTrack = 'No track playing';
  String _artistName = 'Unknown artist';
  late TabController _tabController;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _spotifyService = widget.spotifyService;
    _tabController = TabController(length: 2, vsync: this);
    _initializeApp();
    _startPeriodicUpdate();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticateAutomatically();
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _authenticateAutomatically() async {
    if (!_isConnected) {
      await _authenticate();
    }
  }

  Future<void> _authenticate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SpotifyAuthWebView(
          authUrl: _spotifyService.getAuthUrl(),
          redirectUri: _spotifyService.redirectUri,
          isForSignUp: false,
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

  Future<void> _initializeApp() async {
    final isLoggedIn = await _spotifyService.isLoggedIn();
    setState(() {
      _isConnected = isLoggedIn;
    });
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
      appBar: AppBar(
        title: Text('MOOD'),
        actions: [
          if (_isConnected)
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: _logout,
            ),
        ],
        bottom: _isConnected ? TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: '플레이리스트'),
            Tab(text: '검색'),
          ],
        ) : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildCurrentTrackInfo(),
        _buildPlaybackControls(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              PlaylistView(spotifyService: _spotifyService),
              SearchView(spotifyService: _spotifyService),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentTrackInfo() {
    return Column(
      children: [
        Text('현재 재생 중인 곡:', style: TextStyle(fontSize: 16)),
        Text(
          _currentTrack,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        Text(_artistName, style: TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildPlaybackControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.skip_previous),
          onPressed: _playPreviousTrack,
        ),
        ElevatedButton(
          onPressed: _togglePlayPause,
          child: Text(_isPlaying ? 'Pause' : 'Play'),
        ),
        IconButton(
          icon: Icon(Icons.skip_next),
          onPressed: _playNextTrack,
        ),
      ],
    );
  }

  Future<void> _logout() async {
    await _spotifyService.logout();
    setState(() {
      _isConnected = false;
      _currentTrack = 'No track playing';
      _artistName = 'Unknown artist';
      _isPlaying = false;
    });
  }

  Future<void> _togglePlayPause() async {
    final isPlaying = await _spotifyService.togglePlayPause();
    setState(() {
      _isPlaying = isPlaying;
    });
    _updateCurrentTrack();
  }

  Future<void> _playNextTrack() async {
    await _spotifyService.playNextTrack();
    _updateCurrentTrack();
  }

  Future<void> _playPreviousTrack() async {
    await _spotifyService.playPreviousTrack();
    _updateCurrentTrack();
  }

  Future<void> _updateCurrentTrack() async {
    final trackInfo = await _spotifyService.getCurrentTrackInfo();
    setState(() {
      _currentTrack = trackInfo['name'] ?? 'No track playing';
      _artistName = trackInfo['artist'] ?? 'Unknown artist';
      _isPlaying = trackInfo['isPlaying'] ?? false;
    });
  }
}