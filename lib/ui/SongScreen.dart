// 감정 카테고리 플레이리스트

import 'package:flutter/material.dart';
import 'package:mood/services/spotify_service.dart';
import 'package:mood/views/search_view.dart';

class SongScreen extends StatefulWidget {
  final String title;
  final SpotifyService spotifyService;

  const SongScreen(
      {Key? key, required this.title, required this.spotifyService})
      : super(key: key);

  @override
  _SongScreenState createState() => _SongScreenState();
}

class _SongScreenState extends State<SongScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => SearchView(spotifyService: widget.spotifyService),
              ),
            );
          },
        ),
        title: Text(
          '${widget.title} 플레이리스트', // Concatenate the title with "플레이리스트"
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(
              '편집',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: List.generate(6, (index) {
            return Container(
              width: MediaQuery.of(context).size.width * 0.9,
              // Adjust width here
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(20), // More rounded corners
              ),
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Center(child: Text('노래 ${index + 1}')),
            );
          }),
        ),
      ),
    );
  }
}
