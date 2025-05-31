// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'base_provider.dart';

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

  Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Token $_token',
  };

  Future<bool> login(String username, String password) async {
    final result = await execute(() async {
      final authResult = await _api.login(username, password);
      _setUserData(authResult.token, authResult.user.id, authResult.user.username);
      return true;
    });
    return result ?? false;
  }

  Future<bool> signup(String username, String email, String password) async {
    final result = await execute(() async {
      final authResult = await _api.signup(username, email, password);
      _setUserData(authResult.token, authResult.user.id, authResult.user.username);
      return true;
    });
    return result ?? false;
  }

  Future<bool> logout() async {
    if (_isLoggedIn && _username != null && _token != null) {
      await execute(() => _api.logout(_username!, _token!));
    }
    _clearUserData();
    return true;
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
