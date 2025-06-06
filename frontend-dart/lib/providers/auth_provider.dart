// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'base_provider.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthProvider with ChangeNotifier, BaseProvider {
  final ApiService _api = ApiService();
  
  bool _isLoggedIn = false;
  String? _token;
  String? _userId;
  String? _username;

  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;
  String? get userId => _userId;
  String? get username => _username;
  String get displayName => _username ?? 'User';
  bool get hasValidToken => _token != null && _token!.isNotEmpty;

  String? _apiBaseUrl;
  GoogleSignIn? googleSignIn;

  String? _apiBaseUrl;
  GoogleSignIn? googleSignIn;

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

  Future<bool> login(String username, String password) async {
    return await execute(() async {
      final authResult = await _api.login(username, password);
      _setUserData(authResult.token, authResult.user.id, authResult.user.username);
    }) != null;
  }

  Future<bool> signup(String username, String email, String password) async {
    return await execute(() async {
      final authResult = await _api.signup(username, email, password);
      _setUserData(authResult.token, authResult.user.id, authResult.user.username);
    }) != null;
  }

  Future<bool> logout() async {
    if (_isLoggedIn && _username != null && _token != null) {
      await execute(() => _api.logout(_username!, _token!));
    }
    _clearUserData();
    return true;
  }

  Future<bool> facebookLogin() async {
    return await execute(() async {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final fbAccessToken = result.accessToken!.tokenString;
        final authResult = await _api.facebookLogin(fbAccessToken);
        _setUserData(authResult.token, authResult.user.id, authResult.user.username);
      } else {
        throw Exception("Facebook login failed!");
      }
    }) != null;
  }

  Future<bool> googleLoginApp() async {
    return await execute(() async {
      final user = await googleSignIn?.signIn();
      if (user == null) throw Exception("Google login failed!");
      
      final auth = await user.authentication;
      final idToken = auth.idToken;
      if (idToken == null) throw Exception("Google login failed!");

      final authResult = await _api.googleLogin('app', idToken);
      _setUserData(authResult.token, authResult.user.id, authResult.user.username);
    }) != null;
  }

  Future<bool> googleLoginWeb(GoogleSignInUserData? account) async {
    return await execute(() async {
      var idToken = account?.idToken;
      if (idToken == null) throw Exception("Google login failed!");

      final authResult = await _api.googleLogin('web', idToken);
      _setUserData(authResult.token, authResult.user.id, authResult.user.username);
    }) != null;
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

  Future<bool> facebookLogin() async {
    try{
        _isLoading = true;
        _errorMessage = null;
        notifyListeners();

        final LoginResult result = await FacebookAuth.instance.login();
        if (result.status == LoginStatus.success) {
          final fbAccessToken = result.accessToken!.tokenString;

          final authResult = await _api.facebookLogin(fbAccessToken);

          _token = authResult.token;
          _userId = authResult.user.id;
          _username = authResult.user.username;
          _isLoggedIn = true;

          _isLoading = false;
          notifyListeners();
          return true;
        }
        else {
          _errorMessage = "Facebook login failed !";
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } catch (e) {
        _errorMessage = e.toString();
        _isLoading = false;
        notifyListeners();
        return false;
      }
  }

  Future<bool> googleLoginWeb(GoogleSignInUserData? account) async {
    try{
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      var idToken = account?.idToken;

      if (idToken == null) {
        _errorMessage = "Google login failed !";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final authResult = await _api.googleLogin('web', idToken);
      _token = authResult.token;
      _userId = authResult.user.id;
      _username = authResult.user.username;
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      return true;


    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }

  }

  Future<bool> googleLoginApp() async {
    try{
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final user = await googleSignIn?.signIn();

      if (user == null) {
        _errorMessage = "Google login failed !";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final auth = await user.authentication;
      final idToken = auth.idToken;

      if (idToken == null) {
        _errorMessage = "Google login failed !";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final authResult = await _api.googleLogin('app', idToken);
      _token = authResult.token;
      _userId = authResult.user.id;
      _username = authResult.user.username;
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e) {
        _errorMessage = e.toString();
        _isLoading = false;
        notifyListeners();
        return false;
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/users/forgot_password/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
        }),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode != 200) {
        throw responseData;
      }
      
    } catch (error) {
      rethrow;
    }
  }

  Future<void> forgotChangePassword(String email, String otpStr, String password) async {
    try {
      int otp = int.parse(otpStr);
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/users/forgot_change_password/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'otp': otp,
          'password': password,
        }),
      );
      
      final responseData = json.decode(response.body);
      if (response.statusCode != 200) {
        throw responseData;
      }

    } catch (error) {
      rethrow;
    }
  }
}
