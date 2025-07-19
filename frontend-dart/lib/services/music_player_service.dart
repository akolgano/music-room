import 'dart:developer' as developer;
import 'package:flutter/foundation.dart' show ChangeNotifier, kDebugMode;
import 'package:just_audio/just_audio.dart';
import '../models/models.dart';
import '../providers/dynamic_theme_provider.dart';
import 'deezer_service.dart';
import 'music_service.dart';
import '../core/service_locator.dart';

class MusicPlayerService with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final DynamicThemeProvider themeProvider;
  final MusicService _musicService = getIt<MusicService>();
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
  String? _authToken;
  final Set<String> _failedTracks = {};
  Function(String originalTrack, String replacementTrack)? _onTrackReplaced;

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

  void setTrackReplacedCallback(Function(String originalTrack, String replacementTrack)? callback) {
    _onTrackReplaced = callback;
  }

  Future<void> setPlaylistAndPlay({
    required List<PlaylistTrack> playlist,
    required int startIndex,
    String? playlistId,
    String? authToken,
  }) async {
    try {
      _playlist = List.from(playlist);
      _playlistId = playlistId;
      _authToken = authToken;
      _currentIndex = startIndex.clamp(0, _playlist.length - 1);
      _failedTracks.clear();
      
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
      try {
        await playTrack(track, track.previewUrl);
      } catch (e) {
        if (kDebugMode) {
          developer.log('Failed to play track "${track.name}": $e', name: 'MusicPlayerService');
        }
        
        final trackKey = '${track.name}_${track.artist}';
        if (!_failedTracks.contains(trackKey)) {
          _failedTracks.add(trackKey);
          
          final replacement = await _findEquivalentTrack(track);
          if (replacement != null && _playlistId != null && _authToken != null) {
            await _replaceTrackInPlaylist(playlistTrack, replacement);
            
            _onTrackReplaced?.call('${track.name} by ${track.artist}', '${replacement.name} by ${replacement.artist}');
            
            await _playCurrentTrack(); 
            return;
          }
        }
        
        if (kDebugMode) {
          developer.log('No replacement found for "${track.name}", skipping to next track', name: 'MusicPlayerService');
        }
        await playNext();
      }
    } else {
      if (kDebugMode) {
        developer.log('No track available for: ${playlistTrack.name}, skipping', name: 'MusicPlayerService');
      }
      await playNext();
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
    _authToken = null;
    _failedTracks.clear();
    notifyListeners();
    if (kDebugMode) {
      developer.log('Playlist cleared', name: 'MusicPlayerService');
    }
  }

  Future<Track?> _findEquivalentTrack(Track originalTrack) async {
    if (_authToken == null) return null;
    
    try {
      if (kDebugMode) {
        developer.log('Searching for equivalent track for: ${originalTrack.name} by ${originalTrack.artist}', name: 'MusicPlayerService');
      }
      
      final searchQuery = '${originalTrack.name} ${originalTrack.artist}';
      final searchResults = await _musicService.searchDeezerTracks(searchQuery);
      
      if (searchResults.isNotEmpty) {
        for (final candidate in searchResults) {
          if (candidate.id != originalTrack.id && 
              candidate.previewUrl != null && 
              candidate.previewUrl!.isNotEmpty) {
            
            final similarity = _calculateTrackSimilarity(originalTrack, candidate);
            if (similarity > 0.7) {
              if (kDebugMode) {
                developer.log('Found replacement: ${candidate.name} by ${candidate.artist} (similarity: ${(similarity * 100).toStringAsFixed(1)}%)', name: 'MusicPlayerService');
              }
              return candidate;
            }
          }
        }
      }
      
      if (kDebugMode) {
        developer.log('No suitable replacement found for: ${originalTrack.name}', name: 'MusicPlayerService');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error searching for replacement track: $e', name: 'MusicPlayerService');
      }
      return null;
    }
  }

  double _calculateTrackSimilarity(Track original, Track candidate) {
    final originalName = original.name.toLowerCase().trim();
    final candidateName = candidate.name.toLowerCase().trim();
    final originalArtist = original.artist.toLowerCase().trim();
    final candidateArtist = candidate.artist.toLowerCase().trim();
    
    final nameSimilarity = _stringSimilarity(originalName, candidateName);
    final artistSimilarity = _stringSimilarity(originalArtist, candidateArtist);
    
    return (nameSimilarity * 0.7) + (artistSimilarity * 0.3);
  }

  double _stringSimilarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    
    if (a.contains(b) || b.contains(a)) return 0.8;
    
    final longer = a.length > b.length ? a : b;
    final shorter = a.length > b.length ? b : a;
    
    if (longer.isEmpty) return 1.0;
    
    final editDistance = _levenshteinDistance(longer, shorter);
    return (longer.length - editDistance) / longer.length;
  }

  int _levenshteinDistance(String s1, String s2) {
    final matrix = List.generate(s1.length + 1, (_) => List.filled(s2.length + 1, 0));
    
    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }
    
    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    
    return matrix[s1.length][s2.length];
  }

  Future<void> _replaceTrackInPlaylist(PlaylistTrack originalTrack, Track replacementTrack) async {
    if (_playlistId == null || _authToken == null) return;
    
    try {
      if (kDebugMode) {
        developer.log('Replacing "${originalTrack.name}" with "${replacementTrack.name}" in playlist', name: 'MusicPlayerService');
      }
      
      await _musicService.removeTrackFromPlaylist(_playlistId!, originalTrack.trackId, _authToken!);
      
      await _musicService.addTrackToPlaylist(_playlistId!, replacementTrack.backendId, _authToken!);
      
      final newPlaylistTrack = PlaylistTrack(
        trackId: replacementTrack.id,
        name: replacementTrack.name,
        position: originalTrack.position,
        points: originalTrack.points,
        track: replacementTrack,
      );
      
      _playlist[_currentIndex] = newPlaylistTrack;
      notifyListeners();
      
      if (kDebugMode) {
        developer.log('Successfully replaced track in playlist', name: 'MusicPlayerService');
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error replacing track in playlist: $e', name: 'MusicPlayerService');
      }
      rethrow;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _audioPlayer.dispose();
    super.dispose();
  }
}
