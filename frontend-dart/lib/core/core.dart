import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:form_validator/form_validator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import '../models/models.dart';

class AppValidators {
  static String? required(String? value, [String? fieldName]) =>
      ValidationBuilder().required('Please enter ${fieldName ?? 'this field'}').build()(value);
  
  static String? email(String? value) =>
      ValidationBuilder().email('Please enter a valid email address').build()(value);
  
  static String? password(String? value, [int minLength = 8]) =>
      ValidationBuilder().minLength(minLength, 'Password must be at least $minLength characters').build()(value);
  
  static String? username(String? value) =>
      ValidationBuilder()
          .minLength(3, 'Username must be at least 3 characters')
          .maxLength(30, 'Username must be less than 30 characters')
          .regExp(RegExp(r'^[a-zA-Z0-9_]+$'), 'Username can only contain letters, numbers, and underscores').build()(value);

  static String? phoneNumber(String? value, [bool required = false]) {
    if (!required && (value?.isEmpty ?? true)) { return null; }
    if (value == null || value.trim().isEmpty) { return required ? 'Please enter a phone number' : null; }
    try {
      final phoneNumber = PhoneNumber.parse(value.trim());
      if (phoneNumber.isValid()) { return null; }
      else { return 'Please enter a valid phone number'; }
    } catch (e) {
      return 'Please enter a valid phone number';
    }
  }
  
  static String? playlistName(String? value) =>
      ValidationBuilder().maxLength(100, 'Playlist name must be less than 100 characters').build()(value);
  
  static String? description(String? value) =>
      value != null && value.length > 500 ? 'Description must be less than 500 characters' : null;
}

class AppTheme {
  static const primary = Color(0xFF1DB954);
  static const background = Color(0xFF121212);
  static const surface = Color(0xFF282828);
  static const surfaceVariant = Color(0xFF333333);
  static const onSurface = Color(0xFFFFFFFF);
  static const onSurfaceVariant = Color(0xFFB3B3B3);
  static const textSecondary = Color(0xFFB3B3B3);
  static const error = Color(0xFFE91429);
  static const success = Color(0xFF00C851);

  static ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true, 
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      cardColor: surface,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        surface: background,
        error: error,
        onPrimary: Colors.white,
        onSurface: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background, 
        foregroundColor: Colors.white, 
        elevation: 0,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black,
          minimumSize: const Size(88, 50), 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: primary)),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: BorderSide(color: primary)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1)
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), 
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1)
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 1),
        ),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
      ),
      cardTheme: CardThemeData(color: surface,
        elevation: 4,
        shadowColor: primary.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      iconTheme: IconThemeData(color: primary),
      primaryIconTheme: const IconThemeData(color: Colors.white),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.black,
        elevation: 6,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: Colors.white60,
        type: BottomNavigationBarType.fixed,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: Colors.white70,
        indicatorColor: primary,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary.withValues(alpha: 0.5);
          return Colors.grey.withValues(alpha: 0.3);
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.transparent;
        }),
        checkColor: const WidgetStatePropertyAll(Colors.black),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: primary.withValues(alpha: 0.3),
        thumbColor: primary,
        overlayColor: primary.withValues(alpha: 0.2),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: primary.withValues(alpha: 0.3),
        circularTrackColor: primary.withValues(alpha: 0.3),
      ),
      dividerTheme: DividerThemeData(color: surface, thickness: 1),
      listTileTheme: ListTileThemeData(textColor: Colors.white, iconColor: primary, selectedColor: primary,
        selectedTileColor: primary.withValues(alpha: 0.1),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
        titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
        titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.white),
        bodySmall: TextStyle(fontSize: 12, color: Colors.white70),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
        labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white),
      ),
    );
  }

  static ThemeData get darkTheme => _buildTheme();

  static InputDecoration getInputDecoration({required String labelText, String? hintText, IconData? prefixIcon}) => InputDecoration(
    labelText: labelText,
    hintText: hintText,
    prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: onSurfaceVariant) : null,
    filled: true,
    fillColor: surfaceVariant,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(kIsWeb ? 8 : 8.r),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1)
    ),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kIsWeb ? 8 : 8.r), 
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1)
    ),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kIsWeb ? 8 : 8.r), 
      borderSide: const BorderSide(color: primary, width: 2)
    ),
    labelStyle: TextStyle(fontSize: kIsWeb ? 16 : 16.sp, color: onSurfaceVariant),
    hintStyle: TextStyle(fontSize: kIsWeb ? 14 : 14.sp, color: onSurfaceVariant.withValues(alpha: 0.7)),
  );

  static Widget _buildCard({
    required Widget child, 
    EdgeInsets? margin, 
    EdgeInsets? padding, 
    double? elevation, double? borderRadius
  }) => Card(
    color: surface,
    elevation: elevation ?? 4,
    margin: margin ?? EdgeInsets.all(kIsWeb ? 16 : 16.w),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius ?? (kIsWeb ? 16 : 16.r))  
    ),
    child: Padding(padding: padding ?? EdgeInsets.all(kIsWeb ? 24 : 24.w), child: child),
  );

  static Widget buildHeaderCard({required Widget child}) => _buildCard(child: child, elevation: 8);

  static Widget buildFormCard({required String title, IconData? titleIcon, required Widget child}) => _buildCard(
    borderRadius: kIsWeb ? 12 : 12.r,
    padding: EdgeInsets.all(kIsWeb ? 20 : 20.w),
    margin: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (titleIcon != null) ...[
              Icon(titleIcon, color: primary, size: kIsWeb ? 20 : 20.sp), 
              SizedBox(width: kIsWeb ? 8 : 8.w)
            ],
            Flexible(
              child: Text(title, 
                style: TextStyle(fontSize: kIsWeb ? 18 : 18.sp, fontWeight: FontWeight.bold, color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ), 
            ),
          ],
        ),
        SizedBox(height: kIsWeb ? 16 : 16.h), 
        child,
      ],
    ),
  );
}

class AppConstants {
  static const String appName = 'Music Room';
  static const String version = '1.0.0';
  static const String defaultApiBaseUrl = 'http://localhost:8000';
  static const String contentTypeJson = 'application/json';
  static const String authorizationPrefix = 'Token';
  static const int minPasswordLength = 8;
}

class AppStrings {
  static const String confirmLogout = 'Are you sure you want to sign out?';
  static const String networkError = 'Network error. Please check your connection.';
  static const String unknownError = 'An unknown error occurred.';
}

class AppRoutes {
  static const String home = '/home';
  static const String auth = '/auth';
  static const String profile = '/profile';
  static const String playlistEditor = '/playlist_editor';
  static const String playlistDetail = '/playlist_detail';
  static const String trackDetail = '/track_detail';
  static const String trackSearch = '/track_search';
  static const String publicPlaylists = '/public_playlists';
  static const String friends = '/friends';
  static const String addFriend = '/add_friend';
  static const String friendRequests = '/friend_requests';
  static const String playlistSharing = '/playlist_sharing';
  static const String player = '/player';
  static const String userPasswordChange = '/user_password_change';
  static const String socialNetworkLink = '/social_network_link';
  static const String signupOtp = '/signup_otp';
  static const String deezerAuth = '/deezer_auth';
}

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
      color = AppTheme.primary;
    }

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.surface,
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
