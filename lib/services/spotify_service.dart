import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

  bool get isConnected {
    // 토큰 유효성 3단계 검증
    final hasValidAccessToken = _accessToken.isNotEmpty;
    final hasUnexpiredToken = !_isTokenExpired();
    final hasRefreshToken = _refreshToken.isNotEmpty;

    return hasValidAccessToken && hasUnexpiredToken && hasRefreshToken;
  }

  Future<void> initialize() async {
    final secureStorage = FlutterSecureStorage();

    // 저장된 토큰 불러오기
    _accessToken = await secureStorage.read(key: 'accessToken') ?? '';
    _refreshToken = await secureStorage.read(key: 'refreshToken') ?? '';
    String? expiryTimeString = await secureStorage.read(key: 'tokenExpiryTime');

    if (expiryTimeString != null) {
      _tokenExpiryTime = DateTime.parse(expiryTimeString);
    }

    // 토큰 갱신 시도
    await _refreshTokenIfNeeded();

    if (_accessToken.isNotEmpty && !_isTokenExpired()) {
      await _initializeSpotifySDK();
    } else {
      print('Spotify 인증 필요');
    }
  }

  String getAuthUrl() {
    final state = DateTime.now().millisecondsSinceEpoch.toString();
    return 'https://accounts.spotify.com/authorize?client_id=$clientId&response_type=token&redirect_uri=$redirectUri&scope=$scopes&state=$state';
  }

  Future<void> setTokens(Map<String, dynamic> tokens) async {
    final secureStorage = FlutterSecureStorage();

    _accessToken = tokens['accessToken'] ?? '';
    _refreshToken = tokens['refreshToken'] ?? '';
    _tokenExpiryTime = tokens['expiryTime'];

    // FlutterSecureStorage에 저장
    await secureStorage.write(key: 'accessToken', value: _accessToken);
    await secureStorage.write(key: 'refreshToken', value: _refreshToken);
    if (_tokenExpiryTime != null) {
      await secureStorage.write(key: 'tokenExpiryTime', value: _tokenExpiryTime!.toIso8601String());
    }

    await _initializeSpotifySDK();
  }

  Future<void> _initializeSpotifySDK() async {
    try {
      bool result = await SpotifySdk.connectToSpotifyRemote(
        clientId: clientId,
        redirectUrl: redirectUri,
      );
      if (result) {
        print('Spotify SDK 연결 성공');
      } else {
        print('Spotify SDK 연결 실패');
      }
    } catch (e) {
      print('Spotify SDK 시작 실패: $e');
    }
  }

  Future<void> _refreshTokenIfNeeded() async {
    if (_accessToken.isNotEmpty && !_isTokenExpired()) return;
    if (_refreshToken.isNotEmpty) {
      await _refreshAccessToken();
    }
  }

  Future<void> _refreshAccessToken() async {
    if (_refreshToken.isEmpty) {
      print('refreshToken 없음. 재로그인 필요');
      return;
    }

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
        _refreshToken = data['refresh_token'] ?? _refreshToken;
        _tokenExpiryTime = DateTime.now().add(Duration(seconds: data['expires_in'] ?? 3600));

        // 갱신된 토큰을 저장
        final secureStorage = FlutterSecureStorage();
        await secureStorage.write(key: 'accessToken', value: _accessToken);
        await secureStorage.write(key: 'tokenExpiryTime', value: _tokenExpiryTime!.toIso8601String());
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
      // SDK 연결 완전 해제
      await SpotifySdk.disconnect();

      // 메모리 내 토큰 초기화
      _accessToken = '';
      _refreshToken = '';
      _tokenExpiryTime = null;

      // 영구 저장소 데이터 삭제
      final secureStorage = FlutterSecureStorage();
      await secureStorage.deleteAll();  // 모든 키 삭제
    } catch (e) {
      print('로그아웃 실패: ${e.toString()}');
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
      print('재생/일시 중지 전환 실패: $e');
      return false;
    }
  }

  Future<void> playNextTrack() async {
    try {
      await SpotifySdk.skipNext();
    } catch (e) {
      print('다음 트랙 재생 실패: $e');
    }
  }

  Future<void> playPreviousTrack() async {
    try {
      await SpotifySdk.skipPrevious();
    } catch (e) {
      print('이전 트랙 재생 실패: $e');
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
      print('현재 트랙 가져오기 실패: $e');
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
        print('플레이리스트 가져오기 실패: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('플레이리스트 가져오기 에러: $e');
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
        print('플레이리스트 트랙 가져오기 실패: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('플레이리스트 트랙 가져오기 에러: $e');
      return [];
    }
  }

  Future<void> playTrack(String spotifyUri) async {
    try {
      await SpotifySdk.play(spotifyUri: spotifyUri);
    } catch (e) {
      print('트랙 재생 실패: $e');
      throw e;
    }
  }

  Future<void> deleteTrack(String playlistId, String trackUri) async {
    await _refreshTokenIfNeeded();
    final url = 'https://api.spotify.com/v1/playlists/$playlistId/tracks';

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'tracks': [{'uri': trackUri}]
        }),
      );

      if (response.statusCode == 200) {
        print('트랙이 성공적으로 삭제되었습니다.');
      } else {
        throw Exception('트랙 삭제 실패: ${response.body}');
      }
    } catch (e) {
      print('트랙 삭제 중 오류 발생: $e');
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