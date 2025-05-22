// lib/providers/music_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class MusicProvider with ChangeNotifier {
  List<Playlist> _playlists = [];
  List<Track> _searchResults = [];
  List<Event> _events = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isRetrying = false;
  final String _apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
  
  List<Playlist> get playlists => [..._playlists];
  List<Track> get searchResults => [..._searchResults];
  List<Event> get events => [..._events];
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isRetrying => _isRetrying;
  bool get hasConnectionError => _errorMessage != null;

  Future<T?> _apiCall<T>(Future<T> Function() call) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final result = await call();
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      _startRetry();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startRetry() {
    _isRetrying = true;
    notifyListeners();
    Future.delayed(const Duration(seconds: 3), () {
      _isRetrying = false;
      notifyListeners();
    });
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchPublicPlaylists() async {
    await _apiCall(() async {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/playlists/public_playlists/')
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _playlists = (data['playlists'] as List)
            .map((p) => Playlist.fromJson(p))
            .toList();
        return _playlists;
      }
      throw Exception('Failed to load public playlists');
    });
  }

  Future<void> fetchUserPlaylists(String token) async {
    await _apiCall(() async {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/playlists/saved_playlists/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _playlists = (data['playlists'] as List)
            .map((p) => Playlist.fromJson(p))
            .toList();
        return _playlists;
      }
      throw Exception('Failed to load user playlists');
    });
  }

  Future<String> createNewPlaylist(String name, String description, bool isPublic, String token) async {
    final result = await _apiCall(() async {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/playlists/playlists'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
        body: json.encode({
          'name': name,
          'description': description,
          'public': isPublic,
        }),
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['playlist_id'].toString();
      }
      throw Exception('Failed to create playlist');
    });
    return result ?? '';
  }

  Future<void> updatePlaylist(String playlistId, String name, String description, bool isPublic, String token) async {
    await _apiCall(() async {
      final response = await http.put(
        Uri.parse('$_apiBaseUrl/playlists/playlists/$playlistId'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
        body: json.encode({
          'name': name,
          'description': description,
          'public': isPublic,
        }),
      );
      
      if (response.statusCode == 200) {
        await fetchUserPlaylists(token);
        return true;
      }
      throw Exception('Failed to update playlist');
    });
  }

  Future<void> deletePlaylist(String playlistId, String token) async {
    await _apiCall(() async {
      final response = await http.delete(
        Uri.parse('$_apiBaseUrl/playlists/playlists/$playlistId'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
      );
      
      if ([200, 204].contains(response.statusCode)) {
        await fetchUserPlaylists(token);
        return true;
      }
      throw Exception('Failed to delete playlist');
    });
  }

  Future<Playlist> getPlaylistDetails(String playlistId, String token) async {
    final result = await _apiCall(() async {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/playlists/playlists/$playlistId'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Playlist.fromJson(data['playlist'][0]);
      }
      throw Exception('Failed to load playlist details');
    });
    
    return result ?? Playlist(
      id: '0', name: 'Unknown', description: '', 
      isPublic: false, creator: '', tracks: []
    );
  }

  Future<List<Track>> searchTracks(String query) async {
    final result = await _apiCall(() async {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/tracks/search/?query=$query')
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _searchResults = (data['tracks'] as List)
            .map((t) => Track.fromJson(t))
            .toList();
        return _searchResults;
      }
      throw Exception('Failed to search tracks');
    });
    return result ?? [];
  }

  Future<void> searchDeezerTracks(String query) async {
    await _apiCall(() async {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/deezer/search/?q=$query')
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _searchResults = (data['data'] as List)
            .map((t) => Track.fromJson(t))
            .toList();
        return _searchResults;
      }
      throw Exception('Failed to search Deezer tracks');
    });
  }

  Future<Track?> getDeezerTrack(String trackId) async {
    return await _apiCall(() async {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/deezer/track/$trackId/')
      );
      
      if (response.statusCode == 200) {
        return Track.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to get Deezer track');
    });
  }

  Future<String?> getDeezerTrackPreviewUrl(String trackId) async {
    final track = await getDeezerTrack(trackId);
    return track?.previewUrl;
  }

  Future<Track?> addTrackFromDeezer(String trackId, String token) async {
    final result = await _apiCall(() async {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/tracks/add_from_deezer/$trackId/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
      );
      
      if ([200, 201].contains(response.statusCode)) {
        return Track.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to add track from Deezer');
    });
    
    return result;
  }

  Future<void> addTrackToPlaylist(String playlistId, String trackId, String token) async {
    await _apiCall(() async {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/playlists/to_playlist/$playlistId/add_track/$trackId/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
      );
      
      if (response.statusCode == 200) {
        await fetchUserPlaylists(token);
        return true;
      }
      throw Exception('Failed to add track to playlist');
    });
  }

  Future<String> saveSharedPlaylist(String name, String description, bool isPublic, List<String> trackIds, String token) async {
    final result = await _apiCall(() async {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/playlists/save_playlist/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
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
      }
      throw Exception('Failed to save shared playlist');
    });
    return result ?? '';
  }

  Future<void> addTracksToPlaylist(String playlistId, List<String> trackIds, String token) async {
    await _apiCall(() async {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/playlists/playlists/$playlistId/tracks'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
        body: json.encode({'track_ids': trackIds}),
      );
      
      if (response.statusCode == 200) {
        await fetchUserPlaylists(token);
        return true;
      }
      throw Exception('Failed to add tracks to playlist');
    });
  }

  Future<String> createPlaylist(String name, String description, bool isPublic, String token) async {
    return await createNewPlaylist(name, description, isPublic, token);
  }
}
