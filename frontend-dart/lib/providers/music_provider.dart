// lib/providers/music_provider.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../models/models.dart';
import '../core/consolidated_core.dart'; 

class MusicProvider extends BaseProvider {
  final ApiService _api = ApiService();
  
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
    final result = await executeAsync(() => _api.getPlaylists(token: token, publicOnly: publicOnly));
    if (result != null) {
      _playlists = result;
      _hasConnectionError = false;
    } else {
      _hasConnectionError = true;
    }
  }

  Future<Playlist?> getPlaylistDetails(String id, String token) async {
    if (id.isEmpty || id == 'null') return null;
    return await executeAsync(() => _api.getPlaylist(id, token));
  }

  Future<String?> createPlaylist(String name, String description, bool isPublic, String token, [String? deviceUuid]) async {
    final result = await executeAsync(() async {
      final id = await _api.createPlaylist(name, description, isPublic, token, deviceUuid);
      await fetchUserPlaylists(token); 
      return id;
    });
    return result;
  }

  Future<void> searchTracks(String query) => _performSearch(query, false);
  Future<void> searchDeezerTracks(String query) => _performSearch(query, true);

  Future<void> _performSearch(String query, bool deezer) async {
    final result = await executeAsync(() => _api.searchTracks(query, deezer: deezer));
    if (result != null) _searchResults = result;
  }

  Future<Track?> getDeezerTrack(String trackId) async {
    return await executeAsync(() => _api.getDeezerTrack(trackId));
  }

  Future<String?> getDeezerTrackPreviewUrl(String trackId) async {
    final track = await getDeezerTrack(trackId);
    return track?.previewUrl;
  }

  Future<void> fetchPlaylistTracks(String playlistId, String token) async {
    final result = await executeAsync(() async {
      final response = await _api.get('/playlists/playlist/$playlistId/tracks', token);
      final tracksData = response['tracks'] as List<dynamic>;
      return tracksData.map((t) => PlaylistTrack.fromJson(t)).toList();
    });
    if (result != null) _playlistTracks = result;
  }

  Future<AddTrackResult> addTrackToPlaylist(String playlistId, String trackId, String token, String? deviceUuid) async {
    return await executeAsync(() async {
      final existingTrack = _playlistTracks.firstWhere(
        (t) => t.trackId == trackId,
        orElse: () => PlaylistTrack(trackId: '', name: '', position: -1),
      );
      
      if (existingTrack.position != -1) {
        return AddTrackResult(
          success: false,
          message: 'Track is already in this playlist',
          isDuplicate: true,
        );
      }

      await _api.post('/playlists/$playlistId/tracks', {
        'track_id': trackId,
        if (deviceUuid != null) 'device_uuid': deviceUuid,
      }, token);

      await fetchPlaylistTracks(playlistId, token);

      return AddTrackResult(
        success: true,
        message: 'Track added successfully',
        isDuplicate: false,
      );
    }) ?? AddTrackResult(
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
      await _api.removeTrackFromPlaylist(
        playlistId: playlistId,
        trackId: trackId,
        token: token,
        deviceUuid: deviceUuid,
      );
      
      _playlistTracks.removeWhere((t) => t.trackId == trackId);
      notifyListeners();
    });
  }

  Future<bool> changePlaylistVisibility(String playlistId, bool isPublic, String token) async {
    final result = await executeAsync(() => _api.post('/playlists/$playlistId/visibility', {
      'public': isPublic,
    }, token));
    return result != null;
  }

  Future<bool> performMusicAction(String endpoint, Map<String, dynamic> data, String token) async {
    final result = await executeAsync(() => _api.post(endpoint, data, token));
    return result != null;
  }

  Future<Map<String, dynamic>?> getMusicData(String endpoint, String token) async {
    return await executeAsync(() => _api.get(endpoint, token));
  }

  Future<void> moveTrackInPlaylist({
    required String playlistId,
    required int rangeStart,
    required int insertBefore,
    int rangeLength = 1,
    required String token,
  }) async {
    await executeAsync(() => _api.moveTrackInPlaylist(
      playlistId: playlistId,
      rangeStart: rangeStart,
      insertBefore: insertBefore,
      rangeLength: rangeLength,
      token: token,
    ));
  }

  Future<void> inviteUserToPlaylist({
    required String playlistId,
    required int userId,
    required String token,
  }) async {
    await executeAsync(() => _api.inviteUserToPlaylist(
      playlistId: playlistId,
      userId: userId,
      token: token,
    ));
  }

  Future<List<PlaylistTrack>> getPlaylistTracksWithDetails(String playlistId, String token) async {
    final result = await executeAsync(() async {
      final response = await _api.get('/playlists/playlist/$playlistId/tracks/', token);
      final tracksData = response['tracks'] as List<dynamic>;
      return tracksData.map((t) {
        final trackData = t['track'] ?? {};
        final track = Track.fromJson(trackData);
        return PlaylistTrack(
          trackId: track.id,
          name: track.name,
          position: t['position'] ?? 0,
          track: track,
        );
      }).toList();
    });
    return result ?? [];
  }

  Future<String?> generatePlaylistShareLink(String playlistId, String token) async {
    final result = await executeAsync(() async {
      return 'musicroom://playlist/$playlistId';
    });
    return result;
  }

  Future<void> savePublicPlaylist(String playlistId, String token) async {
    await executeAsync(() => _api.post('/playlists/$playlistId/save/', {}, token));
  }

  Future<void> searchTracksWithFilters({
    required String query,
    String? artist,
    String? album,
    bool deezer = true,
    int limit = 50,
  }) async {
    final params = <String, String>{
      if (deezer) 'q' : query else 'query': query,
      if (artist != null) 'artist': artist,
      if (album != null) 'album': album,
      'limit': limit.toString(),
    };
    
    final result = await executeAsync(() async {
      final endpoint = deezer ? '/deezer/search/' : '/tracks/search/';
      final uri = Uri.parse('http://localhost:8000$endpoint').replace(queryParameters: params);
      final response = await http.get(uri);
      
      if (response.statusCode >= 400) {
        throw Exception('Search failed');
      }
      
      final data = json.decode(response.body);
      final tracks = deezer ? data['data'] as List<dynamic> : data['tracks'] as List<dynamic>;
      return tracks.map((t) => Track.fromJson(t as Map<String, dynamic>)).toList();
    });
    
    if (result != null) _searchResults = result;
  }

  Future<Map<String, dynamic>> getPlaylistStatistics(String playlistId, String token) async {
    final result = await executeAsync(() async {
      final playlist = await getPlaylistDetails(playlistId, token);
      if (playlist == null) return <String, dynamic>{};
      
      final tracks = playlist.tracks;
      return {
        'total_tracks': tracks.length,
        'unique_artists': tracks.map((t) => t.artist).toSet().length,
        'estimated_duration_minutes': tracks.length * 3.5,
        'created_date': DateTime.now().toIso8601String(),
        'last_modified': DateTime.now().toIso8601String(),
      };
    });
    return result ?? {};
  }

  Future<List<Map<String, dynamic>>> getPlaylistCollaborators(String playlistId, String token) async {
    final result = await executeAsync(() async {
      final response = await _api.get('/playlists/$playlistId/collaborators/', token);
      return List<Map<String, dynamic>>.from(response['collaborators'] ?? []);
    });
    return result ?? [];
  }

  Future<void> updatePlaylistDetails({
    required String playlistId,
    String? name,
    String? description,
    bool? isPublic,
    required String token,
  }) async {
    await executeAsync(() async {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (isPublic != null) updates['public'] = isPublic;
      
      if (updates.isNotEmpty) {
        await _api.post('/playlists/$playlistId/update/', updates, token);
      }
    });
  }

  Future<Map<String, dynamic>> exportPlaylist(String playlistId, String token) async {
    final result = await executeAsync(() async {
      final playlist = await getPlaylistDetails(playlistId, token);
      if (playlist == null) return <String, dynamic>{};
      
      return {
        'name': playlist.name,
        'description': playlist.description,
        'tracks': playlist.tracks.map((t) => {
          'name': t.name,
          'artist': t.artist,
          'album': t.album,
          'deezer_track_id': t.deezerTrackId,
        }).toList(),
        'exported_at': DateTime.now().toIso8601String(),
        'exported_by': 'Music Room App',
      };
    });
    return result ?? {};
  }

  Future<List<Track>> getRecommendedTracks({
    String? basedOnPlaylistId,
    String? basedOnTrackId,
    required String token,
    int limit = 20,
  }) async {
    final result = await executeAsync(() async {
      final results = await _api.searchTracks('popular music', deezer: true);
      return results.take(limit).toList();
    });
    return result ?? [];
  }

  Future<void> addTrackFromDeezer(String deezerTrackId, String token) async {
    await executeAsync(() => _api.addTrackFromDeezer(deezerTrackId, token));
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
}

class AddTrackResult {
  final bool success;
  final String message;
  final bool isDuplicate;

  AddTrackResult({
    required this.success,
    required this.message,
    required this.isDuplicate,
  });
}

class BatchAddResult {
  final int totalTracks;
  final int successCount;
  final int duplicateCount;
  final int failureCount;
  final List<String> errors;

  BatchAddResult({
    required this.totalTracks,
    required this.successCount,
    required this.duplicateCount,
    required this.failureCount,
    required this.errors,
  });

  bool get hasErrors => failureCount > 0;
  bool get hasPartialSuccess => successCount > 0 && failureCount > 0;
  bool get isCompleteSuccess => successCount == totalTracks;
  
  String get summaryMessage {
    if (isCompleteSuccess) {
      return 'All $totalTracks tracks added successfully!';
    } else if (hasPartialSuccess) {
      return '$successCount/$totalTracks tracks added successfully';
    } else {
      return 'Failed to add tracks to playlist';
    }
  }

  String get detailedMessage {
    final parts = <String>[];
    if (successCount > 0) parts.add('$successCount added');
    if (duplicateCount > 0) parts.add('$duplicateCount duplicates');
    if (failureCount > 0) parts.add('$failureCount failed');
    return parts.join(', ');
  }
}
