import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:music_room/providers/profile_providers.dart';
import 'package:music_room/services/api_services.dart';
import 'package:music_room/providers/auth_providers.dart';
import 'package:music_room/models/api_models.dart';
import 'package:music_room/core/locator_core.dart';
import 'package:get_it/get_it.dart';

@GenerateMocks([ApiService, AuthProvider])
import 'profile_providers_test.mocks.dart';

void main() {
  group('ProfileProvider Tests', () {
    late ProfileProvider profileProvider;
    late MockApiService mockApiService;
    late MockAuthProvider mockAuthProvider;

    setUp(() {
      GetIt.instance.reset();
      mockApiService = MockApiService();
      mockAuthProvider = MockAuthProvider();
      
      getIt.registerSingleton<ApiService>(mockApiService);
      getIt.registerSingleton<AuthProvider>(mockAuthProvider);
      
      when(mockAuthProvider.token).thenReturn('test_token');
      when(mockAuthProvider.currentUser).thenReturn(
        User(id: '1', username: 'testuser', email: 'test@example.com')
      );
      when(mockAuthProvider.authHeaders).thenReturn({
        'Content-Type': 'application/json',
        'Authorization': 'Token test_token'
      });
      
      profileProvider = ProfileProvider();
    });

    tearDown(() {
      GetIt.instance.reset();
    });

    test('should initialize with current user data', () {
      expect(profileProvider.currentUser, isNotNull);
      expect(profileProvider.currentUser?.username, 'testuser');
      expect(profileProvider.currentUser?.email, 'test@example.com');
    });

    test('should update profile successfully', () async {
      final updatedUser = User(id: '1', username: 'updateduser', email: 'updated@example.com');
      when(mockApiService.updateProfile(any, any)).thenAnswer((_) async => ProfileUpdateResponse(user: updatedUser, success: true));
      
      final result = await profileProvider.updateProfile(
        username: 'updateduser',
        email: 'updated@example.com',
      );
      
      expect(result, isTrue);
      verify(mockApiService.updateProfile('test_token', any)).called(1);
    });

    test('should handle update profile error', () async {
      when(mockApiService.updateProfile(any, any)).thenThrow(Exception('API Error'));
      
      final result = await profileProvider.updateProfile(
        username: 'updateduser',
        email: 'updated@example.com',
      );
      
      expect(result, isFalse);
      expect(profileProvider.hasError, isTrue);
      verify(mockApiService.updateProfile('test_token', any)).called(1);
    });

    test('should change password successfully', () async {
      when(mockApiService.changePassword(any, any, any)).thenAnswer((_) async => PasswordChangeResponse(success: true, message: 'Password changed'));
      
      final result = await profileProvider.changePassword(
        currentPassword: 'oldpass',
        newPassword: 'newpass',
      );
      
      expect(result, isTrue);
      verify(mockApiService.changePassword('test_token', 'oldpass', 'newpass')).called(1);
    });

    test('should handle change password error', () async {
      when(mockApiService.changePassword(any, any, any)).thenThrow(Exception('Password change failed'));
      
      final result = await profileProvider.changePassword(
        currentPassword: 'oldpass',
        newPassword: 'newpass',
      );
      
      expect(result, isFalse);
      expect(profileProvider.hasError, isTrue);
      verify(mockApiService.changePassword('test_token', 'oldpass', 'newpass')).called(1);
    });

    test('should upload profile picture successfully', () async {
      when(mockApiService.uploadProfilePicture(any, any)).thenAnswer((_) async => ProfilePictureResponse(
        success: true,
        imageUrl: 'https://example.com/new-avatar.jpg'
      ));
      
      final result = await profileProvider.uploadProfilePicture('path/to/image.jpg');
      
      expect(result, isTrue);
      verify(mockApiService.uploadProfilePicture('test_token', 'path/to/image.jpg')).called(1);
    });

    test('should handle upload profile picture error', () async {
      when(mockApiService.uploadProfilePicture(any, any)).thenThrow(Exception('Upload failed'));
      
      final result = await profileProvider.uploadProfilePicture('path/to/image.jpg');
      
      expect(result, isFalse);
      expect(profileProvider.hasError, isTrue);
      verify(mockApiService.uploadProfilePicture('test_token', 'path/to/image.jpg')).called(1);
    });

    test('should delete profile picture successfully', () async {
      when(mockApiService.deleteProfilePicture(any)).thenAnswer((_) async => ProfilePictureResponse(success: true));
      
      final result = await profileProvider.deleteProfilePicture();
      
      expect(result, isTrue);
      verify(mockApiService.deleteProfilePicture('test_token')).called(1);
    });

    test('should handle delete profile picture error', () async {
      when(mockApiService.deleteProfilePicture(any)).thenThrow(Exception('Delete failed'));
      
      final result = await profileProvider.deleteProfilePicture();
      
      expect(result, isFalse);
      expect(profileProvider.hasError, isTrue);
      verify(mockApiService.deleteProfilePicture('test_token')).called(1);
    });

    test('should get user statistics successfully', () async {
      final stats = UserStats(
        totalPlaylists: 15,
        totalTracks: 250,
        totalFriends: 12,
        totalPlaytime: 45000,
      );
      
      when(mockApiService.getUserStats(any)).thenAnswer((_) async => UserStatsResponse(stats: stats));
      
      await profileProvider.loadUserStats();
      
      expect(profileProvider.userStats, isNotNull);
      expect(profileProvider.userStats?.totalPlaylists, 15);
      expect(profileProvider.userStats?.totalTracks, 250);
      verify(mockApiService.getUserStats('test_token')).called(1);
    });

    test('should handle get user statistics error', () async {
      when(mockApiService.getUserStats(any)).thenThrow(Exception('Stats load failed'));
      
      await profileProvider.loadUserStats();
      
      expect(profileProvider.userStats, isNull);
      expect(profileProvider.hasError, isTrue);
      verify(mockApiService.getUserStats('test_token')).called(1);
    });

    test('should link social media account successfully', () async {
      when(mockApiService.linkSocialAccount(any, any, any)).thenAnswer((_) async => SocialLinkResponse(
        success: true,
        message: 'Account linked successfully'
      ));
      
      final result = await profileProvider.linkSocialAccount('facebook', 'facebook_token');
      
      expect(result, isTrue);
      verify(mockApiService.linkSocialAccount('test_token', 'facebook', 'facebook_token')).called(1);
    });

    test('should handle link social media account error', () async {
      when(mockApiService.linkSocialAccount(any, any, any)).thenThrow(Exception('Link failed'));
      
      final result = await profileProvider.linkSocialAccount('facebook', 'facebook_token');
      
      expect(result, isFalse);
      expect(profileProvider.hasError, isTrue);
      verify(mockApiService.linkSocialAccount('test_token', 'facebook', 'facebook_token')).called(1);
    });

    test('should unlink social media account successfully', () async {
      when(mockApiService.unlinkSocialAccount(any, any)).thenAnswer((_) async => SocialLinkResponse(
        success: true,
        message: 'Account unlinked successfully'
      ));
      
      final result = await profileProvider.unlinkSocialAccount('facebook');
      
      expect(result, isTrue);
      verify(mockApiService.unlinkSocialAccount('test_token', 'facebook')).called(1);
    });

    test('should handle unlink social media account error', () async {
      when(mockApiService.unlinkSocialAccount(any, any)).thenThrow(Exception('Unlink failed'));
      
      final result = await profileProvider.unlinkSocialAccount('facebook');
      
      expect(result, isFalse);
      expect(profileProvider.hasError, isTrue);
      verify(mockApiService.unlinkSocialAccount('test_token', 'facebook')).called(1);
    });

    test('should get user preferences successfully', () async {
      final preferences = UserPreferences(
        notifications: true,
        privateProfile: false,
        autoPlay: true,
        theme: 'dark',
      );
      
      when(mockApiService.getUserPreferences(any)).thenAnswer((_) async => UserPreferencesResponse(preferences: preferences));
      
      await profileProvider.loadUserPreferences();
      
      expect(profileProvider.userPreferences, isNotNull);
      expect(profileProvider.userPreferences?.notifications, isTrue);
      expect(profileProvider.userPreferences?.theme, 'dark');
      verify(mockApiService.getUserPreferences('test_token')).called(1);
    });

    test('should update user preferences successfully', () async {
      final preferences = UserPreferences(
        notifications: false,
        privateProfile: true,
        autoPlay: false,
        theme: 'light',
      );
      
      when(mockApiService.updateUserPreferences(any, any)).thenAnswer((_) async => UserPreferencesResponse(preferences: preferences));
      
      final result = await profileProvider.updateUserPreferences(preferences);
      
      expect(result, isTrue);
      expect(profileProvider.userPreferences?.notifications, isFalse);
      expect(profileProvider.userPreferences?.theme, 'light');
      verify(mockApiService.updateUserPreferences('test_token', preferences)).called(1);
    });

    test('should handle update user preferences error', () async {
      final preferences = UserPreferences(
        notifications: false,
        privateProfile: true,
        autoPlay: false,
        theme: 'light',
      );
      
      when(mockApiService.updateUserPreferences(any, any)).thenThrow(Exception('Update failed'));
      
      final result = await profileProvider.updateUserPreferences(preferences);
      
      expect(result, isFalse);
      expect(profileProvider.hasError, isTrue);
      verify(mockApiService.updateUserPreferences('test_token', preferences)).called(1);
    });

    test('should refresh profile data', () async {
      final updatedUser = User(id: '1', username: 'refresheduser', email: 'refreshed@example.com');
      when(mockApiService.getCurrentUser(any)).thenAnswer((_) async => UserResponse(user: updatedUser));
      
      await profileProvider.refreshProfile();
      
      verify(mockApiService.getCurrentUser('test_token')).called(1);
    });

    test('should validate username availability', () async {
      when(mockApiService.checkUsernameAvailability(any)).thenAnswer((_) async => UsernameAvailabilityResponse(available: true));
      
      final result = await profileProvider.isUsernameAvailable('newusername');
      
      expect(result, isTrue);
      verify(mockApiService.checkUsernameAvailability('newusername')).called(1);
    });

    test('should handle username availability check error', () async {
      when(mockApiService.checkUsernameAvailability(any)).thenThrow(Exception('Check failed'));
      
      final result = await profileProvider.isUsernameAvailable('newusername');
      
      expect(result, isFalse);
      verify(mockApiService.checkUsernameAvailability('newusername')).called(1);
    });

    test('should handle token not available', () async {
      when(mockAuthProvider.token).thenReturn(null);
      
      final result = await profileProvider.updateProfile(username: 'newuser');
      
      expect(result, isFalse);
      expect(profileProvider.hasError, isTrue);
      verifyNever(mockApiService.updateProfile(any, any));
    });

    test('should notify listeners on state changes', () {
      var notified = false;
      profileProvider.addListener(() => notified = true);
      
      profileProvider.notifyListeners();
      
      expect(notified, isTrue);
    });
  });
}

class ProfileUpdateResponse {
  final User user;
  final bool success;
  ProfileUpdateResponse({required this.user, required this.success});
}

class PasswordChangeResponse {
  final bool success;
  final String message;
  PasswordChangeResponse({required this.success, required this.message});
}

class ProfilePictureResponse {
  final bool success;
  final String? imageUrl;
  ProfilePictureResponse({required this.success, this.imageUrl});
}

class UserStats {
  final int totalPlaylists;
  final int totalTracks;
  final int totalFriends;
  final int totalPlaytime;
  
  UserStats({
    required this.totalPlaylists,
    required this.totalTracks,
    required this.totalFriends,
    required this.totalPlaytime,
  });
}

class UserStatsResponse {
  final UserStats stats;
  UserStatsResponse({required this.stats});
}

class SocialLinkResponse {
  final bool success;
  final String message;
  SocialLinkResponse({required this.success, required this.message});
}

class UserPreferences {
  final bool notifications;
  final bool privateProfile;
  final bool autoPlay;
  final String theme;
  
  UserPreferences({
    required this.notifications,
    required this.privateProfile,
    required this.autoPlay,
    required this.theme,
  });
}

class UserPreferencesResponse {
  final UserPreferences preferences;
  UserPreferencesResponse({required this.preferences});
}

class UserResponse {
  final User user;
  UserResponse({required this.user});
}

class UsernameAvailabilityResponse {
  final bool available;
  UsernameAvailabilityResponse({required this.available});
}
