import 'package:flutter/material.dart';
import 'CategoryTagScreen.dart';
import 'package:mood/services/spotify_service.dart';
import 'package:mood/views/search_view.dart';

class PlaylistScreen extends StatefulWidget {
  final SpotifyService spotifyService;

  const PlaylistScreen({Key? key, required this.spotifyService}) : super(key: key);

  @override
  _PlaylistScreenState createState() => _PlaylistScreenState();
}


class _PlaylistScreenState extends State<PlaylistScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: Icon(Icons.close, color: Colors.black),
            onPressed: () {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchView(spotifyService: widget.spotifyService,
                        onTabChange: (index) {}
                    ),));
            },
          ),
          title: Text(
            '재생목록',
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
        body: Column(
          children: [
            TabBar(
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(text: '노래'),
                Tab(text: '플레이리스트'),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      children: List.generate(6, (index) {
                        return Container(
                          width: double.infinity,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.all(16),
                          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: Text('노래 ${index + 1}'),
                        );
                      }),
                    ),
                  ),
                  SingleChildScrollView(
                    child: Column(
                      children: List.generate(6, (index) {
                        return Container(
                          width: double.infinity,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.all(16),
                          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: Text('플레이리스트 ${index + 1}'),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}