// lib/providers/music_provider.dart
import 'package:flutter/material.dart';
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

  Future<void> fetchUserPlaylists(String token) async {
    final result = await execute(() => _api.getPlaylists(token: token, publicOnly: false));
    if (result != null) {
      _playlists = result;
      _hasConnectionError = false;
    } else {
      _hasConnectionError = true;
    }
  }

  Future<void> fetchPublicPlaylists(String token) async {
    final result = await execute(() => _api.getPlaylists(token: token, publicOnly: true));
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

  Future<void> searchTracks(String query) async {
    final result = await execute(() => _api.searchTracks(query, deezer: false));
    if (result != null) _searchResults = result;
  }

  Future<void> searchDeezerTracks(String query) async {
    final result = await execute(() => _api.searchTracks(query, deezer: true));
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

  Future<void> removeTrackFromPlaylist(String playlistId, String trackId, String token, String? deviceUuid) async {
    await execute(() => _api.post('/playlists/$playlistId/tracks/remove', {
      'track_id': trackId,
      if (deviceUuid != null) 'device_uuid': deviceUuid,
    }, token));
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
}
