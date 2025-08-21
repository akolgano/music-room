import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInCore {
  static final GoogleSignIn _instance = GoogleSignIn.instance;
  
  static bool _isInitialized = false;
  static StreamSubscription? _authEventSubscription;
  
  static GoogleSignIn get instance => _instance;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      if (kDebugMode) {
        print('GoogleSignInCore: Starting initialization');
        print('GoogleSignInCore: Platform is ${kIsWeb ? "Web" : "Mobile"}');
        print('GoogleSignInCore: Using google_sign_in v7 API');
      }
      
      await _instance.initialize(
        serverClientId: '554843341079-624c05j4vgscahelnj7j7oa8njlau04m.apps.googleusercontent.com',
      );
      
      _authEventSubscription?.cancel();
      _authEventSubscription = _instance.authenticationEvents.listen(
        (GoogleSignInAuthenticationEvent event) {
          if (kDebugMode) {
            print('GoogleSignInCore: Auth event received: $event');
          }
        },
        onError: (error) {
          if (kDebugMode) {
            print('GoogleSignInCore: Auth error: $error');
          }
        },
      );
      
      _isInitialized = true;
      
      if (kDebugMode) {
        print('GoogleSignInCore: Initialization complete');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('GoogleSignInCore initialization error: $e');
      }
      rethrow;
    }
  }
  
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
      _isInitialized = false;
      _authEventSubscription?.cancel();
      _authEventSubscription = null;
      await initialize();
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
  
  static void dispose() {
    _authEventSubscription?.cancel();
    _authEventSubscription = null;
  }
}
