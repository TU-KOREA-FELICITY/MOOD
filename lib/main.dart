/*import 'package:flutter/material.dart';
import 'spotify_home_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MOOD',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SpotifyHomePage(),
    );
  }
}*/

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
  String _currentPlaylistName = '';
  String _currentCategoryName = '';
  String _currentCategoryId = '';
  String _selectedCategoryId = '';
  bool _isPlaying = false;
  bool _isLoadingPlaylists = false;
  bool _showCategories = false;
  List<dynamic> _playlists = [];
  List<dynamic> _spotifyPlaylists = [];
  List<dynamic> _playlistTracks = [];
  List<dynamic> _searchResults = [];
  Timer? _updateTimer;
  List<dynamic> _categories = [];
  List<dynamic> _categoryPlaylists = [];

  @override
  void initState() {
    super.initState();
    _updateTimer = Timer.periodic(Duration(seconds: 5), (_) => _updateCurrentTrack());
    _getPlaylists();
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
              onPressed:  () async{
                await _logout();

                setState(() {
                  _connected = false;
                });
              },
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
                child: Text('플레이리스트 새로고침'),
              ),
              Expanded(
                child: _isLoadingPlaylists
                    ? Center(child: CircularProgressIndicator())
                    : _playlists.isNotEmpty
                    ? ListView.builder(
                  itemCount: _playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = _playlists[index];
                    return ListTile(
                      title: Text(playlist['name']),
                      subtitle: Text('${playlist['tracks']['total']} tracks'),
                      onTap: () {
                        _showPlaylistTracks(playlist['id'], playlist['name']);
                      },
                    );
                  },
                )
                    : Center(child: Text('플레이리스트가 없습니다.')),
              ),
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      String newPlaylistName = '';
                      String newPlaylistDescription = '';
                      return AlertDialog(
                        title: Text('새 플레이리스트 만들기'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              decoration: InputDecoration(hintText: "플레이리스트 이름"),
                              onChanged: (value) {
                                newPlaylistName = value;
                              },
                            ),
                            TextField(
                              decoration: InputDecoration(hintText: "설명 (선택사항)"),
                              onChanged: (value) {
                                newPlaylistDescription = value;
                              },
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            child: Text('취소'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          TextButton(
                            child: Text('생성'),
                            onPressed: () {
                              if (newPlaylistName.isNotEmpty) {
                                _createPlaylist(newPlaylistName, description: newPlaylistDescription);
                                Navigator.of(context).pop();
                              }
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Text('새 플레이리스트 만들기'),
              ),

              if (_playlistTracks.isNotEmpty) ...[
                Text(_currentPlaylistName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Expanded(
                  child: ListView.builder(
                    itemCount: _playlistTracks.length,
                    itemBuilder: (context, index) {
                      final track = _playlistTracks[index]['track'];
                      return ListTile(
                        title: Text(track['name']),
                        subtitle: Text(track['artists'][0]['name']),
                        onTap: () {
                          _playTrack(track['uri']);
                        },
                      );
                    },
                  ),
                ),
              ],
              Divider(),
              _buildCategoriesAndPlaylists(),
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

  Widget _buildCategoriesAndPlaylists() {
    return SingleChildScrollView(
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              setState(() {
                _showCategories = !_showCategories;
                if (!_showCategories) {
                  _categories = [];
                  _categoryPlaylists = [];
                } else {
                  _getCategories();
                }
              });
            },
            child: Text(_showCategories ? '카테고리 숨기기' : '카테고리 불러오기'),
          ),
          if (_categories.isNotEmpty)
            SizedBox(
              height: 200,
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((category) {
                    return ElevatedButton(
                      onPressed: () => _getCategoryPlaylists(category['id'], category['name']),
                      child: Text(category['name']),
                    );
                  }).toList(),
                ),),),

          if (_spotifyPlaylists.isNotEmpty)
            Column(
              children: [
                Text('스포티파이 플레이리스트', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: _categoryPlaylists.length,
                    itemBuilder: (context, index) {
                      final playlist = _categoryPlaylists[index];
                      return ListTile(
                        title: Text(playlist['name']),
                        subtitle: Text('${playlist['tracks']['total']}tracks'),
                        leading: playlist['images'].isNotEmpty
                            ? Image.network(
                          playlist['images'][0]['url'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                            : Icon(Icons.music_note),
                        trailing: IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () => _addPlaylistToMyPlaylists(playlist['id']),
                        ),
                        onTap: () {
                          _showPlaylistTracks(playlist['id'], playlist['name']);
                          // 플레이리스트나 앨범 재생 로직 구현
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }


  Future<void> _authenticate() async {
    final clientId = 'b97a6ed3a4d24de0b0ee76f73e54df74';
    final redirectUri = 'http://localhost:8080/callback';
    final scopes = 'app-remote-control user-read-playback-state user-modify-playback-state playlist-read-private playlist-read-collaborative user-library-read playlist-modify-private playlist-modify-public streaming';
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
        _tokenExpiryTime = result['expiryTime'] ??
            DateTime.now().add(Duration(hours: 1));
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
        accessToken: _accessToken,
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

      final controller = WebViewController();
      await controller.clearCache();
      await controller.clearLocalStorage();

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
    setState(() {
      _isLoadingPlaylists = true;
    });
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
          _isLoadingPlaylists = false;
        });
      } else {
        print('Failed to fetch playlists: ${response.statusCode}');
        print('Response body: ${response.body}');
        setState(() {
          _isLoadingPlaylists = false;
        });
      }
    } catch (e) {
      print('Error fetching playlists: $e');
      setState(() {
        _isLoadingPlaylists = false;
      });
    }
  }

  Future<void> _getSpotifyPlaylists() async {
    if (_accessToken.isEmpty || _isTokenExpired()) {
      await _refreshAccessToken();
    }
    final url = Uri.parse('https://api.spotify.com/v1/users/spotify/playlists?limit=50');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _spotifyPlaylists = data['items'];
        });
      } else {
        print('Failed to fetch Spotify playlists: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error fetching Spotify playlists: $e');
    }
  }

  Future<void> _showPlaylistTracks(String playlistId, String playlistName) async {
    if (_accessToken.isEmpty || _isTokenExpired()) {
      await _refreshAccessToken();
    }
    try {
      await _getPlaylistTracks(playlistId);
      setState(() {
        _currentPlaylistName = playlistName;
      });
    } catch (e) {
      print('Failed to show playlist tracks: $e');
    }
  }

  Future<void> _getPlaylistTracks(String playlistId) async {
    if (_accessToken.isEmpty || _isTokenExpired()) {
      await _refreshAccessToken();
    }
    final url = Uri.parse('https://api.spotify.com/v1/playlists/$playlistId/tracks');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _playlistTracks = data['items'];
        });
      } else {
        print('Failed to fetch playlist tracks: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error fetching playlist tracks: $e');
    }
  }

  Future<void> _createPlaylist(String name, {String description = ''}) async {
    if (_accessToken.isEmpty || _isTokenExpired()) {
      await _refreshAccessToken();
    }
    final url = Uri.parse('https://api.spotify.com/v1/me/playlists');
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name,
          'description': description,
          'public': false,
        }),
      );
      if (response.statusCode == 201) {
        print('Playlist created successfully');
        // 플레이리스트 목록 새로고침
        await _getPlaylists();
      } else {
        print('Failed to create playlist: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error creating playlist: $e');
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

  Future<void> _getCategories() async {
    if (_accessToken.isEmpty || _isTokenExpired()) {
      await _refreshAccessToken();
    }
    final url = Uri.parse('https://api.spotify.com/v1/browse/categories?limit=50');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _categories = data['categories']['items'];
        });
      } else {
        print('Failed to get categories: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error getting categories: $e');
    }
  }

  Future<void> _getCategoryPlaylists(String categoryId, String categoryName) async {
    if (_accessToken.isEmpty || _isTokenExpired()) {
      await _refreshAccessToken();
    }
    final url = Uri.parse('https://api.spotify.com/v1/users/spotify/playlists?limit=50');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _spotifyPlaylists = data['items'];
        });
      } else {
        print('Failed to get category playlists: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error fetching Spotify playlists: $e');
    }
  }

  Future<void> getAlbumInfo(String albumId) async {
    final url = Uri.parse('https://api.spotify.com/v1/albums/$albumId');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $_accessToken'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // 앨범 정보 처리
    }
  }

  Future<void> _getCategoryRecommendations(String categoryId) async {
    if (_accessToken.isEmpty || _isTokenExpired()) {
      await _refreshAccessToken();
    }
    final playlistsUrl = Uri.parse('https://api.spotify.com/v1/browse/categories/$categoryId/playlists?limit=10');
    final albumsUrl = Uri.parse('https://api.spotify.com/v1/browse/new-releases?limit=10');

    try {
      final playlistsResponse = await http.get(
        playlistsUrl,
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
      final albumsResponse = await http.get(
        albumsUrl,
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (playlistsResponse.statusCode == 200 && albumsResponse.statusCode == 200) {
        final playlistsData = json.decode(playlistsResponse.body);
        final albumsData = json.decode(albumsResponse.body);

        setState(() {
          _categoryPlaylists = [
            ...playlistsData['playlists']['items'],
            ...albumsData['albums']['items']
          ];
        });
      } else {
        print('Failed to get recommendations: ${playlistsResponse.statusCode}, ${albumsResponse.statusCode}');
      }
    } catch (e) {
      print('Error getting recommendations: $e');
    }
  }

  Future<void> _addPlaylistToMyPlaylists(String playlistId) async {
    if (_accessToken.isEmpty || _isTokenExpired()) {
      await _refreshAccessToken();
    }
    final url = Uri.parse('https://api.spotify.com/v1/playlists/$playlistId/followers');
    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('플레이리스트가 추가되었습니다.')),
        );
        await _getPlaylists(); // 플레이리스트 목록 새로고침
      } else {
        print('Failed to add playlist: ${response.statusCode}');
        print('Response body: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('플레이리스트 추가에 실패했습니다.')),
        );
      }
    } catch (e) {
      print('Error adding playlist: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다.')),
      );
    }
  }

  Future<void> _searchCategoryPlaylists(String query) async {
    if (_accessToken.isEmpty || _isTokenExpired()) {
      await _refreshAccessToken();
    }
    if (_currentCategoryId.isEmpty) {
      print('카테고리가 선택되지 않았습니다.');
      return;
    }
    final url = Uri.parse('https://api.spotify.com/v1/search?q=$query&type=playlist&limit=20');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final allPlaylists = data['playlists']['items'];
        final categoryPlaylists = allPlaylists.where((playlist) {
          return playlist['owner']['id'] == 'spotify' &&
              playlist['description'].toLowerCase().contains(_currentCategoryName.toLowerCase());
        }).toList();

        setState(() {
          _categoryPlaylists = categoryPlaylists;
        });
      } else {
        print('카테고리 내 플레이리스트 검색 실패: ${response.statusCode}');
        print('응답 본문: ${response.body}');
      }
    } catch (e) {
      print('카테고리 내 플레이리스트 검색 오류: $e');
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





