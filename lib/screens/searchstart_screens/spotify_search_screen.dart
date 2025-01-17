import 'package:flutter/material.dart';
import 'spotify_search_playlist_screen.dart';
import 'spotify_service.dart';

class SearchView extends StatefulWidget {
  final SpotifyService spotifyService;

  SearchView({required this.spotifyService});

  @override
  _SearchViewState createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  Map<String, List> _searchResults = {'tracks': [], 'playlists': []};
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: '검색',
              suffixIcon: IconButton(
                icon: Icon(Icons.search),
                onPressed: _performSearch,
              ),
            ),
            onSubmitted: (_) => _performSearch(),
          ),
        ),
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : ListView(
            children: [
              _buildSectionHeader('트랙'),
              ..._buildTrackList(),
              _buildSectionHeader('플레이리스트'),
              ..._buildPlaylistList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  List<Widget> _buildTrackList() {
    return _searchResults['tracks']!.map((track) {
      return ListTile(
        title: Text(track['name']),
        subtitle: Text(track['artists'][0]['name']),
        onTap: () => widget.spotifyService.playTrack(track['uri']),
      );
    }).toList();
  }

  List<Widget> _buildPlaylistList() {
    return _searchResults['playlists']?.map((playlist) {
      if (playlist == null) return SizedBox();
      return ListTile(
        title: Text(playlist['name'] ?? '알 수 없는 플레이리스트'),
        subtitle: Text('${playlist['tracks']?['total'] ?? 0} 트랙'),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlaylistDetailView(
                spotifyService: widget.spotifyService,
                playlistId: playlist['id'], // 플레이리스트 ID 전달
                playlistName: playlist['name'] ?? '플레이리스트', // 이름 전달
              ),
            ),
          );
        },
      );
    }).toList() ?? [];
  }

  Future<void> _performSearch() async {
    final query = _searchController.text;
    if (query.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final results = await widget.spotifyService.search(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      print('검색 중 오류 발생: $e');
      setState(() => _isLoading = false);
    }
  }
}
