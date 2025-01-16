import 'package:flutter/material.dart';
import '../services/spotify_service.dart';

class PlaylistView extends StatefulWidget {
  final SpotifyService spotifyService;

  PlaylistView({required this.spotifyService});

  @override
  _PlaylistViewState createState() => _PlaylistViewState();
}

class _PlaylistViewState extends State<PlaylistView> {
  List<dynamic> _playlists = [];
  TextEditingController _playlistNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    setState(() => _isLoading = true);
    try {
      final playlists = await widget.spotifyService.getPlaylists();
      setState(() {
        _playlists = playlists;
        _isLoading = false;
      });
    } catch (e) {
      print('플레이리스트 로딩 중 오류 발생: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createPlaylist() async {
    final name = _playlistNameController.text;
    if (name.isNotEmpty) {
      try {
        await widget.spotifyService.createPlaylist(name);
        _playlistNameController.clear();
        await _loadPlaylists();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('플레이리스트 생성 실패: $e')),
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
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            '재생목록',
            style: TextStyle(color: Colors.black),
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
        body: Column(
          children: [
            TabBar(
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(text: '노래'),
                Tab(text: '플레이리스트'),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                children: [
                  // 노래 탭
                  SingleChildScrollView(
                    child: Column(
                      children: List.generate(6, (index) {
                        return Container(
                          width: double.infinity,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.all(16),
                          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: Text('노래 ${index + 1}'),
                        );
                      }),
                    ),
                  ),
                  // 플레이리스트 탭
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _playlistNameController,
                                decoration: InputDecoration(
                                  hintText: '새 플레이리스트 이름',
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _createPlaylist,
                              child: Text('생성'),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _isLoading
                            ? Center(child: CircularProgressIndicator())
                            : ListView.builder(
                          itemCount: _playlists.length,
                          itemBuilder: (context, index) {
                            final playlist = _playlists[index];
                            return Container(
                              width: double.infinity,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.all(16),
                              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              child: ListTile(
                                title: Text(playlist['name']),
                                subtitle: Text('${playlist['tracks']['total']} 트랙'),
                                onTap: () => _showPlaylistTracks(playlist['id'], playlist['name']),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlaylistTracks(String playlistId, String playlistName) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistTracksView(
          spotifyService: widget.spotifyService,
          playlistId: playlistId,
          playlistName: playlistName,
        ),
      ),
    );
    if (result == true) {
      _loadPlaylists();
    }
  }
}

class PlaylistTracksView extends StatefulWidget {
  final SpotifyService spotifyService;
  final String playlistId;
  final String playlistName;

  PlaylistTracksView({
    required this.spotifyService,
    required this.playlistId,
    required this.playlistName,
  });

  @override
  _PlaylistTracksViewState createState() => _PlaylistTracksViewState();
}

class _PlaylistTracksViewState extends State<PlaylistTracksView> {
  List<dynamic> _tracks = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    setState(() => _isLoading = true);
    try {
      final tracks = await widget.spotifyService.getPlaylistTracks(widget.playlistId);
      setState(() {
        _tracks = tracks;
        _isLoading = false;
      });
    } catch (e) {
      print('트랙 로딩 중 오류 발생: $e');
      setState(() => _isLoading = false);
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.playlistName)),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _tracks.length,
        itemBuilder: (context, index) {
          final track = _tracks[index]['track'];
          return ListTile(
            title: Text(track['name']),
            subtitle: Text(track['artists'][0]['name']),
            trailing: IconButton(
              icon: Icon(Icons.playlist_add),
              onPressed: () => _addTrackToPlaylist(track['uri']),
            ),
            onTap: () => widget.spotifyService.playTrack(track['uri']),
          );
        },
      ),
    );
  }
}