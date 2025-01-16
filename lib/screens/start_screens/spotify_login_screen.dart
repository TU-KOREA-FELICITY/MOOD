import 'package:flutter/material.dart';
import 'spotify_service.dart';
import 'spotify_web_login_screen.dart';

class SpotifyLoginScreen extends StatelessWidget {
  final SpotifyService _spotifyService = SpotifyService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Spotify 로그인')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _navigateToSpotifyLogin(context),
          child: Text('Spotify로 로그인'),
        ),
      ),
    );
  }

  void _navigateToSpotifyLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SpotifyWebLoginScreen(
        authUrl: _spotifyService.getAuthUrl(),
        redirectUri: _spotifyService.redirectUri,
      )),
    );
  }
}
