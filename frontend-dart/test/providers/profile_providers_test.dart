import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:music_room/providers/profile_providers.dart';
import 'package:music_room/services/api_services.dart';
import 'package:music_room/models/api_models.dart';
import 'package:music_room/core/locator_core.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  late ProfileProvider provider;
  late MockApiService mockApiService;

  setUp(() {
    mockApiService = MockApiService();
    if (!getIt.isRegistered<ApiService>()) {
      getIt.registerLazySingleton<ApiService>(() => mockApiService);
    }
    provider = ProfileProvider();
  });

  tearDown(() {
    provider.dispose();
    if (getIt.isRegistered<ApiService>()) {
      getIt.unregister<ApiService>();
    }
  });

  group('ProfileProvider Tests', () {
    group('Initial State', () {
      test('should initialize with correct default values', () {
        expect(provider.userId, isNull);
        expect(provider.username, isNull);
        expect(provider.userEmail, isNull);
        expect(provider.socialEmail, isNull);
        expect(provider.socialName, isNull);
        expect(provider.socialType, isNull);
        expect(provider.isPasswordUsable, isFalse);
        expect(provider.avatar, isNull);
        expect(provider.name, isNull);
        expect(provider.location, isNull);
        expect(provider.bio, isNull);
        expect(provider.phone, isNull);
        expect(provider.friendInfo, isNull);
        expect(provider.musicPreferences, isNull);
        expect(provider.musicPreferenceIds, isNull);
        expect(provider.avatarVisibility, isNull);
        expect(provider.nameVisibility, isNull);
        expect(provider.locationVisibility, isNull);
        expect(provider.bioVisibility, isNull);
        expect(provider.phoneVisibility, isNull);
        expect(provider.friendInfoVisibility, isNull);
        expect(provider.musicPreferencesVisibility, isNull);
        expect(provider.isLoading, isFalse);
        expect(provider.hasError, isFalse);
        expect(provider.hasSuccess, isFalse);
      });
    });

    group('resetValues', () {
      test('should reset all values to defaults', () {
        provider.resetValues();
        
        expect(provider.userId, isNull);
        expect(provider.username, isNull);
        expect(provider.userEmail, isNull);
        expect(provider.socialEmail, isNull);
        expect(provider.socialName, isNull);
        expect(provider.socialType, isNull);
        expect(provider.isPasswordUsable, isFalse);
        expect(provider.avatar, isNull);
        expect(provider.name, isNull);
        expect(provider.location, isNull);
        expect(provider.bio, isNull);
        expect(provider.phone, isNull);
        expect(provider.friendInfo, isNull);
        expect(provider.musicPreferences, isNull);
        expect(provider.musicPreferenceIds, isNull);
        expect(provider.avatarVisibility, isNull);
        expect(provider.nameVisibility, isNull);
        expect(provider.locationVisibility, isNull);
        expect(provider.bioVisibility, isNull);
        expect(provider.phoneVisibility, isNull);
        expect(provider.friendInfoVisibility, isNull);
        expect(provider.musicPreferencesVisibility, isNull);
      });
    });

    group('loadProfile', () {
      test('should load profile successfully with user data and profile data', () async {
        final userData = UserResponse(
          id: 'user123',
          username: 'testuser',
          email: 'test@example.com',
          isPasswordUsable: true,
          hasSocialAccount: true,
          social: {
            'type': 'google',
            'social_email': 'social@example.com',
            'social_name': 'Social Name'
          },
        );
        
        final profileData = ProfileResponse(
          avatar: 'base64avatar',
          name: 'Test User',
          location: 'Test City',
          bio: 'Test bio',
          phone: '+1234567890',
          friendInfo: 'Friend info',
          musicPreferences: ['Rock', 'Pop'],
          musicPreferencesIds: [1, 2],
          avatarVisibility: 'public',
          nameVisibility: 'friends',
          locationVisibility: 'private',
          bioVisibility: 'public',
          phoneVisibility: 'private',
          friendInfoVisibility: 'friends',
          musicPreferencesVisibility: 'public',
        );

        when(mockApiService.getUser('token123'))
            .thenAnswer((_) async => userData);
        when(mockApiService.getMyProfile('token123'))
            .thenAnswer((_) async => profileData);

        final result = await provider.loadProfile('token123');

        expect(result, isTrue);
        expect(provider.userId, 'user123');
        expect(provider.username, 'testuser');
        expect(provider.userEmail, 'test@example.com');
        expect(provider.isPasswordUsable, isTrue);
        expect(provider.socialType, 'google');
        expect(provider.socialEmail, 'social@example.com');
        expect(provider.socialName, 'Social Name');
        expect(provider.avatar, 'base64avatar');
        expect(provider.name, 'Test User');
        expect(provider.location, 'Test City');
        expect(provider.bio, 'Test bio');
        expect(provider.phone, '+1234567890');
        expect(provider.friendInfo, 'Friend info');
        expect(provider.musicPreferences, ['Rock', 'Pop']);
        expect(provider.musicPreferenceIds, [1, 2]);
        expect(provider.avatarVisibility, VisibilityLevel.public);
        expect(provider.nameVisibility, VisibilityLevel.friends);
        expect(provider.locationVisibility, VisibilityLevel.private);
        expect(provider.bioVisibility, VisibilityLevel.public);
        expect(provider.phoneVisibility, VisibilityLevel.private);
        expect(provider.friendInfoVisibility, VisibilityLevel.friends);
        expect(provider.musicPreferencesVisibility, VisibilityLevel.public);
        expect(provider.hasSuccess, isTrue);
      });

      test('should load profile with fallback visibility settings when profile data fails', () async {
        final userData = UserResponse(
          id: 'user123',
          username: 'testuser',
          email: 'test@example.com',
          isPasswordUsable: false,
          hasSocialAccount: false,
        );

        when(mockApiService.getUser('token123'))
            .thenAnswer((_) async => userData);
        when(mockApiService.getMyProfile('token123'))
            .thenThrow(Exception('Profile not found'));

        final result = await provider.loadProfile('token123');

        expect(result, isTrue);
        expect(provider.userId, 'user123');
        expect(provider.username, 'testuser');
        expect(provider.userEmail, 'test@example.com');
        expect(provider.isPasswordUsable, isFalse);
        expect(provider.socialType, isNull);
        expect(provider.avatar, isNull);
        expect(provider.name, isNull);
        expect(provider.avatarVisibility, VisibilityLevel.public);
        expect(provider.nameVisibility, VisibilityLevel.public);
        expect(provider.locationVisibility, VisibilityLevel.public);
        expect(provider.bioVisibility, VisibilityLevel.public);
        expect(provider.phoneVisibility, VisibilityLevel.private);
        expect(provider.friendInfoVisibility, VisibilityLevel.friends);
        expect(provider.musicPreferencesVisibility, VisibilityLevel.public);
      });

      test('should handle failure when user data fails', () async {
        when(mockApiService.getUser('invalid_token'))
            .thenThrow(Exception('User not found'));

        final result = await provider.loadProfile('invalid_token');

        expect(result, isFalse);
        expect(provider.hasError, isTrue);
        expect(provider.errorMessage, contains('User not found'));
      });
    });

    group('userPasswordChange', () {
      test('should change password successfully', () async {
        when(mockApiService.userPasswordChange('token123', 
            const PasswordChangeRequest(currentPassword: 'oldpass', newPassword: 'newpass')))
            .thenAnswer((_) async {});

        final result = await provider.userPasswordChange('token123', 'oldpass', 'newpass');

        expect(result, isTrue);
        expect(provider.hasSuccess, isTrue);
        expect(provider.successMessage, 'Password changed successfully');
      });

      test('should handle password change failure', () async {
        when(mockApiService.userPasswordChange('token123', 
            const PasswordChangeRequest(currentPassword: 'wrongpass', newPassword: 'newpass')))
            .thenThrow(Exception('Invalid current password'));

        final result = await provider.userPasswordChange('token123', 'wrongpass', 'newpass');

        expect(result, isFalse);
        expect(provider.hasError, isTrue);
        expect(provider.errorMessage, contains('Invalid current password'));
      });
    });

    group('getMusicPreferences', () {
      test('should return music preferences list', () async {
        final mockPreferences = [
          {'id': 1, 'name': 'Rock'},
          {'id': 2, 'name': 'Pop'},
          {'id': 3, 'name': 'Jazz'},
        ];

        when(mockApiService.getMusicPreferences('token123'))
            .thenAnswer((_) async => mockPreferences);

        final result = await provider.getMusicPreferences('token123');

        expect(result, equals(mockPreferences));
      });

      test('should return empty list on error', () async {
        when(mockApiService.getMusicPreferences('token123'))
            .thenThrow(Exception('Network error'));

        final result = await provider.getMusicPreferences('token123');

        expect(result, isEmpty);
      });
    });

    group('deleteAvatar', () {
      test('should delete avatar successfully', () async {
        when(mockApiService.deleteAvatar('token123'))
            .thenAnswer((_) async {});

        final result = await provider.deleteAvatar('token123');

        expect(result, isTrue);
        expect(provider.avatar, isNull);
        expect(provider.hasSuccess, isTrue);
        expect(provider.successMessage, 'Avatar deleted successfully');
      });

      test('should handle delete avatar failure', () async {
        when(mockApiService.deleteAvatar('token123'))
            .thenThrow(Exception('Avatar not found'));

        final result = await provider.deleteAvatar('token123');

        expect(result, isFalse);
        expect(provider.hasError, isTrue);
        expect(provider.errorMessage, contains('Avatar not found'));
      });
    });

    group('avatarUrl getter', () {
      test('should return null when avatar is null or empty', () {
        provider.resetValues();
        expect(provider.avatarUrl, isNull);
      });
    });

    group('BaseProvider functionality', () {
      test('should handle loading state correctly', () {
        expect(provider.isLoading, isFalse);
        expect(provider.isReady, isTrue);
        
        provider.setLoading(true);
        expect(provider.isLoading, isTrue);
        expect(provider.isReady, isFalse);
        
        provider.setLoading(false);
        expect(provider.isLoading, isFalse);
        expect(provider.isReady, isTrue);
      });

      test('should handle error state correctly', () {
        provider.setError('Test error');
        
        expect(provider.hasError, isTrue);
        expect(provider.errorMessage, 'Test error');
        expect(provider.hasSuccess, isFalse);
        expect(provider.isReady, isFalse);
      });

      test('should handle success state correctly', () {
        provider.setSuccess('Test success');
        
        expect(provider.hasSuccess, isTrue);
        expect(provider.successMessage, 'Test success');
        expect(provider.hasError, isFalse);
        expect(provider.isReady, isTrue);
      });

      test('should clear messages correctly', () {
        provider.setError('Test error');
        provider.clearMessages();
        
        expect(provider.hasError, isFalse);
        expect(provider.errorMessage, isNull);
        expect(provider.hasSuccess, isFalse);
        expect(provider.successMessage, isNull);
      });
    });
  });

  group('VisibilityLevel enum', () {
    test('should have correct string values', () {
      expect(VisibilityLevel.public.value, 'public');
      expect(VisibilityLevel.friends.value, 'friends');
      expect(VisibilityLevel.private.value, 'private');
    });

    test('should parse from string correctly', () {
      expect(VisibilityLevelExtension.fromString('public'), VisibilityLevel.public);
      expect(VisibilityLevelExtension.fromString('friends'), VisibilityLevel.friends);
      expect(VisibilityLevelExtension.fromString('private'), VisibilityLevel.private);
      expect(VisibilityLevelExtension.fromString('invalid'), VisibilityLevel.public);
      expect(VisibilityLevelExtension.fromString(null), VisibilityLevel.public);
    });
  });
}