//카테고리 태그 -> SongScreen

import 'package:flutter/material.dart';
import '../services/spotify_service.dart';
import '../views/playlist_tracks_view.dart';
import 'SongScreen.dart';

class CategoryTagScreen extends StatefulWidget {
  final SpotifyService spotifyService;
  const CategoryTagScreen({super.key, required this.spotifyService});

  @override
  _CategoryTagScreenState createState() => _CategoryTagScreenState();
}

class _CategoryTagScreenState extends State<CategoryTagScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _playlistNameController = TextEditingController();
  final List<String> _emotionCategories = ['행복', '슬픔', '분노', '놀람', '혐오', '공포', '중립', '경멸'];
  List<dynamic> _playlists = [];
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPlaylists();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showPlaylistTracks(String playlistId, String playlistName) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistTracksView(
          spotifyService: widget.spotifyService,
          playlistId: playlistId,
          playlistName: playlistName,
          isEmotionPlaylist: true,
        ),
      ),
    );
    if (result == true) {
      _loadPlaylists();
    }
  }

  Future<void> _loadPlaylists() async {
    List playlists = await widget.spotifyService.getPlaylists();

    for (String emotion in _emotionCategories) {
      if (!playlists.any((playlist) => playlist['name'] == emotion)) {
        // 해당 감정의 플레이리스트가 없으면 새로 생성
        await widget.spotifyService.createPlaylist(emotion);
        playlists.add({'name': emotion, 'id': 'new_${emotion}_id'});
      }
    }

    setState(() {
      _playlists = playlists;
    });
  }

  Color _getColorForEmotion(String emotion) {
    switch (emotion) {
      case '행복': return Colors.yellow[300]!;
      case '슬픔': return Colors.blue[300]!;
      case '분노': return Colors.red[300]!;
      case '놀람': return Colors.purple[300]!;
      case '혐오': return Colors.green[300]!;
      case '공포': return Colors.black54;
      case '중립': return Colors.grey[300]!;
      case '경멸': return Colors.orange[300]!;
      default: return Colors.grey[300]!;
    }
  }

  Future<void> _deletePlaylist(String playlistId) async {
    try {
      await widget.spotifyService.deletePlaylist(playlistId);
      await _loadPlaylists();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('플레이리스트가 삭제되었습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('플레이리스트 삭제 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                  TabBar(
                    labelColor: Colors.blueAccent[700],
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.blueAccent,
                      controller: _tabController,
                tabs: [
                  Tab(text: '감정 카테고리'),
                  Tab(text: '내 플레이리스트'),
                ],
                ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEmotionCategories(),
                    _buildMyPlaylist(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmotionCategories() {
    return Column(
      children: [
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _emotionCategories.length,
            itemBuilder: (context, index) {
              final emotion = _emotionCategories[index];
              final playlist = _playlists.firstWhere(
                    (p) => p['name'] == emotion,
                orElse: () => {'name': emotion, 'id': 'new_${emotion}_id', 'tracks': {'total': 0}},
              );
              return GestureDetector(
                onTap: () => _showPlaylistTracks(playlist['id'], playlist['name']),
                child: Container(
                  decoration: BoxDecoration(
                    color: _getColorForEmotion(emotion),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Playlist',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          emotion,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${playlist['tracks']['total']}곡',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }



  Widget _buildMyPlaylist() {
    return Column(
      children: [
        SizedBox(height: 7),
        ElevatedButton(
          onPressed: () => _showCreatePlaylistDialog(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent[400],
            foregroundColor: Colors.white,
            minimumSize: Size(200, 45),
            side: BorderSide(color: Colors.blue),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15)
            )
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add,
                size: 25,
                color: Colors.white,
              ),
              SizedBox(width: 8), //아이콘 텍스트 간격
              Text(
                '새 플레이리스트',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16),

        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
            itemCount: _playlists.where((playlist) => !_emotionCategories.contains(playlist['name'])).length,
            itemBuilder: (context, index) {
              final playlist = _playlists.where((playlist) => !_emotionCategories.contains(playlist['name'])).toList()[index];
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
                      playlist['name'],
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${playlist['tracks']['total']}곡'),
                    trailing: IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => _deletePlaylist(playlist['id']),
                    ),
                    onTap: () => _showPlaylistTracks(playlist['id'], playlist['name']),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }



  void _showCreatePlaylistDialog() {
    TextEditingController _playlistNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('새 플레이리스트 생성'),
          content: TextField(
            controller: _playlistNameController,
            decoration: InputDecoration(hintText: "플레이리스트 이름"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('취소',
                style: TextStyle(color: Colors.blueAccent),),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('생성',
              style: TextStyle(color: Colors.blueAccent),),
              onPressed: () async {
                if (_playlistNameController.text.isNotEmpty) {
                  try {
                    await widget.spotifyService.createPlaylist(
                        _playlistNameController.text);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('플레이리스트가 생성되었습니다.')),
                    );
                    await _loadPlaylists();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('플레이리스트 생성 실패: $e')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}