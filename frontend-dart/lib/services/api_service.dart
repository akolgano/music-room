// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/models.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String _baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
  
  Map<String, String> _getHeaders([String? token]) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Token $token',
  };

  Future<T> _handleRequest<T>(
    Future<http.Response> Function() request,
    T Function(Map<String, dynamic>) parser,
  ) async {
    try {
      final response = await request();
      
      if (response.statusCode >= 400) {
        String errorMessage;
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['error'] ?? errorData['detail'] ?? 'Request failed: ${response.statusCode}';
        } catch (e) {
          errorMessage = 'Request failed: ${response.statusCode}';
        }
        throw ApiException(errorMessage);
      }
      
      final data = json.decode(response.body);
      return parser(data);
    } on SocketException {
      throw ApiException('Connection error. Check your internet.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<AuthResult> login(String username, String password) async {
    return _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/users/login/'),
        headers: _getHeaders(),
        body: json.encode({'username': username, 'password': password}),
      ),
      (data) => AuthResult.fromJson(data),
    );
  }

  Future<AuthResult> signup(String username, String email, String password) async {
    return _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/users/signup/'),
        headers: _getHeaders(),
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
        }),
      ),
      (data) => AuthResult.fromJson(data),
    );
  }

  Future<List<Playlist>> getPlaylists({required String token, bool publicOnly = false}) async {
    final endpoint = publicOnly ? '/playlists/public_playlists/' : '/playlists/saved_playlists/';
    return _handleRequest(
      () => http.get(Uri.parse('$_baseUrl$endpoint'), headers: _getHeaders(token)),
      (data) => (data['playlists'] as List).map((p) => Playlist.fromJson(p)).toList(),
    );
  }

  Future<Playlist> getPlaylist(String id, String token) async {
    if (id.isEmpty || id == 'null') {
      throw ApiException('Invalid playlist ID: $id');
    }
    
    print('API: Getting playlist with ID: $id');
    
    return _handleRequest(
      () => http.get(Uri.parse('$_baseUrl/playlists/playlists/$id'), headers: _getHeaders(token)),
      (data) => Playlist.fromJson(data['playlist'][0]),
    );
  }

  Future<String> createPlaylist(String name, String description, bool isPublic, String token) async {
    return _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/playlists/playlists'),
        headers: _getHeaders(token),
        body: json.encode({'name': name, 'description': description, 'public': isPublic}),
      ),
      (data) => data['playlist_id'].toString(),
    );
  }

  Future<void> updatePlaylist(String id, String name, String description, bool isPublic, String token) async {
    if (id.isEmpty || id == 'null') {
      throw ApiException('Invalid playlist ID: $id');
    }
    
    await _handleRequest(
      () => http.put(
        Uri.parse('$_baseUrl/playlists/playlists/$id'),
        headers: _getHeaders(token),
        body: json.encode({'name': name, 'description': description, 'public': isPublic}),
      ),
      (_) => null,
    );
  }

  Future<void> deletePlaylist(String id, String token) async {
    if (id.isEmpty || id == 'null') {
      throw ApiException('Invalid playlist ID: $id');
    }
    
    await _handleRequest(
      () => http.delete(Uri.parse('$_baseUrl/playlists/playlists/$id'), headers: _getHeaders(token)),
      (_) => null,
    );
  }

  Future<List<Track>> searchTracks(String query, {bool deezer = true}) async {
    final endpoint = deezer ? '/deezer/search/' : '/tracks/search/';
    final param = deezer ? 'q' : 'query';
    return _handleRequest(
      () => http.get(Uri.parse('$_baseUrl$endpoint?$param=${Uri.encodeQueryComponent(query)}')),
      (data) {
        final tracks = deezer ? data['data'] : data['tracks'];
        return (tracks as List).map((t) => Track.fromJson(t)).toList();
      },
    );
  }

  Future<Track> getDeezerTrack(String trackId) async {
    return _handleRequest(
      () => http.get(Uri.parse('$_baseUrl/deezer/track/$trackId/')),
      (data) => Track.fromJson(data),
    );
  }

  Future<void> addTrackFromDeezer(String trackId, String token) async {
    await _handleRequest(
      () => http.post(Uri.parse('$_baseUrl/tracks/add_from_deezer/$trackId/'), headers: _getHeaders(token)),
      (_) => null,
    );
  }

  Future<void> addTrackToPlaylist(String playlistId, String trackId, String token) async {
    if (playlistId.isEmpty || playlistId == 'null') {
      throw ApiException('Invalid playlist ID: $playlistId');
    }
    if (trackId.isEmpty || trackId == 'null') {
      throw ApiException('Invalid track ID: $trackId');
    }
    
    await _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/playlists/to_playlist/$playlistId/add_track/$trackId/'),
        headers: _getHeaders(token),
      ),
      (_) => null,
    );
  }

  Future<List<int>> getFriends(String token) async {
    return _handleRequest(
      () => http.get(Uri.parse('$_baseUrl/users/get_friends/'), headers: _getHeaders(token)),
      (data) => List<int>.from(data['friends']),
    );
  }

  Future<String> sendFriendRequest(int userId, String token) async {
    return _handleRequest(
      () => http.post(Uri.parse('$_baseUrl/users/send_friend_request/$userId/'), headers: _getHeaders(token)),
      (data) => data['message'],
    );
  }

  Future<AuthResult> facebookLogin(String fbAccessToken) async {
    return _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/auth/facebook/login/'),
        headers: _getHeaders(),
        body: json.encode({'fbAccessToken': fbAccessToken,}),
      ),
      (data) => AuthResult.fromJson(data),
    );
  }

  Future<AuthResult> googleLoginApp(String idToken) async {
    return _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/auth/google/login_app/'),
        headers: _getHeaders(),
        body: json.encode({'idToken': idToken}),
      ),
      (data) => AuthResult.fromJson(data),
    );
  }

  Future<AuthResult> googleLoginWeb(String idToken) async {
  return _handleRequest(
    () => http.post(
      Uri.parse('$_baseUrl/auth/google/login_web/'),
      headers: _getHeaders(),
      body: json.encode({'idToken': idToken}),
    ),
    (data) => AuthResult.fromJson(data),
  );
  }

}

class AuthResult {
  final String token;
  final User user;
  
  AuthResult({required this.token, required this.user});
  
  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
    token: json['token'],
    user: User.fromJson(json['user']),
  );
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}




