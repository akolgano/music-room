// lib/providers/profile_provider.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/service_locator.dart';  
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../core/core.dart';
import '../core/base_provider.dart'; 
import '../models/api_models.dart';

enum VisibilityLevel { public, friends, private }

extension VisibilityLevelExtension on VisibilityLevel {
  String get value {
    switch (this) {
      case VisibilityLevel.public:
        return 'public';
      case VisibilityLevel.friends:
        return 'friends';
      case VisibilityLevel.private:
        return 'private';
    }
  }

  static VisibilityLevel fromString(String? value) {
    switch (value) {
      case 'public':
        return VisibilityLevel.public;
      case 'friends':
        return VisibilityLevel.friends;
      case 'private':
        return VisibilityLevel.private;
      default:
        return VisibilityLevel.public;
    }
  }
}

class ProfileProvider extends BaseProvider { 
  final ApiService _apiService;  

  String? _userId;
  String? _username;
  String? _userEmail;
  String? _socialEmail;
  String? _socialName;
  String? _socialType;
  String? _socialId;
  bool _isPasswordUsable = false;

  String? _avatar;
  String? _name;
  String? _location;
  String? _bio;
  String? _phone;
  String? _friendInfo;
  List<String>? _musicPreferences;
  List<int>? _musicPreferenceIds;

  VisibilityLevel? _avatarVisibility;
  VisibilityLevel? _nameVisibility;
  VisibilityLevel? _locationVisibility;
  VisibilityLevel? _bioVisibility;
  VisibilityLevel? _phoneVisibility;
  VisibilityLevel? _friendInfoVisibility;
  VisibilityLevel? _musicPreferencesVisibility;

  String? get userId => _userId;
  String? get username => _username;
  String? get userEmail => _userEmail;
  String? get socialEmail => _socialEmail;
  String? get socialName => _socialName;
  String? get socialType => _socialType;
  String? get socialId => _socialId;
  bool get isPasswordUsable => _isPasswordUsable;

  String? get avatar => _avatar;
  String? get name => _name;
  String? get location => _location;
  String? get bio => _bio;
  String? get phone => _phone;
  String? get friendInfo => _friendInfo;
  List<String>? get musicPreferences => _musicPreferences;
  List<int>? get musicPreferenceIds => _musicPreferenceIds;

  VisibilityLevel? get avatarVisibility => _avatarVisibility;
  VisibilityLevel? get nameVisibility => _nameVisibility;
  VisibilityLevel? get locationVisibility => _locationVisibility;
  VisibilityLevel? get bioVisibility => _bioVisibility;
  VisibilityLevel? get phoneVisibility => _phoneVisibility;
  VisibilityLevel? get friendInfoVisibility => _friendInfoVisibility;
  VisibilityLevel? get musicPreferencesVisibility => _musicPreferencesVisibility;

  ProfileProvider() : _apiService = getIt<ApiService>();

  void resetValues() {
    _userId = null;
    _username = null;
    _userEmail = null;
    _isPasswordUsable = false;
    _socialType = null;
    _socialEmail = null;
    _socialName = null;
    _socialId = null;
    _avatar = null;
    _name = null;
    _location = null;
    _bio = null;
    _phone = null;
    _friendInfo = null;
    _musicPreferences = null;
    _musicPreferenceIds = null;
    _avatarVisibility = null;
    _nameVisibility = null;
    _locationVisibility = null;
    _bioVisibility = null;
    _phoneVisibility = null;
    _friendInfoVisibility = null;
    _musicPreferencesVisibility = null;
  }

  Future<bool> loadProfile(String? token) async {
    return await executeBool(
      () async {
        resetValues();
        
        final userData = await _apiService.getUserData(token);
        _userId = userData['id'];
        _username = userData['username'];
        _userEmail = userData['email'];
        _isPasswordUsable = userData['is_password_usable'] as bool;

        final hasSocialAccount = userData['has_social_account'] as bool;
        if (hasSocialAccount) {
          final social = userData['social'] as Map<String, dynamic>;
          _socialType = social['type'];
          _socialEmail = social['social_email'];
          _socialName = social['social_name'];
          _socialId = social['social_id'];
        }

        final profileData = await _apiService.getProfileData(token!);
        _avatar = profileData['avatar'];
        _name = profileData['name'];
        _location = profileData['location'];
        _bio = profileData['bio'];
        _phone = profileData['phone'];
        _friendInfo = profileData['friend_info'];

        if (profileData['music_preferences'] != null) {
          _musicPreferences = (profileData['music_preferences'] as List<dynamic>?)?.cast<String>();
        }
        if (profileData['music_preferences_ids'] != null) {
          _musicPreferenceIds = (profileData['music_preferences_ids'] as List<dynamic>?)?.cast<int>();
        }

        _avatarVisibility = VisibilityLevelExtension.fromString(profileData['avatar_visibility']);
        _nameVisibility = VisibilityLevelExtension.fromString(profileData['name_visibility']);
        _locationVisibility = VisibilityLevelExtension.fromString(profileData['location_visibility']);
        _bioVisibility = VisibilityLevelExtension.fromString(profileData['bio_visibility']);
        _phoneVisibility = VisibilityLevelExtension.fromString(profileData['phone_visibility']);
        _friendInfoVisibility = VisibilityLevelExtension.fromString(profileData['friend_info_visibility']);
        _musicPreferencesVisibility = VisibilityLevelExtension.fromString(profileData['music_preferences_visibility']);
      },
      successMessage: 'Profile loaded successfully',
      errorMessage: 'Failed to load profile',
    );
  }

  Future<bool> userPasswordChange(String? token, String currentPassword, String newPassword) async {
    return await executeBool(
      () async {
        await _apiService.userPasswordChange(token!, PasswordChangeRequest(
          currentPassword: currentPassword, 
          newPassword: newPassword
        ));
      },
      successMessage: 'Password changed successfully',
      errorMessage: 'Failed to change password',
    );
  }

  Future<bool> facebookLink(String? token) async {
    return await executeBool(() async {
        final LoginResult result = await FacebookAuth.instance.login();
        if (result.status == LoginStatus.success) {
          final fbAccessToken = result.accessToken!.tokenString;
          final request = SocialLinkRequest(fbAccessToken: fbAccessToken);
          await _apiService.facebookLink(token!, request);
        } else throw Exception("Facebook login failed!");
      },
      successMessage: 'Facebook account linked successfully',
      errorMessage: 'Failed to link Facebook account',
    );
  }

  Future<bool> googleLinkApp(String? token) async {
    return await executeBool(
      () async {
        final googleSignIn = SocialLoginUtils.googleSignInInstance;
        if (googleSignIn == null) throw Exception("Google Sign-In not initialized");
        final GoogleSignInAccount? user = await googleSignIn.signIn();
        if (user == null) throw Exception("Google login failed!");
        final GoogleSignInAuthentication auth = await user.authentication;
        final idToken = auth.idToken;
        if (idToken == null) throw Exception("Google login failed!");
        await _apiService.googleLink(token!, SocialLinkRequest(idToken: idToken, type: 'app'));
      },
      successMessage: 'Google account linked successfully',
      errorMessage: 'Failed to link Google account',
    );
  }

  Future<bool> updateProfile(String? token, {
    String? avatarBase64,
    String? mimeType,
    String? name,
    String? location,
    String? bio,
    String? phone,
    String? friendInfo, 
    List<int>? musicPreferencesIds,
  }) async {
    return await executeBool(
      () async {
        final updateData = <String, dynamic>{};
        if (avatarBase64 != null) updateData['avatar'] = avatarBase64;
        if (mimeType != null) updateData['mime_type'] = mimeType;
        if (name != null) updateData['name'] = name;
        if (location != null) updateData['location'] = location;
        if (bio != null) updateData['bio'] = bio;
        if (phone != null) updateData['phone'] = phone;
        if (friendInfo != null) updateData['friend_info'] = friendInfo;
        if (musicPreferencesIds != null) updateData['music_preferences_ids'] = musicPreferencesIds;

        await _apiService.updateProfile(token!, updateData);

        if (avatarBase64 != null) _avatar = avatarBase64;
        if (name != null) _name = name;
        if (location != null) _location = location;
        if (bio != null) _bio = bio;
        if (phone != null) _phone = phone;
        if (friendInfo != null) _friendInfo = friendInfo;
        if (musicPreferencesIds != null) _musicPreferenceIds = musicPreferencesIds;
      },
      successMessage: 'Profile updated successfully',
      errorMessage: 'Failed to update profile',
    );
  }

  Future<bool> updateVisibility(String? token, {
    VisibilityLevel? avatarVisibility,
    VisibilityLevel? nameVisibility,
    VisibilityLevel? locationVisibility,
    VisibilityLevel? bioVisibility,
    VisibilityLevel? phoneVisibility,
    VisibilityLevel? friendInfoVisibility,
    VisibilityLevel? musicPreferencesVisibility,
  }) async {
    return await executeBool(
      () async {
        final updateData = <String, dynamic>{};
        if (avatarVisibility != null) updateData['avatar_visibility'] = avatarVisibility.value;
        if (nameVisibility != null) updateData['name_visibility'] = nameVisibility.value;
        if (locationVisibility != null) updateData['location_visibility'] = locationVisibility.value;
        if (bioVisibility != null) updateData['bio_visibility'] = bioVisibility.value;
        if (phoneVisibility != null) updateData['phone_visibility'] = phoneVisibility.value;
        if (friendInfoVisibility != null) updateData['friend_info_visibility'] = friendInfoVisibility.value;
        if (musicPreferencesVisibility != null) updateData['music_preferences_visibility'] = musicPreferencesVisibility.value;

        await _apiService.updateProfile(token!, updateData);

        if (avatarVisibility != null) _avatarVisibility = avatarVisibility;
        if (nameVisibility != null) _nameVisibility = nameVisibility;
        if (locationVisibility != null) _locationVisibility = locationVisibility;
        if (bioVisibility != null) _bioVisibility = bioVisibility;
        if (phoneVisibility != null) _phoneVisibility = phoneVisibility;
        if (friendInfoVisibility != null) _friendInfoVisibility = friendInfoVisibility;
        if (musicPreferencesVisibility != null) _musicPreferencesVisibility = musicPreferencesVisibility;
      },
      successMessage: 'Visibility settings updated successfully',
      errorMessage: 'Failed to update visibility settings',
    );
  }

  Future<List<Map<String, dynamic>>> getMusicPreferences(String token) async {
    try {
      return await _apiService.getMusicPreferences(token);
    } catch (e) {
      print('Error getting music preferences: $e');
      return [];
    }
  }

  Future<bool> deleteAvatar(String? token) async {
    return await executeBool(
      () async {
        await _apiService.deleteAvatar(token!);
        _avatar = null;
      },
      successMessage: 'Avatar deleted successfully',
      errorMessage: 'Failed to delete avatar',
    );
  }

  String? get avatarUrl {
    if (_avatar?.isNotEmpty == true) {
      if (_avatar!.startsWith('data:')) return _avatar;
      else if (_avatar!.length > 100) return 'data:image/jpeg;base64,$_avatar';
      else return _avatar;
    }
    return null;
  }
}
