import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/result_models.dart';

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
      if (kDebugMode) {
        developer.log('Social login initialization completed successfully', name: 'SocialLoginUtils');
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Social login initialization error: $e', name: 'SocialLoginUtils');
      }
      rethrow;
    }
  }

  static Future<void> _initializeFacebook() async {
    try {
      final fbAppId = dotenv.env['FACEBOOK_APP_ID'];
      if (fbAppId == null || fbAppId.isEmpty) {
        if (kDebugMode) {
          developer.log('Warning: FACEBOOK_APP_ID not found in environment variables', name: 'SocialLoginUtils');
        }
        return;
      }
      if (kIsWeb) {
        await FacebookAuth.instance.webAndDesktopInitialize(appId: fbAppId, cookie: true, xfbml: true, version: "v18.0");
        if (kDebugMode) {
          developer.log('Facebook initialized for web', name: 'SocialLoginUtils');
        }
      } else {
        if (kDebugMode) {
          developer.log('Facebook SDK configured for mobile platform', name: 'SocialLoginUtils');
        }
      }
      _facebookInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        developer.log('Facebook initialization error: $e', name: 'SocialLoginUtils');
      }
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
        if (kDebugMode) {
          developer.log('Google Sign-In initialized for ${kIsWeb ? 'web' : 'app'} with client ID: ${googleClientId.substring(0, 20)}...', name: 'SocialLoginUtils');
        }
      } else {
        if (kDebugMode) {
          developer.log('Warning: Google Client ID not found in environment variables', name: 'SocialLoginUtils');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Google initialization error: $e', name: 'SocialLoginUtils');
      }
      rethrow;
    }
  }

  static GoogleSignIn? get googleSignInInstance => _googleSignIn;
  static bool get isInitialized => _isInitialized;
  static bool get isFacebookInitialized => _facebookInitialized;

  static Future<SocialLoginResult> loginWithFacebook() async {
    try {
      if (!_isInitialized) {
        if (kDebugMode) {
          developer.log('Social login not initialized, initializing now...', name: 'SocialLoginUtils');
        }
        await initialize();
      }

      if (!_facebookInitialized) { return SocialLoginResult.error('Facebook not properly initialized. Please check your configuration.'); }

      if (kDebugMode) {
        developer.log('Attempting Facebook login...', name: 'SocialLoginUtils');
      }
      
      try {
        await FacebookAuth.instance.logOut();
      } catch (e) {
        if (kDebugMode) {
          developer.log('Warning: Could not log out existing Facebook session: $e', name: 'SocialLoginUtils');
        }
      }

      final result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (kDebugMode) {
        developer.log('Facebook login result status: ${result.status}', name: 'SocialLoginUtils');
      }

      if (result.status == LoginStatus.success) {
        final accessToken = result.accessToken?.tokenString;
        if (accessToken != null && accessToken.isNotEmpty) {
          if (kDebugMode) {
            developer.log('Facebook login successful with access token', name: 'SocialLoginUtils');
          }
          return SocialLoginResult.success(accessToken, 'facebook');
        } else {
          if (kDebugMode) {
            developer.log('Facebook login failed - no valid token received', name: 'SocialLoginUtils');
          }
          return SocialLoginResult.error('Facebook login failed - no access token received');
        }
      } else if (result.status == LoginStatus.cancelled) {
        if (kDebugMode) {
          developer.log('Facebook login was cancelled by user', name: 'SocialLoginUtils');
        }
        return SocialLoginResult.error('Facebook login was cancelled');
      } else if (result.status == LoginStatus.failed) {
        if (kDebugMode) {
          developer.log('Facebook login failed: ${result.message}', name: 'SocialLoginUtils');
        }
        return SocialLoginResult.error('Facebook login failed: ${result.message ?? "Unknown error"}');
      } else {
        if (kDebugMode) {
          developer.log('Facebook login failed with status: ${result.status}', name: 'SocialLoginUtils');
        }
        return SocialLoginResult.error('Facebook login failed with unexpected status');
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Facebook login error: $e', name: 'SocialLoginUtils');
      }
      
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
      if (kDebugMode) {
        developer.log('Google Sign-In not initialized, initializing now...', name: 'SocialLoginUtils');
      }
      await initialize();
    }

    if (_googleSignIn == null) {
      if (kDebugMode) {
        developer.log('Google Sign-In instance is null after initialization', name: 'SocialLoginUtils');
      }
      return SocialLoginResult.error(
        'Google Sign-In not properly initialized. Please check your configuration.'
      );
    }

    try {
      await _googleSignIn!.signOut();
      
      final GoogleSignInAccount? user = await _googleSignIn!.signIn();
      
      if (user != null) {
        if (kDebugMode) {
          developer.log('Google user signed in: ${user.email}', name: 'SocialLoginUtils');
        }
        final GoogleSignInAuthentication auth = await user.authentication;
        if (kDebugMode) {
          developer.log('Google auth obtained - idToken: ${auth.idToken != null}', name: 'SocialLoginUtils');
        }
        
        final idToken = auth.idToken;
        if (idToken != null && idToken.isNotEmpty) {
          if (kDebugMode) {
            developer.log('Google login successful with idToken', name: 'SocialLoginUtils');
          }
          return SocialLoginResult.success(idToken, 'google');
        }
      } else {
        if (kDebugMode) {
          developer.log('Google sign-in was cancelled by user', name: 'SocialLoginUtils');
        }
        return SocialLoginResult.error('Google sign-in was cancelled');
      }
      
      if (kDebugMode) {
        developer.log('Google login failed - no valid token received', name: 'SocialLoginUtils');
      }
      return SocialLoginResult.error('Google login failed - no valid token received');
    } catch (e) {
      if (kDebugMode) {
        developer.log('Google login error: $e', name: 'SocialLoginUtils');
      }
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
      color = const Color(0xFF1DB954); // AppTheme.primary
    }

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF282828), // AppTheme.surface
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