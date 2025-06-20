// lib/services/auth_service.dart
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
    _currentToken = _storage.get<String>('auth_token');
    final userJson = _storage.get<Map<String, dynamic>>('current_user');
    if (userJson != null) {
      _currentUser = User.fromJson(userJson);
    }
  }

  Future<AuthResult> login(String username, String password) async {
    final request = LoginRequest(username: username, password: password);
    final result = await _api.login(request);
    
    await _storeAuth(result.token, result.user);
    return result;
  }

  Future<AuthResult> signup(String username, String email, String password) async {
    final request = SignupRequest(username: username, email: email, password: password);
    final result = await _api.signup(request);
    
    await _storeAuth(result.token, result.user);
    return result;
  }

  Future<void> logout() async {
    if (_currentUser != null && _currentToken != null) {
      try {
        final request = LogoutRequest(username: _currentUser!.username);
        await _api.logout('Token $_currentToken', request);
      } catch (e) {}
    }
    await _clearAuth();
  }

  Future<AuthResult> facebookLogin(String accessToken) async {
    final request = SocialLoginRequest(accessToken: accessToken);
    final result = await _api.facebookLogin(request);
    await _storeAuth(result.token, result.user);
    return result;
  }

  Future<AuthResult> googleLogin(String type, String token) async {
    final request = SocialLoginRequest(
      type: type, 
      idToken: token,
      accessToken: token,
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

  Future<AuthResult> signupWithOtp(String username, String email, String password, int otp) async {
    final request = SignupWithOtpRequest(
      username: username, 
      email: email, 
      password: password, 
      otp: otp
    );
    final result = await _api.signupWithOtp(request);
    
    await _storeAuth(result.token, result.user);
    return result;
  }
}
