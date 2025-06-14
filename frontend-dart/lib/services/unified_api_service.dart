// lib/services/unified_api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../core/app_core.dart';

class UnifiedApiService {
  static final UnifiedApiService _instance = UnifiedApiService._internal();
  factory UnifiedApiService() => _instance;
  UnifiedApiService._internal();

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

      if (expectJson) {
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

  Future<T> get<T>(
    String endpoint, 
    T Function(dynamic) parser, {
    String? token,
    Map<String, String>? queryParams,
    bool expectJson = true,
  }) async {
    Uri uri = Uri.parse('$_baseUrl$endpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    return _handleRequest(
      () => http.get(uri, headers: _getHeaders(token)),
      parser,
      expectJson: expectJson,
    );
  }

  Future<T> post<T>(
    String endpoint,
    T Function(dynamic) parser, {
    String? token,
    Map<String, dynamic>? body,
    bool expectJson = true,
  }) async {
    return _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _getHeaders(token),
        body: body != null ? json.encode(body) : null,
      ),
      parser,
      expectJson: expectJson,
    );
  }

  Future<T> put<T>(
    String endpoint,
    T Function(dynamic) parser, {
    String? token,
    Map<String, dynamic>? body,
    bool expectJson = true,
  }) async {
    return _handleRequest(
      () => http.put(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _getHeaders(token),
        body: body != null ? json.encode(body) : null,
      ),
      parser,
      expectJson: expectJson,
    );
  }

  Future<T> delete<T>(
    String endpoint,
    T Function(dynamic) parser, {
    String? token,
    bool expectJson = true,
  }) async {
    return _handleRequest(
      () => http.delete(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _getHeaders(token),
      ),
      parser,
      expectJson: expectJson,
    );
  }

  Future<Map<String, dynamic>> getJson(String endpoint, {String? token, Map<String, String>? queryParams}) =>
      get(endpoint, (data) => data as Map<String, dynamic>, token: token, queryParams: queryParams);

  Future<List<dynamic>> getList(String endpoint, {String? token, Map<String, String>? queryParams}) =>
      get(endpoint, (data) => data as List<dynamic>, token: token, queryParams: queryParams);

  Future<String> getString(String endpoint, {String? token, Map<String, String>? queryParams}) =>
      get(endpoint, (data) => data.toString(), token: token, queryParams: queryParams, expectJson: false);

  Future<Map<String, dynamic>> postJson(String endpoint, {String? token, Map<String, dynamic>? body}) =>
      post(endpoint, (data) => data as Map<String, dynamic>, token: token, body: body);

  Future<List<dynamic>> postList(String endpoint, {String? token, Map<String, dynamic>? body}) =>
      post(endpoint, (data) => data as List<dynamic>, token: token, body: body);

  Future<String> postString(String endpoint, {String? token, Map<String, dynamic>? body}) =>
      post(endpoint, (data) => data.toString(), token: token, body: body, expectJson: false);

  Future<void> postVoid(String endpoint, {String? token, Map<String, dynamic>? body}) =>
      post(endpoint, (_) => null, token: token, body: body);

  Future<Map<String, dynamic>> putJson(String endpoint, {String? token, Map<String, dynamic>? body}) =>
      put(endpoint, (data) => data as Map<String, dynamic>, token: token, body: body);

  Future<void> putVoid(String endpoint, {String? token, Map<String, dynamic>? body}) =>
      put(endpoint, (_) => null, token: token, body: body);

  Future<void> deleteVoid(String endpoint, {String? token}) =>
      delete(endpoint, (_) => null, token: token);

  Future<List<T>> batchRequests<T>(
    List<Future<T> Function()> requests, {
    int? concurrency,
    void Function(int completed, int total)? onProgress,
  }) async {
    final results = <T>[];
    final totalRequests = requests.length;
    
    if (concurrency != null && concurrency > 1) {
      for (int i = 0; i < requests.length; i += concurrency) {
        final batch = requests.skip(i).take(concurrency);
        final batchResults = await Future.wait(batch.map((req) => req()));
        results.addAll(batchResults);
        onProgress?.call(results.length, totalRequests);
      }
    } else {
      for (int i = 0; i < requests.length; i++) {
        final result = await requests[i]();
        results.add(result);
        onProgress?.call(i + 1, totalRequests);
      }
    }
    
    return results;
  }

  Future<T> withRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
    bool Function(dynamic error)? shouldRetry,
  }) async {
    int attempts = 0;
    dynamic lastError;

    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        lastError = e;
        attempts++;
        
        if (attempts >= maxRetries) break;
        if (shouldRetry != null && !shouldRetry(e)) break;
        
        await Future.delayed(delay * attempts);
      }
    }
    
    throw lastError;
  }

  Future<Map<String, dynamic>> uploadFile(
    String endpoint,
    String filePath,
    String fieldName, {
    String? token,
    Map<String, String>? additionalFields,
    void Function(int sent, int total)? onProgress,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final request = http.MultipartRequest('POST', uri);
    
    if (token != null) {
      request.headers['Authorization'] = '${AppConstants.authorizationPrefix} $token';
    }
    
    final file = await http.MultipartFile.fromPath(fieldName, filePath);
    request.files.add(file);
    
    if (additionalFields != null) {
      request.fields.addAll(additionalFields);
    }
    
    final streamedResponse = await request.send();
    
    if (onProgress != null) {
      streamedResponse.stream.listen(
        (data) => onProgress(data.length, streamedResponse.contentLength ?? 0),
      );
    }
    
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode >= 400) {
      final errorData = json.decode(response.body);
      throw ApiException(_extractErrorMessage(errorData, response.statusCode));
    }
    
    return json.decode(response.body);
  }

  Future<List<int>> downloadFile(
    String endpoint, {
    String? token,
    void Function(int received, int total)? onProgress,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final request = http.Request('GET', uri);
    
    if (token != null) {
      request.headers['Authorization'] = '${AppConstants.authorizationPrefix} $token';
    }
    
    final streamedResponse = await http.Client().send(request);
    
    if (streamedResponse.statusCode >= 400) {
      throw ApiException('Download failed: ${streamedResponse.statusCode}');
    }
    
    final bytes = <int>[];
    final total = streamedResponse.contentLength ?? 0;
    
    await for (final chunk in streamedResponse.stream) {
      bytes.addAll(chunk);
      onProgress?.call(bytes.length, total);
    }
    
    return bytes;
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
      return await getJson('/info');
    } catch (e) {
      return null;
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  ApiException(this.message, {this.statusCode, this.originalError});

  @override
  String toString() => message;
}

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? error;
  final int? statusCode;

  ApiResponse.success(this.data, {this.message, this.statusCode}) 
    : success = true, error = null;
  
  ApiResponse.error(this.error, {this.statusCode}) 
    : success = false, data = null, message = null;

  bool get isError => !success;
  bool get hasData => data != null;
}

class RequestConfig {
  final Duration timeout;
  final int maxRetries;
  final bool enableCache;
  final Map<String, String> headers;

  const RequestConfig({
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.enableCache = false,
    this.headers = const {},
  });
}

class ApiEndpoints {
  static const String _auth = '/auth';
  static const String _users = '/users';
  static const String _playlists = '/playlists';
  static const String _tracks = '/tracks';
  static const String _deezer = '/deezer';
  static const String _devices = '/devices';
  static const String _profile = '/profile';

  static String get login => '$_users/login/';
  static String get signup => '$_users/signup/';
  static String get logout => '$_users/logout/';
  static String get forgotPassword => '$_users/forgot_password/';
  static String get resetPassword => '$_users/forgot_change_password/';

  static String get facebookLogin => '$_auth/facebook/login/';
  static String get googleLogin => '$_auth/google/login/';
  static String get facebookLink => '$_auth/facebook/link/';
  static String get googleLink => '$_auth/google/link/';

  static String get userInfo => '$_users/get_user/';
  static String get userPasswordChange => '$_users/user_password_change/';
  static String get getFriends => '$_users/get_friends/';
  static String get sendFriendRequest => '$_users/send_friend_request/';
  static String get getPendingRequests => '$_users/get_pending_requests/';
  static String acceptFriendRequest(int id) => '$_users/accept_friend_request/$id/';
  static String rejectFriendRequest(int id) => '$_users/reject_friend_request/$id/';
  static String removeFriend(int id) => '$_users/remove_friend/$id/';

  static String get playlists => '$_playlists/playlists';
  static String get savedPlaylists => '$_playlists/saved_playlists/';
  static String get publicPlaylists => '$_playlists/public_playlists/';
  static String playlist(String id) => '$_playlists/playlist/$id';
  static String playlistTracks(String id) => '$_playlists/playlist/$id/tracks';
  static String playlistVisibility(String id) => '$_playlists/$id/visibility';
  static String playlistInvite(String id) => '$_playlists/$id/invite-user/';
  static String get moveTrack => '$_playlists/move-track/';

  static String get searchTracks => '$_tracks/search/';
  static String addFromDeezer(String id) => '$_tracks/add_from_deezer/$id/';

  static String get deezerSearch => '$_deezer/search/';
  static String deezerTrack(String id) => '$_deezer/track/$id/';

  static String get registerDevice => '$_devices/register/';
  static String get userDevices => '$_devices/';
  static String get delegateControl => '$_devices/delegate/';
  static String deviceCanControl(String uuid) => '$_devices/$uuid/can-control';

  static String get profilePublic => '$_profile/public/';
  static String get profilePrivate => '$_profile/private/';
  static String get profileFriend => '$_profile/friend/';
  static String get profileMusic => '$_profile/music/';
  static String get updateProfilePublic => '$_profile/public/update/';
  static String get updateProfilePrivate => '$_profile/private/update/';
  static String get updateProfileFriend => '$_profile/friend/update/';
  static String get updateProfileMusic => '$_profile/music/update/';
}
