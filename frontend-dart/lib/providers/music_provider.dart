// lib/providers/music_provider.dart
import 'package:flutter/material.dart';
import '../core/base_provider.dart';
import '../core/service_locator.dart';
import '../services/music_service.dart';
import '../models/models.dart';
import '../models/sort_models.dart';
import '../services/track_sorting_service.dart';

class MusicProvider extends BaseProvider {
  final MusicService _musicService = getIt<MusicService>();

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

  Future<void> fetchUserPlaylists(String token) async {
    final result = await executeAsync(
      () => _musicService.getUserPlaylists(token),
      errorMessage: 'Failed to load playlists',
    );
    if (result != null) {
      _playlists = result;
      _hasConnectionError = false;
    } else {
      _hasConnectionError = true;
    }
  }

  Future<void> fetchPublicPlaylists(String token) async {
    final result = await executeAsync(
      () => _musicService.getPublicPlaylists(token),
      errorMessage: 'Failed to load public playlists',
    );
    if (result != null) {
      _playlists = result;
      _hasConnectionError = false;
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
    if (result != null) {
      _searchResults = result;
    }
  }

  void clearSearchResults() {
    _searchResults.clear();
    notifyListeners();
  }

  Future<Track?> getDeezerTrack(String trackId, String token) async {
    try {
      setLoading(true);
      final track = await _musicService.getDeezerTrack(trackId, token);
      setLoading(false);
      return track;
    } catch (e) {
      setError('Failed to get track details');
      return null;
    }
  }

  Future<void> addTrackFromDeezer(String deezerTrackId, String token) async {
    await executeAsync(
      () => _musicService.addTrackFromDeezer(deezerTrackId, token),
      successMessage: 'Track added to library successfully!',
      errorMessage: 'Failed to add track to library',
    );
  }

  Track? getTrackById(String trackId) {
    for (final track in _searchResults) {
      if (track.id == trackId) return track;
    }
    for (final playlistTrack in _playlistTracks) {
      if (playlistTrack.track?.id == trackId) return playlistTrack.track;
      if (playlistTrack.trackId == trackId) return playlistTrack.track;
    }
    return null;
  }

  Future<void> fetchPlaylistTracks(String playlistId, String token) async {
    final result = await executeAsync(
      () => _musicService.getPlaylistTracksWithDetails(playlistId, token),
      errorMessage: 'Failed to load playlist tracks',
    );
    if (result != null) {
      _playlistTracks = result;
    }
  }

  bool isTrackInPlaylist(String trackId) {
    return _playlistTracks.any((pt) => pt.trackId == trackId || pt.track?.id == trackId);
  }

  Future<AddTrackResult> addTrackToPlaylist(String playlistId, String trackId, String token) async {
    try {
      final backendTrackId = Track.toBackendId(trackId);
      await _musicService.addTrackToPlaylist(playlistId, backendTrackId, token);
      return AddTrackResult(success: true, message: 'Track added successfully');
    } catch (e) {
      return AddTrackResult(success: false, message: e.toString());
    }
  }

  Future<AddTrackResult> addTrackObjectToPlaylist(String playlistId, Track track, String token) async {
    try {
      await _musicService.addTrackToPlaylist(playlistId, track.backendId, token);
      return AddTrackResult(success: true, message: 'Track added successfully');
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
      if (onProgress != null) {
        onProgress(i + 1, trackIds.length);
      }
      
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
      
      if (i < trackIds.length - 1) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    await fetchPlaylistTracks(playlistId, token);
    
    return BatchAddResult(
      totalTracks: trackIds.length,
      successCount: successCount,
      duplicateCount: duplicateCount,
      failureCount: failureCount,
      errors: errors,
    );
  }

  Future<void> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
    required String token,
  }) async {
    await executeAsync(
      () => _musicService.removeTrackFromPlaylist(playlistId, trackId, token),
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
      () => _musicService.moveTrackInPlaylist(
        playlistId: playlistId, rangeStart: rangeStart, insertBefore: insertBefore, rangeLength: rangeLength, token: token),
      successMessage: 'Track order updated',
      errorMessage: 'Failed to update track order',
    );
  }
}
