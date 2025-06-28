// lib/services/profile_service.dart
import '../services/api_service.dart';
import '../models/api_models.dart';

class ProfileService {
  final ApiService _api;
  ProfileService(this._api);

  Future<UserResponse> getUser(String token) async {
    return await _api.getUser(token); 
  }

  Future<ProfilePublicResponse> getProfilePublic(String token) async {
    return await _api.getProfilePublic(token); 
  }

  Future<ProfilePrivateResponse> getProfilePrivate(String token) async {
    return await _api.getProfilePrivate(token); 
  }

  Future<ProfileFriendResponse> getProfileFriend(String token) async {
    return await _api.getProfileFriend(token); 
  }

  Future<ProfileMusicResponse> getProfileMusic(String token) async {
    return await _api.getProfileMusic(token); 
  }

  Future<void> userPasswordChange(String currentPassword, String newPassword, String token) async {
    final request = PasswordChangeRequest(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    await _api.userPasswordChange(token, request); 
  }

  Future<void> updateAvatar(String? avatarBase64, String? mimeType, String token) async {
    final request = AvatarUpdateRequest(avatar: avatarBase64, mimeType: mimeType);
    await _api.updateAvatar(token, request); 
  }

  Future<void> updatePublicBasic(String? gender, String? location, String token) async {
    final request = PublicBasicUpdateRequest(gender: gender, location: location);
    await _api.updatePublicBasic(token, request); 
  }

  Future<void> updatePublicBio(String? bio, String token) async {
    final request = BioUpdateRequest(bio: bio);
    await _api.updatePublicBio(token, request); 
  }

  Future<void> updatePrivateInfo({
    String? firstName,
    String? lastName,
    String? phone,
    String? street,
    String? country,
    String? postalCode,
    required String token,
  }) async {
    final request = PrivateInfoUpdateRequest(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      street: street,
      country: country,
      postalCode: postalCode,
    );
    await _api.updatePrivateInfo(token, request); 
  }

  Future<void> updateFriendInfo(String? dob, List<String>? hobbies, String? friendInfo, String token) async {
    final request = FriendInfoUpdateRequest(dob: dob, hobbies: hobbies, friendInfo: friendInfo);
    await _api.updateFriendInfo(token, request); 
  }

  Future<void> updateMusicPreferences(List<String>? musicPreferences, String token) async {
    final request = MusicPreferencesUpdateRequest(musicPreferences: musicPreferences);
    await _api.updateMusicPreferences(token, request); 
  }

  Future<void> facebookLink(String accessToken, String token) async {
    final request = SocialLinkRequest(accessToken: accessToken);
    await _api.facebookLink(token, request); 
  }

  Future<void> googleLink(String type, String idToken, String token) async {
    final request = SocialLinkRequest(type: type, idToken: idToken);
    await _api.googleLink(token, request);
  }
}
