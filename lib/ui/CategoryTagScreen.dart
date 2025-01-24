//카테고리 태그 -> SongScreen

import 'package:flutter/material.dart';
import 'package:mood/views/playlist_detail_view.dart';
import '../views/playlist_view.dart';
import 'PlaylistScreen.dart';
import 'SongScreen.dart';
import 'package:mood/services/spotify_service.dart';

class CategoryTagScreen extends StatefulWidget {
  final SpotifyService spotifyService;
  const CategoryTagScreen({Key? key, required this.spotifyService}) : super(key: key);

  @override
  _CategoryTagScreenState createState() => _CategoryTagScreenState();
}

class _CategoryTagScreenState extends State<CategoryTagScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _playlistNameController = TextEditingController();
  List<dynamic> _playlists = [];
  List<dynamic> _tracks = [];
  bool _isLoading = false;

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

  Future<void> _deletePlaylist(String playlistId) async {
    try {
      await widget.spotifyService.deletePlaylist(playlistId);
      await _loadPlaylists();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('플레이리스트가 삭제되었습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('플레이리스트 삭제에 실패했습니다: $e')),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
              const SizedBox(height: 20),
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: '감정 카테고리'),
                  Tab(text: '내 플레이리스트'),
                ],
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
              ),
              const SizedBox(height: 13),
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
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.8,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildCategoryCard('분노', Colors.pink[300]!),
        _buildCategoryCard('중립', Colors.purple[300]!),
        _buildCategoryCard('감정', Colors.teal[300]!),
        _buildCategoryCard('감정', Colors.orange[300]!),
        _buildCategoryCard('슬픔', Colors.blue[300]!),
        _buildCategoryCard('감정', Colors.green[300]!),
        _buildCategoryCard('기쁨', Colors.yellow[300]!),
      ],
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
            itemCount: _playlists.length,
            itemBuilder: (context, index) {
              final playlist = _playlists[index];
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
        // Navigate to SongScreen when the card is tapped
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
                    setState(() {}); // 화면 새로고침
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