// 검색 -> 플레이리스트 탭 -> 플레이리스트 내 트랙

import 'package:flutter/material.dart';
import '../service/spotify_service.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final SpotifyService spotifyService;
  final String playlistId;
  final String playlistName;

  PlaylistDetailScreen({
    required this.spotifyService,
    required this.playlistId,
    required this.playlistName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(playlistName),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: FutureBuilder(
        future: spotifyService.getPlaylistTracks(playlistId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('플레이리스트 로드 실패: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final tracks = snapshot.data as List<dynamic>;
            return ListView.builder(
              itemCount: tracks.length,
              itemBuilder: (context, index) {
                final track = tracks[index]['track'];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
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
                        ]
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      leading: _buildAlbumCover(track),
                      title: Text(track['name']),
                      subtitle: Text(track['artists'][0]['name']),
                      onTap: () {
                        spotifyService.playTrack(track['uri']);
                      },
                    ),),);
              },
            );
          }
          return Center(child: Text('플레이리스트가 비어 있습니다.'));
        },
      ),
    );
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

}