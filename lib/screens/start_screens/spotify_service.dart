import 'package:http/http.dart' as http;
import 'dart:convert';

class SpotifyService {
  final String clientId = 'b97a6ed3a4d24de0b0ee76f73e54df74';
  final String redirectUri = 'http://localhost:8080/callback';
  final String scope = 'user-read-playback-state user-modify-playback-state playlist-read-private playlist-read-collaborative user-library-read playlist-modify-private playlist-modify-public';

  String? _accessToken;
  String? _refreshToken;

  String getAuthUrl() {
    return 'https://accounts.spotify.com/authorize?client_id=$clientId&response_type=token&redirect_uri=$redirectUri&scope=$scope';
  }

  Future<void> setTokens(Map<String, String> tokens) async {
    _accessToken = tokens['access_token'];
    _refreshToken = tokens['refresh_token'];
  }

  Future<Map<String, dynamic>> getCurrentTrackInfo() async {
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/me/player/currently-playing'),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'name': data['item']['name'],
        'artist': data['item']['artists'][0]['name'],
        'isPlaying': data['is_playing'],
      };
    } else {
      return {'name': null, 'artist': null, 'isPlaying': false};
    }
  }

  Future<void> togglePlayPause() async {
    final currentlyPlaying = await getCurrentTrackInfo();
    final endpoint = currentlyPlaying['isPlaying'] ? 'pause' : 'play';

    await http.put(
      Uri.parse('https://api.spotify.com/v1/me/player/$endpoint'),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );
  }

  Future<void> playNextTrack() async {
    await http.post(
      Uri.parse('https://api.spotify.com/v1/me/player/next'),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );
  }

  Future<void> playPreviousTrack() async {
    await http.post(
      Uri.parse('https://api.spotify.com/v1/me/player/previous'),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );
  }
}
