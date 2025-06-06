// lib/providers/profile_provider.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'base_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

class ProfileProvider with ChangeNotifier, BaseProvider {
  final ApiService _apiService = ApiService();
  
  String? _userId;
  String? _username;
  String? _userEmail;
  String? _socialEmail;
  String? _socialName;
  String? _socialType;
  String? _socialId;
  bool _isPasswordUsable = false;
  GoogleSignIn? googleSignIn;

  String? get userId => _userId;
  String? get username => _username;
  String? get userEmail => _userEmail;
  String? get socialEmail => _socialEmail;
  String? get socialName => _socialName;
  String? get socialType => _socialType;
  String? get socialId => _socialId;
  bool get isPasswordUsable => _isPasswordUsable;

  ProfileProvider() {
    if (!kIsWeb) {
      googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile', 'openid'],
        clientId: dotenv.env['GOOGLE_CLIENT_ID_APP'],
      );
    }
  }

  void resetValues() {
    _userId = null;
    _username = null;
    _userEmail = null;
    _isPasswordUsable = false;
    _socialType = null;
    _socialEmail = null;
    _socialName = null;
    _socialId = null;
  }

  Future<bool> loadProfile(String? token) async {
    return await execute(() async {
      resetValues();
      final data = await _apiService.getUser(token);

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
    }) != null;
  }

  Future<bool> userPasswordChange(String? token, String currentPassword, String newPassword) async {
    return await execute(() async {
      await _apiService.userPasswordChange(token, currentPassword, newPassword);
    }) != null;
  }

  Future<bool> facebookLink(String? token) async {
    return await execute(() async {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final fbAccessToken = result.accessToken!.tokenString;
        await _apiService.facebookLink(token, fbAccessToken);
      } else {
        throw Exception("Facebook login failed!");
      }
    }) != null;
  }

  Future<bool> googleLinkWeb(String? token, GoogleSignInUserData? account) async {
    return await execute(() async {
      var idToken = account?.idToken;
      if (idToken == null) throw Exception("Google login failed!");
      await _apiService.googleLink('web', token, idToken);
    }) != null;
  }

  Future<bool> googleLinkApp(String? token) async {
    return await execute(() async {
      final user = await googleSignIn?.signIn();
      if (user == null) throw Exception("Google login failed!");

      final auth = await user.authentication;
      final idToken = auth.idToken;
      if (idToken == null) throw Exception("Google login failed!");

      await _apiService.googleLink('app', token, idToken);
    }) != null;
  }
}
