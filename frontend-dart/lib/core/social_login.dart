import 'dart:async';
import 'app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/result_models.dart';

class SocialLoginUtils {
  static GoogleSignIn? _googleSignIn;
  static bool _isInitialized = false;
  static bool _facebookInitialized = false;

  static void _debugLog(String message) {
    AppLogger.debug(message, 'SocialLoginUtils');
  }

  static Future<void> initialize() async {
    if (_isInitialized) { return; }    
    try {
      await _initializeFacebook();
      await _initializeGoogle();
      _isInitialized = true;
      _debugLog('Social login initialization completed successfully');
    } catch (e) {
      _debugLog('Social login initialization error: $e');
      rethrow;
    }
  }

  static Future<void> _initializeFacebook() async {
    try {
      final fbAppId = dotenv.env['FACEBOOK_APP_ID'];
      if (fbAppId == null || fbAppId.isEmpty) {
        _debugLog('Warning: FACEBOOK_APP_ID not found in environment variables');
        return;
      }
      if (kIsWeb) {
        await FacebookAuth.instance.webAndDesktopInitialize(appId: fbAppId, cookie: true, xfbml: true, version: "v18.0");
        _debugLog('Facebook initialized for web');
      } else {
        _debugLog('Facebook SDK configured for mobile platform');
      }
      _facebookInitialized = true;
    } catch (e) {
      _debugLog('Facebook initialization error: $e');
      _facebookInitialized = false;
      rethrow;
    }
  }

  static Future<void> _initializeGoogle() async {
    try {
      final googleClientId = kIsWeb ? dotenv.env['GOOGLE_CLIENT_ID_WEB'] : dotenv.env['GOOGLE_CLIENT_ID_APP'];
      if (googleClientId != null && googleClientId.isNotEmpty) {
        _googleSignIn = GoogleSignIn(
          scopes: <String>['email', 'profile', 'openid'],
        );
        _debugLog('Google Sign-In initialized for ${kIsWeb ? 'web' : 'app'} with client ID: ${googleClientId.substring(0, 20)}...');
      } else {
        _debugLog('Warning: Google Client ID not found in environment variables');
      }
    } catch (e) {
      _debugLog('Google initialization error: $e');
      rethrow;
    }
  }

  static GoogleSignIn? get googleSignInInstance => _googleSignIn;
  static bool get isInitialized => _isInitialized;
  static bool get isFacebookInitialized => _facebookInitialized;

  static Future<SocialLoginResult> loginWithFacebook() async {
    try {
      if (!_isInitialized) {
        _debugLog('Social login not initialized, initializing now...');
        await initialize();
      }

      if (!_facebookInitialized) { return SocialLoginResult.error('Facebook not properly initialized. Please check your configuration.'); }

      _debugLog('Attempting Facebook login...');
      
      try {
        await FacebookAuth.instance.logOut();
      } catch (e) {
        _debugLog('Warning: Could not log out existing Facebook session: $e');
      }

      final result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      _debugLog('Facebook login result status: ${result.status}');

      if (result.status == LoginStatus.success) {
        final accessToken = result.accessToken?.tokenString;
        if (accessToken != null && accessToken.isNotEmpty) {
          _debugLog('Facebook login successful with access token');
          return SocialLoginResult.success(accessToken, 'facebook');
        } else {
          _debugLog('Facebook login failed - no valid token received');
          return SocialLoginResult.error('Facebook login failed - no access token received');
        }
      } else if (result.status == LoginStatus.cancelled) {
        _debugLog('Facebook login was cancelled by user');
        return SocialLoginResult.error('Facebook login was cancelled');
      } else if (result.status == LoginStatus.failed) {
        _debugLog('Facebook login failed: ${result.message}');
        return SocialLoginResult.error('Facebook login failed: ${result.message ?? "Unknown error"}');
      } else {
        _debugLog('Facebook login failed with status: ${result.status}');
        return SocialLoginResult.error('Facebook login failed with unexpected status');
      }
    } catch (e) {
      _debugLog('Facebook login error: $e');
      
      if (e.toString().contains('MissingPluginException')) {
        return SocialLoginResult.error(
          'Facebook login is not properly configured. Please check your platform-specific setup.'
        );
      }
      
      return SocialLoginResult.error('Facebook login error: $e');
    }
  }

  static Future<SocialLoginResult> loginWithGoogle() async {
    if (!_isInitialized) {
      _debugLog('Google Sign-In not initialized, initializing now...');
      await initialize();
    }

    if (_googleSignIn == null) {
      _debugLog('Google Sign-In instance is null after initialization');
      return SocialLoginResult.error(
        'Google Sign-In not properly initialized. Please check your configuration.'
      );
    }

    try {
      await _googleSignIn!.signOut();
      
      final GoogleSignInAccount? user = await _googleSignIn!.signIn();
      
      if (user != null) {
        _debugLog('Google user signed in: ${user.email}');
        final GoogleSignInAuthentication auth = await user.authentication;
        _debugLog('Google auth obtained - idToken: ${auth.idToken != null}');
        
        final idToken = auth.idToken;
        if (idToken != null && idToken.isNotEmpty) {
          _debugLog('Google login successful with idToken');
          return SocialLoginResult.success(idToken, 'google');
        }
      } else {
        _debugLog('Google sign-in was cancelled by user');
        return SocialLoginResult.error('Google sign-in was cancelled');
      }
      
      _debugLog('Google login failed - no valid token received');
      return SocialLoginResult.error('Google login failed - no valid token received');
    } catch (e) {
      _debugLog('Google login error: $e');
      return SocialLoginResult.error('Google login error: $e');
    }
  }
}

class SocialLoginButton extends StatelessWidget {
  final String provider;
  final VoidCallback? onPressed;
  final bool isLoading;

  const SocialLoginButton({super.key, required this.provider, this.onPressed, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    final isGoogle = provider.toLowerCase() == 'google';
    final isFacebook = provider.toLowerCase() == 'facebook';

    IconData icon;
    Color color;
    if (isGoogle) {
      icon = Icons.g_mobiledata;
      color = Colors.red;
    } else if (isFacebook) {
      icon = Icons.facebook;
      color = Colors.blue;
    } else {
      icon = Icons.login;
      color = const Color(0xFF1DB954); 
    }

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF282828), 
          foregroundColor: Colors.white,
          side: BorderSide(color: color),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
        ),
        child: isLoading 
          ? SizedBox(
              width: 20, height: 20, 
              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(color)),
            ) 
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Continue with $provider',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
      ),
    );
  }
}
