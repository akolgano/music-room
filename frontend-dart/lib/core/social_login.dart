import 'dart:async';
import 'logging_navigation_observer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/api_models.dart';

class SocialLoginUtils {
  static GoogleSignIn? _googleSignIn;
  static bool _isInitialized = false;
  static bool _facebookInitialized = false;


  static Future<void> initialize() async {
    if (_isInitialized) { return; }    
    try {
      await _initializeFacebook();
      await _initializeGoogle();
      _isInitialized = true;
      AppLogger.debug('Social login initialization completed successfully', 'SocialLoginUtils');
    } catch (e) {
      AppLogger.debug('Social login initialization error: $e', 'SocialLoginUtils');
      rethrow;
    }
  }

  static Future<void> _initializeFacebook() async {
    try {
      final fbAppId = dotenv.env['FACEBOOK_APP_ID'];
      if (fbAppId == null || fbAppId.isEmpty) {
        AppLogger.debug('Warning: FACEBOOK_APP_ID not found in environment variables', 'SocialLoginUtils');
        return;
      }
      if (kIsWeb) {
        await FacebookAuth.instance.webAndDesktopInitialize(appId: fbAppId, cookie: true, xfbml: true, version: "v18.0");
        AppLogger.debug('Facebook initialized for web', 'SocialLoginUtils');
      } else {
        AppLogger.debug('Facebook SDK configured for mobile platform', 'SocialLoginUtils');
      }
      _facebookInitialized = true;
    } catch (e) {
      AppLogger.debug('Facebook initialization error: $e', 'SocialLoginUtils');
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
        AppLogger.debug('Google Sign-In initialized for ${kIsWeb ? 'web' : 'app'} with client ID: ${googleClientId.substring(0, 20)}...', 'SocialLoginUtils');
      } else {
        AppLogger.debug('Warning: Google Client ID not found in environment variables', 'SocialLoginUtils');
      }
    } catch (e) {
      AppLogger.debug('Google initialization error: $e', 'SocialLoginUtils');
      rethrow;
    }
  }

  static bool get isInitialized => _isInitialized;
  static bool get isFacebookInitialized => _facebookInitialized;

  static Future<SocialLoginResult> loginWithFacebook() async {
    try {
      if (!_isInitialized) {
        AppLogger.debug('Social login not initialized, initializing now...', 'SocialLoginUtils');
        await initialize();
      }

      if (!_facebookInitialized) { return SocialLoginResult.error('Facebook not properly initialized. Please check your configuration.'); }

      AppLogger.debug('Attempting Facebook login...', 'SocialLoginUtils');
      
      try {
        await FacebookAuth.instance.logOut();
      } catch (e) {
        AppLogger.debug('Warning: Could not log out existing Facebook session: $e', 'SocialLoginUtils');
      }

      final result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      AppLogger.debug('Facebook login result status: ${result.status}', 'SocialLoginUtils');

      if (result.status == LoginStatus.success) {
        final accessToken = result.accessToken?.tokenString;
        if (accessToken != null && accessToken.isNotEmpty) {
          AppLogger.debug('Facebook login successful with access token', 'SocialLoginUtils');
          return SocialLoginResult.success(accessToken, 'facebook');
        } else {
          AppLogger.debug('Facebook login failed - no valid token received', 'SocialLoginUtils');
          return SocialLoginResult.error('Facebook login failed - no access token received');
        }
      } else if (result.status == LoginStatus.cancelled) {
        AppLogger.debug('Facebook login was cancelled by user', 'SocialLoginUtils');
        return SocialLoginResult.error('Facebook login was cancelled');
      } else if (result.status == LoginStatus.failed) {
        AppLogger.debug('Facebook login failed: ${result.message}', 'SocialLoginUtils');
        return SocialLoginResult.error('Facebook login failed: ${result.message ?? "Unknown error"}');
      } else {
        AppLogger.debug('Facebook login failed with status: ${result.status}', 'SocialLoginUtils');
        return SocialLoginResult.error('Facebook login failed with unexpected status');
      }
    } catch (e) {
      AppLogger.debug('Facebook login error: $e', 'SocialLoginUtils');
      
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
      AppLogger.debug('Google Sign-In not initialized, initializing now...', 'SocialLoginUtils');
      await initialize();
    }

    if (_googleSignIn == null) {
      AppLogger.debug('Google Sign-In instance is null after initialization', 'SocialLoginUtils');
      return SocialLoginResult.error(
        'Google Sign-In not properly initialized. Please check your configuration.'
      );
    }

    try {
      await _googleSignIn!.signOut();
      
      final GoogleSignInAccount? user = await _googleSignIn!.signIn();
      
      if (user != null) {
        AppLogger.debug('Google user signed in: ${user.email}', 'SocialLoginUtils');
        final GoogleSignInAuthentication auth = await user.authentication;
        AppLogger.debug('Google auth obtained - idToken: ${auth.idToken != null}', 'SocialLoginUtils');
        
        final idToken = auth.idToken;
        if (idToken != null && idToken.isNotEmpty) {
          AppLogger.debug('Google login successful with idToken', 'SocialLoginUtils');
          return SocialLoginResult.success(idToken, 'google');
        }
      } else {
        AppLogger.debug('Google sign-in was cancelled by user', 'SocialLoginUtils');
        return SocialLoginResult.error('Google sign-in was cancelled');
      }
      
      AppLogger.debug('Google login failed - no valid token received', 'SocialLoginUtils');
      return SocialLoginResult.error('Google login failed - no valid token received');
    } catch (e) {
      AppLogger.debug('Google login error: $e', 'SocialLoginUtils');
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
