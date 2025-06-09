// lib/providers/music_provider.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../models/models.dart';
import 'base_provider.dart';

class MusicProvider with ChangeNotifier, BaseProvider {
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
    final result = await execute(() => _api.getPlaylists(token: token, publicOnly: publicOnly));
    if (result != null) {
      _playlists = result;
      _hasConnectionError = false;
    } else {
      _hasConnectionError = true;
    }
  }

  Future<Playlist?> getPlaylistDetails(String id, String token) async {
    if (id.isEmpty || id == 'null') return null;
    return await execute(() => _api.getPlaylist(id, token));
  }

  Future<String?> createPlaylist(String name, String description, bool isPublic, String token, [String? deviceUuid]) async {
    final result = await execute(() async {
      final id = await _api.createPlaylist(name, description, isPublic, token, deviceUuid);
      await fetchUserPlaylists(token); 
      return id;
    });
    return result;
  }

  Future<void> searchTracks(String query) => _performSearch(query, false);
  Future<void> searchDeezerTracks(String query) => _performSearch(query, true);

  Future<void> _performSearch(String query, bool deezer) async {
    final result = await execute(() => _api.searchTracks(query, deezer: deezer));
    if (result != null) _searchResults = result;
  }

  Future<Track?> getDeezerTrack(String trackId) async {
    return await execute(() => _api.getDeezerTrack(trackId));
  }

  Future<String?> getDeezerTrackPreviewUrl(String trackId) async {
    final track = await getDeezerTrack(trackId);
    return track?.previewUrl;
  }

  Future<void> fetchPlaylistTracks(String playlistId, String token) async {
    final result = await execute(() async {
      final response = await _api.get('/playlists/playlist/$playlistId/tracks', token);
      final tracksData = response['tracks'] as List<dynamic>;
      return tracksData.map((t) => PlaylistTrack.fromJson(t)).toList();
    });
    if (result != null) _playlistTracks = result;
  }

  Future<void> addTrackToPlaylist(String playlistId, String trackId, String token, String? deviceUuid) async {
    await execute(() => _api.post('/playlists/$playlistId/tracks', {
      'track_id': trackId,
      if (deviceUuid != null) 'device_uuid': deviceUuid,
    }, token));
  }

  Future<void> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
    required String token,
    String? deviceUuid,
  }) async {
    await execute(() => _api.removeTrackFromPlaylist(
      playlistId: playlistId,
      trackId: trackId,
      token: token,
      deviceUuid: deviceUuid,
    ));
  }

  Future<bool> changePlaylistVisibility(String playlistId, bool isPublic, String token) async {
    final result = await execute(() => _api.post('/playlists/$playlistId/visibility', {
      'public': isPublic,
    }, token));
    return result != null;
  }

  Future<void> addTrackFromDeezer(String deezerTrackId, String token) async {
    await execute(() => _api.post('/tracks/add_from_deezer', {
      'deezer_track_id': deezerTrackId,
    }, token));
  }

  Future<bool> performMusicAction(String endpoint, Map<String, dynamic> data, String token) async {
    final result = await execute(() => _api.post(endpoint, data, token));
    return result != null;
  }

  Future<Map<String, dynamic>?> getMusicData(String endpoint, String token) async {
    return await execute(() => _api.get(endpoint, token));
  }

  Future<void> moveTrackInPlaylist({
    required String playlistId,
    required int rangeStart,
    required int insertBefore,
    int rangeLength = 1,
    required String token,
  }) async {
    await execute(() => _api.moveTrackInPlaylist(
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
    await execute(() => _api.inviteUserToPlaylist(
      playlistId: playlistId,
      userId: userId,
      token: token,
    ));
  }

  Future<List<PlaylistTrack>> getPlaylistTracksWithDetails(String playlistId, String token) async {
    final result = await execute(() async {
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
    final result = await execute(() async {
      return 'musicroom://playlist/$playlistId';
    });
    return result;
  }

  Future<void> savePublicPlaylist(String playlistId, String token) async {
    await execute(() => _api.post('/playlists/$playlistId/save/', {}, token));
  }

  Future<void> searchTracksWithFilters({
    required String query,
    String? artist,
    String? album,
    bool deezer = true,
  }) async {
    final params = <String, String>{
      if (deezer) 'q' : query else 'query': query,
      if (artist != null) 'artist': artist,
      if (album != null) 'album': album,
    };
    
    final result = await execute(() async {
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

  Future<void> addMultipleTracksToPlaylist({
    required String playlistId,
    required List<String> trackIds,
    required String token,
    String? deviceUuid,
  }) async {
    await _batchPlaylistOperation(playlistId, trackIds, token, deviceUuid, true);
  }

  Future<void> removeMultipleTracksFromPlaylist({
    required String playlistId,
    required List<String> trackIds,
    required String token,
    String? deviceUuid,
  }) async {
    await _batchPlaylistOperation(playlistId, trackIds, token, deviceUuid, false);
  }

  Future<void> _batchPlaylistOperation(
    String playlistId,
    List<String> trackIds,
    String token,
    String? deviceUuid,
    bool isAdd,
  ) async {
    await execute(() async {
      for (final trackId in trackIds) {
        if (isAdd) {
          await _api.post('/playlists/$playlistId/tracks/', {
            'track_id': trackId,
            if (deviceUuid != null) 'device_uuid': deviceUuid,
          }, token);
        } else {
          await _api.removeTrackFromPlaylist(
            playlistId: playlistId,
            trackId: trackId,
            token: token,
            deviceUuid: deviceUuid,
          );
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }
    });
  }

  Future<Map<String, dynamic>> getPlaylistStatistics(String playlistId, String token) async {
    final result = await execute(() async {
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
    final result = await execute(() async {
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
    await execute(() async {
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
    final result = await execute(() async {
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
    final result = await execute(() async {
      final results = await _api.searchTracks('popular music', deezer: true);
      return results.take(limit).toList();
    });
    return result ?? [];
  }
}
