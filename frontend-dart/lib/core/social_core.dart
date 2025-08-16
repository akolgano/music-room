import 'dart:async';
import 'navigation_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SocialLoginUtils {
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
      
      
      _isInitialized = true;
      AppLogger.debug('Social login initialization completed successfully', 'SocialLoginUtils');
    } catch (e) {
      AppLogger.debug('Social login initialization error: $e', 'SocialLoginUtils');
      rethrow;
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
