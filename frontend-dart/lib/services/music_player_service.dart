import 'dart:developer' as developer;
import 'package:flutter/foundation.dart' show ChangeNotifier, kDebugMode;
import 'package:just_audio/just_audio.dart';
import '../models/models.dart';
import '../providers/dynamic_theme_provider.dart';
import 'deezer_service.dart';

class MusicPlayerService with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final DynamicThemeProvider themeProvider;
  bool _disposed = false;

  Track? _currentTrack;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  
  List<PlaylistTrack> _playlist = [];
  int _currentIndex = -1;
  String? _playlistId;
  bool _isShuffleMode = false;
  bool _isRepeatMode = false;
  bool _isUsingFullAudio = false;

  MusicPlayerService({required this.themeProvider}) {
    _audioPlayer.positionStream.listen((position) {
      if (!_disposed) {
        _position = position;
        notifyListeners();
      }
    });

    _audioPlayer.durationStream.listen((duration) {
      if (!_disposed) {
        _duration = duration ?? Duration.zero;
        notifyListeners();
      }
    });

    _audioPlayer.playerStateStream.listen((state) {
      if (!_disposed) {
        _isPlaying = state.playing;
        notifyListeners();
      }
    });

    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (!_disposed) {
            _onTrackCompleted();
          }
        });
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
  bool get isUsingFullAudio => _isUsingFullAudio;
  bool get canPlayFullAudio => DeezerService.instance.canPlayFullAudio;

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
      if (kDebugMode) {
        developer.log('Playlist set with ${_playlist.length} tracks, starting at index $_currentIndex', name: 'MusicPlayerService');
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error setting playlist: $e', name: 'MusicPlayerService');
      }
      rethrow;
    }
  }

  Future<void> playTrack(Track track, String? fallbackUrl) async {
    try {
      await _audioPlayer.stop();
      _position = Duration.zero;
      _duration = Duration.zero;
      _currentTrack = track;
      _isUsingFullAudio = false;
      
      String? audioUrl;
      
      if (track.deezerTrackId != null && DeezerService.instance.canPlayFullAudio) {
        try {
          audioUrl = await DeezerService.instance.getTrackStreamUrl(track.deezerTrackId!);
          if (audioUrl != null) {
            _isUsingFullAudio = true;
            if (kDebugMode) {
              developer.log('Using Deezer full audio for: ${track.name}', name: 'MusicPlayerService');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            developer.log('Failed to get Deezer full audio, falling back to preview: $e', name: 'MusicPlayerService');
          }
        }
      }
      
      if (audioUrl == null) {
        audioUrl = fallbackUrl ?? track.previewUrl;
        if (audioUrl == null) {
          throw Exception('No audio URL available for track: ${track.name}');
        }
        if (kDebugMode) {
          developer.log('Using preview audio for: ${track.name}', name: 'MusicPlayerService');
        }
      }
      
      await _audioPlayer.setUrl(audioUrl);
      await _audioPlayer.play();
      
      if (track.imageUrl != null) {
        themeProvider.extractAndApplyDominantColor(track.imageUrl);
      }
      
      if (kDebugMode) {
        developer.log('Successfully started playing: ${track.name} (Full audio: $_isUsingFullAudio)', name: 'MusicPlayerService');
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error playing track "${track.name}": $e', name: 'MusicPlayerService');
      }
      _currentTrack = null;
      _isPlaying = false;
      _position = Duration.zero;
      _duration = Duration.zero;
      _isUsingFullAudio = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _playCurrentTrack() async {
    if (_currentIndex < 0 || _currentIndex >= _playlist.length) return;
    
    final playlistTrack = _playlist[_currentIndex];
    final track = playlistTrack.track;
    
    if (track != null) {
      await playTrack(track, track.previewUrl);
    } else {
      throw Exception('No track available for: ${playlistTrack.name}');
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
    if (kDebugMode) {
      developer.log('Playing next track: ${_currentTrack?.name}', name: 'MusicPlayerService');
    }
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
    if (kDebugMode) {
      developer.log('Playing previous track: ${_currentTrack?.name}', name: 'MusicPlayerService');
    }
  }

  Future<void> playTrackAtIndex(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    
    _currentIndex = index;
    await _playCurrentTrack();
    if (kDebugMode) {
      developer.log('Playing track at index $index: ${_currentTrack?.name}', name: 'MusicPlayerService');
    }
  }

  void _onTrackCompleted() {
    if (kDebugMode) {
      developer.log('Track completed: ${_currentTrack?.name ?? "Unknown"}', name: 'MusicPlayerService');
    }
    
    if (_isRepeatMode && _playlist.isNotEmpty) {
      if (kDebugMode) {
        developer.log('Repeat mode enabled, playing next track', name: 'MusicPlayerService');
      }
      playNext();
    } else if (hasNextTrack) {
      if (kDebugMode) {
        developer.log('Auto-playing next track', name: 'MusicPlayerService');
      }
      playNext();
    } else {
      if (kDebugMode) {
        developer.log('No more tracks to play, stopping', name: 'MusicPlayerService');
      }
      stop();
    }
  }

  void toggleShuffle() {
    _isShuffleMode = !_isShuffleMode;
    notifyListeners();
    if (kDebugMode) {
      developer.log('Shuffle mode: $_isShuffleMode', name: 'MusicPlayerService');
    }
  }

  void toggleRepeat() {
    _isRepeatMode = !_isRepeatMode;
    notifyListeners();
    if (kDebugMode) {
      developer.log('Repeat mode: $_isRepeatMode', name: 'MusicPlayerService');
    }
  }

  Future<void> play() async {
    try {
      await _audioPlayer.play();
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error resuming playback: $e', name: 'MusicPlayerService');
      }
      rethrow;
    }
  }

  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error pausing playback: $e', name: 'MusicPlayerService');
      }
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
      if (kDebugMode) {
        developer.log('Error stopping playback: $e', name: 'MusicPlayerService');
      }
      rethrow;
    }
  }

  Future<void> togglePlay() async {
    try {
      if (_isPlaying) {
        await pause();
      } else {
        await play();
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error toggling playback: $e', name: 'MusicPlayerService');
      }
      rethrow;
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error seeking to position: $e', name: 'MusicPlayerService');
      }
      rethrow;
    }
  }

  void clearPlaylist() {
    _playlist.clear();
    _currentIndex = -1;
    _playlistId = null;
    notifyListeners();
    if (kDebugMode) {
      developer.log('Playlist cleared', name: 'MusicPlayerService');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _audioPlayer.dispose();
    super.dispose();
  }
}
