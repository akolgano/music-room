// services/music_player_service.dart
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../models/track.dart';

class MusicPlayerService with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  Track? _currentTrack;
  
  bool _isPlaying = false;
  bool _isBuffering = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  
  AudioPlayer get audioPlayer => _audioPlayer;
  Track? get currentTrack => _currentTrack;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  Duration get duration => _duration;
  Duration get position => _position;
  
  MusicPlayerService() {
    _init();
  }
  
  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    
    _audioPlayer.playerStateStream.listen((playerState) {
      _isPlaying = playerState.playing;
      _isBuffering = playerState.processingState == ProcessingState.buffering;
      notifyListeners();
    });
    
    _audioPlayer.durationStream.listen((newDuration) {
      if (newDuration != null) {
        _duration = newDuration;
        notifyListeners();
      }
    });
    
    _audioPlayer.positionStream.listen((newPosition) {
      _position = newPosition;
      notifyListeners();
    });
  }
  
  Future<void> playTrack(Track track, String previewUrl) async {
    if (_currentTrack?.id == track.id && _isPlaying) {
      await pause();
      return;
    }
    
    try {
      _currentTrack = track;
      await _audioPlayer.stop();
      await _audioPlayer.setUrl(previewUrl);
      await _audioPlayer.play();
      notifyListeners();
    } catch (e) {
      print('Error playing track: $e');
      rethrow;
    }
  }
  
  Future<void> togglePlay() async {
    if (_isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }
  
  Future<void> pause() async {
    await _audioPlayer.pause();
    notifyListeners();
  }
  
  Future<void> resume() async {
    await _audioPlayer.play();
    notifyListeners();
  }
  
  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentTrack = null;
    notifyListeners();
  }
  
  Future<void> seekTo(Duration position) async {
    await _audioPlayer.seek(position);
    notifyListeners();
  }
  
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
