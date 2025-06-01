// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user.dart';
import '../models/track.dart';
import '../models/playlist.dart';
import '../models/playlist_track.dart';
import '../models/device.dart';
import '../core/constants.dart';
import '../core/app_strings.dart';

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

  Future<List<PlaylistTrack>> getPlaylistTracks(String playlistId, String token) async {
    return _handleRequest(
      () => http.get(Uri.parse('$_baseUrl/playlists/playlist/$playlistId/tracks/'), headers: _getHeaders(token)),
      (data) {
        final tracks = data['tracks'] as List<dynamic>;
        return tracks.map((t) => PlaylistTrack.fromJson(t as Map<String, dynamic>)).toList();
      },
    );
  }

  Future<String> createPlaylist(String name, String description, bool isPublic, String token) async {
    return _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/playlists/playlists'), 
        headers: _getHeaders(token), 
        body: json.encode({'name': name, 'description': description, 'public': isPublic})
      ),
      (data) => data['playlist_id'].toString(),
    );
  }

  Future<String> createPlaylistWithDevice(String name, String description, bool isPublic, String token, String? deviceUuid) async {
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

  Future<void> changePlaylistVisibility(String playlistId, bool isPublic, String token) async {
    await _handleRequest(
      () => http.patch(
        Uri.parse('$_baseUrl/playlists/playlists/$playlistId/change-visibility/'), 
        headers: _getHeaders(token), 
        body: json.encode({'public': isPublic})
      ),
      (_) => null,
    );
  }

  Future<void> addTrackToPlaylist(String playlistId, String trackId, String token) async {
    await _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/playlists/$playlistId/tracks/'), 
        headers: _getHeaders(token), 
        body: json.encode({'track_id': trackId})
      ),
      (_) => null,
    );
  }

  Future<void> addTrackToPlaylistWithDevice(String playlistId, String trackId, String token, String? deviceUuid) async {
    final body = {
      'track_id': trackId,
      if (deviceUuid != null) 'device_uuid': deviceUuid,
    };
    await _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/playlists/$playlistId/tracks/'), 
        headers: _getHeaders(token), 
        body: json.encode(body)
      ),
      (_) => null,
    );
  }

  Future<void> removeTrackFromPlaylistWithDevice(String playlistId, String trackId, String token, String? deviceUuid) async {
    final body = {
      if (deviceUuid != null) 'device_uuid': deviceUuid,
    };
    await _handleRequest(
      () => http.delete(
        Uri.parse('$_baseUrl/playlists/playlists/$playlistId/tracks/$trackId/'), 
        headers: _getHeaders(token), 
        body: json.encode(body)
      ),
      (_) => null,
    );
  }

  Future<void> moveTrackInPlaylistWithDevice(String playlistId, int oldIndex, int newIndex, int rangeLength, String token, String? deviceUuid) async {
    final body = {
      'old_index': oldIndex,
      'new_index': newIndex,
      'range_length': rangeLength,
      if (deviceUuid != null) 'device_uuid': deviceUuid,
    };
    await _handleRequest(
      () => http.patch(
        Uri.parse('$_baseUrl/playlists/move-track/$playlistId/'), 
        headers: _getHeaders(token), 
        body: json.encode(body)
      ),
      (_) => null,
    );
  }

  Future<void> inviteUserToPlaylist(String playlistId, String userId, String token) async {
    await _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/playlists/playlists/$playlistId/invite-user/'), 
        headers: _getHeaders(token), 
        body: json.encode({'user_id': userId})
      ),
      (_) => null,
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

  Future<void> addTrackFromDeezer(String trackId, String token) async {
    await _handleRequest(
      () => http.post(Uri.parse('$_baseUrl/tracks/add_from_deezer/$trackId/'), headers: _getHeaders(token)),
      (_) => null,
    );
  }

  Future<List<int>> getFriends(String token) async {
    return _handleRequest(
      () => http.get(Uri.parse('$_baseUrl/users/get_friends/'), headers: _getHeaders(token)),
      (data) {
        final friends = data['friends'] as List<dynamic>;
        return friends.map((f) => f as int).toList();
      },
    );
  }

  Future<String> sendFriendRequest(int userId, String token) async {
    return _handleRequest(
      () => http.post(Uri.parse('$_baseUrl/users/send_friend_request/$userId/'), headers: _getHeaders(token)),
      (data) => data['message'] as String,
    );
  }

  Future<String> acceptFriendRequest(int friendshipId, String token) async {
    return _handleRequest(
      () => http.post(Uri.parse('$_baseUrl/users/accept_friend_request/$friendshipId/'), headers: _getHeaders(token)),
      (data) => data['message'] as String,
    );
  }

  Future<String> rejectFriendRequest(int friendshipId, String token) async {
    return _handleRequest(
      () => http.post(Uri.parse('$_baseUrl/users/reject_friend_request/$friendshipId/'), headers: _getHeaders(token)),
      (data) => data['message'] as String,
    );
  }

  Future<void> removeFriend(int userId, String token) async {
    await _handleRequest(
      () => http.post(Uri.parse('$_baseUrl/users/remove_friend/$userId/'), headers: _getHeaders(token)),
      (_) => null,
    );
  }

  Future<List<Device>> getUserDevices(String token) async {
    return _handleRequest(
      () => http.get(Uri.parse('$_baseUrl/devices/'), headers: _getHeaders(token)),
      (data) {
        final devices = data['devices'] as List<dynamic>;
        return devices.map((d) => Device.fromJson(d as Map<String, dynamic>)).toList();
      },
    );
  }

  Future<Device> registerDevice(String uuid, String licenseKey, String deviceName, String token) async {
    return _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/devices/register/'),
        headers: _getHeaders(token),
        body: json.encode({
          'uuid': uuid,
          'license_key': licenseKey,
          'device_name': deviceName,
        }),
      ),
      (data) => Device.fromJson(data['device'] as Map<String, dynamic>),
    );
  }

  Future<bool> checkControlPermission(String deviceUuid, String token) async {
    return _handleRequest(
      () => http.get(Uri.parse('$_baseUrl/devices/$deviceUuid/can-control/'), headers: _getHeaders(token)),
      (data) => data['can_control'] as bool,
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
