// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
//import '../models/user.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in_web/google_sign_in_web.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  String? _token;
  String? _userId;
  String? _username;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _errorMessage;

  String? get token => _token;
  String? get userId => _userId;
  String? get username => _username;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  String? _apiBaseUrl;
  GoogleSignIn? googleSignIn;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  AuthProvider() {
    _apiBaseUrl = dotenv.env['API_BASE_URL'];

    if (!kIsWeb) {
      googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile', 'openid'],
      clientId: dotenv.env['GOOGLE_CLIENT_ID_APP'],
      );
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final authResult = await _apiService.login(username, password);
      
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

  Future<bool> signup(String username, String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final authResult = await _apiService.signup(username, email, password);
      
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

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _username = null;
    _isLoggedIn = false;
    _errorMessage = null;
    
    final googleSignInPlugin = GoogleSignInPlatform.instance as GoogleSignInPlugin;
    await googleSignInPlugin.signOut();
    
    notifyListeners();
  }

  Future<bool> facebookLogin() async {
    try{
        _isLoading = true;
        _errorMessage = null;
        notifyListeners();

        final LoginResult result = await FacebookAuth.instance.login();
        if (result.status == LoginStatus.success) {
          final fbAccessToken = result.accessToken!.tokenString;

          final authResult = await _apiService.facebookLogin(fbAccessToken);

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

      final authResult = await _apiService.googleLoginWeb(idToken);
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

      final authResult = await _apiService.googleLoginApp(idToken);
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

  Future<void> changePassword(String email, String otpStr, String password) async {
    try {
      int otp = int.parse(otpStr);
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/users/change_password/'),
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