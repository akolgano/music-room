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

  Future<void> logout(String username, String token) async {
    await _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/users/logout/'),
        headers: _getHeaders(token),
        body: json.encode({'username': username}),
      ),
      (_) => null,
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
    
    return _handleRequest(
      () => http.get(Uri.parse('$_baseUrl/playlists/playlists/$id'), headers: _getHeaders(token)),
      (data) => Playlist.fromJson(data['playlist'][0]),
    );
  }

  Future<List<PlaylistTrack>> getPlaylistTracks(String playlistId, String token) async {
    if (playlistId.isEmpty || playlistId == 'null') {
      throw ApiException('Invalid playlist ID: $playlistId');
    }
    
    return _handleRequest(
      () => http.get(Uri.parse('$_baseUrl/playlists/playlist/$playlistId/tracks/'), headers: _getHeaders(token)),
      (data) => (data['tracks'] as List).map((t) => PlaylistTrack.fromJson(t)).toList(),
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

  Future<void> addTrackToPlaylist(String playlistId, String trackId, String token) async {
    if (playlistId.isEmpty || playlistId == 'null') {
      throw ApiException('Invalid playlist ID: $playlistId');
    }
    if (trackId.isEmpty || trackId == 'null') {
      throw ApiException('Invalid track ID: $trackId');
    }
    
    await _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/playlists/$playlistId/add/'),
        headers: _getHeaders(token),
        body: json.encode({'track_id': trackId}),
      ),
      (_) => null,
    );
  }

  Future<void> removeTrackFromPlaylist(String playlistId, String trackId, String token) async {
    if (playlistId.isEmpty || playlistId == 'null') {
      throw ApiException('Invalid playlist ID: $playlistId');
    }
    
    await _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/playlists/playlists/$playlistId/remove_tracks'),
        headers: _getHeaders(token),
        body: json.encode({'track_id': trackId}),
      ),
      (_) => null,
    );
  }

  Future<void> moveTrackInPlaylist(String playlistId, int rangeStart, int insertBefore, int rangeLength, String token) async {
    if (playlistId.isEmpty || playlistId == 'null') {
      throw ApiException('Invalid playlist ID: $playlistId');
    }
    
    await _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/playlists/move-track/'),
        headers: _getHeaders(token),
        body: json.encode({
          'playlist_id': playlistId,
          'range_start': rangeStart,
          'insert_before': insertBefore,
          'range_length': rangeLength,
        }),
      ),
      (_) => null,
    );
  }

  Future<void> changePlaylistVisibility(String playlistId, bool isPublic, String token) async {
    if (playlistId.isEmpty || playlistId == 'null') {
      throw ApiException('Invalid playlist ID: $playlistId');
    }
    
    await _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/playlists/$playlistId/change-visibility/'),
        headers: _getHeaders(token),
        body: json.encode({'public': isPublic}),
      ),
      (_) => null,
    );
  }

  Future<void> inviteUserToPlaylist(String playlistId, String userId, String token) async {
    if (playlistId.isEmpty || playlistId == 'null') {
      throw ApiException('Invalid playlist ID: $playlistId');
    }
    
    await _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/playlists/$playlistId/invite-user/'),
        headers: _getHeaders(token),
        body: json.encode({'user_id': userId}),
      ),
      (_) => null,
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

  Future<String> acceptFriendRequest(int friendshipId, String token) async {
    return _handleRequest(
      () => http.post(Uri.parse('$_baseUrl/users/accept_friend_request/$friendshipId/'), headers: _getHeaders(token)),
      (data) => data['message'],
    );
  }

  Future<String> rejectFriendRequest(int friendshipId, String token) async {
    return _handleRequest(
      () => http.post(Uri.parse('$_baseUrl/users/reject_friend_request/$friendshipId/'), headers: _getHeaders(token)),
      (data) => data['message'],
    );
  }

  Future<void> removeFriend(int userId, String token) async {
    await _handleRequest(
      () => http.post(Uri.parse('$_baseUrl/users/remove_friend/$userId/'), headers: _getHeaders(token)),
      (_) => null,
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
      (data) => Device.fromJson(data['device']),
    );
  }

  Future<MusicControlDelegate> delegateControl(String deviceUuid, String delegateUserId, bool canControl, String token) async {
    return _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/devices/delegate/'),
        headers: _getHeaders(token),
        body: json.encode({
          'device_uuid': deviceUuid,
          'delegate_user_id': delegateUserId,
          'can_control': canControl,
        }),
      ),
      (data) => MusicControlDelegate.fromJson(data['delegation']),
    );
  }

  Future<bool> checkControlPermission(String deviceUuid, String token) async {
    return _handleRequest(
      () => http.get(Uri.parse('$_baseUrl/devices/$deviceUuid/can-control/'), headers: _getHeaders(token)),
      (data) => data['can_control'] as bool,
    );
  }
}

class Device {
  final String id;
  final String userId;
  final String uuid;
  final String licenseKey;
  final bool isActive;
  
  Device({
    required this.id,
    required this.userId,
    required this.uuid,
    required this.licenseKey,
    required this.isActive,
  });
  
  factory Device.fromJson(Map<String, dynamic> json) => Device(
    id: json['id'].toString(),
    userId: json['user'].toString(),
    uuid: json['uuid'] ?? '',
    licenseKey: json['license_key'] ?? '',
    isActive: json['is_active'] ?? false,
  );
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'user': userId,
    'uuid': uuid,
    'license_key': licenseKey,
    'is_active': isActive,
  };
}

class MusicControlDelegate {
  final String id;
  final String owner;
  final String delegate;
  final String deviceId;
  final bool canControl;
  final DateTime createdAt;
  
  MusicControlDelegate({
    required this.id,
    required this.owner,
    required this.delegate,
    required this.deviceId,
    required this.canControl,
    required this.createdAt,
  });
  
  factory MusicControlDelegate.fromJson(Map<String, dynamic> json) => MusicControlDelegate(
    id: json['id'].toString(),
    owner: json['owner'] ?? '',
    delegate: json['delegate'] ?? '',
    deviceId: json['device'].toString(),
    canControl: json['can_control'] ?? false,
    createdAt: DateTime.parse(json['created_at']),
  );
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'owner': owner,
    'delegate': delegate,
    'device': deviceId,
    'can_control': canControl,
    'created_at': createdAt.toIso8601String(),
  };
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
