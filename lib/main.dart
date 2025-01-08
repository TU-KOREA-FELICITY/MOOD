import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face Authentication',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AuthPage(),
    );
  }
}

class AuthPage extends StatefulWidget {
  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isAuthenticating = false;
  String _authStatus = '';

  void _startAuthentication() async {
    setState(() {
      _isAuthenticating = true;
      _authStatus = 'Starting authentication...';
    });

    try {
      await http.post(Uri.parse('http://192.168.121.211:3000/start_auth')); // 10.0.2.2
      _checkAuthStatus();
    } catch (e) {
      setState(() {
        _isAuthenticating = false;
        _authStatus = 'Error starting authentication: $e';
      });
    }
  }

  void _checkAuthStatus() async {
    if (!_isAuthenticating) return;

    try {
      final response = await http.get(Uri.parse('http://192.168.121.211:3000/check_auth'), headers: {'Content-Type': 'application/json'},  // 10.0.2.2
      ).timeout(Duration(seconds: 10));
      final result = json.decode(response.body);

      if (result['authenticated'] == true) {
        setState(() {
          _isAuthenticating = false;
          _authStatus = 'Authentication successful! User ID: ${result['user_id']}';
        });
      } else {
        Future.delayed(Duration(seconds: 2), _checkAuthStatus);
      }
    } catch (e) {
      if (e is TimeoutException) {
        print('Request timed out');
      } else {
        print('Error: $e');
      }
      setState(() {
        _isAuthenticating = false;
        _authStatus = 'Error checking authentication status: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Face Authentication'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _isAuthenticating ? null : _startAuthentication,
              child: Text('Start Authentication'),
            ),
            SizedBox(height: 20),
            Text(_authStatus),
          ],
        ),
      ),
    );
  }
}
