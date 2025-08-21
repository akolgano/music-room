import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/navigation_core.dart';
import '../services/api_services.dart';
import '../models/music_models.dart';
import '../models/api_models.dart';

class StorageService {
  static late Box _box;

  static Future<StorageService> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox('app_storage');
    return StorageService._();
  }

  StorageService._();

  T? get<T>(String key) {
    final value = _box.get(key);
    if (value == null) { return null; }
    return value as T?;
  }

  Map<String, dynamic>? getMap(String key) {
    final value = _box.get(key);
    if (value == null) { return null; }
    if (value is Map<String, dynamic>) { return value; }
    if (value is Map) { return Map<String, dynamic>.from(value); }
    return null;
  }

  Future<void> set(String key, dynamic value) => _box.put(key, value);

  Future<void> delete(String key) => _box.delete(key);

  Future<void> clear() => _box.clear();

  bool containsKey(String key) => _box.containsKey(key);
}

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
        AppLogger.error('Error loading stored auth: ${e.toString()}', null, null, 'AuthService');
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
    await _performServerLogout();
    await _clearAuth();
  }

  Future<void> _performServerLogout() async {
    if (!_canPerformServerLogout()) return;
    
    try {
      final request = _createLogoutRequest();
      await _api.logout(_currentToken!, request);
    } catch (e) {
      _logLogoutError(e);
    }
  }

  bool _canPerformServerLogout() {
    return _currentUser != null && _currentToken != null;
  }

  LogoutRequest _createLogoutRequest() {
    return LogoutRequest(username: _currentUser!.username);
  }

  void _logLogoutError(dynamic error) {
    if (kDebugMode) {
      AppLogger.error('Error during logout API call: ${error.toString()}', null, null, 'AuthService');
    }
  }



  Future<AuthResult> facebookLogin(String accessToken) async {
    final request = SocialLoginRequest(fbAccessToken: accessToken);
    final result = await _api.facebookLogin(request);
    await _storeAuth(result.token, result.user);
    return result;
  }

  Future<AuthResult> googleLogin({String? idToken, String? socialId, String? socialEmail, String? socialName}) async {
    final request = SocialLoginRequest(
      idToken: idToken,
      socialId: socialId,
      socialEmail: socialEmail,
      socialName: socialName,
    );
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