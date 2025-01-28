// 검색 후 화면

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mood/views/search_view.dart';
import 'package:spotify_sdk/spotify_sdk.dart';

import '../services/spotify_service.dart';
import '../views/playlist_detail_view.dart';

class PlaylistScreen extends StatefulWidget {
  final SpotifyService spotifyService;
  final Map<String, List> searchResults;
  final String searchQuery;
  final List<String> recentSearches;


  const PlaylistScreen({
    Key? key,
    required this.spotifyService,
    required this.searchResults,
    required this.searchQuery,
    required this.recentSearches,
  }) : super(key: key);

  @override
  _PlaylistScreenState createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  bool _showCancelIcon = false;
  bool _isSearchFocused = false;
  late Map<String, List> _searchResults;
  late List<String> _recentSearches;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery;
    _searchResults = widget.searchResults;
    _recentSearches = List.from(widget.recentSearches);
    _searchController.addListener(() {
      setState(() {
        _showCancelIcon = _searchController.text.isNotEmpty;
      });
    });
    _focusNode.addListener(() {
      setState(() {
        _isSearchFocused = _focusNode.hasFocus;
      });
    });
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateCurrentTrack();
      }
    });
  }

  void _addToRecentSearches(String query) {
    setState(() {
      _recentSearches.remove(query);
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 5) {
        _recentSearches.removeLast();
      }
    });
  }

  Future _performSearch() async {
    final query = _searchController.text;
    if (query.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final results = await widget.spotifyService.search(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
        _isSearchFocused = false;
      });
      _addToRecentSearches(query);
    } catch (e) {
      print('검색 중 오류 발생: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateCurrentTrack() async {
    try {
      final playerState = await SpotifySdk.getPlayerState();
      if (playerState != null && playerState.track != null) {
        setState(() {
        });
      }
    } catch (e) {
      print('Failed to get player state: $e');
    }
  }

  Future<List<dynamic>> _getPlaylists() async {
    try {
      return await widget.spotifyService.getPlaylists();
    } catch (e) {
      print('플레이리스트 가져오기 오류: $e');
      return [];
    }
  }

  void _addTrackToPlaylist(String trackUri) async {
    final playlists = await _getPlaylists();

    final selectedPlaylist = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text('플레이리스트 선택'),
          children: playlists.map((playlist) {
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, playlist);
              },
              child: Text(playlist['name'] ?? '알 수 없는 플레이리스트'),
            );
          }).toList(),
        );
      },
    );

    if (selectedPlaylist != null) {
      try {
        await widget.spotifyService.addTrackToPlaylist(
          selectedPlaylist['id'],
          trackUri,
        );
        selectedPlaylist['tracks']['total']++;
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('곡이 플레이리스트에 추가되었습니다.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('곡 추가에 실패했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              //검색
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SearchView(spotifyService: widget.spotifyService),
                        ),
                      ),
                    ),
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
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              _performSearch();
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isSearchFocused)
                _buildRecentSearches()
              else
                Expanded(
                  child: Column(
                    children: [
                      TabBar(
                        labelColor: Colors.blueAccent,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Colors.blueAccent,
                        tabs: [
                          Tab(text: '트랙',),
                          Tab(text: '플레이리스트'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildTracksTab(),
                            _buildPlaylistsTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Expanded(
      child: Padding(
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
                      },
                    ),
                    onTap: () {
                      _searchController.text = _recentSearches[index];
                      _performSearch();
                      _focusNode.unfocus();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildTracksTab() {
    final tracks = _searchResults['tracks'] ?? [];
    if (tracks.isEmpty) {
      return Center(child: Text('검색 결과가 없습니다'));
    }
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '검색 결과',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        SizedBox(height: 8.0),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.0),
            child: ListView(
              children: _buildTrackList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaylistsTab() {
    final playlists = _searchResults['playlists'] ?? [];
    if (playlists.isEmpty) {
      return Center(child: Text('검색 결과가 없습니다'));
    }
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '검색 결과',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        SizedBox(height: 7.0),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical:12.0, horizontal: 16.0),
            child: ListView(
              children: _buildPlaylistList(),
            ),
          ),
        ),
      ],
    );
  }


  List<Widget> _buildTrackList() {
    return (_searchResults['tracks'] as List<dynamic>).map((track) {
      return Container(
        margin: EdgeInsets.symmetric(vertical: 8.0),
        padding: EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track['name'] ?? '알 수 없는 트랙',
                    style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    track['artists']?[0]?['name'] ?? '알 수 없는 아티스트',
                    style: TextStyle(fontSize: 14.0, color: Colors.grey),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.play_arrow, color: Colors.black),
              onPressed: () async {
                await SpotifySdk.play(spotifyUri: track['uri']);
                _updateCurrentTrack();
                // 재생 기능 구현
              },
            ),
            IconButton(
              icon: Icon(Icons.playlist_add, color: Colors.black),
              onPressed: () => _addTrackToPlaylist(track['uri']),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildPlaylistList() {
    return (_searchResults['playlists'] as List<dynamic>).map((playlist) {
      return GestureDetector(
          onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaylistDetailView(
              spotifyService: widget.spotifyService, // spotifyService 인스턴스를 전달해야 합니다
              playlistId: playlist?['id'] ?? '',
              playlistName: playlist?['name'] ?? '알 수 없는 플레이리스트',
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8.0),
        padding: EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist?['name'] ?? '알 수 없는 플레이리스트',
                    style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    '${playlist?['tracks']?['total'] ?? 0} 트랙',
                    style: TextStyle(fontSize: 14.0, color: Colors.grey),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.play_arrow, color: Colors.black),
              onPressed: () async{
                await SpotifySdk.play(spotifyUri: playlist['uri']);
                _updateCurrentTrack();
                // 플레이리스트 재생 기능 구현
              },
            ),
            IconButton(
              icon: Icon(Icons.playlist_add, color: Colors.black),
              onPressed: () {
                // 플레이리스트에 추가 기능 구현
              },
            ),
          ],
        ),
      ),
      );
    }).toList();
  }
}



