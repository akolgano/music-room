// lib/providers/music_provider.dart - ENHANCED VERSION with missing methods
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class MusicProvider with ChangeNotifier {
  final String _apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
  
  List<Playlist> _playlists = [];
  List<Track> _searchResults = [];
  List<Event> _events = []; 
  bool _isLoading = false;
  bool _isRetrying = false; 
  String? _errorMessage;

  List<Playlist> get playlists => [..._playlists];
  List<Track> get searchResults => [..._searchResults];
  List<Event> get events => [..._events]; 
  bool get isLoading => _isLoading;
  bool get isRetrying => _isRetrying; 
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get hasConnectionError => _errorMessage?.contains('Connection') ?? false; 

  Future<T?> _apiCall<T>(Future<T> Function() call) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final result = await call();
      return result;
    } catch (e) {
      _errorMessage = 'Connection error. Please check your internet.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<T?> _apiCallWithRetry<T>(Future<T> Function() call) async {
    _isRetrying = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final result = await call();
      return result;
    } catch (e) {
      _errorMessage = 'Connection error. Please check your internet.';
      return null;
    } finally {
      _isRetrying = false;
      notifyListeners();
    }
  }

  Map<String, String> _getHeaders([String? token]) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Token $token',
  };

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchPublicPlaylists() async {
    await _apiCall(() async {
      final response = await http.get(Uri.parse('$_apiBaseUrl/playlists/public_playlists/'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _playlists = (data['playlists'] as List).map((p) => Playlist.fromJson(p)).toList();
      } else throw Exception('Failed to load playlists');
    });
  }

  Future<void> fetchUserPlaylists(String token) async {
    await _apiCall(() async {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/playlists/saved_playlists/'),
        headers: _getHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _playlists = (data['playlists'] as List).map((p) => Playlist.fromJson(p)).toList();
      } else throw Exception('Failed to load playlists');
    });
  }

  Future<String?> createPlaylist(String name, String description, bool isPublic, String token) async {
    return await _apiCall(() async {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/playlists/playlists'),
        headers: _getHeaders(token),
        body: json.encode({'name': name, 'description': description, 'public': isPublic}),
      );
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        await fetchUserPlaylists(token);
        return data['playlist_id'].toString();
      } else throw Exception('Failed to create playlist');
    });
  }

  Future<String?> createNewPlaylist(String name, String description, bool isPublic, String token) async {
    return await createPlaylist(name, description, isPublic, token);
  }

  Future<bool> updatePlaylist(String playlistId, String name, String description, bool isPublic, String token) async {
    final result = await _apiCall(() async {
      final response = await http.put(
        Uri.parse('$_apiBaseUrl/playlists/playlists/$playlistId'),
        headers: _getHeaders(token),
        body: json.encode({'name': name, 'description': description, 'public': isPublic}),
      );
      if (response.statusCode == 200) {
        await fetchUserPlaylists(token);
        return true;
      } else throw Exception('Failed to update playlist');
    });
    return result ?? false;
  }

  Future<bool> deletePlaylist(String playlistId, String token) async {
    final result = await _apiCall(() async {
      final response = await http.delete(
        Uri.parse('$_apiBaseUrl/playlists/playlists/$playlistId'),
        headers: _getHeaders(token),
      );
      if ([200, 204].contains(response.statusCode)) {
        await fetchUserPlaylists(token);
        return true;
      } else throw Exception('Failed to delete playlist');
    });
    return result ?? false;
  }

  Future<Playlist?> getPlaylistDetails(String playlistId, String token) async {
    return await _apiCall(() async {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/playlists/playlists/$playlistId'),
        headers: _getHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Playlist.fromJson(data['playlist'][0]);
      } else throw Exception('Failed to load playlist');
    });
  }

  Future<void> searchTracks(String query, {bool deezer = true}) async {
    await _apiCall(() async {
      final endpoint = deezer ? '/deezer/search/' : '/tracks/search/';
      final param = deezer ? 'q' : 'query';
      final response = await http.get(Uri.parse('$_apiBaseUrl$endpoint?$param=$query'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tracks = deezer ? data['data'] : data['tracks'];
        _searchResults = (tracks as List).map((t) => Track.fromJson(t)).toList();
      } else throw Exception('Failed to search tracks');
    });
  }

  Future<void> searchDeezerTracks(String query) async {
    await searchTracks(query, deezer: true);
  }

  Future<Track?> getDeezerTrack(String trackId) async {
    return await _apiCall(() async {
      final response = await http.get(Uri.parse('$_apiBaseUrl/deezer/track/$trackId/'));
      if (response.statusCode == 200) {
        return Track.fromJson(json.decode(response.body));
      } else throw Exception('Failed to get track');
    });
  }

  Future<String?> getDeezerTrackPreviewUrl(String trackId) async {
    final track = await getDeezerTrack(trackId);
    return track?.previewUrl;
  }

  Future<bool> addTrackFromDeezer(String trackId, String token) async {
    final result = await _apiCall(() async {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/tracks/add_from_deezer/$trackId/'),
        headers: _getHeaders(token),
      );
      return [200, 201].contains(response.statusCode);
    });
    return result ?? false;
  }

  Future<bool> addTrackToPlaylist(String playlistId, String trackId, String token) async {
    final result = await _apiCall(() async {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/playlists/to_playlist/$playlistId/add_track/$trackId/'),
        headers: _getHeaders(token),
      );
      if (response.statusCode == 200) {
        await fetchUserPlaylists(token);
        return true;
      } else throw Exception('Failed to add track');
    });
    return result ?? false;
  }

  Future<bool> addTracksToPlaylist(String playlistId, List<String> trackIds, String token) async {
    final result = await _apiCall(() async {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/playlists/playlists/$playlistId/tracks'),
        headers: _getHeaders(token),
        body: json.encode({'track_ids': trackIds}),
      );
      if (response.statusCode == 200) {
        await fetchUserPlaylists(token);
        return true;
      } else throw Exception('Failed to add tracks');
    });
    return result ?? false;
  }

  Future<String?> saveSharedPlaylist(
    String name,
    String description,
    bool isPublic,
    List<String> trackIds,
    String token,
  ) async {
    return await _apiCall(() async {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/playlists/save_playlist/'),
        headers: _getHeaders(token),
        body: json.encode({
          'name': name,
          'description': description,
          'public': isPublic,
          'track_ids': trackIds,
        }),
      );
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        await fetchUserPlaylists(token);
        return data['playlist_id'].toString();
      } else throw Exception('Failed to save playlist');
    });
  }

  Future<void> fetchEvents() async {
    await _apiCall(() async {
      _events = [
        Event(
          id: '1',
          name: 'Sample Music Event',
          description: 'A demo event for music voting',
          isPublic: true,
          creator: 'Demo User',
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 2)),
          location: 'Virtual',
        ),
      ];
    });
  }

  Future<String?> createEvent(String name, String description, bool isPublic, String token) async {
    return await _apiCall(() async {
      final newEvent = Event(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        description: description,
        isPublic: isPublic,
        creator: 'Current User',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 2)),
      );
      _events.add(newEvent);
      return newEvent.id;
    });
  }
}
