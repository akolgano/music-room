// lib/core/api_constants.dart
class ApiEndpoints {
  static const String login = '/users/login/';
  static const String signup = '/users/signup/';
  static const String logout = '/users/logout/';
  
  static const String playlists = '/playlists/playlists';
  static const String savedPlaylists = '/playlists/saved_playlists/';
  static const String publicPlaylists = '/playlists/public_playlists/';
  static const String playlistTracks = '/playlists/playlist';
  static const String addToPlaylist = '/playlists';
  static const String removeFromPlaylist = '/playlists/playlists';
  static const String moveTrack = '/playlists/move-track/';
  static const String changeVisibility = '/change-visibility/';
  static const String inviteUser = '/invite-user/';
  
  static const String searchTracks = '/tracks/search/';
  static const String addFromDeezer = '/tracks/add_from_deezer';
  
  static const String deezerSearch = '/deezer/search/';
  static const String deezerTrack = '/deezer/track/';
  
  static const String getFriends = '/users/get_friends/';
  static const String sendFriendRequest = '/users/send_friend_request/';
  static const String acceptFriendRequest = '/users/accept_friend_request/';
  static const String rejectFriendRequest = '/users/reject_friend_request/';
  static const String removeFriend = '/users/remove_friend/';
  
  static const String registerDevice = '/devices/register/';
  static const String delegateControl = '/devices/delegate/';
  static const String canControl = '/devices';
}
