// lib/core/app_core.dart
export 'constants.dart';
export 'theme.dart';

class AppStrings {
  static const String appName = 'Music Room';
  static const String version = '1.0.0';
  
  static const String signIn = 'Sign In';
  static const String signUp = 'Sign Up';
  static const String username = 'Username';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String login = 'Login';
  static const String logout = 'Logout';
  
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String add = 'Add';
  static const String search = 'Search';
  static const String share = 'Share';
  
  static const String playlists = 'Playlists';
  static const String tracks = 'Tracks';
  static const String nowPlaying = 'Now Playing';
  static const String play = 'Play';
  static const String pause = 'Pause';
  
  static const String loading = 'Loading...';
  static const String error = 'Error';
  static const String comingSoon = 'Coming Soon';
  static const String noResultsFound = 'No results found';
}

class AppDimensions {
  static const double padding = 16.0;
  static const double paddingSmall = 8.0;
  static const double paddingLarge = 24.0;
  static const double radius = 8.0;
  static const double radiusLarge = 12.0;
  static const double iconSize = 24.0;
  static const double buttonHeight = 50.0;
}

class ApiEndpoints {
  static const String login = '/users/login/';
  static const String signup = '/users/signup/';
  static const String logout = '/users/logout/';
  static const String playlists = '/playlists/playlists';
  static const String publicPlaylists = '/playlists/public_playlists/';
  static const String searchTracks = '/tracks/search/';
  static const String deezerSearch = '/deezer/search/';
  static const String deezerTrack = '/deezer/track/';
  static const String getFriends = '/users/get_friends/';
  static const String registerDevice = '/devices/register/';
}
