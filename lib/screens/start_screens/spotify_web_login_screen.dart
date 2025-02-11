import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'signup_completion_screen.dart';

class SpotifyAuthWebView extends StatefulWidget {
  final String authUrl;
  final String redirectUri;
  final bool isForSignUp;
  final Map<String, dynamic> userInfo;

  SpotifyAuthWebView(
      {required this.authUrl,
      required this.redirectUri,
      this.isForSignUp = true,
      required this.userInfo});

  @override
  _SpotifyAuthWebViewState createState() => _SpotifyAuthWebViewState();
}

class _SpotifyAuthWebViewState extends State<SpotifyAuthWebView> {
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

    final authData = {
      'accessToken': params['access_token'],
      'refreshToken': params['refresh_token'],
      'expiryTime': DateTime.now().add(
        Duration(seconds: int.tryParse(params['expires_in'] ?? '3600') ?? 3600),
      ),
    };

    if (widget.isForSignUp) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SignUpCompletionScreen(
            authData: authData,
            userInfo: widget.userInfo,
          ),
        ),
      );
    } else {
      Navigator.pop(context, authData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF121212),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Spotify 연동하기',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        titleSpacing: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}
