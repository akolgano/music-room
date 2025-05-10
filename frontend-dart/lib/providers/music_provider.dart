// lib/providers/music_provider.dart - Fixed version
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'base_provider.dart';
import '../models/playlist.dart';
import '../models/track.dart';
import '../models/event.dart';

class MusicProvider with ChangeNotifier, BaseProviderMixin {
  List<Playlist> _playlists = [];
  List<Track> _searchResults = [];
  String? _apiBaseUrl;
  List<Event> _events = [];
  
  List<Playlist> get playlists => [..._playlists];
  List<Track> get searchResults => [..._searchResults];
  List<Event> get events => [..._events];

  MusicProvider() {
    // _apiBaseUrl = 'http://localhost:8000';
    _apiBaseUrl = dotenv.env['API_BASE_URL'];
  }

  Future<void> fetchPublicPlaylists() async {
    await apiCall(() async {
      final response = await http.get(Uri.parse('$_apiBaseUrl/playlists/public_playlists/'));
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> playlistsData = responseData['playlists'];
        _playlists = playlistsData.map((playlist) => Playlist.fromJson(playlist)).toList();
        return _playlists;
      } else {
        throw Exception('Failed to load public playlists');
      }
    });
  }

  Future<void> fetchUserPlaylists(String token) async {
    await apiCall(() async {
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
        return _playlists;
      } else {
        throw Exception('Failed to load user playlists');
      }
    });
  }

  Future<String> saveSharedPlaylist(String name, String description, bool isPublic, 
      List<String> trackIds, String token) async {
    final result = await apiCall(() async {
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
        return responseData['playlist_id'].toString();
      } else {
        final responseData = json.decode(response.body);
        throw Exception(responseData['error'] ?? 'Failed to save shared playlist');
      }
    });
    
    return result ?? ''; 
  }

  Future<void> updatePlaylist(String playlistId, String name, String description, bool isPublic, String token) async {
    await apiCall(() async {
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
        return true;
      } else {
        final responseData = json.decode(response.body);
        throw Exception(responseData['error'] ?? 'Failed to update playlist');
      }
    });
  }

  Future<void> deletePlaylist(String playlistId, String token) async {
    await apiCall(() async {
      final response = await http.delete(
        Uri.parse('$_apiBaseUrl/playlists/playlists/$playlistId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );
      
      if (response.statusCode == 204 || response.statusCode == 200) {
        await fetchUserPlaylists(token);
        return true;
      } else {
        final responseData = json.decode(response.body);
        throw Exception(responseData['error'] ?? 'Failed to delete playlist');
      }
    });
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
    final result = await apiCall(() async {
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
        throw Exception(responseData['error'] ?? 'Failed to create playlist');
      }
    });
    
    return result ?? ''; 
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
    await apiCall(() async {
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
        return true;
      } else {
        final responseData = json.decode(response.body);
        throw Exception(responseData['error'] ?? 'Failed to add tracks to playlist');
      }
    });
  }

  Future<List<Track>> searchTracks(String query) async {
    final result = await apiCall(() async {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/tracks/search/?query=$query'),
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> tracksData = responseData['tracks'];
        
        _searchResults = tracksData.map((track) => Track.fromJson(track)).toList();
        return _searchResults;
      } else {
        throw Exception('Failed to search tracks');
      }
    });
    
    return result ?? []; 
  }

  Future<Track> addTrackFromDeezer(String trackId, String token) async {
    final result = await apiCall(() async {
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
        throw Exception(responseData['error'] ?? 'Failed to add track from Deezer');
      }
    });
    
    
    return result ?? Track(
      id: '0',
      name: 'Unknown Track',
      artist: 'Unknown Artist',
      album: 'Unknown Album',
      url: '',
    );
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
    final result = await apiCall(() async {
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
        throw Exception('Failed to load playlist details');
      }
    });
    
    return result ?? Playlist(
      id: '0',
      name: 'Unknown Playlist',
      description: '',
      isPublic: false,
      creator: '',
      tracks: [],
    );
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
    await apiCall(() async {
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
        return _searchResults;
      } else {
        throw Exception('Failed to search Deezer tracks');
      }
    });
  }
}
