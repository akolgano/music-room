import 'package:form_validator/form_validator.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

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
}

class AppRoutes {
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
  static const String userPage = '/user_page';
  static const String adminDashboard = '/admin_dashboard';
  static const String beaconAdmin = '/beacon_admin';
}

class FormatUtils {
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}

class AppValidators {
  static String? required(String? value, [String? fieldName]) =>
      ValidationBuilder().required('Please enter ${fieldName ?? 'this field'}').build()(value);
  
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an email address';
    }
    
    if (value != value.trim()) {
      return 'Email cannot have leading or trailing spaces';
    }
    
    final emailRegex = RegExp(r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    
    return null;
  }
  
  static String? password(String? value, [int minLength = 8]) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    
    if (value.contains(' ')) {
      return 'The password must not contain spaces';
    }
    
    return null;
  }
  
  static String? username(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a username';
    }
    
    if (value != value.trim()) {
      return 'Username cannot have leading or trailing spaces';
    }
    
    if (value.isEmpty) {
      return 'Username must be at least 1 character';
    }
    if (value.length > 20) {
      return 'Username must be less than 20 characters';
    }
    
    if (!RegExp(r'^\w+$').hasMatch(value)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    
    return null;
  }

  static String? phoneNumber(String? value, [bool required = false]) {
    if (!required && (value?.isEmpty ?? true)) { return null; }
    if (value == null || value.trim().isEmpty) { return required ? 'Please enter a phone number' : null; }
    try {
      final phoneNumber = PhoneNumber.parse(value.trim());
      if (phoneNumber.isValid()) { return null; }
      else { return 'Please enter a valid phone number'; }
    } catch (e) {
      return 'Please enter a valid phone number';
    }
  }
  
  
  static String? bio(String? value) =>
      ValidationBuilder().maxLength(500, 'Bio must be less than 500 characters').build()(value);
  
}