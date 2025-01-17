import 'package:flutter/material.dart';
import 'package:mood/screens/start_screens/spotify_web_login_screen.dart';
import '../homestart_screens/home_screen.dart';
import '../searchstart_screens/spotify_service.dart';
import 'spotify_web_login_screen.dart';

class SpotifyLoginScreen extends StatelessWidget {
  final SpotifyService _spotifyService = SpotifyService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Spotify 로그인')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '스포티파이 계정으로\n로그인하여 음악을 감상하세요.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            ElevatedButton(
              onPressed: () => _navigateToSpotifyLogin(context),
              child: Text('Spotify 로그인'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToSpotifyLogin(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SpotifyAuthWebView(
        authUrl: _spotifyService.getAuthUrl(),
        redirectUri: _spotifyService.redirectUri,
      )),
    );

    if (result != null && result is Map<String, dynamic>) {
      await _spotifyService.setTokens(result);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    }
  }
}
