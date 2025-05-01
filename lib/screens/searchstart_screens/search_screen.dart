import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'service/spotify_service.dart';
import '../homestart_screens/emotion_analysis_service.dart';
import '../start_screens/spotify_web_login_screen.dart';
import 'widget/miniplayer.dart';
import 'search/search_result_screen.dart';
import 'category/category_tag_screen.dart';

class SearchScreen extends StatefulWidget {
  final SpotifyService spotifyService;
  final Map<String, dynamic> userInfo;
  final List<String>? recentSearches;

  SearchScreen({required this.spotifyService, required this.userInfo, this.recentSearches,});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late SpotifyService _spotifyService;
  final EmotionAnalysisService _emotionAnalysisService = EmotionAnalysisService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isConnected = false;
  bool _isSearching = false;
  bool _showCancelIcon = false;
  List<String> _recentSearches = [];
  Map<String, List> _searchResults = {'tracks': [], 'playlists': []};
  List<Map<String, dynamic>> emotions = [];

  @override
  void initState() {
    super.initState();
    if (widget.recentSearches != null) {
      _recentSearches = List.from(widget.recentSearches!);
    }
    _spotifyService = widget.spotifyService;
    _emotionAnalysisService.setUserInfo(widget.userInfo['user_id']);
    _initializeApp();
    _fetchTag();

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
    _searchController.clear();
    _searchResults = {'tracks': [], 'playlists': []};
    _isSearching = false;
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
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTrackFinished() {
    _emotionAnalysisService.runEmotionAnalysis();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recentSearches') ?? [];
    });
  }

  Future<void> _saveRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recentSearches', _recentSearches);
  }

  void _addToRecentSearches(String query) {
    setState(() {
      _recentSearches.remove(query);
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 5) {
        _recentSearches.removeLast();
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
    } catch (e) {
      print('검색 중 오류 발생: $e');
    }
  }

  Future<void> _fetchTag() async {
    try {
      final data = await _getSearchTag();
      if (data['success']) {
        setState(() {
          emotions = List<Map<String, dynamic>>.from(data['emotions']);
        });
      } else {
        print(data['message']);
      }
    } catch (e) {
    }
  }

  Future<Map<String, dynamic>> _getSearchTag() async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.60.219:3000/get_search_tag'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success']) {
          return {
            'success': true,
            'emotions': List<Map<String, dynamic>>.from(result['emotions']),
          };
        } else {
          return {
            'success': false,
            'message': result['message'] ?? '알 수 없는 오류가 발생했습니다.',
          };
        }
      } else {
        return {
          'success': false,
          'message': '서버 오류: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '태그 가져오는 중 오류 발생: $e',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
            children: [
            Icon(Icons.search, size: 30),
        SizedBox(width: 10),
        Text(
          '검색',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
            ),
          ),
        ],
    ),
        titleSpacing: 16,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
        Padding(
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
            prefixIcon: Icon(Icons.headphones, color: Colors.black),
            suffixIcon: _showCancelIcon
                ? IconButton(
              icon: Icon(Icons.cancel, color: Colors.grey[600]),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _showCancelIcon = false;
                  _isSearching = false;
                });
                _focusNode.unfocus();
              },
            )
                : null,
            border: InputBorder.none,
            contentPadding:
            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onSubmitted: (value) async {
            if (value.isNotEmpty) {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SearchResultScreen(
                        spotifyService: widget.spotifyService,
                        searchResults: _searchResults,
                        searchQuery: value,
                        recentSearches: _recentSearches,
                        userInfo: widget.userInfo,
                      ),
                ),
              );
              if (result != null && result is List<String>) {
                setState(() {
                  _recentSearches = result;
                });
                _saveRecentSearches();
              }
            }
          }
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
        ),
            Expanded(
              child: _isSearching
                  ? _buildRecentSearches()
                  : Column(
                children: [
                  Miniplayer(spotifyService: widget.spotifyService, onTrackFinished: _onTrackFinished,),
                  Expanded(
                    child: CategoryTagScreen(
                      spotifyService: widget.spotifyService, userInfo: widget.userInfo, emotionInfo: emotions, emotionAnalysisService: _emotionAnalysisService,),
                  ),
                ],
              ),
            ),
          ],
        ),
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
              itemCount: _recentSearches.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    child: Icon(Icons.history, color: Colors.grey[800]),
                  ),
                  title: Text(
                    _recentSearches[index],
                    style: TextStyle(color: Colors.grey[800]),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.close, color: Colors.grey[800]),
                    onPressed: () {
                      setState(() {
                        _recentSearches.removeAt(index);
                      });
                      _saveRecentSearches();
                    },
                  ),
                  onTap: () {
                    _searchController.text = _recentSearches[index];
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