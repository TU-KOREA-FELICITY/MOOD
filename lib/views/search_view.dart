/*import 'package:flutter/material.dart';
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

 */











import 'package:flutter/material.dart';
import 'package:mood/ui/CategoryTagScreen.dart';
import 'package:mood/services/spotify_service.dart';
import 'package:mood/ui/Search_View.dart';
import 'package:mood/ui/SongScreen.dart';
import 'package:mood/views/spotify_home_page.dart';

class SearchView extends StatefulWidget {
  final SpotifyService spotifyService;
  final Function(int) onTabChange;

  const SearchView({Key? key, required this.spotifyService, required this.onTabChange}) : super(key: key);

  @override
  _SearchViewState createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;
  bool _showCancelIcon = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> _searchResults = [];
  List<String> recentSearches = [];
  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _showCancelIcon = _searchController.text.isNotEmpty;
      });
    });
    _searchController.addListener(() {
      setState(() {
        _showCancelIcon = _searchController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _addToRecentSearches(String query) {
    setState(() {
      recentSearches.remove(query);
      recentSearches.insert(0, query);
      if (recentSearches.length > 5) {
        recentSearches.removeLast();
      }
    });
  }

  void _performSearch() async {
    final query = _searchController.text;
    if (query.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });
      _addToRecentSearches(query);
      List<dynamic> searchResultsDynamic = await widget.spotifyService
          .searchTracks(query);
      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(searchResultsDynamic);
        _isLoading = false;
      });
      if (_searchResults.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                SearchView2(
                  searchResults: _searchResults,
                  spotifyService: widget.spotifyService,
                  category: '',),
          ),
        );
      } else {
        // 검색 결과가 없을 경우 사용자에게 알림
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('검색 결과가 없습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                          decoration: InputDecoration(
                            hintText: '곡, 아티스트 검색',
                            hintStyle: TextStyle(color: Colors.grey),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.search, color: Colors.black),
                              onPressed: _performSearch,
                            ),
                            border: InputBorder.none,
                            filled: true,
                            fillColor: Colors.grey[200],
                          ),
                          onSubmitted: (_) => _performSearch(),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _searchResults.clear();
                          _searchController.clear();
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

                  ]
              ),
            ),

            if (_showCancelIcon)
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())

              :(_isSearching && recentSearches.isEmpty)
                  ? Center(child: Text('최근 검색어가 없습니다.'))
                  : ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(recentSearches[index]),
                    onTap: () {
                      setState(() {
                        _searchController.text=recentSearches[index];
                        _performSearch();
                      });
                    }
                  );
                },
              ),
            )
            else
              Expanded(child: Column(children: [
                Expanded(child: SpotifyHomePage()),
                Expanded(child: CategoryTagScreen(spotifyService: widget.spotifyService)),
              ],))
    ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        iconSize: 30,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: '검색'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '프로필'),
        ],
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 1) {

              } else {
            setState(() {
             widget.onTabChange(index);
            });
      }
        },

        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF014FFA),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
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
                    },
                  ),
                  onTap: () {
                    setState(() {
                      _searchController.text = recentSearches[index];
                      _performSearch();
                    });
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