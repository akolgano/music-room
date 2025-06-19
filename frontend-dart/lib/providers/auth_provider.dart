// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../core/service_locator.dart';
import '../services/auth_service.dart';
import '../models/models.dart';
import '../models/api_models.dart';
import '../core/core.dart';

class AuthProvider with ChangeNotifier {
  late final AuthService _authService;
  
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider() {
    try {
      _authService = getIt<AuthService>();
      _initializeAuthState();
    } catch (e) {
      print('Error initializing AuthProvider: $e');
      _authService = getIt<AuthService>();
    }
  }

  Future<void> _initializeAuthState() async {
    try {
      notifyListeners();
    } catch (e) {
      print('Error loading stored auth state: $e');
    }
  }
  
  bool get isLoggedIn => _authService.isLoggedIn;
  String? get userId => _authService.currentUser?.id;
  String? get username => _authService.currentUser?.username;
  String get displayName => username ?? 'User';
  bool get hasValidToken => token != null && token!.isNotEmpty;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  User? get currentUser => _authService.currentUser;

  String? get token {
    final currentToken = _authService.currentToken;
    return currentToken;
  }

  Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Token $token',
  };

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
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    return await _execute(() => _authService.login(username, password));
  }

  Future<bool> signup(String username, String email, String password) async {
    return await _execute(() => _authService.signup(username, email, password));
  }

  Future<bool> logout() async {
    return await _execute(() => _authService.logout());
  }

  Future<bool> forgotPassword(String email) async {
    return await _execute(() async {
      final request = ForgotPasswordRequest(email: email);
      await _authService.api.forgotPassword(request);
    });
  }

  Future<bool> forgotChangePassword(String email, String otp, String password) async {
    return await _execute(() async {
      final request = ChangePasswordRequest(email: email, otp: int.parse(otp), password: password);
      await _authService.api.forgotChangePassword(request);
    });
  }

  Future<bool> facebookLogin() async {
    return await _execute(() async {
      final result = await SocialLoginUtils.loginWithFacebook();
      if (result.success) await _authService.facebookLogin(result.token!);
      else throw Exception(result.error ?? "Facebook login failed!");
    });
  }

  Future<bool> googleLoginApp() async {
    return await _execute(() async {
      final result = await SocialLoginUtils.loginWithGoogle();
      if (result.success) await _authService.googleLogin('app', result.token!);
      else throw Exception(result.error ?? "Google login failed!");
    });
  }

  Future<bool> sendSignupEmailOtp(String email) async {
    return await _execute(() => _authService.sendSignupEmailOtp(email));
  }

  Future<bool> signupWithOtp(String username, String email, String password, String otp) async {
    return await _execute(() async {
      final otpInt = int.parse(otp);
      await _authService.signupWithOtp(username, email, password, otpInt);
    });
  }
}
