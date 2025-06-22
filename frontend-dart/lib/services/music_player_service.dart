// lib/services/music_player_service.dart
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/models.dart';
import '../providers/dynamic_theme_provider.dart';

class MusicPlayerService with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final DynamicThemeProvider themeProvider;
  
  Track? _currentTrack;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  MusicPlayerService({required this.themeProvider}) {
    _audioPlayer.positionStream.listen((position) {
      _position = position;
      notifyListeners();
    });

    _audioPlayer.durationStream.listen((duration) {
      _duration = duration ?? Duration.zero;
      notifyListeners();
    });

    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });
  }

  Track? get currentTrack => _currentTrack;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;

  Future<void> playTrack(Track track, String url) async {
    try {
      await _audioPlayer.stop();
      _position = Duration.zero;
      _duration = Duration.zero;
      _currentTrack = track;
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
      if (track.imageUrl != null) themeProvider.extractAndApplyDominantColor(track.imageUrl);
      print('Successfully started playing: ${track.name}');
      notifyListeners();
    } catch (e) {
      print('Error playing track "${track.name}": $e');
      _currentTrack = null;
      _isPlaying = false;
      _position = Duration.zero;
      _duration = Duration.zero;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> play() async {
    try {
      await _audioPlayer.play();
    } catch (e) {
      print('Error resuming playback: $e');
      rethrow;
    }
  }

  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      print('Error pausing playback: $e');
      rethrow;
    }
  }

  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _currentTrack = null;
      _position = Duration.zero;
      _duration = Duration.zero;
      notifyListeners();
    } catch (e) {
      print('Error stopping playback: $e');
      rethrow;
    }
  }

  Future<void> togglePlay() async {
    try {
      if (_isPlaying) await pause();
      else await play();
    } catch (e) {
      print('Error toggling playback: $e');
      rethrow;
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      print('Error seeking to position: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
