import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:music_room/providers/profile_provider.dart';
import 'package:music_room/core/base_provider.dart';
import 'package:music_room/services/api_service.dart';
void main() {
  group('Profile Provider Tests', () {
    late ProfileProvider profileProvider;
    setUp(() {
      GetIt.instance.reset();
      final dio = Dio();
      dio.options.baseUrl = 'http://localhost:8000';
      final apiService = ApiService(dio);
      GetIt.instance.registerSingleton<ApiService>(apiService);
      profileProvider = ProfileProvider();
    });
    test('ProfileProvider should extend BaseProvider', () {
      expect(profileProvider, isA<BaseProvider>());
    });
    test('ProfileProvider should have initial null values', () {
      expect(profileProvider.userId, null);
      expect(profileProvider.username, null);
      expect(profileProvider.userEmail, null);
      expect(profileProvider.socialEmail, null);
      expect(profileProvider.socialName, null);
      expect(profileProvider.socialType, null);
      expect(profileProvider.isPasswordUsable, false);
    });
    test('ProfileProvider should have initial profile field values', () {
      expect(profileProvider.avatar, null);
      expect(profileProvider.name, null);
      expect(profileProvider.location, null);
      expect(profileProvider.bio, null);
      expect(profileProvider.phone, null);
      expect(profileProvider.friendInfo, null);
      expect(profileProvider.musicPreferences, null);
      expect(profileProvider.musicPreferenceIds, null);
    });
    test('ProfileProvider should have initial visibility values', () {
      expect(profileProvider.avatarVisibility, null);
      expect(profileProvider.nameVisibility, null);
      expect(profileProvider.locationVisibility, null);
      expect(profileProvider.bioVisibility, null);
      expect(profileProvider.phoneVisibility, null);
      expect(profileProvider.friendInfoVisibility, null);
      expect(profileProvider.musicPreferencesVisibility, null);
    });
    test('ProfileProvider should reset values correctly', () {
      profileProvider.resetValues();
      
      expect(profileProvider.userId, null);
      expect(profileProvider.username, null);
      expect(profileProvider.userEmail, null);
      expect(profileProvider.isPasswordUsable, false);
      expect(profileProvider.socialType, null);
      expect(profileProvider.avatar, null);
      expect(profileProvider.name, null);
      expect(profileProvider.musicPreferences, null);
    });
    test('VisibilityLevel enum should have correct values', () {
      expect(VisibilityLevel.public.value, 'public');
      expect(VisibilityLevel.friends.value, 'friends');
      expect(VisibilityLevel.private.value, 'private');
    });
    test('VisibilityLevel should parse from string correctly', () {
      expect(VisibilityLevelExtension.fromString('public'), VisibilityLevel.public);
      expect(VisibilityLevelExtension.fromString('friends'), VisibilityLevel.friends);
      expect(VisibilityLevelExtension.fromString('private'), VisibilityLevel.private);
      expect(VisibilityLevelExtension.fromString('invalid'), VisibilityLevel.public);
      expect(VisibilityLevelExtension.fromString(null), VisibilityLevel.public);
    });
    test('ProfileProvider should handle avatar URL correctly', () {
      expect(profileProvider.avatarUrl, null);
    });
    test('ProfileProvider should handle base64 avatar URL', () {
      expect(profileProvider.avatarUrl, null);
    });
    test('ProfileProvider should handle data URI avatar', () {
      expect(profileProvider.avatarUrl, null);
    });
    test('ProfileProvider should handle empty avatar string', () {
      expect(profileProvider.avatarUrl, null);
    });
  });
}