// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/models.dart';
import '../core/constants.dart';
import '../core/api_constants.dart';
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
          errorMessage = errorData['error'] ?? 
                        errorData['detail'] ?? 
                        '${AppStrings.requestFailed}: ${response.statusCode}';
        } catch (e) {
          errorMessage = '${AppStrings.requestFailed}: ${response.statusCode}';
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
        Uri.parse('$_baseUrl${ApiEndpoints.login}'),
        headers: _getHeaders(),
        body: json.encode({'username': username, 'password': password}),
      ),
      (data) => AuthResult.fromJson(data),
    );
  }

  Future<AuthResult> signup(String username, String email, String password) async {
    return _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl${ApiEndpoints.signup}'),
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
        Uri.parse('$_baseUrl${ApiEndpoints.logout}'),
        headers: _getHeaders(token),
        body: json.encode({'username': username}),
      ),
      (_) => null,
    );
  }

  Future<List<Playlist>> getPlaylists({required String token, bool publicOnly = false}) async {
    final endpoint = publicOnly ? ApiEndpoints.publicPlaylists : ApiEndpoints.savedPlaylists;
    return _handleRequest(
      () => http.get(Uri.parse('$_baseUrl$endpoint'), headers: _getHeaders(token)),
      (data) => (data['playlists'] as List).map((p) => Playlist.fromJson(p)).toList(),
    );
  }

  Future<Playlist> getPlaylist(String id, String token) async {
    if (id.isEmpty || id == 'null') {
      throw ApiException('${AppStrings.invalidId}: $id');
    }
    
    return _handleRequest(
      () => http.get(Uri.parse('$_baseUrl${ApiEndpoints.playlists}/$id'), headers: _getHeaders(token)),
      (data) => Playlist.fromJson(data['playlist'][0]),
    );
  }

  Future<List<PlaylistTrack>> getPlaylistTracks(String playlistId, String token) async {
    if (playlistId.isEmpty || playlistId == 'null') {
      throw ApiException('${AppStrings.invalidId}: $playlistId');
    }
    
    return _handleRequest(
      () => http.get(Uri.parse('$_baseUrl${ApiEndpoints.playlistTracks}/$playlistId/tracks/'), headers: _getHeaders(token)),
      (data) => (data['tracks'] as List).map((t) => PlaylistTrack.fromJson(t)).toList(),
    );
  }

  Future<String> createPlaylist(String name, String description, bool isPublic, String token) async {
    return _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl${ApiEndpoints.playlists}'),
        headers: _getHeaders(token),
        body: json.encode({'name': name, 'description': description, 'public': isPublic}),
      ),
      (data) => data['playlist_id'].toString(),
    );
  }

  Future<void> addTrackToPlaylist(String playlistId, String trackId, String token) async {
    if (playlistId.isEmpty || playlistId == 'null') {
      throw ApiException('${AppStrings.invalidId}: $playlistId');
    }
    if (trackId.isEmpty || trackId == 'null') {
      throw ApiException('${AppStrings.invalidId}: $trackId');
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
      throw ApiException('${AppStrings.invalidId}: $playlistId');
    }
    
    await _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl${ApiEndpoints.removeFromPlaylist}/$playlistId/remove_tracks'),
        headers: _getHeaders(token),
        body: json.encode({'track_id': trackId}),
      ),
      (_) => null,
    );
  }

  Future<void> moveTrackInPlaylist(String playlistId, int rangeStart, int insertBefore, int rangeLength, String token) async {
    if (playlistId.isEmpty || playlistId == 'null') {
      throw ApiException('${AppStrings.invalidId}: $playlistId');
    }
    
    await _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl${ApiEndpoints.moveTrack}'),
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
      throw ApiException('${AppStrings.invalidId}: $playlistId');
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
      throw ApiException('${AppStrings.invalidId}: $playlistId');
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

  Future<List<Track>> searchTracks(String query, {bool deezer = true}) async {
    final endpoint = deezer ? ApiEndpoints.deezerSearch : ApiEndpoints.searchTracks;
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
      () => http.get(Uri.parse('$_baseUrl${ApiEndpoints.deezerTrack}$trackId/')),
      (data) => Track.fromJson(data),
    );
  }

  Future<void> addTrackFromDeezer(String trackId, String token) async {
    await _handleRequest(
      () => http.post(Uri.parse('$_baseUrl${ApiEndpoints.addFromDeezer}/$trackId/'), headers: _getHeaders(token)),
      (_) => null,
    );
  }

  Future<List<int>> getFriends(String token) async {
    return _handleRequest(
      () => http.get(Uri.parse('$_baseUrl${ApiEndpoints.getFriends}'), headers: _getHeaders(token)),
      (data) => List<int>.from(data['friends']),
    );
  }

  Future<String> sendFriendRequest(int userId, String token) async {
    return _handleRequest(
      () => http.post(Uri.parse('$_baseUrl${ApiEndpoints.sendFriendRequest}$userId/'), headers: _getHeaders(token)),
      (data) => data['message'],
    );
  }

  Future<String> acceptFriendRequest(int friendshipId, String token) async {
    return _handleRequest(
      () => http.post(Uri.parse('$_baseUrl${ApiEndpoints.acceptFriendRequest}$friendshipId/'), headers: _getHeaders(token)),
      (data) => data['message'],
    );
  }

  Future<String> rejectFriendRequest(int friendshipId, String token) async {
    return _handleRequest(
      () => http.post(Uri.parse('$_baseUrl${ApiEndpoints.rejectFriendRequest}$friendshipId/'), headers: _getHeaders(token)),
      (data) => data['message'],
    );
  }

  Future<void> removeFriend(int userId, String token) async {
    await _handleRequest(
      () => http.post(Uri.parse('$_baseUrl${ApiEndpoints.removeFriend}$userId/'), headers: _getHeaders(token)),
      (_) => null,
    );
  }

  Future<Device> registerDevice(String uuid, String licenseKey, String deviceName, String token) async {
    return _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl${ApiEndpoints.registerDevice}'),
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
        Uri.parse('$_baseUrl${ApiEndpoints.delegateControl}'),
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
      () => http.get(Uri.parse('$_baseUrl${ApiEndpoints.canControl}/$deviceUuid/can-control/'), headers: _getHeaders(token)),
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
