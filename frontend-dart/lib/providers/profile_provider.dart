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
        _gender = profileData['gender'];
        _location = profileData['location'];
        _bio = profileData['bio'];
        _firstName = profileData['first_name'];
        _lastName = profileData['last_name'];
        _phone = profileData['phone'];
        _street = profileData['street'];
        _country = profileData['country'];
        _postalCode = profileData['postal_code'];
        final dobString = profileData['dob'];
        if (dobString != null) _dob = DateTime.parse(dobString);
        _hobbies = (profileData['hobbies'] as List<dynamic>?)?.cast<String>();
        _friendInfo = profileData['friend_info'];
        _musicPreferences = (profileData['music_preferences'] as List<dynamic>?)?.cast<String>();
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
    String? gender,
    String? location,
    String? bio,
    String? firstName,
    String? lastName,
    String? phone,
    String? street,
    String? country,
    String? postalCode,
    String? dob,
    List<String>? hobbies,
    String? friendInfo, List<String>? musicPreferences,
  }) async {
    return await executeBool(
      () async {
        final updateData = <String, dynamic>{};
        if (avatarBase64 != null) updateData['avatar_base64'] = avatarBase64;
        if (mimeType != null) updateData['mime_type'] = mimeType;
        if (gender != null) updateData['gender'] = gender;
        if (location != null) updateData['location'] = location;
        if (bio != null) updateData['bio'] = bio;
        if (firstName != null) updateData['first_name'] = firstName;
        if (lastName != null) updateData['last_name'] = lastName;
        if (phone != null) updateData['phone'] = phone;
        if (street != null) updateData['street'] = street;
        if (country != null) updateData['country'] = country;
        if (postalCode != null) updateData['postal_code'] = postalCode;
        if (dob != null) updateData['dob'] = dob;
        if (hobbies != null) updateData['hobbies'] = hobbies;
        if (friendInfo != null) updateData['friend_info'] = friendInfo;
        if (musicPreferences != null) updateData['music_preferences'] = musicPreferences;
        await _apiService.updateProfile(token!, updateData);
        if (avatarBase64 != null) _avatar = avatarBase64;
        if (gender != null) _gender = gender;
        if (location != null) _location = location;
        if (bio != null) _bio = bio;
        if (firstName != null) _firstName = firstName;
        if (lastName != null) _lastName = lastName;
        if (phone != null) _phone = phone;
        if (street != null) _street = street;
        if (country != null) _country = country;
        if (postalCode != null) _postalCode = postalCode;
        if (dob != null) _dob = DateTime.parse(dob);
        if (hobbies != null) _hobbies = hobbies;
        if (friendInfo != null) _friendInfo = friendInfo;
        if (musicPreferences != null) _musicPreferences = musicPreferences;
      },
      successMessage: 'Profile updated successfully',
      errorMessage: 'Failed to update profile',
    );
  }

  Future<bool> updatePersonalInfo(String? token, String? firstName, String? lastName, String? phone, String? street, String? country, String? postalCode) async {
    return updateProfile(token, firstName: firstName, lastName: lastName, phone: phone, street: street, country: country, postalCode: postalCode);
  }

  Future<bool> updateFriendInfo(String? token, String? dob, List<String>? hobbies, String? friendInfo) async {
    return updateProfile(token, dob: dob, hobbies: hobbies, friendInfo: friendInfo);
  }

  Future<bool> updateMusicPreferences(String? token, List<String>? musicPreferences) async {
    return updateProfile(token, musicPreferences: musicPreferences);
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
