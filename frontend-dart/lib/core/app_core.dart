// lib/core/app_core.dart
import 'package:flutter/material.dart';

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
}

class AppRoutes {
  static const String home = '/home';
  static const String auth = '/auth';
  static const String profile = '/profile';
  static const String trackVote = '/track_vote';
  static const String controlDelegation = '/control_delegation';
  static const String musicFeatures = '/music_features';
  static const String playlistEditor = '/playlist_editor';
  static const String trackSelection = '/track_selection';
  static const String trackSearch = '/track_search';
  static const String publicPlaylists = '/public_playlists';
  static const String playlistSharing = '/playlist_sharing';
  static const String deezerTrackDetail = '/deezer_track_detail';
  static const String player = '/player';
  static const String friends = '/friends';
  static const String addFriend = '/add_friend';
  static const String friendRequests = '/friend_requests';
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

class AppDimens {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radiusBtn = 25.0;
  
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;
  static const double iconXxl = 64.0;
  static const double iconXxxl = 80.0;
  
  static const double btnHeight = 50.0;
  static const double btnHeightSm = 40.0;
  static const double btnHeightLg = 60.0;
  
  static const double albumArtSm = 50.0;
  static const double albumArtMd = 100.0;
  static const double albumArtLg = 200.0;
  static const double albumArtXl = 320.0;
  static const double miniPlayerHeight = 64.0;
  static const double playBtnSize = 64.0;
  
  static const double textXs = 12.0;
  static const double textSm = 14.0;
  static const double textMd = 16.0;
  static const double textLg = 18.0;
  static const double textXl = 20.0;
  static const double textTitle = 24.0;
  static const double textHeading = 32.0;
  
  static const double avatarSm = 32.0;
  static const double avatarMd = 50.0;
  static const double avatarLg = 80.0;
  static const double avatarXl = 100.0;
}

class AppColors {
  static const Color primary = Color(0xFF1DB954);
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF282828);
  static const Color surfaceVariant = Color(0xFF333333);
  static const Color onSurface = Color(0xFFFFFFFF);
  static const Color onSurfaceVariant = Color(0xFFB3B3B3);
  static const Color error = Color(0xFFE91429);
  static const Color success = Color(0xFF00C851);
  static const Color warning = Color(0xFFFF9F00);
  static const Color info = Color(0xFF2196F3);
  
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF1AAE4F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static const primary = AppColors.primary;
  static const background = AppColors.background;
  static const surface = AppColors.surface;
  static const surfaceVariant = AppColors.surfaceVariant;
  static const onSurface = AppColors.onSurface;
  static const onSurfaceVariant = AppColors.onSurfaceVariant;
  static const error = AppColors.error;
  static const success = AppColors.success;
  static const warning = AppColors.warning;
  static const info = AppColors.info;
  
  static const textPrimary = AppColors.onSurface;
  static const textSecondary = AppColors.onSurfaceVariant;
  static Color get textDisabled => AppColors.onSurface.withOpacity(0.5);
  static Color get textSubtle => AppColors.onSurface.withOpacity(0.7);

  static List<BoxShadow> get defaultShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get lightShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: AppDimens.sm,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get heroShadow => [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.3),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
    ...defaultShadow,
  ];

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    cardColor: AppColors.surface,
    
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      surface: AppColors.surface,
      background: AppColors.background,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSurface: AppColors.onSurface,
      onBackground: Colors.white,
    ),
    
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: AppDimens.textLg,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        minimumSize: Size(88, AppDimens.btnHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusBtn),
        ),
        elevation: 4,
        textStyle: TextStyle(
          fontSize: AppDimens.textSm,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariant,
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppDimens.md,
        vertical: AppDimens.sm,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      labelStyle: const TextStyle(color: AppColors.onSurfaceVariant),
      hintStyle: TextStyle(
        color: AppColors.onSurface.withOpacity(0.6),
      ),
    ),
    
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      margin: EdgeInsets.symmetric(
        horizontal: AppDimens.md,
        vertical: AppDimens.sm,
      ),
    ),
  );

  static ButtonStyle get fullWidthButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.black,
    minimumSize: Size(double.infinity, AppDimens.btnHeight),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimens.radiusBtn),
    ),
    elevation: 4,
    textStyle: TextStyle(
      fontSize: AppDimens.textSm,
      fontWeight: FontWeight.w600,
    ),
  );

  static ButtonStyle get dangerButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: AppColors.error,
    foregroundColor: Colors.white,
    minimumSize: Size(88, AppDimens.btnHeight),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimens.radiusBtn),
    ),
    elevation: 4,
    textStyle: TextStyle(
      fontSize: AppDimens.textSm,
      fontWeight: FontWeight.w600,
    ),
  );
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
    if (value!.length < 8) return 'Password must be at least 8 characters';
    return null;
  }
}
