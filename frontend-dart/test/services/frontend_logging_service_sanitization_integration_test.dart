import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/services/frontend_logging_service.dart';

void main() {
  group('FrontendLoggingService Integration Tests', () {
    late FrontendLoggingService loggingService;

    setUp(() {
      loggingService = FrontendLoggingService();
    });

    test('should sanitize real-world login metadata', () {
      final loginMetadata = {
        'username': 'john.doe@example.com',
        'password': 'MySecretPassword123!',
        'remember_me': true,
        'login_timestamp': '2023-01-01T00:00:00Z',
        'user_agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
        'auth_header': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c',
      };

      final sanitized = loggingService.sanitizeMetadata(loginMetadata);

      expect(sanitized['username'], equals('john.doe@example.com'));
      expect(sanitized['password'], startsWith('My'));
      expect(sanitized['password'], endsWith('3!'));
      expect(sanitized['remember_me'], equals(true));
      expect(sanitized['login_timestamp'], equals('2023-01-01T00:00:00Z'));
      expect(sanitized['user_agent'], equals('Mozilla/5.0 (Windows NT 10.0; Win64; x64)'));
      expect(sanitized['auth_header'], startsWith('Be'));
      expect(sanitized['auth_header'], endsWith('5c'));
    });

    test('should sanitize API request metadata', () {
      final apiMetadata = {
        'endpoint': '/api/v1/users',
        'method': 'POST',
        'api_key': 'sk-1234567890abcdef1234567890abcdef',
        'authorization': 'Token abc123def456ghi789',
        'request_body': {
          'email': 'user@example.com',
          'password': 'newuserpassword',
          'profile': {
            'name': 'Test User',
            'preferences': {
              'theme': 'dark',
              'secret_setting': 'mysecretvalue'
            }
          }
        },
        'response_headers': {
          'content-type': 'application/json',
          'x-auth-token': 'xyz789abc123'
        }
      };

      final sanitized = loggingService.sanitizeMetadata(apiMetadata);

      expect(sanitized['endpoint'], equals('/api/v1/users'));
      expect(sanitized['method'], equals('POST'));
      expect(sanitized['api_key'], startsWith('sk'));
      expect(sanitized['api_key'], endsWith('ef'));
      expect(sanitized['authorization'], startsWith('To'));
      expect(sanitized['authorization'], endsWith('89'));
      
      expect(sanitized['request_body']['email'], equals('user@example.com'));
      expect(sanitized['request_body']['password'], startsWith('ne'));
      expect(sanitized['request_body']['password'], endsWith('rd'));
      expect(sanitized['request_body']['profile']['name'], equals('Test User'));
      expect(sanitized['request_body']['profile']['preferences']['theme'], equals('dark'));
      expect(sanitized['request_body']['profile']['preferences']['secret_setting'], startsWith('my'));
      expect(sanitized['request_body']['profile']['preferences']['secret_setting'], endsWith('ue'));
      
      expect(sanitized['response_headers']['content-type'], equals('application/json'));
      expect(sanitized['response_headers']['x-auth-token'], startsWith('xy'));
      expect(sanitized['response_headers']['x-auth-token'], endsWith('23'));
    });

    test('should handle complex nested structures with mixed sensitive/non-sensitive data', () {
      final complexMetadata = {
        'user_data': {
          'id': 12345,
          'username': 'testuser',
          'credentials': {
            'current_password': 'oldpassword123',
            'new_password': 'newpassword456',
            'backup_codes': ['code1', 'code2', 'secret123'],
          },
          'sessions': [
            {
              'id': 'session_1',
              'token': 'session_token_abc123',
              'expires': '2023-12-31T23:59:59Z'
            },
            {
              'id': 'session_2', 
              'token': 'session_token_def456',
              'expires': '2023-12-31T23:59:59Z'
            }
          ]
        },
        'app_state': {
          'current_screen': 'settings',
          'api_keys': {
            'deezer_key': 'dk_test_12345',
            'spotify_key': 'sp_live_abcdef'
          }
        }
      };

      final sanitized = loggingService.sanitizeMetadata(complexMetadata);

      expect(sanitized['user_data']['id'], equals(12345));
      expect(sanitized['user_data']['username'], equals('testuser'));
      expect(sanitized['user_data']['credentials']['current_password'], startsWith('ol'));
      expect(sanitized['user_data']['credentials']['current_password'], endsWith('23'));
      expect(sanitized['user_data']['credentials']['new_password'], startsWith('ne'));
      expect(sanitized['user_data']['credentials']['new_password'], endsWith('56'));
      
      expect(sanitized['user_data']['sessions'][0]['id'], equals('session_1'));
      expect(sanitized['user_data']['sessions'][0]['token'], startsWith('se'));
      expect(sanitized['user_data']['sessions'][0]['token'], endsWith('23'));
      expect(sanitized['user_data']['sessions'][0]['expires'], equals('2023-12-31T23:59:59Z'));
      
      expect(sanitized['app_state']['current_screen'], equals('settings'));
      expect(sanitized['app_state']['api_keys']['deezer_key'], startsWith('dk'));
      expect(sanitized['app_state']['api_keys']['deezer_key'], endsWith('45'));
      expect(sanitized['app_state']['api_keys']['spotify_key'], startsWith('sp'));
      expect(sanitized['app_state']['api_keys']['spotify_key'], endsWith('ef'));
    });
  });
}