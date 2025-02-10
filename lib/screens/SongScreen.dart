// 미사용 파일

import 'package:flutter/material.dart';
import 'package:mood/services/spotify_service.dart';

import 'home/search_view.dart';

class SongScreen extends StatefulWidget {
  final String title;
  final SpotifyService spotifyService;
  const SongScreen(
      {super.key, required this.title, required this.spotifyService});

  @override
  _SongScreenState createState() => _SongScreenState();
}

class _SongScreenState extends State<SongScreen> {
  List<dynamic> tracks = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTracks();
  }

  Future<void> _fetchTracks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
    var fetchedTracks = await widget.spotifyService.getPlaylistTracks(
        widget.title);
    setState(() {
      tracks = fetchedTracks;
      _isLoading = false;
    });
  } catch(e) {
      setState(() {
        _error = '트랙을 불러오는 중 오류가 발생했습니다.';
        _isLoading = false;
      });
    }
  }

  Widget _buildTrackItem(dynamic track) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(20),
      ),
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              track['album']['images'][0]['url'],
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  track['name'],
                  style: TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  track['artists'][0]['name'],
                  style: TextStyle(color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    SearchView(
                      spotifyService: widget.spotifyService),
              ),
            );
          },
        ),
        title: Text(
          '${widget.title} 플레이리스트', // Concatenate the title with "플레이리스트"
          style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black),
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

      body: _isLoading
      ? Center(child: CircularProgressIndicator())
      : _error != null
      ? Center(child: Text(_error!))
      : RefreshIndicator(
        onRefresh: _fetchTracks,
        child: tracks.isEmpty
            ? Center(child: Text('플레이리스트가 비어있습니다.'))
            : ListView.builder(
          itemCount: tracks.length,
          itemBuilder: (context, index) {
            return _buildTrackItem(tracks[index]);
          },
        ),
      ),
    );
  }
}

