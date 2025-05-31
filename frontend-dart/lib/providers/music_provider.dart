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
    await execute(() async {
      _playlists = await _api.getPlaylists(token: token, publicOnly: false);
      _hasConnectionError = false;
    });
    
    if (hasError) {
      _hasConnectionError = true;
    }
  }

  Future<void> fetchPublicPlaylists(String token) async {
    await execute(() async {
      _playlists = await _api.getPlaylists(token: token, publicOnly: true);
      _hasConnectionError = false;
    });
    
    if (hasError) {
      _hasConnectionError = true;
    }
  }

  Future<Playlist?> getPlaylistDetails(String id, String token) async {
    if (id.isEmpty || id == 'null') return null;
    
    return await execute(() => _api.getPlaylist(id, token));
  }

  Future<void> fetchPlaylistTracks(String playlistId, String token) async {
    if (playlistId.isEmpty || playlistId == 'null') return;
    
    await execute(() async {
      _playlistTracks = await _api.getPlaylistTracks(playlistId, token);
    });
  }

  Future<String?> createPlaylist(String name, String description, bool isPublic, String token, [String? deviceUuid]) async {
    final result = await execute(() async {
      final id = deviceUuid != null 
          ? await _api.createPlaylistWithDevice(name, description, isPublic, token, deviceUuid)
          : await _api.createPlaylist(name, description, isPublic, token);
      await fetchUserPlaylists(token);
      return id;
    });
    return result;
  }

  Future<bool> changePlaylistVisibility(String playlistId, bool isPublic, String token) async {
    final result = await execute(() async {
      await _api.changePlaylistVisibility(playlistId, isPublic, token);
      await fetchUserPlaylists(token);
      return true;
    });
    return result ?? false;
  }

  Future<void> searchTracks(String query) async {
    await execute(() async {
      _searchResults = await _api.searchTracks(query, deezer: false);
    });
  }

  Future<void> searchDeezerTracks(String query) async {
    await execute(() async {
      _searchResults = await _api.searchTracks(query, deezer: true);
    });
  }

  Future<Track?> getDeezerTrack(String trackId) async {
    return await execute(() => _api.getDeezerTrack(trackId));
  }

  Future<String?> getDeezerTrackPreviewUrl(String trackId) async {
    final track = await getDeezerTrack(trackId);
    return track?.previewUrl;
  }

  Future<bool> addTrackFromDeezer(String trackId, String token) async {
    final result = await execute(() async {
      await _api.addTrackFromDeezer(trackId, token);
      return true;
    });
    return result ?? false;
  }

  Future<bool> addTrackToPlaylist(String playlistId, String trackId, String token, [String? deviceUuid]) async {
    if (playlistId.isEmpty || playlistId == 'null' || 
        trackId.isEmpty || trackId == 'null') return false;
    
    final result = await execute(() async {
      if (deviceUuid != null) {
        await _api.addTrackToPlaylistWithDevice(playlistId, trackId, token, deviceUuid);
      } else {
        await _api.addTrackToPlaylist(playlistId, trackId, token);
      }
      await fetchUserPlaylists(token);
      return true;
    });
    return result ?? false;
  }

  Future<bool> removeTrackFromPlaylist(String playlistId, String trackId, String token, [String? deviceUuid]) async {
    if (playlistId.isEmpty || playlistId == 'null') return false;
    
    final result = await execute(() async {
      await _api.removeTrackFromPlaylistWithDevice(playlistId, trackId, token, deviceUuid);
      return true;
    });
    return result ?? false;
  }

  Future<bool> moveTrackInPlaylist(String playlistId, int oldIndex, int newIndex, int rangeLength, String token, [String? deviceUuid]) async {
    if (playlistId.isEmpty || playlistId == 'null') return false;
    
    final result = await execute(() async {
      await _api.moveTrackInPlaylistWithDevice(playlistId, oldIndex, newIndex, rangeLength, token, deviceUuid);
      return true;
    });
    return result ?? false;
  }

  Future<bool> inviteUserToPlaylist(String playlistId, String userId, String token) async {
    if (playlistId.isEmpty || playlistId == 'null') return false;
    
    final result = await execute(() async {
      await _api.inviteUserToPlaylist(playlistId, userId, token);
      return true;
    });
    return result ?? false;
  }
}
