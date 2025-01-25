import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';

import '../services/spotify_service.dart';
import '../widgets/spotify_auth_webview.dart';
import 'search_view.dart';

class SpotifyHomePage extends StatefulWidget {
  @override
  _SpotifyHomePageState createState() => _SpotifyHomePageState();
}

class _SpotifyHomePageState extends State<SpotifyHomePage> with SingleTickerProviderStateMixin {
  final SpotifyService _spotifyService = SpotifyService();
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _spotifyService.initialize();
    final isLoggedIn = await _checkLoginStatus();
    if (isLoggedIn) {
      await _autoLogin();
    }
    setState(() {
      _isConnected = _spotifyService.isConnected;
    });
  }

  Future<bool> _checkLoginStatus() async {
    final value = await _secureStorage.read(key: 'isLoggedIn');
    return value == 'true';
  }

  Future<void> _autoLogin() async {
    final accessToken = await _secureStorage.read(key: 'accessToken');
    final refreshToken = await _secureStorage.read(key: 'refreshToken');
    if (accessToken != null && refreshToken != null) {
      await _spotifyService.setTokens({
        'accessToken': accessToken,
        'refreshToken': refreshToken,
      });
    }
  }

  Future<void> _authenticate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SpotifyAuthWebView(
          authUrl: _spotifyService.getAuthUrl(),
          redirectUri: _spotifyService.redirectUri,
        ),
      ),
    );
    if (result != null && result is Map<String, dynamic>) {
      await _spotifyService.setTokens(result);
      await _secureStorage.write(key: 'isLoggedIn', value: 'true');
      await _secureStorage.write(key: 'accessToken', value: result['accessToken']);
      await _secureStorage.write(key: 'refreshToken', value: result['refreshToken']);
      setState(() {
        _isConnected = true;
      });
    }
  }

  Future<void> _logout() async {
    await _secureStorage.delete(key: 'isLoggedIn');
    await _secureStorage.delete(key: 'accessToken');
    await _secureStorage.delete(key: 'refreshToken');
    setState(() {
      _isConnected = false;
    });
    // 여기에 Spotify SDK를 사용한 로그아웃 로직 추가
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isConnected ? _buildLoggedInView() : _buildLoginView(),
    );
  }

  Widget _buildLoggedInView() {
    return Column(
      children: [
        Expanded(
          child: SearchView(spotifyService: _spotifyService),
        ),
      ],
    );
  }

  Widget _buildLoginView() {
    return Center(
      child: ElevatedButton(
        onPressed: _authenticate,
        child: Text('로그인'),
      ),
    );
  }
}
