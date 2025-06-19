// lib/core/consolidated_core.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:form_validator/form_validator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/api_service.dart';

class AppValidators {
  static String? required(String? value, [String? fieldName]) =>
      ValidationBuilder().required('Please enter ${fieldName ?? 'this field'}').build()(value);

  static String? email(String? value) =>
      ValidationBuilder().email('Please enter a valid email address').build()(value);

  static String? password(String? value, [int minLength = 8]) =>
      ValidationBuilder().minLength(minLength, 'Password must be at least $minLength characters').build()(value);

  static String? confirmPassword(String? value, String? originalPassword) =>
      value != originalPassword ? 'Passwords do not match' : null;

  static String? username(String? value) =>
      ValidationBuilder()
          .minLength(3, 'Username must be at least 3 characters')
          .maxLength(30, 'Username must be less than 30 characters')
          .regExp(RegExp(r'^[a-zA-Z0-9_]+$'), 'Username can only contain letters, numbers, and underscores')
          .build()(value);

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
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return duration.inHours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
}

class AsyncUtils {
  static Future<bool> executeSimple<T>({
    required Future<T> Function() operation,
    Function(String)? onError,
    Function(T)? onSuccess,
  }) async {
    try {
      final result = await operation();
      onSuccess?.call(result);
      return true;
    } catch (e) {
      onError?.call(e.toString());
      return false;
    }
  }
}

mixin StateManagement on ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get hasError => _errorMessage != null;
  bool get hasSuccess => _successMessage != null;
  bool get isReady => !_isLoading && !hasError;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    if (loading) clearMessages();
    notifyListeners();
  }

  void setError(String error) {
    _errorMessage = error;
    _successMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  void setSuccess(String message) {
    _successMessage = message;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<T?> executeAsync<T>(Future<T> Function() operation, {String? successMessage, String? errorMessage}) async {
    setLoading(true);
    try {
      final result = await operation();
      if (successMessage != null) setSuccess(successMessage);
      return result;
    } catch (e) {
      setError(errorMessage ?? e.toString());
      return null;
    } finally {
      setLoading(false);
    }
  }
}

abstract class BaseProvider extends ChangeNotifier with StateManagement {}

mixin AsyncOperationStateMixin<T extends StatefulWidget> on State<T> {
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get hasError => _errorMessage != null;
  bool get hasSuccess => _successMessage != null;

  void clearMessages() => setState(() {
    _errorMessage = null;
    _successMessage = null;
  });

  void setError(String error) => setState(() {
    _errorMessage = error;
    _successMessage = null;
    _isLoading = false;
  });

  void setSuccess(String message) => setState(() {
    _successMessage = message;
    _errorMessage = null;
    _isLoading = false;
  });

  void setLoading(bool loading) => setState(() {
    _isLoading = loading;
    if (loading) {
      _errorMessage = null;
      _successMessage = null;
    }
  });

  Future<bool> executeBool({
    required Future<void> Function() operation,
    String? successMessage,
    String? errorMessage,
    VoidCallback? onSuccess,
  }) async {
    setLoading(true);
    try {
      await operation();
      if (successMessage != null) setSuccess(successMessage);
      onSuccess?.call();
      return true;
    } catch (e) {
      setError(errorMessage ?? e.toString());
      return false;
    } finally {
      setLoading(false);
    }
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

  static ThemeData _buildTheme({bool responsive = false}) {
    double fontSize(double size) => responsive && !kIsWeb ? size.sp : size;
    double dimension(double size) => responsive && !kIsWeb ? size.w : size;
    double radius(double size) => responsive && !kIsWeb ? size.r : size;
    EdgeInsets padding(double size) => responsive && !kIsWeb ? EdgeInsets.all(size.w) : EdgeInsets.all(size);

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
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: fontSize(20),
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black,
          minimumSize: Size(dimension(88), dimension(50)), 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius(25))),
          textStyle: TextStyle(fontSize: fontSize(16), fontWeight: FontWeight.w600),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: fontSize(32), fontWeight: FontWeight.bold, color: Colors.white),
        displayMedium: TextStyle(fontSize: fontSize(28), fontWeight: FontWeight.bold, color: Colors.white),
        displaySmall: TextStyle(fontSize: fontSize(24), fontWeight: FontWeight.bold, color: Colors.white),
        headlineLarge: TextStyle(fontSize: fontSize(22), fontWeight: FontWeight.w600, color: Colors.white),
        headlineMedium: TextStyle(fontSize: fontSize(20), fontWeight: FontWeight.w600, color: Colors.white),
        headlineSmall: TextStyle(fontSize: fontSize(18), fontWeight: FontWeight.w600, color: Colors.white),
        titleLarge: TextStyle(fontSize: fontSize(16), fontWeight: FontWeight.w500, color: Colors.white),
        titleMedium: TextStyle(fontSize: fontSize(14), fontWeight: FontWeight.w500, color: Colors.white),
        titleSmall: TextStyle(fontSize: fontSize(12), fontWeight: FontWeight.w500, color: Colors.white),
        bodyLarge: TextStyle(fontSize: fontSize(16), color: Colors.white),
        bodyMedium: TextStyle(fontSize: fontSize(14), color: Colors.white),
        bodySmall: TextStyle(fontSize: fontSize(12), color: Colors.white70),
        labelLarge: TextStyle(fontSize: fontSize(14), fontWeight: FontWeight.w500, color: Colors.white),
        labelMedium: TextStyle(fontSize: fontSize(12), fontWeight: FontWeight.w500, color: Colors.white),
        labelSmall: TextStyle(fontSize: fontSize(10), fontWeight: FontWeight.w500, color: Colors.white),
      ),
    );
  }

  static ThemeData get darkTheme => _buildTheme();
  static ThemeData getResponsiveDarkTheme() => _buildTheme(responsive: true);

  static InputDecoration getInputDecoration({
    required String labelText, 
    String? hintText, 
    IconData? prefixIcon
  }) => InputDecoration(
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
              child: Text(
                title, 
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

class AppSizes {
  static EdgeInsets get screenPadding => const EdgeInsets.all(16);
  static EdgeInsets get cardPadding => const EdgeInsets.all(16);
  static double get borderRadius => 8;
  static double get iconSize => 24;
}

class AppDurations {
  static const Duration shortDelay = Duration(milliseconds: 300);
  static const Duration mediumDelay = Duration(milliseconds: 500);
  static const Duration longDelay = Duration(seconds: 1);
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
  static const String deviceManagement = '/device_management';
  static const String playlistSharing = '/playlist_sharing';
  static const String trackSelection = '/track_selection';
  static const String player = '/player';
  static const String controlDelegation = '/control_delegation';
  static const String musicFeatures = '/music_features';
  static const String trackVote = '/track_vote';
  static const String deezerTrackDetail = '/deezer_track_detail';
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
      final fbAppId = dotenv.env['FACEBOOK_APP_ID'];
      if (kIsWeb && fbAppId != null) {
        await FacebookAuth.instance.webAndDesktopInitialize(appId: fbAppId, cookie: true, xfbml: true, version: "v22.0");
      }
      if (!kIsWeb) {
        final googleClientId = dotenv.env['GOOGLE_CLIENT_ID_APP'];
        if (googleClientId != null) {
          _googleSignIn = GoogleSignIn(scopes: ['email', 'profile', 'openid'], clientId: googleClientId);
        }
      }
      _isInitialized = true;
    } catch (e) {
      print('Social login initialization error: $e');
    }
  }

  static Future<SocialLoginResult> _performSocialLogin(
    Future<dynamic> Function() loginFunction,
    String Function(dynamic) tokenExtractor,
    String provider,
  ) async {
    try {
      final result = await loginFunction();
      final token = tokenExtractor(result);
      return token != null 
        ? SocialLoginResult.success(token, provider.toLowerCase())
        : SocialLoginResult.error('$provider login failed or was cancelled');
    } catch (e) {
      return SocialLoginResult.error('$provider login error: $e');
    }
  }

  static Future<SocialLoginResult> loginWithFacebook() async {
    return _performSocialLogin(
      () async {
        final result = await FacebookAuth.instance.login();
        return result.status == LoginStatus.success ? result.accessToken : null;
      },
      (result) => result?.tokenString,
      'Facebook',
    );
  }

  static Future<SocialLoginResult> loginWithGoogle() async {
    if (_googleSignIn == null) return SocialLoginResult.error('Google Sign-In not initialized');
    
    return _performSocialLogin(
      () async {
        final user = await _googleSignIn!.signIn();
        return user != null ? await user.authentication : null;
      },
      (result) => result?.idToken,
      'Google',
    );
  }

  static Future<void> signOut() async {
    try {
      await FacebookAuth.instance.logOut();
      if (_googleSignIn != null) await _googleSignIn!.signOut();
    } catch (e) {
      print('Social sign out error: $e');
    }
  }

  static void setupGoogleWebCallback(Function(dynamic) callback) => print('Google web callback setup (web-specific)');
  static Widget renderGoogleWebButton() => const SizedBox.shrink();
}

class SocialLoginResult {
  final bool success;
  final String? token;
  final String? provider;
  final String? error;

  SocialLoginResult.success(this.token, this.provider) : success = true, error = null;
  SocialLoginResult.error(this.error) : success = false, token = null, provider = null;
}

class SocialLoginButton extends StatelessWidget {
  final String provider;
  final VoidCallback? onPressed;
  final bool isLoading;

  const SocialLoginButton({Key? key, required this.provider, this.onPressed, this.isLoading = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isGoogle = provider == 'Google';
    final icon = isGoogle ? Icons.g_mobiledata : Icons.facebook;
    final color = isGoogle ? Colors.red : Colors.blue;

    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading 
        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
        : Icon(icon, color: color),
      label: Text(provider),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.surface,
        foregroundColor: Colors.white,
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
