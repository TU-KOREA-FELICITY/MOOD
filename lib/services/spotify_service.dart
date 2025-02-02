import 'package:http/http.dart' as http;
import 'package:spotify_sdk/spotify_sdk.dart';
import 'dart:convert';

class SpotifyService {
  final String clientId = 'b97a6ed3a4d24de0b0ee76f73e54df74';
  final String clientSecret = '3d31c7ba27094d239c015ce6a1b86477';
  final String redirectUri = 'http://localhost:8080/callback';
  final String scopes = 'user-read-playback-state user-modify-playback-state playlist-read-private playlist-read-collaborative user-library-read playlist-modify-private playlist-modify-public streaming';

  String _accessToken = '';
  String _refreshToken = '';
  DateTime? _tokenExpiryTime;

  bool get isConnected => _accessToken.isNotEmpty && !_isTokenExpired();

  Future<void> initialize() async {
    await _refreshTokenIfNeeded();
    if (isConnected) {
      await _initializeSpotifySDK();
    }
  }

  String getAuthUrl() {
    final state = DateTime.now().millisecondsSinceEpoch.toString();
    return 'https://accounts.spotify.com/authorize?client_id=$clientId&response_type=token&redirect_uri=$redirectUri&scope=$scopes&state=$state';
  }

  Future<void> setTokens(Map<String, dynamic> tokens) async {
    _accessToken = tokens['accessToken'] ?? '';
    _refreshToken = tokens['refreshToken'] ?? '';
    _tokenExpiryTime = tokens['expiryTime'];
    await _initializeSpotifySDK();
  }

  Future<void> _initializeSpotifySDK() async {
    try {
      await SpotifySdk.connectToSpotifyRemote(
        clientId: clientId,
        redirectUrl: redirectUri,
      );
    } catch (e) {
      print('Failed to initialize Spotify SDK: $e');
    }
  }

  Future<void> _refreshTokenIfNeeded() async {
    if (_accessToken.isNotEmpty && !_isTokenExpired()) return;
    if (_refreshToken.isNotEmpty) {
      await _refreshAccessToken();
    }
  }

  Future<void> _refreshAccessToken() async {
    if (_refreshToken.isEmpty) return;

    final credentials = base64Encode(utf8.encode('$clientId:$clientSecret'));
    final url = 'https://accounts.spotify.com/api/token';

    try {
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
        _accessToken = data['access_token'];
        _tokenExpiryTime = DateTime.now().add(Duration(seconds: data['expires_in']));
      } else {
        print('토큰 갱신 실패: ${response.body}');
        _accessToken = '';
        _refreshToken = '';
        _tokenExpiryTime = null;
      }
    } catch (e) {
      print('토큰 갱신 중 오류 발생: $e');
      _accessToken = '';
      _refreshToken = '';
      _tokenExpiryTime = null;
    }
  }

  Future<void> logout() async {
    try {
      await SpotifySdk.disconnect();
      _accessToken = '';
      _refreshToken = '';
      _tokenExpiryTime = null;
    } catch (e) {
      print('Failed to disconnect: $e');
    }
  }

  Future<bool> togglePlayPause() async {
    try {
      var playerState = await SpotifySdk.getPlayerState();
      if (playerState != null && playerState.isPaused) {
        await SpotifySdk.resume();
        return true;
      } else {
        await SpotifySdk.pause();
        return false;
      }
    } catch (e) {
      print('Failed to toggle play/pause: $e');
      return false;
    }
  }

  Future<void> playNextTrack() async {
    try {
      await SpotifySdk.skipNext();
    } catch (e) {
      print('Failed to play next track: $e');
    }
  }

  Future<void> playPreviousTrack() async {
    try {
      await SpotifySdk.skipPrevious();
    } catch (e) {
      print('Failed to play previous track: $e');
    }
  }

  Future<Map<String, dynamic>> getCurrentTrackInfo() async {
    try {
      var playerState = await SpotifySdk.getPlayerState();
      if (playerState != null && playerState.track != null) {
        return {
          'name': playerState.track!.name,
          'artist': playerState.track!.artist.name,
          'isPlaying': !playerState.isPaused,
          'albumCoverUrl': playerState.track!.imageUri.raw,
        };
      }
    } catch (e) {
      print('Failed to get current track info: $e');
    }
    return {
      'name': 'No track playing',
      'artist': 'Unknown artist',
      'isPlaying': false,
      'albumCoverUrl': null,
    };
  }

  Future<List<dynamic>> getPlaylists() async {
    await _refreshTokenIfNeeded();
    final url = Uri.parse('https://api.spotify.com/v1/me/playlists');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['items'];
      } else {
        print('Failed to fetch playlists: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching playlists: $e');
      return [];
    }
  }

  Future<List<dynamic>> getPlaylistTracks(String playlistId) async {
    await _refreshTokenIfNeeded();
    final url = Uri.parse('https://api.spotify.com/v1/playlists/$playlistId/tracks');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['items'];
      } else {
        print('Failed to fetch playlist tracks: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching playlist tracks: $e');
      return [];
    }
  }

  Future<void> playTrack(String spotifyUri) async {
    try {
      await SpotifySdk.play(spotifyUri: spotifyUri);
    } catch (e) {
      print('Failed to play track: $e');
      throw e;
    }
  }

  Future<String> getCurrentUserId() async {
    await _refreshTokenIfNeeded();
    final url = Uri.parse('https://api.spotify.com/v1/me');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $_accessToken'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['id'];
    } else {
      throw Exception('사용자 ID 가져오기 실패: ${response.body}');
    }
  }

  Future<String> createPlaylist(String name, {String description = ''}) async {
    await _refreshTokenIfNeeded();
    final userId = await getCurrentUserId();
    final url = 'https://api.spotify.com/v1/users/$userId/playlists';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'description': description,
          'public': false,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['id'];
      } else {
        throw Exception('플레이리스트 생성 실패: ${response.body}');
      }
    } catch (e) {
      print('플레이리스트 생성 중 오류 발생: $e');
      throw e;
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    final url = 'https://api.spotify.com/v1/playlists/$playlistId/followers';
    final headers = {
      'Authorization': 'Bearer $_accessToken',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.delete(Uri.parse(url), headers: headers);

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('플레이리스트가 성공적으로 삭제되었습니다.');
      } else {
        throw Exception('플레이리스트 삭제 실패: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print('플레이리스트 삭제 중 오류 발생: $e');
      throw e;
    }
  }

  Future<void> addTrackToPlaylist(String playlistId, String trackUri) async {
    await _refreshTokenIfNeeded();
    final url = 'https://api.spotify.com/v1/playlists/$playlistId/tracks';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'uris': [trackUri],
        }),
      );

      if (response.statusCode != 201) {
        throw Exception('곡 추가 실패: ${response.body}');
      }
    } catch (e) {
      print('곡 추가 중 오류 발생: $e');
      throw e;
    }
  }

  Future<Map<String, List>> search(String query) async {
    await _refreshTokenIfNeeded();
    final url = Uri.parse('https://api.spotify.com/v1/search?q=$query&type=track,playlist&limit=50');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'tracks': data['tracks']['items'] ?? [],
          'playlists': data['playlists']['items'] ?? [],
        };
      } else {
        print('검색 실패: ${response.statusCode}');
        return {'tracks': [], 'playlists': []};
      }
    } catch (e) {
      print('검색 중 오류 발생: $e');
      return {'tracks': [], 'playlists': []};
    }
  }

  bool _isTokenExpired() {
    if (_tokenExpiryTime == null) return true;
    return DateTime.now().isAfter(_tokenExpiryTime!);
  }
}