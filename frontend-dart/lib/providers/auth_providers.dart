import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../core/provider_core.dart';
import '../core/locator_core.dart';
import '../services/auth_services.dart';
import '../services/websocket_services.dart';
import '../services/logging_services.dart';
import '../models/music_models.dart';
import '../models/api_models.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends BaseProvider {
  late final AuthService _authService;
  late final WebSocketService _webSocketService;
  late final FrontendLoggingService _loggingService;

  AuthProvider() {
    try {
      _authService = getIt<AuthService>();
      _webSocketService = getIt<WebSocketService>();
      _loggingService = getIt<FrontendLoggingService>();
      _initializeAuthState();
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error initializing AuthProvider: $e', name: 'AuthProvider');
      }
      _authService = getIt<AuthService>();
      _webSocketService = getIt<WebSocketService>();
      _loggingService = getIt<FrontendLoggingService>();
    }
  }

  bool get isLoggedIn => _authService.isLoggedIn;
  String? get userId => _authService.currentUser?.id;
  String? get username => _authService.currentUser?.username;
  String get displayName => username ?? 'User';
  bool get hasValidToken => token != null && token!.isNotEmpty;
  User? get currentUser => _authService.currentUser;

  String? get token => _authService.currentToken;

  final googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile', 'openid'],
  );


  Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Token $token',
  };

  Future<void> _initializeAuthState() async {
    try {
      notifyListeners();
      
      if (isLoggedIn && token != null) {
        try {
          await _webSocketService.connect(token!);
          if (kDebugMode) {
            developer.log('WebSocket connected on app startup', name: 'AuthProvider');
          }
        } catch (e) {
          if (kDebugMode) {
            developer.log('Failed to connect WebSocket on app startup: $e', name: 'AuthProvider');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error loading stored auth state: $e', name: 'AuthProvider');
      }
    }
  }

  Future<bool> login(String username, String password) async {
    final success = await executeBool(
      () => _authService.login(username, password),
      successMessage: 'Login successful!',
      errorMessage: 'Login failed',
    );
    
    if (success && token != null) {
      _loggingService.updateUserId(userId);
      try {
        await _webSocketService.connect(token!);
        if (kDebugMode) {
          developer.log('WebSocket connected after login', name: 'AuthProvider');
        }
      } catch (e) {
        if (kDebugMode) {
          developer.log('Failed to connect WebSocket after login: $e', name: 'AuthProvider');
        }
      }
    }
    
    return success;
  }

  Future<bool> logout() async {
    try {
      await _webSocketService.disconnect();
      if (kDebugMode) {
        developer.log('WebSocket disconnected before logout', name: 'AuthProvider');
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Failed to disconnect WebSocket before logout: $e', name: 'AuthProvider');
      }
    }
    
    final success = await executeBool(
      () => _authService.logout(),
      successMessage: 'Logged out successfully',
      errorMessage: 'Logout failed',
    );
    
    if (success) {
      _loggingService.updateUserId(null);
    }
    
    return success;
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
        final request = ChangePasswordRequest(email: email, otp: otp, password: password);
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
    );
  }

  Future<bool> signupWithOtp(String username, String email, String password, String otp) async {
    final success = await executeBool(
      () async => await _authService.signupWithOtp(username, email, password, otp),
      successMessage: 'Account created successfully!',
    );
    
    if (success && token != null) {
      try {
        await _webSocketService.connect(token!);
        if (kDebugMode) {
          developer.log('WebSocket connected after signup', name: 'AuthProvider');
        }
      } catch (e) {
        if (kDebugMode) {
          developer.log('Failed to connect WebSocket after signup: $e', name: 'AuthProvider');
        }
      }
    }
    
    return success;
  }

  Future<bool> googleLogin() async {
    final success = await executeBool(
      () async {
        final user = await googleSignIn.signIn();
        if (user == null) throw Exception("Google login failed!");
        
        final socialId = user.id;
        final socialEmail = user.email;
        final socialName = user.displayName;

        final auth = await user.authentication;
        final idToken = auth.idToken;

        if (idToken != null) {
          await _authService.googleLogin(idToken: idToken);
        }
        else {
          await _authService.googleLogin(socialId: socialId, socialEmail: socialEmail, socialName: socialName);
        }
      
      },
      successMessage: 'Google login successful!',
      errorMessage: 'Google login failed',
    );
    
    if (success && token != null) {
      try {
        await _webSocketService.connect(token!);
        if (kDebugMode) {
          developer.log('WebSocket connected after Google login', name: 'AuthProvider');
        }
      } catch (e) {
        if (kDebugMode) {
          developer.log('Failed to connect WebSocket after Google login: $e', name: 'AuthProvider');
        }
      }
    }
    
    return success;
  }

  Future<bool> facebookLogin() async {
    final success = await executeBool(
      () async {
        final LoginResult result = await FacebookAuth.instance.login();
        if (result.status == LoginStatus.success) {
          final fbAccessToken = result.accessToken!.tokenString;
          await _authService.facebookLogin(fbAccessToken);
        } else {
          throw Exception(result.message ?? "Facebook login failed!");
        }
      },
      successMessage: 'Facebook login successful!',
      errorMessage: 'Facebook login failed',
    );
    
    if (success && token != null) {
      try {
        await _webSocketService.connect(token!);
        if (kDebugMode) {
          developer.log('WebSocket connected after Facebook login', name: 'AuthProvider');
        }
      } catch (e) {
        if (kDebugMode) {
          developer.log('Failed to connect WebSocket after Facebook login: $e', name: 'AuthProvider');
        }
      }
    }
    
    return success;
  }

  Future<bool> checkEmailAvailability(String email) async {
    try {
      final result = await _authService.api.checkEmail(email);
      return result['exists'] == false;
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error checking email availability: $e', name: 'AuthProvider');
      }
      return false;
    }
  }

}
