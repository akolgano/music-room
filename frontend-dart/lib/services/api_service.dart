// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/models.dart';

class ApiService {
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';

  Map<String, String> _getHeaders([String? token]) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Token $token',
  };

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/login/'),
      headers: _getHeaders(),
      body: json.encode({'username': username, 'password': password}),
    );
    
    if (response.statusCode != 200) {
      final error = json.decode(response.body);
      throw error['detail'] ?? 'Login failed';
    }
    
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> signup(String username, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/signup/'),
      headers: _getHeaders(),
      body: json.encode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );
    
    if (response.statusCode != 201) {
      final error = json.decode(response.body);
      throw error['detail'] ?? 'Signup failed';
    }
    
    return json.decode(response.body);
  }

  Future<List<Playlist>> getPlaylists(String? token, {bool publicOnly = false}) async {
    final endpoint = publicOnly ? '/playlists/public_playlists/' : '/playlists/saved_playlists/';
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _getHeaders(token),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['playlists'] as List)
          .map((p) => Playlist.fromJson(p))
          .toList();
    }
    throw 'Failed to load playlists';
  }

  Future<List<Track>> searchTracks(String query, {bool deezer = false}) async {
    final endpoint = deezer ? '/deezer/search/' : '/tracks/search/';
    final param = deezer ? 'q' : 'query';
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint?$param=$query'),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final tracks = deezer ? data['data'] : data['tracks'];
      return (tracks as List).map((t) => Track.fromJson(t)).toList();
    }
    throw 'Failed to search tracks';
  }

  Future<Track?> getDeezerTrack(String trackId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/deezer/track/$trackId/'),
    );
    
    if (response.statusCode == 200) {
      return Track.fromJson(json.decode(response.body));
    }
    return null;
  }
}
