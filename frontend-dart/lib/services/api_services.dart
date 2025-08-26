import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/music_models.dart';
import '../models/api_models.dart';
import '../providers/auth_providers.dart';
import '../core/locator_core.dart';
import '../core/navigation_core.dart';

class _ResponseLimitingInterceptor extends Interceptor {
  static const int maxLines = 60;
  
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logLimitedResponse(response);
    handler.next(response);
  }
  
  void _logLimitedResponse(Response response) {
    if (response.data != null) {
      String responseStr;
      try {
        responseStr = const JsonEncoder.withIndent('  ').convert(response.data);
      } catch (e) {
        responseStr = response.data.toString();
      }
      
      final lines = responseStr.split('\n');
      if (lines.length <= maxLines) {
        debugPrint(responseStr);
      } else {
        final truncated = lines.take(maxLines).join('\n');
        debugPrint(truncated);
        debugPrint('... Response truncated (${lines.length - maxLines} more lines) ...');
      }
    }
  }
}

class ApiService {
  final Dio _dio;
  final ApiRateMonitorService _rateMonitor = ApiRateMonitorService();

  ApiService([Dio? dio]) : _dio = dio ?? _createConfiguredDio() {
    _rateMonitor.startMonitoring();
  }

  static Dio _createConfiguredDio() {
    final baseUrl = (dotenv.env['API_BASE_URL']?.isNotEmpty == true 
        ? dotenv.env['API_BASE_URL']! 
        : 'http://localhost:8000');
    final dio = Dio()
      ..options = BaseOptions(
          baseUrl: baseUrl, 
          headers: {'Content-Type': 'application/json', 'Accept': 'application/json'}, 
          connectTimeout: const Duration(seconds: 10), 
          receiveTimeout: const Duration(seconds: 10), 
          sendTimeout: const Duration(seconds: 10))
      ..interceptors.addAll([
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          logPrint: (log) {
            String maskedLog = log.toString();
            if (maskedLog.contains('password')) {
              maskedLog = maskedLog.replaceAllMapped(
                RegExp(r'"password"\s*:\s*"[^"]*"'),
                (match) => '"password": "***HIDDEN***"'
              );
            }
            debugPrint('DIO >>> $maskedLog');
          },
        ),
        _ResponseLimitingInterceptor(),
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.contains('/tracks/vote/')) {
              debugPrint('INTERCEPTOR >>> Vote request headers:');
              options.headers.forEach((key, value) {
                debugPrint('  $key: $value');
              });
            }
            handler.next(options);
          },
          onError: (error, handler) {
            if (error.requestOptions.path.contains('/tracks/vote/')) {
              debugPrint('INTERCEPTOR >>> Vote request failed');
              debugPrint('  Headers sent: ${error.requestOptions.headers}');
              debugPrint('  Data sent: ${error.requestOptions.data}');
            }
            handler.next(error);
          }
        )
      ]);
    return dio;
  }

  Future<T> _request<T>(
    String method, 
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    String? token,
    T Function(Map<String, dynamic>)? fromJson,
    bool debug = false,
  }) async {
    
    _rateMonitor.recordApiCall();
    
    final headers = <String, dynamic>{};
    if (token != null) headers['Authorization'] = 'Token $token';
    
    dynamic processedData;
    try {
      processedData = data?.toJson?.call() ?? data;
    } catch (e) {
      processedData = data;
    }

    if (endpoint.contains('/tracks/vote/') && processedData is Map) {
      debugPrint('API >>> Vote endpoint: $endpoint');
      debugPrint('API >>> Vote data: $processedData');
      
      if (processedData['latitude'] != null) {
        headers['X-User-Latitude'] = processedData['latitude'].toString();
        debugPrint('API >>> Adding X-User-Latitude: ${headers['X-User-Latitude']}');
      }
      if (processedData['longitude'] != null) {
        headers['X-User-Longitude'] = processedData['longitude'].toString();
        debugPrint('API >>> Adding X-User-Longitude: ${headers['X-User-Longitude']}');
      }
      
      debugPrint('API >>> Final headers for vote: $headers');
    }

    if (method.toUpperCase() == 'POST' && !headers.containsKey('Content-Type')) {
      headers['Content-Type'] = 'application/json';
    }
    
    final options = Options(headers: headers);
    
    Response response;
    switch (method.toUpperCase()) {
      case 'GET':
        response = await _dio.get(endpoint, queryParameters: queryParams, options: options);
        break;
      case 'POST':
        response = await _dio.post(endpoint, data: processedData, options: options);
        break;
      case 'PATCH':
        response = await _dio.patch(endpoint, data: processedData, options: options);
        break;
      case 'DELETE':
        response = await _dio.delete(endpoint, data: processedData, options: options);
        break;
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
    
    return fromJson != null ? fromJson(response.data) : response.data;
  }

  Future<T> _post<T>(String endpoint, dynamic data, T Function(Map<String, dynamic>) fromJson, 
      {String? token}) async => _request('POST', endpoint, data: data, fromJson: fromJson, token: token);
  Future<T> _get<T>(String endpoint, T Function(Map<String, dynamic>) fromJson, 
      {String? token, Map<String, dynamic>? queryParams}) async => 
      _request('GET', endpoint, queryParams: queryParams, fromJson: fromJson, token: token);
  Future<T> _patch<T>(String endpoint, dynamic data, T Function(Map<String, dynamic>) fromJson, 
      {String? token}) async => _request('PATCH', endpoint, data: data, fromJson: fromJson, token: token);
  Future<void> _postVoid(String endpoint, dynamic data, {String? token}) async => 
      _request<void>('POST', endpoint, data: data, token: token);
  Future<void> _delete(String endpoint, {String? token, dynamic data}) async => 
      _request<void>('DELETE', endpoint, data: data, token: token);

  Future<AuthResult> login(LoginRequest request) => _post('/users/login/', request, AuthResult.fromJson);
  Future<void> logout(String token, LogoutRequest request) => _postVoid('/users/logout/', request, token: token);
  Future<AuthResult> facebookLogin(SocialLoginRequest request) => _post('/auth/facebook/login/', request, AuthResult.fromJson);
  Future<AuthResult> googleLogin(SocialLoginRequest request) => _post('/auth/google/login/', request, AuthResult.fromJson);

  Future<void> forgotPassword(ForgotPasswordRequest request) => _postVoid('/users/forgot_password/', request);
  Future<void> forgotChangePassword(ChangePasswordRequest request) => _postVoid('/users/forgot_change_password/', request);
  Future<void> sendSignupEmailOtp(EmailOtpRequest request) => _postVoid('/users/signup_email_otp/', request);
  Future<AuthResult> signupWithOtp(SignupWithOtpRequest request) => _post('/users/signup/', request, AuthResult.fromJson);
  Future<void> facebookLink(String token, SocialLinkRequest request) => 
      _postVoid('/auth/facebook/link/', request, token: token);
  Future<void> googleLink(String token, SocialLinkRequest request) => 
      _postVoid('/auth/google/link/', request, token: token);

  Future<UserResponse> getUser(String token) => _get('/users/get_user/', UserResponse.fromJson, token: token);
  Future<void> userPasswordChange(String token, PasswordChangeRequest request) => 
      _postVoid('/users/user_password_change/', request, token: token);
  Future<FriendsResponse> getFriends(String token) => _get('/users/get_friends/', FriendsResponse.fromJson, token: token);

  Future<MessageResponse> sendFriendRequest(String userId, String token) => 
      _post('/users/send_friend_request/$userId/', {}, MessageResponse.fromJson, token: token);
  Future<MessageResponse> acceptFriendRequest(String friendshipId, String token) => 
      _post('/users/accept_friend_request/$friendshipId/', {}, MessageResponse.fromJson, token: token);
  Future<MessageResponse> rejectFriendRequest(String friendshipId, String token) => 
      _post('/users/reject_friend_request/$friendshipId/', {}, MessageResponse.fromJson, token: token);
  Future<void> removeFriend(String userId, String token) => _postVoid('/users/remove_friend/$userId/', {}, token: token);

  Future<void> logActivity(String token, ActivityLogRequest request) => 
      _postVoid('/users/log_activity/', request, token: token);

  Future<FriendInvitationsResponse> getReceivedInvitations(String token) => 
      _get('/users/invitations/received/', FriendInvitationsResponse.fromJson, token: token);
  Future<FriendInvitationsResponse> getSentInvitations(String token) => 
      _get('/users/invitations/sent/', FriendInvitationsResponse.fromJson, token: token);

  Future<Map<String, dynamic>> checkEmail(String email) async {
    return (await _dio.post('/users/check_email/', data: {'email': email})).data;
  }

  Future<ProfileByIdResponse> getProfileById(String userId, String token) => 
      _get('/profile/$userId/', ProfileByIdResponse.fromJson, token: token);
  Future<ProfileResponse> getMyProfile(String token) => 
      _get('/profile/me/', ProfileResponse.fromJson, token: token);
  Future<void> updateProfile(String token, Map<String, dynamic> data) => 
      _request<void>('PATCH', '/profile/me/', data: data, token: token, debug: true);
  Future<ProfileResponse> updateProfileFull(String token, ProfileUpdateRequest request) => 
      _patch('/profile/me/', request, ProfileResponse.fromJson, token: token);

  Future<List<Map<String, dynamic>>> getMusicPreferences(String token) async => 
      ((await _dio.get('/profile/music-preferences/', 
      options: Options(headers: {'Authorization': 'Token $token'}))).data as List<dynamic>)
      .cast<Map<String, dynamic>>();
  Future<void> deleteAvatar(String token) => _delete('/profile/me/avatar/', token: token);

  void _addProfileFieldsToFormData(FormData formData, {String? name, String? location, 
      String? bio, String? phone, String? friendInfo, String? avatarVisibility, 
      String? nameVisibility, String? locationVisibility, String? bioVisibility, 
      String? phoneVisibility, String? friendInfoVisibility, String? musicPreferencesVisibility, 
      List<int>? musicPreferencesIds}) {
    <String, String?>{
      'name': name, 'location': location, 'bio': bio, 'phone': phone, 'friend_info': friendInfo,
      'avatar_visibility': avatarVisibility, 'name_visibility': nameVisibility,
      'location_visibility': locationVisibility, 'bio_visibility': bioVisibility,
      'phone_visibility': phoneVisibility, 'friend_info_visibility': friendInfoVisibility,
      'music_preferences_visibility': musicPreferencesVisibility
    }
      .forEach((k, v) => v != null ? formData.fields.add(MapEntry(k, v)) : null);
    musicPreferencesIds?.forEach((id) => formData.fields.add(MapEntry('music_preferences_ids', id.toString())));
  }

  Future<ProfileResponse> _updateProfileWithFormData(String token, FormData formData, [bool debug = false]) async {
    final response = await _dio.patch('/profile/me/', data: formData, 
        options: Options(headers: {'Authorization': 'Token $token'}, contentType: 'multipart/form-data'));
    return ProfileResponse.fromJson(response.data);
  }

  Future<ProfileResponse> updateProfileWithFile(String token, {String? avatarPath, String? name, 
      String? location, String? bio, String? phone, String? friendInfo, List<int>? musicPreferencesIds, 
      String? avatarVisibility, String? nameVisibility, String? locationVisibility, String? bioVisibility, 
      String? phoneVisibility, String? friendInfoVisibility, String? musicPreferencesVisibility}) async {
    final formData = FormData();
    if (avatarPath != null) {
      formData.files.add(MapEntry('avatar', await MultipartFile.fromFile(avatarPath)));
    }
    _addProfileFieldsToFormData(formData, name: name, location: location, bio: bio, phone: phone, friendInfo: friendInfo, 
      avatarVisibility: avatarVisibility, nameVisibility: nameVisibility, locationVisibility: locationVisibility, 
      bioVisibility: bioVisibility, phoneVisibility: phoneVisibility, friendInfoVisibility: friendInfoVisibility, 
      musicPreferencesVisibility: musicPreferencesVisibility, musicPreferencesIds: musicPreferencesIds);
    return _updateProfileWithFormData(token, formData);
  }

  Future<ProfileResponse> updateProfileWithFileWeb(String token, {List<int>? avatarBytes, 
      String? mimeType, String? name, String? location, String? bio, String? phone, String? friendInfo, 
      List<int>? musicPreferencesIds, String? avatarVisibility, String? nameVisibility, 
      String? locationVisibility, String? bioVisibility, String? phoneVisibility, 
      String? friendInfoVisibility, String? musicPreferencesVisibility}) async {
    final formData = FormData();
    if (avatarBytes != null) {
      formData.files.add(MapEntry('avatar', 
          MultipartFile.fromBytes(avatarBytes, filename: 'avatar.jpg', 
          contentType: DioMediaType.parse(mimeType ?? 'image/jpeg'))));
    }
    _addProfileFieldsToFormData(formData, name: name, location: location, bio: bio, phone: phone, friendInfo: friendInfo,
      avatarVisibility: avatarVisibility, nameVisibility: nameVisibility, locationVisibility: locationVisibility,
      bioVisibility: bioVisibility, phoneVisibility: phoneVisibility, friendInfoVisibility: friendInfoVisibility,
      musicPreferencesVisibility: musicPreferencesVisibility, musicPreferencesIds: musicPreferencesIds);
    return _updateProfileWithFormData(token, formData, true);
  }

  Future<DeezerSearchResponse> searchDeezerTracks(String query) => _get('/deezer/search/', DeezerSearchResponse.fromJson, queryParams: {'q': query});
  Future<DeezerSearchResponse> searchTracks(String query, String token) => 
      _get('/tracks/search/', DeezerSearchResponse.fromJson, token: token, queryParams: {'query': query});
  Future<Track?> getDeezerTrack(String trackId, String token) async { 
    try { 
      return await _get('/deezer/track/${trackId.startsWith('deezer_') ? trackId.substring(7) : trackId}/', 
          Track.fromJson, token: token); 
    } catch (e) { 
      return null; 
    } 
  }
  Future<Map<String, dynamic>> addTrackFromDeezer(String trackId, String token) => _post('/tracks/add_from_deezer/$trackId/', {}, (data) => data, token: token);

  Future<PlaylistsResponse> getSavedPlaylists(String token) => 
      _get('/playlists/saved_playlists/', PlaylistsResponse.fromJson, token: token);
  Future<PlaylistsResponse> getPublicPlaylists(String token) => 
      _get('/playlists/public_playlists/', PlaylistsResponse.fromJson, token: token);
  Future<PlaylistDetailResponse> getPlaylist(String id, String token) => 
      _get('/playlists/playlists/$id', PlaylistDetailResponse.fromJson, token: token);

  Future<CreatePlaylistResponse> createPlaylist(String token, CreatePlaylistRequest request) async => 
      CreatePlaylistResponse.fromJson((await _dio.post('/playlists/playlists', data: request.toJson(), 
      options: Options(headers: {'Authorization': 'Token $token'}))).data);

  Future<void> updatePlaylist(String playlistId, String token, UpdatePlaylistRequest request) => 
      _request<void>('PATCH', '/playlists/update_playlist/$playlistId', data: request, token: token, debug: true);

  Future<void> changePlaylistVisibility(String playlistId, String token, VisibilityRequest request) => 
      _postVoid('/playlists/$playlistId/change-visibility/', request, token: token);
  Future<void> inviteUserToPlaylist(String playlistId, String token, InviteUserRequest request) => 
      _postVoid('/playlists/$playlistId/invite-user/', request, token: token);
  Future<PlaylistLicenseResponse> getPlaylistLicense(String playlistId, String token) => 
      _get('/playlists/$playlistId/license/', PlaylistLicenseResponse.fromJson, token: token);
  Future<PlaylistLicenseResponse> updatePlaylistLicense(String playlistId, String token, 
      PlaylistLicenseRequest request) => _patch('/playlists/$playlistId/license/', request, 
      PlaylistLicenseResponse.fromJson, token: token);
  Future<PlaylistTracksResponse> getPlaylistTracks(String playlistId, String token) => 
      _get('/playlists/playlist/$playlistId/tracks/', PlaylistTracksResponse.fromJson, token: token);
  Future<void> addTrackToPlaylist(String playlistId, String token, AddTrackRequest request) => 
      _postVoid('/playlists/$playlistId/add/', request, token: token);

  Future<void> removeTrackFromPlaylist(String playlistId, String trackId, String token) async {
    final tracksResponse = await getPlaylistTracks(playlistId, token);
    PlaylistTrack? targetTrack;
    
    for (final track in tracksResponse.tracks) {
      if (track.trackId == trackId) {
        targetTrack = track;
        break;
      }
    }
    
    if (targetTrack == null) {
      throw Exception('Track not found in playlist');
    }
    
    final idToUse = targetTrack.playlistTrackId ?? trackId;
    
    int? parsedId;
    try {
      parsedId = int.parse(idToUse);
    } catch (e) {
      throw Exception('Invalid ID format: $idToUse');
    }
    
    return _postVoid('/playlists/playlists/$playlistId/remove_tracks', {'track_id': parsedId}, token: token);
  }
  Future<void> moveTrackInPlaylist(String playlistId, String token, MoveTrackRequest request) => 
      _postVoid('/playlists/$playlistId/move-track/', request, token: token);

  Future<void> deletePlaylist(String playlistId, String token) => 
      _postVoid('/playlists/delete_playlist/$playlistId', {}, token: token);
  
  Future<PlaylistsResponse> getSavedEvents(String token) => 
      _get('/playlists/saved_events/', PlaylistsResponse.fromJson, token: token);
  
  Future<PlaylistsResponse> getPublicEvents(String token) => 
      _get('/playlists/public_events/', PlaylistsResponse.fromJson, token: token);
  Future<VoteResponse> voteForTrack(String playlistId, String token, VoteRequest request) => 
      _post('/playlists/$playlistId/tracks/vote/', request, VoteResponse.fromJson, token: token);

  Future<BatchAddResult> addMultipleTracksToPlaylist({required String playlistId, 
      required List<String> trackIds, required String token, String? deviceUuid}) async {
    int successCount = 0, duplicateCount = 0, failureCount = 0;
    List<String> errors = [];
    
    for (String trackId in trackIds) {
      try {
        await addTrackToPlaylist(playlistId, token, 
            AddTrackRequest(trackId: trackId, deviceUuid: deviceUuid));
        successCount++;
      } catch (e) {
        if (e.toString().contains('already exists') || e.toString().contains('duplicate')) {
          duplicateCount++;
        } else {
          failureCount++;
          errors.add(e.toString());
        }
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    return BatchAddResult(totalTracks: trackIds.length, successCount: successCount, 
        duplicateCount: duplicateCount, failureCount: failureCount, errors: errors);
  }

  Future<List<Map<String, dynamic>>> getRandomTracks({int count = 10}) async {
    try {
      final response = await _dio.get('/tracks/random/', queryParameters: {'count': count});
      return (response.data as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to get random tracks: $e');
    }
  }

  String get baseUrl => _dio.options.baseUrl;
  
  void dispose() {
    _rateMonitor.dispose();
  }
}

class ApiRateMonitorService {
  static const int _maxRequestsPerMinute = 60;
  static const Duration _windowDuration = Duration(minutes: 1);
  
  final List<DateTime> _requestTimestamps = [];
  Timer? _cleanupTimer;
  
  ApiRateMonitorService() {
    _cleanupTimer = Timer.periodic(const Duration(seconds: 30), (_) => _cleanup());
  }
  
  bool canMakeRequest() {
    _cleanup();
    return _requestTimestamps.length < _maxRequestsPerMinute;
  }
  
  void recordRequest() {
    _requestTimestamps.add(DateTime.now());
    AppLogger.debug('API request recorded. Total in window: ${_requestTimestamps.length}', 'ApiRateMonitorService');
  }
  
  int get remainingRequests {
    _cleanup();
    return _maxRequestsPerMinute - _requestTimestamps.length;
  }
  
  Duration? get timeUntilReset {
    if (_requestTimestamps.isEmpty) return null;
    final oldestRequest = _requestTimestamps.first;
    final resetTime = oldestRequest.add(_windowDuration);
    final now = DateTime.now();
    if (resetTime.isAfter(now)) {
      return resetTime.difference(now);
    }
    return null;
  }
  
  void _cleanup() {
    final cutoff = DateTime.now().subtract(_windowDuration);
    _requestTimestamps.removeWhere((timestamp) => timestamp.isBefore(cutoff));
  }
  
  void dispose() {
    _cleanupTimer?.cancel();
  }
  
  Map<String, dynamic> getStats() {
    _cleanup();
    return {
      'currentRequests': _requestTimestamps.length,
      'maxRequests': _maxRequestsPerMinute,
      'remainingRequests': remainingRequests,
      'timeUntilReset': timeUntilReset?.inSeconds,
    };
  }
  
  void startMonitoring() {
    AppLogger.debug('API rate monitoring started', 'ApiRateMonitorService');
  }
  
  void recordApiCall() {
    recordRequest();
  }
}

class ActivityService {
  final ApiService _api = getIt<ApiService>();

  Future<void> logUserActivity({
    required String action,
    required String token,
    String? details,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _api.logActivity(token, ActivityLogRequest(
        action: action,
        details: details,
        metadata: metadata,
      ));
    } catch (e) {
      AppLogger.error('Failed to log user activity', e, null, 'ActivityService');
    }
  }

  Future<void> _logWithToken(String action, String? details, String token, Map<String, dynamic>? metadata) =>
    logUserActivity(action: action, token: token, details: details, metadata: metadata);

  Future<void> logButtonClick(String buttonName, String token, {Map<String, dynamic>? metadata}) =>
    _logWithToken('button_click', buttonName, token, metadata);

  Future<void> logScreenView(String screenName, String token, {Map<String, dynamic>? metadata}) =>
    _logWithToken('screen_view', screenName, token, metadata);

  Future<void> logPlaylistAction(String action, String playlistId, String token, {Map<String, dynamic>? metadata}) =>
    _logWithToken('playlist_$action', playlistId, token, metadata);

  Future<void> logTrackAction(String action, String trackId, String token, {Map<String, dynamic>? metadata}) =>
    _logWithToken('track_$action', trackId, token, metadata);

  Future<void> logActivity({
    required String action,
    String? details,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final token = getIt<AuthProvider>().token;
      if (token != null) {
        await logUserActivity(
          action: action,
          token: token,
          details: details,
          metadata: metadata,
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to log activity: $e');
    }
  }

  Future<void> logPlaylistActionAuto(String action, String playlistId, {Map<String, dynamic>? metadata}) =>
    logActivity(action: 'playlist_$action', details: playlistId, metadata: metadata);

  Future<void> logTrackActionAuto(String action, String trackId, {Map<String, dynamic>? metadata}) =>
    logActivity(action: 'track_$action', details: trackId, metadata: metadata);
}
