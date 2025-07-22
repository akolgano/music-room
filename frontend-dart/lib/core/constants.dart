class AppConstants {
  static const String appName = 'Music Room';
  static const String version = '1.0.0';
  static const String defaultApiBaseUrl = 'http://localhost:8000';
  static const String contentTypeJson = 'application/json';
  static const String authorizationPrefix = 'Token';
  static const int minPasswordLength = 4;
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
  static const String userPage = '/user_page';
}