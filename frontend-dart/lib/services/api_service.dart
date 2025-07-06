// lib/services/api_service.dart
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/models.dart';
import '../models/api_models.dart';
import '../models/friend_models.dart';
import '../models/profile_models.dart';

class ApiService {
  final Dio _dio;

  ApiService([Dio? dio]) : _dio = dio ?? _createConfiguredDio();

  Options? _createAuthOptions(String? token) {
    return token != null ? Options(headers: {'Authorization': token}) : null;
  }

  Options _createRequiredAuthOptions(String token) {
    return Options(headers: {'Authorization': token});
  }

  static Dio _createConfiguredDio() {
    final dio = Dio();
    String baseUrl;
    final envBaseUrl = dotenv.env['API_BASE_URL'];
    if (envBaseUrl != null && envBaseUrl.isNotEmpty) baseUrl = envBaseUrl;
    else baseUrl = 'http://localhost:8000';

    if (baseUrl.endsWith('/')) baseUrl = baseUrl.substring(0, baseUrl.length - 1);

    dio.options.baseUrl = baseUrl;
    dio.options.headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};
    dio.options.connectTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 10);
    dio.options.sendTimeout = const Duration(seconds: 10);

    dio.interceptors.add(PrettyDioLogger(requestHeader: true, requestBody: true, responseBody: true,
      responseHeader: false,
      error: true, 
      compact: true, 
      maxWidth: 120,
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) => handler.next(options),
      onError: (error, handler) {
        if (error.response?.statusCode == 401) print('Unauthorized request detected - should trigger logout');
        handler.next(error);
      },
    ));

    return dio;
  }

  Future<T> _post<T>(String endpoint, dynamic data, T Function(Map<String, dynamic>) fromJson, {String? token}) async {
    final response = await _dio.post(endpoint, 
      data: data?.toJson?.call() ?? data,
      options: _createAuthOptions(token)
    );
    return fromJson(response.data);
  }

  Future<T> _get<T>(String endpoint, T Function(Map<String, dynamic>) fromJson, {String? token, Map<String, dynamic>? queryParams}) async {
    final response = await _dio.get(endpoint,
      queryParameters: queryParams,
      options: _createAuthOptions(token)
    );
    return fromJson(response.data);
  }

  Future<T> _patch<T>(String endpoint, dynamic data, T Function(Map<String, dynamic>) fromJson, {String? token}) async {
    final response = await _dio.patch(endpoint,
      data: data?.toJson?.call() ?? data,
      options: _createAuthOptions(token)
    );
    return fromJson(response.data);
  }

  Future<void> _postVoid(String endpoint, dynamic data, {String? token}) async {
    await _dio.post(endpoint,
      data: data?.toJson?.call() ?? data,
      options: _createAuthOptions(token)
    );
  }

  Future<void> _delete(String endpoint, {String? token, dynamic data}) async {
    await _dio.delete(endpoint, 
      data: data?.toJson?.call() ?? data,
      options: _createAuthOptions(token)
    );
  }

  Future<AuthResult> login(LoginRequest request) => 
      _post('/users/login/', request, AuthResult.fromJson);

  Future<void> logout(String token, LogoutRequest request) => 
      _postVoid('/users/logout/', request, token: token);

  Future<AuthResult> facebookLogin(SocialLoginRequest request) => 
      _post('/auth/facebook/login/', request, AuthResult.fromJson);

  Future<AuthResult> googleLogin(SocialLoginRequest request) => 
      _post('/auth/google/login/', request, AuthResult.fromJson);

  Future<void> forgotPassword(ForgotPasswordRequest request) => 
      _postVoid('/users/forgot_password/', request);

  Future<void> forgotChangePassword(ChangePasswordRequest request) => 
      _postVoid('/users/forgot_change_password/', request);

  Future<void> sendSignupEmailOtp(EmailOtpRequest request) => 
      _postVoid('/users/signup_email_otp/', request);

  Future<AuthResult> signupWithOtp(SignupWithOtpRequest request) => 
      _post('/users/signup/', request, AuthResult.fromJson);

  Future<void> facebookLink(String token, SocialLinkRequest request) => 
      _postVoid('/auth/facebook/link/', request, token: token);

  Future<void> googleLink(String token, SocialLinkRequest request) => 
      _postVoid('/auth/google/link/', request, token: token);

  Future<UserResponse> getUser(String token) => 
      _get('/users/get_user/', UserResponse.fromJson, token: token);

  Future<Map<String, dynamic>> getUserData(String? token) async {
    if (token == null || token.isEmpty) throw Exception('Authentication token is required');
    try {
      return await _get('/users/get_user/', (data) => data, token: token);
    } catch (e) {
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        throw Exception('Authentication failed. Please log in again.');
      } else if (e.toString().contains('403') || e.toString().contains('Forbidden')) {
        throw Exception('Access denied. Please check your permissions.');
      } else if (e.toString().contains('404') || e.toString().contains('Not Found')) {
        throw Exception('User data not found.');
      } else if (e.toString().contains('NetworkException') || e.toString().contains('SocketException')) {
        throw Exception('Network error. Please check your internet connection.');
      }
      throw Exception('Failed to load user data: ${e.toString()}');
    }
  }

  Future<void> userPasswordChange(String token, PasswordChangeRequest request) => 
      _postVoid('/users/user_password_change/', request, token: token);

  Future<FriendsResponse> getFriends(String token) => 
      _get('/users/get_friends/', FriendsResponse.fromJson, token: token);

  Future<MessageResponse> sendFriendRequest(int userId, String token) => 
    _post('/users/send_friend_request/$userId/', {}, MessageResponse.fromJson, token: token);

  Future<MessageResponse> acceptFriendRequest(int friendshipId, String token) => 
      _post('/users/accept_friend_request/$friendshipId/', {}, MessageResponse.fromJson, token: token);

  Future<MessageResponse> rejectFriendRequest(int friendshipId, String token) => 
      _post('/users/reject_friend_request/$friendshipId/', {}, MessageResponse.fromJson, token: token);

  Future<void> removeFriend(int userId, String token) => 
      _postVoid('/users/remove_friend/$userId/', {}, token: token);

  Future<FriendInvitationsResponse> getReceivedInvitations(String token) => 
      _get('/users/invitations/received/', FriendInvitationsResponse.fromJson, token: token);

  Future<FriendInvitationsResponse> getSentInvitations(String token) => 
      _get('/users/invitations/sent/', FriendInvitationsResponse.fromJson, token: token);

  Future<DeezerSearchResponse> searchDeezerTracks(String query) => 
      _get('/deezer/search/', DeezerSearchResponse.fromJson, queryParams: {'q': query});

  Future<Track?> getDeezerTrack(String trackId, String token) async {
    try {
      String cleanTrackId = trackId;
      if (trackId.startsWith('deezer_')) cleanTrackId = trackId.substring(7);
      final endpoint = '/deezer/track/$cleanTrackId/';
      return await _get(endpoint, Track.fromJson, token: token);
    } catch (e) {
      return null;
    }
  }

  Future<PlaylistsResponse> getSavedPlaylists(String token) => 
      _get('/playlists/saved_playlists/', PlaylistsResponse.fromJson, token: token);

  Future<PlaylistsResponse> getPublicPlaylists(String token) => 
      _get('/playlists/public_playlists/', PlaylistsResponse.fromJson, token: token);

  Future<PlaylistDetailResponse> getPlaylist(String id, String token) => 
      _get('/playlists/playlists/$id', PlaylistDetailResponse.fromJson, token: token);

  Future<CreatePlaylistResponse> createPlaylist(String token, CreatePlaylistRequest request) async {
    final response = await _dio.post('/playlists/playlists', 
      data: request.toJson(), 
      options: _createRequiredAuthOptions(token)
    );
    return CreatePlaylistResponse.fromJson(response.data);
  }

  Future<void> changePlaylistVisibility(String playlistId, String token, VisibilityRequest request) => 
      _postVoid('/playlists/$playlistId/change-visibility/', request, token: token);

  Future<void> inviteUserToPlaylist(String playlistId, String token, InviteUserRequest request) => 
      _postVoid('/playlists/$playlistId/invite-user/', request, token: token);

  Future<PlaylistLicenseResponse> getPlaylistLicense(String playlistId, String token) => 
      _get('/playlists/$playlistId/license/', PlaylistLicenseResponse.fromJson, token: token);

  Future<PlaylistLicenseResponse> updatePlaylistLicense(String playlistId, String token, PlaylistLicenseRequest request) => 
      _patch('/playlists/$playlistId/license/', request, PlaylistLicenseResponse.fromJson, token: token);

  Future<PlaylistTracksResponse> getPlaylistTracks(String playlistId, String token) => 
      _get('/playlists/playlist/$playlistId/tracks/', PlaylistTracksResponse.fromJson, token: token);

  Future<void> addTrackToPlaylist(String playlistId, String token, AddTrackRequest request) => 
      _postVoid('/playlists/$playlistId/add/', request, token: token);

  Future<void> removeTrackFromPlaylist(String playlistId, String trackId, String token) => 
      _postVoid('/playlists/playlists/$playlistId/remove_tracks', {'track_id': int.parse(trackId)}, token: token);

  Future<void> moveTrackInPlaylist(String playlistId, String token, MoveTrackRequest request) => 
      _postVoid('/playlists/$playlistId/move-track/', request, token: token);

  Future<VoteResponse> voteForTrack(String playlistId, String token, VoteRequest request) => 
      _post('/playlists/$playlistId/tracks/vote/', request, VoteResponse.fromJson, token: token);

  Future<BatchAddResult> addMultipleTracksToPlaylist({required String playlistId, required List<String> trackIds,
    required String token,
    String? deviceUuid,
  }) async {
    int totalTracks = trackIds.length;
    int successCount = 0;
    int duplicateCount = 0;
    int failureCount = 0;
    List<String> errors = [];

    for (String trackId in trackIds) {
      try {
        final request = AddTrackRequest(trackId: trackId, deviceUuid: deviceUuid);
        await addTrackToPlaylist(playlistId, token, request);
        successCount++;
      } catch (e) {
        if (e.toString().contains('already exists') || e.toString().contains('duplicate')) duplicateCount++;
        else {
          failureCount++;
          errors.add(e.toString());
        }
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return BatchAddResult(totalTracks: totalTracks, successCount: successCount, duplicateCount: duplicateCount, 
      failureCount: failureCount, 
      errors: errors,
    );
  }

  String get baseUrl => _dio.options.baseUrl;

  void updateAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Token $token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  Future<Profile> getMyProfile(String token) async {
    if (token.isEmpty) throw Exception('Authentication token is required');
    
    try {
      return await _get('/profile/me/', Profile.fromJson, token: token);
    } catch (e) {
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        throw Exception('Authentication failed. Please log in again.');
      } else if (e.toString().contains('403') || e.toString().contains('Forbidden')) {
        throw Exception('Access denied. Please check your permissions.');
      } else if (e.toString().contains('404') || e.toString().contains('Not Found')) {
        throw Exception('Profile not found. Please contact support.');
      } else if (e.toString().contains('NetworkException') || e.toString().contains('SocketException')) {
        throw Exception('Network error. Please check your internet connection.');
      }
      throw Exception('Failed to load profile: ${e.toString()}');
    }
  }

  Future<Profile> updateMyProfile(String token, ProfileUpdateRequest request) => 
      _putFormData('/profile/me/', request.toFormData(), Profile.fromJson, token: token);

  Future<Profile> patchMyProfile(String token, ProfileUpdateRequest request) => 
      _patchFormData('/profile/me/', request.toFormData(), Profile.fromJson, token: token);

  Future<Map<String, dynamic>> getProfileById(String token, int profileId) => 
      _get('/profile/$profileId/', (data) => data, token: token);

  Future<void> deleteMyAvatar(String token) => 
      _delete('/profile/me/avatar/', token: token);

  Future<List<MusicPreference>> getMusicPreferences(String token) async {
    if (token.isEmpty) {
      throw Exception('Authentication token is required');
    }
    
    try {
      return await _get('/profile/music-preferences/', (data) => 
          (data as List<dynamic>).map((item) => 
              MusicPreference.fromJson(item as Map<String, dynamic>)).toList(), 
          token: token);
    } catch (e) {
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        throw Exception('Authentication failed. Please log in again.');
      } else if (e.toString().contains('404') || e.toString().contains('Not Found')) {
        print('Music preferences endpoint not found, returning empty list');
        return <MusicPreference>[];
      } else if (e.toString().contains('NetworkException') || e.toString().contains('SocketException')) {
        throw Exception('Network error. Please check your internet connection.');
      }
      print('Failed to load music preferences: $e');
      return <MusicPreference>[];
    }
  }

  Future<List<Track>> searchTracks(String query, String token) => 
      _get('/tracks/search/', (data) => 
          (data['tracks'] as List<dynamic>).map((item) => 
              Track.fromJson(item as Map<String, dynamic>)).toList(), 
          token: token, queryParams: {'query': query});

  Future<MessageResponse> addTrackFromDeezer(int trackId, String token) => 
      _post('/tracks/add_from_deezer/$trackId/', {}, MessageResponse.fromJson, token: token);

  Future<T> _putFormData<T>(String endpoint, Map<String, dynamic> formData, T Function(Map<String, dynamic>) fromJson, {String? token}) async {
    final response = await _dio.put(endpoint,
      data: formData,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data', if (token != null) 'Authorization': token},
      ),
    );
    return fromJson(response.data);
  }

  Future<T> _patchFormData<T>(String endpoint, Map<String, dynamic> formData, T Function(Map<String, dynamic>) fromJson, {String? token}) async {
    final response = await _dio.patch(endpoint,
      data: formData,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data', if (token != null) 'Authorization': token},
      ),
    );
    return fromJson(response.data);
  }
}
