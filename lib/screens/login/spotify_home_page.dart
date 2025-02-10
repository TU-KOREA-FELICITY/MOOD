// 앱 로그인 화면

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';

import '../../services/spotify_service.dart';

import '../home/search_view.dart';
import 'spotify_auth_webview.dart';

class SpotifyHomePage extends StatefulWidget {
  @override
  _SpotifyHomePageState createState() => _SpotifyHomePageState();
}

class _SpotifyHomePageState extends State<SpotifyHomePage> with SingleTickerProviderStateMixin {
  final SpotifyService _spotifyService = SpotifyService();
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  bool _isConnected = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _spotifyService.initialize();

    // 통합 검증 로직
    final isLoggedIn = await _checkLoginStatus();
    final isSdkConnected = _spotifyService.isConnected;

    if (isLoggedIn && isSdkConnected) {
      await _autoLogin();
      setState(() {
        _isConnected = true;
      });
    }
    setState(() {
      _isInitialized = true;
    });
  }

  Future<bool> _checkLoginStatus() async {
    final accessToken = await _secureStorage.read(key: 'accessToken');
    final refreshToken = await _secureStorage.read(key: 'refreshToken');
    final isLoggedIn = await _secureStorage.read(key: 'isLoggedIn');

    print('accessToken: $accessToken');
    print('refreshToken: $refreshToken');
    print('isLoggedIn: $isLoggedIn');

    // 3가지 값 모두 존재해야 유효한 로그인 상태로 판단
    return isLoggedIn == 'true' && accessToken != null && refreshToken != null;
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

  Future<void> authenticate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SpotifyAuthWebView(
          authUrl: _spotifyService.getAuthUrl(),
          redirectUri: _spotifyService.redirectUri,
        ),
      ),
    );

    print('Authentication result: $result');

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

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        color: Colors.white,
        child: Center(
          child: CircularProgressIndicator(
            backgroundColor: Colors.white,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
      );
    }
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
        onPressed: authenticate,
        child: Text('로그인'),
      ),
    );
  }
}
