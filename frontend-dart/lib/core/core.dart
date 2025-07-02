// lib/core/core.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:form_validator/form_validator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:duration/duration.dart'; 
import '../services/api_service.dart';
import '../models/models.dart';
import 'responsive_helper.dart'; 

export 'responsive_helper.dart';

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
    if (!required && (value?.isEmpty ?? true)) return null;
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{8,15}$');
    return phoneRegex.hasMatch(value ?? '') ? null : 'Please enter a valid phone number';
  }
  
  static String? playlistName(String? value) =>
      ValidationBuilder().maxLength(100, 'Playlist name must be less than 100 characters').build()(value);
  
  static String? description(String? value) =>
      value != null && value.length > 500 ? 'Description must be less than 500 characters' : null;
}

class DateTimeUtils {
  static String formatDate(DateTime? date) => date != null ? DateFormat('yyyy-MM-dd').format(date) : '';
  
  static String formatDuration(Duration duration) {
    return printDuration(duration, abbreviated: false,
      spacer: '',
      delimiter: ':',
      conjugation: '',
      tersity: duration.inHours > 0 ? DurationTersity.hour : DurationTersity.minute,
    );
  }
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
        surface: surface,
        background: background,
        error: error,
        onPrimary: Colors.white,
        onSurface: onSurface,
        onBackground: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background, 
        foregroundColor: Colors.white, 
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
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
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: primary),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 4,
        shadowColor: primary.withOpacity(0.1),
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
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return primary;
          return Colors.grey;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return primary.withOpacity(0.5);
          return Colors.grey.withOpacity(0.3);
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return primary;
          return Colors.transparent;
        }),
        checkColor: const MaterialStatePropertyAll(Colors.black),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: primary.withOpacity(0.3),
        thumbColor: primary,
        overlayColor: primary.withOpacity(0.2),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: primary.withOpacity(0.3),
        circularTrackColor: primary.withOpacity(0.3),
      ),
      dividerTheme: DividerThemeData(color: surface, thickness: 1),
      listTileTheme: ListTileThemeData(textColor: Colors.white, iconColor: primary, selectedColor: primary,
        selectedTileColor: primary.withOpacity(0.1),
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
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kIsWeb ? 8 : 8.r), 
      borderSide: BorderSide.none
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kIsWeb ? 8 : 8.r), 
      borderSide: const BorderSide(color: primary, width: 2)
    ),
    labelStyle: TextStyle(fontSize: kIsWeb ? 16 : 16.sp, color: onSurfaceVariant),
    hintStyle: TextStyle(fontSize: kIsWeb ? 14 : 14.sp, color: onSurfaceVariant.withOpacity(0.7)),
  );

  static Widget _buildCard({
    required Widget child, 
    EdgeInsets? margin, 
    EdgeInsets? padding, 
    double? elevation, 
    double? borderRadius,
  }) => Card(
    color: surface,
    elevation: elevation ?? 4,
    margin: margin ?? EdgeInsets.all(kIsWeb ? 16 : 16.w),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius ?? (kIsWeb ? 16 : 16.r))),
    child: Padding(
      padding: padding ?? EdgeInsets.all(kIsWeb ? 24 : 24.w), 
      child: child
    ),
  );

  static Widget buildHeaderCard({required Widget child}) => _buildCard(child: child, elevation: 8);

  static Widget buildFormCard({
    required String title, 
    IconData? titleIcon, 
    required Widget child
  }) => _buildCard(
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
}

class SocialLoginUtils {
  static GoogleSignIn? _googleSignIn;
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('Initializing social login services...');
      
      final fbAppId = dotenv.env['FACEBOOK_APP_ID'];
      if (kIsWeb && fbAppId != null) {
        await FacebookAuth.instance.webAndDesktopInitialize(
          appId: fbAppId, 
          cookie: true, 
          xfbml: true, 
          version: "v22.0"
        );
        print('Facebook initialized for web');
      }

      final googleClientId = kIsWeb 
          ? dotenv.env['GOOGLE_CLIENT_ID_WEB']
          : dotenv.env['GOOGLE_CLIENT_ID_APP'];
      
      if (googleClientId != null && googleClientId.isNotEmpty) {
        _googleSignIn = GoogleSignIn(
          scopes: <String>[
            'email',
            'profile',
            'openid',
          ],
          clientId: googleClientId,
        );
        print('Google Sign-In initialized for ${kIsWeb ? 'web' : 'app'} with client ID: ${googleClientId.substring(0, 20)}...');
      } else {
        print('Warning: Google Client ID not found in environment variables');
      }

      _isInitialized = true;
      print('Social login initialization completed successfully');
    } catch (e) {
      print('Social login initialization error: $e');
      rethrow;
    }
  }

  static GoogleSignIn? get googleSignInInstance => _googleSignIn;
  static bool get isInitialized => _isInitialized;

  static Future<SocialLoginResult> loginWithFacebook() async {
    if (!_isInitialized) await initialize();

    try {
      print('Attempting Facebook login...');
      final result = await FacebookAuth.instance.login();
      
      if (result.status == LoginStatus.success) {
        final accessToken = result.accessToken?.tokenString;
        if (accessToken != null && accessToken.isNotEmpty) {
          print('Facebook login successful with accessToken');
          return SocialLoginResult.success(accessToken, 'facebook');
        }
      }
      
      print('Facebook login failed - no valid token received');
      return SocialLoginResult.error('Facebook login failed - no valid token received');
    } catch (e) {
      print('Facebook login error: $e');
      return SocialLoginResult.error('Facebook login error: $e');
    }
  }

  static Future<SocialLoginResult> loginWithGoogle() async {
    if (!_isInitialized) {
      print('Google Sign-In not initialized, initializing now...');
      await initialize();
    }

    if (_googleSignIn == null) {
      print('Google Sign-In instance is null after initialization');
      return SocialLoginResult.error('Google Sign-In not properly initialized. Please check your configuration.');
    }

    try {
      await _googleSignIn!.signOut();
      final GoogleSignInAccount? user = await _googleSignIn!.signIn();
      
      if (user != null) {
        print('Google user signed in: ${user.email}');
        final GoogleSignInAuthentication auth = await user.authentication;
        print('Google auth obtained - idToken: ${auth.idToken != null}, accessToken: ${auth.accessToken != null}');
        
        final idToken = auth.idToken;
        if (idToken != null && idToken.isNotEmpty) {
          print('Google login successful with idToken');
          return SocialLoginResult.success(idToken, 'google');
        }
      } else {
        print('Google sign-in was cancelled by user');
        return SocialLoginResult.error('Google sign-in was cancelled');
      }
      
      print('Google login failed - no valid token received');
      return SocialLoginResult.error('Google login failed - no valid token received');
    } catch (e) {
      print('Google login error: $e');
      return SocialLoginResult.error('Google login error: $e');
    }
  }
}

class SocialLoginButton extends StatelessWidget {
  final String provider;
  final VoidCallback? onPressed;
  final bool isLoading;

  const SocialLoginButton({
    Key? key, 
    required this.provider, 
    this.onPressed, 
    this.isLoading = false
  }) : super(key: key);

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
              width: 20, 
              height: 20, 
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
