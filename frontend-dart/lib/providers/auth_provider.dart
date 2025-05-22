// lib/providers/auth_provider.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false;
  String? _token;
  String? _userId;
  String? _username;
  final String _apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
  
  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;
  String? get userId => _userId;
  String? get username => _username;
  
  AuthProvider() {
    autoLogin();
  }
  
  Future<void> autoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('userData');
    if (userData != null) {
      final data = json.decode(userData);
      _token = data['token'];
      _userId = data['userId'];
      _username = data['username'];
      _isLoggedIn = true;
      notifyListeners();
    }
  }
  
  Future<void> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_apiBaseUrl/users/login/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'password': password}),
    );
    
    final responseData = json.decode(response.body);
    if (response.statusCode != 200) {
      throw responseData['detail'] ?? 'Authentication failed';
    }
    
    _token = responseData['token'];
    _userId = responseData['user']['id'].toString();
    _username = responseData['user']['username'];
    _isLoggedIn = true;
    
    await _saveUserData();
    notifyListeners();
  }

  Future<void> signup(String username, String email, String password) async {
    final response = await http.post(
      Uri.parse('$_apiBaseUrl/users/signup/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );
    
    final responseData = json.decode(response.body);
    if (response.statusCode != 201) {
      throw _parseErrorMessage(responseData);
    }
    
    _token = responseData['token'];
    _userId = responseData['user']['id'].toString();
    _username = responseData['user']['username'];
    _isLoggedIn = true;
    
    await _saveUserData();
    notifyListeners();
  }
  
  Future<void> logout() async {
    try {
      if (_token != null && _username != null) {
        await http.post(
          Uri.parse('$_apiBaseUrl/users/logout/'),
          headers: getAuthHeaders(),
          body: json.encode({'username': _username}),
        );
      }
    } catch (error) {
      print('Error during logout: $error');
    }
    
    _clearUserData();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userData');
    notifyListeners();
  }
  
  Map<String, String> getAuthHeaders() => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Token $_token',
  };

  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userData', json.encode({
      'token': _token,
      'userId': _userId,
      'username': _username,
    }));
  }

  void _clearUserData() {
    _token = null;
    _userId = null;
    _username = null;
    _isLoggedIn = false;
  }

  String _parseErrorMessage(dynamic responseData) {
    if (responseData is Map) {
      String errorMsg = '';
      responseData.forEach((key, value) {
        errorMsg += value is List 
          ? '$key: ${value.join(', ')}\n'
          : '$key: $value\n';
      });
      return errorMsg.trim();
    }
    return responseData['detail'] ?? 'Operation failed';
  }
}
