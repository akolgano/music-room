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
  Timer? _authTimer;
  String? _apiBaseUrl;
  
  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;
  String? get userId => _userId;
  String? get username => _username;
  
  AuthProvider() {
    _apiBaseUrl = dotenv.env['API_BASE_URL'];
    autoLogin();
  }
  
  Future<void> autoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) {
      return;
    }
    
    final userData = json.decode(prefs.getString('userData')!);
    _token = userData['token'];
    _userId = userData['userId'];
    _username = userData['username'];
    _isLoggedIn = true;
    notifyListeners();
  }
  
  Future<void> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/users/login/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );
      
      final responseData = json.decode(response.body);
      if (response.statusCode != 200) {
        throw responseData['detail'] ?? 'Authentication failed';
        throw responseData['detail'];
      }
      
      _token = responseData['token'];
      _userId = responseData['user']['id'].toString();
      _username = responseData['user']['username'];
      _isLoggedIn = true;
      
      final prefs = await SharedPreferences.getInstance();
      final userData = json.encode({
        'token': _token,
        'userId': _userId,
        'username': _username,
      });
      prefs.setString('userData', userData);
      
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> signup(String username, String email, String password) async {
    try {
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
        if (responseData is Map) {
          String errorMsg = '';
          responseData.forEach((key, value) {
            if (value is List) {
              errorMsg += '$key: ${value.join(', ')}\n';
            } else {
              errorMsg += '$key: $value\n';
            }
          });
          throw errorMsg.trim();
        } else if (responseData['detail'] != null) {
          throw responseData['detail'];
        } else {
          throw 'Registration failed';
        }
      }
      
      _token = responseData['token'];
      _userId = responseData['user']['id'].toString();
      _username = responseData['user']['username'];
      _isLoggedIn = true;
      
      final prefs = await SharedPreferences.getInstance();
      final userData = json.encode({
        'token': _token,
        'userId': _userId,
        'username': _username,
      });
      prefs.setString('userData', userData);
      
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }
  
  Future<void> logout() async {
    try {
      if (_token != null && _username != null) {
        await http.post(
          Uri.parse('$_apiBaseUrl/users/logout/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $_token',
          },
          body: json.encode({
            'username': _username,
          }),
        );
      }
    } catch (error) {
      print('Error during logout: $error');
    }
    
    _token = null;
    _userId = null;
    _username = null;
    _isLoggedIn = false;
    
    if (_authTimer != null) {
      _authTimer!.cancel();
      _authTimer = null;
    }
    
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('userData');
    
    notifyListeners();
  }
  
  Map<String, String> getAuthHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Token $_token',
    };
  }
}
