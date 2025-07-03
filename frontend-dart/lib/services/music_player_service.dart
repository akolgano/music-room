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
  
  List<PlaylistTrack> _playlist = [];
  int _currentIndex = -1;
  String? _playlistId;
  bool _isShuffleMode = false;
  bool _isRepeatMode = false;

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

    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _onTrackCompleted();
      }
    });
  }

  Track? get currentTrack => _currentTrack;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  List<PlaylistTrack> get playlist => List.unmodifiable(_playlist);
  int get currentIndex => _currentIndex;
  String? get playlistId => _playlistId;
  bool get isShuffleMode => _isShuffleMode;
  bool get isRepeatMode => _isRepeatMode;
  bool get hasPlaylist => _playlist.isNotEmpty;
  bool get hasPreviousTrack => _currentIndex > 0;
  bool get hasNextTrack => _currentIndex >= 0 && _currentIndex < _playlist.length - 1;

  String get currentTrackInfo {
    if (_currentTrack == null) return '';
    return '${_currentIndex + 1} of ${_playlist.length}';
  }

  Future<void> setPlaylistAndPlay({
    required List<PlaylistTrack> playlist,
    required int startIndex,
    String? playlistId,
  }) async {
    try {
      _playlist = List.from(playlist);
      _playlistId = playlistId;
      _currentIndex = startIndex.clamp(0, _playlist.length - 1);
      
      await _playCurrentTrack();
      print('Playlist set with ${_playlist.length} tracks, starting at index $_currentIndex');
    } catch (e) {
      print('Error setting playlist: $e');
      rethrow;
    }
  }

  Future<void> playTrack(Track track, String url) async {
    try {
      await _audioPlayer.stop();
      _position = Duration.zero;
      _duration = Duration.zero;
      _currentTrack = track;
      
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
      
      if (track.imageUrl != null) {
        themeProvider.extractAndApplyDominantColor(track.imageUrl);
      }
      
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

  Future<void> _playCurrentTrack() async {
    if (_currentIndex < 0 || _currentIndex >= _playlist.length) return;
    
    final playlistTrack = _playlist[_currentIndex];
    final track = playlistTrack.track;
    
    if (track?.previewUrl != null) {
      await playTrack(track!, track.previewUrl!);
    } else {
      throw Exception('No preview available for track: ${track?.name ?? playlistTrack.name}');
    }
  }

  Future<void> playNext() async {
    if (!hasNextTrack) {
      if (_isRepeatMode && _playlist.isNotEmpty) {
        _currentIndex = 0;
        await _playCurrentTrack();
      }
      return;
    }
    
    _currentIndex++;
    await _playCurrentTrack();
    print('Playing next track: ${_currentTrack?.name}');
  }

  Future<void> playPrevious() async {
    if (!hasPreviousTrack) {
      if (_isRepeatMode && _playlist.isNotEmpty) {
        _currentIndex = _playlist.length - 1;
        await _playCurrentTrack();
      }
      return;
    }
    
    _currentIndex--;
    await _playCurrentTrack();
    print('Playing previous track: ${_currentTrack?.name}');
  }

  Future<void> playTrackAtIndex(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    
    _currentIndex = index;
    await _playCurrentTrack();
    print('Playing track at index $index: ${_currentTrack?.name}');
  }

  void _onTrackCompleted() {
    if (hasNextTrack || _isRepeatMode) {
      playNext();
    } else {
      stop();
    }
  }

  void toggleShuffle() {
    _isShuffleMode = !_isShuffleMode;
    notifyListeners();
    print('Shuffle mode: $_isShuffleMode');
  }

  void toggleRepeat() {
    _isRepeatMode = !_isRepeatMode;
    notifyListeners();
    print('Repeat mode: $_isRepeatMode');
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

  void clearPlaylist() {
    _playlist.clear();
    _currentIndex = -1;
    _playlistId = null;
    notifyListeners();
    print('Playlist cleared');
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
