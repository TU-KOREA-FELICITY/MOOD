import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:spotify_sdk/spotify_sdk.dart';
import 'dart:convert';

class SpotifyService {
  final String clientId = 'b97a6ed3a4d24de0b0ee76f73e54df74';
  final String clientSecret = '3d31c7ba27094d239c015ce6a1b86477';
  final String redirectUri = 'http://127.0.0.1:8080/callback';
  final String scopes =
      'user-read-playback-state user-modify-playback-state playlist-read-private playlist-read-collaborative user-library-read playlist-modify-private playlist-modify-public streaming';

  String _accessToken = '';
  String _refreshToken = '';
  DateTime? _tokenExpiryTime;

  bool get isConnected => _accessToken.isNotEmpty && !_isTokenExpired();

  Future<void> initialize() async {
    final secureStorage = FlutterSecureStorage();
    _accessToken = await secureStorage.read(key: 'accessToken') ?? '';
    _refreshToken = await secureStorage.read(key: 'refreshToken') ?? '';
    String? expiryTimeString = await secureStorage.read(key: 'tokenExpiryTime');

    await _refreshTokenIfNeeded();

    if (isConnected) {
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
    _tokenExpiryTime =
        tokens['expiryTime'] ?? DateTime.now().add(Duration(hours: 1));

    await secureStorage.write(key: 'accessToken', value: _accessToken);
    await secureStorage.write(key: 'refreshToken', value: _refreshToken);
    if (_tokenExpiryTime != null) {
      await secureStorage.write(
          key: 'tokenExpiryTime', value: _tokenExpiryTime!.toIso8601String());
    }

    if (_accessToken.isNotEmpty) {
      print('Access token 설정됨: $_accessToken');
      await _initializeSpotifySDK();
    } else {
      print('Access token 설정 실패');
    }
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
        print('새 토큰 받음: ${response.body}');
        final data = json.decode(response.body);
        _accessToken = data['access_token'];
        _tokenExpiryTime =
            DateTime.now().add(Duration(seconds: data['expires_in']));
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

  bool _isTokenExpired() {
    if (_tokenExpiryTime == null) return true;
    return DateTime.now().isAfter(_tokenExpiryTime!);
  }

  Future<bool> isLoggedIn() async {
    return _accessToken != null && _accessToken.isNotEmpty;
  }

  Future<void> logout() async {
    try {
      await SpotifySdk.disconnect();

      _accessToken = '';
      _refreshToken = '';
      _tokenExpiryTime = null;

      final secureStorage = FlutterSecureStorage();
      await secureStorage.deleteAll();
    } catch (e) {
      print('로그아웃 실패: $e');
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

    final secureStorage = FlutterSecureStorage();
    _accessToken = await secureStorage.read(key: 'accessToken') ?? '';
    _refreshToken = await secureStorage.read(key: 'refreshToken') ?? '';
    String? expiryTimeString = await secureStorage.read(key: 'tokenExpiryTime');

    if (_accessToken.isEmpty) {
      print('Access token이 비어 있음');
      throw Exception('Access token이 없습니다.');
    }

    final url = Uri.parse('https://api.spotify.com/v1/me');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['id'];
      } else {
        print('사용자 ID 가져오기 실패: ${response.body}');
        throw Exception('사용자 ID 가져오기 실패');
      }
    } catch (e) {
      print('getCurrentUserId 중 오류 발생: $e');
      throw e;
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

  Future<List<dynamic>> getPlaylistTracks(String playlistId) async {
    await _refreshTokenIfNeeded();
    final url =
        Uri.parse('https://api.spotify.com/v1/playlists/$playlistId/tracks');
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

  Future<int> addTrackToPlaylist(
      String playlistId, List<String> trackUris) async {
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
          'uris': trackUris,
        }),
      );
      if (response.statusCode == 201) {
        print('곡이 성공적으로 추가되었습니다.');
        return await updatePlaylistInfo(playlistId);
      } else {
        throw Exception('곡 추가 실패: ${response.body}');
      }
    } catch (e) {
      print('곡 추가 중 오류 발생: $e');
      throw e;
    }
  }

  Future<int> deleteTrackFromPlaylist(
      String playlistId, String trackUri) async {
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
          'tracks': [
            {'uri': trackUri}
          ],
        }),
      );

      if (response.statusCode == 200) {
        print('곡이 성공적으로 삭제되었습니다.');
        return await updatePlaylistInfo(playlistId);
      } else {
        throw Exception('곡 삭제 실패: ${response.body}');
      }
    } catch (e) {
      print('곡 삭제 중 오류 발생: $e');
      throw e;
    }
  }

  Future<List<dynamic>> getPlaylists() async {
    await _refreshTokenIfNeeded();

    final secureStorage = FlutterSecureStorage();
    _accessToken = await secureStorage.read(key: 'accessToken') ?? '';
    _refreshToken = await secureStorage.read(key: 'refreshToken') ?? '';
    String? expiryTimeString = await secureStorage.read(key: 'tokenExpiryTime');

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

  Future<int> updatePlaylistInfo(String playlistId) async {
    final url = 'https://api.spotify.com/v1/playlists/$playlistId';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final int totalTracks = data['tracks']['total'];
        return totalTracks;
      } else {
        throw Exception('플레이리스트 정보 가져오기 실패: ${response.body}');
      }
    } catch (e) {
      print('플레이리스트 정보 업데이트 중 오류 발생: $e');
      throw e;
    }
  }

  Future<void> updatePlaylistDetails({
    required String playlistId,
    String? name,
    String? description,
    bool? public,
    bool? collaborative,
  }) async {
    await _refreshTokenIfNeeded();

    final url = 'https://api.spotify.com/v1/playlists/$playlistId';

    // 업데이트할 필드만 포함하는 맵을 생성합니다.
    final Map<String, dynamic> body = {};
    if (name != null) {
      body['name'] = name;
    }
    if (description != null) {
      body['description'] = description;
    }
    if (public != null) {
      body['public'] = public;
    }
    if (collaborative != null) {
      body['collaborative'] = collaborative;
    }

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print('플레이리스트 정보가 성공적으로 업데이트되었습니다.');
      } else {
        throw Exception(
            '플레이리스트 정보 업데이트 실패: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print('플레이리스트 정보 업데이트 중 오류 발생: $e');
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
        throw Exception(
            '플레이리스트 삭제 실패: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print('플레이리스트 삭제 중 오류 발생: $e');
      throw e;
    }
  }

  Future<Map<String, List>> search(String query) async {
    await _refreshTokenIfNeeded();
    final url = Uri.parse(
        'https://api.spotify.com/v1/search?q=$query&type=track,playlist&limit=50');
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

  Future<Map<String, dynamic>> searchPlaylists(String query) async {
    await _refreshTokenIfNeeded();
    final encodedQuery = Uri.encodeComponent(query);
    final url = Uri.parse(
        'https://api.spotify.com/v1/search?q=$encodedQuery&type=playlist&limit=10');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'playlists': data['playlists']['items']};
      } else {
        print('플레이리스트 검색 실패: ${response.statusCode}');
        print('에러 메시지: ${response.body}');
        return {'playlists': []};
      }
    } catch (e) {
      print('플레이리스트 검색 중 오류 발생: $e');
      return {'playlists': []};
    }
  }

  Future<List<String>> addTracksToPlaylist(
      String playlistId, List<String> trackUris) async {
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
          'uris': trackUris,
        }),
      );
      if (response.statusCode == 201) {
        print('트랙이 성공적으로 추가되었습니다.');
        return trackUris;
      } else {
        print('트랙 추가 실패: ${response.statusCode}');
        print('에러 메시지: ${response.body}');
        throw Exception('트랙 추가 실패: ${response.body}');
      }
    } catch (e) {
      print('트랙 추가 중 오류 발생: $e');
      throw e;
    }
  }
}
