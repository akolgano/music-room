import 'dart:async';
import 'navigation_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/api_models.dart';

class SocialLoginUtils {
  static GoogleSignIn? _googleSignIn;
  static bool _isInitialized = false;


  static Future<void> initialize() async {
    if (_isInitialized) { return; }    
    try {
      final fbAppId = dotenv.env['FACEBOOK_APP_ID'];
      if (fbAppId != null && fbAppId.isNotEmpty) {
        if (kIsWeb) {
          await FacebookAuth.instance.webAndDesktopInitialize(appId: fbAppId, cookie: true, xfbml: true, version: "v18.0");
        }
      }
      
      final googleClientId = kIsWeb ? dotenv.env['GOOGLE_CLIENT_ID_WEB'] : dotenv.env['GOOGLE_CLIENT_ID_APP'];
      if (googleClientId != null && googleClientId.isNotEmpty) {
        _googleSignIn = GoogleSignIn(
          scopes: <String>['email', 'profile', 'openid'],
        );
        AppLogger.debug('Google Sign-In initialized for ${kIsWeb ? 'web' : 'app'} with client ID: ${googleClientId.substring(0, 20)}...', 'SocialLoginUtils');
      } else {
        AppLogger.debug('Warning: Google Client ID not found in environment variables', 'SocialLoginUtils');
      }
      
      _isInitialized = true;
      AppLogger.debug('Social login initialization completed successfully', 'SocialLoginUtils');
    } catch (e) {
      AppLogger.debug('Social login initialization error: $e', 'SocialLoginUtils');
      rethrow;
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
    final providerLower = provider.toLowerCase();
    
    late IconData icon;
    late Color color;
    
    switch (providerLower) {
      case 'google':
        icon = Icons.g_mobiledata;
        color = Colors.red;
        break;
      case 'facebook':
        icon = Icons.facebook;
        color = Colors.blue;
        break;
      default:
        throw ArgumentError('Unsupported social login provider: $provider');
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
