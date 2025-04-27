import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_room/models/user.dart';
import 'package:music_room/services/api_service.dart';

enum AuthStatus { idle, authenticating, authenticated, error }

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  String? _token;
  AuthStatus _status = AuthStatus.idle;
  String? _errorMessage;
  final ApiService _apiService = ApiService();

  User? get currentUser => _currentUser;
  String? get token => _token;
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null && _token != null;

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/auth/login', {
        'email': email,
        'password': password,
      });

      if (response.containsKey('token') && response.containsKey('user')) {
        _token = response['token'];
        _currentUser = User.fromJson(response['user']);
        _status = AuthStatus.authenticated;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        
        notifyListeners();
        return true;
      } else {
        _status = AuthStatus.error;
        _errorMessage = 'Invalid login response';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String username, String email, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/auth/register', {
        'username': username,
        'email': email,
        'password': password,
      });

      if (response.containsKey('token') && response.containsKey('user')) {
        _token = response['token'];
        _currentUser = User.fromJson(response['user']);
        _status = AuthStatus.authenticated;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        
        notifyListeners();
        return true;
      } else {
        _status = AuthStatus.error;
        _errorMessage = 'Invalid registration response';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithSocial(String provider) async {
    return false;
  }

  Future<void> logout() async {
    _currentUser = null;
    _token = null;
    _status = AuthStatus.idle;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    
    notifyListeners();
  }

  Future<bool> autoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token == null) {
      return false;
    }
    
    try {
      _token = token;
      final response = await _apiService.get('/auth/user', token: token);
      _currentUser = User.fromJson(response);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _token = null;
      await prefs.remove('auth_token');
      return false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put('/users/profile', data, token: _token);
      _currentUser = User.fromJson(response);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }
}
