// lib/core/app_core.dart
import 'package:flutter/material.dart';

export 'package:flutter/material.dart';

class AppTheme {
  static const primary = Color(0xFF1DB954);
  static const background = Color(0xFF121212);
  static const surface = Color(0xFF282828);
  static const surfaceVariant = Color(0xFF333333);
  static const onSurface = Color(0xFFFFFFFF);
  static const onSurfaceVariant = Color(0xFFB3B3B3);
  static const error = Color(0xFFE91429);
  static const success = Color(0xFF00C851);
  static const warning = Color(0xFFFF9F00);
  static const info = Color(0xFF2196F3);
  
  static const textPrimary = onSurface;
  static const textSecondary = onSurfaceVariant;
  static Color get textDisabled => onSurface.withOpacity(0.5);
  static Color get textSubtle => onSurface.withOpacity(0.7);

  static List<BoxShadow> get defaultShadow => [
    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
  ];

  static List<BoxShadow> get lightShadow => [
    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
  ];

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
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.black,
        minimumSize: const Size(88, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        elevation: 4,
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
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: error, width: 2),
      ),
      labelStyle: const TextStyle(color: onSurfaceVariant),
      hintStyle: TextStyle(color: onSurface.withOpacity(0.6)),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  );

  static ButtonStyle get fullWidthButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primary,
    foregroundColor: Colors.black,
    minimumSize: const Size(double.infinity, 50),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
    elevation: 4,
  );

  static ButtonStyle get dangerButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: error,
    foregroundColor: Colors.white,
    minimumSize: const Size(88, 50),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
    elevation: 4,
  );

  static ButtonStyle get outlinedButtonStyle => OutlinedButton.styleFrom(
    foregroundColor: primary,
    side: const BorderSide(color: primary),
    minimumSize: const Size(88, 50),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
  );

  static Widget buildStandardCard({
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    VoidCallback? onTap,
    Color? color,
  }) {
    return Card(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color ?? surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }

  static Widget buildFormCard({
    required Widget child,
    String? title,
    IconData? titleIcon,
    EdgeInsets? padding,
    EdgeInsets? margin,
  }) {
    return Card(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: surface,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
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
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
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

  static Widget buildListCard({
    required Widget child,
    VoidCallback? onTap,
    EdgeInsets? margin,
    Color? color,
  }) {
    return Card(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: color ?? surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );
  }

  static Widget buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
    Widget? trailing,
  }) {
    final cardIconColor = iconColor ?? primary;
    return buildListCard(
      onTap: onTap,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cardIconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: cardIconColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: onSurfaceVariant, fontSize: 12),
        ),
        trailing: trailing ?? const Icon(Icons.chevron_right, color: onSurfaceVariant),
      ),
    );
  }

  static Widget buildHeaderCard({
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    List<Color>? gradientColors,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors ?? [primary, primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  static Widget buildGradientContainer({
    required Widget child,
    List<Color>? colors,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors ?? [primary, primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  static Widget buildShadowContainer({
    required Widget child,
    Color? shadowColor,
    double? blurRadius,
    EdgeInsets? padding,
    BorderRadius? borderRadius,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (shadowColor ?? primary).withOpacity(0.3),
            blurRadius: blurRadius ?? 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  static Widget buildCard({
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Color? color,
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color ?? surface,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        boxShadow: boxShadow ?? lightShadow,
      ),
      child: child,
    );
  }

  static Widget buildPrimaryCard({
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withOpacity(0.3)),
      ),
      child: child,
    );
  }

  static Widget buildErrorCard({
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: error.withOpacity(0.3)),
      ),
      child: child,
    );
  }

  static Widget buildSuccessCard({
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: success.withOpacity(0.3)),
      ),
      child: child,
    );
  }

  static Decoration get glassmorphicDecoration => BoxDecoration(
    color: surface.withOpacity(0.8),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: Colors.white.withOpacity(0.1),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 10,
        offset: const Offset(0, 5),
      ),
    ],
  );

  static Widget buildPrimaryButton({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    bool fullWidth = true,
  }) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading 
        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
        : Icon(icon ?? Icons.check, size: 16),
      label: Text(text),
      style: fullWidth ? fullWidthButtonStyle : ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.black,
        minimumSize: const Size(88, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
    );
  }

  static Widget buildSecondaryButton({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    bool fullWidth = false,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon ?? Icons.check, size: 16),
      label: Text(text),
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary),
        minimumSize: fullWidth ? const Size(double.infinity, 50) : const Size(88, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
    );
  }

  static Widget buildDangerButton({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    bool fullWidth = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon ?? Icons.warning, size: 16),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: error,
        foregroundColor: Colors.white,
        minimumSize: fullWidth ? const Size(double.infinity, 50) : const Size(88, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
    );
  }

  static InputDecoration getInputDecoration({
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      errorText: errorText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: onSurfaceVariant) : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: error, width: 2),
      ),
      labelStyle: const TextStyle(color: onSurfaceVariant),
      hintStyle: TextStyle(color: onSurface.withOpacity(0.6)),
    );
  }
}

class AppConstants {
  static const String appName = 'Music Room';
  static const String version = '1.0.0';
  static const String defaultApiBaseUrl = 'http://localhost:8000';
  static const String contentTypeJson = 'application/json';
  static const String authorizationPrefix = 'Token';
  static const Duration retryDelay = Duration(seconds: 3);
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const int defaultPageSize = 25;
  static const int maxSearchResults = 100;
  static const int minPasswordLength = 8;

  static const int maxPlaylistNameLength = 100;
  static const int maxDescriptionLength = 500;
  static const int maxTracksPerPlaylist = 1000;
  static const int maxFriendsCount = 500;
  static const int maxDevicesPerUser = 10;
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
  static const String retry = 'Retry';
  static const String ok = 'OK';
  
  static const String playlists = 'Playlists';
  static const String publicPlaylists = 'Public Playlists';
  static const String createPlaylist = 'Create Playlist';
  static const String editPlaylist = 'Edit Playlist';
  static const String tracks = 'Tracks';
  static const String searchTracks = 'Search Tracks';
  static const String playlistCreated = 'Playlist created successfully';
  static const String playlistUpdated = 'Playlist updated successfully';
  static const String trackAdded = 'Track added to playlist';
  static const String trackRemoved = 'Track removed from playlist';
  
  static const String nowPlaying = 'NOW PLAYING';
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
  static const String trackDetails = 'Track Details';
  static const String album = 'Album';
  static const String openInDeezer = 'Open in Deezer';
  
  static const String loading = 'Loading...';
  static const String error = 'Error';
  static const String noResultsFound = 'No results found';
  static const String noTracksFound = 'No tracks found';
  static const String tryDifferentKeywords = 'Try searching with different keywords';
  static const String connectionErrorMessage = 'Connection error. Check your internet.';
  static const String featureComingSoon = 'This feature is coming soon!';
  static const String searchForTracks = 'Search for tracks';
  static const String noPlaylistsPlaceholder = 'No playlists yet. Create one to get started!';
  static const String noActivityPlaceholder = 'No recent activity to show.';
  static const String deleteAccountWarning = 'This will permanently delete your account and all associated data.';
  static const String confirmDelete = 'Are you sure you want to delete';
}

class AppMessages {
  static const String featureComingSoon = 'This feature is coming soon!';
  static const String connectionError = 'Connection error. Check your internet.';
  static const String loadingPlaylists = 'Loading playlists...';
  static const String loadingTracks = 'Loading tracks...';
  static const String loadingFriends = 'Loading friends...';
  static const String noResultsFound = 'No results found';
  static const String tryDifferentKeywords = 'Try searching with different keywords';
  static const String confirmAction = 'Are you sure?';
  static const String actionCompleted = 'Action completed successfully';
  static const String actionFailed = 'Action failed. Please try again.';
  static const String playlistEmpty = 'This playlist is empty';
  static const String noFriendsYet = 'No friends yet. Add some to get started!';
  static const String noDevicesRegistered = 'No devices registered';
  static const String networkErrorRetry = 'Network error. Tap to retry.';
  static const String sessionExpired = 'Session expired. Please sign in again.';
  static const String unauthorized = 'You are not authorized to perform this action.';
  static const String serverError = 'Server error. Please try again later.';
}

class AppDurations {
  static const Duration shortDelay = Duration(milliseconds: 300);
  static const Duration mediumDelay = Duration(milliseconds: 500);
  static const Duration longDelay = Duration(milliseconds: 800);
  static const Duration snackBarDuration = Duration(seconds: 3);
  static const Duration animationDuration = Duration(milliseconds: 250);
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration debounceDelay = Duration(milliseconds: 500);
  static const Duration refreshIndicatorDuration = Duration(seconds: 1);
}

class AppSizes {
  static const double borderRadius = 12.0;
  static const double cardElevation = 4.0;
  static const double iconSize = 24.0;
  static const double avatarSize = 40.0;
  static const double buttonHeight = 50.0;
  static const double appBarHeight = 56.0;
  static const double bottomNavHeight = 60.0;
  static const double fabSize = 56.0;
  
  static const EdgeInsets screenPadding = EdgeInsets.all(16.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0);
}

class AppAnimations {
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.bounceOut;
  static const Curve elasticCurve = Curves.elasticOut;
  
  static Tween<double> get fadeIn => Tween<double>(begin: 0.0, end: 1.0);
  static Tween<double> get slideUp => Tween<double>(begin: 1.0, end: 0.0);
  static Tween<double> get scaleUp => Tween<double>(begin: 0.0, end: 1.0);
}

class Validators {
  static String? required(String? value, String fieldName) {
    if (value?.isEmpty ?? true) return 'Please enter $fieldName';
    return null;
  }

  static String? email(String? value) {
    if (value?.isEmpty ?? true) return 'Please enter an email';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  static String? password(String? value) {
    if (value?.isEmpty ?? true) return 'Please enter password';
    if (value!.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
    }
    return null;
  }

  static String? playlistName(String? value) {
    if (value?.isEmpty ?? true) return 'Please enter a playlist name';
    if (value!.length > AppConstants.maxPlaylistNameLength) {
      return 'Playlist name too long (max ${AppConstants.maxPlaylistNameLength} characters)';
    }
    return null;
  }

  static String? description(String? value) {
    if (value != null && value.length > AppConstants.maxDescriptionLength) {
      return 'Description too long (max ${AppConstants.maxDescriptionLength} characters)';
    }
    return null;
  }

  static String? username(String? value) {
    if (value?.isEmpty ?? true) return 'Please enter a username';
    if (value!.length < 3) return 'Username must be at least 3 characters';
    if (value.length > 30) return 'Username must be less than 30 characters';
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    return null;
  }

  static String? phoneNumber(String? value) {
    if (value?.isEmpty ?? true) return null; 
    if (!RegExp(r'^\+?[\d\s\-\(\)]+$').hasMatch(value!)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }
}

class AppUtils {
  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static String formatNumber(int number) {
    if (number < 1000) return number.toString();
    if (number < 1000000) return '${(number / 1000).toStringAsFixed(1)}K';
    if (number < 1000000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    return '${(number / 1000000000).toStringAsFixed(1)}B';
  }

  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  static bool isValidUrl(String url) {
    return RegExp(r'^https?://').hasMatch(url);
  }

  static String truncateString(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return hslLight.toColor();
  }
}
