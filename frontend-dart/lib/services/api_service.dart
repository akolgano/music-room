// lib/services/api_service.dart
import 'package:dio/dio.dart';
import '../models/models.dart';
import '../models/api_models.dart';

class ApiService {
  final Dio _dio;

  ApiService([Dio? dio]) : _dio = dio ?? Dio() {
    _dio.options.headers = {'Content-Type': 'application/json'};
  }

  Future<AuthResult> login(LoginRequest request) async {
    final response = await _dio.post('/users/login/', data: request.toJson());
    return AuthResult.fromJson(response.data);
  }

  Future<AuthResult> signup(SignupRequest request) async {
    final response = await _dio.post('/users/signup/', data: request.toJson());
    return AuthResult.fromJson(response.data);
  }

  Future<void> logout(String token, LogoutRequest request) async {
    await _dio.post('/users/logout/', 
      data: request.toJson(),
      options: Options(headers: {'Authorization': token})
    );
  }

  Future<AuthResult> facebookLogin(SocialLoginRequest request) async {
    final response = await _dio.post('/users/facebook_login/', data: request.toJson());
    return AuthResult.fromJson(response.data);
  }

  Future<AuthResult> googleLogin(SocialLoginRequest request) async {
    final response = await _dio.post('/users/google_login/', data: request.toJson());
    return AuthResult.fromJson(response.data);
  }

  Future<void> forgotPassword(ForgotPasswordRequest request) async {
    await _dio.post('/users/forgot_password/', data: request.toJson());
  }

  Future<void> forgotChangePassword(ChangePasswordRequest request) async {
    await _dio.post('/users/forgot_change_password/', data: request.toJson());
  }

  Future<PlaylistsResponse> getSavedPlaylists(String token) async {
    final response = await _dio.get('/playlists/saved_playlists/',
      options: Options(headers: {'Authorization': token})
    );
    return PlaylistsResponse.fromJson(response.data);
  }

  Future<PlaylistsResponse> getPublicPlaylists(String token) async {
    final response = await _dio.get('/playlists/public_playlists/',
      options: Options(headers: {'Authorization': token})
    );
    return PlaylistsResponse.fromJson(response.data);
  }

  Future<PlaylistDetailResponse> getPlaylist(String id, String token) async {
    final response = await _dio.get('/playlists/playlists/$id',
      options: Options(headers: {'Authorization': token})
    );
    return PlaylistDetailResponse.fromJson(response.data);
  }

  Future<CreatePlaylistResponse> createPlaylist(String token, CreatePlaylistRequest request) async {
    final response = await _dio.post('/playlists',
      data: request.toJson(),
      options: Options(headers: {'Authorization': token})
    );
    return CreatePlaylistResponse.fromJson(response.data);
  }

  Future<void> updatePlaylist(String id, String token, UpdatePlaylistRequest request) async {
    await _dio.post('/playlists/$id/update/',
      data: request.toJson(),
      options: Options(headers: {'Authorization': token})
    );
  }

  Future<TrackSearchResponse> searchTracks(String query) async {
    final response = await _dio.get('/tracks/search/', queryParameters: {'query': query});
    return TrackSearchResponse.fromJson(response.data);
  }

  Future<DeezerSearchResponse> searchDeezerTracks(String query) async {
    final response = await _dio.get('/deezer/search/', queryParameters: {'q': query});
    return DeezerSearchResponse.fromJson(response.data);
  }

  Future<Track> getDeezerTrack(String trackId) async {
    final response = await _dio.get('/deezer/track/$trackId/');
    return Track.fromJson(response.data);
  }

  Future<void> addTrackFromDeezer(String token, AddDeezerTrackRequest request) async {
    await _dio.post('/deezer/add_track/',
      data: request.toJson(),
      options: Options(headers: {'Authorization': token})
    );
  }

  Future<PlaylistTracksResponse> getPlaylistTracks(String playlistId, String token) async {
    final response = await _dio.get('/playlists/$playlistId/tracks',
      options: Options(headers: {'Authorization': token})
    );
    return PlaylistTracksResponse.fromJson(response.data);
  }

  Future<void> addTrackToPlaylist(String playlistId, String token, AddTrackRequest request) async {
    await _dio.post('/playlists/$playlistId/tracks',
      data: request.toJson(),
      options: Options(headers: {'Authorization': token})
    );
  }

  Future<void> removeTrackFromPlaylist(String playlistId, String trackId, String token) async {
    await _dio.delete('/playlists/$playlistId/tracks/$trackId',
      options: Options(headers: {'Authorization': token})
    );
  }

  Future<void> moveTrackInPlaylist(String playlistId, String token, MoveTrackRequest request) async {
    await _dio.post('/playlists/$playlistId/move_track/',
      data: request.toJson(),
      options: Options(headers: {'Authorization': token})
    );
  }

  Future<void> changePlaylistVisibility(String playlistId, String token, VisibilityRequest request) async {
    await _dio.post('/playlists/$playlistId/visibility/',
      data: request.toJson(),
      options: Options(headers: {'Authorization': token})
    );
  }

  Future<void> inviteUserToPlaylist(String playlistId, String token, InviteUserRequest request) async {
    await _dio.post('/playlists/$playlistId/invite/',
      data: request.toJson(),
      options: Options(headers: {'Authorization': token})
    );
  }

  Future<FriendsResponse> getFriends(String token) async {
    final response = await _dio.get('/users/get_friends/',
      options: Options(headers: {'Authorization': token})
    );
    return FriendsResponse.fromJson(response.data);
  }

  Future<MessageResponse> sendFriendRequest(String token, FriendRequestRequest request) async {
    final response = await _dio.post('/users/send_friend_request/',
      data: request.toJson(),
      options: Options(headers: {'Authorization': token})
    );
    return MessageResponse.fromJson(response.data);
  }

  Future<MessageResponse> acceptFriendRequest(String token, FriendRequestActionRequest request) async {
    final response = await _dio.post('/users/accept_friend_request/',
      data: request.toJson(),
      options: Options(headers: {'Authorization': token})
    );
    return MessageResponse.fromJson(response.data);
  }

  Future<MessageResponse> rejectFriendRequest(String token, FriendRequestActionRequest request) async {
    final response = await _dio.post('/users/reject_friend_request/',
      data: request.toJson(),
      options: Options(headers: {'Authorization': token})
    );
    return MessageResponse.fromJson(response.data);
  }

  Future<void> removeFriend(String token, RemoveFriendRequest request) async {
    await _dio.post('/users/remove_friend/',
      data: request.toJson(),
      options: Options(headers: {'Authorization': token})
    );
  }

  Future<UserResponse> getUser(String token) async {
    final response = await _dio.get('/users/get_user/',
      options: Options(headers: {'Authorization': token})
    );
    return UserResponse.fromJson(response.data);
  }

  Future<Map<String, dynamic>> getUserData(String? token) async {
    final response = await _dio.get('/users/get_user/',
      options: Options(headers: {'Authorization': token})
    );
    return response.data;
  }

  Future<void> userPasswordChange(String token, PasswordChangeRequest request) async {
    await _dio.post('/users/password_change/',
      data: request.toJson(),
      options: Options(headers: {'Authorization': token})
    );
  }

  Future<void> userPasswordChangeData(String? token, String currentPassword, String newPassword) async {
    final request = PasswordChangeRequest(currentPassword: currentPassword, newPassword: newPassword);
    await userPasswordChange(token!, request);
  }

  Future<ProfilePublicResponse> getProfilePublic(String token) async {
    final response = await _dio.get('/profile/public/',
      options: Options(headers: {'Authorization': token})
    );
    return ProfilePublicResponse.fromJson(response.data);
  }

  Future<Map<String, dynamic>> getProfilePublicData(String? token) async {
    final response = await _dio.get('/profile/public/',
      options: Options(headers: {'Authorization': token})
    );
    return response.data;
  }

  Future<ProfilePrivateResponse> getProfilePrivate(String token) async {
    final response = await _dio.get('/profile/private/',
      options: Options(headers: {'Authorization': token})
    );
    return ProfilePrivateResponse.fromJson(response.data);
  }

  Future<Map<String, dynamic>> getProfilePrivateData(String? token) async {
    final response = await _dio.get('/profile/private/',
      options: Options(headers: {'Authorization': token})
    );
    return response.data;
  }

  Future<ProfileFriendResponse> getProfileFriend(String token) async {
    final response = await _dio.get('/profile/friend/',
      options: Options(headers: {'Authorization': token})
    );
    return ProfileFriendResponse.fromJson(response.data);
  }

  Future<Map<String, dynamic>> getProfileFriendData(String? token) async {
    final response = await _dio.get('/profile/friend/',
      options: Options(headers: {'Authorization': token})
    );
    return response.data;
  }

  Future<ProfileMusicResponse> getProfileMusic(String token) async {
    final response = await _dio.get('/profile/music/',
      options: Options(headers: {'Authorization': token})
    );
    return ProfileMusicResponse.fromJson(response.data);
  }

  Future<Map<String, dynamic>> getProfileMusicData(String? token) async {
    final response = await _dio.get('/profile/music/',
      options: Options(headers: {'Authorization': token})
    );
    return response.data;
  }

  Future<void> updateAvatar(String token, AvatarUpdateRequest request) async {
    await _dio.post('/profile/avatar/',
      data: request.toJson(),
      options: Options(headers: {'Authorization': token})
    );
  }

  Future<void> updateAvatarData(String? token, String? avatarBase64, String? mimeType) async {
    final request = AvatarUpdateRequest(avatar: avatarBase64, mimeType: mimeType);
    await updateAvatar(token!, request);
  }

  Future<void> updatePublicBasic(String token, PublicBasicUpdateRequest request) async {
    await _dio.post('/profile/public/basic/',
      data: request.toJson(),
      options: Options(headers: {'Authorization': token})
    );
  }

  Future<void> updatePublicBasicData(String? token, String? gender, String? location) async {
    final request = PublicBasicUpdateRequest(gender: gender, location: location);
    await updatePublicBasic(token!, request);
  }

  Future<void> updatePublicBio(String token, BioUpdateRequest request) async {
    await _dio.post('/profile/public/bio/',
      data: request.toJson(),
      options: Options(headers: {'Authorization': token})
    );
  }

  Future<void> updatePublicBioData(String? token, String? bio) async {
    final request = BioUpdateRequest(bio: bio);
    await updatePublicBio(token!, request);
  }

  Future<void> updatePrivateInfo(String token, PrivateInfoUpdateRequest request) async {
    await _dio.post('/profile/private/',
      data: request.toJson(),
      options: Options(headers: {'Authorization': token})
    );
  }

  Future<void> updatePrivateInfoData(String? token, String? firstName, String? lastName, String? phone, String? street, String? country, String? postalCode) async {
    final request = PrivateInfoUpdateRequest(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      street: street,
      country: country,
      postalCode: postalCode,
    );
    await updatePrivateInfo(token!, request);
  }

  Future<void> updateFriendInfo(String token, FriendInfoUpdateRequest request) async {
    await _dio.post('/profile/friend/', data: request.toJson(), options: Options(headers: {'Authorization': token}));
  }

  Future<void> updateFriendInfoData(String? token, String? dob, List<String>? hobbies, String? friendInfo) async {
    final request = FriendInfoUpdateRequest(dob: dob, hobbies: hobbies, friendInfo: friendInfo);
    await updateFriendInfo(token!, request);
  }

  Future<void> updateMusicPreferences(String token, MusicPreferencesUpdateRequest request) async {
    await _dio.post('/profile/music/', data: request.toJson(), options: Options(headers: {'Authorization': token}));
  }

  Future<void> updateMusicPreferencesData(String? token, List<String>? musicPreferences) async {
    final request = MusicPreferencesUpdateRequest(musicPreferences: musicPreferences);
    await updateMusicPreferences(token!, request);
  }

  Future<void> facebookLink(String token, SocialLinkRequest request) async {
    await _dio.post('/users/facebook_link/',
      data: request.toJson(),
      options: Options(headers: {'Authorization': token})
    );
  }

  Future<void> facebookLinkData(String? token, String accessToken) async {
    final request = SocialLinkRequest(accessToken: accessToken);
    await facebookLink(token!, request);
  }

  Future<void> googleLink(String token, SocialLinkRequest request) async {
    await _dio.post('/users/google_link/',
      data: request.toJson(),
      options: Options(headers: {'Authorization': token})
    );
  }

  Future<void> googleLinkData(String type, String? token, String idToken) async {
    final request = SocialLinkRequest(type: type, idToken: idToken);
    await googleLink(token!, request);
  }

  Future<void> sendSignupEmailOtp(EmailOtpRequest request) async {
    await _dio.post('/users/signup_email_otp/', data: request.toJson());
  }

  Future<AuthResult> signupWithOtp(SignupWithOtpRequest request) async {
    final response = await _dio.post('/users/signup/', data: request.toJson());
    return AuthResult.fromJson(response.data);
  }

  Future<PendingRequestsResponse> getPendingFriendRequests(String token) async {
    final response = await _dio.get('/users/pending_friend_requests/',
      options: Options(headers: {'Authorization': token})
    );
    return PendingRequestsResponse.fromJson(response.data);
  }

  Future<DevicesResponse> getUserDevices(String token) async {
    final response = await _dio.get('/devices/user/',
      options: Options(headers: {'Authorization': token})
    );
    return DevicesResponse.fromJson(response.data);
  }

  Future<DevicesResponse> getAllUserDevices(String token) async {
    final response = await _dio.get('/devices/all/',
      options: Options(headers: {'Authorization': token})
    );
    return DevicesResponse.fromJson(response.data);
  }

  Future<DeviceResponse> registerDevice(String token, RegisterDeviceRequest request) async {
    final response = await _dio.post('/devices/register/',
      data: request.toJson(),
      options: Options(headers: {'Authorization': token})
    );
    return DeviceResponse.fromJson(response.data);
  }

  Future<PermissionResponse> checkControlPermission(String deviceUuid, String token) async {
    final response = await _dio.get('/devices/$deviceUuid/can-control/',
      options: Options(headers: {'Authorization': token})
    );
    return PermissionResponse.fromJson(response.data);
  }

  Future<void> delegateDeviceControl(String token, DelegateControlRequest request) async {
    await _dio.post('/devices/delegate/',
      data: request.toJson(),
      options: Options(headers: {'Authorization': token})
    );
  }
}
