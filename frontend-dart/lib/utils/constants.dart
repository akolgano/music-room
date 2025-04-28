// utils/constants.dart
class AppConstants {
  static const String AUTH_LOGIN_ENDPOINT = '/auth/login';
  static const String AUTH_SIGNUP_ENDPOINT = '/auth/signup';
  
  static const String USER_DATA_KEY = 'userData';
  
  static const String ERROR_EMAIL_EXISTS = 'EMAIL_EXISTS';
  static const String ERROR_INVALID_EMAIL = 'INVALID_EMAIL';
  static const String ERROR_WEAK_PASSWORD = 'WEAK_PASSWORD';
  static const String ERROR_EMAIL_NOT_FOUND = 'EMAIL_NOT_FOUND';
  static const String ERROR_INVALID_PASSWORD = 'INVALID_PASSWORD';
  
  static const String HOME_ROUTE = '/home';
  static const String PROFILE_ROUTE = '/profile';
  static const String TRACK_VOTE_ROUTE = '/track_vote';
  static const String CONTROL_DELEGATION_ROUTE = '/control_delegation';
  static const String PLAYLIST_EDITOR_ROUTE = '/playlist_editor';
}
