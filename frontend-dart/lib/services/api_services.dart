import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/music_models.dart';
import '../models/api_models.dart';
import 'apimonitor_services.dart';

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
        PrettyDioLogger(
            requestHeader: true, requestBody: true, responseBody: true, 
            responseHeader: false, error: true, compact: true, maxWidth: 120),
        InterceptorsWrapper(onRequest: (options, handler) => handler.next(options), onError: (error, handler) {
          handler.next(error);
        })
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
    
    final options = token != null ? Options(headers: {'Authorization': 'Token $token'}) : null;
    dynamic processedData;
    try {
      processedData = data?.toJson?.call() ?? data;
    } catch (e) {
      processedData = data;
    }
    
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
