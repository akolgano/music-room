// lib/utils/social_login_utils.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SocialLoginUtils {
  static GoogleSignIn? _googleSignIn;
  static GoogleSignInPlugin? _googleSignInPlugin;
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (kIsWeb) {
        final fbAppId = dotenv.env['FACEBOOK_APP_ID'];
        if (fbAppId != null) {
          await FacebookAuth.instance.webAndDesktopInitialize(
            appId: fbAppId,
            cookie: true,
            xfbml: true,
            version: "v22.0",
          );
        }
      }

      if (kIsWeb) {
        _googleSignInPlugin = GoogleSignInPlatform.instance as GoogleSignInPlugin;
        final googleClientId = dotenv.env['GOOGLE_CLIENT_ID_WEB'];
        if (googleClientId != null) {
          await _googleSignInPlugin!.initWithParams(
            SignInInitParameters(
              clientId: googleClientId,
              scopes: ['email', 'profile', 'openid'],
            ),
          );
        }
      } else {
        final googleClientId = dotenv.env['GOOGLE_CLIENT_ID_APP'];
        if (googleClientId != null) {
          _googleSignIn = GoogleSignIn(
            scopes: ['email', 'profile', 'openid'],
            clientId: googleClientId,
          );
        }
      }

      _isInitialized = true;
    } catch (e) {
      print('Social login initialization error: $e');
    }
  }

  static Future<SocialLoginResult> loginWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      
      if (result.status == LoginStatus.success) {
        final accessToken = result.accessToken!.tokenString;
        return SocialLoginResult.success(accessToken, 'facebook');
      } else {
        return SocialLoginResult.error('Facebook login failed or was cancelled');
      }
    } catch (e) {
      return SocialLoginResult.error('Facebook login error: $e');
    }
  }

  static Future<SocialLoginResult> loginWithGoogleApp() async {
    try {
      if (_googleSignIn == null) {
        return SocialLoginResult.error('Google Sign-In not initialized');
      }

      final user = await _googleSignIn!.signIn();
      if (user == null) {
        return SocialLoginResult.error('Google login was cancelled');
      }

      final auth = await user.authentication;
      final idToken = auth.idToken;
      
      if (idToken == null) {
        return SocialLoginResult.error('Failed to get Google ID token');
      }

      return SocialLoginResult.success(idToken, 'google_app');
    } catch (e) {
      return SocialLoginResult.error('Google login error: $e');
    }
  }

  static Future<SocialLoginResult> loginWithGoogleWeb() async {
    try {
      if (_googleSignInPlugin == null) {
        return SocialLoginResult.error('Google Sign-In Web not initialized');
      }

      return SocialLoginResult.error('Web Google login should be handled via button callback');
    } catch (e) {
      return SocialLoginResult.error('Google web login error: $e');
    }
  }

  static void setupGoogleWebCallback(Function(GoogleSignInUserData) onSuccess) {
    if (kIsWeb && _googleSignInPlugin != null) {
      _googleSignInPlugin!.userDataEvents?.listen((GoogleSignInUserData? account) {
        if (account != null) {
          onSuccess(account);
        }
      });
    }
  }

  static Widget renderGoogleWebButton() {
    if (kIsWeb && _googleSignInPlugin != null) {
      return _googleSignInPlugin!.renderButton();
    }
    return const SizedBox.shrink();
  }

  static Future<void> signOut() async {
    try {
      await FacebookAuth.instance.logOut();
      if (_googleSignIn != null) {
        await _googleSignIn!.signOut();
      }
    } catch (e) {
      print('Social sign out error: $e');
    }
  }

  static bool get isGoogleAvailable => _googleSignIn != null || _googleSignInPlugin != null;
  static bool get isFacebookAvailable => true; 

  static Future<SocialLoginResult> loginWithGoogle() async {
    if (kIsWeb) {
      return loginWithGoogleWeb();
    } else {
      return loginWithGoogleApp();
    }
  }
}

class SocialLoginResult {
  final bool success;
  final String? token;
  final String? provider;
  final String? error;

  SocialLoginResult.success(this.token, this.provider)
      : success = true,
        error = null;

  SocialLoginResult.error(this.error)
      : success = false,
        token = null,
        provider = null;
}

class SocialLoginButton extends StatelessWidget {
  final String provider;
  final VoidCallback onPressed;
  final bool isLoading;

  const SocialLoginButton({
    Key? key,
    required this.provider,
    required this.onPressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    IconData icon;
    String label;
    
    switch (provider.toLowerCase()) {
      case 'google':
        icon = Icons.g_mobiledata;
        label = 'GOOGLE';
        break;
      case 'facebook':
        icon = Icons.facebook;
        label = 'FACEBOOK';
        break;
      default:
        icon = Icons.login;
        label = provider.toUpperCase();
    }

    return OutlinedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading 
        ? const SizedBox(
            width: 16, 
            height: 16, 
            child: CircularProgressIndicator(strokeWidth: 2)
          )
        : Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      ),
    );
  }
}
