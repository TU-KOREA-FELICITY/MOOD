// 검색 홈 (검색바, 미니플레이어, 탭 호출)

import 'package:flutter/material.dart';
import 'package:mood/screens/search/search_result_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/spotify_service.dart';
import 'CategoryTagScreen.dart';
import 'Miniplayer.dart';


class SearchView extends StatefulWidget {
  final SpotifyService spotifyService;

  SearchView({
    required this.spotifyService,
  });

  @override
  _SearchViewState createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;
  bool _showCancelIcon = false;
  List<String> recentSearches = [];
  Map<String, List> _searchResults = {'tracks': [], 'playlists': []};


  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isSearching = _focusNode.hasFocus;
      });
    });
    _searchController.addListener(() {
      setState(() {
        _showCancelIcon = _searchController.text.isNotEmpty;
      });
    });
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      recentSearches = prefs.getStringList('recentSearches') ?? [];
    });
  }

  Future<void> _saveRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recentSearches', recentSearches);
  }


  void _addToRecentSearches(String query) {
    setState(() {
      recentSearches.remove(query);
      recentSearches.insert(0, query);
      if (recentSearches.length > 5) {
        recentSearches.removeLast();
      }
    });
    _saveRecentSearches();
  }

  Future _performSearch() async {
    final query = _searchController.text;
    if (query.isEmpty) return;
    try {
      final results = await widget.spotifyService.search(query);
      setState(() {
        _searchResults = results;
      });
      _addToRecentSearches(query);
      final updatedSearches = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SearchResultView(
                spotifyService: widget.spotifyService,
                searchResults: _searchResults,
                searchQuery: query,
                recentSearches: recentSearches,
              ),
        ),
      );
      if (updatedSearches != null) {
        setState(() {
          recentSearches = updatedSearches;
        });
        _saveRecentSearches();
      }
      setState(() {});
    } catch (e) {
      print('검색 중 오류 발생: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(),
            Expanded(
              child: _isSearching
                  ? _buildRecentSearches()
                  : Column(
                children: [
                  Miniplayer(spotifyService: widget.spotifyService),
                  Expanded(
                    child: CategoryTagScreen(spotifyService: widget.spotifyService),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: '곡, 아티스트 검색',
                  hintStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(Icons.search, color: Colors.black),
                  suffixIcon: _showCancelIcon
                      ? IconButton(
                    icon: Icon(Icons.cancel, color: Colors.grey[600]),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _showCancelIcon = false;
                      });
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    _performSearch();
                  }
                },
              ),
            ),
          ),
          if (_isSearching)
            Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isSearching = false;
                  });
                  _focusNode.unfocus();
                },
                child: Text(
                  '취소',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '최근 검색',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: recentSearches.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    child: Icon(Icons.history, color: Colors.grey[800]),
                  ),
                  title: Text(
                    recentSearches[index],
                    style: TextStyle(color: Colors.grey[800]),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.close, color: Colors.grey[800]),
                    onPressed: () {
                      setState(() {
                        recentSearches.removeAt(index);
                      });
                      _saveRecentSearches();
                    },
                  ),
                  onTap: () {
                    _searchController.text = recentSearches[index];
                    _performSearch();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
