import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final SpotifyService spotifyService = SpotifyService();

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
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.8,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: List.generate(6, (index) {
        return GestureDetector(
          onTap: () {
            // Navigate to SongScreen when the card is tapped
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SongScreen(title: '플레이리스트', spotifyService: spotifyService)),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[300], // Uniform gray color for playlist boxes
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Center(
                child: Text(
                  '플레이리스트',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCategoryCard(String title, Color color) {
    return GestureDetector(
      onTap: () {
        // Navigate to SongScreen when the card is tapped
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SongScreen(title: title, spotifyService: spotifyService)),
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
}
