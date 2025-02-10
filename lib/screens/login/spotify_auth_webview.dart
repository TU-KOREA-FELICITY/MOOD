import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SpotifyAuthWebView extends StatefulWidget {
  final String authUrl;
  final String redirectUri;

  SpotifyAuthWebView({required this.authUrl, required this.redirectUri});

  @override
  _SpotifyAuthWebViewState createState() => _SpotifyAuthWebViewState();
}

class _SpotifyAuthWebViewState extends State<SpotifyAuthWebView> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..clearCache()
      ..clearLocalStorage()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith(widget.redirectUri)) {
              final uri = Uri.parse(request.url);
              final fragments = uri.fragment.split('&');
              final Map<String, dynamic> params = {};
              for (final fragment in fragments) {
                final split = fragment.split('=');
                if (split.length == 2) {
                  params[split[0]] = Uri.decodeComponent(split[1]);
                }
              }
              Navigator.pop(context, {
                'accessToken': params['access_token'],
                'refreshToken': params['refresh_token'],
                'expiryTime': DateTime.now().add(
                  Duration(seconds: int.tryParse(params['expires_in'] ?? '3600') ?? 3600),
                ),
              });
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Spotify 로그인'),
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}