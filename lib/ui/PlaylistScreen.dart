import 'package:flutter/material.dart';
import 'package:mood/services/spotify_service.dart';
import 'package:mood/views/playlist_detail_view.dart';

class PlaylistScreen extends StatefulWidget {
  final SpotifyService spotifyService;
  final Map<String, List> searchResults;

  const PlaylistScreen({
    Key? key,
    required this.spotifyService,
    required this.searchResults,
  }) : super(key: key);

  @override
  _PlaylistScreenState createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  bool _isLoading = false;
  late Map<String, List> _searchResults;

  @override
  void initState() {
    super.initState();
    _searchResults = widget.searchResults;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            '검색 결과',
            style: TextStyle(color: Colors.black),
          ),
          bottom: TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
            tabs: [
              Tab(text: '트랙'),
              Tab(text: '플레이리스트'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTracksTab(),
            _buildPlaylistsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTracksTab() {
    final tracks = widget.searchResults['tracks'] ?? [];
    if (tracks.isEmpty) {
      return Center(child: Text('검색 결과가 없습니다'));
    }
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : ListView(
      children: _buildTrackList(),
    );
  }

  Widget _buildPlaylistsTab() {
    final playlists = widget.searchResults['playlists'] ?? [];
    if (playlists.isEmpty) {
      return Center(child: Text('검색 결과가 없습니다'));
    }
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : ListView(
      children: _buildPlaylistList(),
    );
  }

  List<Widget> _buildTrackList() {
    return (_searchResults['tracks'] as List<dynamic>).map((track) {
      return ListTile(
        title: Text(track['name'] ?? '알 수 없는 트랙'),
        subtitle: Text(track['artists']?[0]?['name'] ?? '알 수 없는 아티스트'),
        onTap: () => widget.spotifyService.playTrack(track['uri']),
      );
    }).toList();
  }

  List<Widget> _buildPlaylistList() {
    return (_searchResults['playlists'] as List<dynamic>).map((playlist) {
      return ListTile(
        title: Text(playlist?['name'] ?? '알 수 없는 플레이리스트'),
        subtitle: Text('${playlist?['tracks']?['total'] ?? 0} 트랙'),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlaylistDetailView(
                spotifyService: widget.spotifyService,
                playlistId: playlist?['id'] ?? '',
                playlistName: playlist?['name'] ?? '플레이리스트',
              ),
            ),
          );
        },
      );
    }).toList();
  }
}
