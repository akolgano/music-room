// lib/providers/enhanced_music_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/models.dart';
import '../utils/enhanced_api_methods.dart';

class EnhancedMusicProvider with ChangeNotifier, EnhancedApiMixin {
  final String _apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
  
  List<Playlist> _playlists = [];
  List<Track> _searchResults = [];
  List<Event> _events = [];

  List<Playlist> get playlists => [..._playlists];
  List<Track> get searchResults => [..._searchResults];
  List<Event> get events => [..._events];

  Map<String, String> _getHeaders([String? token]) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Token $token',
  };

  Future<void> fetchPublicPlaylists() async {
    await apiCall(() async {
      final response = await enhancedHttpRequest(
        method: 'GET',
        url: '$_apiBaseUrl/playlists/public_playlists/',
      );
      
      final data = json.decode(response.body);
      _playlists = (data['playlists'] as List)
          .map((p) => Playlist.fromJson(p))
          .toList();
    }, debugContext: 'fetchPublicPlaylists');
  }

  Future<void> fetchUserPlaylists(String token) async {
    await apiCall(() async {
      final response = await enhancedHttpRequest(
        method: 'GET',
        url: '$_apiBaseUrl/playlists/saved_playlists/',
        headers: _getHeaders(token),
      );
      
      final data = json.decode(response.body);
      _playlists = (data['playlists'] as List)
          .map((p) => Playlist.fromJson(p))
          .toList();
    }, debugContext: 'fetchUserPlaylists');
  }

  Future<String?> createPlaylist(
    String name,
    String description,
    bool isPublic,
    String token,
  ) async {
    return await apiCall(() async {
      final response = await enhancedHttpRequest(
        method: 'POST',
        url: '$_apiBaseUrl/playlists/playlists',
        headers: _getHeaders(token),
        body: json.encode({
          'name': name,
          'description': description,
          'public': isPublic,
        }),
      );
      
      final data = json.decode(response.body);
      await fetchUserPlaylists(token);
      return data['playlist_id'].toString();
    }, debugContext: 'createPlaylist - name: $name, public: $isPublic');
  }

  Future<bool> updatePlaylist(
    String playlistId,
    String name,
    String description,
    bool isPublic,
    String token,
  ) async {
    final result = await apiCall(() async {
      await enhancedHttpRequest(
        method: 'PUT',
        url: '$_apiBaseUrl/playlists/playlists/$playlistId',
        headers: _getHeaders(token),
        body: json.encode({
          'name': name,
          'description': description,
          'public': isPublic,
        }),
      );
      
      await fetchUserPlaylists(token);
      return true;
    }, debugContext: 'updatePlaylist - ID: $playlistId');
    
    return result ?? false;
  }

  Future<bool> deletePlaylist(String playlistId, String token) async {
    final result = await apiCall(() async {
      await enhancedHttpRequest(
        method: 'DELETE',
        url: '$_apiBaseUrl/playlists/playlists/$playlistId',
        headers: _getHeaders(token),
      );
      
      await fetchUserPlaylists(token);
      return true;
    }, debugContext: 'deletePlaylist - ID: $playlistId');
    
    return result ?? false;
  }

  Future<Playlist?> getPlaylistDetails(String playlistId, String token) async {
    return await apiCall(() async {
      final response = await enhancedHttpRequest(
        method: 'GET',
        url: '$_apiBaseUrl/playlists/playlists/$playlistId',
        headers: _getHeaders(token),
      );
      
      final data = json.decode(response.body);
      return Playlist.fromJson(data['playlist'][0]);
    }, debugContext: 'getPlaylistDetails - ID: $playlistId');
  }

  Future<void> searchTracks(String query, {bool deezer = true}) async {
    await apiCall(() async {
      final endpoint = deezer ? '/deezer/search/' : '/tracks/search/';
      final param = deezer ? 'q' : 'query';
      
      final response = await enhancedHttpRequest(
        method: 'GET',
        url: '$_apiBaseUrl$endpoint?$param=${Uri.encodeQueryComponent(query)}',
      );
      
      final data = json.decode(response.body);
      final tracks = deezer ? data['data'] : data['tracks'];
      _searchResults = (tracks as List)
          .map((t) => Track.fromJson(t))
          .toList();
    }, debugContext: 'searchTracks - query: $query, deezer: $deezer');
  }

  Future<Track?> getDeezerTrack(String trackId) async {
    return await apiCall(() async {
      final response = await enhancedHttpRequest(
        method: 'GET',
        url: '$_apiBaseUrl/deezer/track/$trackId/',
      );
      
      return Track.fromJson(json.decode(response.body));
    }, debugContext: 'getDeezerTrack - ID: $trackId');
  }

  Future<bool> addTrackFromDeezer(String trackId, String token) async {
    final result = await apiCall(() async {
      final response = await enhancedHttpRequest(
        method: 'POST',
        url: '$_apiBaseUrl/tracks/add_from_deezer/$trackId/',
        headers: _getHeaders(token),
      );
      
      return [200, 201].contains(response.statusCode);
    }, debugContext: 'addTrackFromDeezer - ID: $trackId');
    
    return result ?? false;
  }

  Future<bool> addTrackToPlaylist(
    String playlistId,
    String trackId,
    String token,
  ) async {
    final result = await apiCall(() async {
      await enhancedHttpRequest(
        method: 'POST',
        url: '$_apiBaseUrl/playlists/to_playlist/$playlistId/add_track/$trackId/',
        headers: _getHeaders(token),
      );
      
      await fetchUserPlaylists(token);
      return true;
    }, debugContext: 'addTrackToPlaylist - playlist: $playlistId, track: $trackId');
    
    return result ?? false;
  }

  void showDebugInfo(BuildContext context) {
    if (lastErrorDetails != null && lastErrorDetails!.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Debug Information'),
          content: SingleChildScrollView(
            child: Text(
              lastErrorDetails!,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Debug info would be copied to clipboard')),
                );
              },
              child: const Text('Copy'),
            ),
          ],
        ),
      );
    }
  }
}
