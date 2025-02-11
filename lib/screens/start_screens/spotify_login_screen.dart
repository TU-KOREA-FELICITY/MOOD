import 'package:flutter/material.dart';
import 'spotify_web_login_screen.dart';
import '../homestart_screens/home_screen.dart';
import '../searchstart_screens/service/spotify_service.dart';

class SpotifyLoginScreen extends StatelessWidget {
  final Map<String, dynamic> userInfo;
  final SpotifyService _spotifyService = SpotifyService();

  SpotifyLoginScreen({required this.userInfo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Spotify 연동하기',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        titleSpacing: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 300),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '스포티파이 계정으로\n로그인하여 음악을 감상하세요.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 300),
            Container(
              width: MediaQuery.of(context).size.width * 0.7,
              child: ElevatedButton(
                onPressed: () => _navigateToSpotifyLogin(context),
                child: Text(
                  'Spotify 로그인하기',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Color(0xFF0126FA)),
                  foregroundColor: MaterialStateProperty.all(Colors.white),
                  padding: MaterialStateProperty.all(
                      EdgeInsets.symmetric(vertical: 12)),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToSpotifyLogin(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => SpotifyAuthWebView(
                authUrl: _spotifyService.getAuthUrl(),
                redirectUri: _spotifyService.redirectUri,
                userInfo: userInfo,
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
