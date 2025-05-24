// lib/providers/music_provider.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class MusicProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Playlist> _playlists = [];
  List<Track> _searchResults = [];
  List<Event> _events = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isRetrying = false;
  bool _hasConnectionError = false;

  List<Playlist> get playlists => List.unmodifiable(_playlists);
  List<Track> get searchResults => List.unmodifiable(_searchResults);
  List<Event> get events => List.unmodifiable(_events);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get isRetrying => _isRetrying;
  bool get hasConnectionError => _hasConnectionError;

  void clearError() {
    _errorMessage = null;
    _hasConnectionError = false;
    notifyListeners();
  }

  Future<void> fetchUserPlaylists(String token) async {
    try {
      _isLoading = true;
      _hasConnectionError = false;
      _isRetrying = false;
      notifyListeners();

      _playlists = await _apiService.getPlaylists(token: token, publicOnly: false);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _hasConnectionError = true;
      _startRetryTimer(token);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPublicPlaylists(String token) async {
    try {
      _isLoading = true;
      _hasConnectionError = false;
      _isRetrying = false;
      notifyListeners();

      _playlists = await _apiService.getPlaylists(token: token, publicOnly: true);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _hasConnectionError = true;
      _startRetryTimer(token);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startRetryTimer(String token) {
    _isRetrying = true;
    notifyListeners();
    
    Future.delayed(const Duration(seconds: 3), () {
      if (_isRetrying) {
        fetchUserPlaylists(token).catchError((_) => fetchPublicPlaylists(token));
      }
    });
  }

  Future<Playlist?> getPlaylistDetails(String id, String token) async {
    if (id.isEmpty || id == 'null') {
      _errorMessage = 'Invalid playlist ID: $id';
      notifyListeners();
      print('MusicProvider: Invalid playlist ID: $id');
      return null;
    }
    
    try {
      print('MusicProvider: Getting playlist details for ID: $id');
      return await _apiService.getPlaylist(id, token);
    } catch (e) {
      _errorMessage = e.toString();
      print('MusicProvider: Error getting playlist details: $e');
      notifyListeners();
      return null;
    }
  }

  Future<String?> createPlaylist(String name, String description, bool isPublic, String token) async {
    try {
      final id = await _apiService.createPlaylist(name, description, isPublic, token);
      await fetchUserPlaylists(token);
      return id;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> updatePlaylist(String id, String name, String description, bool isPublic, String token) async {
    if (id.isEmpty || id == 'null') {
      _errorMessage = 'Invalid playlist ID: $id';
      notifyListeners();
      print('MusicProvider: Invalid playlist ID for update: $id');
      return false;
    }
    
    try {
      print('MusicProvider: Updating playlist ID: $id');
      await _apiService.updatePlaylist(id, name, description, isPublic, token);
      await fetchUserPlaylists(token);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('MusicProvider: Error updating playlist: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePlaylist(String id, String token) async {
    if (id.isEmpty || id == 'null') {
      _errorMessage = 'Invalid playlist ID: $id';
      notifyListeners();
      print('MusicProvider: Invalid playlist ID for deletion: $id');
      return false;
    }
    
    try {
      print('MusicProvider: Deleting playlist ID: $id');
      await _apiService.deletePlaylist(id, token);
      await fetchUserPlaylists(token);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('MusicProvider: Error deleting playlist: $e');
      notifyListeners();
      return false;
    }
  }

  Future<void> searchTracks(String query) async {
    try {
      _searchResults = await _apiService.searchTracks(query, deezer: false);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> searchDeezerTracks(String query) async {
    try {
      _searchResults = await _apiService.searchTracks(query, deezer: true);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<Track?> getDeezerTrack(String trackId) async {
    try {
      return await _apiService.getDeezerTrack(trackId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<String?> getDeezerTrackPreviewUrl(String trackId) async {
    try {
      final track = await _apiService.getDeezerTrack(trackId);
      return track.previewUrl;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> addTrackFromDeezer(String trackId, String token) async {
    try {
      await _apiService.addTrackFromDeezer(trackId, token);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addTrackToPlaylist(String playlistId, String trackId, String token) async {
    if (playlistId.isEmpty || playlistId == 'null') {
      _errorMessage = 'Invalid playlist ID: $playlistId';
      notifyListeners();
      print('MusicProvider: Invalid playlist ID for adding track: $playlistId');
      return false;
    }
    
    if (trackId.isEmpty || trackId == 'null') {
      _errorMessage = 'Invalid track ID: $trackId';
      notifyListeners();
      print('MusicProvider: Invalid track ID: $trackId');
      return false;
    }
    
    try {
      print('MusicProvider: Adding track $trackId to playlist $playlistId');
      await _apiService.addTrackToPlaylist(playlistId, trackId, token);
      await fetchUserPlaylists(token);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('MusicProvider: Error adding track to playlist: $e');
      notifyListeners();
      return false;
    }
  }
}
