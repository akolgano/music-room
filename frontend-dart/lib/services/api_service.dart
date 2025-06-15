// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/models.dart';
import '../core/consolidated_core.dart';

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
    T Function(dynamic) parser, {
    bool expectJson = true,
  }) async {
    try {
      final response = await request();
      
      if (response.statusCode >= 400) {
        String errorMessage;
        try {
          if (expectJson) {
            final errorData = json.decode(response.body);
            errorMessage = _extractErrorMessage(errorData, response.statusCode);
          } else {
            errorMessage = response.body.isNotEmpty ? response.body : 'HTTP ${response.statusCode}';
          }
        } catch (e) {
          errorMessage = '${AppStrings.error}: ${response.statusCode}';
        }
        throw ApiException(errorMessage);
      }

      if (expectJson && response.body.isNotEmpty) {
        final data = json.decode(response.body);
        return parser(data);
      } else {
        return parser(response.body);
      }
    } on SocketException {
      throw ApiException(AppStrings.connectionErrorMessage);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  String _extractErrorMessage(dynamic errorData, int statusCode) {
    if (errorData is Map<String, dynamic>) {
      return errorData['error'] ?? 
             errorData['detail'] ?? 
             errorData['message'] ?? 
             '${AppStrings.error}: $statusCode';
    } else if (errorData is String) {
      return errorData;
    }
    return '${AppStrings.error}: $statusCode';
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

  Future<void> facebookLink(String? token, String fbAccessToken) async {
    await _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/auth/facebook/link/'),
        headers: _getHeaders(token),
        body: json.encode({'fbAccessToken': fbAccessToken}),
      ),
      (_) => null,
    );
  }

  Future<void> googleLink(String type, String? token, String idToken) async {
    await _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/auth/google/link/'),
        headers: _getHeaders(token),
        body: json.encode({'idToken': idToken, 'type': type}),
      ),
      (_) => null,
    );
  }

  Future<void> forgotPassword(String email) async {
    await _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/users/forgot_password/'),
        headers: _getHeaders(),
        body: json.encode({'email': email}),
      ),
      (_) => null,
    );
  }

  Future<void> forgotChangePassword(String email, String otpStr, String password) async {
    await _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/users/forgot_change_password/'),
        headers: _getHeaders(),
        body: json.encode({'email': email, 'otp': int.parse(otpStr), 'password': password}),
      ),
      (_) => null,
    );
  }

  Future<Map<String, dynamic>> getUser(String? token) async {
    return _handleRequest(
      () => http.get(Uri.parse('$_baseUrl/users/get_user/'), headers: _getHeaders(token)),
      (data) => data,
    );
  }

  Future<void> userPasswordChange(String? token, String currentPassword, String newPassword) async {
    await _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/users/user_password_change/'),
        headers: _getHeaders(token),
        body: json.encode({'currentPassword': currentPassword, 'newPassword': newPassword}),
      ),
      (_) => null,
    );
  }

  Future<Map<String, dynamic>> getProfilePublic(String? token) async {
    return _handleRequest(
      () => http.get(Uri.parse('$_baseUrl/profile/public/'), headers: _getHeaders(token)),
      (data) => data,
    );
  }

  Future<Map<String, dynamic>> getProfilePrivate(String? token) async {
    return _handleRequest(
      () => http.get(Uri.parse('$_baseUrl/profile/private/'), headers: _getHeaders(token)),
      (data) => data,
    );
  }

  Future<Map<String, dynamic>> getProfileFriend(String? token) async {
    return _handleRequest(
      () => http.get(Uri.parse('$_baseUrl/profile/friend/'), headers: _getHeaders(token)),
      (data) => data,
    );
  }

  Future<Map<String, dynamic>> getProfileMusic(String? token) async {
    return _handleRequest(
      () => http.get(Uri.parse('$_baseUrl/profile/music/'), headers: _getHeaders(token)),
      (data) => data,
    );
  }

  Future<void> updateAvatar(String? token, String? avatarBase64, String? mimeType) async {
    await _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/profile/public/update/'),
        headers: _getHeaders(token),
        body: json.encode({'avatarBase64': avatarBase64, 'mimeType': mimeType}),
      ),
      (_) => null,
    );
  }

  Future<void> updatePublicBasic(String? token, String? gender, String? location) async {
    await _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/profile/public/update/'),
        headers: _getHeaders(token),
        body: json.encode({'gender': gender, 'location': location}),
      ),
      (_) => null,
    );
  }

  Future<void> updatePublicBio(String? token, String? bio) async {
    await _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/profile/public/update/'),
        headers: _getHeaders(token),
        body: json.encode({'bio': bio}),
      ),
      (_) => null,
    );
  }

  Future<void> updatePrivateInfo(String? token, String? firstName, String? lastName, String? phone, String? street, String? country, String? postalCode) async {
    await _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/profile/private/update/'),
        headers: _getHeaders(token),
        body: json.encode({
          'firstName': firstName,
          'lastName': lastName,
          'phone': phone,
          'street': street,
          'country': country,
          'postalCode': postalCode,
        }),
      ),
      (_) => null,
    );
  }

  Future<void> updateFriendInfo(String? token, String? dob, List<String>? hobbies, String? friendInfo) async {
    await _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/profile/friend/update/'),
        headers: _getHeaders(token),
        body: json.encode({
          'dob': dob,
          'hobbies': hobbies,
          'friendInfo': friendInfo,
        }),
      ),
      (_) => null,
    );
  }

  Future<void> updateMusicPreferences(String? token, List<String>? musicPreferences) async {
    await _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/profile/music/update/'),
        headers: _getHeaders(token),
        body: json.encode({'musicPreferences': musicPreferences}),
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

  Future<void> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
    required String token,
    String? deviceUuid,
  }) async {
    await _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/playlists/$playlistId/remove_tracks'),
        headers: _getHeaders(token),
        body: json.encode({
          'track_id': trackId,
          if (deviceUuid != null) 'device_uuid': deviceUuid,
        }),
      ),
      (_) => null,
    );
  }

  Future<void> moveTrackInPlaylist({
    required String playlistId,
    required int rangeStart,
    required int insertBefore,
    int rangeLength = 1,
    required String token,
  }) async {
    await _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/playlists/move-track/'),
        headers: _getHeaders(token),
        body: json.encode({
          'playlist_id': int.parse(playlistId),
          'range_start': rangeStart,
          'insert_before': insertBefore,
          'range_length': rangeLength,
        }),
      ),
      (_) => null,
    );
  }

  Future<void> inviteUserToPlaylist({
    required String playlistId,
    required int userId,
    required String token,
  }) async {
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

  Future<void> addTrackFromDeezer(String deezerTrackId, String token) async {
    await _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/tracks/add_from_deezer/$deezerTrackId/'),
        headers: _getHeaders(token),
      ),
      (_) => null,
    );
  }

  Future<Device?> registerDevice(String uuid, String licenseKey, String deviceName, String token) async {
    try {
      return await _handleRequest(
        () => http.post(
          Uri.parse('$_baseUrl/devices/register/'),
          headers: _getHeaders(token),
          body: json.encode({
            'uuid': uuid,
            'license_key': licenseKey,
            'device_name': deviceName,
          }),
        ),
        (data) => Device.fromJson(data),
      );
    } catch (e) {
      return null;
    }
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

  Future<bool> checkControlPermission(String deviceUuid, String token) async {
    try {
      await _handleRequest(
        () => http.get(Uri.parse('$_baseUrl/devices/$deviceUuid/can-control'), headers: _getHeaders(token)),
        (data) => data,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> delegateDeviceControl({
    required String deviceUuid,
    required int delegateUserId,
    required bool canControl,
    required String token,
  }) async {
    await _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/devices/delegate/'),
        headers: _getHeaders(token),
        body: json.encode({
          'device_uuid': deviceUuid,
          'delegate_user_id': delegateUserId,
          'can_control': canControl,
        }),
      ),
      (_) => null,
    );
  }

  Future<List<Device>> getAllUserDevices(String token) async {
    return getUserDevices(token); 
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
      () => http.post(
        Uri.parse('$_baseUrl/users/send_friend_request/'),
        headers: _getHeaders(token),
        body: json.encode({'user_id': userId}),
      ),
      (data) => data['message'] ?? 'Friend request sent',
    );
  }

  Future<List<Map<String, dynamic>>> getPendingFriendRequests(String token) async {
    return _handleRequest(
      () => http.get(Uri.parse('$_baseUrl/users/get_pending_requests/'), headers: _getHeaders(token)),
      (data) {
        final requests = data['requests'] as List<dynamic>;
        return requests.map((r) => r as Map<String, dynamic>).toList();
      },
    );
  }

  Future<String> acceptFriendRequest(int friendshipId, String token) async {
    return _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/users/accept_friend_request/$friendshipId/'),
        headers: _getHeaders(token),
      ),
      (data) => data['message'] ?? 'Friend request accepted',
    );
  }

  Future<String> rejectFriendRequest(int friendshipId, String token) async {
    return _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/users/reject_friend_request/$friendshipId/'),
        headers: _getHeaders(token),
      ),
      (data) => data['message'] ?? 'Friend request rejected',
    );
  }

  Future<void> removeFriend(int friendId, String token) async {
    await _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/users/remove_friend/$friendId/'),
        headers: _getHeaders(token),
      ),
      (_) => null,
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

  Future<bool> checkConnectivity() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode < 400;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getApiInfo() async {
    try {
      return await _handleRequest(
        () => http.get(Uri.parse('$_baseUrl/info')),
        (data) => data,
      );
    } catch (e) {
      return null;
    }
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
  final int? statusCode;
  final dynamic originalError;

  ApiException(this.message, {this.statusCode, this.originalError});

  @override
  String toString() => message;
}
