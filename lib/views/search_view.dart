import 'package:flutter/material.dart';
import '../services/spotify_service.dart';

class SearchView extends StatefulWidget {
  final SpotifyService spotifyService;

  SearchView({required this.spotifyService});

  @override
  _SearchViewState createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  List<dynamic> _searchResults = [];
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
              : ListView.builder(
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final track = _searchResults[index];
              return ListTile(
                title: Text(track['name']),
                subtitle: Text(track['artists'][0]['name']),
                onTap: () => widget.spotifyService.playTrack(track['uri']),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _performSearch() async {
    final query = _searchController.text;
    if (query.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final results = await widget.spotifyService.searchTracks(query);
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