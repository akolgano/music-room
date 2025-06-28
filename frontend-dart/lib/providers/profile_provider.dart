// lib/providers/profile_provider.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/service_locator.dart';  
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import '../core/core.dart';
import '../core/base_provider.dart'; 
import '../models/api_models.dart';

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
  String? _gender;
  String? _location;
  String? _bio;
  String? _firstName;
  String? _lastName;
  String? _phone;
  String? _street;
  String? _country;
  String? _postalCode;
  DateTime? _dob;
  List<String>? _hobbies;
  String? _friendInfo;
  List<String>? _musicPreferences;
  
  String? get userId => _userId;
  String? get username => _username;
  String? get userEmail => _userEmail;
  String? get socialEmail => _socialEmail;
  String? get socialName => _socialName;
  String? get socialType => _socialType;
  String? get socialId => _socialId;
  bool get isPasswordUsable => _isPasswordUsable;
  String? get avatar => _avatar;
  String? get gender => _gender;
  String? get location => _location;
  String? get bio => _bio;
  String? get firstName => _firstName;
  String? get lastName => _lastName;
  String? get phone => _phone;
  String? get street => _street;
  String? get country => _country;
  String? get postalCode => _postalCode;
  DateTime? get dob => _dob;
  List<String>? get hobbies => _hobbies;
  String? get friendInfo => _friendInfo;
  List<String>? get musicPreferences => _musicPreferences;

  GoogleSignIn? googleSignIn;

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
    _gender = null;
    _location = null;
    _bio = null;
    _firstName = null;
    _lastName = null;
    _phone = null;
    _street = null;
    _country = null;
    _postalCode = null;
    _dob = null;
    _hobbies = null;
    _friendInfo = null;
    _musicPreferences = null;
  }

  Future<bool> loadProfile(String? token) async {
    return await executeBool(
      () async {
        resetValues();
        final data = await _apiService.getUserData(token);
        _userId = data['id'];
        _username = data['username'];
        _userEmail = data['email'];
        _isPasswordUsable = data['is_password_usable'] as bool;
        
        final hasSocialAccount = data['has_social_account'] as bool;
        if (hasSocialAccount) {
          final social = data['social'] as Map<String, dynamic>;
          _socialType = social['type'];
          _socialEmail = social['social_email'];
          _socialName = social['social_name'];
          _socialId = social['social_id'];
        }

        final profilePublic = await _apiService.getProfilePublicData(token);
        _avatar = profilePublic['avatar'];
        _gender = profilePublic['gender'];
        _location = profilePublic['location'];
        _bio = profilePublic['bio'];

        final profilePrivate = await _apiService.getProfilePrivateData(token);
        _firstName = profilePrivate['first_name'];
        _lastName = profilePrivate['last_name'];
        _phone = profilePrivate['phone'];
        _street = profilePrivate['street'];
        _country = profilePrivate['country'];
        _postalCode = profilePrivate['postal_code'];

        final profileFriend = await _apiService.getProfileFriendData(token);
        _hobbies = profileFriend['hobbies'];
        _friendInfo = profileFriend['friend_info'];
        final dobDb = profileFriend['dob'];
        if (dobDb != null) _dob = DateTime.parse(dobDb);

        final profileMusic = await _apiService.getProfileMusicData(token);
        _musicPreferences = profileMusic['music_preferences'];
      },
      successMessage: 'Profile loaded successfully',
      errorMessage: 'Failed to load profile',
    );
  }

  Future<bool> userPasswordChange(String? token, String currentPassword, String newPassword) async {
    return await executeBool(
      () async {
        await _apiService.userPasswordChangeData(token, currentPassword, newPassword);
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

  Future<bool> googleLinkWeb(String? token, GoogleSignInUserData? account) async {
    return await executeBool(
      () async {
        var idToken = account?.idToken;
        if (idToken == null) throw Exception("Google login failed!");
        await _apiService.googleLinkData('web', token, idToken);
      },
      successMessage: 'Google account linked successfully',
      errorMessage: 'Failed to link Google account',
    );
  }

  Future<bool> googleLinkApp(String? token) async {
    return await executeBool(
      () async {
        final googleSignIn = SocialLoginUtils.googleSignInInstance;
        if (googleSignIn == null) throw Exception("Google Sign-In not initialized");
        final user = await googleSignIn.signIn();
        if (user == null) throw Exception("Google login failed!");
        final auth = await user.authentication;
        final idToken = auth.idToken;
        if (idToken == null) throw Exception("Google login failed!");
        await _apiService.googleLinkData('app', token, idToken);
      },
      successMessage: 'Google account linked successfully',
      errorMessage: 'Failed to link Google account',
    );
  }

  Future<bool> updateAvatar(String? token, String? avatarBase64, String? mimeType) async {
    return await executeBool(
      () async {
        await _apiService.updateProfile(token!, {
          if (avatarBase64 != null) 'avatar_base64': avatarBase64,
          if (mimeType != null) 'mime_type': mimeType,
        });
      },
      successMessage: 'Avatar updated successfully',
      errorMessage: 'Failed to update avatar',
    );
  }

  Future<bool> updatePublicBasic(String? token, String? gender, String? location) async {
    return await executeBool(
      () async {
        await _apiService.updatePublicBasic(token!, PublicBasicUpdateRequest(gender: gender, location: location));
      },
      successMessage: 'Public info updated successfully',
      errorMessage: 'Failed to update public info',
    );
  }

  Future<bool> updatePublicBio(String? token, String? bio) async {
    return await executeBool(
      () async {
        await _apiService.updatePublicBioData(token, bio);
      },
      successMessage: 'Bio updated successfully',
      errorMessage: 'Failed to update bio',
    );
  }

  Future<bool> updatePrivateInfo(String? token, String? firstName, String? lastName, String? phone, String? street, String? country, String? postalCode) async {
    return await executeBool(
      () async {
        await _apiService.updatePrivateInfoData(token, firstName, lastName, phone, street, country, postalCode);
      },
      successMessage: 'Private info updated successfully',
      errorMessage: 'Failed to update private info',
    );
  }

  Future<bool> updateFriendInfo(String? token, String? dob, List<String>? hobbies, String? friendInfo) async {
    return await executeBool(
      () async {
        await _apiService.updateFriendInfoData(token, dob, hobbies, friendInfo);
      },
      successMessage: 'Friend info updated successfully',
      errorMessage: 'Failed to update friend info',
    );
  }

  Future<bool> updateMusicPreferences(String? token, List<String>? musicPreferences) async {
    return await executeBool(
      () async {
        await _apiService.updateMusicPreferencesData(token, musicPreferences);
      },
      successMessage: 'Music preferences updated successfully',
      errorMessage: 'Failed to update music preferences',
    );
  }
}
