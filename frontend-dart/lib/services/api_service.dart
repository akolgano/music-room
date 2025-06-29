// lib/services/api_service.dart
import 'package:dio/dio.dart';
import '../models/models.dart';
import '../models/api_models.dart';

class ApiService {
  final Dio _dio;
  
  ApiService([Dio? dio]) : _dio = dio ?? Dio() {
    if (_dio.options.headers['Content-Type'] == null) {
      _dio.options.headers['Content-Type'] = 'application/json';
    }
    if (_dio.options.headers['Accept'] == null) {
      _dio.options.headers['Accept'] = 'application/json';
    }
    if (_dio.options.baseUrl.isEmpty) {
      _dio.options.baseUrl = 'http://localhost:8000';
      print('ApiService: Base URL was empty, hardcoded to: http://localhost:8000');
    }
    print('ApiService: Initialized with base URL: "${_dio.options.baseUrl}"');
  }

  Future<T> _post<T>(String endpoint, dynamic data, T Function(Map<String, dynamic>) fromJson, {String? token}) async {
    _validateAndLogRequest('POST', endpoint);
    final response = await _dio.post(endpoint, 
      data: data?.toJson?.call() ?? data,
      options: token != null ? Options(headers: {'Authorization': token}) : null
    );
    return fromJson(response.data);
  }

  Future<T> _get<T>(String endpoint, T Function(Map<String, dynamic>) fromJson, {String? token, Map<String, dynamic>? queryParams}) async {
    _validateAndLogRequest('GET', endpoint);
    final response = await _dio.get(endpoint,
      queryParameters: queryParams,
      options: token != null ? Options(headers: {'Authorization': token}) : null
    );
    _validateResponse(response, endpoint);
    return fromJson(response.data);
  }

  Future<T> _patch<T>(String endpoint, dynamic data, T Function(Map<String, dynamic>) fromJson, {String? token}) async {
    _validateAndLogRequest('PATCH', endpoint);
    final response = await _dio.patch(endpoint,
      data: data?.toJson?.call() ?? data,
      options: token != null ? Options(headers: {'Authorization': token}) : null
    );
    return fromJson(response.data);
  }

  Future<void> _postVoid(String endpoint, dynamic data, {String? token}) async {
    _validateAndLogRequest('POST', endpoint);
    await _dio.post(endpoint,
      data: data?.toJson?.call() ?? data,
      options: token != null ? Options(headers: {'Authorization': token}) : null
    );
  }

  Future<void> _delete(String endpoint, {String? token, dynamic data}) async {
    _validateAndLogRequest('DELETE', endpoint);
    await _dio.delete(endpoint, 
      data: data?.toJson?.call() ?? data,
      options: token != null ? Options(headers: {'Authorization': token}) : null
    );
  }

  void _validateAndLogRequest(String method, String endpoint) {
    final baseUrl = _dio.options.baseUrl;
    final fullUrl = baseUrl + endpoint;
    print('ApiService: $method $endpoint');
    print('   Base URL: "$baseUrl"');
    print('   Full URL: "$fullUrl"');
    if (baseUrl.isEmpty) {
      print('CRITICAL: Base URL is empty!');
      throw Exception('API base URL is not configured');
    }
    if (!fullUrl.startsWith('http')) {
      print('CRITICAL: Full URL does not start with http!');
      throw Exception('Invalid API URL configuration: $fullUrl');
    }
  }

  void _validateResponse(Response response, String endpoint) {
    print('ApiService: Response ${response.statusCode} for $endpoint');
    if (response.data is String && response.data.toString().contains('<!DOCTYPE html>')) {
      print('ERROR: Received HTML instead of JSON from $endpoint');
      print('   This usually means the request is not reaching the Django backend.');
      throw Exception('Received HTML response instead of JSON - API routing issue');
    }
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

  Future<Map<String, dynamic>> getProfileData(String token) => 
      _get('/profile/profile/', (data) => data, token: token);
      
  Future<void> updateProfile(String token, Map<String, dynamic> data) => 
      _postVoid('/profile/profile/update/', data, token: token);

  Future<DeezerSearchResponse> searchDeezerTracks(String query) => 
      _get('/deezer/search/', DeezerSearchResponse.fromJson, queryParams: {'q': query});
      
  Future<Track?> getDeezerTrack(String trackId, String token) async {
    try {
      print('ApiService: Fetching Deezer track with ID: $trackId');
      String cleanTrackId = trackId;
      if (trackId.startsWith('deezer_')) cleanTrackId = trackId.substring(7);
      final endpoint = '/deezer/track/$cleanTrackId/';
      print('Endpoint: $endpoint');
      final track = await _get(endpoint, Track.fromJson, token: token);
      print('Successfully parsed track: ${track.name} by ${track.artist}');
      return track;
    } catch (e) {
      print('API error getting Deezer track $trackId: $e');
      return null;
    }
  }
  
  Future<void> addTrackFromDeezer(int trackId, String token) => 
      _postVoid('/tracks/add_from_deezer/$trackId/', {}, token: token);
      
  Future<Map<String, dynamic>> searchTracks(String query, String token) => 
      _get('/tracks/search/', (data) => data, queryParams: {'query': query}, token: token);

  Future<PlaylistsResponse> getSavedPlaylists(String token) => 
      _get('/playlists/saved_playlists/', PlaylistsResponse.fromJson, token: token);
      
  Future<PlaylistsResponse> getPublicPlaylists(String token) => 
      _get('/playlists/public_playlists/', PlaylistsResponse.fromJson, token: token);
      
  Future<PlaylistDetailResponse> getPlaylist(String id, String token) => 
      _get('/playlists/playlists/$id', PlaylistDetailResponse.fromJson, token: token);
      
  Future<CreatePlaylistResponse> createPlaylist(String token, CreatePlaylistRequest request) async {
    try {
      final response = await _dio.post('/playlists/playlists', 
        data: request.toJson(), 
        options: Options(headers: {'Authorization': token})
      );
      return CreatePlaylistResponse.fromJson(response.data);
    } catch (e) {
      print('Playlist creation error: $e'); 
      rethrow;
    }
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
}
