// lib/core/consolidated_core.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/api_service.dart';

class AppValidators {
  static String? required(String? value, [String? fieldName]) {
    if (value?.trim().isEmpty ?? true) return 'Please enter ${fieldName ?? 'this field'}';
    return null;
  }

  static String? email(String? value) {
    if (value?.isEmpty ?? true) return 'Please enter an email';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value!.trim())) return 'Please enter a valid email address';
    return null;
  }

  static String? password(String? value, [int minLength = 8]) {
    if (value?.isEmpty ?? true) return 'Please enter a password';
    if (value!.length < minLength) return 'Password must be at least $minLength characters';
    return null;
  }

  static String? confirmPassword(String? value, String? originalPassword) {
    if (value?.isEmpty ?? true) return 'Please confirm your password';
    if (value != originalPassword) return 'Passwords do not match';
    return null;
  }

  static String? username(String? value) {
    if (value?.isEmpty ?? true) return 'Please enter a username';
    if (value!.length < 3) return 'Username must be at least 3 characters';
    if (value.length > 30) return 'Username must be less than 30 characters';
    
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(value)) return 'Username can only contain letters, numbers, and underscores';
    return null;
  }

  static String? phoneNumber(String? value, {bool required = false}) {
    if (value?.isEmpty ?? true) return required ? 'Please enter a phone number' : null;
    
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]+$');
    if (!phoneRegex.hasMatch(value!)) {
      return 'Please enter a valid phone number';
    }
    
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length < 7 || digitsOnly.length > 15) {
      return 'Phone number must be between 7 and 15 digits';
    }
    
    return null;
  }

  static String? maxLength(String? value, int maxLength, [String? fieldName]) {
    if (value != null && value.length > maxLength) {
      return '${fieldName ?? 'Field'} must be less than $maxLength characters';
    }
    return null;
  }

  static String? lengthRange(String? value, int min, int max, [String? fieldName]) {
    if (value != null) {
      if (value.length < min) {
        return '${fieldName ?? 'Field'} must be at least $min characters';
      }
      if (value.length > max) {
        return '${fieldName ?? 'Field'} must be less than $max characters';
      }
    }
    return null;
  }

  static String? playlistName(String? value) {
    if (value?.isEmpty ?? true) return 'Please enter a playlist name';
    if (value!.length > 100) return 'Playlist name must be less than 100 characters';
    return null;
  }

  static String? description(String? value) {
    if (value != null && value.length > 500) {
      return 'Description must be less than 500 characters';
    }
    return null;
  }

  static String? Function(String?) compose(List<String? Function(String?)> validators) {
    return (String? value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) return result;
      }
      return null;
    };
  }

  static String? otp(String? value) {
    if (value?.isEmpty ?? true) return 'Please enter OTP';
    if (!RegExp(r'^\d{6}$').hasMatch(value!)) return 'OTP must be exactly 6 digits';
    return null;
  }
}

class ValidationUtils {
  static String? required(String? value, [String? fieldName]) => AppValidators.required(value, fieldName);
  static String? email(String? value) => AppValidators.email(value);
  static String? password(String? value, [int minLength = 8]) => AppValidators.password(value, minLength);
  static String? username(String? value) => AppValidators.username(value);
  static String? phoneNumber(String? value, {bool required = false}) => AppValidators.phoneNumber(value, required: required);
  static String? lengthRange(String? value, int min, int max, [String? fieldName]) => AppValidators.lengthRange(value, min, max, fieldName);
  static String? otp(String? value) => AppValidators.otp(value);
}

class Validators {
  static String? Function(String?) get playlistName => AppValidators.playlistName;
  static String? Function(String?) get description => AppValidators.description;
}

class AppUtils {
  static String formatDate(DateTime? date) {
    if (date != null) {
      return DateFormat('yyyy-MM-dd').format(date);
    }
    return '';
  }

  static void showSnackBar(BuildContext context, String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? Colors.blue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
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
    if (loading) {
      _errorMessage = null;
      _successMessage = null;
    }
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

  Future<T?> executeAsync<T>(
    Future<T> Function() operation, {
    String? successMessage,
    String? errorMessage,
    bool showLoading = true,
  }) async {
    if (showLoading) setLoading(true);
    clearMessages();

    try {
      final result = await operation();
      if (successMessage != null) setSuccess(successMessage);
      return result;
    } catch (e) {
      setError(errorMessage ?? e.toString());
      return null;
    } finally {
      if (showLoading) setLoading(false);
    }
  }

  Future<bool> executeBool(
    Future<void> Function() operation, {
    String? successMessage,
    String? errorMessage,
    bool showLoading = true,
  }) async {
    final result = await executeAsync<bool>(
      () async {
        await operation();
        return true;
      },
      successMessage: successMessage,
      errorMessage: errorMessage,
      showLoading: showLoading,
    );
    return result ?? false;
  }
}

mixin CrudOperations<T> on ChangeNotifier, StateManagement {
  final ApiService _api = ApiService();
  List<T> _items = [];
  T? _selectedItem;

  List<T> get items => List.unmodifiable(_items);
  T? get selectedItem => _selectedItem;
  bool get hasItems => _items.isNotEmpty;
  int get itemCount => _items.length;

  Future<List<T>> fetchFromApi(String token, {String? endpoint});
  Future<T?> createInApi(Map<String, dynamic> data, String token, {String? endpoint});
  Future<void> updateInApi(String id, Map<String, dynamic> data, String token, {String? endpoint});
  Future<void> deleteInApi(String id, String token, {String? endpoint});
  String getItemId(T item);

  Future<void> fetchItems(String token, {String? endpoint}) async {
    final result = await executeAsync(
      () => fetchFromApi(token, endpoint: endpoint),
      errorMessage: 'Failed to fetch items',
    );
    if (result != null) {
      _items = result;
    }
  }

  Future<T?> createItem(Map<String, dynamic> data, String token, {String? endpoint}) async {
    return executeAsync(
      () async {
        final item = await createInApi(data, token, endpoint: endpoint);
        if (item != null) {
          _items.add(item);
          notifyListeners();
          return item;
        }
        throw Exception('Failed to create item');
      },
      successMessage: 'Item created successfully',
      errorMessage: 'Failed to create item',
    );
  }

  Future<bool> updateItem(String id, Map<String, dynamic> data, String token, {String? endpoint}) async {
    return executeBool(
      () async {
        await updateInApi(id, data, token, endpoint: endpoint);
        await refreshItems(token, endpoint: endpoint);
      },
      successMessage: 'Item updated successfully',
      errorMessage: 'Failed to update item',
    );
  }

  Future<bool> deleteItem(String id, String token, {String? endpoint}) async {
    return executeBool(
      () async {
        await deleteInApi(id, token, endpoint: endpoint);
        _items.removeWhere((item) => getItemId(item) == id);
        if (_selectedItem != null && getItemId(_selectedItem!) == id) {
          _selectedItem = null;
        }
        notifyListeners();
      },
      successMessage: 'Item deleted successfully',
      errorMessage: 'Failed to delete item',
    );
  }

  void selectItem(T? item) {
    _selectedItem = item;
    notifyListeners();
  }

  Future<void> refreshItems(String token, {String? endpoint}) async {
    await fetchItems(token, endpoint: endpoint);
  }

  void clearItems() {
    _items.clear();
    _selectedItem = null;
    notifyListeners();
  }

  T? findItemById(String id) {
    try {
      return _items.firstWhere((item) => getItemId(item) == id);
    } catch (e) {
      return null;
    }
  }

  void addItem(T item) {
    _items.add(item);
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((item) => getItemId(item) == id);
    if (_selectedItem != null && getItemId(_selectedItem!) == id) {
      _selectedItem = null;
    }
    notifyListeners();
  }

  void updateItemInList(T updatedItem) {
    final index = _items.indexWhere((item) => getItemId(item) == getItemId(updatedItem));
    if (index != -1) {
      _items[index] = updatedItem;
      if (_selectedItem != null && getItemId(_selectedItem!) == getItemId(updatedItem)) {
        _selectedItem = updatedItem;
      }
      notifyListeners();
    }
  }
}

abstract class BaseProvider extends ChangeNotifier with StateManagement {
  final ApiService api = ApiService();

  Future<void> performAction(
    Future<void> Function() action, {
    String? successMessage,
    String? errorMessage,
    VoidCallback? onSuccess,
    VoidCallback? onError,
  }) async {
    final success = await executeBool(
      action,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
    
    if (success) {
      onSuccess?.call();
    } else {
      onError?.call();
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

  static ThemeData get darkTheme => ThemeData(
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
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.black,
        minimumSize: const Size(88, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
    ),
  );

  static Widget buildCard({required Widget child, EdgeInsets? padding, EdgeInsets? margin, Color? color}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color ?? surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  static Widget buildHeaderCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, primary.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  static Widget buildFormCard({required Widget child, String? title, IconData? titleIcon}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  if (titleIcon != null) ...[
                    Icon(titleIcon, color: primary, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 16),
            ],
            child,
          ],
        ),
      ),
    );
  }

  static Widget buildPrimaryButton({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading 
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
          : Icon(icon ?? Icons.check, size: 16),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        ),
      ),
    );
  }

  static InputDecoration getInputDecoration({required String labelText, String? hintText, IconData? prefixIcon}) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: onSurfaceVariant) : null,
      filled: true,
      fillColor: surfaceVariant,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primary, width: 2)),
    );
  }
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
  static const EdgeInsets screenPadding = EdgeInsets.all(16.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const double borderRadius = 12.0;
  static const double iconSize = 24.0;
  static const double avatarRadius = 20.0;
}

class AppDurations {
  static const Duration shortDelay = Duration(milliseconds: 100);
  static const Duration mediumDelay = Duration(milliseconds: 300);
  static const Duration longDelay = Duration(milliseconds: 500);
  static const Duration animationDuration = Duration(milliseconds: 250);
}

class AppAnimations {
  static const Curve defaultCurve = Curves.easeInOut;
  static final Tween<double> fadeIn = Tween<double>(begin: 0.0, end: 1.0);
  static final Tween<double> slideUp = Tween<double>(begin: 1.0, end: 0.0);
  static final Tween<Offset> slideFromRight = Tween<Offset>(
    begin: const Offset(1.0, 0.0),
    end: Offset.zero,
  );
}

class AppRoutes {
  static const String home = '/home';
  static const String auth = '/auth';
  static const String profile = '/profile';
  static const String playlistEditor = '/playlist_editor';
  static const String trackSearch = '/track_search';
  static const String publicPlaylists = '/public_playlists';
  static const String playlistSharing = '/playlist_sharing';
  static const String trackSelection = '/track_selection';
  static const String player = '/player';
  static const String friends = '/friends';
  static const String addFriend = '/add_friend';
  static const String friendRequests = '/friend_requests';
  static const String deviceManagement = '/device_management';
  static const String controlDelegation = '/control_delegation';
  static const String musicFeatures = '/music_features';
  static const String trackVote = '/track_vote';
  static const String deezerTrackDetail = '/deezer_track_detail';
  static const String userPasswordChange = '/user_password_change';
  static const String socialNetworkLink = '/social_network_link';
}

class AppStrings {
  static const String signIn = 'Sign In';
  static const String signUp = 'Sign Up';
  static const String username = 'Username';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String login = 'Login';
  static const String logout = 'Logout';
  static const String loginSuccessful = 'Login successful';
  static const String accountCreated = 'Account created successfully';
  static const String confirmLogout = 'Are you sure you want to logout?';
  
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String delete = 'Delete';
  static const String add = 'Add';
  static const String search = 'Search';
  static const String ok = 'OK';
  
  static const String playlists = 'Playlists';
  static const String publicPlaylists = 'Public Playlists';
  static const String createPlaylist = 'Create Playlist';
  static const String editPlaylist = 'Edit Playlist';
  static const String tracks = 'Tracks';
  static const String searchTracks = 'Search Tracks';
  static const String playlistCreated = 'Playlist created successfully';
  static const String trackAdded = 'Track added to playlist';
  
  static const String play = 'Play';
  static const String pause = 'Pause';
  static const String playPreview = 'Play Preview';
  static const String pausePreview = 'Pause Preview';
  static const String noPreviewAvailable = 'No preview available for this track';
  
  static const String friends = 'Friends';
  static const String addFriend = 'Add Friend';
  static const String deezer = 'Deezer';
  static const String local = 'Local';
  static const String addToLibrary = 'Add to Library';
  static const String addedToLibrary = 'Added to your library';
  static const String addToPlaylist = 'Add to Playlist';
  
  static const String loading = 'Loading...';
  static const String error = 'Error';
  static const String noResultsFound = 'No results found';
  static const String noTracksFound = 'No tracks found';
  static const String tryDifferentKeywords = 'Try searching with different keywords';
  static const String connectionErrorMessage = 'Connection error. Check your internet.';
  static const String featureComingSoon = 'This feature is coming soon!';
  static const String searchForTracks = 'Search for tracks';
  static const String deleteAccountWarning = 'This will permanently delete your account and all associated data.';
  static const String confirmDelete = 'Are you sure you want to delete';
}

class AsyncOperationUtils {
  static Future<T?> executeWithLoading<T>({
    required Future<T> Function() operation,
    required VoidCallback setLoading,
    required VoidCallback clearLoading,
    required Function(String) onError,
    VoidCallback? onSuccess,
    String? successMessage,
    String? errorMessage,
  }) async {
    setLoading();
    
    try {
      final result = await operation();
      clearLoading();
      onSuccess?.call();
      return result;
    } catch (e) {
      clearLoading();
      onError(errorMessage ?? e.toString());
      return null;
    }
  }

  static Future<bool> executeBool({
    required Future<void> Function() operation,
    required VoidCallback setLoading,
    required VoidCallback clearLoading,
    required Function(String) onError,
    VoidCallback? onSuccess,
    String? successMessage,
    String? errorMessage,
  }) async {
    final result = await executeWithLoading<bool>(
      operation: () async {
        await operation();
        return true;
      },
      setLoading: setLoading,
      clearLoading: clearLoading,
      onError: onError,
      onSuccess: onSuccess,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
    
    return result ?? false;
  }

  static Function debounce(Function function, Duration delay) {
    Timer? timer;
    return () {
      timer?.cancel();
      timer = Timer(delay, () => function());
    };
  }

  static Function throttle(Function function, Duration interval) {
    bool isThrottled = false;
    return () {
      if (!isThrottled) {
        function();
        isThrottled = true;
        Timer(interval, () => isThrottled = false);
      }
    };
  }
}

class SocialLoginUtils {
  static GoogleSignIn? _googleSignIn;
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final fbAppId = dotenv.env['FACEBOOK_APP_ID'];
      if (kIsWeb && fbAppId != null) {
        await FacebookAuth.instance.webAndDesktopInitialize(
          appId: fbAppId,
          cookie: true,
          xfbml: true,
          version: "v22.0",
        );
      }

      if (!kIsWeb) {
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

  static Future<SocialLoginResult> loginWithGoogle() async {
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

      return SocialLoginResult.success(idToken, 'google');
    } catch (e) {
      return SocialLoginResult.error('Google login error: $e');
    }
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

  static void setupGoogleWebCallback(Function(dynamic) callback) {
    print('Google web callback setup (web-specific)');
  }
  
  static Widget renderGoogleWebButton() {
    return const SizedBox.shrink();
  }
}

class SocialLoginResult {
  final bool success;
  final String? token;
  final String? provider;
  final String? error;

  SocialLoginResult.success(this.token, this.provider)
      : success = true, error = null;

  SocialLoginResult.error(this.error)
      : success = false, token = null, provider = null;
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
        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
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

mixin AsyncOperationMixin on ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get hasError => _errorMessage != null;
  bool get hasSuccess => _successMessage != null;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _errorMessage = null;
      _successMessage = null;
    }
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

  Future<bool> executeBool({
    required Future<void> Function() operation,
    String? successMessage,
    String? errorMessage,
    VoidCallback? onSuccess,
    VoidCallback? onError,
  }) async {
    setLoading(true);
    
    try {
      await operation();
      setLoading(false);
      if (successMessage != null) setSuccess(successMessage);
      onSuccess?.call();
      return true;
    } catch (e) {
      setLoading(false);
      setError(errorMessage ?? e.toString());
      onError?.call();
      return false;
    }
  }

  void showSuccess(String message) {
    setSuccess(message);
  }

  void showError(String message) {
    setError(message);
  }
}

mixin AsyncOperationStateMixin<T extends StatefulWidget> on State<T> {
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get hasError => _errorMessage != null;
  bool get hasSuccess => _successMessage != null;

  void clearMessages() {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });
  }

  void setLoading(bool loading) {
    setState(() {
      _isLoading = loading;
      if (loading) {
        _errorMessage = null;
        _successMessage = null;
      }
    });
  }

  void setError(String error) {
    setState(() {
      _errorMessage = error;
      _successMessage = null;
      _isLoading = false;
    });
  }

  void setSuccess(String message) {
    setState(() {
      _successMessage = message;
      _errorMessage = null;
      _isLoading = false;
    });
  }

  Future<bool> executeBool({
    required Future<void> Function() operation,
    String? successMessage,
    String? errorMessage,
    VoidCallback? onSuccess,
    VoidCallback? onError,
  }) async {
    setLoading(true);
    
    try {
      await operation();
      setLoading(false);
      if (successMessage != null) setSuccess(successMessage);
      onSuccess?.call();
      return true;
    } catch (e) {
      setLoading(false);
      setError(errorMessage ?? e.toString());
      onError?.call();
      return false;
    }
  }

  void showSuccess(String message) {
    setSuccess(message);
  }

  void showError(String message) {
    setError(message);
  }
}
