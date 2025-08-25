import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:music_room/services/api_services.dart';
import 'package:music_room/providers/auth_providers.dart';
import 'package:music_room/models/api_models.dart';
import 'package:music_room/core/locator_core.dart';
import 'package:get_it/get_it.dart';

@GenerateMocks([ApiService, AuthProvider])
import 'activity_services_test.mocks.dart';

void main() {
  group('ActivityService Tests', () {
    late ActivityService activityService;
    late MockApiService mockApiService;
    late MockAuthProvider mockAuthProvider;

    setUp(() {
      GetIt.instance.reset();
      mockApiService = MockApiService();
      mockAuthProvider = MockAuthProvider();
      
      getIt.registerSingleton<ApiService>(mockApiService);
      getIt.registerSingleton<AuthProvider>(mockAuthProvider);
      
      when(mockAuthProvider.token).thenReturn('test_token');
      
      activityService = ActivityService();
    });

    tearDown(() {
      GetIt.instance.reset();
    });

    test('should log user activity successfully', () async {
      when(mockApiService.logActivity(any, any)).thenAnswer((_) async => ActivityLogResponse(success: true));
      
      await activityService.logUserActivity(
        action: 'test_action',
        token: 'test_token',
        details: 'test details',
        metadata: {'key': 'value'},
      );
      
      verify(mockApiService.logActivity('test_token', any)).called(1);
    });

    test('should handle log user activity error gracefully', () async {
      when(mockApiService.logActivity(any, any)).thenThrow(Exception('API Error'));
      
      await expectLater(
        activityService.logUserActivity(
          action: 'test_action',
          token: 'test_token',
          details: 'test details',
        ),
        completes,
      );
      
      verify(mockApiService.logActivity('test_token', any)).called(1);
    });

    test('should log button click successfully', () async {
      when(mockApiService.logActivity(any, any)).thenAnswer((_) async => ActivityLogResponse(success: true));
      
      await activityService.logButtonClick('login_button', 'test_token');
      
      verify(mockApiService.logActivity('test_token', any)).called(1);
    });

    test('should log button click with metadata', () async {
      when(mockApiService.logActivity(any, any)).thenAnswer((_) async => ActivityLogResponse(success: true));
      
      await activityService.logButtonClick(
        'play_button',
        'test_token',
        metadata: {'track_id': '123', 'playlist_id': '456'},
      );
      
      verify(mockApiService.logActivity('test_token', any)).called(1);
    });

    test('should log screen view successfully', () async {
      when(mockApiService.logActivity(any, any)).thenAnswer((_) async => ActivityLogResponse(success: true));
      
      await activityService.logScreenView('home_screen', 'test_token');
      
      verify(mockApiService.logActivity('test_token', any)).called(1);
    });

    test('should log screen view with metadata', () async {
      when(mockApiService.logActivity(any, any)).thenAnswer((_) async => ActivityLogResponse(success: true));
      
      await activityService.logScreenView(
        'profile_screen',
        'test_token',
        metadata: {'user_id': '789'},
      );
      
      verify(mockApiService.logActivity('test_token', any)).called(1);
    });

    test('should log playlist action successfully', () async {
      when(mockApiService.logActivity(any, any)).thenAnswer((_) async => ActivityLogResponse(success: true));
      
      await activityService.logPlaylistAction('create', 'playlist_123', 'test_token');
      
      verify(mockApiService.logActivity('test_token', any)).called(1);
    });

    test('should log playlist action with metadata', () async {
      when(mockApiService.logActivity(any, any)).thenAnswer((_) async => ActivityLogResponse(success: true));
      
      await activityService.logPlaylistAction(
        'share',
        'playlist_456',
        'test_token',
        metadata: {'recipient_count': 5},
      );
      
      verify(mockApiService.logActivity('test_token', any)).called(1);
    });

    test('should log track action successfully', () async {
      when(mockApiService.logActivity(any, any)).thenAnswer((_) async => ActivityLogResponse(success: true));
      
      await activityService.logTrackAction('play', 'track_789', 'test_token');
      
      verify(mockApiService.logActivity('test_token', any)).called(1);
    });

    test('should log track action with metadata', () async {
      when(mockApiService.logActivity(any, any)).thenAnswer((_) async => ActivityLogResponse(success: true));
      
      await activityService.logTrackAction(
        'favorite',
        'track_101',
        'test_token',
        metadata: {'from_playlist': 'playlist_202'},
      );
      
      verify(mockApiService.logActivity('test_token', any)).called(1);
    });

    test('should log activity with auth provider token', () async {
      when(mockApiService.logActivity(any, any)).thenAnswer((_) async => ActivityLogResponse(success: true));
      
      await activityService.logActivity(
        action: 'auto_action',
        details: 'auto details',
      );
      
      verify(mockApiService.logActivity('test_token', any)).called(1);
    });

    test('should handle log activity with null token', () async {
      when(mockAuthProvider.token).thenReturn(null);
      
      await activityService.logActivity(
        action: 'test_action',
        details: 'test details',
      );
      
      verifyNever(mockApiService.logActivity(any, any));
    });

    test('should handle log activity error gracefully', () async {
      when(mockApiService.logActivity(any, any)).thenThrow(Exception('Network error'));
      
      await expectLater(
        activityService.logActivity(
          action: 'test_action',
          details: 'test details',
        ),
        completes,
      );
      
      verify(mockApiService.logActivity('test_token', any)).called(1);
    });

    test('should log playlist action automatically', () async {
      when(mockApiService.logActivity(any, any)).thenAnswer((_) async => ActivityLogResponse(success: true));
      
      await activityService.logPlaylistActionAuto('edit', 'playlist_999');
      
      verify(mockApiService.logActivity('test_token', any)).called(1);
    });

    test('should log playlist action automatically with metadata', () async {
      when(mockApiService.logActivity(any, any)).thenAnswer((_) async => ActivityLogResponse(success: true));
      
      await activityService.logPlaylistActionAuto(
        'delete',
        'playlist_888',
        metadata: {'confirmation': true},
      );
      
      verify(mockApiService.logActivity('test_token', any)).called(1);
    });

    test('should log track action automatically', () async {
      when(mockApiService.logActivity(any, any)).thenAnswer((_) async => ActivityLogResponse(success: true));
      
      await activityService.logTrackActionAuto('skip', 'track_555');
      
      verify(mockApiService.logActivity('test_token', any)).called(1);
    });

    test('should log track action automatically with metadata', () async {
      when(mockApiService.logActivity(any, any)).thenAnswer((_) async => ActivityLogResponse(success: true));
      
      await activityService.logTrackActionAuto(
        'rate',
        'track_444',
        metadata: {'rating': 5},
      );
      
      verify(mockApiService.logActivity('test_token', any)).called(1);
    });

    test('should handle multiple concurrent activity logs', () async {
      when(mockApiService.logActivity(any, any)).thenAnswer((_) async => ActivityLogResponse(success: true));
      
      final futures = [
        activityService.logActivity(action: 'action1', details: 'details1'),
        activityService.logActivity(action: 'action2', details: 'details2'),
        activityService.logActivity(action: 'action3', details: 'details3'),
      ];
      
      await Future.wait(futures);
      
      verify(mockApiService.logActivity('test_token', any)).called(3);
    });

    test('should handle activity logging with empty metadata', () async {
      when(mockApiService.logActivity(any, any)).thenAnswer((_) async => ActivityLogResponse(success: true));
      
      await activityService.logActivity(
        action: 'test_action',
        details: 'test details',
        metadata: {},
      );
      
      verify(mockApiService.logActivity('test_token', any)).called(1);
    });

    test('should handle activity logging with complex metadata', () async {
      when(mockApiService.logActivity(any, any)).thenAnswer((_) async => ActivityLogResponse(success: true));
      
      await activityService.logActivity(
        action: 'complex_action',
        details: 'complex details',
        metadata: {
          'string_value': 'test',
          'number_value': 42,
          'boolean_value': true,
          'nested_map': {
            'inner_key': 'inner_value',
          },
          'list_value': [1, 2, 3],
        },
      );
      
      verify(mockApiService.logActivity('test_token', any)).called(1);
    });

    test('should handle network timeout gracefully', () async {
      when(mockApiService.logActivity(any, any)).thenAnswer((_) async {
        await Future.delayed(Duration(seconds: 10));
        throw Exception('Timeout');
      });
      
      await expectLater(
        activityService.logActivity(action: 'timeout_test'),
        completes,
      );
    });

    test('should handle API rate limiting gracefully', () async {
      when(mockApiService.logActivity(any, any)).thenThrow(Exception('Rate limit exceeded'));
      
      await expectLater(
        activityService.logActivity(action: 'rate_limit_test'),
        completes,
      );
    });

    test('should validate required parameters', () async {
      when(mockApiService.logActivity(any, any)).thenAnswer((_) async => ActivityLogResponse(success: true));
      
      await activityService.logUserActivity(
        action: 'required_test',
        token: 'required_token',
      );
      
      verify(mockApiService.logActivity('required_token', any)).called(1);
    });

    test('should handle special characters in activity data', () async {
      when(mockApiService.logActivity(any, any)).thenAnswer((_) async => ActivityLogResponse(success: true));
      
      await activityService.logActivity(
        action: 'special_chars_àáâãäåæçèéêëìíîïðñòóôõö',
        details: 'Details with émojis 🎵🎶 and symbols !@#$%^&*()',
        metadata: {
          'unicode': 'ñáéíóú',
          'symbols': '!@#$%^&*()',
          'emojis': '🎵🎶🎸🥁',
        },
      );
      
      verify(mockApiService.logActivity('test_token', any)).called(1);
    });

    test('should create proper ActivityLogRequest object', () async {
      ActivityLogRequest? capturedRequest;
      
      when(mockApiService.logActivity(any, any)).thenAnswer((invocation) async {
        capturedRequest = invocation.positionalArguments[1] as ActivityLogRequest;
        return ActivityLogResponse(success: true);
      });
      
      await activityService.logUserActivity(
        action: 'test_action',
        token: 'test_token',
        details: 'test_details',
        metadata: {'test_key': 'test_value'},
      );
      
      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.action, 'test_action');
      expect(capturedRequest!.details, 'test_details');
      expect(capturedRequest!.metadata, {'test_key': 'test_value'});
    });
  });
}

class ActivityLogResponse {
  final bool success;
  ActivityLogResponse({required this.success});
}

class ActivityLogRequest {
  final String action;
  final String? details;
  final Map<String, dynamic>? metadata;
  
  ActivityLogRequest({
    required this.action,
    this.details,
    this.metadata,
  });
}
