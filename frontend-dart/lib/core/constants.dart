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
