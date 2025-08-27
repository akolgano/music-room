import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:music_room/providers/profile_providers.dart';
import 'package:music_room/services/api_services.dart';
import 'package:music_room/services/auth_services.dart';
import 'package:music_room/models/api_models.dart';
import 'package:music_room/models/music_models.dart';
import 'package:music_room/core/locator_core.dart';
import 'package:get_it/get_it.dart';

import 'profile_providers_test.mocks.dart';

@GenerateMocks([ApiService, AuthService])


void main() {
  group('ProfileProvider Tests', () {
    late ProfileProvider profileProvider;
    late MockApiService mockApiService;
    late MockAuthService mockAuthService;

    setUp(() {
      GetIt.instance.reset();
      mockApiService = MockApiService();
      mockAuthService = MockAuthService();
      
      getIt.registerSingleton<ApiService>(mockApiService);
      getIt.registerSingleton<AuthService>(mockAuthService);
      
      when(mockAuthService.currentToken).thenReturn('test_token');
      when(mockAuthService.currentUser).thenReturn(
        User(id: '1', username: 'testuser', email: 'test@example.com')
      );
      
      profileProvider = ProfileProvider();
    });

    tearDown(() {
      GetIt.instance.reset();
    });

    test('should load profile successfully', () async {
      when(mockApiService.getUser(any)).thenAnswer((_) async => User(
        id: '1',
        username: 'testuser',
        email: 'test@example.com',
      ));
      when(mockApiService.getMyProfile(any)).thenAnswer((_) async => ProfileResponse(
        avatar: 'avatar_url',
        name: 'Test User',
        location: 'Test Location',
      ));
      
      final result = await profileProvider.loadProfile('test_token');
      
      expect(result, isTrue);
      expect(profileProvider.username, 'testuser');
      expect(profileProvider.userEmail, 'test@example.com');
      verify(mockApiService.getUser('test_token')).called(1);
    });

    test('should update profile successfully', () async {
      when(mockApiService.updateProfileWithFile(
        any,
        name: anyNamed('name'),
        location: anyNamed('location'),
        bio: anyNamed('bio'),
        phone: anyNamed('phone'),
        friendInfo: anyNamed('friendInfo'),
        musicPreferencesIds: anyNamed('musicPreferencesIds'),
      )).thenAnswer((_) async => ProfileResponse(
        name: 'Updated User',
        location: 'Updated Location',
      ));
      
      final result = await profileProvider.updateProfile(
        'test_token',
        name: 'Updated User',
        location: 'Updated Location',
      );
      
      expect(result, isTrue);
      verify(mockApiService.updateProfileWithFile(
        'test_token',
        name: 'Updated User',
        location: 'Updated Location',
        bio: null,
        phone: null,
        friendInfo: null,
        musicPreferencesIds: null,
      )).called(1);
    });

    test('should handle update profile error', () async {
      when(mockApiService.updateProfileWithFile(
        any,
        name: anyNamed('name'),
        location: anyNamed('location'),
        bio: anyNamed('bio'),
        phone: anyNamed('phone'),
        friendInfo: anyNamed('friendInfo'),
        musicPreferencesIds: anyNamed('musicPreferencesIds'),
      )).thenThrow(Exception('API Error'));
      
      final result = await profileProvider.updateProfile(
        'test_token',
        name: 'Updated User',
      );
      
      expect(result, isFalse);
      expect(profileProvider.hasError, isTrue);
    });

    test('should change password successfully', () async {
      when(mockApiService.userPasswordChange(any, any)).thenAnswer((_) async {});
      
      final result = await profileProvider.userPasswordChange(
        'test_token',
        'oldpass',
        'newpass',
      );
      
      expect(result, isTrue);
      verify(mockApiService.userPasswordChange('test_token', any)).called(1);
    });

    test('should handle change password error', () async {
      when(mockApiService.userPasswordChange(any, any)).thenThrow(Exception('Password change failed'));
      
      final result = await profileProvider.userPasswordChange(
        'test_token',
        'oldpass',
        'newpass',
      );
      
      expect(result, isFalse);
      expect(profileProvider.hasError, isTrue);
      verify(mockApiService.userPasswordChange('test_token', any)).called(1);
    });

    test('should delete avatar successfully', () async {
      when(mockApiService.deleteAvatar(any)).thenAnswer((_) async {});
      
      final result = await profileProvider.deleteAvatar('test_token');
      
      expect(result, isTrue);
      expect(profileProvider.avatar, isNull);
      verify(mockApiService.deleteAvatar('test_token')).called(1);
    });

    test('should handle delete avatar error', () async {
      when(mockApiService.deleteAvatar(any)).thenThrow(Exception('Delete failed'));
      
      final result = await profileProvider.deleteAvatar('test_token');
      
      expect(result, isFalse);
      expect(profileProvider.hasError, isTrue);
      verify(mockApiService.deleteAvatar('test_token')).called(1);
    });

    test('should get music preferences successfully', () async {
      final preferences = [
        {'id': 1, 'name': 'Rock'},
        {'id': 2, 'name': 'Jazz'},
      ];
      
      when(mockApiService.getMusicPreferences(any)).thenAnswer((_) async => preferences);
      
      final result = await profileProvider.getMusicPreferences('test_token');
      
      expect(result, isNotEmpty);
      expect(result.length, 2);
      expect(result[0]['name'], 'Rock');
      verify(mockApiService.getMusicPreferences('test_token')).called(1);
    });

    test('should handle get music preferences error', () async {
      when(mockApiService.getMusicPreferences(any)).thenThrow(Exception('Failed to load preferences'));
      
      final result = await profileProvider.getMusicPreferences('test_token');
      
      expect(result, isEmpty);
      verify(mockApiService.getMusicPreferences('test_token')).called(1);
    });

    test('should update visibility settings successfully', () async {
      when(mockApiService.updateProfileWithFile(
        any,
        avatarVisibility: anyNamed('avatarVisibility'),
        nameVisibility: anyNamed('nameVisibility'),
        locationVisibility: anyNamed('locationVisibility'),
        bioVisibility: anyNamed('bioVisibility'),
        phoneVisibility: anyNamed('phoneVisibility'),
        friendInfoVisibility: anyNamed('friendInfoVisibility'),
        musicPreferencesVisibility: anyNamed('musicPreferencesVisibility'),
      )).thenAnswer((_) async => ProfileResponse(
        avatarVisibility: 'public',
        nameVisibility: 'friends',
      ));
      
      final result = await profileProvider.updateVisibility(
        'test_token',
        avatarVisibility: VisibilityLevel.public,
        nameVisibility: VisibilityLevel.friends,
      );
      
      expect(result, isTrue);
      expect(profileProvider.avatarVisibility, VisibilityLevel.public);
      expect(profileProvider.nameVisibility, VisibilityLevel.friends);
    });

    test('should handle visibility update error', () async {
      when(mockApiService.updateProfileWithFile(
        any,
        avatarVisibility: anyNamed('avatarVisibility'),
        nameVisibility: anyNamed('nameVisibility'),
        locationVisibility: anyNamed('locationVisibility'),
        bioVisibility: anyNamed('bioVisibility'),
        phoneVisibility: anyNamed('phoneVisibility'),
        friendInfoVisibility: anyNamed('friendInfoVisibility'),
        musicPreferencesVisibility: anyNamed('musicPreferencesVisibility'),
      )).thenThrow(Exception('Update failed'));
      
      final result = await profileProvider.updateVisibility(
        'test_token',
        avatarVisibility: VisibilityLevel.private,
      );
      
      expect(result, isFalse);
      expect(profileProvider.hasError, isTrue);
    });

    test('should reset values correctly', () {
      profileProvider.resetValues();
      
      expect(profileProvider.userId, isNull);
      expect(profileProvider.username, isNull);
      expect(profileProvider.userEmail, isNull);
      expect(profileProvider.avatar, isNull);
      expect(profileProvider.name, isNull);
      expect(profileProvider.location, isNull);
      expect(profileProvider.bio, isNull);
      expect(profileProvider.avatarVisibility, isNull);
    });

    test('should handle null token in loadProfile', () async {
      final result = await profileProvider.loadProfile(null);
      
      expect(result, isFalse);
      expect(profileProvider.hasError, isTrue);
      verifyNever(mockApiService.getUser(any));
    });

    test('should notify listeners on state changes', () {
      var notified = false;
      profileProvider.addListener(() => notified = true);
      
      profileProvider.notifyListeners();
      
      expect(notified, isTrue);
    });
  });
}

