// lib/providers/music_provider.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class MusicProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  
  List<Playlist> _playlists = [];
  List<Track> _searchResults = [];
  List<Event> _events = [];
  List<PlaylistTrack> _playlistTracks = [];
  List<Device> _devices = [];
  List<MusicControlDelegate> _delegates = [];
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _isRetrying = false;
  bool _hasConnectionError = false;

  List<Playlist> get playlists => List.unmodifiable(_playlists);
  List<Track> get searchResults => List.unmodifiable(_searchResults);
  List<Event> get events => List.unmodifiable(_events);
  List<PlaylistTrack> get playlistTracks => List.unmodifiable(_playlistTracks);
  List<Device> get devices => List.unmodifiable(_devices);
  List<MusicControlDelegate> get delegates => List.unmodifiable(_delegates);
  
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

  Future<T?> _execute<T>(Future<T> Function() operation) async {
    _isLoading = true;
    _errorMessage = null;
    _hasConnectionError = false;
    _isRetrying = false;
    notifyListeners();

    try {
      final result = await operation();
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      _hasConnectionError = true;
      _startRetryTimer();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startRetryTimer() {
    _isRetrying = true;
    notifyListeners();
    
    Future.delayed(const Duration(seconds: 3), () {
      if (_isRetrying) {
        _isRetrying = false;
        notifyListeners();
      }
    });
  }

  Future<void> fetchUserPlaylists(String token) async {
    await _execute(() async {
      _playlists = await _api.getPlaylists(token: token, publicOnly: false);
    });
  }

  Future<void> fetchPublicPlaylists(String token) async {
    await _execute(() async {
      _playlists = await _api.getPlaylists(token: token, publicOnly: true);
    });
  }

  Future<Playlist?> getPlaylistDetails(String id, String token) async {
    if (id.isEmpty || id == 'null') return null;
    
    return await _execute(() => _api.getPlaylist(id, token));
  }

  Future<void> fetchPlaylistTracks(String playlistId, String token) async {
    if (playlistId.isEmpty || playlistId == 'null') return;
    
    await _execute(() async {
      _playlistTracks = await _api.getPlaylistTracks(playlistId, token);
    });
  }

  Future<String?> createPlaylist(String name, String description, bool isPublic, String token) async {
    final result = await _execute(() async {
      final id = await _api.createPlaylist(name, description, isPublic, token);
      await fetchUserPlaylists(token);
      return id;
    });
    return result;
  }

  Future<bool> updatePlaylist(String id, String name, String description, bool isPublic, String token) async {
    if (id.isEmpty || id == 'null') return false;
    
    final result = await _execute(() async {
      await _api.updatePlaylist(id, name, description, isPublic, token);
      await fetchUserPlaylists(token);
      return true;
    });
    return result ?? false;
  }

  Future<bool> deletePlaylist(String id, String token) async {
    if (id.isEmpty || id == 'null') return false;
    
    final result = await _execute(() async {
      await _api.deletePlaylist(id, token);
      await fetchUserPlaylists(token);
      return true;
    });
    return result ?? false;
  }

  Future<bool> addTrackToPlaylist(String playlistId, String trackId, String token) async {
    if (playlistId.isEmpty || playlistId == 'null' || 
        trackId.isEmpty || trackId == 'null') return false;
    
    final result = await _execute(() async {
      await _api.addTrackToPlaylist(playlistId, trackId, token);
      await fetchPlaylistTracks(playlistId, token); 
      return true;
    });
    return result ?? false;
  }

  Future<bool> removeTrackFromPlaylist(String playlistId, String trackId, String token) async {
    if (playlistId.isEmpty || playlistId == 'null') return false;
    
    final result = await _execute(() async {
      await _api.removeTrackFromPlaylist(playlistId, trackId, token);
      await fetchPlaylistTracks(playlistId, token); 
      return true;
    });
    return result ?? false;
  }

  Future<bool> moveTrackInPlaylist(String playlistId, int rangeStart, int insertBefore, int rangeLength, String token) async {
    if (playlistId.isEmpty || playlistId == 'null') return false;
    
    final result = await _execute(() async {
      await _api.moveTrackInPlaylist(playlistId, rangeStart, insertBefore, rangeLength, token);
      await fetchPlaylistTracks(playlistId, token); 
      return true;
    });
    return result ?? false;
  }

  Future<bool> changePlaylistVisibility(String playlistId, bool isPublic, String token) async {
    if (playlistId.isEmpty || playlistId == 'null') return false;
    
    final result = await _execute(() async {
      await _api.changePlaylistVisibility(playlistId, isPublic, token);
      await fetchUserPlaylists(token); 
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

  Future<void> searchTracks(String query) async {
    await _execute(() async {
      _searchResults = await _api.searchTracks(query, deezer: false);
    });
  }

  Future<void> searchDeezerTracks(String query) async {
    await _execute(() async {
      _searchResults = await _api.searchTracks(query, deezer: true);
    });
  }

  Future<Track?> getDeezerTrack(String trackId) async {
    return await _execute(() => _api.getDeezerTrack(trackId));
  }

  Future<String?> getDeezerTrackPreviewUrl(String trackId) async {
    try {
      final track = await _api.getDeezerTrack(trackId);
      return track.previewUrl;
    } catch (e) {
      return null;
    }
  }

  Future<bool> addTrackFromDeezer(String trackId, String token) async {
    final result = await _execute(() async {
      await _api.addTrackFromDeezer(trackId, token);
      return true;
    });
    return result ?? false;
  }

  Future<void> fetchDevices(String token) async {
    await _execute(() async {
      _devices = [];
    });
  }

  Future<Device?> registerDevice(String uuid, String licenseKey, String deviceName, String token) async {
    return await _execute(() => _api.registerDevice(uuid, licenseKey, deviceName, token));
  }

  Future<MusicControlDelegate?> delegateControl(String deviceUuid, String delegateUserId, bool canControl, String token) async {
    final result = await _execute(() async {
      final delegate = await _api.delegateControl(deviceUuid, delegateUserId, canControl, token);
      _delegates.add(delegate);
      return delegate;
    });
    return result;
  }

  Future<bool> checkControlPermission(String deviceUuid, String token) async {
    final result = await _execute(() => _api.checkControlPermission(deviceUuid, token));
    return result ?? false;
  }

  Future<void> fetchEvents() async {
    _events = [];
    notifyListeners();
  }
}
