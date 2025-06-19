// lib/services/api_service.dart
import 'package:dio/dio.dart';
import '../models/models.dart';
import '../models/api_models.dart';

class ApiService {
  final Dio _dio;

  ApiService([Dio? dio]) : _dio = dio ?? Dio() {
    _dio.options.headers = {'Content-Type': 'application/json'};
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

  Future<void> _postVoid(String endpoint, dynamic data, {String? token}) async {
    await _dio.post(endpoint,
      data: data?.toJson?.call() ?? data,
      options: token != null ? Options(headers: {'Authorization': token}) : null
    );
  }

  Future<void> _delete(String endpoint, {String? token}) async {
    await _dio.delete(endpoint, options: token != null ? Options(headers: {'Authorization': token}) : null);
  }

  Future<AuthResult> login(LoginRequest request) => _post('/users/login/', request, AuthResult.fromJson);
  Future<AuthResult> signup(SignupRequest request) => _post('/users/signup/', request, AuthResult.fromJson);
  Future<void> logout(String token, LogoutRequest request) => _postVoid('/users/logout/', request, token: token);
  Future<AuthResult> facebookLogin(SocialLoginRequest request) => _post('/users/facebook_login/', request, AuthResult.fromJson);
  Future<AuthResult> googleLogin(SocialLoginRequest request) => _post('/users/google_login/', request, AuthResult.fromJson);
  Future<void> forgotPassword(ForgotPasswordRequest request) => _postVoid('/users/forgot_password/', request);
  Future<void> forgotChangePassword(ChangePasswordRequest request) => _postVoid('/users/forgot_change_password/', request);
  Future<void> sendSignupEmailOtp(EmailOtpRequest request) => _postVoid('/users/signup_email_otp/', request);
  Future<AuthResult> signupWithOtp(SignupWithOtpRequest request) => _post('/users/signup/', request, AuthResult.fromJson);

  Future<PlaylistsResponse> getSavedPlaylists(String token) => _get('/playlists/saved_playlists/', PlaylistsResponse.fromJson, token: token);
  Future<PlaylistsResponse> getPublicPlaylists(String token) => _get('/playlists/public_playlists/', PlaylistsResponse.fromJson, token: token);
  Future<PlaylistDetailResponse> getPlaylist(String id, String token) => _get('/playlists/playlists/$id', PlaylistDetailResponse.fromJson, token: token);
  
  Future<CreatePlaylistResponse> createPlaylist(String token, CreatePlaylistRequest request) async {
    try {
      final response = await _dio.post('/playlists/playlists', data: request.toJson(), options: Options(headers: {'Authorization': token}));
      return CreatePlaylistResponse.fromJson(response.data);
    } catch (e) {
      print('Playlist creation error: $e'); 
      rethrow;
    }
  }

  Future<void> updatePlaylist(String id, String token, UpdatePlaylistRequest request) async {
    throw UnimplementedError('Update playlist endpoint not implemented in backend');
  }

  Future<void> changePlaylistVisibility(String playlistId, String token, VisibilityRequest request) => 
      _postVoid('/playlists/$playlistId/change-visibility/', request, token: token);

  Future<void> inviteUserToPlaylist(String playlistId, String token, InviteUserRequest request) => 
      _postVoid('/playlists/$playlistId/invite-user/', request, token: token);

  Future<TrackSearchResponse> searchTracks(String query) => _get('/tracks/search/', TrackSearchResponse.fromJson, queryParams: {'query': query});
  Future<DeezerSearchResponse> searchDeezerTracks(String query) => _get('/deezer/search/', DeezerSearchResponse.fromJson, queryParams: {'q': query});
  Future<Track> getDeezerTrack(String trackId) => _get('/deezer/track/$trackId/', Track.fromJson);
  Future<void> addTrackFromDeezer(String token, AddDeezerTrackRequest request) => _postVoid('/deezer/add_from_deezer/', request, token: token);

  Future<void> addTrackFromDeezerToTracks(String trackId, String token) async {
    await _postVoid('/tracks/add_from_deezer/$trackId', null, token: token);
  }

  Future<PlaylistTracksResponse> getPlaylistTracks(String playlistId, String token) => 
      _get('/playlists/playlist/$playlistId/tracks/', PlaylistTracksResponse.fromJson, token: token);

  Future<void> addTrackToPlaylist(String playlistId, String token, AddTrackRequest request) => 
      _postVoid('/playlists/$playlistId/add/', request, token: token);

  Future<void> removeTrackFromPlaylist(String playlistId, String trackId, String token) => 
      _delete('/playlists/$playlistId/remove_tracks', token: token);

  Future<void> moveTrackInPlaylist(String playlistId, String token, MoveTrackRequest request) => 
      _postVoid('/playlists/move-track/', request, token: token);

  Future<FriendsResponse> getFriends(String token) => _get('/users/get_friends/', FriendsResponse.fromJson, token: token);
  Future<PendingRequestsResponse> getPendingFriendRequests(String token) => _get('/users/pending_friend_requests/', PendingRequestsResponse.fromJson, token: token);
  Future<MessageResponse> sendFriendRequest(String token, FriendRequestRequest request) => _post('/users/send_friend_request/', request, MessageResponse.fromJson, token: token);
  Future<MessageResponse> acceptFriendRequest(String token, FriendRequestActionRequest request) => _post('/users/accept_friend_request/', request, MessageResponse.fromJson, token: token);
  Future<MessageResponse> rejectFriendRequest(String token, FriendRequestActionRequest request) => _post('/users/reject_friend_request/', request, MessageResponse.fromJson, token: token);
  Future<void> removeFriend(String token, RemoveFriendRequest request) => _postVoid('/users/remove_friend/', request, token: token);

  Future<UserResponse> getUser(String token) => _get('/users/get_user/', UserResponse.fromJson, token: token);
  Future<Map<String, dynamic>> getUserData(String? token) => _get('/users/get_user/', (data) => data, token: token);
  Future<void> userPasswordChange(String token, PasswordChangeRequest request) => _postVoid('/users/password_change/', request, token: token);
  Future<void> userPasswordChangeData(String? token, String currentPassword, String newPassword) => 
      userPasswordChange(token!, PasswordChangeRequest(currentPassword: currentPassword, newPassword: newPassword));

  Future<ProfilePublicResponse> getProfilePublic(String token) => _get('/profile/public/', ProfilePublicResponse.fromJson, token: token);
  Future<Map<String, dynamic>> getProfilePublicData(String? token) => _get('/profile/public/', (data) => data, token: token);
  Future<ProfilePrivateResponse> getProfilePrivate(String token) => _get('/profile/private/', ProfilePrivateResponse.fromJson, token: token);
  Future<Map<String, dynamic>> getProfilePrivateData(String? token) => _get('/profile/private/', (data) => data, token: token);
  Future<ProfileFriendResponse> getProfileFriend(String token) => _get('/profile/friend/', ProfileFriendResponse.fromJson, token: token);
  Future<Map<String, dynamic>> getProfileFriendData(String? token) => _get('/profile/friend/', (data) => data, token: token);
  Future<ProfileMusicResponse> getProfileMusic(String token) => _get('/profile/music/', ProfileMusicResponse.fromJson, token: token);
  Future<Map<String, dynamic>> getProfileMusicData(String? token) => _get('/profile/music/', (data) => data, token: token);

  Future<void> updateAvatar(String token, AvatarUpdateRequest request) => _postVoid('/profile/avatar/', request, token: token);
  Future<void> updateAvatarData(String? token, String? avatarBase64, String? mimeType) => 
      updateAvatar(token!, AvatarUpdateRequest(avatar: avatarBase64, mimeType: mimeType));

  Future<void> updatePublicBasic(String token, PublicBasicUpdateRequest request) => _postVoid('/profile/public/basic/', request, token: token);
  Future<void> updatePublicBasicData(String? token, String? gender, String? location) => 
      updatePublicBasic(token!, PublicBasicUpdateRequest(gender: gender, location: location));

  Future<void> updatePublicBio(String token, BioUpdateRequest request) => _postVoid('/profile/public/bio/', request, token: token);
  Future<void> updatePublicBioData(String? token, String? bio) => updatePublicBio(token!, BioUpdateRequest(bio: bio));

  Future<void> updatePrivateInfo(String token, PrivateInfoUpdateRequest request) => _postVoid('/profile/private/', request, token: token);
  Future<void> updatePrivateInfoData(String? token, String? firstName, String? lastName, String? phone, String? street, String? country, String? postalCode) => 
      updatePrivateInfo(token!, PrivateInfoUpdateRequest(firstName: firstName, lastName: lastName, phone: phone, street: street, country: country, postalCode: postalCode));

  Future<void> updateFriendInfo(String token, FriendInfoUpdateRequest request) => _postVoid('/profile/friend/', request, token: token);
  Future<void> updateFriendInfoData(String? token, String? dob, List<String>? hobbies, String? friendInfo) => 
      updateFriendInfo(token!, FriendInfoUpdateRequest(dob: dob, hobbies: hobbies, friendInfo: friendInfo));

  Future<void> updateMusicPreferences(String token, MusicPreferencesUpdateRequest request) => _postVoid('/profile/music/', request, token: token);
  Future<void> updateMusicPreferencesData(String? token, List<String>? musicPreferences) => 
      updateMusicPreferences(token!, MusicPreferencesUpdateRequest(musicPreferences: musicPreferences));

  Future<void> facebookLink(String token, SocialLinkRequest request) => _postVoid('/users/facebook_link/', request, token: token);
  Future<void> facebookLinkData(String? token, String accessToken) => facebookLink(token!, SocialLinkRequest(accessToken: accessToken));
  Future<void> googleLink(String token, SocialLinkRequest request) => _postVoid('/users/google_link/', request, token: token);
  Future<void> googleLinkData(String type, String? token, String idToken) => googleLink(token!, SocialLinkRequest(type: type, idToken: idToken));

  Future<DevicesResponse> getUserDevices(String token) => _get('/devices/user/', DevicesResponse.fromJson, token: token);
  Future<DevicesResponse> getAllUserDevices(String token) => _get('/devices/all/', DevicesResponse.fromJson, token: token);
  Future<DeviceResponse> registerDevice(String token, RegisterDeviceRequest request) => _post('/devices/register/', request, DeviceResponse.fromJson, token: token);
  Future<PermissionResponse> checkControlPermission(String deviceUuid, String token) => _get('/devices/$deviceUuid/can-control/', PermissionResponse.fromJson, token: token);
  Future<void> delegateDeviceControl(String token, DelegateControlRequest request) => _postVoid('/devices/delegate/', request, token: token);
}
