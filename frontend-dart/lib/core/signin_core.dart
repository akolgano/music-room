import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInCore {
  static final GoogleSignIn _instance = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: kIsWeb ? null : '554843341079-624c05j4vgscahelnj7j7oa8njlau04m.apps.googleusercontent.com',
  );
  
  static GoogleSignIn get instance => _instance;
  
  static Future<void> clearCache() async {
    try {
      try {
        await _instance.disconnect();
        if (kDebugMode) {
          print('GoogleSignInCore: Disconnected successfully');
        }
      } catch (e) {
        if (kDebugMode) {
          print('GoogleSignInCore: Disconnect error (continuing): $e');
        }
      }
      
      try {
        await _instance.signOut();
        if (kDebugMode) {
          print('GoogleSignInCore: Signed out successfully');
        }
      } catch (e) {
        if (kDebugMode) {
          print('GoogleSignInCore: Sign out error: $e');
        }
      }
      
      if (kDebugMode) {
        print('GoogleSignInCore: Cache cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('GoogleSignInCore: Error clearing cache: $e');
      }
    }
  }
  
  static Future<void> resetGoogleSignIn() async {
    try {
      await clearCache();
      if (kDebugMode) {
        print('GoogleSignInCore: Reset complete');
      }
    } catch (e) {
      if (kDebugMode) {
        print('GoogleSignInCore: Reset error: $e');
      }
      rethrow;
    }
  }
}