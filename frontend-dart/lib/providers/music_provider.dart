import '../core/base_provider.dart';
import '../core/service_locator.dart';
import '../core/app_logger.dart';
import '../services/music_service.dart';
import '../services/track_cache_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/music_models.dart';
import '../models/result_models.dart';
import '../models/sort_models.dart';
import '../services/track_sorting_service.dart';

class MusicProvider extends BaseProvider {
  final MusicService _musicService = getIt<MusicService>();
  final TrackCacheService _trackCacheService = getIt<TrackCacheService>();
  final ApiService _apiService = getIt<ApiService>();

  List<Playlist> _playlists = [];
  List<Track> _searchResults = [];
  List<PlaylistTrack> _playlistTracks = [];
  bool _hasConnectionError = false;

  List<Playlist> get playlists => List.unmodifiable(_playlists);
  List<Track> get searchResults => List.unmodifiable(_searchResults);
  List<PlaylistTrack> get playlistTracks => _playlistTracks;
  bool get hasConnectionError => _hasConnectionError;

  TrackSortOption _currentSortOption = TrackSortOption.defaultOptions.first;
  TrackSortOption get currentSortOption => _currentSortOption;

  List<PlaylistTrack> get sortedPlaylistTracks => 
      TrackSortingService.sortTracks(_playlistTracks, _currentSortOption);

  void setSortOption(TrackSortOption sortOption) {
    _currentSortOption = sortOption;
    notifyListeners();
  }

  void resetToCustomOrder() {
    _currentSortOption = TrackSortOption.defaultOptions.first;
    notifyListeners();
  }

  Future<void> _fetchPlaylists(Future<List<Playlist>> Function() fetchMethod, String errorMessage) async {
    final result = await executeAsync(
      fetchMethod,
      errorMessage: errorMessage,
    );
    if (result != null) {
      _playlists = result;
      _hasConnectionError = false;
    } else {
      _hasConnectionError = true;
    }
  }

  Future<void> fetchUserPlaylists(String token) async {
    await _fetchPlaylists(
      () => _musicService.getUserPlaylists(token),
      'Failed to load playlists',
    );
  }

  Future<void> fetchPublicPlaylists(String token) async {
    await _fetchPlaylists(
      () => _musicService.getPublicPlaylists(token),
      'Failed to load public playlists',
    );
  }

  Future<Playlist?> getPlaylistDetails(String id, String token) async {
    if (id.isEmpty || id == 'null') {
      setError('Invalid playlist ID');
      return null;
    }
    return await executeAsync(
      () => _musicService.getPlaylistDetails(id, token),
      errorMessage: 'Failed to load playlist details',
    );
  }

  Future<String?> createPlaylist(
    String name, 
    String description, 
    bool isPublic, 
    String token, 
    [String? deviceUuid]
  ) async {
    final result = await executeAsync(
      () async {
        final id = await _musicService.createPlaylist(
          name, description, isPublic, token, deviceUuid
        );
        await fetchUserPlaylists(token);
        return id;
      },
      successMessage: 'Playlist created successfully!',
      errorMessage: 'Failed to create playlist',
    );
    return result;
  }

  Future<void> searchDeezerTracks(String query) async {
    final result = await executeAsync(
      () => _musicService.searchDeezerTracks(query),
      errorMessage: 'Search failed',
    );
    if (result != null) _searchResults = result;
  }

  void clearSearchResults() {
    _searchResults.clear();
    notifyListeners();
  }

  Future<Track?> getDeezerTrack(String trackId, String token) async {
    try {
      setLoading(true);
      final track = await _trackCacheService.getTrackDetails(trackId, token, _apiService);
      setLoading(false);
      return track;
    } catch (e) {
      setError('Failed to get track details');
      return null;
    }
  }

  Track? getTrackById(String trackId) {
    return _searchResults.where((track) => track.id == trackId).firstOrNull ??
           _playlistTracks.where((pt) => pt.track?.id == trackId || pt.trackId == trackId).firstOrNull?.track;
  }

  Future<void> fetchPlaylistTracks(String playlistId, String token) async {
    final result = await executeAsync(
      () => _musicService.getPlaylistTracksWithDetails(playlistId, token),
      errorMessage: 'Failed to load playlist tracks',
    );
    if (result != null) {
      _playlistTracks = result;
      
      final trackIdsToPreload = <String>[];
      for (final playlistTrack in _playlistTracks) {
        final track = playlistTrack.track;
        if (track?.deezerTrackId != null && 
            (track?.artist.isEmpty == true || track?.album.isEmpty == true) &&
            !_trackCacheService.isTrackCached(track!.deezerTrackId!)) {
          trackIdsToPreload.add(track.deezerTrackId!);
        }
      }
      
      if (trackIdsToPreload.isNotEmpty) {
        _trackCacheService.preloadTracks(trackIdsToPreload, token, _apiService);
      }
    }
  }

  bool isTrackInPlaylist(String trackId) {
    return _playlistTracks.any((pt) => pt.trackId == trackId || pt.track?.id == trackId);
  }

  Future<AddTrackResult> _addTrackToPlaylistInternal(String playlistId, String trackId, String token) async {
    try {
      await _musicService.addTrackToPlaylist(playlistId, trackId, token);
      await fetchPlaylistTracks(playlistId, token);
      final trackList = _playlistTracks.map((pt) => pt.track).where((t) => t != null).cast<Track>().toList();
      updatePlaylistInCache(playlistId, tracks: trackList);
      notifyListeners();
      return AddTrackResult(success: true, message: 'Track added successfully');
    } catch (e) {
      return AddTrackResult(success: false, message: e.toString());
    }
  }

  Future<AddTrackResult> addTrackToPlaylist(String playlistId, String trackId, String token) async {
    return _addTrackToPlaylistInternal(playlistId, trackId, token);
  }

  Future<AddTrackResult> addTrackObjectToPlaylist(String playlistId, Track track, String token) async {
    return _addTrackToPlaylistInternal(playlistId, track.backendId, token);
  }

  Future<AddTrackResult> addRandomTrackToPlaylist(String playlistId, String token) async {
    try {
      await _musicService.addRandomTrackToPlaylist(playlistId, token);
      await fetchPlaylistTracks(playlistId, token);
      final trackList = _playlistTracks.map((pt) => pt.track).where((t) => t != null).cast<Track>().toList();
      updatePlaylistInCache(playlistId, tracks: trackList);
      notifyListeners();
      return AddTrackResult(success: true, message: 'Random track added successfully');
    } catch (e) {
      return AddTrackResult(success: false, message: e.toString());
    }
  }

  Future<BatchAddResult> addMultipleTracksToPlaylist({
    required String playlistId,
    required List<String> trackIds,
    required String token,
    String? deviceUuid,
    Function(int current, int total)? onProgress,
  }) async {
    int successCount = 0;
    int failureCount = 0;
    int duplicateCount = 0;
    List<String> errors = [];

    for (int i = 0; i < trackIds.length; i++) {
      if (onProgress != null) onProgress(i + 1, trackIds.length);
      try {
        if (isTrackInPlaylist(trackIds[i])) {
          duplicateCount++;
          continue;
        }
        await _musicService.addTrackToPlaylist(playlistId, trackIds[i], token);
        successCount++;
      } catch (e) {
        failureCount++;
        errors.add(e.toString());
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
    await fetchPlaylistTracks(playlistId, token);
    final trackList = _playlistTracks.map((pt) => pt.track).where((t) => t != null).cast<Track>().toList();
    updatePlaylistInCache(playlistId, tracks: trackList);
    notifyListeners();
    return BatchAddResult(
      totalTracks: trackIds.length, 
      successCount: successCount, 
      duplicateCount: duplicateCount, 
      failureCount: failureCount, 
      errors: errors
    );
  }

  Future<void> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
    required String token,
  }) async {
    await executeAsync(
      () async {
        await _musicService.removeTrackFromPlaylist(playlistId, trackId, token);
        await fetchPlaylistTracks(playlistId, token);
        final trackList = _playlistTracks.map((pt) => pt.track).where((t) => t != null).cast<Track>().toList();
        updatePlaylistInCache(playlistId, tracks: trackList);
      },
      successMessage: 'Track removed from playlist',
      errorMessage: 'Failed to remove track',
    );
  }

  Future<void> moveTrackInPlaylist({
    required String playlistId,
    required int rangeStart,
    required int insertBefore,
    required String token,
    int rangeLength = 1,
  }) async {
    await executeAsync(
      () async {
        await _musicService.moveTrackInPlaylist(playlistId: playlistId, 
          rangeStart: rangeStart, 
          insertBefore: insertBefore, 
          rangeLength: rangeLength, 
          token: token
        );
        await fetchPlaylistTracks(playlistId, token);
      },
      successMessage: 'Track order updated',
      errorMessage: 'Failed to update track order',
    );
  }

  void updateTrackInPlaylist(String trackId, Track trackDetails) {
    for (int i = 0; i < _playlistTracks.length; i++) {
      if (_playlistTracks[i].trackId == trackId) {
        _playlistTracks[i] = PlaylistTrack(
          trackId: _playlistTracks[i].trackId,
          name: _playlistTracks[i].name,
          position: _playlistTracks[i].position,
          points: _playlistTracks[i].points,
          track: trackDetails,
        );
        notifyListeners();
        break;
      }
    }
  }

  void updatePlaylistTracks(List<PlaylistTrack> updatedTracks) {
    _log('Updating playlist tracks: ${updatedTracks.length} tracks (WebSocket update)');
    _playlistTracks = updatedTracks;
    
    notifyListeners();
    
    _loadMissingTrackDetailsInBackground();
    
    _log('Completed playlist tracks update and triggered UI refresh');
  }

  void updatePlaylistTracksWithPreload(List<PlaylistTrack> updatedTracks) {
    _log('Updating playlist tracks with comprehensive preload: ${updatedTracks.length} tracks (WebSocket comprehensive update)');
    _playlistTracks = updatedTracks;
    
    notifyListeners();
    
    _preloadTrackDetails(updatedTracks);
    
    Future.microtask(() => notifyListeners());
    
    _log('Completed comprehensive playlist tracks update with preload and multiple notifications');
  }

  void _preloadTrackDetails(List<PlaylistTrack> tracks) {
    try {
      final trackIdsToPreload = <String>[];
      for (final playlistTrack in tracks) {
        final track = playlistTrack.track;
        if (track?.deezerTrackId != null && 
            (track?.artist.isEmpty == true || track?.album.isEmpty == true || track?.imageUrl?.isEmpty == true) &&
            !_trackCacheService.isTrackCached(track!.deezerTrackId!)) {
          trackIdsToPreload.add(track.deezerTrackId!);
        }
      }
      
      if (trackIdsToPreload.isNotEmpty) {
        _log('Preloading ${trackIdsToPreload.length} tracks with missing details');
        if (getIt.isRegistered<AuthService>()) {
          final authService = getIt<AuthService>();
          final token = authService.currentToken;
          if (token != null) {
            _trackCacheService.preloadTracks(trackIdsToPreload, token, _apiService).then((_) {
              _log('Completed preloading tracks, updating tracks with complete details');
              _updateTracksWithCachedDetails();
            }).catchError((e) {
              _log('Error preloading tracks: $e');
            });
          }
        }
      }
    } catch (e) {
      _log('Error in preload track details: $e');
    }
  }

  void _updateTracksWithCachedDetails() {
    bool updated = false;
    for (int i = 0; i < _playlistTracks.length; i++) {
      final playlistTrack = _playlistTracks[i];
      final track = playlistTrack.track;
      
      if (track?.deezerTrackId != null && _trackCacheService.isTrackCached(track!.deezerTrackId!)) {
        final cachedTrack = _trackCacheService.getCachedTrack(track.deezerTrackId!);
        if (cachedTrack != null && 
            (cachedTrack.artist != track.artist || 
             cachedTrack.album != track.album || 
             cachedTrack.imageUrl != track.imageUrl)) {
          
          _playlistTracks[i] = playlistTrack.copyWithTrack(cachedTrack);
          updated = true;
          _log('Updated track ${track.name} with cached details');
        }
      }
    }
    
    if (updated) {
      _log('Refreshing UI with updated track details');
      notifyListeners();
    }
  }

  void _loadMissingTrackDetailsInBackground() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _preloadTrackDetails(_playlistTracks);
    });
  }

  void _log(String message) {
    AppLogger.debug(message, 'MusicProvider');
  }

  void updatePlaylistInCache(String playlistId, {
    String? name,
    String? description,
    bool? isPublic,
    List<Track>? tracks,
  }) {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      final currentPlaylist = _playlists[index];
      _playlists[index] = Playlist(
        id: currentPlaylist.id,
        name: name ?? currentPlaylist.name,
        description: description ?? currentPlaylist.description,
        creator: currentPlaylist.creator,
        isPublic: isPublic ?? currentPlaylist.isPublic,
        tracks: tracks ?? currentPlaylist.tracks,
        imageUrl: currentPlaylist.imageUrl,
      );
      notifyListeners();
    }
  }

  Future<void> shufflePlaylistTracks(String playlistId, String token) async {
    if (_playlistTracks.isEmpty) return;
    
    final shuffledIndices = List.generate(_playlistTracks.length, (index) => index);
    shuffledIndices.shuffle();
    
    try {
      setLoading(true);
      
      for (int targetPos = 0; targetPos < shuffledIndices.length; targetPos++) {
        final sourcePos = shuffledIndices[targetPos];
        
        if (sourcePos != targetPos) {
          await _musicService.moveTrackInPlaylist(
            playlistId: playlistId,
            rangeStart: sourcePos,
            insertBefore: targetPos,
            token: token,
          );
          
          for (int i = targetPos + 1; i < shuffledIndices.length; i++) {
            if (shuffledIndices[i] <= sourcePos) {
              shuffledIndices[i]++;
            }
          }
        }
      }
      
      await fetchPlaylistTracks(playlistId, token);
      resetToCustomOrder();
      setLoading(false);
      
    } catch (e) {
      setLoading(false);
      setError('Failed to shuffle playlist: $e');
      rethrow;
    }
  }
}
