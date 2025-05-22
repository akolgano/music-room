// lib/services/music_player_service.dart
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/track.dart';

class MusicPlayerService with ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  Track? _currentTrack;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  Track? get currentTrack => _currentTrack;
  bool get isPlaying => _isPlaying;
  Duration get duration => _duration;
  Duration get position => _position;

  MusicPlayerService() {
    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });
    
    _player.durationStream.listen((duration) {
      _duration = duration ?? Duration.zero;
      notifyListeners();
    });
    
    _player.positionStream.listen((position) {
      _position = position;
      notifyListeners();
    });
  }

  Future<void> playTrack(Track track, String url) async {
    _currentTrack = track;
    await _player.setUrl(url);
    await _player.play();
    notifyListeners();
  }

  Future<void> togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> pause() async => await _player.pause();
  Future<void> stop() async {
    await _player.stop();
    _currentTrack = null;
    notifyListeners();
  }

  Future<void> seekTo(Duration position) async => await _player.seek(position);

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
