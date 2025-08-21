import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, debugPrint;
import 'package:path_provider/path_provider.dart';
import '../services/api_services.dart';
import '../core/locator_core.dart';  
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/provider_core.dart'; 
import '../core/signin_core.dart';
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

  GoogleSignIn get googleSignIn => GoogleSignInCore.instance;

  String? _userId;
  String? _username;
  String? _userEmail;
  String? _socialEmail;
  String? _socialName;
  String? _socialType;
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
        }

        try {
          final profileData = await _apiService.getMyProfile(token);
          _avatar = profileData.avatar;
          _name = profileData.name;
          _location = profileData.location;
          _bio = profileData.bio;
          _phone = profileData.phone;
          _friendInfo = profileData.friendInfo;
          _musicPreferences = profileData.musicPreferences;
          _musicPreferenceIds = profileData.musicPreferencesIds;
          _avatarVisibility = VisibilityLevelExtension.fromString(profileData.avatarVisibility);
          _nameVisibility = VisibilityLevelExtension.fromString(profileData.nameVisibility);
          _locationVisibility = VisibilityLevelExtension.fromString(profileData.locationVisibility);
          _bioVisibility = VisibilityLevelExtension.fromString(profileData.bioVisibility);
          _phoneVisibility = VisibilityLevelExtension.fromString(profileData.phoneVisibility);
          _friendInfoVisibility = VisibilityLevelExtension.fromString(profileData.friendInfoVisibility);
          _musicPreferencesVisibility = VisibilityLevelExtension.fromString(profileData.musicPreferencesVisibility);
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
        if (kDebugMode) {
          debugPrint('[ProfileProvider] Starting Google Sign-In process');
          debugPrint('[ProfileProvider] Platform: ${kIsWeb ? "Web" : "Android"}');
          debugPrint('[ProfileProvider] Using google_sign_in v7 API');
        }
        
        await GoogleSignInCore.initialize();
        
        GoogleSignInAccount? user;
        
        try {
          try {
            await googleSignIn.signOut();
            if (kDebugMode) {
              debugPrint('[ProfileProvider] Signed out previous session');
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('[ProfileProvider] No previous session: $e');
            }
          }
          
          if (kDebugMode) {
            debugPrint('[ProfileProvider] Showing Google account picker...');
          }
          
          if (googleSignIn.supportsAuthenticate()) {
            user = await googleSignIn.authenticate(
              scopeHint: ['email', 'profile'],
            );
          } else {
            throw Exception('Google Sign-In not supported on this platform');
          }
          
          if (kDebugMode) {
            debugPrint('[ProfileProvider] Sign-in successful: ${user.email}');
          }
          
        } on GoogleSignInException catch (e) {
          if (kDebugMode) {
            debugPrint('[ProfileProvider] Google Sign-In error: code: ${e.code.name} description:${e.description} details:${e.details}');
          }
          
          if (e.code == GoogleSignInExceptionCode.canceled) {
            throw Exception("Google Sign-In was cancelled.");
          } else if (e.code == GoogleSignInExceptionCode.interrupted) {
            throw Exception("Network error during Google Sign-In. Please check your connection.");
          } else if (e.code == GoogleSignInExceptionCode.clientConfigurationError) {
            throw Exception(
              "SHA fingerprint mismatch! Fix:\n"
              "1. Run: cd android && gradlew signingReport\n"
              "2. Copy SHA1 and SHA256 for debug variant\n"
              "3. Add to Firebase Console > Project Settings\n"
              "4. Download new google-services.json\n"
              "5. Replace android/app/google-services.json\n"
              "6. Clean rebuild: flutter clean && flutter run"
            );
          } else {
            throw Exception(e.description ?? "Google Sign-In failed. Please try again.");
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('[ProfileProvider] Unexpected error: $e');
          }
          throw Exception("Google Sign-In failed. Please try again.");
        }
        
        
        final socialId = user.id;
        final socialEmail = user.email;
        final socialName = user.displayName;
        
        if (kDebugMode) {
          debugPrint('[ProfileProvider] Google Sign-In successful');
          debugPrint('[ProfileProvider] User: $socialEmail');
          debugPrint('[ProfileProvider] ID: $socialId');
        }
        
        if (kIsWeb) {
          if (kDebugMode) {
            debugPrint('[ProfileProvider] Web platform - sending social credentials directly');
          }
          await _apiService.googleLink(token!, SocialLinkRequest(
            socialId: socialId,
            socialEmail: socialEmail,
            socialName: socialName
          ));
        } else {
          final auth = user.authentication;
          final idToken = auth.idToken;
          
          if (kDebugMode) {
            debugPrint('[ProfileProvider] Android platform - using idToken');
            debugPrint('[ProfileProvider] idToken present: ${idToken != null && idToken.isNotEmpty}');
          }
          
          if (idToken != null && idToken.isNotEmpty) {
            await _apiService.googleLink(token!, SocialLinkRequest(idToken: idToken));
          } else {
            if (kDebugMode) {
              debugPrint('[ProfileProvider] No idToken, falling back to social credentials');
            }
            await _apiService.googleLink(token!, SocialLinkRequest(
              socialId: socialId,
              socialEmail: socialEmail,
              socialName: socialName
            ));
          }
        }
      },
      successMessage: 'Google account linked successfully',
      errorMessage: null,
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
    List<Map<String, dynamic>>? availableMusicPreferences,
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
            if (musicPreferencesIds != null) {
              _musicPreferenceIds = musicPreferencesIds;
              _updateMusicPreferenceNames(availableMusicPreferences);
            }
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
              if (musicPreferencesIds != null) {
                _musicPreferenceIds = musicPreferencesIds;
                _updateMusicPreferenceNames(availableMusicPreferences);
              }
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
          if (musicPreferencesIds != null) {
            _musicPreferenceIds = musicPreferencesIds;
            _updateMusicPreferenceNames(availableMusicPreferences);
          }
        }
      },
      successMessage: 'Profile updated successfully',
      errorMessage: 'Failed to update profile',
    );
  }

  void _updateMusicPreferenceNames(List<Map<String, dynamic>>? availablePreferences) {
    if (availablePreferences == null || _musicPreferenceIds == null) return;
    
    _musicPreferences = _musicPreferenceIds!
        .map((id) {
          final preference = availablePreferences.firstWhere(
            (pref) => pref['id'] == id,
            orElse: () => <String, dynamic>{},
          );
          return preference['name']?.toString() ?? 'Unknown';
        })
        .where((name) => name != 'Unknown')
        .toList();
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
        
        ProfileResponse response;
        if (kIsWeb) {
          response = await _apiService.updateProfileWithFileWeb(
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
          response = await _apiService.updateProfileWithFile(
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

        _avatarVisibility = VisibilityLevelExtension.fromString(response.avatarVisibility);
        _nameVisibility = VisibilityLevelExtension.fromString(response.nameVisibility);
        _locationVisibility = VisibilityLevelExtension.fromString(response.locationVisibility);
        _bioVisibility = VisibilityLevelExtension.fromString(response.bioVisibility);
        _phoneVisibility = VisibilityLevelExtension.fromString(response.phoneVisibility);
        _friendInfoVisibility = VisibilityLevelExtension.fromString(response.friendInfoVisibility);
        _musicPreferencesVisibility = VisibilityLevelExtension.fromString(response.musicPreferencesVisibility);
        
        if (response.avatar != null) _avatar = response.avatar;
        if (response.name != null) _name = response.name;
        if (response.location != null) _location = response.location;
        if (response.bio != null) _bio = response.bio;
        if (response.phone != null) _phone = response.phone;
        if (response.friendInfo != null) _friendInfo = response.friendInfo;
        if (response.musicPreferences != null) _musicPreferences = response.musicPreferences;
        if (response.musicPreferencesIds != null) _musicPreferenceIds = response.musicPreferencesIds;
        
        notifyListeners();
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
