import 'package:flutter/material.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SpotifyHomePage(),
    );
  }
}

class SpotifyHomePage extends StatefulWidget {
  @override
  _SpotifyHomePageState createState() => _SpotifyHomePageState();
}

class _SpotifyHomePageState extends State<SpotifyHomePage> {
  bool _connected = false;
  String _accessToken = '';
  String _refreshToken = '';
  DateTime? _tokenExpiryTime;
  String _currentTrack = 'No track playing';
  String _artistName = 'Unknown artist';
  bool _isPlaying = false;
  List<dynamic> _playlists = [];
  List<dynamic> _searchResults = [];
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _updateTimer = Timer.periodic(Duration(seconds: 5), (_) => _updateCurrentTrack());
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MOOD'),
        actions: [
          if (_connected)
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: _logout,
            ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _connected ? _disconnect : _authenticate,
              child: Text(_connected ? '연결 끊기' : '로그인'),
            ),
            SizedBox(height: 20),
            if (_connected) ...[
              Text('현재 재생 중인 곡:', style: TextStyle(fontSize: 16)),
              SizedBox(height: 10),
              Text(
                _currentTrack,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Text(_artistName, style: TextStyle(fontSize: 16)),
              SizedBox(height: 20),
              Row(
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
              ),
              Divider(),
              ElevatedButton(
                onPressed: _getPlaylists,
                child: Text('플레이리스트'),
              ),
              Expanded(
                child: _playlists.isNotEmpty
                    ? ListView.builder(
                  itemCount: _playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = _playlists[index];
                    return ListTile(
                      title: Text(playlist['name']),
                      subtitle: Text('${playlist['tracks']['total']} tracks'),
                      onTap: () {
                        print('Selected playlist: ${playlist['name']}');
                      },
                    );
                  },
                )
                    : Center(child: Text('플레이리스트가 없습니다.')),
              ),
              Divider(),
              TextField(
                decoration: InputDecoration(
                  labelText: '검색',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (query) => _searchMusic(query),
              ),
              Expanded(
                child: _searchResults.isNotEmpty
                    ? ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final track = _searchResults[index];
                    return ListTile(
                      title: Text(track['name']),
                      subtitle: Text(track['artists'][0]['name']),
                      onTap: () {
                        _playTrack(track['uri']);
                      },
                    );
                  },
                )
                    : Center(child: Text('검색 결과가 없습니다.')),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _authenticate() async {
    final clientId = 'b97a6ed3a4d24de0b0ee76f73e54df74';
    final redirectUri = 'http://localhost:8080/callback';
    final scopes = 'user-read-playback-state user-modify-playback-state playlist-read-private playlist-read-collaborative user-library-read';
    final state = DateTime.now().millisecondsSinceEpoch.toString();
    final authUrl = 'https://accounts.spotify.com/authorize?client_id=$clientId&response_type=token&redirect_uri=$redirectUri&scope=$scopes&state=$state';

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SpotifyAuthWebView(authUrl: authUrl, redirectUri: redirectUri),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _accessToken = result['accessToken'] ?? '';
        _refreshToken = result['refreshToken'] ?? '';
        _tokenExpiryTime = result['expiryTime'] ?? DateTime.now().add(Duration(hours: 1));
        _connected = true;
      });
      await _initializeSpotifySDK();
      await _updateCurrentTrack();
    }
  }

  Future<void> _initializeSpotifySDK() async {
    try {
      await SpotifySdk.connectToSpotifyRemote(
        clientId: 'b97a6ed3a4d24de0b0ee76f73e54df74',
        redirectUrl: 'http://localhost:8080/callback',
      );
    } catch (e) {
      print('Failed to initialize Spotify SDK: $e');
    }
  }

  Future<void> _refreshAccessToken() async {
    if (_refreshToken.isEmpty) return;
    final clientId = 'b97a6ed3a4d24de0b0ee76f73e54df74';
    final clientSecret = '3d31c7ba27094d239c015ce6a1b86477';
    final credentials = base64Encode(utf8.encode('$clientId:$clientSecret'));
    final url = 'https://accounts.spotify.com/api/token';
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': _refreshToken,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _accessToken = data['access_token'];
        _tokenExpiryTime = DateTime.now().add(Duration(seconds: data['expires_in']));
      });
    } else {
      print('Failed to refresh token: ${response.body}');
    }
  }

  Future<void> _logout() async {
    try {
      await SpotifySdk.disconnect();
      _updateTimer?.cancel();

      final controller = WebViewController();
      WebViewController().clearCache();
      WebViewController().clearLocalStorage();

      setState(() {
        _connected = false;
        _accessToken = '';
        _refreshToken = '';
        _tokenExpiryTime = null;
        _playlists = [];
        _searchResults = [];
        _currentTrack = 'No track playing';
        _artistName = 'Unknown artist';
        _isPlaying = false;
      });
      print("Logged out: Tokens and session cleared");
    } catch (e) {
      print('Failed to disconnect: $e');
    }
  }

  Future<void> _disconnect() async {
    try {
      await SpotifySdk.disconnect();
      setState(() {
        _connected = false;
        _currentTrack = 'No track playing';
        _artistName = 'Unknown artist';
        _isPlaying = false;
      });
      print("Spotify disconnected successfully");
    } catch (e) {
      print('Failed to disconnect: $e');
    }
  }

  Future<void> _togglePlayPause() async {
    try {
      var playerState = await SpotifySdk.getPlayerState();
      if (playerState != null && playerState.isPaused) {
        await SpotifySdk.resume();
        setState(() => _isPlaying = true);
      } else {
        await SpotifySdk.pause();
        setState(() => _isPlaying = false);
      }
      _updateCurrentTrack();
    } catch (e) {
      print('Failed to toggle play/pause: $e');
    }
  }

  Future<void> _playTrack(String spotifyUri) async {
    try {
      await SpotifySdk.play(spotifyUri: spotifyUri);
      _updateCurrentTrack();
    } catch (e) {
      print('Failed to play track: $e');
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
      var playerState = await SpotifySdk.getPlayerState();
      if (playerState != null && playerState.track != null) {
        setState(() {
          _currentTrack = playerState.track!.name;
          _artistName = playerState.track!.artist.name!;
          _isPlaying = !playerState.isPaused;
        });
      } else {
        setState(() {
          _currentTrack = 'No track playing';
          _artistName = 'Unknown artist';
          _isPlaying = false;
        });
      }
    } catch (e) {
      print('Failed to update current track: $e');
      setState(() {
        _currentTrack = 'Error fetching track';
        _artistName = 'Unknown';
        _isPlaying = false;
      });
    }
  }

  Future<void> _getPlaylists() async {
    if (_accessToken.isEmpty || _isTokenExpired()) {
      await _refreshAccessToken();
    }
    final url = Uri.parse('https://api.spotify.com/v1/me/playlists');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _playlists = data['items'];
        });
      } else {
        print('Failed to fetch playlists: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error fetching playlists: $e');
    }
  }

  Future<void> _searchMusic(String query) async {
    if (_accessToken.isEmpty || _isTokenExpired()) {
      await _refreshAccessToken();
    }
    final url = Uri.parse('https://api.spotify.com/v1/search?q=$query&type=track&limit=10');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _searchResults = data['tracks']['items'];
        });
      } else {
        print('Failed to search music: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error searching music: $e');
    }
  }

  bool _isTokenExpired() {
    if (_tokenExpiryTime == null) return true;
    return DateTime.now().isAfter(_tokenExpiryTime!);
  }
}

class SpotifyAuthWebView extends StatefulWidget {
  final String authUrl;
  final String redirectUri;

  SpotifyAuthWebView({required this.authUrl, required this.redirectUri});

  @override
  _SpotifyAuthWebViewState createState() => _SpotifyAuthWebViewState();
}

class _SpotifyAuthWebViewState extends State<SpotifyAuthWebView> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..clearCache()
      ..clearLocalStorage()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith(widget.redirectUri)) {
              final uri = Uri.parse(request.url);
              final fragments = uri.fragment.split('&');
              final Map<String, dynamic> params = {};
              for (final fragment in fragments) {
                final split = fragment.split('=');
                if (split.length == 2) {
                  params[split[0]] = Uri.decodeComponent(split[1]);
                }
              }
              Navigator.pop(context, {
                'accessToken': params['access_token'],
                'refreshToken': params['refresh_token'],
                'expiryTime': DateTime.now().add(
                  Duration(seconds: int.tryParse(params['expires_in'] ?? '3600') ?? 3600),
                ),
              });
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Spotify'),
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}
