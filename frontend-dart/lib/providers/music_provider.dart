// lib/providers/music_provider.dart
import 'package:flutter/material.dart';
import '../core/service_locator.dart';
import '../services/music_service.dart';
import '../models/models.dart';
import '../core/core.dart';

class MusicProvider extends BaseProvider {
  final MusicService _musicService = getIt<MusicService>();
  
  List<Playlist> _playlists = [];
  List<Track> _searchResults = [];
  List<PlaylistTrack> _playlistTracks = [];
  bool _hasConnectionError = false;

  List<Playlist> get playlists => List.unmodifiable(_playlists);
  List<Track> get searchResults => List.unmodifiable(_searchResults);
  List<PlaylistTrack> get playlistTracks => List.unmodifiable(_playlistTracks);
  bool get hasConnectionError => _hasConnectionError;

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
    } else {
      _hasConnectionError = true;
    }
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

  Future<void> updatePlaylistDetails({
    required String playlistId,
    String? name,
    String? description,
    bool? isPublic,
    required String token,
  }) async {
    await executeAsync(() => _musicService.updatePlaylist(
      playlistId, 
      name: name, 
      description: description, 
      isPublic: isPublic, 
      token,
    ));
  }

  Future<void> searchTracks(String query) => _performSearch(query, false);
  Future<void> searchDeezerTracks(String query) => _performSearch(query, true);

  Future<void> _performSearch(String query, bool deezer) async {
    final result = await executeAsync(() async {
      return deezer 
        ? await _musicService.searchDeezerTracks(query)
        : await _musicService.searchTracks(query);
    });
    if (result != null) _searchResults = result;
  }

  Future<Track?> getDeezerTrack(String trackId) async {
    return await executeAsync(() => _musicService.getDeezerTrack(trackId));
  }

  Future<String?> getDeezerTrackPreviewUrl(String trackId) async {
    final track = await getDeezerTrack(trackId);
    return track?.previewUrl;
  }

  Future<void> fetchPlaylistTracks(String playlistId, String token) async {
    final result = await executeAsync(() => _musicService.getPlaylistTracks(playlistId, token));
    if (result != null) _playlistTracks = result;
  }

  Future<AddTrackResult> addTrackToPlaylist(String playlistId, String trackId, String token, String? deviceUuid) async {
    return await executeAsync(() async {
      final existingTrack = _playlistTracks.firstWhere(
        (t) => t.trackId == trackId,
        orElse: () => const PlaylistTrack(trackId: '', name: '', position: -1),
      );
      
      if (existingTrack.position != -1) {
        return const AddTrackResult(
          success: false,
          message: 'Track is already in this playlist',
          isDuplicate: true,
        );
      }

      await _musicService.addTrackToPlaylist(playlistId, trackId, token, deviceUuid);
      await fetchPlaylistTracks(playlistId, token);

      return const AddTrackResult(
        success: true,
        message: 'Track added successfully',
        isDuplicate: false,
      );
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
        final result = await addTrackToPlaylist(playlistId, trackId, token, deviceUuid);
        
        if (result.success) {
          successCount++;
        } else if (result.isDuplicate) {
          duplicateCount++;
        } else {
          failureCount++;
          errors.add(result.message);
        }
        
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        failureCount++;
        errors.add('Failed to add track: $e');
      }
    }

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
        
        if (addToTracksApi) await _musicService.addTrackFromDeezerToTracks(track.deezerTrackId!, token);
        
        successCount++;
        successfulTracks.add(track.name);
        
        if (i < validTracks.length - 1) await Future.delayed(const Duration(milliseconds: 200));
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

  Future<void> addSingleTrackFromDeezerToTracks(String trackId, String token) async {
    await executeAsync(() => _musicService.addTrackFromDeezerToTracks(trackId, token));
  }
}
