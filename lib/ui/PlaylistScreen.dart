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
        setState(() {});
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
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery
                    .of(context)
                    .size
                    .height * 0.55,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.blue[800],
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16.0),
                        topRight: Radius.circular(16.0),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      '플레이리스트 선택',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: playlists.map((playlist) {
                            return Column(
                              children: [
                                ListTile(
                                  leading: Icon(
                                      Icons.add, color: Colors.blueAccent),
                                  title: Text(
                                    playlist['name'] ?? '알 수 없는 플레이리스트',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.pop(context, playlist);
                                  },
                                ),
                                if (playlist != playlists.last)
                                  Divider(
                                    height: 7,
                                    indent: 16, //구분선 좌우 여백
                                    endIndent: 16,
                                  ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
                      onPressed: () =>
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SearchView(
                                      spotifyService: widget.spotifyService),
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
            padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
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
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            leading: _buildAlbumCover(track),
            title: Text(
              track['name'] ?? '알 수 없는 트랙',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(track['artists']?[0]?['name'] ?? '알 수 없는 아티스트'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.play_arrow, color: Colors.black),
                  onPressed: () async {
                    await SpotifySdk.play(spotifyUri: track['uri']);
                    _updateCurrentTrack();
                  },
                ),
                IconButton(
                  icon: Icon(Icons.playlist_add, color: Colors.black),
                  onPressed: () => _addTrackToPlaylist(track['uri']),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }


  Widget _buildAlbumCover(dynamic track) {
    final images = track['album']?['images'] as List?;
    final imageUrl = images?.isNotEmpty == true ? images?.first['url'] as String? : null;

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: imageUrl != null
          ? ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(child: Icon(Icons.music_note, color: Colors.grey[600]));
          },
        ),
      )
          : Center(child: Icon(Icons.music_note, color: Colors.grey[600])),
    );
  }


  List<Widget> _buildPlaylistList() {
  return (_searchResults['playlists'] as List<dynamic>).map((playlist) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          title: Text(
            playlist?['name'] ?? '알 수 없는 플레이리스트',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Text('${playlist?['tracks']?['total'] ?? 0} 트랙'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.play_arrow, color: Colors.black),
                onPressed: () async {
                  await SpotifySdk.play(spotifyUri: playlist['uri']);
                  _updateCurrentTrack();
                },
              ),
              IconButton(
                icon: Icon(Icons.playlist_add, color: Colors.black),
                onPressed: () {
                  // �뚮젅�대━�ㅽ듃�� 異붽� 湲곕뒫 援ы쁽
                },
              ),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    PlaylistDetailView(
                      spotifyService: widget.spotifyService,
                      playlistId: playlist?['id'] ?? '',
                      playlistName: playlist?['name'] ?? '알 수 없는 플레이리스트',
                    ),
              ),
            );
          },
        ),
      ),
    );
  }).toList();
}
}