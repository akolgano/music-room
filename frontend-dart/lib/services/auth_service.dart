// lib/services/auth_service.dart
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/models.dart';
import '../models/api_models.dart';

class AuthService {
  final ApiService _api;
  final StorageService _storage;
  
  String? _currentToken;
  User? _currentUser;

  AuthService(this._api, this._storage) {
    _loadStoredAuth();
  }

  String? get currentToken => _currentToken;
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentToken != null && _currentUser != null;
  ApiService get api => _api;

  Future<void> _loadStoredAuth() async {
    try {
      _currentToken = _storage.get<String>('auth_token');
      final userData = _storage.getMap('current_user');
      if (userData != null) { _currentUser = User.fromJson(userData); }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error loading stored auth: $e', name: 'AuthService');
      }
      await _clearAuth();
    }
  }

  Future<AuthResult> login(String username, String password) async {
    final request = LoginRequest(username: username, password: password);
    final result = await _api.login(request);
    await _storeAuth(result.token, result.user);
    return result;
  }

  Future<void> logout() async {
    if (_currentUser != null && _currentToken != null) {
      try {
        final request = LogoutRequest(username: _currentUser!.username);
        await _api.logout('Token $_currentToken', request);
      } catch (e) {
        if (kDebugMode) {
          developer.log('Error during logout API call: $e', name: 'AuthService');
        }
      }
    }
    await _clearAuth();
  }


  // Facebook and google login is project requirement, they must be implemented
  Future<AuthResult> facebookLogin(String accessToken) async {
    final request = SocialLoginRequest(fbAccessToken: accessToken);
    final result = await _api.facebookLogin(request);
    await _storeAuth(result.token, result.user);
    return result;
  }

  Future<AuthResult> googleLoginApp(String idToken) async {
    final request = SocialLoginRequest(idToken: idToken);
    final result = await _api.googleLogin(request);
    await _storeAuth(result.token, result.user);
    return result;
  }

  Future<AuthResult> googleLoginWeb(String socialId, String socialEmail, String? socialName) async {
    final request = SocialLoginRequest(socialId: socialId, socialEmail: socialEmail, socialName: socialName);
    final result = await _api.googleLogin(request);
    await _storeAuth(result.token, result.user);
    return result;
  }

  Future<void> _storeAuth(String token, User user) async {
    _currentToken = token;
    _currentUser = user;
    await _storage.set('auth_token', token);
    await _storage.set('current_user', user.toJson());
  }

  Future<void> _clearAuth() async {
    _currentToken = null;
    _currentUser = null;
    await _storage.delete('auth_token');
    await _storage.delete('current_user');
  }

  Future<void> sendSignupEmailOtp(String email) async {
    final request = EmailOtpRequest(email: email);
    await _api.sendSignupEmailOtp(request);
  }

  Future<AuthResult> signupWithOtp(String username, String email, String password, String otp) async {
    final request = SignupWithOtpRequest(username: username, email: email, password: password, otp: otp);
    final result = await _api.signupWithOtp(request);
    await _storeAuth(result.token, result.user);
    return result;
  }
}
