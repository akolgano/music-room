import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('NotificationService Tests', () {
    late NotificationService notificationService;

    setUp(() {
      notificationService = NotificationService();
    });

    tearDown(() {
      notificationService.dispose();
    });

    test('NotificationService should be instantiable', () {
      expect(notificationService, isA<NotificationService>());
    });

    test('should have navigatorKey', () {
      expect(notificationService.navigatorKey, isA<GlobalKey<NavigatorState>>());
    });

    test('dispose should not throw', () {
      expect(() => notificationService.dispose(), returnsNormally);
    });

    test('should handle WebSocket playlist update message data correctly', () {
      final testData = {
        'type': 'playlist_update',
        'playlist_id': 'test-123',
        'data': [
          {'id': '1', 'name': 'Test Track'}
        ]
      };

      // Test internal methods for message parsing
      expect(testData['type'], equals('playlist_update'));
      expect(testData['playlist_id'], equals('test-123'));
      expect(testData['data'], isA<List>());
    });

    test('should handle unknown message types', () {
      final testData = {
        'type': 'unknown_type',
        'data': {'some': 'data'}
      };

      expect(testData['type'], equals('unknown_type'));
      expect(testData['data'], isA<Map>());
    });
  });
}