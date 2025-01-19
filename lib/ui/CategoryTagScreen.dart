//카테고리 태그 -> SongScreen

import 'package:flutter/material.dart';
import 'package:mood/views/playlist_detail_view.dart';
import '../views/playlist_view.dart';
import 'PlaylistScreen.dart';
import 'SongScreen.dart';
import 'package:mood/services/spotify_service.dart';

class CategoryTagScreen extends StatefulWidget {
  const CategoryTagScreen({Key? key}) : super(key: key);

  @override
  _CategoryTagScreenState createState() => _CategoryTagScreenState();
}

class _CategoryTagScreenState extends State<CategoryTagScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _playlistNameController = TextEditingController();
  final SpotifyService spotifyService = SpotifyService();
  List<dynamic> _tracks = [];
  bool _isLoading = false;


  void _createPlaylist() async {
    if (_playlistNameController.text.isNotEmpty) {
      try {
        await spotifyService.createPlaylist(_playlistNameController.text);
        _playlistNameController.clear();
        setState(() {});
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('플레이리스트 생성 실패: $e')),
        );
      }
    }
  }

  void _showPlaylistTracks(String playlistId, String playlistName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistTracksView(
          spotifyService: spotifyService,
          playlistId: playlistId,
          playlistName: playlistName,
        ),
      ),
    );
  }


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    setState(() => _isLoading = true);
    try {
      final userId = await spotifyService.getCurrentUserId();
      final tracks = await spotifyService.getPlaylists();
      setState(() {
        _tracks = tracks;
        _isLoading = false;
      });
    } catch (e) {
      print('플레이리스트 로딩 중 오류 발생: $e');
      setState(() => _isLoading = false);
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
                    // Emotion Categories Tab
                    _buildEmotionCategories(),
                    // My Playlist Tab
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
    return FutureBuilder<List<dynamic>>(
      future: spotifyService.getPlaylists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('플레이리스트를 불러오는 데 실패했습니다.'));
        }

        List<dynamic> playlists = snapshot.data ?? [];
        return Column(
          children: [
            ElevatedButton(
              onPressed: () => _showCreatePlaylistDialog(),
              child: Text('새 플레이리스트 생성',
              style: TextStyle(color: Colors.blueAccent),),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                minimumSize: Size(200, 50),
                side: BorderSide(color: Colors.blueAccent)
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.8,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: playlists.length,
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Center(
                        child: Text(
                          playlists[index]['name'],
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }



  Widget _buildCategoryCard(String title, Color color) {
    return GestureDetector(
      onTap: () {
        // Navigate to SongScreen when the card is tapped
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) =>
              SongScreen(title: title, spotifyService: spotifyService)),
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
                    await spotifyService.createPlaylist(
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