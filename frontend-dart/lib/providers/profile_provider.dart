import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, debugPrint;
import 'package:path_provider/path_provider.dart';
import '../services/api_service.dart';
import '../core/service_locator.dart';  
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  final googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile', 'openid'],
  );

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
        
        final userData = await _apiService.getUser(token!);
        _userId = userData.id;
        _username = userData.username;
        _userEmail = userData.email;
        _isPasswordUsable = userData.isPasswordUsable ?? false;

        final hasSocialAccount = userData.hasSocialAccount ?? false;
        if (hasSocialAccount && userData.social != null) {
          final social = userData.social!;
          _socialType = social['type'];
          _socialEmail = social['social_email'];
          _socialName = social['social_name'];
          _socialId = social['social_id'];
        }

        if (_userId != null) {
          try {
            final profileData = await _apiService.getProfileById(_userId!, token);
            _avatar = profileData.avatar;
            _name = profileData.name;
            _location = profileData.location;
            _bio = profileData.bio;
            _phone = profileData.phone;
            _friendInfo = profileData.friendInfo;
            _musicPreferences = profileData.musicPreferences;
            _avatarVisibility = VisibilityLevel.public;
            _nameVisibility = VisibilityLevel.public;
            _locationVisibility = VisibilityLevel.public;
            _bioVisibility = VisibilityLevel.public;
            _phoneVisibility = VisibilityLevel.private;
            _friendInfoVisibility = VisibilityLevel.friends;
            _musicPreferencesVisibility = VisibilityLevel.public;
          } catch (e) {
            if (kDebugMode) {
              debugPrint('[ProfileProvider] Error loading profile data: $e');
            }
            _avatar = null;
            _name = null;
            _location = null;
            _bio = null;
            _phone = null;
            _friendInfo = null;
            _musicPreferences = null;
            _musicPreferenceIds = null;
            
            _avatarVisibility = VisibilityLevel.public;
            _nameVisibility = VisibilityLevel.public;
            _locationVisibility = VisibilityLevel.public;
            _bioVisibility = VisibilityLevel.public;
            _phoneVisibility = VisibilityLevel.private;
            _friendInfoVisibility = VisibilityLevel.friends;
            _musicPreferencesVisibility = VisibilityLevel.public;
          }
        }
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
        } else {
          throw Exception(result.message ?? "Facebook login failed!");
        }
      },
      successMessage: 'Facebook account linked successfully',
      errorMessage: 'Failed to link Facebook account',
    );
  }

  Future<bool> googleLink(String? token) async {
    return await executeBool(
      () async {

        final user = await googleSignIn.signIn();
        if (user == null) throw Exception("Google login failed!");

        final socialId = user.id;
        final socialEmail = user.email;
        final socialName = user.displayName;

        final auth = await user.authentication;
        final idToken = auth.idToken;

        if (idToken != null) {
          await _apiService.googleLink(token!, SocialLinkRequest(idToken: idToken));
        }
        else {
          await _apiService.googleLink(token!, SocialLinkRequest(socialId: socialId, socialEmail: socialEmail, socialName: socialName));
        }
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
        
        if (kDebugMode) {
          debugPrint('[ProfileProvider] updateProfile called with avatarBase64: ${avatarBase64 != null ? 'present' : 'null'}');
        }
        
        if (avatarBase64 != null) {
          if (kIsWeb) {
            if (kDebugMode) {
              debugPrint('[ProfileProvider] Web platform detected, preparing avatar upload with multipart');
            }
            
            final bytes = base64Decode(avatarBase64);
            
            if (kDebugMode) {
              debugPrint('[ProfileProvider] Making API call to updateProfileWithFile (web)');
            }
            await _apiService.updateProfileWithFileWeb(
              token!,
              avatarBytes: bytes,
              mimeType: mimeType,
              name: name,
              location: location,
              bio: bio,
              phone: phone,
              friendInfo: friendInfo,
              musicPreferencesIds: musicPreferencesIds,
            );
            if (kDebugMode) {
              debugPrint('[ProfileProvider] Web API call completed successfully');
            }
            
            _avatar = avatarBase64;
            if (name != null) _name = name;
            if (location != null) _location = location;
            if (bio != null) _bio = bio;
            if (phone != null) _phone = phone;
            if (friendInfo != null) _friendInfo = friendInfo;
            if (musicPreferencesIds != null) _musicPreferenceIds = musicPreferencesIds;
          } else {
            if (kDebugMode) {
              debugPrint('[ProfileProvider] Mobile platform detected, preparing avatar upload');
            }
            final bytes = base64Decode(avatarBase64);
            
            if (bytes.length > 5 * 1024 * 1024) {
              throw Exception('Image too large. Please choose an image smaller than 5MB.');
            }
            
            final tempDir = await getTemporaryDirectory();
            final tempFile = File('${tempDir.path}/temp_avatar.jpg');
            await tempFile.writeAsBytes(bytes);
            
            try {
              if (kDebugMode) {
                debugPrint('[ProfileProvider] Making API call to updateProfileWithFile');
              }
              final result = await _apiService.updateProfileWithFile(
                token!,
                avatarPath: tempFile.path,
                name: name,
                location: location,
                bio: bio,
                phone: phone,
                friendInfo: friendInfo,
                musicPreferencesIds: musicPreferencesIds,
              );
              
              if (kDebugMode) {
                debugPrint('[ProfileProvider] Mobile API call completed successfully');
              }
              
              _avatar = result.avatar;
              if (name != null) _name = name;
              if (location != null) _location = location;
              if (bio != null) _bio = bio;
              if (phone != null) _phone = phone;
              if (friendInfo != null) _friendInfo = friendInfo;
              if (musicPreferencesIds != null) _musicPreferenceIds = musicPreferencesIds;
            } finally {
              if (await tempFile.exists()) {
                await tempFile.delete();
              }
            }
          }
        } else {
          if (kDebugMode) {
            debugPrint('[ProfileProvider] No avatar update, performing regular profile update with multipart');
          }
          
          if (kIsWeb) {
            if (kDebugMode) {
              debugPrint('[ProfileProvider] Web platform detected for non-avatar update');
            }
            await _apiService.updateProfileWithFileWeb(
              token!,
              name: name,
              location: location,
              bio: bio,
              phone: phone,
              friendInfo: friendInfo,
              musicPreferencesIds: musicPreferencesIds,
            );
            if (kDebugMode) {
              debugPrint('[ProfileProvider] Web non-avatar API call completed successfully');
            }
          } else {
            if (kDebugMode) {
              debugPrint('[ProfileProvider] Mobile platform detected for non-avatar update');
            }
            await _apiService.updateProfileWithFile(
              token!,
              name: name,
              location: location,
              bio: bio,
              phone: phone,
              friendInfo: friendInfo,
              musicPreferencesIds: musicPreferencesIds,
            );
            if (kDebugMode) {
              debugPrint('[ProfileProvider] Mobile non-avatar API call completed successfully');
            }
          }

          if (name != null) _name = name;
          if (location != null) _location = location;
          if (bio != null) _bio = bio;
          if (phone != null) _phone = phone;
          if (friendInfo != null) _friendInfo = friendInfo;
          if (musicPreferencesIds != null) _musicPreferenceIds = musicPreferencesIds;
        }
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
        
        if (kDebugMode) {
          debugPrint('[ProfileProvider] Updating visibility settings with multipart');
        }
        
        if (kIsWeb) {
          await _apiService.updateProfileWithFileWeb(
            token!,
            avatarVisibility: avatarVisibility?.value,
            nameVisibility: nameVisibility?.value,
            locationVisibility: locationVisibility?.value,
            bioVisibility: bioVisibility?.value,
            phoneVisibility: phoneVisibility?.value,
            friendInfoVisibility: friendInfoVisibility?.value,
            musicPreferencesVisibility: musicPreferencesVisibility?.value,
          );
        } else {
          await _apiService.updateProfileWithFile(
            token!,
            avatarVisibility: avatarVisibility?.value,
            nameVisibility: nameVisibility?.value,
            locationVisibility: locationVisibility?.value,
            bioVisibility: bioVisibility?.value,
            phoneVisibility: phoneVisibility?.value,
            friendInfoVisibility: friendInfoVisibility?.value,
            musicPreferencesVisibility: musicPreferencesVisibility?.value,
          );
        }

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
      if (kDebugMode) {
        debugPrint('[ProfileProvider] Error getting music preferences: $e');
      }
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
      if (_avatar!.startsWith('data:')) {
        return _avatar;
      } else if (_avatar!.length > 100) {
        return 'data:image/jpeg;base64,$_avatar';
      } else {
        return _avatar;
      }
    }
    return null;
  }
}
