// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  
  bool _isLoggedIn = false;
  String? _token;
  String? _userId;
  String? _username;
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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
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
