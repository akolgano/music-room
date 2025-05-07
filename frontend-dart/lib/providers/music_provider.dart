// providers/music_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import '../models/playlist.dart';
import '../models/track.dart';
import '../models/event.dart';

class MusicProvider with ChangeNotifier {
  List<Playlist> _playlists = [];
  List<Track> _searchResults = [];
  String? _apiBaseUrl;
  
  List<Playlist> get playlists => [..._playlists];
  List<Track> get searchResults => [..._searchResults];

  List<Event> _events = [];
  List<Event> get events => [..._events];

  bool _isLoading = false;
  String? _errorMessage;
  bool _hasConnectionError = false;

  bool _isRetrying = false;
  int _retryCount = 0;
  int _maxRetries = 3;
  int _retryDelaySeconds = 3;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasConnectionError => _hasConnectionError;
  bool get isRetrying => _isRetrying;

  MusicProvider() {
    _apiBaseUrl = dotenv.env['API_BASE_URL'];
  }

  void resetError() {
    _errorMessage = null;
    _hasConnectionError = false;
    notifyListeners();
  }

  Future<void> _autoRetry(Function apiCall) async {
    if (_retryCount >= _maxRetries) {
      _isRetrying = false;
      notifyListeners();
      return;
    }

    _isRetrying = true;
    _retryCount++;
    notifyListeners();
    
    await Future.delayed(Duration(seconds: _retryDelaySeconds));
    
    try {
      await apiCall();
      _isRetrying = false;
      _retryCount = 0;
      _errorMessage = null;
      _hasConnectionError = false;
    } catch (error) {
      if (_retryCount < _maxRetries) {
        _autoRetry(apiCall);
      } else {
        _isRetrying = false;
        _errorMessage = 'Unable to connect after $_maxRetries attempts. Please check your connection and try again manually.';
        _hasConnectionError = true;
      }
    }
    
    notifyListeners();
  }

  Future<void> fetchPublicPlaylists() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _hasConnectionError = false;
      _isRetrying = false;
      
      Future.microtask(() => notifyListeners());
      
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/playlists/public_playlists/'),
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> playlistsData = responseData['playlists'];
        
        _playlists = playlistsData.map((playlist) => Playlist.fromJson(playlist)).toList();
        _retryCount = 0;
      } else {
        _errorMessage = 'Failed to load public playlists';
        _hasConnectionError = true;
        throw Exception(_errorMessage);
      }
    } catch (error) {
      _errorMessage = 'Unable to connect to server. Please check your internet connection.';
      _hasConnectionError = true;
      print('Error fetching public playlists: $error');
      
      if (!_isRetrying) {
        _autoRetry(() => fetchPublicPlaylists());
      }
    } finally {
      _isLoading = false;
      Future.microtask(() => notifyListeners());
    }
  }

  Future<void> fetchUserPlaylists(String token) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _hasConnectionError = false;
      _isRetrying = false;
      notifyListeners();
      
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/playlists/saved_playlists/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> playlistsData = responseData['playlists'];
        
        _playlists = playlistsData.map((playlist) => Playlist.fromJson(playlist)).toList();
        _retryCount = 0;
      } else {
        _errorMessage = 'Failed to load user playlists';
        _hasConnectionError = true;
        throw Exception(_errorMessage);
      }
    } catch (error) {
      _errorMessage = 'Unable to connect to server. Please check your internet connection.';
      _hasConnectionError = true;
      print('Error fetching user playlists: $error');
      
      if (!_isRetrying) {
        _autoRetry(() => fetchUserPlaylists(token));
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> saveSharedPlaylist(String name, String description, bool isPublic, 
      List<String> trackIds, String token) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _hasConnectionError = false;
      _isRetrying = false;
      notifyListeners();
      
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/playlists/save_playlist/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: json.encode({
          'name': name,
          'description': description,
          'public': isPublic,
          'track_ids': trackIds,
        }),
      );
      
      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        await fetchUserPlaylists(token);
        _retryCount = 0;
        return responseData['playlist_id'].toString();
      } else {
        final responseData = json.decode(response.body);
        _errorMessage = responseData['error'] ?? 'Failed to save shared playlist';
        _hasConnectionError = true;
        throw Exception(_errorMessage);
      }
    } catch (error) {
      _errorMessage = 'Unable to connect to server. Please check your internet connection.';
      _hasConnectionError = true;
      print('Error saving shared playlist: $error');
      
      if (!_isRetrying) {
        _autoRetry(() => saveSharedPlaylist(name, description, isPublic, trackIds, token));
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePlaylist(String playlistId, String name, String description, bool isPublic, String token) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _hasConnectionError = false;
      notifyListeners();
      
      final response = await http.put(
        Uri.parse('$_apiBaseUrl/playlists/playlists/$playlistId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: json.encode({
          'name': name,
          'description': description,
          'public': isPublic,
        }),
      );
      
      if (response.statusCode == 200) {
        await fetchUserPlaylists(token);
      } else {
        final responseData = json.decode(response.body);
        _errorMessage = responseData['error'] ?? 'Failed to update playlist';
        _hasConnectionError = true;
        throw Exception(_errorMessage);
      }
    } catch (error) {
      _errorMessage = 'Unable to connect to server. Please check your internet connection.';
      _hasConnectionError = true;
      print('Error updating playlist: $error');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletePlaylist(String playlistId, String token) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _hasConnectionError = false;
      notifyListeners();
      
      final response = await http.delete(
        Uri.parse('$_apiBaseUrl/playlists/playlists/$playlistId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );
      
      if (response.statusCode == 204 || response.statusCode == 200) {
        await fetchUserPlaylists(token);
      } else {
        final responseData = json.decode(response.body);
        _errorMessage = responseData['error'] ?? 'Failed to delete playlist';
        _hasConnectionError = true;
        throw Exception(_errorMessage);
      }
    } catch (error) {
      _errorMessage = 'Unable to connect to server. Please check your internet connection.';
      _hasConnectionError = true;
      print('Error deleting playlist: $error');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createPlaylist(String name, String description, bool isPublic, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/playlists/playlists'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: json.encode({
          'name': name,
          'description': description,
          'public': isPublic,
        }),
      );
      
      if (response.statusCode == 201) {
        await fetchUserPlaylists(token);
      } else {
        final responseData = json.decode(response.body);
        throw Exception(responseData['error'] ?? 'Failed to create playlist');
      }
    } catch (error) {
      print('Error creating playlist: $error');
      rethrow;
    }
  }

  Future<String> createNewPlaylist(String name, String description, bool isPublic, String token) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _hasConnectionError = false;
      notifyListeners();
      
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/playlists/playlists'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: json.encode({
          'name': name,
          'description': description,
          'public': isPublic,
        }),
      );
      
      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return responseData['playlist_id'].toString();
      } else {
        final responseData = json.decode(response.body);
        _errorMessage = responseData['error'] ?? 'Failed to create playlist';
        _hasConnectionError = true;
        throw Exception(_errorMessage);
      }
    } catch (error) {
      _errorMessage = 'Unable to connect to server. Please check your internet connection.';
      _hasConnectionError = true;
      print('Error creating playlist: $error');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTrackToPlaylist(String playlistId, String trackId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/playlists/to_playlist/$playlistId/add_track/$trackId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );
      
      if (response.statusCode == 200) {
        await fetchUserPlaylists(token);
      } else {
        final responseData = json.decode(response.body);
        throw Exception(responseData['error'] ?? 'Failed to add track to playlist');
      }
    } catch (error) {
      print('Error adding track to playlist: $error');
      rethrow;
    }
  }

  Future<void> addTracksToPlaylist(String playlistId, List<String> trackIds, String token) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _hasConnectionError = false;
      notifyListeners();
      
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/playlists/playlists/$playlistId/tracks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: json.encode({
          'track_ids': trackIds,
        }),
      );
      
      if (response.statusCode == 201) {
        await fetchUserPlaylists(token);
      } else {
        final responseData = json.decode(response.body);
        _errorMessage = responseData['error'] ?? 'Failed to add tracks to playlist';
        _hasConnectionError = true;
        throw Exception(_errorMessage);
      }
    } catch (error) {
      _errorMessage = 'Unable to connect to server. Please check your internet connection.';
      _hasConnectionError = true;
      print('Error adding tracks to playlist: $error');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Track>> searchTracks(String query) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _hasConnectionError = false;
      _isRetrying = false;
      notifyListeners();
      
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/tracks/search/?query=$query'),
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> tracksData = responseData['tracks'];
        
        _searchResults = tracksData.map((track) => Track.fromJson(track)).toList();
        _retryCount = 0;
        return _searchResults;
      } else {
        _errorMessage = 'Failed to search tracks';
        _hasConnectionError = true;
        throw Exception(_errorMessage);
      }
    } catch (error) {
      _errorMessage = 'Unable to connect to server. Please check your internet connection.';
      _hasConnectionError = true;
      print('Error searching tracks: $error');
      
      if (!_isRetrying) {
        _autoRetry(() => searchTracks(query));
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Track> addTrackFromDeezer(String trackId, String token) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _hasConnectionError = false;
      notifyListeners();
      
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/tracks/add_from_deezer/$trackId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return Track.fromJson(responseData);
      } else {
        final responseData = json.decode(response.body);
        _errorMessage = responseData['error'] ?? 'Failed to add track from Deezer';
        _hasConnectionError = true;
        throw Exception(_errorMessage);
      }
    } catch (error) {
      _errorMessage = 'Unable to connect to server. Please check your internet connection.';
      _hasConnectionError = true;
      print('Error adding track from Deezer: $error');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<Playlist> getPlaylist(String playlistId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/playlists/playlists/$playlistId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        );
        
        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          return Playlist.fromJson(responseData['playlist'][0]);
        } else {
          final responseData = json.decode(response.body);
          throw Exception(responseData['error'] ?? 'Failed to get playlist');
        }
      } catch (error) {
        print('Error getting playlist: $error');
        rethrow;
      }
    }

    Future<Playlist> getPlaylistDetails(String playlistId, String token) async {
      try {
        _isLoading = true;
        _errorMessage = null;
        _hasConnectionError = false;
        notifyListeners();
        
        final response = await http.get(
          Uri.parse('$_apiBaseUrl/playlists/playlists/$playlistId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $token',
          },
        );
        
        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          final playlistData = responseData['playlist'][0];
          
          return Playlist.fromJson(playlistData);
      } else {
        _errorMessage = 'Failed to load playlist details';
        _hasConnectionError = true;
        throw Exception(_errorMessage);
      }
    } catch (error) {
      _errorMessage = 'Unable to connect to server. Please check your internet connection.';
      _hasConnectionError = true;
      print('Error fetching playlist details: $error');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> getDeezerTrackPreviewUrl(String trackId) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/deezer/track/$trackId/'),
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        return responseData['preview'];
      } else {
        throw Exception('Failed to get Deezer track preview URL');
      }
    } catch (error) {
      print('Error getting Deezer track preview URL: $error');
      rethrow;
    }
  }

  Future<Track?> getDeezerTrack(String trackId) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/deezer/track/$trackId/'),
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        return Track(
          id: responseData['id'].toString(),
          name: responseData['title'],
          artist: responseData['artist']['name'],
          album: responseData['album']['title'],
          url: responseData['link'],
          deezerTrackId: responseData['id'].toString(),
          previewUrl: responseData['preview'],
          imageUrl: responseData['album']['cover_medium'] ?? responseData['album']['cover'],
        );
      } else {
        throw Exception('Failed to get Deezer track details');
      }
    } catch (error) {
      print('Error getting Deezer track: $error');
      rethrow;
    }
  }

  Future<void> searchDeezerTracks(String query) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _hasConnectionError = false;
      _isRetrying = false;
      notifyListeners();
      
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/deezer/search/?q=$query'),
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> tracksData = responseData['data'];
        
        _searchResults = tracksData.map((track) {
          return Track(
            id: track['id'].toString(),
            name: track['title'],
            artist: track['artist']['name'],
            album: track['album']['title'],
            url: track['link'],
            deezerTrackId: track['id'].toString(),
            imageUrl: track['album']['cover_medium'] ?? track['album']['cover'],
          );
        }).toList();
        _retryCount = 0;
      } else {
        _errorMessage = 'Failed to search Deezer tracks';
        _hasConnectionError = true;
        throw Exception(_errorMessage);
      }
    } catch (error) {
      _errorMessage = 'Unable to connect to the Deezer service. Please check your internet connection.';
      _hasConnectionError = true;
      print('Error searching Deezer tracks: $error');
      
      if (!_isRetrying) {
        _autoRetry(() => searchDeezerTracks(query));
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
