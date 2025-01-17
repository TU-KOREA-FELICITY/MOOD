import 'package:flutter/material.dart';
import 'spotify_service.dart';

class PlaylistDetailView extends StatelessWidget {
  final SpotifyService spotifyService;
  final String playlistId;
  final String playlistName;

  PlaylistDetailView({
    required this.spotifyService,
    required this.playlistId,
    required this.playlistName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(playlistName),
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
                return ListTile(
                  title: Text(track['name']),
                  subtitle: Text(track['artists'][0]['name']),
                  onTap: () {
                    spotifyService.playTrack(track['uri']);
                  },
                );
              },
            );
          }
          return Center(child: Text('플레이리스트가 비어 있습니다.'));
        },
      ),
    );
  }
}
