import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:spotify_sdk/models/image_uri.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:marquee/marquee.dart';
import '../service/spotify_service.dart';

class Miniplayer extends StatefulWidget {
  final SpotifyService spotifyService;
  final Function onTrackFinished;

  const Miniplayer({super.key, required this.spotifyService, required this.onTrackFinished});

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
  Timer? _trackEndTimer;
  Uint8List? _albumArtwork;

  @override
  void initState() {
    super.initState();
    _updateCurrentTrack();
    _startPeriodicUpdate();
  }

  void _startPeriodicUpdate() {
    _updateTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      _updateCurrentTrack();
      _checkTrackEnd();
    });
  }

  void _checkTrackEnd() {
    if (_sliderValue >= 0.99) {
      // 트랙의 99%가 재생되었을 때
      _trackEndTimer?.cancel(); // 기존 타이머 취소
      _trackEndTimer = Timer(Duration(seconds: 1), () {
        // 1초 후 콜백 호출
        widget.onTrackFinished(); // 트랙 종료 시 콜백 호출
      });
    }
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
      if (e.toString().contains('SpotifyDisconnectedException')) {
        await _reconnectToSpotify();
      }
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
          _artistName = playerState.track!.artist.name!;
          _isPlaying = playerState.isPaused != null ? !playerState.isPaused : false;
          _duration = playerState.track!.duration.toDouble();
          _sliderValue = (playerState.playbackPosition / _duration).clamp(0.0, 1.0);
        });
        _albumArtwork = await _loadAlbumArtwork(playerState.track!.imageUri);
        setState(() {});
      }
    } catch (e) {
      print('Failed to get player state: $e');
      if (e.toString().contains('SpotifyDisconnectedException')) {
        await _reconnectToSpotify();
      }
    }
  }

  Future<void> _reconnectToSpotify() async {
    try {
      await widget.spotifyService.connect();
      print('Spotify 재연결 성공');
    } catch (e) {
      print('Spotify 재연결 실패: $e');
    }
  }

  Future<Uint8List?> _loadAlbumArtwork(ImageUri imageUri) async {
    try {
      return await SpotifySdk.getImage(
        imageUri: imageUri,
        dimension: ImageDimension.medium,
      );
    } catch (e) {
      print('Failed to load album artwork: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Container(
          height: 110,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _albumArtwork != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            _albumArtwork!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey[300],
                          child:
                              Icon(Icons.music_note, color: Colors.grey[600]),
                        ),
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
                        icon: Icon(Icons.skip_next,
                            color: Colors.black, size: 24),
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
                  activeTrackColor: Color(0xFF0126FA),
                  inactiveTrackColor: Colors.grey[300],
                  thumbColor: Color(0xFF0126FA),
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
      ),
    );
  }
}
