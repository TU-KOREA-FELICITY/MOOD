import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../homestart_screens/home_screen.dart';

class SpotifyWebLoginScreen extends StatefulWidget {
  final String authUrl;
  final String redirectUri;

  SpotifyWebLoginScreen({required this.authUrl, required this.redirectUri});

  @override
  _SpotifyWebLoginScreenState createState() => _SpotifyWebLoginScreenState();
}

class _SpotifyWebLoginScreenState extends State<SpotifyWebLoginScreen> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith(widget.redirectUri)) {
              _handleRedirect(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authUrl));
  }

  void _handleRedirect(String url) {
    final uri = Uri.parse(url);
    final fragment = uri.fragment;
    final params = Uri.splitQueryString(fragment);
    final accessToken = params['access_token'];

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Spotify 로그인')),
      body: WebViewWidget(controller: controller),
    );
  }
}
