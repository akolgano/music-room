// lib/services/api_service.dart
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/models.dart';
import '../models/api_models.dart';

class ApiService {
  final Dio _dio;

  ApiService([Dio? dio]) : _dio = dio ?? _createConfiguredDio();

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

    dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true, 
      compact: true, 
      maxWidth: 120,
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          print('Unauthorized request detected - should trigger logout');
        }
        handler.next(error);
      },
    ));

    return dio;
  }

  Future<T> _post<T>(String endpoint, dynamic data, T Function(Map<String, dynamic>) fromJson, {String? token}) async {
    final response = await _dio.post(endpoint, 
      data: data?.toJson?.call() ?? data,
      options: token != null ? Options(headers: {'Authorization': token}) : null
    );
    return fromJson(response.data);
  }

  Future<T> _get<T>(String endpoint, T Function(Map<String, dynamic>) fromJson, {String? token, Map<String, dynamic>? queryParams}) async {
    final response = await _dio.get(endpoint,
      queryParameters: queryParams,
      options: token != null ? Options(headers: {'Authorization': token}) : null
    );
    return fromJson(response.data);
  }

  Future<T> _patch<T>(String endpoint, dynamic data, T Function(Map<String, dynamic>) fromJson, {String? token}) async {
    final response = await _dio.patch(endpoint,
      data: data?.toJson?.call() ?? data,
      options: token != null ? Options(headers: {'Authorization': token}) : null
    );
    return fromJson(response.data);
  }

  Future<void> _postVoid(String endpoint, dynamic data, {String? token}) async {
    await _dio.post(endpoint,
      data: data?.toJson?.call() ?? data,
      options: token != null ? Options(headers: {'Authorization': token}) : null
    );
  }

  Future<void> _delete(String endpoint, {String? token, dynamic data}) async {
    await _dio.delete(endpoint, 
      data: data?.toJson?.call() ?? data,
      options: token != null ? Options(headers: {'Authorization': token}) : null
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

  Future<Map<String, dynamic>> getUserData(String? token) => 
      _get('/users/get_user/', (data) => data, token: token);

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

  Future<Map<String, dynamic>> getProfileData(String token) => 
      _get('/profile/profile/', (data) => data, token: token);

  Future<void> updateProfile(String token, Map<String, dynamic> data) => 
      _postVoid('/profile/profile/update/', data, token: token);

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
    final response = await _dio.post('/playlists/playlists', data: request.toJson(), 
      options: Options(headers: {'Authorization': token})
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

  Future<DeviceResponse> registerDevice(String token, RegisterDeviceRequest request) => 
      _post('/devices/register/', request, DeviceResponse.fromJson, token: token);

  Future<DevicesResponse> getUserDevices(String token) => 
      _get('/devices/', DevicesResponse.fromJson, token: token);

  Future<DeviceResponse> getDeviceInfo(String deviceUuid, String token) => 
      _get('/devices/$deviceUuid/', DeviceResponse.fromJson, token: token);

  Future<void> updateDeviceStatus(String deviceUuid, String token, Map<String, dynamic> data) => 
      _postVoid('/devices/$deviceUuid/status/', data, token: token);

  Future<void> delegateDeviceControl(String token, DelegateControlRequest request) => 
      _postVoid('/devices/delegate/', request, token: token);

  Future<PermissionResponse> checkDevicePermission(String deviceUuid, String token) => 
      _get('/devices/$deviceUuid/permission/', PermissionResponse.fromJson, token: token);

  Future<BatchAddResult> addMultipleTracksToPlaylist({
    required String playlistId,
    required List<String> trackIds,
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
        if (e.toString().contains('already exists') || e.toString().contains('duplicate')) {
          duplicateCount++;
        } else {
          failureCount++;
          errors.add(e.toString());
        }
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return BatchAddResult(
      totalTracks: totalTracks,
      successCount: successCount, duplicateCount: duplicateCount, failureCount: failureCount, errors: errors,
    );
  }

  String _extractErrorMessage(DioException error) {
    if (error.response?.data is Map<String, dynamic>) {
      final data = error.response!.data as Map<String, dynamic>;
      if (data.containsKey('error')) return data['error'].toString();
      if (data.containsKey('detail')) return data['detail'].toString();
      if (data.containsKey('message')) return data['message'].toString();
    }
    return error.message ?? 'Unknown error occurred';
  }

  String get baseUrl => _dio.options.baseUrl;

  void updateAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Token $token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
}
