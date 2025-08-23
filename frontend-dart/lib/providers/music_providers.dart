import '../core/provider_core.dart';
import '../core/locator_core.dart';
import '../core/navigation_core.dart';
import '../core/logging_core.dart';
import '../services/music_services.dart';
import '../services/cache_services.dart';
import '../services/api_services.dart';
import '../services/auth_services.dart';
import '../models/music_models.dart';
import '../models/api_models.dart';
import '../models/sort_models.dart';
import 'friend_providers.dart';
import 'auth_providers.dart';

class MusicProvider extends BaseProvider {
  final MusicService _musicService = getIt<MusicService>();
  final TrackCacheService _trackCacheService = getIt<TrackCacheService>();
  final ApiService _apiService = getIt<ApiService>();

  List<Playlist> _playlists = [];
  List<Playlist> _userPlaylists = [];
  List<Playlist> _publicPlaylists = [];
  List<Track> _searchResults = [];
  List<PlaylistTrack> _playlistTracks = [];
  bool _hasConnectionError = false;
  List<Playlist> get playlists => List.unmodifiable(_playlists);
  List<Playlist> get userPlaylists => List.unmodifiable(_userPlaylists);
  List<Playlist> get publicPlaylists => List.unmodifiable(_publicPlaylists);
  List<Track> get searchResults => List.unmodifiable(_searchResults);
  
  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }
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

  Future<void> fetchUserPlaylists(String token) async {
    final result = await executeAsync(
      () => _musicService.getUserPlaylists(token),
      errorMessage: 'Failed to load user playlists',
    );
    if (result != null) {
      _userPlaylists = result;
      notifyListeners();
    }
  }

  Future<void> fetchPublicPlaylists(String token) async {
    final result = await executeAsync(
      () => _musicService.getPublicPlaylists(token),
      errorMessage: 'Failed to load public playlists',
    );
    if (result != null) {
      _publicPlaylists = result;
      notifyListeners();
    }
  }

  Future<void> fetchAllPlaylists(String token) async {
    String? currentUsername;
    try {
      if (getIt.isRegistered<AuthProvider>()) {
        final authProvider = getIt<AuthProvider>();
        currentUsername = authProvider.currentUser?.username ?? authProvider.username;
        AppLogger.debug('Current username for filtering: $currentUsername (from currentUser: ${authProvider.currentUser?.username}, from username: ${authProvider.username})', 'MusicProvider');
      }
    } catch (e) {
      AppLogger.debug('Could not get current username: $e', 'MusicProvider');
    }
    
    final result = await executeAsync(
      () async {
        
        final allPlaylists = <String, Playlist>{};
        
        Set<String> friendIds = {};
        try {
          if (getIt.isRegistered<FriendProvider>()) {
            final friendProvider = getIt<FriendProvider>();
            await friendProvider.fetchFriends(token);
            friendIds = friendProvider.friends.map((f) => f.id).toSet();
          }
        } catch (e) {
          AppLogger.debug('Could not fetch friends for filtering: $e', 'MusicProvider');
        }
        
        try {
          final userPlaylists = await _musicService.getUserPlaylists(token);
          for (final playlist in userPlaylists) {
            
            
            
            allPlaylists[playlist.id] = playlist;
            AppLogger.debug('Including user playlist "${playlist.name}" (public: ${playlist.isPublic}, creator: ${playlist.creator})', 'MusicProvider');
          }
        } catch (e) {
          AppLogger.error('Failed to fetch user playlists', e, null, 'MusicProvider');
        }
        
        try {
          final publicPlaylists = await _musicService.getPublicPlaylists(token);
          for (final playlist in publicPlaylists) {
            if (!allPlaylists.containsKey(playlist.id)) {
              final isOwnPlaylist = playlist.creator == currentUsername;
              final isFromFriend = friendIds.contains(playlist.creator);
              
              final shouldKeep = isOwnPlaylist || playlist.isPublic || isFromFriend;
              
              if (shouldKeep) {
                allPlaylists[playlist.id] = playlist;
              } else {
                AppLogger.debug('Filtering out private playlist "${playlist.name}" from ex-friend/non-friend ${playlist.creator}', 'MusicProvider');
              }
            }
          }
        } catch (e) {
          AppLogger.error('Failed to fetch public playlists', e, null, 'MusicProvider');
        }
        
        try {
          final userEvents = await _musicService.getSavedEvents(token);
          for (final event in userEvents) {
            
            
            allPlaylists[event.id] = event;
            AppLogger.debug('Including user event "${event.name}" (public: ${event.isPublic}, creator: ${event.creator})', 'MusicProvider');
          }
        } catch (e) {
          AppLogger.error('Failed to fetch user events', e, null, 'MusicProvider');
        }
        
        try {
          final publicEvents = await _musicService.getPublicEvents(token);
          for (final event in publicEvents) {
            if (!allPlaylists.containsKey(event.id)) {
              final isOwnEvent = event.creator == currentUsername;
              final isFromFriend = friendIds.contains(event.creator);
              
              final shouldKeep = isOwnEvent || event.isPublic || isFromFriend;
              
              if (shouldKeep) {
                allPlaylists[event.id] = event;
              } else {
                AppLogger.debug('Filtering out private event "${event.name}" from ex-friend/non-friend ${event.creator}', 'MusicProvider');
              }
            }
          }
        } catch (e) {
          AppLogger.error('Failed to fetch public events', e, null, 'MusicProvider');
        }
        
        final resultList = allPlaylists.values.toList();
        return resultList;
      },
      errorMessage: 'Failed to load playlists and events',
    );
    
    if (result != null) {
      _playlists = result;
      _hasConnectionError = false;
      AppLogger.debug('Final playlists set: ${_playlists.length} total playlists', 'MusicProvider');
    } else {
      _hasConnectionError = true;
    }
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
    String licenseType, 
    bool isEvent,
    [String? deviceUuid]
  ) async {
    final result = await executeAsync(
      () async {
        final id = await _musicService.createPlaylist(
          name, description, isPublic, token, licenseType, isEvent, deviceUuid
        );
        await fetchAllPlaylists(token);
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
            _trackCacheService[track!.deezerTrackId!] == null) {
          trackIdsToPreload.add(track.deezerTrackId!);
        }
      }
      
      if (trackIdsToPreload.isNotEmpty) {
        _trackCacheService.preloadTracks(trackIdsToPreload, token, _apiService);
      }
      
      notifyListeners();
    }
  }

  bool isTrackInPlaylist(String trackId) {
    return _playlistTracks.any((pt) => pt.trackId == trackId || pt.track?.id == trackId);
  }

  Future<AddTrackResult> addTrackToPlaylist(String playlistId, String trackId, String token) async {
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

  Future<AddTrackResult> addTrackObjectToPlaylist(String playlistId, Track track, String token) async {
    return addTrackToPlaylist(playlistId, track.backendId, token);
  }

  Future<AddTrackResult> addRandomTrackToPlaylist(String playlistId, String token) async {
    try {
      final randomTracks = await _musicService.getRandomTracks(count: 1);
      if (randomTracks.isNotEmpty) {
        await _musicService.addTrackToPlaylist(playlistId, randomTracks.first.backendId, token);
      } else {
        return AddTrackResult(success: false, message: 'No random tracks available');
      }
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
    _playlistTracks = updatedTracks;
    
    notifyListeners();
    
    Future.delayed(const Duration(milliseconds: 100), () {
      _preloadTrackDetails(_playlistTracks);
    });
  }

  void updatePlaylistTracksWithPreload(List<PlaylistTrack> updatedTracks) {
    _playlistTracks = updatedTracks;
    
    notifyListeners();
    
    _preloadTrackDetails(updatedTracks);
    
    Future.microtask(() => notifyListeners());
  }

  void _preloadTrackDetails(List<PlaylistTrack> tracks) {
    try {
      final trackIdsToPreload = <String>[];
      for (final playlistTrack in tracks) {
        final track = playlistTrack.track;
        if (track?.deezerTrackId != null && 
            (track?.artist.isEmpty == true || track?.album.isEmpty == true || track?.imageUrl?.isEmpty == true) &&
            _trackCacheService[track!.deezerTrackId!] == null) {
          trackIdsToPreload.add(track.deezerTrackId!);
        }
      }
      
      if (trackIdsToPreload.isNotEmpty) {
        if (getIt.isRegistered<AuthService>()) {
          final authService = getIt<AuthService>();
          final token = authService.currentToken;
          if (token != null) {
            _trackCacheService.preloadTracks(trackIdsToPreload, token, _apiService).then((_) {
              _updateTracksWithCachedDetails();
            }).catchError((e) {
            });
          }
        }
      }
    } catch (e) {
    }
  }

  void _updateTracksWithCachedDetails() {
    bool updated = false;
    for (int i = 0; i < _playlistTracks.length; i++) {
      final playlistTrack = _playlistTracks[i];
      final track = playlistTrack.track;
      
      if (track?.deezerTrackId != null && _trackCacheService[track!.deezerTrackId!] != null) {
        final cachedTrack = _trackCacheService[track.deezerTrackId!];
        if (cachedTrack != null && 
            (cachedTrack.artist != track.artist || 
             cachedTrack.album != track.album || 
             cachedTrack.imageUrl != track.imageUrl)) {
          _playlistTracks[i] = playlistTrack.copyWithTrack(cachedTrack);
          updated = true;
        }
      }
    }
    
    if (updated) {
      notifyListeners();
    }
  }

  void updatePlaylistInCache(String playlistId, {
    String? name,
    String? description,
    bool? isPublic,
    List<Track>? tracks,
    String? licenseType,
    bool? isEvent,
    List<User>? sharedWith,
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
        licenseType: licenseType ?? currentPlaylist.licenseType,
        isEvent: isEvent ?? currentPlaylist.isEvent,
        sharedWith: sharedWith ?? currentPlaylist.sharedWith,
      );
      notifyListeners();
    }
  }

  Future<void> updatePlaylistDetails(String playlistId, String token, {String? name, String? description, bool? isEvent}) async {
    final result = await executeAsync(
      () async {
        final request = UpdatePlaylistRequest(name: name, description: description, isEvent: isEvent);
        await _apiService.updatePlaylist(playlistId, token, request);
        updatePlaylistInCache(playlistId, name: name, description: description, isEvent: isEvent);
      },
      errorMessage: 'Failed to update playlist details',
    );
    return result;
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

  Future<void> forceRefreshPlaylists(String token) async {
    _playlists = [];
    _userPlaylists = [];
    _publicPlaylists = [];
    notifyListeners();
    
    await fetchAllPlaylists(token);
  }

  Future<bool> deletePlaylist(String playlistId, String token) async {
    final result = await executeAsync(
      () async {
        await _musicService.deletePlaylist(playlistId, token);
        await fetchAllPlaylists(token);
        return true;
      },
      successMessage: 'Playlist deleted successfully',
      errorMessage: 'Failed to delete playlist',
    );
    return result ?? false;
  }

  Future<List<Playlist>> getSavedEvents(String token) async {
    final result = await executeAsync(
      () => _musicService.getSavedEvents(token),
      errorMessage: 'Failed to load saved events',
    );
    return result ?? [];
  }

  Future<List<Playlist>> getPublicEvents(String token) async {
    final result = await executeAsync(
      () => _musicService.getPublicEvents(token),
      errorMessage: 'Failed to load public events',
    );
    return result ?? [];
  }

  Future<List<Track>> getRandomTracksFromAPI({int count = 10}) async {
    final result = await executeAsync(
      () => _musicService.getRandomTracksFromAPI(count: count),
      errorMessage: 'Failed to load random tracks',
    );
    return result ?? [];
  }
}
