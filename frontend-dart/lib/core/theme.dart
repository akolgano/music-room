// lib/core/theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF1DB954);
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF282828);
  static const Color surfaceVariant = Color(0xFF333333);
  static const Color onSurface = Color(0xFFFFFFFF);
  static const Color onSurfaceVariant = Color(0xFFB3B3B3);
  static const Color error = Color(0xFFE91429);

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
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primary),
      ),
    ),
  );
}

class AppConstants {
  static const String appName = 'Music Room';
}

class AppRoutes {
  static const String home = '/home';
  static const String profile = '/profile';
  static const String trackVote = '/track_vote';
  static const String controlDelegation = '/control_delegation';
  static const String musicFeatures = '/music_features';
  static const String apiDocs = '/api_docs';
  static const String enhancedPlaylistEditor = '/enhanced_playlist_editor';
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
