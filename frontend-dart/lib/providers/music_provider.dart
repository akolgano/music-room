// providers/music_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

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

  MusicProvider() {
    _apiBaseUrl = dotenv.env['API_BASE_URL'];
  }

  Future<void> fetchPublicEvents() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/events/public_events/'),
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> eventsData = responseData['events'];
        
        _events = eventsData.map((event) => Event.fromJson(event)).toList();
        notifyListeners();
      } else {
        throw Exception('Failed to load public events');
      }
    } catch (error) {
      print('Error fetching public events: $error');
      rethrow;
    }
  }

  Future<void> fetchPublicPlaylists() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/playlists/public_playlists/'),
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> playlistsData = responseData['playlists'];
        
        _playlists = playlistsData.map((playlist) => Playlist.fromJson(playlist)).toList();
        notifyListeners();
      } else {
        throw Exception('Failed to load public playlists');
      }
    } catch (error) {
      print('Error fetching public playlists: $error');
      rethrow;
    }
  }
  
  Future<void> fetchUserPlaylists(String token) async {
    try {
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
        notifyListeners();
      } else {
        throw Exception('Failed to load user playlists');
      }
    } catch (error) {
      print('Error fetching user playlists: $error');
      rethrow;
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
        // Refresh playlists after adding a track
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
  
  Future<void> searchTracks(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/tracks/search/?query=$query'),
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> tracksData = responseData['tracks'];
        
        _searchResults = tracksData.map((track) => Track.fromJson(track)).toList();
        notifyListeners();
      } else {
        throw Exception('Failed to search tracks');
      }
    } catch (error) {
      print('Error searching tracks: $error');
      rethrow;
    }
  }
  
  Future<void> searchDeezerTracks(String query) async {
    try {
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
          );
        }).toList();
        notifyListeners();
      } else {
        throw Exception('Failed to search Deezer tracks');
      }
    } catch (error) {
      print('Error searching Deezer tracks: $error');
      rethrow;
    }
  }
  
  Future<void> addTrackFromDeezer(String trackId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/tracks/add_from_deezer/$trackId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );
      
      if (response.statusCode != 201 && response.statusCode != 200) {
        final responseData = json.decode(response.body);
        throw Exception(responseData['error'] ?? 'Failed to add track from Deezer');
      }
    } catch (error) {
      print('Error adding track from Deezer: $error');
      rethrow;
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
}
