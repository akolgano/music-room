import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/music_models.dart';
import '../models/result_models.dart';
import '../models/social_models.dart';
import '../models/api_models.dart';

class ApiService {
  final Dio _dio;

  ApiService([Dio? dio]) : _dio = dio ?? _createConfiguredDio();

  static Dio _createConfiguredDio() {
    final dio = Dio();
    String baseUrl;
    final envBaseUrl = dotenv.env['API_BASE_URL'];
    if (envBaseUrl != null && envBaseUrl.isNotEmpty) {
      baseUrl = envBaseUrl;
    } else {
      baseUrl = 'http://localhost:8000';
    }

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
          if (kDebugMode) {
            debugPrint('[ApiService] Unauthorized request detected - should trigger logout');
          }
        }
        handler.next(error);
      },
    ));

    return dio;
  }

  Options? _createAuthOptions(String? token) {
    return token != null ? Options(headers: {'Authorization': 'Token $token'}) : null;
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

  Future<void> _patchVoid(String endpoint, dynamic data, {String? token}) async {
    if (kDebugMode) {
      debugPrint('[ApiService] _patchVoid called: $endpoint with data: $data');
    }
    await _dio.patch(endpoint,
      data: data,
      options: _createAuthOptions(token)
    );
    if (kDebugMode) {
      debugPrint('[ApiService] _patchVoid completed: $endpoint');
    }
  }

  Future<void> _delete(String endpoint, {String? token, dynamic data}) async {
    await _dio.delete(endpoint, 
      data: data,
      options: _createAuthOptions(token)
    );
  }

  Future<AuthResult> login(LoginRequest request) => _post('/users/login/', request, AuthResult.fromJson);
  Future<void> logout(String token, LogoutRequest request) => _postVoid('/users/logout/', request, token: token);
  Future<AuthResult> facebookLogin(SocialLoginRequest request) => _post('/auth/facebook/login/', request, AuthResult.fromJson);
  Future<AuthResult> googleLogin(SocialLoginRequest request) => _post('/auth/google/login/', request, AuthResult.fromJson);

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

  Future<ProfileByIdResponse> getProfileById(int userId, String token) => 
      _get('/profile/$userId/', ProfileByIdResponse.fromJson, token: token);

  Future<void> updateProfile(String token, Map<String, dynamic> data) => 
      _patchVoid('/profile/me/', data, token: token);

  Future<ProfileResponse> updateProfileFull(String token, ProfileUpdateRequest request) => 
      _patch('/profile/me/', request, ProfileResponse.fromJson, token: token);

  Future<List<Map<String, dynamic>>> getMusicPreferences(String token) async {
    final response = await _dio.get('/profile/music-preferences/', 
      options: Options(headers: {'Authorization': 'Token $token'}));
    return (response.data as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> deleteAvatar(String token) => 
      _delete('/profile/me/avatar/', token: token);

  void _addProfileFieldsToFormData(FormData formData, {
    String? name, String? location, String? bio, String? phone, String? friendInfo,
    String? avatarVisibility, String? nameVisibility, String? locationVisibility,
    String? bioVisibility, String? phoneVisibility, String? friendInfoVisibility,
    String? musicPreferencesVisibility, List<int>? musicPreferencesIds,
  }) {
    final fieldMap = {
      'name': name, 'location': location, 'bio': bio, 'phone': phone, 'friend_info': friendInfo,
      'avatar_visibility': avatarVisibility, 'name_visibility': nameVisibility,
      'location_visibility': locationVisibility, 'bio_visibility': bioVisibility,
      'phone_visibility': phoneVisibility, 'friend_info_visibility': friendInfoVisibility,
      'music_preferences_visibility': musicPreferencesVisibility,
    };
    fieldMap.forEach((key, value) {
      if (value != null) formData.fields.add(MapEntry(key, value));
    });
    if (musicPreferencesIds != null) {
      for (final id in musicPreferencesIds) {
        formData.fields.add(MapEntry('music_preferences_ids', id.toString()));
      }
    }
  }

  Future<ProfileResponse> updateProfileWithFile(String token, {
    String? avatarPath,
    String? name,
    String? location,
    String? bio,
    String? phone,
    String? friendInfo,
    List<int>? musicPreferencesIds,
    String? avatarVisibility,
    String? nameVisibility,
    String? locationVisibility,
    String? bioVisibility,
    String? phoneVisibility,
    String? friendInfoVisibility,
    String? musicPreferencesVisibility,
  }) async {
    final formData = FormData();
    
    if (avatarPath != null) {
      formData.files.add(MapEntry(
        'avatar',
        await MultipartFile.fromFile(avatarPath),
      ));
    }
    
    _addProfileFieldsToFormData(formData, name: name, location: location, bio: bio, phone: phone,
      friendInfo: friendInfo, avatarVisibility: avatarVisibility, nameVisibility: nameVisibility,
      locationVisibility: locationVisibility, bioVisibility: bioVisibility, phoneVisibility: phoneVisibility,
      friendInfoVisibility: friendInfoVisibility, musicPreferencesVisibility: musicPreferencesVisibility,
      musicPreferencesIds: musicPreferencesIds);

    final response = await _dio.patch(
      '/profile/me/',
      data: formData,
      options: Options(
        headers: {'Authorization': 'Token $token'},
        contentType: 'multipart/form-data',
      ),
    );
    
    return ProfileResponse.fromJson(response.data);
  }

  Future<ProfileResponse> updateProfileWithFileWeb(String token, {
    List<int>? avatarBytes,
    String? mimeType,
    String? name,
    String? location,
    String? bio,
    String? phone,
    String? friendInfo,
    List<int>? musicPreferencesIds,
    String? avatarVisibility,
    String? nameVisibility,
    String? locationVisibility,
    String? bioVisibility,
    String? phoneVisibility,
    String? friendInfoVisibility,
    String? musicPreferencesVisibility,
  }) async {
    final formData = FormData();
    
    if (avatarBytes != null) {
      formData.files.add(MapEntry(
        'avatar',
        MultipartFile.fromBytes(
          avatarBytes,
          filename: 'avatar.jpg',
          contentType: DioMediaType.parse(mimeType ?? 'image/jpeg'),
        ),
      ));
    }
    
    _addProfileFieldsToFormData(formData, name: name, location: location, bio: bio, phone: phone,
      friendInfo: friendInfo, avatarVisibility: avatarVisibility, nameVisibility: nameVisibility,
      locationVisibility: locationVisibility, bioVisibility: bioVisibility, phoneVisibility: phoneVisibility,
      friendInfoVisibility: friendInfoVisibility, musicPreferencesVisibility: musicPreferencesVisibility,
      musicPreferencesIds: musicPreferencesIds);

    if (kDebugMode) {
      debugPrint('[ApiService] updateProfileWithFileWeb: Sending multipart form data to /profile/me/');
    }

    final response = await _dio.patch(
      '/profile/me/',
      data: formData,
      options: Options(
        headers: {'Authorization': 'Token $token'},
        contentType: 'multipart/form-data',
      ),
    );
    
    if (kDebugMode) {
      debugPrint('[ApiService] updateProfileWithFileWeb: Response received with status ${response.statusCode}');
    }
    
    return ProfileResponse.fromJson(response.data);
  }

  Future<DeezerSearchResponse> searchDeezerTracks(String query) => 
      _get('/deezer/search/', DeezerSearchResponse.fromJson, queryParams: {'q': query});

  Future<DeezerSearchResponse> searchTracks(String query, String token) => 
      _get('/tracks/search/', DeezerSearchResponse.fromJson, token: token, queryParams: {'query': query});

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

  Future<Map<String, dynamic>> addTrackFromDeezer(String trackId, String token) => 
      _post('/tracks/add_from_deezer/$trackId/', {}, (data) => data, token: token);

  Future<PlaylistsResponse> getSavedPlaylists(String token) => 
      _get('/playlists/saved_playlists/', PlaylistsResponse.fromJson, token: token);

  Future<PlaylistsResponse> getPublicPlaylists(String token) => 
      _get('/playlists/public_playlists/', PlaylistsResponse.fromJson, token: token);

  Future<PlaylistDetailResponse> getPlaylist(String id, String token) => 
      _get('/playlists/playlists/$id', PlaylistDetailResponse.fromJson, token: token);

  Future<CreatePlaylistResponse> createPlaylist(String token, CreatePlaylistRequest request) async {
    final response = await _dio.post('/playlists/playlists', data: request.toJson(), 
      options: Options(headers: {'Authorization': 'Token $token'})
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

  Future<BatchAddResult> addMultipleTracksToPlaylist({required String playlistId, required List<String> trackIds, required String token,
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
      successCount: successCount, 
      duplicateCount: duplicateCount, 
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
}
