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
import '../models/profile_models.dart';

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
  String _avatarVisibility = 'public';
  String _nameVisibility = 'public';
  String _locationVisibility = 'public';
  String _bioVisibility = 'public';
  String _phoneVisibility = 'private';
  String _friendInfoVisibility = 'friends';
  String _musicPreferencesVisibility = 'public';
  List<String> _musicPreferences = [];
  List<MusicPreference> _availableMusicPreferences = [];
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
  String get avatarVisibility => _avatarVisibility;
  String get nameVisibility => _nameVisibility;
  String get locationVisibility => _locationVisibility;
  String get bioVisibility => _bioVisibility;
  String get phoneVisibility => _phoneVisibility;
  String get friendInfoVisibility => _friendInfoVisibility;
  String get musicPreferencesVisibility => _musicPreferencesVisibility;
  List<String> get musicPreferences => List.from(_musicPreferences);
  List<MusicPreference> get availableMusicPreferences => List.from(_availableMusicPreferences);

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
    _avatarVisibility = 'public';
    _nameVisibility = 'public';
    _locationVisibility = 'public';
    _bioVisibility = 'public';
    _phoneVisibility = 'private';
    _friendInfoVisibility = 'friends';
    _musicPreferencesVisibility = 'public';
    _musicPreferences.clear();
    _availableMusicPreferences.clear();
  }

  Future<bool> loadProfile(String? token) async {
    if (token == null || token.isEmpty) {
      setError('Authentication required. Please log in again.');
      return false;
    }

    return await executeBool(
      () async {
        resetValues();
        try {
          final userData = await _apiService.getUserData(token);
          _userId = userData['id']?.toString();
          _username = userData['username'] as String?;
          _userEmail = userData['email'] as String?;
          _isPasswordUsable = userData['is_password_usable'] as bool? ?? false;
          
          final hasSocialAccount = userData['has_social_account'] as bool? ?? false;
          if (hasSocialAccount && userData['social'] != null) {
            final social = userData['social'] as Map<String, dynamic>;
            _socialType = social['type'] as String?;
            _socialEmail = social['social_email'] as String?;
            _socialName = social['social_name'] as String?;
            _socialId = social['social_id'] as String?;
          }
        } catch (e) {
          print('Failed to load user data: $e');
          throw Exception('Failed to load user information: $e');
        }

        try {
          final profile = await _apiService.getMyProfile(token);
          _avatar = profile.avatar;
          _name = profile.name;
          _location = profile.location;
          _bio = profile.bio;
          _phone = profile.phone;
          _friendInfo = profile.friendInfo;
          _avatarVisibility = profile.avatarVisibility;
          _nameVisibility = profile.nameVisibility;
          _locationVisibility = profile.locationVisibility;
          _bioVisibility = profile.bioVisibility;
          _phoneVisibility = profile.phoneVisibility;
          _friendInfoVisibility = profile.friendInfoVisibility;
          _musicPreferencesVisibility = profile.musicPreferencesVisibility;
          _musicPreferences = List.from(profile.musicPreferences);
        } catch (e) {
          print('Failed to load profile data: $e');
          throw Exception('Failed to load profile information: $e');
        }

        try {
          _availableMusicPreferences = await _apiService.getMusicPreferences(token);
        } catch (e) {
          print('Failed to load music preferences: $e');
          _availableMusicPreferences = [];
        }
      },
      successMessage: 'Profile loaded successfully',
      errorMessage: 'Failed to load profile',
    );
  }

  Future<bool> updateProfile(String? token, {
    String? avatar,
    String? name,
    String? location,
    String? bio,
    String? phone,
    String? friendInfo,
    String? avatarVisibility,
    String? nameVisibility,
    String? locationVisibility,
    String? bioVisibility,
    String? phoneVisibility,
    String? friendInfoVisibility,
    String? musicPreferencesVisibility,
    List<int>? musicPreferencesIds,
  }) async {
    return await executeBool(
      () async {
        final request = ProfileUpdateRequest(
          avatar: avatar,
          name: name,
          location: location,
          bio: bio,
          phone: phone,
          friendInfo: friendInfo,
          avatarVisibility: avatarVisibility,
          nameVisibility: nameVisibility,
          locationVisibility: locationVisibility,
          bioVisibility: bioVisibility,
          phoneVisibility: phoneVisibility,
          friendInfoVisibility: friendInfoVisibility,
          musicPreferencesVisibility: musicPreferencesVisibility,
          musicPreferencesIds: musicPreferencesIds,
        );

        final updatedProfile = await _apiService.patchMyProfile(token!, request);
        _avatar = updatedProfile.avatar;
        _name = updatedProfile.name;
        _location = updatedProfile.location;
        _bio = updatedProfile.bio;
        _phone = updatedProfile.phone;
        _friendInfo = updatedProfile.friendInfo;
        _avatarVisibility = updatedProfile.avatarVisibility;
        _nameVisibility = updatedProfile.nameVisibility;
        _locationVisibility = updatedProfile.locationVisibility;
        _bioVisibility = updatedProfile.bioVisibility;
        _phoneVisibility = updatedProfile.phoneVisibility;
        _friendInfoVisibility = updatedProfile.friendInfoVisibility;
        _musicPreferencesVisibility = updatedProfile.musicPreferencesVisibility;
        _musicPreferences = List.from(updatedProfile.musicPreferences);
      },
      successMessage: 'Profile updated successfully',
      errorMessage: 'Failed to update profile',
    );
  }

  Future<bool> updateAvatar(String? token, String? avatarBase64) async {
    return updateProfile(token, avatar: avatarBase64);
  }

  Future<bool> updateBasicInfo(String? token, {
    String? name,
    String? location,
    String? bio,
  }) async {
    return updateProfile(
      token,
      name: name,
      location: location,
      bio: bio,
    );
  }

  Future<bool> updateContactInfo(String? token, {
    String? phone,
    String? friendInfo,
  }) async {
    return updateProfile(
      token,
      phone: phone,
      friendInfo: friendInfo,
    );
  }

  Future<bool> updateMusicPreferences(String? token, List<int> musicPreferencesIds) async {
    return updateProfile(token, musicPreferencesIds: musicPreferencesIds);
  }

  Future<bool> updateVisibilitySettings(String? token, {
    String? avatarVisibility,
    String? nameVisibility,
    String? locationVisibility,
    String? bioVisibility,
    String? phoneVisibility,
    String? friendInfoVisibility,
    String? musicPreferencesVisibility,
  }) async {
    return updateProfile(
      token,
      avatarVisibility: avatarVisibility,
      nameVisibility: nameVisibility,
      locationVisibility: locationVisibility,
      bioVisibility: bioVisibility,
      phoneVisibility: phoneVisibility,
      friendInfoVisibility: friendInfoVisibility,
      musicPreferencesVisibility: musicPreferencesVisibility,
    );
  }

  Future<bool> deleteAvatar(String? token) async {
    return await executeBool(
      () async {
        await _apiService.deleteMyAvatar(token!);
        _avatar = null;
      },
      successMessage: 'Avatar deleted successfully',
      errorMessage: 'Failed to delete avatar',
    );
  }

  Future<bool> loadMusicPreferences(String? token) async {
    return await executeBool(
      () async {
        _availableMusicPreferences = await _apiService.getMusicPreferences(token!);
      },
      errorMessage: 'Failed to load music preferences',
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

  String? get avatarUrl {
    if (_avatar?.isNotEmpty == true) {
      if (_avatar!.startsWith('data:')) return _avatar;
      else if (_avatar!.length > 100) return 'data:image/jpeg;base64,$_avatar';
      else return _avatar;
    }
    return null;
  }

  List<String> getMusicPreferenceNames(List<int> ids) {
    return _availableMusicPreferences.where((pref) => ids.contains(pref.id)).map((pref) => pref.name).toList();
  }

  List<int> getMusicPreferenceIds(List<String> names) {
    return _availableMusicPreferences.where((pref) => names.contains(pref.name)).map((pref) => pref.id).toList();
  }

  bool get hasBasicInfo => _name?.isNotEmpty == true || _location?.isNotEmpty == true || _bio?.isNotEmpty == true;

  bool get hasContactInfo => _phone?.isNotEmpty == true || _friendInfo?.isNotEmpty == true;

  bool get isProfileComplete => hasBasicInfo && _avatar?.isNotEmpty == true && _musicPreferences.isNotEmpty;

  double get profileCompletionPercentage {
    int completed = 0;
    int total = 5; 
    if (_avatar?.isNotEmpty == true) completed++;
    if (_name?.isNotEmpty == true) completed++;
    if (_location?.isNotEmpty == true) completed++;
    if (_bio?.isNotEmpty == true) completed++;
    if (_musicPreferences.isNotEmpty) completed++;
    return completed / total;
  }
}
