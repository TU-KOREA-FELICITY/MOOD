import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'service/spotify_service.dart';
import '../start_screens/spotify_web_login_screen.dart';
import 'widget/miniplayer.dart';
import 'search/search_result_screen.dart';
import 'category/category_tag_screen.dart';

class SearchScreen extends StatefulWidget {
  final SpotifyService spotifyService;
  final Map<String, dynamic> userInfo;

  SearchScreen({required this.spotifyService, required this.userInfo});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late SpotifyService _spotifyService;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isConnected = false;
  bool _isSearching = false;
  bool _showCancelIcon = false;
  List<String> recentSearches = [];
  Map<String, List> _searchResults = {'tracks': [], 'playlists': []};

  @override
  void initState() {
    super.initState();
    _spotifyService = widget.spotifyService;
    _initializeApp();
    // _startPeriodicUpdate();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticateAutomatically();
    });

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

  Future<void> _initializeApp() async {
    final isLoggedIn = await _spotifyService.isLoggedIn();
    setState(() {
      _isConnected = isLoggedIn;
    });
    setState(() {
      _isConnected = _spotifyService.isConnected;
    });
    if (_isConnected) {
      // _updateCurrentTrack();
    }
  }

  Future<void> _authenticateAutomatically() async {
    if (!_isConnected) {
      await _authenticate();
    }
  }

  Future<void> _authenticate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SpotifyAuthWebView(
          authUrl: _spotifyService.getAuthUrl(),
          redirectUri: _spotifyService.redirectUri,
          isForSignUp: false,
          userInfo: {},
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      await _spotifyService.setTokens(result);
      setState(() {
        _isConnected = true;
      });
      // _updateCurrentTrack();
    }
  }

  // void _startPeriodicUpdate() {
  //   _updateTimer = Timer.periodic(Duration(seconds: 1), (timer) {
  //     if (_isConnected) {
  //       _updateCurrentTrack();
  //     }
  //   });
  // }

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
          builder: (context) => SearchResultScreen(
            spotifyService: widget.spotifyService,
            searchResults: _searchResults,
            searchQuery: query,
            recentSearches: recentSearches,
            userInfo: widget.userInfo
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
                          child: CategoryTagScreen(
                              spotifyService: widget.spotifyService, userInfo: widget.userInfo),
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
