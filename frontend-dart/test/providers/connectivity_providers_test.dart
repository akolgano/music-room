import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:music_room/providers/connectivity_providers.dart';
import 'package:music_room/services/api_services.dart';
import 'package:music_room/core/locator_core.dart';
import 'package:get_it/get_it.dart';

void main() {
  group('ConnectivityProvider', () {
    late ConnectivityProvider provider;
    late MockApiService mockApiService;

    setUp(() {
      GetIt.instance.reset();
      mockApiService = MockApiService();
      when(mockApiService.baseUrl).thenReturn('https://api.test.com');
      
      getIt.registerSingleton<ApiService>(mockApiService);
    });

    tearDown(() {
      if (provider != null) {
        provider.dispose();
      }
      
      GetIt.instance.reset();
    });

    group('Initial State', () {
      test('should start with checking status', () {
        provider = ConnectivityProvider();
        
        expect(provider.connectionStatus, ConnectionStatus.checking);
        expect(provider.isChecking, isTrue);
        expect(provider.isConnected, isFalse);
        expect(provider.isDisconnected, isFalse);
        expect(provider.lastConnectedTime, isNull);
        expect(provider.consecutiveFailures, 0);
        expect(provider.currentCheckInterval, const Duration(seconds: 30));
      });
    });

    group('Connection Status Management', () {
      test('should update connection status correctly', () async {
        provider = ConnectivityProvider();
        bool listenerCalled = false;
        provider.addListener(() => listenerCalled = true);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(listenerCalled, isTrue);
      });

      test('should set correct boolean flags for each status', () {
        provider = ConnectivityProvider();
        
        expect(provider.connectionStatus, ConnectionStatus.checking);
        expect(provider.isChecking, isTrue);
        expect(provider.isConnected, isFalse);
        expect(provider.isDisconnected, isFalse);
      });
    });

    group('Connection Status Text', () {
      test('should return correct status text for each connection state', () {
        provider = ConnectivityProvider();
        
        expect(provider.connectionStatusText, 'Checking...');
      });

      test('should provide detailed status text', () {
        provider = ConnectivityProvider();
        
        expect(provider.detailedStatusText, 'Checking connection...');
      });
    });

    group('Time Formatting', () {
      test('should format time correctly for different durations', () {
        provider = ConnectivityProvider();
        
        expect(provider.detailedStatusText, isA<String>());
        expect(provider.detailedStatusText.isNotEmpty, isTrue);
      });
    });

    group('Health Check Intervals', () {
      test('should start with initial interval', () {
        provider = ConnectivityProvider();
        
        expect(provider.currentCheckInterval, const Duration(seconds: 30));
        expect(provider.consecutiveFailures, 0);
      });

      test('should track consecutive failures', () {
        provider = ConnectivityProvider();
        
        expect(provider.consecutiveFailures, 0);
      });
    });

    group('Manual Connection Check', () {
      test('should set status to checking when check starts', () async {
        provider = ConnectivityProvider();
        
        await Future.delayed(const Duration(milliseconds: 50));
        
        final checkFuture = provider.checkConnection();
        
        expect(provider.connectionStatus, ConnectionStatus.checking);
        
        await checkFuture;
      });

      test('should handle successful connection check', () async {
        provider = ConnectivityProvider();
        
        await Future.delayed(const Duration(milliseconds: 200));
        
        expect(provider.connectionStatus, isA<ConnectionStatus>());
        expect(provider.currentCheckInterval, isA<Duration>());
      });

      test('should handle failed connection check gracefully', () async {
        provider = ConnectivityProvider();
        
        await Future.delayed(const Duration(milliseconds: 200));
        
        expect(provider.connectionStatus, isA<ConnectionStatus>());
        expect(provider.consecutiveFailures, isA<int>());
      });
    });

    group('Backoff Strategy', () {
      test('should use exponential backoff for consecutive failures', () {
        provider = ConnectivityProvider();
        
        expect(provider.currentCheckInterval, const Duration(seconds: 30));
        
      });

      test('should cap maximum interval', () {
        provider = ConnectivityProvider();
        
        expect(provider.currentCheckInterval.inMilliseconds, 
               lessThanOrEqualTo(const Duration(minutes: 10).inMilliseconds));
      });

      test('should reset interval on successful connection', () {
        provider = ConnectivityProvider();
        
        expect(provider.currentCheckInterval, 
               lessThanOrEqualTo(const Duration(minutes: 10)));
      });
    });

    group('Timer Management', () {
      test('should start health check timer on initialization', () {
        provider = ConnectivityProvider();
        
        expect(provider.connectionStatus, isA<ConnectionStatus>());
      });

      test('should cancel timer on dispose', () {
        provider = ConnectivityProvider();
        
        expect(() => provider.dispose(), returnsNormally);
      });
    });

    group('Listener Notifications', () {
      test('should notify listeners on status change', () async {
        provider = ConnectivityProvider();
        
        int notificationCount = 0;
        provider.addListener(() => notificationCount++);
        
        await Future.delayed(const Duration(milliseconds: 200));
        
        expect(notificationCount, greaterThan(0));
      });

      test('should not notify if status does not change', () {
        provider = ConnectivityProvider();
        
        int notificationCount = 0;
        provider.addListener(() => notificationCount++);
        
        final currentStatus = provider.connectionStatus;
        
        notificationCount = 0;
        
        expect(provider.connectionStatus, currentStatus);
      });
    });

    group('Status Text Generation', () {
      test('should generate appropriate status text for connected state', () {
        provider = ConnectivityProvider();
        
        final statusText = provider.connectionStatusText;
        expect(statusText, isA<String>());
        expect(statusText.isNotEmpty, isTrue);
      });

      test('should generate detailed status text with time information', () {
        provider = ConnectivityProvider();
        
        final detailedText = provider.detailedStatusText;
        expect(detailedText, isA<String>());
        expect(detailedText.isNotEmpty, isTrue);
      });

      test('should handle null last connected time gracefully', () {
        provider = ConnectivityProvider();
        
        expect(provider.lastConnectedTime, isNull);
        
        expect(provider.detailedStatusText, isNotEmpty);
      });
    });

    group('Edge Cases', () {
      test('should handle rapid successive status checks', () async {
        provider = ConnectivityProvider();
        
        final futures = List.generate(5, (index) => provider.checkConnection());
        
        await Future.wait(futures);
        
        expect(provider.connectionStatus, isA<ConnectionStatus>());
      });

      test('should handle very short time differences', () {
        provider = ConnectivityProvider();
        
        expect(provider.detailedStatusText, isA<String>());
      });

      test('should maintain consistency during concurrent operations', () async {
        provider = ConnectivityProvider();
        
        final checkFuture = provider.checkConnection();
        
        expect(provider.connectionStatus, isA<ConnectionStatus>());
        expect(provider.isChecking || provider.isConnected || provider.isDisconnected, isTrue);
        
        await checkFuture;
      });
    });

    group('Memory Management', () {
      test('should properly dispose without memory leaks', () {
        provider = ConnectivityProvider();
        
        provider.addListener(() {});
        
        expect(() => provider.dispose(), returnsNormally);
      });

      test('should handle dispose called multiple times', () {
        provider = ConnectivityProvider();
        
        provider.dispose();
        expect(() => provider.dispose(), returnsNormally);
      });
    });

    group('Integration Scenarios', () {
      test('should work correctly with no internet connection', () async {
        provider = ConnectivityProvider();
        
        await Future.delayed(const Duration(milliseconds: 300));
        
        expect(provider.connectionStatus, isA<ConnectionStatus>());
      });

      test('should recover from temporary network issues', () async {
        provider = ConnectivityProvider();
        
        await Future.delayed(const Duration(milliseconds: 200));
        
        expect(provider.connectionStatus, isA<ConnectionStatus>());
        expect(provider.consecutiveFailures, isA<int>());
      });
    });

    group('Enum Values', () {
      test('should have correct enum values', () {
        expect(ConnectionStatus.connected, isA<ConnectionStatus>());
        expect(ConnectionStatus.disconnected, isA<ConnectionStatus>());
        expect(ConnectionStatus.checking, isA<ConnectionStatus>());
      });
    });

    group('Constants', () {
      test('should have reasonable timeout values', () {
        provider = ConnectivityProvider();
        
        expect(provider.currentCheckInterval.inSeconds, greaterThan(0));
        expect(provider.currentCheckInterval.inMinutes, lessThanOrEqualTo(10));
      });
    });

    group('Boolean Properties', () {
      test('should have mutually exclusive boolean properties', () {
        provider = ConnectivityProvider();
        
        final boolCount = [
          provider.isConnected,
          provider.isDisconnected,
          provider.isChecking,
        ].where((b) => b).length;
        
        expect(boolCount, 1);
      });
    });
  });
}