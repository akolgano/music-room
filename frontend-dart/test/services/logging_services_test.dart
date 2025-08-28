import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/services/logging_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('FrontendLoggingService Tests', () {
    late FrontendLoggingService loggingService;

    setUp(() {
      loggingService = FrontendLoggingService();
    });

    test('should create FrontendLoggingService instance', () {
      expect(loggingService, isA<FrontendLoggingService>());
    });

    test('should handle user ID updates', () {
      loggingService.updateUserId('testUser123');
      expect(() => loggingService.updateUserId('testUser123'), returnsNormally);
    });

    test('should handle current route updates', () {
      loggingService.updateCurrentRoute('/test-route');
      expect(() => loggingService.updateCurrentRoute('/test-route'), returnsNormally);
    });

    test('should sanitize sensitive metadata', () {
      final testMetadata = {
        'username': 'testuser',
        'password': 'secret123',
        'token': 'abc123def456',
        'normalField': 'normalValue'
      };
      
      final sanitized = loggingService.sanitizeMetadata(testMetadata);
      
      expect(sanitized['username'], equals('testuser'));
      expect(sanitized['password'], equals('[MASKED]'));
      expect(sanitized['token'], equals('[MASKED]'));
      expect(sanitized['normalField'], equals('normalValue'));
    });

    test('should handle null metadata in sanitization', () {
      final sanitized = loggingService.sanitizeMetadata(null);
      expect(sanitized, isA<Map<String, dynamic>>());
      expect(sanitized.isEmpty, isTrue);
    });

    test('should sanitize nested metadata', () {
      final testMetadata = {
        'user': {
          'name': 'John',
          'secret': 'hidden'
        },
        'normalField': 'value'
      };
      
      final sanitized = loggingService.sanitizeMetadata(testMetadata);
      
      expect(sanitized['user']['name'], equals('John'));
      expect(sanitized['user']['secret'], equals('[MASKED]'));
      expect(sanitized['normalField'], equals('value'));
    });

    test('should handle list metadata sanitization', () {
      final testMetadata = {
        'items': ['normal', 'password=secret', 'token=abc123'],
        'normalField': 'value'
      };
      
      final sanitized = loggingService.sanitizeMetadata(testMetadata);
      
      expect(sanitized['items'][0], equals('normal'));
      expect(sanitized['items'][1], equals('[MASKED]'));
      expect(sanitized['items'][2], equals('[MASKED]'));
      expect(sanitized['normalField'], equals('value'));
    });
  });

  group('FrontendLogEvent Tests', () {
    test('should create FrontendLogEvent instance', () {
      final event = FrontendLogEvent(
        id: 'test-id',
        timestamp: DateTime.now(),
        actionType: UserActionType.buttonClick,
        description: 'Test button click',
      );
      
      expect(event, isA<FrontendLogEvent>());
      expect(event.id, equals('test-id'));
      expect(event.actionType, equals(UserActionType.buttonClick));
      expect(event.description, equals('Test button click'));
      expect(event.level, equals(LogLevel.info));
    });

    test('should convert to JSON correctly', () {
      final timestamp = DateTime.now();
      final event = FrontendLogEvent(
        id: 'test-id',
        timestamp: timestamp,
        actionType: UserActionType.navigation,
        description: 'Test navigation',
        level: LogLevel.warning,
        metadata: {'key': 'value'},
        userId: 'user123',
        screenName: 'TestScreen',
        route: '/test',
      );
      
      final json = event.toJson();
      
      expect(json['id'], equals('test-id'));
      expect(json['timestamp'], equals(timestamp.toIso8601String()));
      expect(json['action_type'], equals('navigation'));
      expect(json['description'], equals('Test navigation'));
      expect(json['level'], equals('warning'));
      expect(json['metadata'], equals({'key': 'value'}));
      expect(json['user_id'], equals('user123'));
      expect(json['screen_name'], equals('TestScreen'));
      expect(json['route'], equals('/test'));
      expect(json['platform'], equals('flutter'));
      expect(json['app_version'], equals('1.0.0'));
    });
  });

  group('LogLevel Tests', () {
    test('should have correct enum values', () {
      expect(LogLevel.values, contains(LogLevel.info));
      expect(LogLevel.values, contains(LogLevel.warning));
      expect(LogLevel.values, contains(LogLevel.error));
      expect(LogLevel.values, contains(LogLevel.debug));
    });
  });

  group('UserActionType Tests', () {
    test('should have all expected action types', () {
      expect(UserActionType.values, contains(UserActionType.navigation));
      expect(UserActionType.values, contains(UserActionType.buttonClick));
      expect(UserActionType.values, contains(UserActionType.formSubmit));
      expect(UserActionType.values, contains(UserActionType.search));
      expect(UserActionType.values, contains(UserActionType.playMusic));
      expect(UserActionType.values, contains(UserActionType.login));
      expect(UserActionType.values, contains(UserActionType.vote));
    });
  });
}