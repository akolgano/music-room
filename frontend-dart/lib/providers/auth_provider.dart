// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/consolidated_core.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  
  bool _isLoggedIn = false;
  String? _token;
  String? _userId;
  String? _username;
  String? _apiBaseUrl;
  GoogleSignIn? googleSignIn;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;
  String? get userId => _userId;
  String? get username => _username;
  String get displayName => _username ?? 'User';
  bool get hasValidToken => _token != null && _token!.isNotEmpty;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Token $_token',
  };

  AuthProvider() {
    _apiBaseUrl = dotenv.env['API_BASE_URL'];
    if (!kIsWeb) {
      googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile', 'openid'],
        clientId: dotenv.env['GOOGLE_CLIENT_ID_APP'],
      );
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> _execute(Future<void> Function() operation) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await operation();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    return await _execute(() async {
      final authResult = await _api.login(username, password);
      _setUserData(authResult.token, authResult.user.id, authResult.user.username);
    });
  }

  Future<bool> signup(String username, String email, String password) async {
    return await _execute(() async {
      final authResult = await _api.signup(username, email, password);
      _setUserData(authResult.token, authResult.user.id, authResult.user.username);
    });
  }

  Future<bool> logout() async {
    if (_isLoggedIn && _username != null && _token != null) {
      await _execute(() => _api.logout(_username!, _token!));
    }
    _clearUserData();
    return true;
  }

  Future<bool> facebookLogin() async {
    return await _execute(() async {
      final result = await SocialLoginUtils.loginWithFacebook();
      if (result.success) {
        final authResult = await _api.facebookLogin(result.token!);
        _setUserData(authResult.token, authResult.user.id, authResult.user.username);
      } else {
        throw Exception(result.error ?? "Facebook login failed!");
      }
    });
  }

  Future<bool> googleLoginApp() async {
    return await _execute(() async {
      final result = await SocialLoginUtils.loginWithGoogle();
      if (result.success) {
        final authResult = await _api.googleLogin('app', result.token!);
        _setUserData(authResult.token, authResult.user.id, authResult.user.username);
      } else {
        throw Exception(result.error ?? "Google login failed!");
      }
    });
  }

  Future<bool> googleLoginWeb(GoogleSignInUserData? account) async {
    return await _execute(() async {
      var idToken = account?.idToken;
      if (idToken == null) throw Exception("Google login failed!");

      final authResult = await _api.googleLogin('web', idToken);
      _setUserData(authResult.token, authResult.user.id, authResult.user.username);
    });
  }

  Future<void> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$_apiBaseUrl/users/forgot_password/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );

    final responseData = json.decode(response.body);
    if (response.statusCode != 200) {
      throw responseData;
    }
  }

  Future<void> forgotChangePassword(String email, String otpStr, String password) async {
    int otp = int.parse(otpStr);
    final response = await http.post(
      Uri.parse('$_apiBaseUrl/users/forgot_change_password/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'otp': otp, 'password': password}),
    );
    
    final responseData = json.decode(response.body);
    if (response.statusCode != 200) {
      throw responseData;
    }
  }

  void _setUserData(String token, String userId, String username) {
    _token = token;
    _userId = userId;
    _username = username;
    _isLoggedIn = true;
  }

  void _clearUserData() {
    _token = null;
    _userId = null;
    _username = null;
    _isLoggedIn = false;
    clearError();
  }
}
