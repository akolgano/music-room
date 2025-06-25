// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../core/base_provider.dart';
import '../core/service_locator.dart';
import '../services/auth_service.dart';
import '../models/models.dart';
import '../models/api_models.dart';
import '../core/core.dart' hide BaseProvider; 

class AuthProvider extends BaseProvider {
  late final AuthService _authService;

  AuthProvider() {
    try {
      _authService = getIt<AuthService>();
      _initializeAuthState();
    } catch (e) {
      print('Error initializing AuthProvider: $e');
      _authService = getIt<AuthService>();
    }
  }

  bool get isLoggedIn => _authService.isLoggedIn;
  String? get userId => _authService.currentUser?.id;
  String? get username => _authService.currentUser?.username;
  String get displayName => username ?? 'User';
  bool get hasValidToken => token != null && token!.isNotEmpty;
  User? get currentUser => _authService.currentUser;

  String? get token => _authService.currentToken;

  Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Token $token',
  };

  Future<void> _initializeAuthState() async {
    try {
      notifyListeners();
    } catch (e) {
      print('Error loading stored auth state: $e');
    }
  }

  Future<bool> login(String username, String password) async {
    return await executeBool(
      () => _authService.login(username, password),
      successMessage: 'Login successful!',
      errorMessage: 'Login failed',
    );
  }

  Future<bool> signup(String username, String email, String password) async {
    return await executeBool(
      () => _authService.signup(username, email, password),
      successMessage: 'Account created successfully!',
      errorMessage: 'Signup failed',
    );
  }

  Future<bool> logout() async {
    return await executeBool(
      () => _authService.logout(),
      successMessage: 'Logged out successfully',
      errorMessage: 'Logout failed',
    );
  }

  Future<bool> forgotPassword(String email) async {
    return await executeBool(
      () async {
        final request = ForgotPasswordRequest(email: email);
        await _authService.api.forgotPassword(request);
      },
      successMessage: 'Password reset email sent',
      errorMessage: 'Failed to send reset email',
    );
  }

  Future<bool> forgotChangePassword(String email, String otp, String password) async {
    return await executeBool(
      () async {
        final request = ChangePasswordRequest(
          email: email,
          otp: int.parse(otp),
          password: password,
        );
        await _authService.api.forgotChangePassword(request);
      },
      successMessage: 'Password changed successfully',
      errorMessage: 'Failed to change password',
    );
  }

  Future<bool> sendSignupEmailOtp(String email) async {
    return await executeBool(
      () async {
        await _authService.sendSignupEmailOtp(email);
      },
      successMessage: 'OTP sent successfully',
      errorMessage: 'Failed to send OTP',
    );
  }

  Future<bool> signupWithOtp(String username, String email, String password, String otp) async {
    return await executeBool(
      () async {
        await _authService.signupWithOtp(username, email, password, int.parse(otp));
      },
      successMessage: 'Account created successfully!',
      errorMessage: 'Signup failed',
    );
  }

  Future<bool> facebookLogin() async {
    return await executeBool(
      () async {
        final result = await SocialLoginUtils.loginWithFacebook();
        if (result.success) {
          await _authService.facebookLogin(result.token!);
        } else {
          throw Exception(result.error ?? "Facebook login failed!");
        }
      },
      successMessage: 'Facebook login successful!',
      errorMessage: 'Facebook login failed',
    );
  }

  Future<bool> googleLoginApp() async {
    return await executeBool(
      () async {
        if (!SocialLoginUtils.isInitialized) {
          await SocialLoginUtils.initialize();
          await Future.delayed(const Duration(milliseconds: 500));
        }
        
        if (SocialLoginUtils.googleSignInInstance == null) {
          throw Exception('Google Sign-In is not properly configured');
        }
        
        final result = await SocialLoginUtils.loginWithGoogle();
        if (result.success && result.token != null) {
          await _authService.googleLogin('app', result.token!);
        } else {
          throw Exception(result.error ?? "Google login failed");
        }
      },
      successMessage: 'Google login successful!',
      errorMessage: 'Google login failed',
    );
  }
}
