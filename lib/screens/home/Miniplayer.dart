import 'dart:async';
import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import '../../services/spotify_service.dart';

class Miniplayer extends StatefulWidget {
  final SpotifyService spotifyService;

  const Miniplayer({Key ? key, required this.spotifyService}) :
  super(key: key);

  @override
  _MiniplayerState createState() => _MiniplayerState();
}

class _MiniplayerState extends State<Miniplayer>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  String _currentTrack = 'No track playing';
  String _artistName = 'Unknown artist';
  double _sliderValue = 0.0;
  double _duration = 1.0;
  Timer? _updateTimer;
  String? _albumImageUrl;


  @override
  void initState() {
    super.initState();
    _updateCurrentTrack();
    _startPeriodicUpdate();
  }

  void _startPeriodicUpdate() {
    _updateTimer = Timer.periodic(Duration(seconds: 1), (timer) {
     if (mounted){
      _updateCurrentTrack();
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await SpotifySdk.pause();
      } else {
        await SpotifySdk.resume();
      }
      _updateCurrentTrack();
    } catch (e) {
      print('Failed to toggle play/pause: $e');
    }
  }

  Future<void> _playNextTrack() async {
    try {
      await SpotifySdk.skipNext();
      _updateCurrentTrack();
    } catch (e) {
      print('Failed to play next track: $e');
    }
  }

  Future<void> _playPreviousTrack() async {
    try {
      await SpotifySdk.skipPrevious();
      _updateCurrentTrack();
    } catch (e) {
      print('Failed to play previous track: $e');
    }
  }

  Future<void> _updateCurrentTrack() async {
    try {
      final playerState = await SpotifySdk.getPlayerState();
      if (playerState != null && playerState.track != null) {
        setState(() {
          _currentTrack = playerState.track!.name;
          _artistName = playerState.track!.artist.name ?? 'Unknown artist';
          _isPlaying = playerState.isPaused != null ? !playerState.isPaused : false;
          _duration = playerState.track!.duration.toDouble();
          _sliderValue = playerState.playbackPosition / _duration;
          _albumImageUrl = playerState.track!.imageUri.raw;
        });
      }
    } catch (e) {
      print('Failed to get player state: $e');
    }
  }


  Widget _buildAlbumCover() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: _albumImageUrl != null
          ? ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          _albumImageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(child: Icon(Icons.music_note, color: Colors.grey[600]));
          },
        ),
      )
          : Center(child: Icon(Icons.music_note, color: Colors.grey[600])),
    );
  }

  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        height: 120,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _buildAlbumCover(),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 24,
                        child: Marquee(
                          text: _currentTrack,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                          scrollAxis: Axis.horizontal,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          blankSpace: 60.0,
                          velocity: 30.0,
                          pauseAfterRound: Duration(seconds: 1),
                          startPadding: 10.0,
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        height: 16,
                        child: Marquee(
                          text: _artistName,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          scrollAxis: Axis.horizontal,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          blankSpace: 60.0,
                          velocity: 30.0,
                          pauseAfterRound: Duration(seconds: 1),
                          startPadding: 10.0,
                        ),
                      ),
                    ],
                  ),
                ),
                // 재생 컨트롤
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.skip_previous,
                          color: Colors.black, size: 24),
                      onPressed: _playPreviousTrack,
                    ),
                    IconButton(
                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.black, size: 32),
                      onPressed: _togglePlayPause,
                    ),
                    IconButton(
                      icon:
                      Icon(Icons.skip_next, color: Colors.black, size: 24),
                      onPressed: _playNextTrack,
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            // 재생 바
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: Colors.blue,
                inactiveTrackColor: Colors.grey[300],
                thumbColor: Colors.blue,
                trackHeight: 2.0,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.0),
                overlayShape: RoundSliderOverlayShape(overlayRadius: 14.0),
              ),
              child: Slider(
                value: _sliderValue,
                onChanged: (value) {
                  setState(() {
                    _sliderValue = value;
                  });
                },
                onChangeEnd: (value) async {
                  try {
                    await SpotifySdk.seekTo(
                        positionedMilliseconds: (value * _duration).toInt());
                  } catch (e) {
                    print('Failed to seek: $e');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}