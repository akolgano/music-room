import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/core/constants.dart';

void main() {
  group('AppConstants Tests', () {
    test('AppConstants should have correct values', () {
      print('Testing: AppConstants should have correct values');
      expect(AppConstants.appName, 'Music Room');
      expect(AppConstants.version, '1.0.0');
      expect(AppConstants.defaultApiBaseUrl, 'http://localhost:8000');
      expect(AppConstants.contentTypeJson, 'application/json');
      expect(AppConstants.authorizationPrefix, 'Token');
      expect(AppConstants.minPasswordLength, 4);
    });
  });

  group('AppStrings Tests', () {
    test('AppStrings should have correct values', () {
      print('Testing: AppStrings should have correct values');
      expect(AppStrings.confirmLogout, 'Are you sure you want to sign out?');
      expect(AppStrings.networkError, 'Network error. Please check your connection.');
      expect(AppStrings.unknownError, 'An unknown error occurred.');
    });
  });

  group('AppRoutes Tests', () {
    test('AppRoutes should have correct values', () {
      print('Testing: AppRoutes should have correct values');
      expect(AppRoutes.home, '/home');
      expect(AppRoutes.auth, '/auth');
      expect(AppRoutes.profile, '/profile');
      expect(AppRoutes.playlistEditor, '/playlist_editor');
      expect(AppRoutes.playlistDetail, '/playlist_detail');
      expect(AppRoutes.trackDetail, '/track_detail');
      expect(AppRoutes.trackSearch, '/track_search');
      expect(AppRoutes.publicPlaylists, '/public_playlists');
      expect(AppRoutes.friends, '/friends');
      expect(AppRoutes.addFriend, '/add_friend');
      expect(AppRoutes.friendRequests, '/friend_requests');
      expect(AppRoutes.playlistSharing, '/playlist_sharing');
      expect(AppRoutes.player, '/player');
      expect(AppRoutes.userPasswordChange, '/user_password_change');
      expect(AppRoutes.socialNetworkLink, '/social_network_link');
      expect(AppRoutes.signupOtp, '/signup_otp');
      expect(AppRoutes.deezerAuth, '/deezer_auth');
    });
  });
}