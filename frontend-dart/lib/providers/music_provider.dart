// lib/providers/music_provider.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/playlist.dart';
import '../models/track.dart';
import '../models/playlist_track.dart';

class MusicProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  
  List<Playlist> _playlists = [];
  List<Track> _searchResults = [];
  List<PlaylistTrack> _playlistTracks = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasConnectionError = false;

  List<Playlist> get playlists => List.unmodifiable(_playlists);
  List<Track> get searchResults => List.unmodifiable(_searchResults);
  List<PlaylistTrack> get playlistTracks => List.unmodifiable(_playlistTracks);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get hasConnectionError => _hasConnectionError;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<T?> _execute<T>(Future<T> Function() operation) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await operation();
      _hasConnectionError = false;
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      _hasConnectionError = true;
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserPlaylists(String token) async {
    final result = await _execute(() => _api.getPlaylists(token: token, publicOnly: false));
    if (result != null) _playlists = result;
  }

  Future<void> fetchPublicPlaylists(String token) async {
    final result = await _execute(() => _api.getPlaylists(token: token, publicOnly: true));
    if (result != null) _playlists = result;
  }

  Future<Playlist?> getPlaylistDetails(String id, String token) async {
    if (id.isEmpty || id == 'null') return null;
    return await _execute(() => _api.getPlaylist(id, token));
  }

  Future<void> fetchPlaylistTracks(String playlistId, String token) async {
    if (playlistId.isEmpty || playlistId == 'null') return;
    final result = await _execute(() => _api.getPlaylistTracks(playlistId, token));
    if (result != null) _playlistTracks = result;
  }

  Future<String?> createPlaylist(String name, String description, bool isPublic, String token, [String? deviceUuid]) async {
    final result = await _execute(() async {
      final id = deviceUuid != null 
        ? await _api.createPlaylistWithDevice(name, description, isPublic, token, deviceUuid)
        : await _api.createPlaylist(name, description, isPublic, token);
      await fetchUserPlaylists(token); 
      return id;
    });
    return result;
  }

  Future<bool> changePlaylistVisibility(String playlistId, bool isPublic, String token) async {
    final result = await _execute(() async {
      await _api.changePlaylistVisibility(playlistId, isPublic, token);
      final index = _playlists.indexWhere((p) => p.id == playlistId);
      if (index != -1) {
        _playlists[index] = Playlist(
          id: _playlists[index].id,
          name: _playlists[index].name,
          description: _playlists[index].description,
          isPublic: isPublic, 
          creator: _playlists[index].creator,
          tracks: _playlists[index].tracks,
          imageUrl: _playlists[index].imageUrl,
        );
      }
      return true;
    });
    return result ?? false;
  }

  Future<void> searchTracks(String query) async {
    final result = await _execute(() => _api.searchTracks(query, deezer: false));
    if (result != null) _searchResults = result;
  }

  Future<void> searchDeezerTracks(String query) async {
    final result = await _execute(() => _api.searchTracks(query, deezer: true));
    if (result != null) _searchResults = result;
  }

  Future<Track?> getDeezerTrack(String trackId) async {
    return await _execute(() => _api.getDeezerTrack(trackId));
  }

  Future<String?> getDeezerTrackPreviewUrl(String trackId) async {
    final track = await getDeezerTrack(trackId);
    return track?.previewUrl;
  }

  Future<bool> addTrackFromDeezer(String trackId, String token) async {
    final result = await _execute(() async {
      await _api.addTrackFromDeezer(trackId, token);
      return true;
    });
    return result ?? false;
  }

  Future<bool> addTrackToPlaylist(String playlistId, String trackId, String token, [String? deviceUuid]) async {
    if (playlistId.isEmpty || playlistId == 'null' || trackId.isEmpty || trackId == 'null') return false;
    
    final result = await _execute(() async {
      if (deviceUuid != null) {
        await _api.addTrackToPlaylistWithDevice(playlistId, trackId, token, deviceUuid);
      } else {
        await _api.addTrackToPlaylist(playlistId, trackId, token);
      }
      return true;
    });
    return result ?? false;
  }

  Future<bool> removeTrackFromPlaylist(String playlistId, String trackId, String token, [String? deviceUuid]) async {
    if (playlistId.isEmpty || playlistId == 'null') return false;
    
    final result = await _execute(() async {
      await _api.removeTrackFromPlaylistWithDevice(playlistId, trackId, token, deviceUuid);
      _playlistTracks.removeWhere((pt) => pt.trackId == trackId);
      return true;
    });
    return result ?? false;
  }

  Future<bool> moveTrackInPlaylist(String playlistId, int oldIndex, int newIndex, int rangeLength, String token, [String? deviceUuid]) async {
    if (playlistId.isEmpty || playlistId == 'null') return false;
    
    final result = await _execute(() async {
      await _api.moveTrackInPlaylistWithDevice(playlistId, oldIndex, newIndex, rangeLength, token, deviceUuid);
      return true;
    });
    return result ?? false;
  }

  Future<bool> inviteUserToPlaylist(String playlistId, String userId, String token) async {
    if (playlistId.isEmpty || playlistId == 'null') return false;
    
    final result = await _execute(() async {
      await _api.inviteUserToPlaylist(playlistId, userId, token);
      return true;
    });
    return result ?? false;
  }
}
