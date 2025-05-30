// lib/core/constants.dart
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
  
  static const String googleDocMimeType = 'application/vnd.google-apps.document';
  static const String googleFolderMimeType = 'application/vnd.google-apps.folder';
  
  static const String emailRegexPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
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
