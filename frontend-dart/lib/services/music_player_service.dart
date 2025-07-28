import '../core/app_logger.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:just_audio/just_audio.dart';
import '../models/music_models.dart';
import '../providers/dynamic_theme_provider.dart';
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
  bool get canPlayFullAudio => false;

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
      AppLogger.info('Playlist set with ${_playlist.length} tracks, starting at index $_currentIndex', 'MusicPlayerService');
    } catch (e) {
      AppLogger.error('Error setting playlist: ${e.toString()}', null, null, 'MusicPlayerService');
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
      
      String? audioUrl = fallbackUrl ?? track.previewUrl;
      
      if (audioUrl == null) {
        throw Exception('No audio URL available for track: ${track.name}');
      }
      AppLogger.debug('Using preview audio for: ${track.name}', 'MusicPlayerService');
      
      await _audioPlayer.setUrl(audioUrl);
      await _audioPlayer.play();
      
      if (track.imageUrl != null) {
        themeProvider.extractAndApplyDominantColor(track.imageUrl);
      }
      
      AppLogger.info('Successfully started playing: ${track.name} (Full audio: $_isUsingFullAudio)', 'MusicPlayerService');
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error playing track "${track.name}": ${e.toString()}', null, null, 'MusicPlayerService');
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
        AppLogger.error('Failed to play track "${track.name}": ${e.toString()}', null, null, 'MusicPlayerService');
        
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
        
        AppLogger.warning('No replacement found for "${track.name}", skipping to next track', 'MusicPlayerService');
        if (hasNextTrack) {
          _currentIndex++;
          await _playCurrentTrack();
        }
      }
    } else {
      AppLogger.warning('No track available for: ${playlistTrack.name}, skipping', 'MusicPlayerService');
      if (hasNextTrack) {
        _currentIndex++;
        await _playCurrentTrack();
      }
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
    AppLogger.debug('Playing next track: ${_currentTrack?.name}', 'MusicPlayerService');
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
    AppLogger.debug('Playing previous track: ${_currentTrack?.name}', 'MusicPlayerService');
  }

  Future<void> playTrackAtIndex(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    
    _currentIndex = index;
    await _playCurrentTrack();
    AppLogger.debug('Playing track at index $index: ${_currentTrack?.name}', 'MusicPlayerService');
  }

  void _onTrackCompleted() {
    AppLogger.debug('Track completed: ${_currentTrack?.name ?? "Unknown"}', 'MusicPlayerService');
    
    if (_isRepeatMode && _playlist.isNotEmpty) {
      AppLogger.debug('Repeat mode enabled, playing next track', 'MusicPlayerService');
      playNext();
    } else if (hasNextTrack) {
      AppLogger.debug('Auto-playing next track', 'MusicPlayerService');
      playNext();
    } else {
      AppLogger.debug('No more tracks to play, stopping', 'MusicPlayerService');
      stop();
    }
  }

  void toggleShuffle() {
    _isShuffleMode = !_isShuffleMode;
    notifyListeners();
    AppLogger.debug('Shuffle mode: $_isShuffleMode', 'MusicPlayerService');
  }

  void toggleRepeat() {
    _isRepeatMode = !_isRepeatMode;
    notifyListeners();
    AppLogger.debug('Repeat mode: $_isRepeatMode', 'MusicPlayerService');
  }

  Future<void> play() async {
    try {
      await _audioPlayer.play();
    } catch (e) {
      AppLogger.error('Error resuming playback: ${e.toString()}', null, null, 'MusicPlayerService');
      rethrow;
    }
  }

  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      AppLogger.error('Error pausing playback: ${e.toString()}', null, null, 'MusicPlayerService');
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
      AppLogger.error('Error stopping playback: ${e.toString()}', null, null, 'MusicPlayerService');
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
      AppLogger.error('Error toggling playback: ${e.toString()}', null, null, 'MusicPlayerService');
      rethrow;
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      AppLogger.error('Error seeking to position: ${e.toString()}', null, null, 'MusicPlayerService');
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
    AppLogger.debug('Playlist cleared', 'MusicPlayerService');
  }

  Future<Track?> _findEquivalentTrack(Track originalTrack) async {
    if (_authToken == null) return null;
    
    try {
      AppLogger.debug('Searching for equivalent track for: ${originalTrack.name} by ${originalTrack.artist}', 'MusicPlayerService');
      
      final searchQuery = '${originalTrack.name} ${originalTrack.artist}';
      final searchResults = await _musicService.searchDeezerTracks(searchQuery);
      
      if (searchResults.isNotEmpty) {
        for (final candidate in searchResults) {
          if (candidate.id != originalTrack.id && 
              candidate.previewUrl != null && 
              candidate.previewUrl!.isNotEmpty) {
            
            final similarity = _calculateTrackSimilarity(originalTrack, candidate);
            if (similarity > 0.7) {
              AppLogger.info('Found replacement: ${candidate.name} by ${candidate.artist} (similarity: ${(similarity * 100).toStringAsFixed(1)}%)', 'MusicPlayerService');
              return candidate;
            }
          }
        }
      }
      
      AppLogger.warning('No suitable replacement found for: ${originalTrack.name}', 'MusicPlayerService');
      return null;
    } catch (e) {
      AppLogger.error('Error searching for replacement track: ${e.toString()}', null, null, 'MusicPlayerService');
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
      AppLogger.info('Replacing "${originalTrack.name}" with "${replacementTrack.name}" in playlist', 'MusicPlayerService');
      
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
      
      AppLogger.info('Successfully replaced track in playlist', 'MusicPlayerService');
    } catch (e) {
      AppLogger.error('Error replacing track in playlist: ${e.toString()}', null, null, 'MusicPlayerService');
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
