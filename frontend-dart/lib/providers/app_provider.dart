// lib/providers/app_provider.dart - Updated version
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
  bool _isRetrying = false;
  bool _hasConnectionError = false;

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
  bool get isRetrying => _isRetrying;
  bool get hasConnectionError => _hasConnectionError;

  Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Token $_token',
  };

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
      if (_isRetrying && _token != null) {
        fetchPlaylists();
      }
    });
  }

  Future<bool> login(String username, String password) async {
    final result = await _execute(() async {
      final authResult = await _api.login(username, password);
      _token = authResult.token;
      _userId = authResult.user.id;
      _username = authResult.user.username;
      _isLoggedIn = true;
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
      return true;
    });
    return result ?? false;
  }

  Future<void> logout() async {
    _clearUserData();
    notifyListeners();
  }

  Future<void> fetchPlaylists({bool publicOnly = false}) async {
    if (_token == null) return;
    
    await _execute(() async {
      _playlists = await _api.getPlaylists(token: _token!, publicOnly: publicOnly);
    });
  }

  Future<Playlist?> getPlaylistDetails(String id) async {
    if (_token == null || id.isEmpty || id == 'null') return null;
    
    return await _execute(() => _api.getPlaylist(id, _token!));
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
    if (_token == null || playlistId.isEmpty || playlistId == 'null' || 
        trackId.isEmpty || trackId == 'null') return false;
    
    final result = await _execute(() async {
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

  Future<void> fetchPendingRequests() async {
    if (_token == null) return;
    
    await _execute(() async {
      _pendingRequests = [
        {
          'id': '1',
          'from_user': 123,
          'to_user': int.parse(_userId ?? '0'),
          'status': 'pending',
        }
      ];
    });
  }

  Future<String?> acceptFriendRequest(int friendshipId) async {
    if (_token == null) return null;
    
    return await _execute(() async {
      await Future.delayed(const Duration(milliseconds: 500));
      return 'Friend request accepted';
    });
  }

  Future<String?> rejectFriendRequest(int friendshipId) async {
    if (_token == null) return null;
    
    return await _execute(() async {
      await Future.delayed(const Duration(milliseconds: 500));
      return 'Friend request rejected';
    });
  }

  Future<void> removeFriend(int friendId) async {
    if (_token == null) return;
    
    await _execute(() async {
      await Future.delayed(const Duration(milliseconds: 500));
      _friends.remove(friendId);
    });
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
    _errorMessage = null;
    _hasConnectionError = false;
    _isRetrying = false;
  }
}
