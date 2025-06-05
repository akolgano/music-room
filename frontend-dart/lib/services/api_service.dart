// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/models.dart';
import '../core/app_core.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String _baseUrl = dotenv.env['API_BASE_URL'] ?? AppConstants.defaultApiBaseUrl;
  
  Map<String, String> _getHeaders([String? token]) => {
    'Content-Type': AppConstants.contentTypeJson,
    if (token != null) 'Authorization': '${AppConstants.authorizationPrefix} $token',
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
          errorMessage = errorData['error'] ?? errorData['detail'] ?? '${AppStrings.error}: ${response.statusCode}';
        } catch (e) {
          errorMessage = '${AppStrings.error}: ${response.statusCode}';
        }
        throw ApiException(errorMessage);
      }
      final data = json.decode(response.body);
      return parser(data);
    } on SocketException {
      throw ApiException(AppStrings.connectionErrorMessage);
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
        body: json.encode({'username': username, 'password': password})
      ),
      (data) => AuthResult.fromJson(data),
    );
  }

  Future<AuthResult> signup(String username, String email, String password) async {
    return _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/users/signup/'), 
        headers: _getHeaders(), 
        body: json.encode({'username': username, 'email': email, 'password': password})
      ),
      (data) => AuthResult.fromJson(data),
    );
  }

  Future<void> logout(String username, String token) async {
    await _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/users/logout/'), 
        headers: _getHeaders(token), 
        body: json.encode({'username': username})
      ),
      (_) => null,
    );
  }

  Future<AuthResult> facebookLogin(String fbAccessToken) async {
    return _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/auth/facebook/login/'),
        headers: _getHeaders(),
        body: json.encode({'fbAccessToken': fbAccessToken}),
      ),
      (data) => AuthResult.fromJson(data),
    );
  }

  Future<AuthResult> googleLogin(String type, String idToken) async {
    return _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/auth/google/login/'),
        headers: _getHeaders(),
        body: json.encode({'idToken': idToken, 'type': type}),
      ),
      (data) => AuthResult.fromJson(data),
    );
  }

  Future<List<Playlist>> getPlaylists({required String token, bool publicOnly = false}) async {
    final endpoint = publicOnly ? '/playlists/public_playlists/' : '/playlists/saved_playlists/';
    return _handleRequest(
      () => http.get(Uri.parse('$_baseUrl$endpoint'), headers: _getHeaders(token)),
      (data) {
        final playlists = data['playlists'] as List<dynamic>;
        return playlists.map((p) => Playlist.fromJson(p as Map<String, dynamic>)).toList();
      },
    );
  }

  Future<Playlist> getPlaylist(String id, String token) async {
    if (id.isEmpty || id == 'null') throw ApiException('Invalid playlist ID: $id');
    return _handleRequest(
      () => http.get(Uri.parse('$_baseUrl/playlists/playlists/$id'), headers: _getHeaders(token)),
      (data) {
        final playlist = data['playlist'] as List<dynamic>;
        return Playlist.fromJson(playlist.first as Map<String, dynamic>);
      },
    );
  }

  Future<String> createPlaylist(String name, String description, bool isPublic, String token, [String? deviceUuid]) async {
    final body = {
      'name': name,
      'description': description,
      'public': isPublic,
      if (deviceUuid != null) 'device_uuid': deviceUuid,
    };
    return _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/playlists/playlists'), 
        headers: _getHeaders(token), 
        body: json.encode(body)
      ),
      (data) => data['playlist_id'].toString(),
    );
  }

  Future<List<Track>> searchTracks(String query, {bool deezer = true}) async {
    final endpoint = deezer ? '/deezer/search/' : '/tracks/search/';
    final param = deezer ? 'q' : 'query';
    return _handleRequest(
      () => http.get(Uri.parse('$_baseUrl$endpoint?$param=${Uri.encodeQueryComponent(query)}')),
      (data) {
        final tracks = deezer ? data['data'] as List<dynamic> : data['tracks'] as List<dynamic>;
        return tracks.map((t) => Track.fromJson(t as Map<String, dynamic>)).toList();
      },
    );
  }

  Future<Track> getDeezerTrack(String trackId) async {
    return _handleRequest(
      () => http.get(Uri.parse('$_baseUrl/deezer/track/$trackId/')),
      (data) => Track.fromJson(data),
    );
  }

  Future<Map<String, dynamic>> get(String endpoint, String token) async {
    return _handleRequest(
      () => http.get(Uri.parse('$_baseUrl$endpoint'), headers: _getHeaders(token)),
      (data) => data,
    );
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body, String token) async {
    return _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _getHeaders(token),
        body: json.encode(body),
      ),
      (data) => data,
    );
  }
}

class AuthResult {
  final String token;
  final User user;
  AuthResult({required this.token, required this.user});
  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
    token: json['token'] as String, 
    user: User.fromJson(json['user'] as Map<String, dynamic>)
  );
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}
