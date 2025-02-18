import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'homestart_screens/home_screen.dart';
import 'profilestart_screens/profile_screen.dart';
import 'searchstart_screens/search_screen.dart';
import 'searchstart_screens/service/spotify_service.dart';

class BottomNavigationWidget extends StatefulWidget {
  @override
  _BottomNavigationWidgetState createState() => _BottomNavigationWidgetState();
}

class _BottomNavigationWidgetState extends State<BottomNavigationWidget> {
  int _currentIndex = 0;
  final SpotifyService _spotifyService = SpotifyService();
  final storage = FlutterSecureStorage();
  Map<String, dynamic>? userInfo;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(),
      SearchScreen(spotifyService: _spotifyService),
      ProfileScreen(),
    ];
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    String? userInfoString = await storage.read(key: 'userInfo');
    if (userInfoString != null) {
      if (mounted) {
        setState(() {
          userInfo = json.decode(userInfoString);
        });
      }
    }
  }

  void _onTabTapped(int index) {
    if (mounted) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: userInfo == null
          ? Center(child: CircularProgressIndicator())
          : _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        iconSize: 30,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: '검색'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '프로필'),
        ],
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF014FFA),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
