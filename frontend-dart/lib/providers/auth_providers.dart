import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../core/provider_core.dart';
import '../core/locator_core.dart';
import '../services/auth_services.dart';
import '../services/websocket_services.dart';
import '../services/logging_services.dart';
import '../services/player_services.dart';
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
  bool get hasValidToken => token != null && token!.isNotEmpty;
  User? get currentUser => _authService.currentUser;

  String? get token => _authService.currentToken;

  GoogleSignIn get googleSignIn => GoogleSignInCore.instance;

  Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Token $token',
  };

  Future<void> _initializeAuthState() async {
    try {
      if (token != null && currentUser == null) {
        await _authService.refreshCurrentUser();
      }
      notifyListeners();
      
      if (isLoggedIn && token != null) {
        if (kDebugMode) {
          developer.log('User authenticated on app startup with user: ${currentUser?.username}', name: 'AuthProvider');
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
    }
    
    return success;
  }

  Future<bool> logout() async {
    try {
      final playerService = getIt<MusicPlayerService>();
      await playerService.stop();
      if (kDebugMode) {
        developer.log('Music player stopped before logout', name: 'AuthProvider');
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Failed to stop music player before logout: $e', name: 'AuthProvider');
      }
    }

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

  Future<bool> resetPasswordWithOtp(String email, String otp, String newPassword) async {
    return await executeBool(
      () async {
        final request = ChangePasswordRequest(email: email, otp: otp, password: newPassword);
        await _authService.api.forgotChangePassword(request);
      },
      successMessage: 'Password reset successfully',
      errorMessage: 'Failed to reset password',
    );
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    return await executeBool(
      () async {
        final request = ForgotPasswordRequest(email: email);
        await _authService.api.forgotPassword(request);
      },
      successMessage: 'Password reset email sent',
      errorMessage: 'Failed to send reset email',
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
    
    return success;
  }

  Future<bool> googleLogin() async {
    final success = await executeBool(
      () async {
        if (kDebugMode) {
          developer.log('Starting Google Sign-In process', name: 'AuthProvider');
          developer.log('Platform: ${kIsWeb ? "Web" : "Android"}', name: 'AuthProvider');
          developer.log('Using google_sign_in v6 API', name: 'AuthProvider');
        }
        
        try {
          await googleSignIn.signOut();
          if (kDebugMode) {
            developer.log('Signed out previous session', name: 'AuthProvider');
          }
        } catch (e) {
          if (kDebugMode) {
            developer.log('No previous session: $e', name: 'AuthProvider');
          }
        }
        
        if (kDebugMode) {
          developer.log('Showing Google account picker...', name: 'AuthProvider');
        }
        
        final user = await googleSignIn.signIn();
        
        
        if (user == null) {
          throw Exception('Google Sign-In failed: No user returned');
        }
        
        final socialId = user.id;
        final socialEmail = user.email;
        final socialName = user.displayName;
        
        if (kDebugMode) {
          developer.log('Google Sign-In successful: $socialEmail', name: 'AuthProvider');
        }
        
        if (kIsWeb) {
          if (kDebugMode) {
            developer.log('Web platform - using social credentials', name: 'AuthProvider');
          }
          await _authService.googleLogin(
            socialId: socialId,
            socialEmail: socialEmail,
            socialName: socialName
          );
        } else {
          final auth = await user.authentication;
          final idToken = auth.idToken;
          
          if (kDebugMode) {
            developer.log('Android platform - using idToken', name: 'AuthProvider');
            developer.log('idToken present: ${idToken != null && idToken.isNotEmpty}', name: 'AuthProvider');
          }
          
          if (idToken != null && idToken.isNotEmpty) {
            await _authService.googleLogin(idToken: idToken);
          } else {
            if (kDebugMode) {
              developer.log('No idToken, falling back to social credentials', name: 'AuthProvider');
            }
            await _authService.googleLogin(
              socialId: socialId,
              socialEmail: socialEmail,
              socialName: socialName
            );
          }
        }
      },
      successMessage: 'Google login successful!',
      errorMessage: null,
    );
    
    return success;
  }

  Future<bool> handleWebGoogleSignIn(GoogleSignInAccount user) async {
    final success = await executeBool(
      () async {
        final socialId = user.id;
        final socialEmail = user.email;
        final socialName = user.displayName;
        
        if (kDebugMode) {
          developer.log('Web Google Sign-In successful: $socialEmail', name: 'AuthProvider');
        }
        
        await _authService.googleLogin(
          socialId: socialId,
          socialEmail: socialEmail,
          socialName: socialName
        );
      },
      successMessage: 'Google login successful!',
      errorMessage: null,
    );
    
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
          final message = result.message ?? "Facebook login failed";
          if (result.status == LoginStatus.cancelled) {
            throw Exception("Facebook login was cancelled");
          } else if (result.status == LoginStatus.failed) {
            throw Exception("Facebook login failed: $message");
          } else {
            throw Exception("Facebook login failed: $message");
          }
        }
      },
      successMessage: 'Facebook login successful!',
      errorMessage: null,
    );
    
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
