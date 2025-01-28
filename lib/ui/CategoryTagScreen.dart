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
                controller: _tabController,
                tabs: [
                  Tab(text: '감정 카테고리'),
                  Tab(text: '내 플레이리스트'),
                ],
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
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
    return GridView.builder(
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
          orElse: () => {'name': emotion, 'id': 'new_${emotion}_id'},
        );
        return _buildCategoryCard(playlist['name'], _getColorForEmotion(playlist['name']));
      },
    );
  }

  Widget _buildMyPlaylist() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => _showCreatePlaylistDialog(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            minimumSize: Size(200, 50),
            side: BorderSide(color: Colors.blueAccent),
          ),
          child: Text(
            '새 플레이리스트 생성',
            style: TextStyle(color: Colors.blueAccent),
          ),
        ),
        SizedBox(height: 16),

        /*Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
            itemCount: _playlists.length,
            itemBuilder: (context, index) {
              final playlist = _playlists[index];
              return ListTile(
                title: Text(playlist['name']),
                subtitle: Text('${playlist['tracks']['total']} 트랙'),
                onTap: () => _showPlaylistTracks(playlist['id'], playlist['name']),
                trailing: IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => _deletePlaylist(playlist['id']),
                ),
              );
            },
          ),
        ),*/

        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
            itemCount: _playlists.where((playlist) => !_emotionCategories.contains(playlist['name'])).length,
            itemBuilder: (context, index) {
              final playlist = _playlists.where((playlist) => !_emotionCategories.contains(playlist['name'])).toList()[index];
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      title: Text(
                        playlist['name'],
                        style: TextStyle(fontSize:20, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${playlist['tracks']['total']} 트랙'),
                      onTap: () => _showPlaylistTracks(playlist['id'], playlist['name']),
                      trailing: IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => _deletePlaylist(playlist['id']),
                      ),
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

  Widget _buildCategoryCard(String title, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) =>
              SongScreen(title: title, spotifyService: widget.spotifyService)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: color,
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
                title,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreatePlaylistButton() {
    return GestureDetector(
      onTap: () => _showCreatePlaylistDialog(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(
            Icons.add,
            size: 40,
            color: Colors.black54,
          ),
        ),
      ),
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