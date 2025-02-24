import 'package:flutter/material.dart';

import 'homestart_screens/home_screen.dart';
import 'profilestart_screens/profile_screen.dart';
import 'searchstart_screens/search_screen.dart';
import 'searchstart_screens/service/spotify_service.dart';

class BottomNavigationWidget extends StatefulWidget {
  late final Map<String, dynamic> userInfo;

  BottomNavigationWidget({required this.userInfo});

  @override
  _BottomNavigationWidgetState createState() => _BottomNavigationWidgetState();
}

class _BottomNavigationWidgetState extends State<BottomNavigationWidget> {
  int _currentIndex = 0;
  final SpotifyService _spotifyService = SpotifyService();

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(userInfo: widget.userInfo),
      SearchScreen(spotifyService: _spotifyService, userInfo: widget.userInfo),
      ProfileScreen(userInfo: widget.userInfo),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
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
        selectedItemColor: Color(0xFF0126FA),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}