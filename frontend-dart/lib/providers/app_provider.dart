// lib/providers/app_provider.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class AppProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  
  bool _isLoggedIn = false;
  String? _token;
  String? _userId;
  String? _username;

  List<Playlist> _playlists = [];
  List<Track> _searchResults = [];
  List<int> _friends = [];
  List<Map<String, dynamic>> _pendingRequests = [];

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;
  String? get userId => _userId;
  String? get username => _username;
  List<Playlist> get playlists => List.unmodifiable(_playlists);
  List<Track> get searchResults => List.unmodifiable(_searchResults);
  List<int> get friends => List.unmodifiable(_friends);
  List<Map<String, dynamic>> get pendingRequests => List.unmodifiable(_pendingRequests);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Token $_token',
  };

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<T?> _execute<T>(Future<T> Function() operation, [String? context]) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await operation();
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    final result = await _execute(() async {
      final authResult = await _api.login(username, password);
      _token = authResult.token;
      _userId = authResult.user.id;
      _username = authResult.user.username;
      _isLoggedIn = true;
      await _saveUserData();
      return true;
    });
    return result ?? false;
  }

  Future<bool> signup(String username, String email, String password) async {
    final result = await _execute(() async {
      final authResult = await _api.signup(username, email, password);
      _token = authResult.token;
      _userId = authResult.user.id;
      _username = authResult.user.username;
      _isLoggedIn = true;
      await _saveUserData();
      return true;
    });
    return result ?? false;
  }

  Future<void> logout() async {
    _clearUserData();
    notifyListeners();
  }

  Future<void> fetchPlaylists({bool publicOnly = false}) async {
    if (_token == null) {
      _errorMessage = 'Authentication required';
      notifyListeners();
      return;
    }
    
    await _execute(() async {
      _playlists = await _api.getPlaylists(
        token: _token!,
        publicOnly: publicOnly,
      );
    });
  }

  Future<Playlist?> getPlaylistDetails(String id) async {
    if (_token == null) {
      _errorMessage = 'Authentication required';
      notifyListeners();
      return null;
    }
    
    if (id.isEmpty || id == 'null') {
      _errorMessage = 'Invalid playlist ID: $id';
      notifyListeners();
      print('AppProvider: Invalid playlist ID: $id');
      return null;
    }
    
    return await _execute(() {
      print('AppProvider: Getting playlist details for ID: $id');
      return _api.getPlaylist(id, _token!);
    });
  }

  Future<String?> createPlaylist(String name, String description, bool isPublic) async {
    if (_token == null) return null;
    
    final result = await _execute(() async {
      final id = await _api.createPlaylist(name, description, isPublic, _token!);
      await fetchPlaylists();
      return id;
    });
    return result;
  }

  Future<bool> updatePlaylist(String id, String name, String description, bool isPublic) async {
    if (_token == null) {
      _errorMessage = 'Authentication required';
      notifyListeners();
      return false;
    }
    
    if (id.isEmpty || id == 'null') {
      _errorMessage = 'Invalid playlist ID: $id';
      notifyListeners();
      print('AppProvider: Invalid playlist ID for update: $id');
      return false;
    }
    
    final result = await _execute(() async {
      print('AppProvider: Updating playlist ID: $id');
      await _api.updatePlaylist(id, name, description, isPublic, _token!);
      await fetchPlaylists();
      return true;
    });
    return result ?? false;
  }

  Future<bool> deletePlaylist(String id) async {
    if (_token == null) {
      _errorMessage = 'Authentication required';
      notifyListeners();
      return false;
    }
    
    if (id.isEmpty || id == 'null') {
      _errorMessage = 'Invalid playlist ID: $id';
      notifyListeners();
      print('AppProvider: Invalid playlist ID for deletion: $id');
      return false;
    }
    
    final result = await _execute(() async {
      print('AppProvider: Deleting playlist ID: $id');
      await _api.deletePlaylist(id, _token!);
      await fetchPlaylists();
      return true;
    });
    return result ?? false;
  }

  Future<void> searchTracks(String query, {bool deezer = true}) async {
    await _execute(() async {
      _searchResults = await _api.searchTracks(query, deezer: deezer);
    });
  }

  Future<Track?> getDeezerTrack(String trackId) async {
    return await _execute(() => _api.getDeezerTrack(trackId));
  }

  Future<bool> addTrackFromDeezer(String trackId) async {
    if (_token == null) return false;
    
    final result = await _execute(() async {
      await _api.addTrackFromDeezer(trackId, _token!);
      return true;
    });
    return result ?? false;
  }

  Future<bool> addTrackToPlaylist(String playlistId, String trackId) async {
    if (_token == null) {
      _errorMessage = 'Authentication required';
      notifyListeners();
      return false;
    }
    
    if (playlistId.isEmpty || playlistId == 'null') {
      _errorMessage = 'Invalid playlist ID: $playlistId';
      notifyListeners();
      print('AppProvider: Invalid playlist ID for adding track: $playlistId');
      return false;
    }
    
    if (trackId.isEmpty || trackId == 'null') {
      _errorMessage = 'Invalid track ID: $trackId';
      notifyListeners();
      print('AppProvider: Invalid track ID: $trackId');
      return false;
    }
    
    final result = await _execute(() async {
      print('AppProvider: Adding track $trackId to playlist $playlistId');
      await _api.addTrackToPlaylist(playlistId, trackId, _token!);
      await fetchPlaylists();
      return true;
    });
    return result ?? false;
  }

  Future<void> fetchFriends() async {
    if (_token == null) return;
    
    await _execute(() async {
      _friends = await _api.getFriends(_token!);
    });
  }

  Future<String?> sendFriendRequest(int userId) async {
    if (_token == null) return null;
    
    return await _execute(() => _api.sendFriendRequest(userId, _token!));
  }

  Future<void> _saveUserData() async {
  }

  void _clearUserData() {
    _token = null;
    _userId = null;
    _username = null;
    _isLoggedIn = false;
    _playlists.clear();
    _searchResults.clear();
    _friends.clear();
    _pendingRequests.clear();
  }
}
