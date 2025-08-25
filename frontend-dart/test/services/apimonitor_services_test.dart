import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/services/apimonitor_services.dart';

void main() {
  group('ApiRateMonitorService', () {
    late ApiRateMonitorService service;

    setUp(() {
      service = ApiRateMonitorService();
    });

    tearDown(() {
      service.dispose();
    });

    test('should initialize with no requests', () {
      expect(service.remainingRequests, equals(60));
      expect(service.canMakeRequest(), isTrue);
      expect(service.timeUntilReset, isNull);
    });

    test('should record requests correctly', () {
      service.recordRequest();
      expect(service.remainingRequests, equals(59));
      expect(service.canMakeRequest(), isTrue);
    });

    test('should record multiple requests', () {
      for (int i = 0; i < 10; i++) {
        service.recordRequest();
      }
      expect(service.remainingRequests, equals(50));
      expect(service.canMakeRequest(), isTrue);
    });

    test('should prevent requests when limit is reached', () {
      for (int i = 0; i < 60; i++) {
        service.recordRequest();
      }
      expect(service.remainingRequests, equals(0));
      expect(service.canMakeRequest(), isFalse);
    });

    test('should calculate time until reset correctly', () {
      service.recordRequest();
      final timeUntilReset = service.timeUntilReset;
      expect(timeUntilReset, isNotNull);
      expect(timeUntilReset!.inSeconds, greaterThan(0));
      expect(timeUntilReset.inSeconds, lessThanOrEqualTo(60));
    });

    test('should return correct stats', () {
      service.recordRequest();
      service.recordRequest();
      service.recordRequest();
      
      final stats = service.getStats();
      expect(stats['currentRequests'], equals(3));
      expect(stats['maxRequests'], equals(60));
      expect(stats['remainingRequests'], equals(57));
      expect(stats['timeUntilReset'], isNotNull);
    });

    test('recordApiCall should call recordRequest', () {
      service.recordApiCall();
      expect(service.remainingRequests, equals(59));
    });

    test('startMonitoring should not throw', () {
      expect(() => service.startMonitoring(), returnsNormally);
    });

    test('should handle cleanup correctly', () {
      service.recordRequest();
      expect(service.remainingRequests, equals(59));
      
    });

    test('should handle multiple services independently', () {
      final service2 = ApiRateMonitorService();
      
      service.recordRequest();
      service.recordRequest();
      
      service2.recordRequest();
      
      expect(service.remainingRequests, equals(58));
      expect(service2.remainingRequests, equals(59));
      
      service2.dispose();
    });

    test('dispose should not throw', () {
      expect(() => service.dispose(), returnsNormally);
      expect(() => service.dispose(), returnsNormally);
    });
  });
}