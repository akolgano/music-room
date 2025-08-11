import '../core/navigation_core.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:just_audio/just_audio.dart';
import '../models/music_models.dart';
import '../providers/theme_providers.dart';
import 'music_services.dart';
import '../core/locator_core.dart';

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
  int _lastPlayedIndex = -1;
  String? _playlistId;
  bool _isShuffleMode = false;
  bool _isRepeatMode = false;
  bool _isUsingFullAudio = false;
  String? _authToken;
  final Set<String> _failedTracks = {};
  double _playbackSpeed = 1.0;

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
  double get playbackSpeed => _playbackSpeed;

  String get currentTrackInfo {
    if (_currentTrack == null) return '';
    return '${_currentIndex + 1} of ${_playlist.length}';
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
      _lastPlayedIndex = -1;
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
      await _audioPlayer.setSpeed(_playbackSpeed);
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
        _lastPlayedIndex = _currentIndex;
        AppLogger.debug('Successfully played track at index $_currentIndex, updated lastPlayedIndex to $_lastPlayedIndex', 'MusicPlayerService');
      } catch (e) {
        AppLogger.error('Failed to play track "${track.name}": ${e.toString()}', null, null, 'MusicPlayerService');
        await _handleTrackFailure(playlistTrack, track);
      }
    } else {
      AppLogger.warning('No track available for: ${playlistTrack.name}, skipping', 'MusicPlayerService');
      await _skipCurrentTrack();
    }
  }

  Future<void> _handleTrackFailure(PlaylistTrack playlistTrack, Track track) async {
    final trackKey = '${track.name}_${track.artist}';
    if (!_failedTracks.contains(trackKey)) {
      _failedTracks.add(trackKey);
      
      final replacement = await _findEquivalentTrack(track);
      if (replacement != null && _playlistId != null && _authToken != null) {
        try {
          await _replaceTrackInPlaylist(playlistTrack, replacement);
          
          await _playCurrentTrack(); 
          return;
        } catch (e) {
          AppLogger.error('Failed to replace track: ${e.toString()}', null, null, 'MusicPlayerService');
        }
      }
    }
    
    AppLogger.warning('No replacement found for "${track.name}", skipping current track', 'MusicPlayerService');
    await _skipCurrentTrack();
  }

  Future<void> _skipCurrentTrack() async {
    int nextIndex = _calculateNextSequentialIndex();
    
    if (nextIndex == -1) {
      if (_isRepeatMode && _playlist.isNotEmpty) {
        _currentIndex = 0;
        _lastPlayedIndex = -1;
        int playableIndex = _findNextPlayableTrack(0);
        if (playableIndex != -1) {
          _currentIndex = playableIndex;
          await _playCurrentTrack();
        } else {
          AppLogger.warning('All tracks failed, stopping playback', 'MusicPlayerService');
          await stop();
        }
      } else {
        AppLogger.debug('No more tracks available, stopping playback', 'MusicPlayerService');
        await stop();
      }
      return;
    }
    
    int playableIndex = _findNextPlayableTrack(nextIndex);
    if (playableIndex != -1) {
      _currentIndex = playableIndex;
      await _playCurrentTrack();
      AppLogger.debug('Skipped to track index $_currentIndex: ${_playlist[_currentIndex].name}', 'MusicPlayerService');
    } else {
      AppLogger.warning('No playable tracks remaining, stopping playback', 'MusicPlayerService');
      await stop();
    }
  }

  int _findNextPlayableTrack(int startIndex) {
    for (int i = startIndex; i < _playlist.length; i++) {
      final playlistTrack = _playlist[i];
      final track = playlistTrack.track;
      
      if (track != null) {
        final trackKey = '${track.name}_${track.artist}';
        if (!_failedTracks.contains(trackKey) && track.previewUrl != null) {
          return i;
        }
      }
    }
    return -1; 
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
      AppLogger.debug('Repeat mode enabled, auto-progressing to next track', 'MusicPlayerService');
      _autoProgressToNext();
    } else if (hasNextTrack) {
      AppLogger.debug('Auto-progressing to next track', 'MusicPlayerService');
      _autoProgressToNext();
    } else {
      AppLogger.debug('No more tracks to play, stopping', 'MusicPlayerService');
      stop();
    }
  }

  Future<void> _autoProgressToNext() async {
    int nextIndex = _calculateNextSequentialIndex();
    
    if (nextIndex == -1) {
      if (_isRepeatMode && _playlist.isNotEmpty) {
        _currentIndex = 0;
        _lastPlayedIndex = -1;
      } else {
        return;
      }
    } else {
      _currentIndex = nextIndex;
    }
    
    AppLogger.debug('Auto-progressed from $_lastPlayedIndex to $_currentIndex: ${_playlist[_currentIndex].name}', 'MusicPlayerService');
    await _playCurrentTrack();
  }

  int _calculateNextSequentialIndex() {
    if (_lastPlayedIndex == -1) {
      return _currentIndex < _playlist.length - 1 ? _currentIndex + 1 : -1;
    }
    
    int expectedNext = _lastPlayedIndex + 1;
    
    if (expectedNext >= _playlist.length) {
      return -1;
    }
    
    AppLogger.debug('Last played: $_lastPlayedIndex, Expected next: $expectedNext', 'MusicPlayerService');
    return expectedNext;
  }

  void toggleShuffle() {
    _isShuffleMode = !_isShuffleMode;
    
    if (_isShuffleMode && _playlist.isNotEmpty) {
      PlaylistTrack? currentTrack = _currentIndex >= 0 && _currentIndex < _playlist.length 
          ? _playlist[_currentIndex] 
          : null;
      
      final shuffledPlaylist = List<PlaylistTrack>.from(_playlist);
      shuffledPlaylist.shuffle();
      
      if (currentTrack != null) {
        shuffledPlaylist.remove(currentTrack);
        shuffledPlaylist.insert(0, currentTrack);
      }
      
      _playlist = shuffledPlaylist;
      _currentIndex = 0;
      _lastPlayedIndex = -1;
      
      _playCurrentTrack();
      
      AppLogger.debug('Playlist shuffled and playing first track', 'MusicPlayerService');
    } else {
      AppLogger.debug('Shuffle mode disabled', 'MusicPlayerService');
    }
    
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

  Future<void> setPlaybackSpeed(double speed) async {
    try {
      _playbackSpeed = speed.clamp(0.25, 3.0); 
      await _audioPlayer.setSpeed(_playbackSpeed);
      notifyListeners();
      AppLogger.debug('Playback speed set to ${_playbackSpeed}x', 'MusicPlayerService');
    } catch (e) {
      AppLogger.error('Error setting playback speed: ${e.toString()}', null, null, 'MusicPlayerService');
      rethrow;
    }
  }

  void clearPlaylist() {
    _playlist.clear();
    _currentIndex = -1;
    _lastPlayedIndex = -1;
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
            
            AppLogger.info('Found replacement: ${candidate.name} by ${candidate.artist}', 'MusicPlayerService');
            return candidate;
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

  void updatePlaylist(List<PlaylistTrack> updatedPlaylist) {
    if (_playlistId == null) return;
    
    final oldLength = _playlist.length;
    _playlist = List.from(updatedPlaylist);
    
    if (_playlist.length > oldLength) {
      _failedTracks.clear();
      AppLogger.debug('Cleared failed tracks cache due to playlist update', 'MusicPlayerService');
    }
    
    if (_currentIndex >= _playlist.length) {
      _currentIndex = _playlist.isEmpty ? -1 : _playlist.length - 1;
    }
    
    notifyListeners();
    AppLogger.debug('Playlist updated: $oldLength -> ${_playlist.length} tracks', 'MusicPlayerService');
  }

  @override
  void dispose() {
    _disposed = true;
    _audioPlayer.dispose();
    super.dispose();
  }
}
