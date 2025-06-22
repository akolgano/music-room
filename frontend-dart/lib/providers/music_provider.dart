// lib/providers/music_provider.dart
import 'package:flutter/material.dart';
import '../core/service_locator.dart';
import '../services/music_service.dart';
import '../models/models.dart';
import '../models/sort_models.dart';
import '../services/track_sorting_service.dart';
import '../core/core.dart';

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
  List<PlaylistTrack> _originalPlaylistTracks = [];

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

  void updateTrackDetails(String trackId, Track updatedTrack) {
    final index = _playlistTracks.indexWhere((pt) => pt.trackId == trackId);
    if (index != -1) {
      _playlistTracks[index] = PlaylistTrack(
        trackId: _playlistTracks[index].trackId,
        name: _playlistTracks[index].name,
        position: _playlistTracks[index].position,
        track: updatedTrack,
      );
      notifyListeners();
    }
  }

  Future<void> fetchUserPlaylists(String token) async => _fetchPlaylists(token, false);
  Future<void> fetchPublicPlaylists(String token) async => _fetchPlaylists(token, true);

  Future<void> _fetchPlaylists(String token, bool publicOnly) async {
    final result = await executeAsync(() async {
      return publicOnly 
        ? await _musicService.getPublicPlaylists(token)
        : await _musicService.getUserPlaylists(token);
    });
    
    if (result != null) {
      _playlists = result;
      _hasConnectionError = false;
    }
    else _hasConnectionError = true;
  }

  Future<void> fetchMissingTrackDetails(String token) async {
    final tracksNeedingDetails = _playlistTracks
        .where((pt) => pt.track == null && pt.track?.deezerTrackId != null)
        .toList();

    if (tracksNeedingDetails.isEmpty) return;

    print('Fetching details for ${tracksNeedingDetails.length} tracks...');

    for (final playlistTrack in tracksNeedingDetails) {
      try {
        final deezerTrackId = playlistTrack.track?.deezerTrackId;
        if (deezerTrackId != null) {
          final trackDetails = await getDeezerTrack(deezerTrackId, token);
          if (trackDetails != null) {
            updateTrackDetails(playlistTrack.trackId, trackDetails);
          }
        }
      } catch (e) {
        print('Failed to fetch details for track ${playlistTrack.name}: $e');
      }
      
      await Future.delayed(const Duration(milliseconds: 200));
    }
    
    print('Finished fetching track details');
  }

  Future<Playlist?> getPlaylistDetails(String id, String token) async {
    print('MusicProvider: Getting playlist details for ID: $id');
    
    if (id.isEmpty || id == 'null') {
      print('MusicProvider: Invalid playlist ID');
      return null;
    }
    
    return await executeAsync(() async {
      print('MusicProvider: Calling music service...');
      final playlist = await _musicService.getPlaylistDetails(id, token);
      print('MusicProvider: Received playlist: ${playlist.name}');
      return playlist;
    });
  }

  Future<String?> createPlaylist(String name, String description, bool isPublic, String token, [String? deviceUuid]) async {
    final result = await executeAsync(() async {
      final id = await _musicService.createPlaylist(name, description, isPublic, token, deviceUuid);
      await fetchUserPlaylists(token);
      return id;
    });
    return result;
  }

  Future<void> updatePlaylistDetails({required String playlistId, String? name, String? description, bool? isPublic, required String token}) async {
    await executeAsync(() => _musicService.updatePlaylist(playlistId, name: name, description: description, isPublic: isPublic, token));
  }

  Future<void> searchDeezerTracks(String query) async {
    final result = await executeAsync(() => _musicService.searchDeezerTracks(query));
    if (result != null) _searchResults = result;
  }

  Future<Track?> getDeezerTrack(String trackId, String token) async {
    try {
      return await _musicService.getDeezerTrack(trackId, token);
    } catch (e) {
      setError(e.toString());
      return null;
    }
  }

  Future<String?> getDeezerTrackPreviewUrl(String trackId, String token) async {
    final track = await getDeezerTrack(trackId, token);
    return track?.previewUrl;
  }

  Future<void> fetchPlaylistTracks(String playlistId, String token) async {
    final result = await executeAsync(() async {
      print('Fetching playlist tracks for playlist $playlistId');
      
      final tracks = await _musicService.getPlaylistTracksWithDetails(playlistId, token);
      print('Received ${tracks.length} tracks from API');
      
      for (final track in tracks) {
        print('Raw track data: trackId=${track.trackId}, name=${track.name}, position=${track.position}');
        if (track.track != null) {
          print('  ✓ Track object created: id=${track.track!.id}, deezerTrackId=${track.track!.deezerTrackId}, artist=${track.track!.artist}');
        } else {
          print('  ✗ Track object is null - will try to fetch details later');
        }
      }
      return tracks;
    });
    
    if (result != null) {
      _playlistTracks = result;
      _originalPlaylistTracks = List.from(result);
      
      final tracksWithDetails = _playlistTracks.where((t) => t.track != null).length;
      final tracksWithDeezerIds = _playlistTracks.where((t) => t.track?.deezerTrackId != null).length;
      
      print('Successfully loaded ${_playlistTracks.length} tracks:');
      print('  - $tracksWithDetails with track objects');
      print('  - $tracksWithDeezerIds with Deezer IDs');
    }
  }

  Future<Track> getTrackWithDetails(String trackId, String token) async {
    final result = await executeAsync(() async {
      return await _musicService.getTrackWithDetails(trackId, token);
    });
    
    if (result == null) throw Exception('Track not found for ID: $trackId');
    
    return result;
  }

  Future<String?> getPlayableTrackUrl(PlaylistTrack playlistTrack, String token) async {
    Track? track = playlistTrack.track;
    
    if (track != null && track.previewUrl != null) return track.previewUrl;
    
    if (track?.deezerTrackId != null) {
      try {
        return await getDeezerTrackPreviewUrl(track!.deezerTrackId!, token);
      } catch (e) {
        print('Failed to get Deezer preview URL: $e');
      }
    }
    
    print('No preview URL available for ${playlistTrack.name}');
    return null;
  }

  bool get allTracksHaveDetails {
    return _playlistTracks.every((track) => track.track?.deezerTrackId != null);
  }

  List<PlaylistTrack> get tracksNeedingDetails {
    return _playlistTracks.where((track) => track.track?.deezerTrackId == null).toList();
  }

  Future<Track?> getPlayableTrack(String trackId, String token) async {
    final existingTrack = _playlistTracks
        .where((pt) => pt.trackId == trackId && pt.track?.deezerTrackId != null)
        .map((pt) => pt.track!).firstOrNull;
    if (existingTrack != null) return existingTrack;
    
    return await getTrackWithDetails(trackId, token);
  }

  Future<AddTrackResult> addTrackToPlaylist(String playlistId, String trackId, String token) async {
    return await executeAsync(() async {
      final existingTrack = _playlistTracks.firstWhere(
        (t) => t.trackId == trackId,
        orElse: () => const PlaylistTrack(trackId: '', name: '', position: -1),
      );
      
      if (existingTrack.position != -1) {
        return const AddTrackResult(
          success: true,
          message: 'Track is already in this playlist',
          isDuplicate: true,
        );
      }

      final track = getTrackById(trackId);
      if (track == null) {
        return const AddTrackResult(
          success: false,
          message: 'Track not found in search results',
          isDuplicate: false,
        );
      }

      String? deezerTrackId = track.deezerTrackId ?? track.backendId;
      
      if (deezerTrackId?.startsWith('deezer_') == true) deezerTrackId = deezerTrackId!.substring(7); 
      
      print('Adding track: ${track.name}, Clean Deezer ID: $deezerTrackId');

      try {
        print('Adding track to playlist with clean ID: $deezerTrackId');
        await _musicService.addTrackToPlaylist(playlistId, deezerTrackId!, token);
        print('✓ Successfully added track with ID: $deezerTrackId');
        
        await fetchPlaylistTracks(playlistId, token);
        return const AddTrackResult(
          success: true,
          message: 'Track added successfully',
          isDuplicate: false,
        );
      } catch (e) {
        print('✗ Failed to add track with clean ID $deezerTrackId: $e');
        return AddTrackResult(
          success: false,
          message: 'Unable to add track to playlist: $e',
          isDuplicate: false,
        );
      }
      
    }) ?? const AddTrackResult(
      success: false,
      message: 'Failed to add track to playlist',
      isDuplicate: false,
    );
  }

  Future<BatchAddResult> addMultipleTracksToPlaylist({
    required String playlistId,
    required List<String> trackIds,
    required String token,
    String? deviceUuid,
    Function(int current, int total)? onProgress,
  }) async {
    int successCount = 0;
    int duplicateCount = 0;
    int failureCount = 0;
    List<String> errors = [];

    for (int i = 0; i < trackIds.length; i++) {
      final trackId = trackIds[i];
      
      onProgress?.call(i + 1, trackIds.length);
      
      try {
        final result = await addTrackToPlaylist(playlistId, trackId, token);
        
        if (result.success) {
          successCount++;
        } else if (result.isDuplicate) {
          duplicateCount++;
        } else {
          failureCount++;
          errors.add(result.message);
        }
        
        await Future.delayed(const Duration(milliseconds: 1000));
      } catch (e) {
        failureCount++;
        errors.add('Failed to add track: $e');
      }
    }

    return BatchAddResult(totalTracks: trackIds.length, successCount: successCount, duplicateCount: duplicateCount, failureCount: failureCount, errors: errors);
  }

  Future<void> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
    required String token,
    String? deviceUuid,
  }) async {
    await executeAsync(() async {
      await _musicService.removeTrackFromPlaylist(playlistId, trackId, token);
      _playlistTracks.removeWhere((t) => t.trackId == trackId);
      notifyListeners();
    });
  }

  Future<bool> changePlaylistVisibility(String playlistId, bool isPublic, String token) async {
    await executeAsync(() => _musicService.changePlaylistVisibility(playlistId, isPublic, token));
    return !hasError;
  }

  Future<void> moveTrackInPlaylist({
    required String playlistId,
    required int rangeStart,
    required int insertBefore,
    int rangeLength = 1,
    required String token,
  }) async {
    await executeAsync(() => _musicService.moveTrackInPlaylist(
      playlistId: playlistId,
      rangeStart: rangeStart,
      insertBefore: insertBefore,
      rangeLength: rangeLength,
      token: token,
    ));
  }

  Future<void> inviteUserToPlaylist({required String playlistId, required int userId, required String token}) async {
    await executeAsync(() => _musicService.inviteUserToPlaylist(playlistId, userId, token));
  }

  Future<void> addTrackFromDeezer(String deezerTrackId, String token) async {
    await executeAsync(() => _musicService.addTrackFromDeezer(deezerTrackId, token));
  }

  Future<BatchLibraryAddResult> addMultipleTracksFromDeezer({
    required List<Track> tracks,
    required String token,
    Function(int current, int total, String trackName)? onProgress,
    bool addToTracksApi = false,
  }) async {
    int successCount = 0;
    int failureCount = 0;
    List<String> errors = [];
    List<String> successfulTracks = [];

    final validTracks = tracks.where((track) => 
      track.deezerTrackId != null && track.deezerTrackId!.isNotEmpty).toList();

    for (int i = 0; i < validTracks.length; i++) {
      final track = validTracks[i];
      
      onProgress?.call(i + 1, validTracks.length, track.name);
      
      try {
        await _musicService.addTrackFromDeezer(track.deezerTrackId!, token);
        successCount++;
        successfulTracks.add(track.name);
        if (i < validTracks.length - 1) await Future.delayed(const Duration(milliseconds: 1000));
      } catch (e) {
        failureCount++;
        errors.add('Failed to add "${track.name}": ${e.toString()}');
      }
    }

    return BatchLibraryAddResult(
      totalTracks: validTracks.length,
      successCount: successCount,
      failureCount: failureCount,
      errors: errors,
      successfulTracks: successfulTracks,
    );
  }

  void clearSearchResults() {
    _searchResults.clear();
    notifyListeners();
  }

  Track? getTrackById(String trackId) {
    try {
      return _searchResults.firstWhere((track) => track.id == trackId);
    } catch (e) {
      return null;
    }
  }

  bool isTrackInPlaylist(String trackId) {
    return _playlistTracks.any((t) => t.trackId == trackId);
  }

  List<Track> get deezerTracksFromSearch {
    return _searchResults.where((track) => 
      track.deezerTrackId != null && track.deezerTrackId!.isNotEmpty).toList();
  }

  bool get hasValidDeezerTracks {
    return deezerTracksFromSearch.isNotEmpty;
  }
}
