import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/services/logging_services.dart';

void main() {
  group('FrontendLoggingService Sanitization Tests', () {
    late FrontendLoggingService loggingService;

    setUp(() {
      loggingService = FrontendLoggingService();
    });

    test('should sanitize password fields', () {
      final testMetadata = {
        'username': 'testuser',
        'password': 'secretpassword123',
        'email': 'test@example.com',
      };

      final sanitized = loggingService.sanitizeMetadata(testMetadata);

      expect(sanitized['username'], equals('testuser'));
      expect(sanitized['password'], equals('se*************23'));
      expect(sanitized['email'], equals('test@example.com'));
    });

    test('should sanitize token fields', () {
      final testMetadata = {
        'auth_token': 'Bearer test_jwt_token_placeholder',
        'access_token': 'abc123def456',
        'refresh_token': 'xyz789uvw012',
        'api_key': 'sk-1234567890abcdef',
      };

      final sanitized = loggingService.sanitizeMetadata(testMetadata);

      expect(sanitized['auth_token'], startsWith('Be'));
      expect(sanitized['auth_token'], endsWith('er'));
      expect(sanitized['access_token'], equals('ab********56'));
      expect(sanitized['refresh_token'], equals('xy********12'));
      expect(sanitized['api_key'], startsWith('sk'));
      expect(sanitized['api_key'], endsWith('ef'));
    });

    test('should sanitize nested objects', () {
      final testMetadata = {
        'user': {
          'id': 123,
          'username': 'testuser',
          'credentials': {
            'password': 'mysecretpassword',
            'token': 'abc123token',
          }
        },
        'settings': {
          'theme': 'dark',
          'api_key': 'secretkey123',
        }
      };

      final sanitized = loggingService.sanitizeMetadata(testMetadata);

      expect(sanitized['user']['id'], equals(123));
      expect(sanitized['user']['username'], equals('testuser'));
      expect(sanitized['user']['credentials']['password'], startsWith('my'));
      expect(sanitized['user']['credentials']['password'], endsWith('rd'));
      expect(sanitized['user']['credentials']['token'], startsWith('ab'));
      expect(sanitized['user']['credentials']['token'], endsWith('en'));
      expect(sanitized['settings']['theme'], equals('dark'));
      expect(sanitized['settings']['api_key'], startsWith('se'));
      expect(sanitized['settings']['api_key'], endsWith('23'));
    });

    test('should sanitize arrays containing sensitive data', () {
      final testMetadata = {
        'tokens': ['Bearer jwt123'],
        'users': [
          {'name': 'user1', 'password': 'pass1'},
          {'name': 'user2', 'secret': 'secret123'},
        ]
      };

      final sanitized = loggingService.sanitizeMetadata(testMetadata);

      expect(sanitized['tokens'][0], startsWith('Be'));
      expect(sanitized['tokens'][0], endsWith('23'));
      expect(sanitized['users'][0]['name'], equals('user1'));
      expect(sanitized['users'][0]['password'], equals('pa**s1'));
      expect(sanitized['users'][1]['name'], equals('user2'));
      expect(sanitized['users'][1]['secret'], startsWith('se'));
      expect(sanitized['users'][1]['secret'], endsWith('23'));
    });

    test('should detect sensitive patterns in string values', () {
      final testMetadata = {
        'header': 'Bearer test_jwt_header_placeholder',
        'auth_header': 'Token abcd1234',
        'config': 'password=mysecret',
        'normal_text': 'This is just normal text',
        'base64_token': 'test_base64_token_placeholder_value',
      };

      final sanitized = loggingService.sanitizeMetadata(testMetadata);

      expect(sanitized['header'], startsWith('Be'));
      expect(sanitized['header'], endsWith('er'));
      expect(sanitized['auth_header'], startsWith('To'));
      expect(sanitized['auth_header'], endsWith('34'));
      expect(sanitized['config'], startsWith('pa'));
      expect(sanitized['config'], endsWith('et'));
      expect(sanitized['normal_text'], equals('This is just normal text'));
      expect(sanitized['base64_token'], startsWith('ey'));
      expect(sanitized['base64_token'], endsWith('ue'));
    });

    test('should handle null and empty values safely', () {
      final testMetadata = {
        'null_value': null,
        'empty_string': '',
        'short_password': 'ab',
        'normal_field': 'value',
      };

      final sanitized = loggingService.sanitizeMetadata(testMetadata);

      expect(sanitized['null_value'], isNull);
      expect(sanitized['empty_string'], equals(''));
      expect(sanitized['short_password'], equals('[MASKED]'));
      expect(sanitized['normal_field'], equals('value'));
    });

    test('should preserve non-sensitive data unchanged', () {
      final testMetadata = {
        'user_id': 12345,
        'screen_name': 'home_screen',
        'action_type': 'button_click',
        'timestamp': '2023-01-01T00:00:00Z',
        'platform': 'flutter',
        'version': '1.0.0',
        'boolean_flag': true,
        'numeric_value': 42.5,
      };

      final sanitized = loggingService.sanitizeMetadata(testMetadata);

      expect(sanitized, equals(testMetadata));
    });
  });
}